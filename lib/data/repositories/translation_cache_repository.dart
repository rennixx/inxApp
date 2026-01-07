import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/utils/logger.dart';
import '../services/gemini_service.dart';

/// Translation cache entry with metadata
class TranslationCacheEntry {
  final int id;
  final String imageHash;
  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String modelUsed;
  final double confidenceScore;
  final int createdAt;
  final int usageCount;
  final int? userRating; // 1 (bad) to 5 (good), null if not rated
  final bool isFavorited;
  final String? bubbleContext; // JSON string of MangaTranslationContext

  TranslationCacheEntry({
    required this.id,
    required this.imageHash,
    required this.originalText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.modelUsed,
    required this.confidenceScore,
    required this.createdAt,
    required this.usageCount,
    this.userRating,
    this.isFavorited = false,
    this.bubbleContext,
  });

  TranslationCacheEntry copyWith({
    int? id,
    String? imageHash,
    String? originalText,
    String? translatedText,
    String? sourceLang,
    String? targetLang,
    String? modelUsed,
    double? confidenceScore,
    int? createdAt,
    int? usageCount,
    int? userRating,
    bool? isFavorited,
    String? bubbleContext,
  }) {
    return TranslationCacheEntry(
      id: id ?? this.id,
      imageHash: imageHash ?? this.imageHash,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      modelUsed: modelUsed ?? this.modelUsed,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
      userRating: userRating ?? this.userRating,
      isFavorited: isFavorited ?? this.isFavorited,
      bubbleContext: bubbleContext ?? this.bubbleContext,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_hash': imageHash,
      'original_text': originalText,
      'translated_text': translatedText,
      'source_lang': sourceLang,
      'target_lang': targetLang,
      'model_used': modelUsed,
      'confidence_score': confidenceScore,
      'created_at': createdAt,
      'usage_count': usageCount,
      'user_rating': userRating,
      'is_favorited': isFavorited ? 1 : 0,
      'bubble_context': bubbleContext,
    };
  }

  factory TranslationCacheEntry.fromMap(Map<String, dynamic> map) {
    return TranslationCacheEntry(
      id: map['id'] as int,
      imageHash: map['image_hash'] as String,
      originalText: map['original_text'] as String,
      translatedText: map['translated_text'] as String,
      sourceLang: map['source_lang'] as String,
      targetLang: map['target_lang'] as String,
      modelUsed: map['model_used'] as String,
      confidenceScore: map['confidence_score'] as double,
      createdAt: map['created_at'] as int,
      usageCount: map['usage_count'] as int,
      userRating: map['user_rating'] as int?,
      isFavorited: (map['is_favorited'] as int?) == 1,
      bubbleContext: map['bubble_context'] as String?,
    );
  }
}

/// Cache statistics
class CacheStatistics {
  final int totalEntries;
  final int totalSize;
  final int totalUsageCount;
  final double averageRating;
  final int favoritedCount;
  final Map<String, int> languageDistribution;

  CacheStatistics({
    required this.totalEntries,
    required this.totalSize,
    required this.totalUsageCount,
    required this.averageRating,
    required this.favoritedCount,
    required this.languageDistribution,
  });
}

/// Repository for managing translation cache
class TranslationCacheRepository {
  TranslationCacheRepository._();

  static Database? _database;
  static const String _tableName = 'translation_cache';
  static const int _maxCacheSizeBytes = 500 * 1024 * 1024; // 500MB
  static const int _maxAgeDays = 30;
  static const int _maxEntries = 10000;

  /// Initialize the database
  static Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      AppLogger.warning('Translation cache not supported on web', tag: 'TranslationCache');
      // Return a mock database for web
      throw UnsupportedError('Translation cache is not supported on web platform');
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'translation_cache.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );

    AppLogger.info('Translation cache database initialized', tag: 'TranslationCache');
    return _database!;
  }

  static Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_hash TEXT NOT NULL UNIQUE,
        original_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        source_lang TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        model_used TEXT NOT NULL,
        confidence_score REAL NOT NULL,
        created_at INTEGER NOT NULL,
        usage_count INTEGER DEFAULT 0,
        user_rating INTEGER,
        is_favorited INTEGER DEFAULT 0,
        bubble_context TEXT
      )
    ''');

    // Create indexes for common queries
    await db.execute('''
      CREATE INDEX idx_image_hash ON $_tableName(image_hash)
    ''');

    await db.execute('''
      CREATE INDEX idx_target_lang ON $_tableName(target_lang)
    ''');

    await db.execute('''
      CREATE INDEX idx_created_at ON $_tableName(created_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_usage_count ON $_tableName(usage_count)
    ''');
  }

  /// Generate hash for image/text combination
  static String _generateHash(String text, String context) {
    final combined = '$text|$context';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 16); // Use first 16 chars
  }

  /// Get translation from cache
  static Future<TranslationCacheEntry?> getTranslation(
    String originalText,
    String targetLanguage, {
    String sourceLanguage = 'auto',
    String? context,
  }) async {
    if (kIsWeb) return null;

    try {
      final db = await database;
      final hash = _generateHash(originalText, context ?? '');

      final maps = await db.query(
        _tableName,
        where: 'image_hash = ? AND target_lang = ?',
        whereArgs: [hash, targetLanguage],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      // Increment usage count
      await db.update(
        _tableName,
        {'usage_count': (maps.first['usage_count'] as int) + 1},
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );

      AppLogger.info('Cache hit for hash: $hash', tag: 'TranslationCache');
      return TranslationCacheEntry.fromMap(maps.first);
    } catch (e) {
      AppLogger.error('Error getting translation from cache', error: e, tag: 'TranslationCache');
      return null;
    }
  }

  /// Save translation to cache
  static Future<void> saveTranslation({
    required String originalText,
    required String translatedText,
    required String targetLanguage,
    required TranslationResult result,
    String? context,
  }) async {
    if (kIsWeb) return;

    try {
      final db = await database;
      final hash = _generateHash(originalText, context ?? '');
      final now = DateTime.now().millisecondsSinceEpoch;

      final entry = TranslationCacheEntry(
        id: 0, // Auto-generated
        imageHash: hash,
        originalText: originalText,
        translatedText: translatedText,
        sourceLang: result.sourceLanguage,
        targetLang: targetLanguage,
        modelUsed: result.modelUsed.modelName,
        confidenceScore: result.confidence,
        createdAt: now,
        usageCount: 1,
        bubbleContext: context,
      );

      await db.insert(
        _tableName,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      AppLogger.info('Saved translation to cache: $hash', tag: 'TranslationCache');

      // Check if cleanup is needed
      await _performCleanupIfNeeded(db);
    } catch (e) {
      AppLogger.error('Error saving translation to cache', error: e, tag: 'TranslationCache');
    }
  }

  /// Rate a translation
  static Future<void> rateTranslation(int id, int rating) async {
    if (kIsWeb) return;

    try {
      final db = await database;
      await db.update(
        _tableName,
        {'user_rating': rating},
        where: 'id = ?',
        whereArgs: [id],
      );

      AppLogger.info('Rated translation $id: $rating', tag: 'TranslationCache');
    } catch (e) {
      AppLogger.error('Error rating translation', error: e, tag: 'TranslationCache');
    }
  }

  /// Toggle favorite status
  static Future<void> toggleFavorite(int id) async {
    if (kIsWeb) return;

    try {
      final db = await database;
      final maps = await db.query(
        _tableName,
        columns: ['is_favorited'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final currentFavorite = (maps.first['is_favorited'] as int?) == 1;
        await db.update(
          _tableName,
          {'is_favorited': currentFavorite ? 0 : 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      AppLogger.info('Toggled favorite for translation $id', tag: 'TranslationCache');
    } catch (e) {
      AppLogger.error('Error toggling favorite', error: e, tag: 'TranslationCache');
    }
  }

  /// Get cache statistics
  static Future<CacheStatistics> getStatistics() async {
    if (kIsWeb) {
      return CacheStatistics(
        totalEntries: 0,
        totalSize: 0,
        totalUsageCount: 0,
        averageRating: 0.0,
        favoritedCount: 0,
        languageDistribution: {},
      );
    }

    try {
      final db = await database;

      // Total entries and size
      final countResult = await db.rawQuery('''
        SELECT COUNT(*) as count, SUM(LENGTH(original_text) + LENGTH(translated_text)) as size
        FROM $_tableName
      ''');

      // Total usage count
      final usageResult = await db.rawQuery('''
        SELECT SUM(usage_count) as total FROM $_tableName
      ''');

      // Average rating
      final ratingResult = await db.rawQuery('''
        SELECT AVG(user_rating) as avg_rating FROM $_tableName WHERE user_rating IS NOT NULL
      ''');

      // Favorited count
      final favoriteResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM $_tableName WHERE is_favorited = 1
      ''');

      // Language distribution
      final langResult = await db.rawQuery('''
        SELECT target_lang, COUNT(*) as count FROM $_tableName GROUP BY target_lang
      ''');

      final langDistribution = <String, int>{};
      for (final row in langResult) {
        langDistribution[row['target_lang'] as String] = row['count'] as int;
      }

      return CacheStatistics(
        totalEntries: countResult.first['count'] as int,
        totalSize: countResult.first['size'] as int? ?? 0,
        totalUsageCount: usageResult.first['total'] as int? ?? 0,
        averageRating: ratingResult.first['avg_rating'] as double? ?? 0.0,
        favoritedCount: favoriteResult.first['count'] as int,
        languageDistribution: langDistribution,
      );
    } catch (e) {
      AppLogger.error('Error getting statistics', error: e, tag: 'TranslationCache');
      rethrow;
    }
  }

  /// Perform LRU cleanup if needed
  static Future<void> _performCleanupIfNeeded(Database db) async {
    final stats = await getStatistics();

    // Check size limit
    if (stats.totalSize > _maxCacheSizeBytes) {
      AppLogger.warning('Cache size limit exceeded, performing cleanup', tag: 'TranslationCache');
      await _cleanupBySize(db, _maxCacheSizeBytes);
    }

    // Check entry limit
    if (stats.totalEntries > _maxEntries) {
      AppLogger.warning('Cache entry limit exceeded, performing cleanup', tag: 'TranslationCache');
      await _cleanupByEntries(db, _maxEntries);
    }

    // Check for old entries
    await _cleanupOldEntries(db);
  }

  /// Cleanup by size (LRU - remove least recently used)
  static Future<void> _cleanupBySize(Database db, int maxSize) async {
    final currentSize = await db.rawQuery('''
      SELECT SUM(LENGTH(original_text) + LENGTH(translated_text)) as size FROM $_tableName
    ''');

    final totalSize = currentSize.first['size'] as int? ?? 0;
    if (totalSize <= maxSize) return;

    // Delete entries with lowest usage count, excluding favorited
    await db.delete(
      _tableName,
      where: '''
        id IN (
          SELECT id FROM $_tableName
          WHERE is_favorited = 0
          ORDER BY usage_count ASC, created_at DESC
          LIMIT 100
        )
      ''',
    );
  }

  /// Cleanup by entry count
  static Future<void> _cleanupByEntries(Database db, int maxEntries) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName'),
    );

    if (count == null || count <= maxEntries) return;

    final excess = count - maxEntries;

    await db.rawDelete('''
      DELETE FROM $_tableName
      WHERE id IN (
        SELECT id FROM $_tableName
        WHERE is_favorited = 0
        ORDER BY usage_count ASC, created_at DESC
        LIMIT $excess
      )
    ''');
  }

  /// Cleanup old entries (older than 30 days, not favorited)
  static Future<void> _cleanupOldEntries(Database db) async {
    final cutoffTime = DateTime.now().subtract(const Duration(days: _maxAgeDays)).millisecondsSinceEpoch;

    await db.delete(
      _tableName,
      where: 'created_at < ? AND is_favorited = 0',
      whereArgs: [cutoffTime],
    );
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    if (kIsWeb) return;

    try {
      final db = await database;
      await db.delete(_tableName);
      AppLogger.info('Translation cache cleared', tag: 'TranslationCache');
    } catch (e) {
      AppLogger.error('Error clearing cache', error: e, tag: 'TranslationCache');
    }
  }

  /// Export cache data
  static Future<List<Map<String, dynamic>>> exportData() async {
    if (kIsWeb) return [];

    try {
      final db = await database;
      return await db.query(_tableName);
    } catch (e) {
      AppLogger.error('Error exporting cache', error: e, tag: 'TranslationCache');
      return [];
    }
  }

  /// Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      AppLogger.info('Translation cache database closed', tag: 'TranslationCache');
    }
  }
}
