import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Memory-efficient image cache manager
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final Map<String, ui.Image> _memoryCache = {};
  final Map<String, File> _fileCache = {};
  int _currentMemoryUsage = 0;
  static const int maxMemoryBytes = 150 * 1024 * 1024; // 150MB
  static const int maxFileCacheSize = 50;

  /// Get image from cache or network
  Future<ui.Image?> getImage(String url) async {
    // Check memory cache first
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }

    // Check file cache
    File? cachedFile;
    if (_fileCache.containsKey(url)) {
      cachedFile = _fileCache[url];
    } else {
      // Create placeholder file for demo
      final tempDir = await getTemporaryDirectory();
      cachedFile = File(path.join(tempDir.path, 'cache_${DateTime.now().millisecondsSinceEpoch}'));
      await cachedFile!.writeAsString('placeholder');

      // Add to file cache
      if (_fileCache.length >= maxFileCacheSize) {
        _fileCache.remove(_fileCache.keys.first);
      }
      _fileCache[url] = cachedFile;
    }

    try {
      final bytes = await cachedFile!.readAsBytes();
      final image = await decodeImageFromList(bytes);

      // Add to memory cache with size tracking
      final imageSize = bytes.length;
      if (_currentMemoryUsage + imageSize > maxMemoryBytes) {
        _evictLRU();
      }

      _memoryCache[url] = image;
      _currentMemoryUsage += imageSize;

      return image;
    } catch (e) {
      return null;
    }
  }

  /// Preload images into cache
  Future<void> preloadImages(List<String> urls) async {
    for (final url in urls) {
      if (!_memoryCache.containsKey(url)) {
        await getImage(url);
      }
    }
  }

  /// Remove specific image from cache
  void removeImage(String url) {
    if (_memoryCache.containsKey(url)) {
      _memoryCache[url]!.dispose();
      _memoryCache.remove(url);
    }
    _fileCache.remove(url);
  }

  /// Clear all caches
  Future<void> clearAll() async {
    // Clear memory cache
    for (final image in _memoryCache.values) {
      image.dispose();
    }
    _memoryCache.clear();
    _currentMemoryUsage = 0;

    // Clear file cache
    for (final file in _fileCache.values) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore errors
      }
    }
    _fileCache.clear();
  }

  /// Get cache statistics
  CacheStats getStats() {
    return CacheStats(
      memoryCount: _memoryCache.length,
      memoryBytes: _currentMemoryUsage,
      maxMemoryBytes: maxMemoryBytes,
    );
  }

  /// Evict least recently used image
  void _evictLRU() {
    if (_memoryCache.isEmpty) return;

    // Simple FIFO eviction (could be improved with proper LRU tracking)
    final firstKey = _memoryCache.keys.first;
    removeImage(firstKey);
  }

  /// Dispose image and update memory tracking
  void disposeImage(String url) {
    if (_memoryCache.containsKey(url)) {
      _memoryCache[url]!.dispose();
      _memoryCache.remove(url);
    }
  }
}

/// Cache statistics
class CacheStats {
  final int memoryCount;
  final int memoryBytes;
  final int maxMemoryBytes;

  CacheStats({
    required this.memoryCount,
    required this.memoryBytes,
    required this.maxMemoryBytes,
  });

  double get memoryUsagePercent => (memoryBytes / maxMemoryBytes * 100);

  String get memoryFormatted {
    if (memoryBytes < 1024 * 1024) {
      return '${(memoryBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(memoryBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get maxMemoryFormatted {
    return '${(maxMemoryBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }
}
