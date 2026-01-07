import 'package:flutter/material.dart';

/// App settings entity
class AppSettings {
  // Reader Preferences
  final double brightness;
  final double autoScrollSpeed;
  final PageTurnAnimation pageTurnAnimation;
  final bool volumeKeyNavigation;
  final bool doubleTapToZoom;
  final double zoomLevel;

  // Translation Settings
  final String targetLanguage;
  final TranslationModel translationModel;
  final TranslationQuality translationQuality;
  final bool enableTranslationCache;
  final int maxCacheSizeMB;

  // Storage Settings
  final int maxStorageSizeMB;
  final String importLocation;
  final bool autoCleanupCache;
  final int cacheCleanupDays;

  // Theme Settings
  final ThemeMode themeMode;
  final bool useOLEDMode;
  final Color accentColor;
  final double fontSize;
  final UIDensity uiDensity;

  AppSettings({
    // Reader Preferences defaults
    this.brightness = 1.0,
    this.autoScrollSpeed = 0.5,
    this.pageTurnAnimation = PageTurnAnimation.slide,
    this.volumeKeyNavigation = false,
    this.doubleTapToZoom = true,
    this.zoomLevel = 1.0,

    // Translation Settings defaults
    this.targetLanguage = 'en',
    this.translationModel = TranslationModel.geminiPro,
    this.translationQuality = TranslationQuality.balanced,
    this.enableTranslationCache = true,
    this.maxCacheSizeMB = 500,

    // Storage Settings defaults
    this.maxStorageSizeMB = 2048,
    this.importLocation = '/storage/emulated/0/Download',
    this.autoCleanupCache = false,
    this.cacheCleanupDays = 30,

    // Theme Settings defaults
    this.themeMode = ThemeMode.dark,
    this.useOLEDMode = true,
    this.accentColor = const Color(0xFF6C5CE7),
    this.fontSize = 14.0,
    this.uiDensity = UIDensity.medium,
  });

  AppSettings copyWith({
    double? brightness,
    double? autoScrollSpeed,
    PageTurnAnimation? pageTurnAnimation,
    bool? volumeKeyNavigation,
    bool? doubleTapToZoom,
    double? zoomLevel,
    String? targetLanguage,
    TranslationModel? translationModel,
    TranslationQuality? translationQuality,
    bool? enableTranslationCache,
    int? maxCacheSizeMB,
    int? maxStorageSizeMB,
    String? importLocation,
    bool? autoCleanupCache,
    int? cacheCleanupDays,
    ThemeMode? themeMode,
    bool? useOLEDMode,
    Color? accentColor,
    double? fontSize,
    UIDensity? uiDensity,
  }) {
    return AppSettings(
      brightness: brightness ?? this.brightness,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      pageTurnAnimation: pageTurnAnimation ?? this.pageTurnAnimation,
      volumeKeyNavigation: volumeKeyNavigation ?? this.volumeKeyNavigation,
      doubleTapToZoom: doubleTapToZoom ?? this.doubleTapToZoom,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      translationModel: translationModel ?? this.translationModel,
      translationQuality: translationQuality ?? this.translationQuality,
      enableTranslationCache: enableTranslationCache ?? this.enableTranslationCache,
      maxCacheSizeMB: maxCacheSizeMB ?? this.maxCacheSizeMB,
      maxStorageSizeMB: maxStorageSizeMB ?? this.maxStorageSizeMB,
      importLocation: importLocation ?? this.importLocation,
      autoCleanupCache: autoCleanupCache ?? this.autoCleanupCache,
      cacheCleanupDays: cacheCleanupDays ?? this.cacheCleanupDays,
      themeMode: themeMode ?? this.themeMode,
      useOLEDMode: useOLEDMode ?? this.useOLEDMode,
      accentColor: accentColor ?? this.accentColor,
      fontSize: fontSize ?? this.fontSize,
      uiDensity: uiDensity ?? this.uiDensity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brightness': brightness,
      'autoScrollSpeed': autoScrollSpeed,
      'pageTurnAnimation': pageTurnAnimation.index,
      'volumeKeyNavigation': volumeKeyNavigation,
      'doubleTapToZoom': doubleTapToZoom,
      'zoomLevel': zoomLevel,
      'targetLanguage': targetLanguage,
      'translationModel': translationModel.index,
      'translationQuality': translationQuality.index,
      'enableTranslationCache': enableTranslationCache,
      'maxCacheSizeMB': maxCacheSizeMB,
      'maxStorageSizeMB': maxStorageSizeMB,
      'importLocation': importLocation,
      'autoCleanupCache': autoCleanupCache,
      'cacheCleanupDays': cacheCleanupDays,
      'themeMode': themeMode.index,
      'useOLEDMode': useOLEDMode,
      'accentColor': accentColor.value, // Keep using value for backward compatibility
      'fontSize': fontSize,
      'uiDensity': uiDensity.index,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      brightness: json['brightness']?.toDouble() ?? 1.0,
      autoScrollSpeed: json['autoScrollSpeed']?.toDouble() ?? 0.5,
      pageTurnAnimation: PageTurnAnimation.values[json['pageTurnAnimation'] ?? 0],
      volumeKeyNavigation: json['volumeKeyNavigation'] ?? false,
      doubleTapToZoom: json['doubleTapToZoom'] ?? true,
      zoomLevel: json['zoomLevel']?.toDouble() ?? 1.0,
      targetLanguage: json['targetLanguage'] ?? 'en',
      translationModel: TranslationModel.values[json['translationModel'] ?? 0],
      translationQuality: TranslationQuality.values[json['translationQuality'] ?? 1],
      enableTranslationCache: json['enableTranslationCache'] ?? true,
      maxCacheSizeMB: json['maxCacheSizeMB'] ?? 500,
      maxStorageSizeMB: json['maxStorageSizeMB'] ?? 2048,
      importLocation: json['importLocation'] ?? '/storage/emulated/0/Download',
      autoCleanupCache: json['autoCleanupCache'] ?? false,
      cacheCleanupDays: json['cacheCleanupDays'] ?? 30,
      themeMode: ThemeMode.values[json['themeMode'] ?? 1],
      useOLEDMode: json['useOLEDMode'] ?? true,
      accentColor: Color(json['accentColor'] ?? 0xFF6C5CE7),
      fontSize: json['fontSize']?.toDouble() ?? 14.0,
      uiDensity: UIDensity.values[json['uiDensity'] ?? 1],
    );
  }
}

/// Page turn animation styles
enum PageTurnAnimation {
  none,
  slide,
  fade,
  curl,
  scale,
}

extension PageTurnAnimationExtension on PageTurnAnimation {
  String get label {
    switch (this) {
      case PageTurnAnimation.none:
        return 'None';
      case PageTurnAnimation.slide:
        return 'Slide';
      case PageTurnAnimation.fade:
        return 'Fade';
      case PageTurnAnimation.curl:
        return 'Curl';
      case PageTurnAnimation.scale:
        return 'Scale';
    }
  }

  String get description {
    switch (this) {
      case PageTurnAnimation.none:
        return 'Instant page change';
      case PageTurnAnimation.slide:
        return 'Smooth slide transition';
      case PageTurnAnimation.fade:
        return 'Fade between pages';
      case PageTurnAnimation.curl:
        return 'Page curl effect';
      case PageTurnAnimation.scale:
        return 'Scale in/out animation';
    }
  }
}

/// Translation models
enum TranslationModel {
  geminiPro,
  geminiFlash,
  gpt4,
  claude,
}

extension TranslationModelExtension on TranslationModel {
  String get label {
    switch (this) {
      case TranslationModel.geminiPro:
        return 'Gemini Pro';
      case TranslationModel.geminiFlash:
        return 'Gemini Flash';
      case TranslationModel.gpt4:
        return 'GPT-4';
      case TranslationModel.claude:
        return 'Claude';
    }
  }

  String get description {
    switch (this) {
      case TranslationModel.geminiPro:
        return 'High quality, slower';
      case TranslationModel.geminiFlash:
        return 'Fast, good quality';
      case TranslationModel.gpt4:
        return 'Best quality, slowest';
      case TranslationModel.claude:
        return 'Balanced option';
    }
  }
}

/// Translation quality presets
enum TranslationQuality {
  fast,
  balanced,
  accurate,
}

extension TranslationQualityExtension on TranslationQuality {
  String get label {
    switch (this) {
      case TranslationQuality.fast:
        return 'Speed';
      case TranslationQuality.balanced:
        return 'Balanced';
      case TranslationQuality.accurate:
        return 'Quality';
    }
  }

  String get description {
    switch (this) {
      case TranslationQuality.fast:
        return 'Prioritize speed over accuracy';
      case TranslationQuality.balanced:
        return 'Balance between speed and quality';
      case TranslationQuality.accurate:
        return 'Prioritize quality over speed';
    }
  }
}

/// UI density options
enum UIDensity {
  compact,
  medium,
  spacious,
}

extension UIDensityExtension on UIDensity {
  String get label {
    switch (this) {
      case UIDensity.compact:
        return 'Compact';
      case UIDensity.medium:
        return 'Medium';
      case UIDensity.spacious:
        return 'Spacious';
    }
  }

  double get scaleFactor {
    switch (this) {
      case UIDensity.compact:
        return 0.85;
      case UIDensity.medium:
        return 1.0;
      case UIDensity.spacious:
        return 1.15;
    }
  }
}
