import 'dart:async';
import 'package:flutter/services.dart';
import 'background_processing_manager.dart';

/// Power profile manager with automatic mode switching
class PowerProfileManager {
  static final PowerProfileManager _instance = PowerProfileManager._internal();
  factory PowerProfileManager() => _instance;
  PowerProfileManager._internal() {
    _initialize();
  }

  static const MethodChannel _platform = MethodChannel('com.inx/power');

  // Current profile
  PowerProfile _currentProfile = PowerProfile.balanced;
  bool _autoSwitchEnabled = true;

  // Battery monitoring
  double _batteryLevel = 100.0;
  bool _isCharging = false;
  Timer? _batteryCheckTimer;

  // Profile change callbacks
  final List<Function(PowerProfile)> _profileChangeListeners = [];

  /// Initialize power profile manager
  void _initialize() async {
    await _updateBatteryState();
    _startBatteryMonitoring();
    _updateProfileBasedOnBattery();
  }

  /// Get current power profile
  PowerProfile get currentProfile => _currentProfile;

  /// Set power profile manually
  void setProfile(PowerProfile profile) {
    if (_currentProfile != profile) {
      _currentProfile = profile;
      _applyProfileSettings(profile);
      _notifyProfileChange(profile);
    }
  }

  /// Enable automatic profile switching
  void enableAutoSwitch() {
    _autoSwitchEnabled = true;
    _updateProfileBasedOnBattery();
  }

  /// Disable automatic profile switching
  void disableAutoSwitch() {
    _autoSwitchEnabled = false;
  }

  /// Add profile change listener
  void addProfileChangeListener(Function(PowerProfile) listener) {
    _profileChangeListeners.add(listener);
  }

  /// Remove profile change listener
  void removeProfileChangeListener(Function(PowerProfile) listener) {
    _profileChangeListeners.remove(listener);
  }

  /// Get image quality for current profile
  double get imageQuality {
    switch (_currentProfile) {
      case PowerProfile.batterySaver:
        return 0.6;
      case PowerProfile.dataSaver:
        return 0.7;
      case PowerProfile.balanced:
        return 0.85;
      case PowerProfile.performance:
        return 1.0;
    }
  }

  /// Get preload page count for current profile
  int get preloadPageCount {
    switch (_currentProfile) {
      case PowerProfile.batterySaver:
        return 1;
      case PowerProfile.dataSaver:
        return 2;
      case PowerProfile.balanced:
        return 3;
      case PowerProfile.performance:
        return 5;
    }
  }

  /// Get max concurrent translations for current profile
  int get maxConcurrentTranslations {
    switch (_currentProfile) {
      case PowerProfile.batterySaver:
        return 1;
      case PowerProfile.dataSaver:
        return 2;
      case PowerProfile.balanced:
        return 3;
      case PowerProfile.performance:
        return 5;
    }
  }

  /// Check if animations are enabled
  bool get animationsEnabled {
    return _currentProfile != PowerProfile.batterySaver;
  }

  /// Check if image compression is enabled
  bool get imageCompressionEnabled {
    return _currentProfile == PowerProfile.dataSaver;
  }

  /// Get compression quality
  int get compressionQuality {
    switch (_currentProfile) {
      case PowerProfile.dataSaver:
        return 70;
      case PowerProfile.batterySaver:
        return 80;
      case PowerProfile.balanced:
        return 90;
      case PowerProfile.performance:
        return 100;
    }
  }

  /// Update battery state
  Future<void> _updateBatteryState() async {
    try {
      final result = await _platform.invokeMethod('getBatteryState');
      if (result != null) {
        _batteryLevel = (result['level'] as num).toDouble();
        _isCharging = result['isCharging'] as bool;
      }
    } catch (e) {
      _batteryLevel = 100.0;
      _isCharging = false;
    }
  }

  /// Start battery monitoring
  void _startBatteryMonitoring() {
    _batteryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _updateBatteryState();
      if (_autoSwitchEnabled) {
        _updateProfileBasedOnBattery();
      }
    });
  }

  /// Update profile based on battery level
  void _updateProfileBasedOnBattery() {
    if (_isCharging) {
      // Use performance or balanced when charging
      setProfile(PowerProfile.performance);
    } else if (_batteryLevel <= 20) {
      // Critical battery level
      setProfile(PowerProfile.batterySaver);
    } else if (_batteryLevel <= 50) {
      // Medium battery level
      setProfile(PowerProfile.dataSaver);
    } else {
      // Good battery level
      setProfile(PowerProfile.balanced);
    }
  }

  /// Apply profile settings
  void _applyProfileSettings(PowerProfile profile) {
    // Apply settings to background processing manager
    BackgroundProcessingManager();

    switch (profile) {
      case PowerProfile.batterySaver:
        // Reduce background processing
        break;
      case PowerProfile.performance:
        // Increase background processing
        break;
      default:
        break;
    }

    // Apply other profile-specific settings
    // In production, this would update various subsystems
  }

  /// Notify profile change listeners
  void _notifyProfileChange(PowerProfile profile) {
    for (final listener in _profileChangeListeners) {
      try {
        listener(profile);
      } catch (e) {
        // Ignore listener errors
      }
    }
  }

  /// Get profile statistics
  ProfileStatistics getStatistics() {
    return ProfileStatistics(
      currentProfile: _currentProfile,
      batteryLevel: _batteryLevel,
      isCharging: _isCharging,
      autoSwitchEnabled: _autoSwitchEnabled,
      imageQuality: imageQuality,
      preloadPageCount: preloadPageCount,
      maxConcurrentTranslations: maxConcurrentTranslations,
      animationsEnabled: animationsEnabled,
      compressionEnabled: imageCompressionEnabled,
      compressionQuality: compressionQuality,
    );
  }

  /// Dispose resources
  void dispose() {
    _batteryCheckTimer?.cancel();
    _profileChangeListeners.clear();
  }
}

/// Power profile enum
enum PowerProfile {
  batterySaver,
  dataSaver,
  balanced,
  performance,
}

/// Power profile extension
extension PowerProfileExtension on PowerProfile {
  String get label {
    switch (this) {
      case PowerProfile.batterySaver:
        return 'Battery Saver';
      case PowerProfile.dataSaver:
        return 'Data Saver';
      case PowerProfile.balanced:
        return 'Balanced';
      case PowerProfile.performance:
        return 'Performance';
    }
  }

  String get description {
    switch (this) {
      case PowerProfile.batterySaver:
        return 'Maximize battery life, lower quality';
      case PowerProfile.dataSaver:
        return 'Reduce data usage, compressed images';
      case PowerProfile.balanced:
        return 'Balance performance and battery';
      case PowerProfile.performance:
        return 'Maximum performance, faster translations';
    }
  }

  String get icon {
    switch (this) {
      case PowerProfile.batterySaver:
        return '🔋';
      case PowerProfile.dataSaver:
        return '📦';
      case PowerProfile.balanced:
        return '⚖️';
      case PowerProfile.performance:
        return '🚀';
    }
  }
}

/// Profile statistics
class ProfileStatistics {
  final PowerProfile currentProfile;
  final double batteryLevel;
  final bool isCharging;
  final bool autoSwitchEnabled;
  final double imageQuality;
  final int preloadPageCount;
  final int maxConcurrentTranslations;
  final bool animationsEnabled;
  final bool compressionEnabled;
  final int compressionQuality;

  ProfileStatistics({
    required this.currentProfile,
    required this.batteryLevel,
    required this.isCharging,
    required this.autoSwitchEnabled,
    required this.imageQuality,
    required this.preloadPageCount,
    required this.maxConcurrentTranslations,
    required this.animationsEnabled,
    required this.compressionEnabled,
    required this.compressionQuality,
  });

  String get profileLabel => currentProfile.label;
  String get batteryFormatted => '${batteryLevel.toStringAsFixed(0)}%';
  String get chargingStatus => isCharging ? 'Charging' : 'On Battery';

  Map<String, dynamic> toJson() => {
    'profile': profileLabel,
    'batteryLevel': batteryLevel,
    'isCharging': isCharging,
    'autoSwitchEnabled': autoSwitchEnabled,
    'imageQuality': imageQuality,
    'preloadPageCount': preloadPageCount,
    'maxConcurrentTranslations': maxConcurrentTranslations,
    'animationsEnabled': animationsEnabled,
    'compressionEnabled': compressionEnabled,
    'compressionQuality': compressionQuality,
  };
}
