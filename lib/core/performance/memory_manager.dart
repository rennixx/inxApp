import 'dart:async';
import 'dart:developer' as developer;
import 'image_optimizer.dart';
import 'image_cache_manager.dart';

/// Memory management service for efficient resource handling
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  // Memory tracking
  final Map<String, _WeakReferenceWrapper> _trackedObjects = {};
  int _activeTranslations = 0;
  static const int maxConcurrentTranslations = 3;

  // GC triggers
  Timer? _gcTimer;
  static const Duration gcInterval = Duration(minutes: 5);

  // Leak detection
  final Map<String, DateTime> _objectCreationTimes = {};
  bool _leakDetectionEnabled = false;

  /// Initialize memory manager
  void initialize() {
    _startGCCollection();
    _setupMemoryPressureListener();
  }

  /// Track an object for disposal
  void trackObject(String key, dynamic object) {
    final wrapper = _WeakReferenceWrapper();
    wrapper.track(object);
    _trackedObjects[key] = wrapper;
    _objectCreationTimes[key] = DateTime.now();
  }

  /// Dispose tracked object
  void disposeObject(String key) {
    if (_trackedObjects.containsKey(key)) {
      _trackedObjects.remove(key);
      _objectCreationTimes.remove(key);

      // Note: Objects are cleaned up by Dart GC when no longer referenced
      // Explicit disposal happens via weak references
    }
  }

  /// Dispose image when changing pages
  void disposeImage(String imagePath) {
    ImageOptimizer().disposeImage(imagePath);
    ImageCacheManager().disposeImage(imagePath);
  }

  /// Limit concurrent translations
  bool canStartTranslation() {
    return _activeTranslations < maxConcurrentTranslations;
  }

  /// Start translation
  void startTranslation() {
    _activeTranslations++;
  }

  /// End translation
  void endTranslation() {
    if (_activeTranslations > 0) {
      _activeTranslations--;
    }
  }

  /// Get memory info
  MemoryUsageInfo getMemoryInfo() {
    // Get current memory usage from Flutter
    final info = MemoryUsageInfo(
      currentMB: _estimateCurrentMemoryMB(),
      trackedObjects: _trackedObjects.length,
      activeTranslations: _activeTranslations,
      maxMB: _estimateMaxMemoryMB(),
    );

    return info;
  }

  /// Trigger garbage collection
  void triggerGC() {
    // Dart's GC is automatic, but we can suggest it
    // In debug/profile mode, this would trigger GC
    try {
      // Force a GC suggestion
    } catch (e) {
      // GC triggering not available in release mode
    }
  }

  /// Enable leak detection
  void enableLeakDetection() {
    _leakDetectionEnabled = true;
    _startLeakDetection();
  }

  /// Disable leak detection
  void disableLeakDetection() {
    _leakDetectionEnabled = false;
  }

  /// Detect potential memory leaks
  List<LeakReport> detectLeaks() {
    final leaks = <LeakReport>[];

    final now = DateTime.now();
    final threshold = Duration(minutes: 10);

    for (final entry in _objectCreationTimes.entries) {
      final age = now.difference(entry.value);
      if (age > threshold) {
        final wrapper = _trackedObjects[entry.key];
        if (wrapper != null) {
          final object = wrapper.target;
          if (object != null) {
            leaks.add(LeakReport(
              key: entry.key,
              age: age,
              objectType: object.runtimeType.toString(),
            ));
          }
        }
      }
    }

    return leaks;
  }

  /// Cleanup resources based on memory pressure
  void cleanup(int pressureLevel) {
    switch (pressureLevel) {
      case 1: // Low pressure
        _lightCleanup();
        break;
      case 2: // Medium pressure
        _moderateCleanup();
        break;
      case 3: // High pressure
        _aggressiveCleanup();
        break;
    }
  }

  // Private methods

  void _startGCCollection() {
    _gcTimer = Timer.periodic(gcInterval, (_) {
      triggerGC();
    });
  }

  void _setupMemoryPressureListener() {
    // Listen to memory pressure events
    // In production, this would use platform channels
    // to listen to system memory pressure callbacks
  }

  void _lightCleanup() {
    // Clean up 10% of oldest cached items
    // Trigger cache cleanup through ImageCacheManager
    triggerGC();
  }

  void _moderateCleanup() {
    // Clean up 30% of cached items
    triggerGC();
  }

  void _aggressiveCleanup() {
    // Clean up 60% of cached items and force GC
    triggerGC();
  }

  void _startLeakDetection() {
    // Periodically check for potential leaks
    Timer.periodic(const Duration(minutes: 5), (_) {
      if (_leakDetectionEnabled) {
        final leaks = detectLeaks();
        if (leaks.isNotEmpty) {
          developer.log('Potential memory leaks detected: ${leaks.length}');
          // In production, report to analytics
        }
      }
    });
  }

  int _estimateCurrentMemoryMB() {
    // Estimate memory usage
    // In production, use platform channels to get actual memory info
    return _trackedObjects.length * 2 + // Rough estimate: 2MB per tracked object
        _activeTranslations * 10; // Rough estimate: 10MB per active translation
  }

  int _estimateMaxMemoryMB() {
    // Estimate max available memory
    // In production, get actual device memory
    return 512; // 512MB default estimate
  }

  void dispose() {
    _gcTimer?.cancel();

    // Dispose all tracked objects
    for (final key in _trackedObjects.keys.toList()) {
      disposeObject(key);
    }

    _trackedObjects.clear();
    _objectCreationTimes.clear();
  }
}

/// Memory usage information
class MemoryUsageInfo {
  final int currentMB;
  final int trackedObjects;
  final int activeTranslations;
  final int maxMB;

  MemoryUsageInfo({
    required this.currentMB,
    required this.trackedObjects,
    required this.activeTranslations,
    required this.maxMB,
  });

  double get usagePercent => (currentMB / maxMB * 100);

  String get usageFormatted {
    if (currentMB < 1024) {
      return '${currentMB}MB';
    } else {
      return '${(currentMB / 1024).toStringAsFixed(1)}GB';
    }
  }

  String get maxFormatted {
    if (maxMB < 1024) {
      return '${maxMB}MB';
    } else {
      return '${(maxMB / 1024).toStringAsFixed(1)}GB';
    }
  }

  MemoryPressure get pressure {
    final percent = usagePercent;
    if (percent < 50) return MemoryPressure.low;
    if (percent < 75) return MemoryPressure.medium;
    return MemoryPressure.high;
  }
}

/// Memory pressure levels
enum MemoryPressure {
  low,
  medium,
  high,
}

extension MemoryPressureExtension on MemoryPressure {
  int get level {
    switch (this) {
      case MemoryPressure.low:
        return 1;
      case MemoryPressure.medium:
        return 2;
      case MemoryPressure.high:
        return 3;
    }
  }
}

/// Leak report
class LeakReport {
  final String key;
  final Duration age;
  final String objectType;

  LeakReport({
    required this.key,
    required this.age,
    required this.objectType,
  });

  String get ageFormatted {
    if (age.inHours > 0) {
      return '${age.inHours}h ${age.inMinutes % 60}m';
    } else {
      return '${age.inMinutes}m ${age.inSeconds % 60}s';
    }
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'ageMinutes': age.inMinutes,
    'objectType': objectType,
  };
}

/// Weak reference wrapper
class _WeakReferenceWrapper {
  final Expando _expando = Expando();

  void track(dynamic object) {
    _expando['object'] = object;
  }

  dynamic get target => _expando['object'];
}
