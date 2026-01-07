class MediaItem {
  final String id;
  final String title;
  final String? thumbnailPath;
  final String filePath;
  final int fileSize;
  final DateTime createdAt;
  final MediaType type;
  final Duration? duration;

  MediaItem({
    required this.id,
    required this.title,
    this.thumbnailPath,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
    required this.type,
    this.duration,
  });

  MediaItem copyWith({
    String? id,
    String? title,
    String? thumbnailPath,
    String? filePath,
    int? fileSize,
    DateTime? createdAt,
    MediaType? type,
    Duration? duration,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      duration: duration ?? this.duration,
    );
  }
}

enum MediaType {
  video,
  image,
  audio,
}
