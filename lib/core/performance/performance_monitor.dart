import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../performance/battery_optimizer.dart';
import '../performance/memory_manager.dart';

/// Performance monitoring service with metrics collection
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Metrics
  final List<FrameMetrics> _frameMetrics = [];
  final List<TranslationMetrics> _translationMetrics = [];
  final List<MemorySnapshot> _memorySnapshots = [];

  // Monitoring state
  bool _isMonitoring = false;
  Timer? _metricsTimer;
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  double _currentFPS = 60.0;
  int _droppedFrames = 0;

  // Debug mode
  bool _showFPS = false;
  bool _showMemory = false;
  OverlayEntry? _fpsOverlay;

  /// Start monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _lastFrameTime = DateTime.now();
    _startFrameTracking();
    _startMetricsCollection();
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _metricsTimer?.cancel();
    _fpsOverlay?.remove();
    _fpsOverlay = null;
  }

  /// Toggle FPS overlay (debug mode)
  void toggleFPSOverlay(BuildContext context) {
    _showFPS = !_showFPS;

    if (_showFPS) {
      _fpsOverlay = OverlayEntry(
        builder: (context) => _FPSOverlayWidget(monitor: this),
      );
      Overlay.of(context).insert(_fpsOverlay!);
    } else {
      _fpsOverlay?.remove();
      _fpsOverlay = null;
    }
  }

  /// Toggle memory display
  void toggleMemoryDisplay() {
    _showMemory = !_showMemory;
  }

  /// Record frame time
  void recordFrame() {
    if (!_isMonitoring) return;

    final now = DateTime.now();
    final frameTime = _lastFrameTime != null
        ? now.difference(_lastFrameTime!).inMicroseconds / 1000.0
        : 16.67; // Default to 60fps

    _lastFrameTime = now;
    _frameCount++;

    // Detect dropped frames
    if (frameTime > 33.33) { // More than 30fps threshold
      _droppedFrames++;
    }

    // Update FPS calculation
    if (_frameCount >= 60) {
      _calculateFPS();
      _frameCount = 0;
      _droppedFrames = 0;
    }
  }

  /// Record translation metrics
  void recordTranslation(String mangaId, int pageCount, Duration duration) {
    final metrics = TranslationMetrics(
      mangaId: mangaId,
      pageCount: pageCount,
      duration: duration,
      timestamp: DateTime.now(),
      avgTimePerPage: duration.inMilliseconds / pageCount,
    );

    _translationMetrics.add(metrics);

    // Keep only last 100 translations
    if (_translationMetrics.length > 100) {
      _translationMetrics.removeAt(0);
    }
  }

  /// Get performance summary
  PerformanceSummary getSummary() {
    return PerformanceSummary(
      currentFPS: _currentFPS,
      avgFPS: _calculateAverageFPS(),
      droppedFrames: _droppedFrames,
      memoryUsage: MemoryManager().getMemoryInfo(),
      powerStatus: BatteryOptimizer().getPowerStatus(),
      translationStats: _getTranslationStats(),
    );
  }

  /// Get current FPS
  double get currentFPS => _currentFPS;

  /// Start frame tracking
  void _startFrameTracking() {
    // Hook into Flutter's frame callbacks
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      recordFrame();
    });
  }

  /// Start metrics collection
  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _collectMetrics();
    });
  }

  /// Collect metrics snapshot
  void _collectMetrics() {
    final memoryInfo = MemoryManager().getMemoryInfo();

    _memorySnapshots.add(MemorySnapshot(
      timestamp: DateTime.now(),
      memoryMB: memoryInfo.currentMB,
      trackedObjects: memoryInfo.trackedObjects,
      activeTranslations: memoryInfo.activeTranslations,
    ));

    // Keep only last 100 snapshots
    if (_memorySnapshots.length > 100) {
      _memorySnapshots.removeAt(0);
    }
  }

  /// Calculate FPS
  void _calculateFPS() {
    final sample = _frameMetrics.take(60).toList();
    if (sample.isEmpty) return;

    final totalFrameTime = sample.fold<double>(
      0.0,
      (sum, metric) => sum + metric.frameTime,
    );

    _currentFPS = 1000.0 / (totalFrameTime / sample.length);
  }

  /// Calculate average FPS
  double _calculateAverageFPS() {
    if (_frameMetrics.isEmpty) return 60.0;

    final totalFrameTime = _frameMetrics.fold<double>(
      0.0,
      (sum, metric) => sum + metric.frameTime,
    );

    return 1000.0 / (totalFrameTime / _frameMetrics.length);
  }

  /// Get translation statistics
  TranslationStats _getTranslationStats() {
    if (_translationMetrics.isEmpty) {
      return TranslationStats(
        totalTranslations: 0,
        totalPagesTranslated: 0,
        avgTimePerPage: 0.0,
        totalDuration: Duration.zero,
      );
    }

    final totalPages = _translationMetrics.fold<int>(
      0,
      (sum, m) => sum + m.pageCount,
    );

    final totalDuration = _translationMetrics.fold<Duration>(
      Duration.zero,
      (sum, m) => sum + m.duration,
    );

    final avgTime = _translationMetrics
            .fold<double>(0.0, (sum, m) => sum + m.avgTimePerPage) /
        _translationMetrics.length;

    return TranslationStats(
      totalTranslations: _translationMetrics.length,
      totalPagesTranslated: totalPages,
      avgTimePerPage: avgTime,
      totalDuration: totalDuration,
    );
  }

  /// Export metrics as JSON
  String exportMetrics() {
    final data = {
      'summary': getSummary().toJson(),
      'frames': _frameMetrics.take(100).map((m) => m.toJson()).toList(),
      'translations': _translationMetrics.map((m) => m.toJson()).toList(),
      'memory': _memorySnapshots.take(100).map((m) => m.toJson()).toList(),
    };

    return jsonEncode(data);
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _frameMetrics.clear();
    _translationMetrics.clear();
    _memorySnapshots.clear();
  }
}

/// Frame metrics
class FrameMetrics {
  final DateTime timestamp;
  final double frameTime; // in milliseconds

  FrameMetrics({
    required this.timestamp,
    required this.frameTime,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'frameTime': frameTime,
  };
}

/// Translation metrics
class TranslationMetrics {
  final String mangaId;
  final int pageCount;
  final Duration duration;
  final DateTime timestamp;
  final double avgTimePerPage;

  TranslationMetrics({
    required this.mangaId,
    required this.pageCount,
    required this.duration,
    required this.timestamp,
    required this.avgTimePerPage,
  });

  Map<String, dynamic> toJson() => {
    'mangaId': mangaId,
    'pageCount': pageCount,
    'duration': duration.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
    'avgTimePerPage': avgTimePerPage,
  };
}

/// Memory snapshot
class MemorySnapshot {
  final DateTime timestamp;
  final int memoryMB;
  final int trackedObjects;
  final int activeTranslations;

  MemorySnapshot({
    required this.timestamp,
    required this.memoryMB,
    required this.trackedObjects,
    required this.activeTranslations,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'memoryMB': memoryMB,
    'trackedObjects': trackedObjects,
    'activeTranslations': activeTranslations,
  };
}

/// Performance summary
class PerformanceSummary {
  final double currentFPS;
  final double avgFPS;
  final int droppedFrames;
  final MemoryUsageInfo memoryUsage;
  final PowerStatus powerStatus;
  final TranslationStats translationStats;

  PerformanceSummary({
    required this.currentFPS,
    required this.avgFPS,
    required this.droppedFrames,
    required this.memoryUsage,
    required this.powerStatus,
    required this.translationStats,
  });

  Map<String, dynamic> toJson() => {
    'currentFPS': currentFPS,
    'avgFPS': avgFPS,
    'droppedFrames': droppedFrames,
    'memoryUsage': memoryUsage.currentMB,
    'powerMode': powerStatus.modeLabel,
    'totalTranslations': translationStats.totalTranslations,
    'avgTranslationTime': translationStats.avgTimePerPage,
  };
}

/// Translation statistics
class TranslationStats {
  final int totalTranslations;
  final int totalPagesTranslated;
  final double avgTimePerPage;
  final Duration totalDuration;

  TranslationStats({
    required this.totalTranslations,
    required this.totalPagesTranslated,
    required this.avgTimePerPage,
    required this.totalDuration,
  });

  String get avgTimeFormatted => '${avgTimePerPage.toStringAsFixed(0)}ms';
  String get totalDurationFormatted {
    if (totalDuration.inHours > 0) {
      return '${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m';
    } else if (totalDuration.inMinutes > 0) {
      return '${totalDuration.inMinutes}m ${totalDuration.inSeconds % 60}s';
    } else {
      return '${totalDuration.inSeconds}s';
    }
  }
}

/// FPS overlay widget
class _FPSOverlayWidget extends StatelessWidget {
  final PerformanceMonitor monitor;

  const _FPSOverlayWidget({required this.monitor});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      right: 16,
      child: StreamBuilder<PerformanceSummary>(
        stream: Stream.periodic(
          const Duration(seconds: 1),
          (_) => monitor.getSummary(),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final summary = snapshot.data!;
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${summary.currentFPS.toStringAsFixed(1)} FPS',
                  style: TextStyle(
                    color: _getFPSColor(summary.currentFPS),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${summary.memoryUsage.usageFormatted}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
                Text(
                  summary.powerStatus.modeLabel,
                  style: TextStyle(
                    color: summary.powerStatus.isPowerSavingMode
                        ? Colors.orange
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.yellow;
    return Colors.red;
  }
}

/// Crash reporting service (basic implementation)
class CrashReporter {
  static final CrashReporter _instance = CrashReporter._internal();
  factory CrashReporter() => _instance;
  CrashReporter._internal();

  final List<CrashReport> _crashReports = [];

  /// Report error
  void reportError(dynamic error, StackTrace stackTrace, {Map<String, dynamic>? context}) {
    final report = CrashReport(
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      timestamp: DateTime.now(),
      context: context,
      performanceData: PerformanceMonitor().getSummary(),
    );

    _crashReports.add(report);

    // In production, send to crash reporting service
    developer.log('Error reported: $error');
  }

  /// Get all crash reports
  List<CrashReport> getReports() => List.from(_crashReports);

  /// Clear reports
  void clearReports() {
    _crashReports.clear();
  }
}

/// Crash report
class CrashReport {
  final String error;
  final String stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  final PerformanceSummary performanceData;

  CrashReport({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    this.context,
    required this.performanceData,
  });

  Map<String, dynamic> toJson() => {
    'error': error,
    'stackTrace': stackTrace,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
    'performance': performanceData.toJson(),
  };
}
