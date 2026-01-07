import 'package:flutter/material.dart';

/// Manga collection entity
class MangaCollection {
  final String id;
  final String name;
  final String description;
  final List<String> mangaIds;
  final Color color;
  final IconData icon;
  final DateTime createdAt;
  final DateTime? lastModified;
  final int order;

  MangaCollection({
    required this.id,
    required this.name,
    this.description = '',
    this.mangaIds = const [],
    this.color = const Color(0xFF6C5CE7),
    this.icon = Icons.folder,
    DateTime? createdAt,
    this.lastModified,
    this.order = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  MangaCollection copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? mangaIds,
    Color? color,
    IconData? icon,
    DateTime? createdAt,
    DateTime? lastModified,
    int? order,
  }) {
    return MangaCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mangaIds: mangaIds ?? this.mangaIds,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      order: order ?? this.order,
    );
  }

  /// Get manga count
  int get mangaCount => mangaIds.length;

  /// Check if collection contains manga
  bool containsManga(String mangaId) => mangaIds.contains(mangaId);

  /// Add manga to collection
  MangaCollection addManga(String mangaId) {
    if (mangaIds.contains(mangaId)) return this;
    return copyWith(
      mangaIds: [...mangaIds, mangaId],
      lastModified: DateTime.now(),
    );
  }

  /// Remove manga from collection
  MangaCollection removeManga(String mangaId) {
    return copyWith(
      mangaIds: mangaIds.where((id) => id != mangaId).toList(),
      lastModified: DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'mangaIds': mangaIds,
      'color': color.value,
      'icon': icon.codePoint,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'order': order,
    };
  }

  /// Create from JSON
  factory MangaCollection.fromJson(Map<String, dynamic> json) {
    return MangaCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      mangaIds: List<String>.from(json['mangaIds'] as List),
      color: Color(json['color'] as int? ?? 0xFF6C5CE7),
      icon: IconData(json['icon'] as int? ?? Icons.folder.codePoint),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      order: json['order'] as int? ?? 0,
    );
  }

  /// Create default collections
  static List<MangaCollection> createDefaultCollections() {
    return [
      MangaCollection(
        id: 'favorites',
        name: 'Favorites',
        description: 'Your favorite manga',
        icon: Icons.favorite,
        color: const Color(0xFFF44336),
        order: 0,
      ),
      MangaCollection(
        id: 'reading',
        name: 'Currently Reading',
        description: 'Manga you\'re currently reading',
        icon: Icons.book,
        color: const Color(0xFF6C5CE7),
        order: 1,
      ),
      MangaCollection(
        id: 'completed',
        name: 'Completed',
        description: 'Manga you\'ve finished reading',
        icon: Icons.check_circle,
        color: const Color(0xFF4CAF50),
        order: 2,
      ),
      MangaCollection(
        id: 'plan_to_read',
        name: 'Plan to Read',
        description: 'Manga you want to read later',
        icon: Icons.watch_later,
        color: const Color(0xFFFF9800),
        order: 3,
      ),
    ];
  }
}

/// Collection colors
class CollectionColors {
  static const List<Color> colors = [
    Color(0xFF6C5CE7), // Purple
    Color(0xFFF44336), // Red
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Deep Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFFEB3B), // Yellow
  ];
}

/// Collection icons
class CollectionIcons {
  static const List<IconData> icons = [
    Icons.folder,
    Icons.favorite,
    Icons.book,
    Icons.bookmark,
    Icons.star,
    Icons.label,
    Icons.auto_stories,
    Icons.menu_book,
    Icons.collections_bookmark,
    Icons.library_books,
  ];
}
