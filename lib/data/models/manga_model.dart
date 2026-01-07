import '../../domain/entities/manga.dart';

class MangaModel {
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

  MangaModel({
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover_path': coverPath,
      'file_path': filePath,
      'file_type': fileType.name,
      'current_page': currentPage,
      'total_pages': totalPages,
      'last_read': lastRead?.millisecondsSinceEpoch,
      'is_favorited': isFavorited ? 1 : 0,
      'tags': tags.join(','),
      'reading_progress': readingProgress,
      'file_size': fileSize,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory MangaModel.fromMap(Map<String, dynamic> map) {
    return MangaModel(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String?,
      coverPath: map['cover_path'] as String?,
      filePath: map['file_path'] as String,
      fileType: FileType.values.firstWhere(
        (e) => e.name == map['file_type'],
        orElse: () => FileType.other,
      ),
      currentPage: map['current_page'] as int? ?? 0,
      totalPages: map['total_pages'] as int? ?? 0,
      lastRead: map['last_read'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_read'] as int)
          : null,
      isFavorited: (map['is_favorited'] as int? ?? 0) == 1,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      readingProgress: map['reading_progress'] as double? ?? 0.0,
      fileSize: map['file_size'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Manga toEntity() {
    return Manga(
      id: id,
      title: title,
      author: author,
      coverPath: coverPath,
      filePath: filePath,
      fileType: fileType,
      currentPage: currentPage,
      totalPages: totalPages,
      lastRead: lastRead,
      isFavorited: isFavorited,
      tags: tags,
      readingProgress: readingProgress,
      fileSize: fileSize,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory MangaModel.fromEntity(Manga manga) {
    return MangaModel(
      id: manga.id,
      title: manga.title,
      author: manga.author,
      coverPath: manga.coverPath,
      filePath: manga.filePath,
      fileType: manga.fileType,
      currentPage: manga.currentPage,
      totalPages: manga.totalPages,
      lastRead: manga.lastRead,
      isFavorited: manga.isFavorited,
      tags: manga.tags,
      readingProgress: manga.readingProgress,
      fileSize: manga.fileSize,
      createdAt: manga.createdAt,
      updatedAt: manga.updatedAt,
    );
  }

  MangaModel copyWith({
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
    return MangaModel(
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
}
