import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/utils/logger.dart';
import 'gemini_service.dart';
import 'ocr_service.dart';
import '../../data/repositories/translation_cache_repository.dart';

/// Progress stages for translation pipeline
enum TranslationStage {
  preprocessing,
  textRecognition,
  translation,
  rendering,
}

/// Translation progress with stage information
class TranslationProgress {
  final TranslationStage stage;
  final double progress; // 0.0 to 1.0
  final String? message;
  final int? current;
  final int? total;

  TranslationProgress({
    required this.stage,
    required this.progress,
    this.message,
    this.current,
    this.total,
  });

  double get overallProgress {
    switch (stage) {
      case TranslationStage.preprocessing:
        return progress * 0.25;
      case TranslationStage.textRecognition:
        return 0.25 + (progress * 0.25);
      case TranslationStage.translation:
        return 0.5 + (progress * 0.25);
      case TranslationStage.rendering:
        return 0.75 + (progress * 0.25);
    }
  }
}

/// Result from the translation pipeline
class PipelineTranslationResult {
  final String originalText;
  final String translatedText;
  final Rect? textRegion;
  final OcrResult? ocrResult;
  final TranslationResult translationResult;
  final bool fromCache;

  PipelineTranslationResult({
    required this.originalText,
    required this.translatedText,
    this.textRegion,
    this.ocrResult,
    required this.translationResult,
    this.fromCache = false,
  });
}

/// Configuration for translation pipeline
class PipelineConfig {
  final String targetLanguage;
  final String sourceLanguage;
  final OcrLanguage ocrLanguage;
  final GeminiModel preferredModel;
  final MangaTranslationContext? context;
  final bool useCache;
  final ImagePreprocessingOptions preprocessingOptions;

  const PipelineConfig({
    required this.targetLanguage,
    this.sourceLanguage = 'auto',
    this.ocrLanguage = OcrLanguage.japanese,
    this.preferredModel = GeminiModel.flash,
    this.context,
    this.useCache = true,
    this.preprocessingOptions = const ImagePreprocessingOptions(),
  });
}

/// Integrated translation pipeline: OCR → Translate → Cache → Render
class TranslationPipelineService {
  TranslationPipelineService._();

  static bool _isInitialized = false;

  /// Initialize the pipeline services
  static Future<void> initialize({
    required String geminiApiKey,
    List<OcrLanguage> ocrLanguages = const [
      OcrLanguage.japanese,
      OcrLanguage.english,
    ],
  }) async {
    if (_isInitialized) {
      AppLogger.info('Translation pipeline already initialized', tag: 'TranslationPipeline');
      return;
    }

    try {
      // Initialize Gemini
      await GeminiService.initialize(geminiApiKey);

      // Initialize OCR (skip on web)
      if (!kIsWeb) {
        await OcrService.initializeLanguages(ocrLanguages);
      }

      // Initialize cache (skip on web)
      if (!kIsWeb) {
        await TranslationCacheRepository.database;
      }

      _isInitialized = true;
      AppLogger.info('Translation pipeline initialized', tag: 'TranslationPipeline');
    } catch (e) {
      AppLogger.error('Failed to initialize translation pipeline', error: e, tag: 'TranslationPipeline');
      rethrow;
    }
  }

  /// Check if pipeline is initialized
  static bool get isInitialized => _isInitialized;

  /// Translate a single image with progress callback
  static Future<PipelineTranslationResult> translateImage(
    String imagePath, {
    required PipelineConfig config,
    void Function(TranslationProgress)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('Translation pipeline not initialized. Call initialize() first.');
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Stage 1: Preprocessing (0-25%)
      onProgress?.call(TranslationProgress(
        stage: TranslationStage.preprocessing,
        progress: 0.0,
        message: 'Preprocessing image...',
      ));

      // Check cache first
      if (config.useCache && !kIsWeb) {
        final cached = await TranslationCacheRepository.getTranslation(
          imagePath,
          config.targetLanguage,
          sourceLanguage: config.sourceLanguage,
        );

        if (cached != null) {
          AppLogger.info('Translation cache hit', tag: 'TranslationPipeline');
          onProgress?.call(TranslationProgress(
            stage: TranslationStage.rendering,
            progress: 1.0,
            message: 'Loaded from cache',
          ));

          return PipelineTranslationResult(
            originalText: cached.originalText,
            translatedText: cached.translatedText,
            translationResult: TranslationResult(
              translatedText: cached.translatedText,
              sourceLanguage: cached.sourceLang,
              modelUsed: GeminiModel.values.firstWhere(
                (m) => m.modelName == cached.modelUsed,
                orElse: () => GeminiModel.flash,
              ),
              confidence: cached.confidenceScore,
            ),
            fromCache: true,
          );
        }
      }

      onProgress?.call(TranslationProgress(
        stage: TranslationStage.preprocessing,
        progress: 1.0,
        message: 'Preprocessing complete',
      ));

      // Stage 2: Text Recognition (25-50%)
      onProgress?.call(TranslationProgress(
        stage: TranslationStage.textRecognition,
        progress: 0.0,
        message: 'Recognizing text...',
      ));

      OcrResult? ocrResult;
      String originalText = '';

      if (!kIsWeb) {
        ocrResult = await OcrService.processImage(
          imagePath,
          language: config.ocrLanguage,
          options: config.preprocessingOptions,
        );

        originalText = ocrResult.fullText;

        onProgress?.call(TranslationProgress(
          stage: TranslationStage.textRecognition,
          progress: 1.0,
          message: 'Found ${ocrResult.textRegions.length} text regions',
          current: ocrResult.textRegions.length,
          total: ocrResult.textRegions.length,
        ));
      } else {
        // Web: Manual text entry required
        throw UnsupportedError('Automatic OCR not supported on web. Please use manual text entry.');
      }

      if (originalText.isEmpty) {
        throw Exception('No text detected in image');
      }

      // Stage 3: Translation (50-75%)
      onProgress?.call(TranslationProgress(
        stage: TranslationStage.translation,
        progress: 0.0,
        message: 'Translating text...',
      ));

      final translationResult = await GeminiService.translateText(
        originalText,
        config.targetLanguage,
        sourceLanguage: config.sourceLanguage,
        preferredModel: config.preferredModel,
        context: config.context,
      );

      onProgress?.call(TranslationProgress(
        stage: TranslationStage.translation,
        progress: 1.0,
        message: 'Translation complete',
      ));

      // Stage 4: Caching and Rendering (75-100%)
      onProgress?.call(TranslationProgress(
        stage: TranslationStage.rendering,
        progress: 0.0,
        message: 'Caching translation...',
      ));

      // Save to cache
      if (config.useCache && !kIsWeb) {
        await TranslationCacheRepository.saveTranslation(
          originalText: originalText,
          translatedText: translationResult.translatedText,
          targetLanguage: config.targetLanguage,
          result: translationResult,
          context: config.context?.toString(),
        );
      }

      onProgress?.call(TranslationProgress(
        stage: TranslationStage.rendering,
        progress: 1.0,
        message: 'Complete',
      ));

      stopwatch.stop();
      AppLogger.info(
        'Translation pipeline complete in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'TranslationPipeline',
      );

      return PipelineTranslationResult(
        originalText: originalText,
        translatedText: translationResult.translatedText,
        ocrResult: ocrResult,
        translationResult: translationResult,
        fromCache: false,
      );
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Translation pipeline failed', error: e, tag: 'TranslationPipeline');
      rethrow;
    }
  }

  /// Translate specific region (speech bubble)
  static Future<PipelineTranslationResult> translateRegion(
    String imagePath,
    Rect region, {
    required PipelineConfig config,
    void Function(TranslationProgress)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('Translation pipeline not initialized. Call initialize() first.');
    }

    try {
      // Extract text from region
      onProgress?.call(TranslationProgress(
        stage: TranslationStage.textRecognition,
        progress: 0.5,
        message: 'Extracting text from region...',
      ));

      final originalText = await OcrService.extractTextFromRegion(
        imagePath,
        region,
        language: config.ocrLanguage,
      );

      if (originalText.isEmpty) {
        throw Exception('No text found in selected region');
      }

      onProgress?.call(TranslationProgress(
        stage: TranslationStage.translation,
        progress: 0.0,
        message: 'Translating...',
      ));

      // Translate
      final translationResult = await GeminiService.translateText(
        originalText,
        config.targetLanguage,
        sourceLanguage: config.sourceLanguage,
        preferredModel: config.preferredModel,
        context: config.context,
      );

      onProgress?.call(TranslationProgress(
        stage: TranslationStage.rendering,
        progress: 1.0,
        message: 'Complete',
      ));

      return PipelineTranslationResult(
        originalText: originalText,
        translatedText: translationResult.translatedText,
        textRegion: region,
        translationResult: translationResult,
        fromCache: false,
      );
    } catch (e) {
      AppLogger.error('Region translation failed', error: e, tag: 'TranslationPipeline');
      rethrow;
    }
  }

  /// Batch translate multiple images
  static Future<List<PipelineTranslationResult>> translateBatch(
    List<String> imagePaths, {
    required PipelineConfig config,
    void Function(TranslationProgress)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('Translation pipeline not initialized. Call initialize() first.');
    }

    final results = <PipelineTranslationResult>[];

    for (int i = 0; i < imagePaths.length; i++) {
      onProgress?.call(TranslationProgress(
        stage: TranslationStage.preprocessing,
        progress: i / imagePaths.length,
        message: 'Processing image ${i + 1} of ${imagePaths.length}',
        current: i + 1,
        total: imagePaths.length,
      ));

      try {
        final result = await translateImage(
          imagePaths[i],
          config: config,
          onProgress: (progress) {
            // Adjust progress to account for batch
            final adjustedProgress = TranslationProgress(
              stage: progress.stage,
              progress: (i + progress.progress) / imagePaths.length,
              message: progress.message,
              current: i + 1,
              total: imagePaths.length,
            );
            onProgress?.call(adjustedProgress);
          },
        );

        results.add(result);
      } catch (e) {
        AppLogger.error('Failed to translate image ${i + 1}', error: e, tag: 'TranslationPipeline');
        // Continue with next image
      }

      // Small delay between images to avoid rate limiting
      if (i < imagePaths.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return results;
  }

  /// Translate manual text entry
  static Future<PipelineTranslationResult> translateText(
    String text, {
    required PipelineConfig config,
    void Function(TranslationProgress)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('Translation pipeline not initialized. Call initialize() first.');
    }

    onProgress?.call(TranslationProgress(
      stage: TranslationStage.translation,
      progress: 0.0,
      message: 'Translating text...',
    ));

    final translationResult = await GeminiService.translateText(
      text,
      config.targetLanguage,
      sourceLanguage: config.sourceLanguage,
      preferredModel: config.preferredModel,
      context: config.context,
    );

    onProgress?.call(TranslationProgress(
      stage: TranslationStage.rendering,
      progress: 1.0,
      message: 'Complete',
    ));

    return PipelineTranslationResult(
      originalText: text,
      translatedText: translationResult.translatedText,
      translationResult: translationResult,
      fromCache: false,
    );
  }

  /// Reset pipeline
  static void reset() {
    _isInitialized = false;
    GeminiService.reset();
    AppLogger.info('Translation pipeline reset', tag: 'TranslationPipeline');
  }

  /// Get pipeline statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final stats = <String, dynamic>{};

    if (!kIsWeb) {
      try {
        final cacheStats = await TranslationCacheRepository.getStatistics();
        stats['cache'] = {
          'totalEntries': cacheStats.totalEntries,
          'totalSize': cacheStats.totalSize,
          'totalUsage': cacheStats.totalUsageCount,
          'averageRating': cacheStats.averageRating,
          'favorited': cacheStats.favoritedCount,
          'languageDistribution': cacheStats.languageDistribution,
        };
      } catch (e) {
        AppLogger.error('Failed to get cache statistics', error: e, tag: 'TranslationPipeline');
      }
    }

    stats['initialized'] = _isInitialized;
    return stats;
  }
}
