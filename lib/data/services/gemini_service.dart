import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';

/// Gemini AI model options
enum GeminiModel {
  /// Fast, cost-effective model for quick translations
  flash('gemini-2.5-flash'),

  /// High-quality model for better translations
  pro('gemini-2.5-pro');

  final String modelName;
  const GeminiModel(this.modelName);
}

/// Translation result with metadata
class TranslationResult {
  final String translatedText;
  final String sourceLanguage;
  final GeminiModel modelUsed;
  final double confidence;
  final int tokensUsed;

  TranslationResult({
    required this.translatedText,
    required this.sourceLanguage,
    required this.modelUsed,
    this.confidence = 0.9,
    this.tokensUsed = 0,
  });

  TranslationResult copyWith({
    String? translatedText,
    String? sourceLanguage,
    GeminiModel? modelUsed,
    double? confidence,
    int? tokensUsed,
  }) {
    return TranslationResult(
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      modelUsed: modelUsed ?? this.modelUsed,
      confidence: confidence ?? this.confidence,
      tokensUsed: tokensUsed ?? this.tokensUsed,
    );
  }
}

/// Manga-specific translation context
class MangaTranslationContext {
  final String? seriesTitle;
  final String? genre;
  final Map<String, String>? characterNames;
  final String? previousDialogue;
  final BubbleType bubbleType;

  MangaTranslationContext({
    this.seriesTitle,
    this.genre,
    this.characterNames,
    this.previousDialogue,
    this.bubbleType = BubbleType.dialogue,
  });
}

/// Types of speech bubbles for context-aware translation
enum BubbleType {
  /// Character dialogue
  dialogue,

  /// Internal thought/monologue
  thought,

  /// Narration box
  narration,

  /// Sound effect
  soundEffect,

  /// Title/header text
  title,
}

/// Google Gemini AI service for translation using REST API
class GeminiService {
  GeminiService._();

  static String? _apiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Initialize Gemini with API key
  static Future<void> initialize(String apiKey) async {
    if (_apiKey == apiKey) {
      AppLogger.info('Gemini already initialized', tag: 'GeminiService');
      return;
    }

    _apiKey = apiKey;
    AppLogger.info('Gemini initialized successfully', tag: 'GeminiService');
  }

  /// Check if Gemini is initialized
  static bool get isInitialized => _apiKey != null && _apiKey!.isNotEmpty;

  /// Translate text with manga context using REST API
  static Future<TranslationResult> translateText(
    String text,
    String targetLanguage, {
    String sourceLanguage = 'auto',
    GeminiModel preferredModel = GeminiModel.flash,
    MangaTranslationContext? context,
  }) async {
    if (!isInitialized) {
      throw Exception('Gemini not initialized. Call initialize() first.');
    }

    try {
      final prompt = _buildTranslationPrompt(
        text,
        targetLanguage,
        sourceLanguage,
        context,
      );

      AppLogger.info(
        'Translating with ${preferredModel.modelName}',
        tag: 'GeminiService',
      );

      final url = Uri.parse(
        '$_baseUrl/models/${preferredModel.modelName}:generateContent?key=$_apiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'API Error (${response.statusCode}): ${errorBody['error']['message'] ?? response.body}',
        );
      }

      final responseData = jsonDecode(response.body);

      // Extract the translated text from response
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No candidates in response');
      }

      final content = candidates[0]['content'] as Map?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('No parts in response');
      }

      final translatedText = (parts[0]['text'] as String?).toString().trim();

      if (translatedText.isEmpty || translatedText == 'null') {
        throw Exception('Empty translation response');
      }

      // Extract token usage metadata
      final usageMetadata = responseData['usageMetadata'] as Map?;
      final tokensUsed = (usageMetadata?['totalTokenCount'] as int?) ?? 0;

      AppLogger.info(
        'Translation successful: $tokensUsed tokens',
        tag: 'GeminiService',
      );

      return TranslationResult(
        translatedText: _cleanTranslation(translatedText),
        sourceLanguage: sourceLanguage,
        modelUsed: preferredModel,
        tokensUsed: tokensUsed,
      );
    } catch (e) {
      AppLogger.error('Translation failed', error: e, tag: 'GeminiService');

      // Fallback to pro model if flash failed
      if (preferredModel == GeminiModel.flash) {
        AppLogger.info('Retrying with pro model', tag: 'GeminiService');
        return translateText(
          text,
          targetLanguage,
          sourceLanguage: sourceLanguage,
          preferredModel: GeminiModel.pro,
          context: context,
        );
      }

      rethrow;
    }
  }

  /// Batch translate multiple text segments
  static Future<List<TranslationResult>> batchTranslate(
    List<String> texts,
    String targetLanguage, {
    String sourceLanguage = 'auto',
    GeminiModel preferredModel = GeminiModel.flash,
    MangaTranslationContext? context,
  }) async {
    AppLogger.info(
      'Batch translating ${texts.length} texts',
      tag: 'GeminiService',
    );

    final results = <TranslationResult>[];

    // Process in batches of 5 to avoid rate limits
    const batchSize = 5;
    for (int i = 0; i < texts.length; i += batchSize) {
      final end = (i + batchSize < texts.length) ? i + batchSize : texts.length;
      final batch = texts.sublist(i, end);

      final batchResults = await Future.wait(
        batch.map(
          (text) => translateText(
            text,
            targetLanguage,
            sourceLanguage: sourceLanguage,
            preferredModel: preferredModel,
            context: context,
          ),
        ),
      );

      results.addAll(batchResults);

      // Small delay between batches to avoid rate limiting
      if (end < texts.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    AppLogger.info('Batch translation complete', tag: 'GeminiService');
    return results;
  }

  /// Detect language of text
  static Future<String> detectLanguage(String text) async {
    if (!isInitialized) {
      throw Exception('Gemini not initialized. Call initialize() first.');
    }

    try {
      const prompt =
          '''Detect the language of this text and respond with ONLY the ISO 639-1 code (e.g., "ja" for Japanese, "ko" for Korean, "zh" for Chinese, "en" for English):

Text: {text}

Language code:''';

      final url = Uri.parse(
        '$_baseUrl/models/${GeminiModel.flash.modelName}:generateContent?key=$_apiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt.replaceFirst('{text}', text)},
            ],
          },
        ],
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Language detection failed: ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final candidates = responseData['candidates'] as List?;
      final content = candidates?[0]['content'] as Map?;
      final parts = content?['parts'] as List?;
      final languageCode = parts?[0]['text'] as String?;

      return languageCode?.trim().toLowerCase() ?? 'unknown';
    } catch (e) {
      AppLogger.error(
        'Language detection failed',
        error: e,
        tag: 'GeminiService',
      );
      return 'unknown';
    }
  }

  /// Build manga-context-aware translation prompt
  static String _buildTranslationPrompt(
    String text,
    String targetLanguage,
    String sourceLanguage,
    MangaTranslationContext? context,
  ) {
    final buffer = StringBuffer();

    // Add context information
    if (context != null) {
      buffer.writeln('**Manga Translation Context**');

      if (context.seriesTitle != null) {
        buffer.writeln('Series: ${context.seriesTitle}');
      }

      if (context.genre != null) {
        buffer.writeln('Genre: ${context.genre}');
      }

      if (context.characterNames != null &&
          context.characterNames!.isNotEmpty) {
        buffer.writeln(
          'Characters: ${context.characterNames!.entries.map((e) => '${e.key} (${e.value})').join(', ')}',
        );
      }

      if (context.previousDialogue != null) {
        buffer.writeln('Previous dialogue: "${context.previousDialogue}"');
      }

      // Add bubble-type specific instructions
      buffer.writeln('\n**Text Type**');
      switch (context.bubbleType) {
        case BubbleType.dialogue:
          buffer.writeln(
            'Character dialogue - preserve character voice and personality',
          );
          break;
        case BubbleType.thought:
          buffer.writeln(
            'Internal monologue - use introspective, first-person style',
          );
          break;
        case BubbleType.narration:
          buffer.writeln('Narration - use formal, descriptive tone');
          break;
        case BubbleType.soundEffect:
          buffer.writeln(
            'Sound effect - translate onomatopoeia naturally for target language',
          );
          break;
        case BubbleType.title:
          buffer.writeln('Title/header - use bold, impactful language');
          break;
      }

      buffer.writeln();
    }

    // Translation instruction
    buffer.writeln('**Translation Task**');
    buffer.writeln('Translate the following text to $targetLanguage');

    if (sourceLanguage != 'auto') {
      buffer.writeln('Source language: $sourceLanguage');
    }

    buffer.writeln('''
**Guidelines:**
- Natural, conversational ${targetLanguage} suitable for manga
- Preserve the original tone and emotion
- Keep the translation concise (speech bubbles are small)
- For dialogue: match character personality
- For thoughts: use internal monologue style
- For sound effects: use natural onomatopoeia
- DO NOT include explanations or notes
- Respond with ONLY the translated text

**Text to translate:**
"$text"

**Translation:**''');

    return buffer.toString();
  }

  /// Clean translation response
  static String _cleanTranslation(String text) {
    // Remove common artifacts
    var cleaned = text.trim();

    // Remove quotes if entire text is quoted
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    } else if (cleaned.startsWith("'") && cleaned.endsWith("'")) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    // Remove common prefixes
    cleaned = cleaned.replaceFirst(
      RegExp(r'^Translation:\s*', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceFirst(
      RegExp(r'^Translated text:\s*', caseSensitive: false),
      '',
    );

    return cleaned.trim();
  }

  /// Reset models (for testing or API key change)
  static void reset() {
    _apiKey = null;
    AppLogger.info('Gemini models reset', tag: 'GeminiService');
  }
}
