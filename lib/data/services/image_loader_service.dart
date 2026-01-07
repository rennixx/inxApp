import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import '../../domain/entities/manga.dart';
import '../../core/utils/logger.dart';
import 'web_file_storage.dart';

class ImageLoaderService {
  ImageLoaderService._();

  static final Map<String, File> _imageCache = {};

  static Future<List<String>> extractImages(String filePath, FileType fileType) async {
    if (kIsWeb) {
      // On web, extract images from WebFileStorage
      return await _extractFromWebStorage(filePath, fileType);
    }

    switch (fileType) {
      case FileType.cbz:
        return await _extractFromArchive(filePath);
      case FileType.folder:
        return await _loadFromFolder(filePath);
      case FileType.image:
        return [filePath];
      default:
        return [];
    }
  }

  static Future<List<String>> _extractFromWebStorage(String fileId, FileType fileType) async {
    try {
      final bytes = WebFileStorage.getFile(fileId);
      if (bytes == null) {
        AppLogger.error('File not found in WebFileStorage: $fileId', tag: 'ImageLoader');
        return [];
      }

      if (fileType == FileType.cbz) {
        // Extract images from CBZ archive
        final archive = ZipDecoder().decodeBytes(bytes);
        final imageFiles = archive.files
            .where((file) => file.isFile && _isImageFile(file.name))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        final imageIds = <String>[];
        for (final file in imageFiles) {
          // Store each image with a predictable ID
          final imageBytes = file.content as List<int>;
          final imageId = '${fileId}_${file.name}';
          WebFileStorage.storeFileWithId(imageId, Uint8List.fromList(imageBytes));
          imageIds.add(imageId);
        }

        AppLogger.info('Extracted ${imageIds.length} images from CBZ on web', tag: 'ImageLoader');
        AppLogger.info('First image ID: ${imageIds.first}', tag: 'ImageLoader');
        return imageIds;
      } else if (fileType == FileType.image) {
        // For single image, return the fileId
        return [fileId];
      } else if (fileType == FileType.pdf) {
        // PDF reading is not yet supported on web
        AppLogger.warning('PDF reading is not yet supported on web', tag: 'ImageLoader');
        return [];
      }

      return [];
    } catch (e) {
      AppLogger.error('Failed to extract images from web storage', error: e, tag: 'ImageLoader');
      return [];
    }
  }

  static Future<List<String>> _extractFromArchive(String archivePath) async {
    try {
      final bytes = await File(archivePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final imageFiles = <String>[];

      for (final file in archive) {
        if (file.isFile && _isImageFile(file.name)) {
          // Extract to temp directory
          final tempDir = Directory.systemTemp;
          final outputPath = path.join(tempDir.path, path.basename(file.name));

          final outputFile = File(outputPath);
          await outputFile.writeAsBytes(file.content as List<int>);

          imageFiles.add(outputPath);
        }
      }

      // Sort by filename to ensure correct order
      imageFiles.sort((a, b) => a.compareTo(b));

      return imageFiles;
    } catch (e) {
      AppLogger.error('Failed to extract archive', error: e, tag: 'ImageLoader');
      return [];
    }
  }

  static Future<List<String>> _loadFromFolder(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      final files = directory.listSync();

      final imageFiles = files
          .whereType<File>()
          .where((file) => _isImageFile(file.path))
          .map((file) => file.path)
          .toList();

      imageFiles.sort();
      return imageFiles;
    } catch (e) {
      AppLogger.error('Failed to load folder', error: e, tag: 'ImageLoader');
      return [];
    }
  }

  static bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'].contains(extension);
  }

  static void clearCache() {
    _imageCache.clear();
  }

  static int get cacheSize => _imageCache.length;
}
