class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'INX';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLibraryPath = 'library_path';
  static const String keyLastSync = 'last_sync';

  // OLED Colors
  static const int oledBlack = 0xFF000000;
  static const int oledWhite = 0xFFFFFFFF;
  static const int glassSurface = 0x1AFFFFFF;
  static const int glassBorder = 0x33FFFFFF;

  // Animation Durations
  static const int animationDurationMs = 300;
  static const int splashAnimationDurationMs = 2000;

  // Glassmorphism
  static const double glassBlur = 20.0;
  static const double glassOpacity = 0.1;
}
