import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/services/translation_pipeline_service.dart';
import '../../../../data/services/ocr_service.dart';
import '../../../../data/services/gemini_service.dart';
import '../../../../data/services/image_editor_service.dart';
import '../../../../core/utils/logger.dart';
import 'translation_overlay.dart';
import 'floating_translation_bubble.dart';

/// State for translation overlay system
class TranslationState {
  final List<TranslationOverlay> overlays;
  final TranslationBubbleState bubbleState;
  final double overlayOpacity;
  final bool showOriginalText;
  final bool showOverlays;
  final bool isCreateMode;
  final String? errorMessage;
  final String? currentImagePath;
  final bool autoTranslateEnabled;
  final Set<String> translatedPages; // Track which pages have been translated
  final String? editedImagePath; // Path to the image with burned-in translations
  final String? originalImagePath; // Store original image path for OCR

  TranslationState({
    this.overlays = const [],
    this.bubbleState = TranslationBubbleState.idle,
    this.overlayOpacity = 0.95,
    this.showOriginalText = false,
    this.showOverlays = true,
    this.isCreateMode = false,
    this.errorMessage,
    this.currentImagePath,
    bool? autoTranslateEnabled,
    Set<String>? translatedPages,
    this.editedImagePath,
    this.originalImagePath,
  }) : autoTranslateEnabled = autoTranslateEnabled ?? false,
       translatedPages = translatedPages ?? const {};

  TranslationState copyWith({
    List<TranslationOverlay>? overlays,
    TranslationBubbleState? bubbleState,
    double? overlayOpacity,
    bool? showOriginalText,
    bool? showOverlays,
    bool? isCreateMode,
    String? errorMessage,
    String? currentImagePath,
    bool? autoTranslateEnabled,
    Set<String>? translatedPages,
    String? editedImagePath,
    String? originalImagePath,
  }) {
    return TranslationState(
      overlays: overlays ?? this.overlays,
      bubbleState: bubbleState ?? this.bubbleState,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      showOriginalText: showOriginalText ?? this.showOriginalText,
      showOverlays: showOverlays ?? this.showOverlays,
      isCreateMode: isCreateMode ?? this.isCreateMode,
      errorMessage: errorMessage ?? this.errorMessage,
      currentImagePath: currentImagePath ?? this.currentImagePath,
      autoTranslateEnabled: autoTranslateEnabled,
      translatedPages: translatedPages,
      editedImagePath: editedImagePath ?? this.editedImagePath,
      originalImagePath: originalImagePath ?? this.originalImagePath,
    );
  }

  /// Factory to handle migration from old state format
  factory TranslationState.fromJson(Map<String, dynamic> json) {
    return TranslationState(
      overlays: json['overlays'] as List<TranslationOverlay>? ?? const [],
      bubbleState: json['bubbleState'] as TranslationBubbleState? ?? TranslationBubbleState.idle,
      overlayOpacity: (json['overlayOpacity'] as num?)?.toDouble() ?? 0.95,
      showOriginalText: json['showOriginalText'] as bool? ?? false,
      showOverlays: json['showOverlays'] as bool? ?? true,
      isCreateMode: json['isCreateMode'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      currentImagePath: json['currentImagePath'] as String?,
      autoTranslateEnabled: json['autoTranslateEnabled'] as bool? ?? false,
      translatedPages: (json['translatedPages'] as Set<String>?) ?? {},
    );
  }
}

/// Notifier for managing translation overlays and bubble state
class TranslationNotifier extends StateNotifier<TranslationState> {
  TranslationNotifier() : super(TranslationState());
  String? _lastTranslatedPath;

  /// Toggle auto-translate mode
  void toggleAutoTranslate() {
    final newState = !state.autoTranslateEnabled;
    state = state.copyWith(autoTranslateEnabled: newState);

    if (newState && state.currentImagePath != null) {
      // Start translating immediately when enabled
      translateCurrentPage();
    }

    AppLogger.info('Auto-translate ${newState ? "enabled" : "disabled"}', tag: 'Translation');
  }

  /// Set the current image path for translation
  void setCurrentImagePath(String path) {
    // Store the original path for OCR purposes
    state = state.copyWith(
      currentImagePath: path,
      originalImagePath: path,
    );

    // Auto-translate if enabled and this page hasn't been translated yet
    if (state.autoTranslateEnabled &&
        path != _lastTranslatedPath &&
        !state.translatedPages.contains(path)) {
      translateCurrentPage();
    }
  }

  /// Translate the current page
  Future<void> translateCurrentPage() async {
    if (state.originalImagePath == null) {
      AppLogger.warning('No image to translate', tag: 'Translation');
      return;
    }

    // Use original image path for OCR, not the edited one
    final imagePathForOcr = state.originalImagePath!;

    // Skip if already translated this page
    if (state.translatedPages.contains(imagePathForOcr)) {
      AppLogger.info('Page already translated, skipping', tag: 'Translation');
      return;
    }

    // Don't translate if currently processing another page
    if (state.bubbleState == TranslationBubbleState.processing) {
      AppLogger.info('Already processing, skipping', tag: 'Translation');
      return;
    }

    _lastTranslatedPath = imagePathForOcr;

    state = state.copyWith(
      bubbleState: TranslationBubbleState.processing,
      errorMessage: null,
    );

    try {
      // Check if pipeline is initialized
      if (!TranslationPipelineService.isInitialized) {
        throw Exception('Translation pipeline not initialized. Please check your API key.');
      }

      AppLogger.info('Translating: $imagePathForOcr', tag: 'Translation');

      // Perform actual translation using the pipeline
      final config = PipelineConfig(
        targetLanguage: 'en',
        ocrLanguage: OcrLanguage.chinese, // Chinese for manhua
        preferredModel: GeminiModel.flash,
        useCache: true,
      );

      final result = await TranslationPipelineService.translateImage(
        imagePathForOcr,
        config: config,
        onProgress: (progress) {
          AppLogger.debug(
            'Progress: ${progress.stage} - ${(progress.progress * 100).toInt()}%',
            tag: 'Translation',
          );
        },
      );

      AppLogger.info('Translation completed: ${result.translatedText}', tag: 'Translation');

      // Check if we have OCR results with multiple text regions
      if (result.ocrResult != null && result.ocrResult!.textRegions.isNotEmpty) {
        // Process ALL detected text regions
        final stamps = <TranslationStamp>[];
        final ocrRegions = result.ocrResult!.textRegions;

        AppLogger.info('Found ${ocrRegions.length} text regions, processing all...', tag: 'Translation');
        AppLogger.info('OCR detected text: ${result.ocrResult!.fullText}', tag: 'Translation');

        // OPTIMIZATION: Use the already-translated text from the pipeline result
        // The pipeline already translated the full text, so we can use that directly
        // instead of making additional API calls for each region

        // Split the translated text by newlines to match the OCR regions
        final translatedLines = result.translatedText.split('\n');

        for (int i = 0; i < ocrRegions.length; i++) {
          final region = ocrRegions[i];
          AppLogger.info('Processing region ${i + 1}/${ocrRegions.length}: "${region.text}"', tag: 'Translation');

          // Use the corresponding translated line, or fallback to the original text
          // if we don't have enough translated lines
          final translatedText = i < translatedLines.length
              ? translatedLines[i]
              : result.translatedText; // Fallback to full translation

          final stamp = TranslationStamp(
            text: translatedText,
            region: region.boundingBox,
            fontSize: (region.boundingBox.height * 0.6).clamp(16.0, 48.0), // Increased font size
            fontFamily: 'Roboto',
            textColor: const Color(0xFF000000),
            backgroundColor: const Color(0xFFFFFFFF),
            opacity: 0.95,
          );

          stamps.add(stamp);
          AppLogger.info('✓ Region ${i + 1} translated: "${translatedText}"', tag: 'Translation');
        }

        // Burn all translations into the image at once (using original image)
        if (stamps.isNotEmpty) {
          final editResult = await ImageEditorService.burnMultipleTranslations(
            imagePath: imagePathForOcr, // Use original image path!
            stamps: stamps,
          );

          AppLogger.info('Burned ${stamps.length} translations into image: ${editResult.editedImagePath}', tag: 'Translation');

          // Mark this page as translated and store edited image path
          final updatedTranslatedPages = {...state.translatedPages, imagePathForOcr};
          state = state.copyWith(
            bubbleState: TranslationBubbleState.complete,
            translatedPages: updatedTranslatedPages,
            editedImagePath: editResult.editedImagePath,
            overlays: [], // Clear overlays since we're using burned-in text
          );
        } else {
          throw Exception('No translations were successfully generated');
        }
      } else if (result.textRegion != null) {
        // Fallback: Single region from old API
        final editResult = await ImageEditorService.burnTranslation(
          imagePath: imagePathForOcr, // Use original image path!
          translatedText: result.translatedText,
          region: result.textRegion!,
          fontSize: (result.textRegion!.height * 0.6).clamp(16.0, 48.0), // Increased font size
          fontFamily: 'Roboto',
          textColor: const Color(0xFF000000),
          backgroundColor: const Color(0xFFFFFFFF),
          opacity: 0.95,
        );

        AppLogger.info('Translation burned into image: ${editResult.editedImagePath}', tag: 'Translation');

        // Mark this page as translated and store edited image path
        final updatedTranslatedPages = {...state.translatedPages, imagePathForOcr};
        state = state.copyWith(
          bubbleState: TranslationBubbleState.complete,
          translatedPages: updatedTranslatedPages,
          editedImagePath: editResult.editedImagePath,
          overlays: [], // Clear overlays since we're using burned-in text
        );
      } else {
        // No OCR region data - create overlay with full text
        AppLogger.warning('No OCR region data, falling back to overlay', tag: 'Translation');
        final overlay = _createSmartOverlay(
          result: result,
          imagePath: imagePathForOcr,
        );

        final updatedTranslatedPages = {...state.translatedPages, imagePathForOcr};
        state = state.copyWith(
          overlays: [overlay],
          bubbleState: TranslationBubbleState.complete,
          translatedPages: updatedTranslatedPages,
        );
      }

      AppLogger.info('Translation complete, total translated: ${state.translatedPages.length}', tag: 'Translation');

      // Reset to idle after a short delay
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        bubbleState: TranslationBubbleState.idle,
      );
    } catch (e) {
      AppLogger.error('Translation failed', error: e, tag: 'Translation');

      // Provide user-friendly error messages
      String userMessage = e.toString();
      if (e.toString().contains('No text detected') || e.toString().contains('No text found')) {
        userMessage = 'No text detected on this page. This might be an action scene or page without dialogue.';
      } else if (e.toString().contains('Translation pipeline not initialized')) {
        userMessage = 'Please configure your Gemini API key in settings.';
      } else if (e.toString().contains('API Error')) {
        userMessage = 'Translation API error. Please check your connection.';
      }

      state = state.copyWith(
        bubbleState: TranslationBubbleState.error,
        errorMessage: userMessage,
      );

      // Reset to idle after error
      await Future.delayed(const Duration(seconds: 3));
      state = state.copyWith(
        bubbleState: TranslationBubbleState.idle,
        errorMessage: null,
      );
    }
  }

  /// Start translation process (bubble tapped) - manual trigger
  Future<void> startTranslation() async {
    if (!state.autoTranslateEnabled) {
      // If auto-translate is off, just translate the current page once
      await translateCurrentPage();
    } else {
      // If auto-translate is on, toggle it off
      toggleAutoTranslate();
    }
  }

  /// Add a new translation overlay
  void addOverlay(TranslationOverlay overlay) {
    final updatedOverlays = [...state.overlays, overlay];
    state = state.copyWith(overlays: updatedOverlays);
  }

  /// Remove a translation overlay by ID
  void removeOverlay(String id) {
    final updatedOverlays = state.overlays.where((o) => o.id != id).toList();
    state = state.copyWith(overlays: updatedOverlays);
  }

  /// Update an existing translation overlay
  void updateOverlay(TranslationOverlay overlay) {
    final updatedOverlays = state.overlays.map((o) {
      return o.id == overlay.id ? overlay : o;
    }).toList();
    state = state.copyWith(overlays: updatedOverlays);
  }

  /// Clear all translation overlays
  void clearOverlays() {
    state = state.copyWith(overlays: []);
  }

  /// Set overlay opacity
  void setOverlayOpacity(double opacity) {
    state = state.copyWith(overlayOpacity: opacity.clamp(0.3, 1.0));
  }

  /// Toggle between original and translated text
  void toggleOriginalText() {
    state = state.copyWith(
      showOriginalText: !state.showOriginalText,
    );
  }

  /// Toggle overlay visibility
  void toggleOverlayVisibility() {
    state = state.copyWith(
      showOverlays: !state.showOverlays,
    );
  }

  /// Enable/disable overlay creation mode
  void setCreateMode(bool enabled) {
    state = state.copyWith(
      isCreateMode: enabled,
    );
  }

  /// Handle overlay creation from user selection
  void handleOverlayCreation(Rect position, String translatedText) {
    final overlay = TranslationOverlay(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: position,
      translatedText: translatedText,
      originalText: 'Original text here', // TODO: Extract from image
    );

    addOverlay(overlay);

    // Exit create mode after adding
    setCreateMode(false);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset all translated pages cache
  void resetTranslatedPages() {
    state = state.copyWith(
      translatedPages: {},
      editedImagePath: null,
    );
    AppLogger.info('Translated pages cache cleared', tag: 'Translation');
  }

  /// Create an in-place translation stamp directly over the original text
  TranslationOverlay _createSmartOverlay({
    required PipelineTranslationResult result,
    required String imagePath,
  }) {
    final translatedText = result.translatedText;
    final originalRegion = result.textRegion;

    // If we have OCR region data, use it to position the translation exactly over the original text
    if (originalRegion != null) {
      // Use the exact same position as the original text
      // The overlay will cover and replace the original text
      final position = Rect.fromLTWH(
        originalRegion.left,
        originalRegion.top,
        originalRegion.width,
        originalRegion.height,
      );

      // Calculate font size based on the region height to fit well
      // Smaller region = smaller font, larger region = larger font
      final fontSize = (originalRegion.height * 0.4).clamp(10.0, 24.0);

      AppLogger.info(
        'Created in-place translation stamp: ${translatedText.length} chars over original region (${originalRegion.width.toStringAsFixed(0)}x${originalRegion.height.toStringAsFixed(0)}px) at (${originalRegion.left.toStringAsFixed(0)}, ${originalRegion.top.toStringAsFixed(0)})',
        tag: 'Translation',
      );

      return TranslationOverlay(
        id: '${imagePath}_${DateTime.now().millisecondsSinceEpoch}',
        position: position,
        translatedText: translatedText,
        originalText: result.originalText,
        fontSize: fontSize,
      );
    }

    // Fallback: No OCR region available, estimate from text
    final textLength = translatedText.length;
    const charWidth = 9.0;
    const lineHeight = 16.0;

    // Compact dimensions for in-place replacement
    final estimatedWidth = (textLength * charWidth).clamp(80.0, 250.0);
    final estimatedLines = (textLength * charWidth / estimatedWidth).ceil();
    final estimatedHeight = (estimatedLines * lineHeight) + 4.0;

    // Default position - try to place in a non-intrusive area
    final position = Rect.fromLTWH(
      20.0,
      20.0,
      estimatedWidth,
      estimatedHeight.clamp(30.0, 100.0),
    );

    AppLogger.info(
      'Created compact overlay (no OCR region): ${translatedText.length} chars, ${estimatedWidth.toStringAsFixed(0)}x${estimatedHeight.toStringAsFixed(0)}px',
      tag: 'Translation',
    );

    return TranslationOverlay(
      id: '${imagePath}_${DateTime.now().millisecondsSinceEpoch}',
      position: position,
      translatedText: translatedText,
      originalText: result.originalText,
      fontSize: 14.0,
    );
  }
}

/// Provider for translation state
final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  return TranslationNotifier();
});
