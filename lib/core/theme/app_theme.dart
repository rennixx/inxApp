import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  // OLED Colors
  static const Color _oledBlack = Color(AppConstants.oledBlack);
  static const Color _oledWhite = Color(AppConstants.oledWhite);
  static const Color _glassSurface = Color(AppConstants.glassSurface);
  static const Color _glassBorder = Color(AppConstants.glassBorder);

  // Text Colors with Opacity Variants
  static const Color _textHighEmphasis = Color(0xFFFFFFFF);
  static const Color _textMediumEmphasis = Color(0xB3FFFFFF);
  static const Color _textLowEmphasis = Color(0x80FFFFFF);

  // Accent Colors
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFF44336);
  static const Color accentOrange = Color(0xFFFF9800);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _oledBlack,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: accentBlue,
        onPrimary: _oledWhite,
        secondary: accentGreen,
        onSecondary: _oledWhite,
        error: accentRed,
        onError: _oledWhite,
        background: _oledBlack,
        onBackground: _textHighEmphasis,
        surface: _glassSurface,
        onSurface: _textHighEmphasis,
        surfaceVariant: _glassSurface,
        onSurfaceVariant: _textMediumEmphasis,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _oledBlack,
        foregroundColor: _textHighEmphasis,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _textHighEmphasis,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _oledBlack,
        selectedItemColor: accentBlue,
        unselectedItemColor: _textMediumEmphasis,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(),
      iconTheme: const IconThemeData(
        color: _textHighEmphasis,
        size: 24,
      ),
      cardTheme: const CardThemeData(
        color: _glassSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: _glassBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: _oledWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textHighEmphasis,
          side: const BorderSide(color: _glassBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _glassBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _oledBlack,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: accentBlue,
        onPrimary: _oledWhite,
        secondary: accentGreen,
        onSecondary: _oledWhite,
        error: accentRed,
        onError: _oledWhite,
        background: _oledBlack,
        onBackground: _textHighEmphasis,
        surface: _glassSurface,
        onSurface: _textHighEmphasis,
        surfaceVariant: _glassSurface,
        onSurfaceVariant: _textMediumEmphasis,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _oledBlack,
        foregroundColor: _textHighEmphasis,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _textHighEmphasis,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _oledBlack,
        selectedItemColor: accentBlue,
        unselectedItemColor: _textMediumEmphasis,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: _buildTextTheme(),
      iconTheme: const IconThemeData(
        color: _textHighEmphasis,
        size: 24,
      ),
      cardTheme: const CardThemeData(
        color: _glassSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: _glassBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: _oledWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textHighEmphasis,
          side: const BorderSide(color: _glassBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _glassBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: _textHighEmphasis,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: _textHighEmphasis,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: _textHighEmphasis,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: _textHighEmphasis,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: _textHighEmphasis,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _textHighEmphasis,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _textHighEmphasis,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _textMediumEmphasis,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _textMediumEmphasis,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _textHighEmphasis,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _textMediumEmphasis,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _textLowEmphasis,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textHighEmphasis,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _textMediumEmphasis,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _textLowEmphasis,
      ),
    );
  }
}
