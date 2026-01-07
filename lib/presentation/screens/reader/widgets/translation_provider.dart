import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/services/translation_pipeline_service.dart';
import '../../../../data/services/ocr_service.dart';
import '../../../../data/services/gemini_service.dart';
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
    state = state.copyWith(currentImagePath: path);

    // Auto-translate if enabled and this page hasn't been translated yet
    if (state.autoTranslateEnabled &&
        path != _lastTranslatedPath &&
        !state.translatedPages.contains(path)) {
      translateCurrentPage();
    }
  }

  /// Translate the current page
  Future<void> translateCurrentPage() async {
    if (state.currentImagePath == null) {
      AppLogger.warning('No image to translate', tag: 'Translation');
      return;
    }

    // Skip if already translated this page
    if (state.translatedPages.contains(state.currentImagePath)) {
      AppLogger.info('Page already translated, skipping', tag: 'Translation');
      return;
    }

    // Don't translate if currently processing another page
    if (state.bubbleState == TranslationBubbleState.processing) {
      AppLogger.info('Already processing, skipping', tag: 'Translation');
      return;
    }

    _lastTranslatedPath = state.currentImagePath;

    state = state.copyWith(
      bubbleState: TranslationBubbleState.processing,
      errorMessage: null,
    );

    try {
      // Check if pipeline is initialized
      if (!TranslationPipelineService.isInitialized) {
        throw Exception('Translation pipeline not initialized. Please check your API key.');
      }

      AppLogger.info('Translating: ${state.currentImagePath}', tag: 'Translation');

      // Perform actual translation using the pipeline
      final config = PipelineConfig(
        targetLanguage: 'en',
        ocrLanguage: OcrLanguage.japanese,
        preferredModel: GeminiModel.flash,
        useCache: true,
      );

      final result = await TranslationPipelineService.translateImage(
        state.currentImagePath!,
        config: config,
        onProgress: (progress) {
          AppLogger.debug(
            'Progress: ${progress.stage} - ${(progress.progress * 100).toInt()}%',
            tag: 'Translation',
          );
        },
      );

      AppLogger.info('Translation completed: ${result.translatedText}', tag: 'Translation');

      // Create overlay from result
      final overlay = TranslationOverlay(
        id: '${state.currentImagePath}_${DateTime.now().millisecondsSinceEpoch}',
        position: result.textRegion ?? const Rect.fromLTWH(50, 50, 200, 100),
        translatedText: result.translatedText,
        originalText: result.originalText,
        fontSize: 14.0,
      );

      // Mark this page as translated and add overlay
      final updatedTranslatedPages = {...state.translatedPages, state.currentImagePath!};
      state = state.copyWith(
        overlays: [overlay],
        bubbleState: TranslationBubbleState.complete,
        translatedPages: updatedTranslatedPages,
      );

      AppLogger.info('Overlay created, total translated: ${updatedTranslatedPages.length}', tag: 'Translation');

      // Reset to idle after a short delay
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        bubbleState: TranslationBubbleState.idle,
      );
    } catch (e) {
      AppLogger.error('Translation failed', error: e, tag: 'Translation');
      state = state.copyWith(
        bubbleState: TranslationBubbleState.error,
        errorMessage: e.toString(),
      );

      // Reset to idle after error
      await Future.delayed(const Duration(seconds: 2));
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
    state = state.copyWith(translatedPages: {});
    AppLogger.info('Translated pages cache cleared', tag: 'Translation');
  }
}

/// Provider for translation state
final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  return TranslationNotifier();
});
