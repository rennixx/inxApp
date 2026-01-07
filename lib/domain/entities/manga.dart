enum FileType {
  cbz,
  pdf,
  image,
  folder,
  other,
}

class Manga {
  final String id;
  final String title;
  final String? author;
  final String? coverPath;
  final String filePath;
  final FileType fileType;
  final int currentPage;
  final int totalPages;
  final DateTime? lastRead;
  final bool isFavorited;
  final List<String> tags;
  final double readingProgress;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  Manga({
    required this.id,
    required this.title,
    this.author,
    this.coverPath,
    required this.filePath,
    required this.fileType,
    this.currentPage = 0,
    this.totalPages = 0,
    this.lastRead,
    this.isFavorited = false,
    this.tags = const [],
    this.readingProgress = 0.0,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  Manga copyWith({
    String? id,
    String? title,
    String? author,
    String? coverPath,
    String? filePath,
    FileType? fileType,
    int? currentPage,
    int? totalPages,
    DateTime? lastRead,
    bool? isFavorited,
    List<String>? tags,
    double? readingProgress,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Manga(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lastRead: lastRead ?? this.lastRead,
      isFavorited: isFavorited ?? this.isFavorited,
      tags: tags ?? this.tags,
      readingProgress: readingProgress ?? this.readingProgress,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fileExtension {
    switch (fileType) {
      case FileType.cbz:
        return '.cbz';
      case FileType.pdf:
        return '.pdf';
      case FileType.image:
        return '.jpg';
      case FileType.folder:
        return '';
      case FileType.other:
        return '';
    }
  }

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    const kb = 1024;
    const mb = 1024 * kb;
    const gb = 1024 * mb;

    if (fileSize! >= gb) {
      return '${(fileSize! / gb).toStringAsFixed(2)} GB';
    } else if (fileSize! >= mb) {
      return '${(fileSize! / mb).toStringAsFixed(2)} MB';
    } else if (fileSize! >= kb) {
      return '${(fileSize! / kb).toStringAsFixed(2)} KB';
    } else {
      return '$fileSize bytes';
    }
  }

  String get formattedProgress {
    if (totalPages == 0) return '0%';
    return '${(readingProgress * 100).toInt()}%';
  }
}
