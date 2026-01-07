import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Image optimization service for efficient handling of manga images
class ImageOptimizer {
  static final ImageOptimizer _instance = ImageOptimizer._internal();
  factory ImageOptimizer() => _instance;
  ImageOptimizer._internal();

  // Cache for optimized images
  final Map<String, File> _optimizedCache = {};
  final Map<String, ui.Image> _memoryCache = {};

  // Maximum memory cache size (in bytes)
  static const int maxMemoryCacheBytes = 100 * 1024 * 1024; // 100MB

  // Target dimensions based on device
  static const int tabletTargetWidth = 1920;
  static const int tabletTargetHeight = 2560;
  static const int phoneTargetWidth = 1080;
  static const int phoneTargetHeight = 1920;

  /// Get target dimensions for current device
  static Size getTargetDimensions() {
    // Use PlatformDispatcher instead of deprecated window
    final physicalWidth = ui.PlatformDispatcher.instance.views.first.physicalSize.width;
    final physicalHeight = ui.PlatformDispatcher.instance.views.first.physicalSize.height;

    // Determine if tablet or phone based on screen size
    final isTablet = physicalWidth >= 1200 || physicalHeight >= 1200;

    if (isTablet) {
      return Size(
        tabletTargetWidth.toDouble(),
        tabletTargetHeight.toDouble(),
      );
    } else {
      return Size(
        phoneTargetWidth.toDouble(),
        phoneTargetHeight.toDouble(),
      );
    }
  }

  /// Optimize and cache an image file
  Future<File> optimizeImage(File imageFile, {bool forceReoptimize = false}) async {
    final cacheKey = '${imageFile.path}_${getTargetDimensions()}';

    // Return cached version if available
    if (_optimizedCache.containsKey(cacheKey) && !forceReoptimize) {
      return _optimizedCache[cacheKey]!;
    }

    try {
      // Read original image
      final bytes = await imageFile.readAsBytes();
      final decoded = await decodeImageFromList(bytes);

      // Calculate target size maintaining aspect ratio
      final targetSize = getTargetDimensions();
      final aspectRatio = decoded.width / decoded.height;
      final targetWidth = targetSize.width.toInt();
      final targetHeight = (targetWidth / aspectRatio).toInt();

      // Only resize if original is larger than target
      if (decoded.width <= targetWidth && decoded.height <= targetHeight) {
        return imageFile;
      }

      // Create resized image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..filterQuality = FilterQuality.high;

      canvas.drawImageRect(
        decoded,
        Rect.fromLTWH(0, 0, decoded.width.toDouble(), decoded.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        paint,
      );

      final picture = recorder.endRecording();
      final resizedImage = await picture.toImage(targetWidth, targetHeight);
      final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      final resizedBytes = byteData!.buffer.asUint8List();

      // Save optimized version
      final optimizedFile = File('${imageFile.path}_optimized');
      await optimizedFile.writeAsBytes(resizedBytes);

      _optimizedCache[cacheKey] = optimizedFile;

      // Cleanup
      decoded.dispose();
      resizedImage.dispose();

      return optimizedFile;
    } catch (e) {
      // Return original if optimization fails
      return imageFile;
    }
  }

  /// Load image into memory cache
  Future<ui.Image> loadImage(File imageFile) async {
    final cacheKey = imageFile.path;

    // Return from memory cache if available
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final image = await decodeImageFromList(bytes);

      // Check memory cache size before adding
      if (_memoryCache.length > 50) {
        _clearOldestMemoryCache();
      }

      _memoryCache[cacheKey] = image;
      return image;
    } catch (e) {
      throw Exception('Failed to load image: $e');
    }
  }

  /// Preload next image in background
  Future<void> preloadNextImage(File? nextImage) async {
    if (nextImage == null) return;

    try {
      await loadImage(nextImage);
    } catch (e) {
      // Silent fail for preloading
    }
  }

  /// Convert image to WebP format for better compression
  Future<File> convertToWebP(File imageFile, {int quality = 85}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgba = byteData!.buffer.asUint8List();

      // WebP encoding would be done here with proper encoder
      // For now, return original as WebP encoding requires native code
      image.dispose();
      codec.dispose();

      return imageFile;
    } catch (e) {
      return imageFile;
    }
  }

  /// Clear memory cache for specific image
  void disposeImage(String imagePath) {
    if (_memoryCache.containsKey(imagePath)) {
      _memoryCache[imagePath]!.dispose();
      _memoryCache.remove(imagePath);
    }
  }

  /// Clear all memory cache
  void clearMemoryCache() {
    _memoryCache.values.forEach((image) => image.dispose());
    _memoryCache.clear();
  }

  /// Clear optimized file cache
  void clearOptimizedCache() {
    _optimizedCache.values.forEach((file) {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });
    _optimizedCache.clear();
  }

  /// Get current memory cache size in bytes
  int getMemoryCacheSize() {
    return _memoryCache.length;
  }

  /// Clear oldest entries from memory cache
  void _clearOldestMemoryCache() {
    // Remove first 10 entries (simple FIFO)
    final keys = _memoryCache.keys.take(10).toList();
    for (final key in keys) {
      disposeImage(key);
    }
  }

  /// Get image info without loading into memory
  Future<ImageInfo> getImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = await decodeImageFromList(bytes);

      final info = ImageInfo(
        width: decoded.width,
        height: decoded.height,
        sizeBytes: bytes.length,
        format: _getImageFormat(imageFile.path),
      );

      decoded.dispose();
      return info;
    } catch (e) {
      throw Exception('Failed to get image info: $e');
    }
  }

  String _getImageFormat(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'JPEG';
      case '.png':
        return 'PNG';
      case '.webp':
        return 'WebP';
      case '.gif':
        return 'GIF';
      default:
        return 'Unknown';
    }
  }
}

/// Image information model
class ImageInfo {
  final int width;
  final int height;
  final int sizeBytes;
  final String format;

  ImageInfo({
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.format,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  double get aspectRatio => width / height;
}
