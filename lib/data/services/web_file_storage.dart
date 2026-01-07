import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/manga.dart';

/// Simple in-memory storage for web file blobs
/// In a real app, you'd use IndexedDB for persistent storage
class WebFileStorage {
  WebFileStorage._();

  static final Map<String, Uint8List> _fileStorage = {};
  static final Map<String, Manga> _mangaIndex = {};

  static String storeFile(String fileName, Uint8List bytes) {
    final fileId = '${fileName}_${DateTime.now().millisecondsSinceEpoch}';
    _fileStorage[fileId] = bytes;
    return fileId;
  }

  static void storeFileWithId(String fileId, Uint8List bytes) {
    _fileStorage[fileId] = bytes;
  }

  static Uint8List? getFile(String fileId) {
    return _fileStorage[fileId];
  }

  static void indexManga(String fileId, Manga manga) {
    _mangaIndex[fileId] = manga;
  }

  static Manga? getManga(String fileId) {
    return _mangaIndex[fileId];
  }

  static List<Manga> getAllManga() {
    return _mangaIndex.values.toList();
  }

  static void removeManga(String fileId) {
    _fileStorage.remove(fileId);
    _mangaIndex.remove(fileId);
  }

  static void clear() {
    _fileStorage.clear();
    _mangaIndex.clear();
  }
}

final webFileStorageProvider = Provider<WebFileStorage>((ref) {
  return WebFileStorage._();
});
