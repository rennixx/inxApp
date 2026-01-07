import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// API Configuration Service
/// Manages storage and initialization of API keys
class ApiConfig {
  ApiConfig._();

  static const String _geminiKeyKey = 'gemini_api_key';
  static String? _cachedGeminiKey;

  /// Get the stored Gemini API key
  static Future<String?> getGeminiApiKey() async {
    if (_cachedGeminiKey != null) {
      return _cachedGeminiKey;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString(_geminiKeyKey);
      if (apiKey != null && apiKey.isNotEmpty) {
        _cachedGeminiKey = apiKey;
        AppLogger.info('Gemini API key loaded', tag: 'ApiConfig');
        return apiKey;
      }
    } catch (e) {
      AppLogger.error('Failed to read API key', error: e, tag: 'ApiConfig');
    }

    return null;
  }

  /// Save the Gemini API key
  static Future<bool> saveGeminiApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_geminiKeyKey, apiKey);
      _cachedGeminiKey = apiKey;
      AppLogger.info('Gemini API key saved', tag: 'ApiConfig');
      return true;
    } catch (e) {
      AppLogger.error('Failed to save API key', error: e, tag: 'ApiConfig');
      return false;
    }
  }

  /// Remove the stored Gemini API key
  static Future<bool> removeGeminiApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_geminiKeyKey);
      _cachedGeminiKey = null;
      AppLogger.info('Gemini API key removed', tag: 'ApiConfig');
      return true;
    } catch (e) {
      AppLogger.error('Failed to remove API key', error: e, tag: 'ApiConfig');
      return false;
    }
  }

  /// Check if Gemini API key is configured
  static Future<bool> isGeminiKeyConfigured() async {
    final key = await getGeminiApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Get masked version of API key for display (e.g., "AIza...AbC3")
  static Future<String> getMaskedApiKey() async {
    final key = await getGeminiApiKey();
    if (key == null || key.isEmpty) {
      return 'Not configured';
    }
    if (key.length <= 8) {
      return '••••••••';
    }
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  /// Clear all stored API keys
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_geminiKeyKey);
      _cachedGeminiKey = null;
      AppLogger.info('API keys cleared', tag: 'ApiConfig');
    } catch (e) {
      AppLogger.error('Failed to clear API keys', error: e, tag: 'ApiConfig');
    }
  }
}
