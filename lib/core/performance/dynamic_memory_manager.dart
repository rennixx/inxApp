import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Dynamic memory manager with adaptive strategies
class DynamicMemoryManager {
  static final DynamicMemoryManager _instance = DynamicMemoryManager._internal();
  factory DynamicMemoryManager() => _instance;
  DynamicMemoryManager._internal() {
    _initialize();
  }

  static const MethodChannel _platform = MethodChannel('com.inx/memory');

  // Device memory classification
  DeviceMemoryClass _memoryClass = DeviceMemoryClass.medium;
  int _deviceRAMMB = 2048;

  // Cache configuration
  late int _maxImageCacheSize;
  late int _maxPreloadPages;
  late int _maxPagesAhead;
  late int _maxPagesBehind;

  // Page tracking
  final Map<String, List<int>> _loadedPages = {};
  final Map<String, int> _currentPage = {};

  // GPU texture recycling
  final List<GPUTextureHolder> _texturePool = [];
  static const int _maxTexturePoolSize = 10;

  // Leak detection
  final Map<String, _TrackedObject> _trackedObjects = {};
  Timer? _leakDetectionTimer;

  /// Initialize memory manager
  void _initialize() async {
    await _detectDeviceMemory();
    _configureForMemoryClass();
    _startLeakDetection();
  }

  /// Detect device memory
  Future<void> _detectDeviceMemory() async {
    try {
      final result = await _platform.invokeMethod('getDeviceMemory');
      if (result != null) {
        _deviceRAMMB = result['ramMB'] as int;
        _memoryClass = _classifyMemory(_deviceRAMMB);
      }
    } catch (e) {
      // Default to medium if detection fails
      _deviceRAMMB = 2048;
      _memoryClass = DeviceMemoryClass.medium;
    }
  }

  /// Classify device memory
  DeviceMemoryClass _classifyMemory(int ramMB) {
    if (ramMB < 2048) return DeviceMemoryClass.low;
    if (ramMB < 4096) return DeviceMemoryClass.medium;
    if (ramMB < 6144) return DeviceMemoryClass.high;
    return DeviceMemoryClass.ultra;
  }

  /// Configure cache settings based on memory class
  void _configureForMemoryClass() {
    switch (_memoryClass) {
      case DeviceMemoryClass.low:
        _maxImageCacheSize = 50 * 1024 * 1024; // 50MB
        _maxPreloadPages = 3;
        _maxPagesAhead = 1;
        _maxPagesBehind = 1;
        break;
      case DeviceMemoryClass.medium:
        _maxImageCacheSize = 100 * 1024 * 1024; // 100MB
        _maxPreloadPages = 5;
        _maxPagesAhead = 2;
        _maxPagesBehind = 2;
        break;
      case DeviceMemoryClass.high:
        _maxImageCacheSize = 200 * 1024 * 1024; // 200MB
        _maxPreloadPages = 7;
        _maxPagesAhead = 3;
        _maxPagesBehind = 3;
        break;
      case DeviceMemoryClass.ultra:
        _maxImageCacheSize = 400 * 1024 * 1024; // 400MB
        _maxPreloadPages = 10;
        _maxPagesAhead = 4;
        _maxPagesBehind = 4;
        break;
    }
  }

  /// Update current page and unload old pages
  void updateCurrentPage(String mangaId, int pageNumber) {
    _currentPage[mangaId] = pageNumber;

    // Unload pages outside the keep range
    final loaded = _loadedPages[mangaId] ?? [];
    final pagesToKeep = <int>[];

    for (final page in loaded) {
      final diff = (page - pageNumber).abs();
      if (diff <= _maxPagesBehind || diff <= _maxPagesAhead) {
        pagesToKeep.add(page);
      } else {
        _unloadPage(mangaId, page);
      }
    }

    _loadedPages[mangaId] = pagesToKeep;
  }

  /// Load page into memory
  Future<void> loadPage(String mangaId, int pageNumber, ui.Image image) async {
    if (!_loadedPages.containsKey(mangaId)) {
      _loadedPages[mangaId] = [];
    }

    if (!_loadedPages[mangaId]!.contains(pageNumber)) {
      _loadedPages[mangaId]!.add(pageNumber);

      // Track the image for leak detection
      trackObject('page_${mangaId}_$pageNumber', _ImageWrapper(image));
    }
  }

  /// Unload page from memory
  void _unloadPage(String mangaId, int pageNumber) {
    disposeObject('page_${mangaId}_$pageNumber');
    _loadedPages[mangaId]?.remove(pageNumber);
  }

  /// Get pages to preload
  List<int> getPagesToPreload(String mangaId, int currentPage) {
    final current = _currentPage[mangaId] ?? currentPage;
    final loaded = _loadedPages[mangaId] ?? [];
    final toPreload = <int>[];

    // Check pages ahead
    for (int i = 1; i <= _maxPagesAhead; i++) {
      final page = current + i;
      if (!loaded.contains(page)) {
        toPreload.add(page);
      }
    }

    // Check pages behind
    for (int i = 1; i <= _maxPagesBehind; i++) {
      final page = current - i;
      if (page > 0 && !loaded.contains(page)) {
        toPreload.add(page);
      }
    }

    return toPreload;
  }

  /// Get or create GPU texture holder
  GPUTextureHolder getTextureHolder() {
    if (_texturePool.isNotEmpty) {
      return _texturePool.removeLast();
    }
    return GPUTextureHolder();
  }

  /// Recycle GPU texture holder
  void recycleTextureHolder(GPUTextureHolder holder) {
    if (_texturePool.length < _maxTexturePoolSize) {
      holder.reset();
      _texturePool.add(holder);
    } else {
      holder.dispose();
    }
  }

  /// Track object for leak detection
  void trackObject(String key, dynamic object) {
    _trackedObjects[key] = _TrackedObject(object, DateTime.now());
  }

  /// Dispose tracked object
  void disposeObject(String key) {
    final tracked = _trackedObjects.remove(key);
    if (tracked != null) {
      tracked.dispose();
    }
  }

  /// Detect memory leaks
  void _startLeakDetection() {
    _leakDetectionTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _detectLeaks();
    });
  }

  /// Detect potential leaks
  void _detectLeaks() {
    final now = DateTime.now();
    final threshold = const Duration(minutes: 10);

    for (final entry in _trackedObjects.entries) {
      final age = now.difference(entry.value.createdAt);
      if (age > threshold) {
        // Potential leak - consider disposing
        // In production, log or report this
      }
    }
  }

  /// Force cleanup
  void forceCleanup() {
    // Dispose all tracked objects
    for (final key in _trackedObjects.keys.toList()) {
      disposeObject(key);
    }

    // Clear texture pool
    for (final holder in _texturePool) {
      holder.dispose();
    }
    _texturePool.clear();

    // Clear loaded pages
    _loadedPages.clear();
    _currentPage.clear();
  }

  /// Get memory statistics
  MemoryStatistics getStatistics() {
    return MemoryStatistics(
      memoryClass: _memoryClass,
      deviceRAMMB: _deviceRAMMB,
      maxImageCacheSize: _maxImageCacheSize,
      maxPreloadPages: _maxPreloadPages,
      maxPagesAhead: _maxPagesAhead,
      maxPagesBehind: _maxPagesBehind,
      trackedObjects: _trackedObjects.length,
      texturePoolSize: _texturePool.length,
      loadedPagesCount: _loadedPages.values.fold(0, (sum, list) => sum + list.length),
    );
  }

  /// Dispose resources
  void dispose() {
    _leakDetectionTimer?.cancel();
    forceCleanup();
  }
}

/// Device memory class
enum DeviceMemoryClass {
  low,
  medium,
  high,
  ultra,
}

/// Memory statistics
class MemoryStatistics {
  final DeviceMemoryClass memoryClass;
  final int deviceRAMMB;
  final int maxImageCacheSize;
  final int maxPreloadPages;
  final int maxPagesAhead;
  final int maxPagesBehind;
  final int trackedObjects;
  final int texturePoolSize;
  final int loadedPagesCount;

  MemoryStatistics({
    required this.memoryClass,
    required this.deviceRAMMB,
    required this.maxImageCacheSize,
    required this.maxPreloadPages,
    required this.maxPagesAhead,
    required this.maxPagesBehind,
    required this.trackedObjects,
    required this.texturePoolSize,
    required this.loadedPagesCount,
  });

  String get memoryClassLabel {
    switch (memoryClass) {
      case DeviceMemoryClass.low: return 'Low';
      case DeviceMemoryClass.medium: return 'Medium';
      case DeviceMemoryClass.high: return 'High';
      case DeviceMemoryClass.ultra: return 'Ultra';
    }
  }

  String get maxImageCacheFormatted {
    if (maxImageCacheSize < 1024 * 1024) {
      return '${(maxImageCacheSize / 1024).toStringAsFixed(0)} KB';
    } else {
      return '${(maxImageCacheSize / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
  }

  Map<String, dynamic> toJson() => {
    'memoryClass': memoryClassLabel,
    'deviceRAMMB': deviceRAMMB,
    'maxImageCacheSize': maxImageCacheFormatted,
    'maxPreloadPages': maxPreloadPages,
    'maxPagesAhead': maxPagesAhead,
    'maxPagesBehind': maxPagesBehind,
    'trackedObjects': trackedObjects,
    'texturePoolSize': texturePoolSize,
    'loadedPagesCount': loadedPagesCount,
  };
}

/// GPU texture holder for recycling
class GPUTextureHolder {
  ui.Image? texture;

  void reset() {
    texture?.dispose();
    texture = null;
  }

  void dispose() {
    texture?.dispose();
  }
}

/// Tracked object for leak detection
class _TrackedObject {
  final dynamic object;
  final DateTime createdAt;

  _TrackedObject(this.object, this.createdAt);

  void dispose() {
    if (object is _ImageWrapper) {
      object.dispose();
    }
  }
}

/// Image wrapper for tracking
class _ImageWrapper {
  final ui.Image image;

  _ImageWrapper(this.image);

  void dispose() {
    image.dispose();
  }
}
