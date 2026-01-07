import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:uuid/uuid.dart';
import 'package:archive/archive.dart';
import '../../domain/entities/manga.dart';
import '../../core/utils/logger.dart';
import 'web_file_storage.dart';

class ImportResult {
  final List<Manga> imported;
  final List<String> errors;
  final int totalFiles;

  ImportResult({
    required this.imported,
    required this.errors,
    required this.totalFiles,
  });
}

class FileScanner {
  static const List<String> supportedExtensions = [
    '.cbz',
    '.cbr',
    '.cb7',
    '.pdf',
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.bmp',
  ];

  static List<String> get imageExtensions => [
        '.jpg',
        '.jpeg',
        '.png',
        '.webp',
        '.gif',
        '.bmp',
      ];

  static List<String> get archiveExtensions => [
        '.cbz',
        '.cbr',
        '.cb7',
      ];

  static bool isSupportedFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return supportedExtensions.contains(extension);
  }

  static FileType detectFileType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    if (archiveExtensions.contains(extension)) {
      return FileType.cbz;
    } else if (extension == '.pdf') {
      return FileType.pdf;
    } else if (imageExtensions.contains(extension)) {
      return FileType.image;
    } else if (Directory(filePath).existsSync()) {
      return FileType.folder;
    }

    return FileType.other;
  }

  static String generateTitleFromPath(String filePath) {
    final fileName = path.basenameWithoutExtension(filePath);
    return fileName.replaceAll(RegExp(r'[_\-\.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<ImportResult> pickFiles() async {
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: supportedExtensions.map((e) => e.replaceFirst('.', '')).toList(),
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return ImportResult(imported: [], errors: [], totalFiles: 0);
    }

    final mangaList = <Manga>[];
    final errorList = <String>[];

    for (var file in result.files) {
      if (kIsWeb) {
        // On web, use bytes instead of path
        if (file.bytes != null) {
          try {
            final manga = await _createMangaFromBytes(file.name, file.bytes!);
            mangaList.add(manga);
          } catch (e) {
            errorList.add('${file.name}: $e');
          }
        }
      } else {
        // On mobile/desktop, use path
        if (file.path != null) {
          try {
            final manga = await createMangaFromFile(file.path!);
            mangaList.add(manga);
          } catch (e) {
            errorList.add('${file.path}: $e');
          }
        }
      }
    }

    return ImportResult(imported: mangaList, errors: errorList, totalFiles: result.files.length);
  }

  Future<Manga> _createMangaFromBytes(String fileName, List<int> bytes) async {
    // For web, store bytes in WebFileStorage
    final now = DateTime.now();
    final extension = path.extension(fileName).toLowerCase();
    final fileType = _detectFileTypeFromExtension(extension);
    final fileId = WebFileStorage.storeFile(fileName, Uint8List.fromList(bytes));

    // Count pages and extract cover for archives
    int totalPages = 0;
    String? coverPath;

    if (fileType == FileType.image) {
      totalPages = 1;
      coverPath = fileId;
    } else if (fileType == FileType.cbz) {
      // Extract pages from CBZ archive
      try {
        final archive = ZipDecoder().decodeBytes(bytes);
        final imageFiles = archive.files
            .where((file) => file.isFile && _isImageFile(file.name))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        totalPages = imageFiles.length;

        // Extract first image as cover
        if (imageFiles.isNotEmpty) {
          final coverBytes = imageFiles.first.content as List<int>;
          final coverId = '${fileId}_cover';
          WebFileStorage.storeFile('cover_$fileName', Uint8List.fromList(coverBytes));
          coverPath = coverId;
        }

        AppLogger.info('CBZ contains $totalPages pages', tag: 'FileScanner');
      } catch (e) {
        AppLogger.error('Failed to extract CBZ pages', error: e, tag: 'FileScanner');
      }
    } else if (fileType == FileType.pdf) {
      // For PDF, we can't easily extract pages without additional libraries
      // Store PDF info for now - page count would require pdf package
      AppLogger.info('PDF file uploaded (page count not available on web)', tag: 'FileScanner');
      totalPages = 1; // Placeholder
    }

    final manga = Manga(
      id: const Uuid().v4(),
      title: generateTitleFromPath(fileName),
      filePath: fileId, // On web, store the fileId reference instead of path
      fileType: fileType,
      fileSize: bytes.length,
      coverPath: coverPath,
      currentPage: 0,
      totalPages: totalPages,
      readingProgress: 0.0,
      createdAt: now,
      updatedAt: now,
    );

    // Index the manga for retrieval
    WebFileStorage.indexManga(fileId, manga);

    return manga;
  }

  bool _isImageFile(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return imageExtensions.contains(extension);
  }

  FileType _detectFileTypeFromExtension(String extension) {
    if (archiveExtensions.contains(extension)) return FileType.cbz;
    if (extension == '.pdf') return FileType.pdf;
    if (imageExtensions.contains(extension)) return FileType.image;
    return FileType.other;
  }

  Future<ImportResult> pickDirectory() async {
    if (kIsWeb) {
      return ImportResult(
        imported: [],
        errors: ['Directory picking is not supported on web. Please use the file picker to select individual files.'],
        totalFiles: 0,
      );
    }

    try {
      final directoryPath = await fp.FilePicker.platform.getDirectoryPath();

      if (directoryPath == null) {
        return ImportResult(imported: [], errors: [], totalFiles: 0);
      }

      return await scanDirectory(directoryPath);
    } catch (e) {
      AppLogger.error('Directory picker failed', error: e, tag: 'FileScanner');
      return ImportResult(
        imported: [],
        errors: ['Failed to pick directory: $e'],
        totalFiles: 0,
      );
    }
  }

  Future<ImportResult> scanDirectory(String directoryPath, {bool recursive = true}) async {
    final List<Manga> imported = [];
    final List<String> errors = [];
    int totalFiles = 0;

    try {
      final directory = Directory(directoryPath);
      if (!directory.existsSync()) {
        errors.add('Directory does not exist: $directoryPath');
        return ImportResult(imported: imported, errors: errors, totalFiles: totalFiles);
      }

      final files = recursive ? directory.listSync(recursive: true) : directory.listSync(recursive: false);

      for (final entity in files) {
        if (entity is File) {
          totalFiles++;
          if (isSupportedFile(entity.path)) {
            try {
              final manga = await createMangaFromFile(entity.path);
              imported.add(manga);
            } catch (e) {
              errors.add('${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      errors.add('Failed to scan directory: $e');
      AppLogger.error('Directory scan failed', error: e, tag: 'FileScanner');
    }

    return ImportResult(imported: imported, errors: errors, totalFiles: totalFiles);
  }

  Future<Manga> createMangaFromFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File does not exist');
    }

    final fileType = detectFileType(filePath);
    final fileSize = await file.length();
    final stat = await file.stat();
    final now = DateTime.now();

    String? coverPath;
    if (fileType == FileType.image) {
      coverPath = filePath;
    }

    return Manga(
      id: const Uuid().v4(),
      title: generateTitleFromPath(filePath),
      filePath: filePath,
      fileType: fileType,
      fileSize: fileSize,
      coverPath: coverPath,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<String>> extractImagesFromArchive(String archivePath) async {
    // TODO: Implement archive extraction logic
    // This would use a package like 'archive' or 'flutter_archive'
    AppLogger.warning('Archive extraction not yet implemented', tag: 'FileScanner');
    return [];
  }

  Future<int> countPages(String filePath) async {
    final fileType = detectFileType(filePath);

    switch (fileType) {
      case FileType.cbz:
        // TODO: Implement CBZ page counting
        return 0;
      case FileType.pdf:
        // TODO: Implement PDF page counting
        return 0;
      case FileType.folder:
        final dir = Directory(filePath);
        final files = dir.listSync()
            .whereType<File>()
            .where((f) => imageExtensions.contains(path.extension(f.path).toLowerCase()))
            .toList();
        return files.length;
      case FileType.image:
        return 1;
      default:
        return 0;
    }
  }

  Future<String?> extractCoverFromArchive(String archivePath) async {
    // TODO: Implement cover extraction from archive
    AppLogger.warning('Cover extraction not yet implemented', tag: 'FileScanner');
    return null;
  }

  Future<String?> generateCoverForFolder(String folderPath) async {
    final dir = Directory(folderPath);
    final images = dir.listSync()
        .whereType<File>()
        .where((f) => imageExtensions.contains(path.extension(f.path).toLowerCase()))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (images.isNotEmpty) {
      return images.first.path;
    }

    return null;
  }

  Future<bool> validateFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!file.existsSync()) {
        return false;
      }

      // Check if file is readable
      final stat = await file.stat();
      if (stat.size == 0) {
        return false;
      }

      // For archives, check if they're valid
      final extension = path.extension(filePath).toLowerCase();
      if (archiveExtensions.contains(extension)) {
        // TODO: Add archive validation
        return true;
      }

      return true;
    } catch (e) {
      AppLogger.error('File validation failed', error: e, tag: 'FileScanner');
      return false;
    }
  }
}
