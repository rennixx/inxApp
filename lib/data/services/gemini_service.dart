import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/utils/logger.dart';

/// Gemini AI model options
enum GeminiModel {
  /// Fast, cost-effective model for quick translations
  flash('gemini-1.5-flash'),

  /// High-quality model for better translations
  pro('gemini-1.5-pro');

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

/// Google Gemini AI service for translation
class GeminiService {
  GeminiService._();

  static GenerativeModel? _flashModel;
  static GenerativeModel? _proModel;
  static String? _apiKey;

  /// Initialize Gemini with API key
  static Future<void> initialize(String apiKey) async {
    if (_apiKey == apiKey && _flashModel != null) {
      AppLogger.info('Gemini already initialized', tag: 'GeminiService');
      return;
    }

    _apiKey = apiKey;

    try {
      // Initialize flash model (default)
      _flashModel = GenerativeModel(
        model: GeminiModel.flash.modelName,
        apiKey: apiKey,
      );

      // Initialize pro model (fallback)
      _proModel = GenerativeModel(
        model: GeminiModel.pro.modelName,
        apiKey: apiKey,
      );

      AppLogger.info('Gemini initialized successfully', tag: 'GeminiService');
    } catch (e) {
      AppLogger.error('Failed to initialize Gemini', error: e, tag: 'GeminiService');
      rethrow;
    }
  }

  /// Check if Gemini is initialized
  static bool get isInitialized => _apiKey != null && _flashModel != null;

  /// Translate text with manga context
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

    final model = preferredModel == GeminiModel.pro ? _proModel! : _flashModel!;

    try {
      final prompt = _buildTranslationPrompt(
        text,
        targetLanguage,
        sourceLanguage,
        context,
      );

      AppLogger.info('Translating with ${preferredModel.modelName}', tag: 'GeminiService');

      final response = await model.generateContent(
        [Content.text(prompt)],
      );

      final translatedText = response.text?.trim() ?? '';

      if (translatedText.isEmpty) {
        throw Exception('Empty translation response');
      }

      // Extract metadata
      final tokensUsed = response.usageMetadata?.totalTokenCount ?? 0;

      AppLogger.info('Translation successful: ${tokensUsed} tokens', tag: 'GeminiService');

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
    AppLogger.info('Batch translating ${texts.length} texts', tag: 'GeminiService');

    final results = <TranslationResult>[];

    // Process in batches of 5 to avoid rate limits
    const batchSize = 5;
    for (int i = 0; i < texts.length; i += batchSize) {
      final end = (i + batchSize < texts.length) ? i + batchSize : texts.length;
      final batch = texts.sublist(i, end);

      final batchResults = await Future.wait(
        batch.map((text) => translateText(
          text,
          targetLanguage,
          sourceLanguage: sourceLanguage,
          preferredModel: preferredModel,
          context: context,
        )),
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
      const prompt = '''Detect the language of this text and respond with ONLY the ISO 639-1 code (e.g., "ja" for Japanese, "ko" for Korean, "zh" for Chinese, "en" for English):

Text: {text}

Language code:''';

      final response = await _flashModel!.generateContent(
        [Content.text(prompt.replaceFirst('{text}', text))],
      );

      final languageCode = response.text?.trim().toLowerCase() ?? 'unknown';
      return languageCode;
    } catch (e) {
      AppLogger.error('Language detection failed', error: e, tag: 'GeminiService');
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

      if (context.characterNames != null && context.characterNames!.isNotEmpty) {
        buffer.writeln('Characters: ${context.characterNames!.entries.map((e) => '${e.key} (${e.value})').join(', ')}');
      }

      if (context.previousDialogue != null) {
        buffer.writeln('Previous dialogue: "${context.previousDialogue}"');
      }

      // Add bubble-type specific instructions
      buffer.writeln('\n**Text Type**');
      switch (context.bubbleType) {
        case BubbleType.dialogue:
          buffer.writeln('Character dialogue - preserve character voice and personality');
          break;
        case BubbleType.thought:
          buffer.writeln('Internal monologue - use introspective, first-person style');
          break;
        case BubbleType.narration:
          buffer.writeln('Narration - use formal, descriptive tone');
          break;
        case BubbleType.soundEffect:
          buffer.writeln('Sound effect - translate onomatopoeia naturally for target language');
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
    cleaned = cleaned.replaceFirst(RegExp(r'^Translation:\s*', caseSensitive: false), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^Translated text:\s*', caseSensitive: false), '');

    return cleaned.trim();
  }

  /// Stream translation for real-time display
  static Stream<String> translateTextStream(
    String text,
    String targetLanguage, {
    String sourceLanguage = 'auto',
    GeminiModel preferredModel = GeminiModel.flash,
    MangaTranslationContext? context,
  }) async* {
    if (!isInitialized) {
      throw Exception('Gemini not initialized. Call initialize() first.');
    }

    final model = preferredModel == GeminiModel.pro ? _proModel! : _flashModel!;

    try {
      final prompt = _buildTranslationPrompt(
        text,
        targetLanguage,
        sourceLanguage,
        context,
      );

      AppLogger.info('Streaming translation with ${preferredModel.modelName}', tag: 'GeminiService');

      final response = model.generateContentStream(
        [Content.text(prompt)],
      );

      final fullText = StringBuffer();

      await for (final chunk in response) {
        final text = chunk.text ?? '';
        fullText.write(text);
        yield text;
      }

      AppLogger.info('Streaming translation complete', tag: 'GeminiService');
    } catch (e) {
      AppLogger.error('Streaming translation failed', error: e, tag: 'GeminiService');
      rethrow;
    }
  }

  /// Reset models (for testing or API key change)
  static void reset() {
    _flashModel = null;
    _proModel = null;
    _apiKey = null;
    AppLogger.info('Gemini models reset', tag: 'GeminiService');
  }
}
