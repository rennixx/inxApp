import 'package:sqflite/sqflite.dart';
import '../datasources/database_helper.dart';
import '../models/manga_model.dart';
import '../../domain/entities/manga.dart';
import '../../core/utils/logger.dart';

class MangaRepository {
  final DatabaseHelper _dbHelper;

  MangaRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<String> addManga(Manga manga) async {
    try {
      final db = await _dbHelper.database;
      final model = MangaModel.fromEntity(manga);

      await db.insert(
        'manga',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      AppLogger.info('Manga added: ${manga.title}', tag: 'MangaRepository');
      return manga.id;
    } catch (e) {
      AppLogger.error('Failed to add manga', error: e, tag: 'MangaRepository');
      rethrow;
    }
  }

  Future<List<Manga>> getMangaList({
    int? limit,
    int? offset,
    String? sortBy,
    bool ascending = true,
  }) async {
    try {
      final db = await _dbHelper.database;

      String orderBy = 'created_at DESC';
      if (sortBy != null) {
        orderBy = '$sortBy ${ascending ? 'ASC' : 'DESC'}';
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'manga',
        limit: limit,
        offset: offset,
        orderBy: orderBy,
      );

      return maps.map((map) => MangaModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      AppLogger.error('Failed to get manga list', error: e, tag: 'MangaRepository');
      return [];
    }
  }

  Future<Manga?> getMangaById(String id) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'manga',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return MangaModel.fromMap(maps.first).toEntity();
    } catch (e) {
      AppLogger.error('Failed to get manga by id', error: e, tag: 'MangaRepository');
      return null;
    }
  }

  Future<List<Manga>> getFavorites() async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'manga',
        where: 'is_favorited = ?',
        whereArgs: [1],
        orderBy: 'last_read DESC',
      );

      return maps.map((map) => MangaModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      AppLogger.error('Failed to get favorites', error: e, tag: 'MangaRepository');
      return [];
    }
  }

  Future<List<Manga>> getRecentlyRead({int limit = 10}) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'manga',
        where: 'last_read IS NOT NULL',
        orderBy: 'last_read DESC',
        limit: limit,
      );

      return maps.map((map) => MangaModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      AppLogger.error('Failed to get recently read', error: e, tag: 'MangaRepository');
      return [];
    }
  }

  Future<bool> updateProgress(String id, int currentPage, int totalPages) async {
    try {
      final db = await _dbHelper.database;

      final progress = totalPages > 0 ? currentPage / totalPages : 0.0;
      final now = DateTime.now().millisecondsSinceEpoch;

      final count = await db.update(
        'manga',
        {
          'current_page': currentPage,
          'total_pages': totalPages,
          'reading_progress': progress,
          'last_read': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      AppLogger.info('Progress updated for manga $id: $currentPage/$totalPages', tag: 'MangaRepository');
      return count > 0;
    } catch (e) {
      AppLogger.error('Failed to update progress', error: e, tag: 'MangaRepository');
      return false;
    }
  }

  Future<bool> toggleFavorite(String id) async {
    try {
      final db = await _dbHelper.database;

      final manga = await getMangaById(id);
      if (manga == null) return false;

      final count = await db.update(
        'manga',
        {
          'is_favorited': manga.isFavorited ? 0 : 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      AppLogger.info('Toggled favorite for manga $id', tag: 'MangaRepository');
      return count > 0;
    } catch (e) {
      AppLogger.error('Failed to toggle favorite', error: e, tag: 'MangaRepository');
      return false;
    }
  }

  Future<bool> updateManga(Manga manga) async {
    try {
      final db = await _dbHelper.database;
      final model = MangaModel.fromEntity(manga.copyWith(
        updatedAt: DateTime.now(),
      ));

      final count = await db.update(
        'manga',
        model.toMap(),
        where: 'id = ?',
        whereArgs: [manga.id],
      );

      AppLogger.info('Manga updated: ${manga.title}', tag: 'MangaRepository');
      return count > 0;
    } catch (e) {
      AppLogger.error('Failed to update manga', error: e, tag: 'MangaRepository');
      return false;
    }
  }

  Future<bool> deleteManga(String id) async {
    try {
      final db = await _dbHelper.database;

      final count = await db.delete(
        'manga',
        where: 'id = ?',
        whereArgs: [id],
      );

      AppLogger.info('Manga deleted: $id', tag: 'MangaRepository');
      return count > 0;
    } catch (e) {
      AppLogger.error('Failed to delete manga', error: e, tag: 'MangaRepository');
      return false;
    }
  }

  Future<List<Manga>> searchManga(String query) async {
    try {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'manga',
        where: 'title LIKE ? OR author LIKE ? OR tags LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'title ASC',
      );

      return maps.map((map) => MangaModel.fromMap(map).toEntity()).toList();
    } catch (e) {
      AppLogger.error('Failed to search manga', error: e, tag: 'MangaRepository');
      return [];
    }
  }

  Future<int> getMangaCount() async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery('SELECT COUNT(*) as count FROM manga');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      AppLogger.error('Failed to get manga count', error: e, tag: 'MangaRepository');
      return 0;
    }
  }

  Future<void> clearAll() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('manga');
      AppLogger.info('All manga cleared', tag: 'MangaRepository');
    } catch (e) {
      AppLogger.error('Failed to clear all manga', error: e, tag: 'MangaRepository');
    }
  }
}
