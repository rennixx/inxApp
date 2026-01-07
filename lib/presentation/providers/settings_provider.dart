import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/settings.dart';

/// Settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load from local storage
    // For now, use default settings
  }

  void updateSettings(AppSettings newSettings) {
    state = newSettings;
    // TODO: Save to local storage
  }

  void updateBrightness(double brightness) {
    state = state.copyWith(brightness: brightness);
  }

  void updateAutoScrollSpeed(double speed) {
    state = state.copyWith(autoScrollSpeed: speed);
  }

  void updatePageTurnAnimation(PageTurnAnimation animation) {
    state = state.copyWith(pageTurnAnimation: animation);
  }

  void toggleVolumeKeyNavigation() {
    state = state.copyWith(volumeKeyNavigation: !state.volumeKeyNavigation);
  }

  void updateTargetLanguage(String language) {
    state = state.copyWith(targetLanguage: language);
  }

  void updateTranslationModel(TranslationModel model) {
    state = state.copyWith(translationModel: model);
  }

  void updateTranslationQuality(TranslationQuality quality) {
    state = state.copyWith(translationQuality: quality);
  }

  void toggleTranslationCache() {
    state = state.copyWith(enableTranslationCache: !state.enableTranslationCache);
  }

  void updateThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleOLEDMode() {
    state = state.copyWith(useOLEDMode: !state.useOLEDMode);
  }

  void updateAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
  }

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size);
  }

  void updateUIDensity(UIDensity density) {
    state = state.copyWith(uiDensity: density);
  }
}

