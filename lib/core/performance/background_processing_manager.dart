import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Background processing manager with battery and thermal awareness
class BackgroundProcessingManager {
  static final BackgroundProcessingManager _instance = BackgroundProcessingManager._internal();
  factory BackgroundProcessingManager() => _instance;
  BackgroundProcessingManager._internal();

  static const MethodChannel _platform = MethodChannel('com.inx/background');

  // Battery state
  double _batteryLevel = 100.0;
  bool _isCharging = false;
  StreamSubscription? _batterySubscription;

  // Thermal state
  ThermalState _thermalState = ThermalState.nominal;
  StreamSubscription? _thermalSubscription;

  // Task queue
  final List<BackgroundTask> _taskQueue = [];
  bool _isProcessing = false;
  Timer? _processingTimer;

  // Configuration
  static const double minBatteryForProcessing = 50.0;
  static const Duration processingInterval = Duration(minutes: 15);

  /// Initialize background processing
  Future<void> initialize() async {
    await _updateBatteryState();
    await _updateThermalState();
    _startPeriodicChecks();
  }

  /// Add task to queue
  void enqueueTask(BackgroundTask task) {
    _taskQueue.add(task);
    _taskQueue.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    _tryProcessNextTask();
  }

  /// Process task immediately if conditions allow
  Future<bool> processTaskNow(BackgroundTask task) async {
    if (!canProcessTasks()) {
      return false;
    }

    try {
      await task.execute();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if tasks can be processed
  bool canProcessTasks() {
    if (_thermalState == ThermalState.critical || _thermalState == ThermalState.serious) {
      return false; // Don't process when device is hot
    }

    if (!_isCharging && _batteryLevel < minBatteryForProcessing) {
      return false; // Don't process when battery is low
    }

    return true;
  }

  /// Get current battery level
  double get batteryLevel => _batteryLevel;

  /// Get charging state
  bool get isCharging => _isCharging;

  /// Get thermal state
  ThermalState get thermalState => _thermalState;

  /// Get queue size
  int get queueSize => _taskQueue.length;

  /// Update battery state from platform
  Future<void> _updateBatteryState() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _platform.invokeMethod('getBatteryState');
        if (result != null) {
          _batteryLevel = (result['level'] as num).toDouble();
          _isCharging = result['isCharging'] as bool;
        }
      }
    } catch (e) {
      // Default values if platform call fails
      _batteryLevel = 100.0;
      _isCharging = false;
    }
  }

  /// Update thermal state from platform
  Future<void> _updateThermalState() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final state = await _platform.invokeMethod('getThermalState');
        if (state != null) {
          _thermalState = ThermalState.values[state as int];
        }
      }
    } catch (e) {
      _thermalState = ThermalState.nominal;
    }
  }

  /// Start periodic checks
  void _startPeriodicChecks() {
    _processingTimer = Timer.periodic(processingInterval, (_) async {
      await _updateBatteryState();
      await _updateThermalState();
      _tryProcessNextTask();
    });
  }

  /// Try to process next task
  void _tryProcessNextTask() {
    if (_isProcessing || _taskQueue.isEmpty) {
      return;
    }

    if (!canProcessTasks()) {
      return; // Wait for better conditions
    }

    _isProcessing = true;
    final task = _taskQueue.removeAt(0);

    task.execute().then((_) {
      _isProcessing = false;
      _tryProcessNextTask(); // Process next task
    }).catchError((e) {
      _isProcessing = false;
      // Re-queue failed tasks with lower priority
      if (task.retryCount < task.maxRetries) {
        task.retryCount++;
        _taskQueue.add(task);
      }
    });
  }

  /// Dispose resources
  void dispose() {
    _processingTimer?.cancel();
    _batterySubscription?.cancel();
    _thermalSubscription?.cancel();
    _taskQueue.clear();
  }
}

/// Background task
abstract class BackgroundTask {
  final TaskPriority priority;
  final int maxRetries;
  int retryCount = 0;

  BackgroundTask({
    this.priority = TaskPriority.normal,
    this.maxRetries = 3,
  });

  Future<void> execute();
}

/// Task priority
enum TaskPriority {
  low,
  normal,
  high,
  critical,
}

/// Thermal state
enum ThermalState {
  nominal,
  fair,
  serious,
  critical,
}

/// Preload manga pages task
class PreloadPagesTask extends BackgroundTask {
  final String mangaId;
  final List<String> pageUrls;
  final int startPage;
  final int pageCount;

  PreloadPagesTask({
    required this.mangaId,
    required this.pageUrls,
    required this.startPage,
    required this.pageCount,
    super.priority = TaskPriority.normal,
  });

  @override
  Future<void> execute() async {
    // Preload pages from startPage to startPage + pageCount
    // Implementation would call image cache manager
    await Future.delayed(Duration(milliseconds: pageCount * 100));
  }
}

/// Cache cleanup task
class CacheCleanupTask extends BackgroundTask {
  final int percentageToClean;

  CacheCleanupTask({
    this.percentageToClean = 20,
    super.priority = TaskPriority.low,
  });

  @override
  Future<void> execute() async {
    // Implementation would clean up cache
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

/// Translation task
class TranslationTask extends BackgroundTask {
  final String mangaId;
  final int pageNumber;
  final String imageUrl;

  TranslationTask({
    required this.mangaId,
    required this.pageNumber,
    required this.imageUrl,
    super.priority = TaskPriority.high,
  });

  @override
  Future<void> execute() async {
    // Implementation would perform translation
    await Future.delayed(const Duration(seconds: 2));
  }
}
