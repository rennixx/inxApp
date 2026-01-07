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

  TranslationState({
    this.overlays = const [],
    this.bubbleState = TranslationBubbleState.idle,
    this.overlayOpacity = 0.95,
    this.showOriginalText = false,
    this.showOverlays = true,
    this.isCreateMode = false,
    this.errorMessage,
    this.currentImagePath,
  });

  TranslationState copyWith({
    List<TranslationOverlay>? overlays,
    TranslationBubbleState? bubbleState,
    double? overlayOpacity,
    bool? showOriginalText,
    bool? showOverlays,
    bool? isCreateMode,
    String? errorMessage,
    String? currentImagePath,
  }) {
    return TranslationState(
      overlays: overlays ?? this.overlays,
      bubbleState: bubbleState ?? this.bubbleState,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      showOriginalText: showOriginalText ?? this.showOriginalText,
      showOverlays: showOverlays ?? this.showOverlays,
      isCreateMode: isCreateMode ?? this.isCreateMode,
      errorMessage: errorMessage,
      currentImagePath: currentImagePath ?? this.currentImagePath,
    );
  }
}

/// Notifier for managing translation overlays and bubble state
class TranslationNotifier extends StateNotifier<TranslationState> {
  TranslationNotifier() : super(TranslationState());

  /// Set the current image path for translation
  void setCurrentImagePath(String path) {
    state = state.copyWith(currentImagePath: path);
  }

  /// Start translation process (bubble tapped)
  Future<void> startTranslation() async {
    if (state.currentImagePath == null) {
      state = state.copyWith(
        bubbleState: TranslationBubbleState.error,
        errorMessage: 'No image loaded',
      );
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(
        bubbleState: TranslationBubbleState.idle,
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      bubbleState: TranslationBubbleState.processing,
      errorMessage: null,
    );

    try {
      // Check if pipeline is initialized
      if (!TranslationPipelineService.isInitialized) {
        throw Exception('Translation pipeline not initialized. Please check your API key.');
      }

      AppLogger.info('Starting translation for: ${state.currentImagePath}', tag: 'Translation');

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
          AppLogger.info(
            'Translation progress: ${progress.stage} - ${(progress.progress * 100).toInt()}%',
            tag: 'Translation',
          );
        },
      );

      AppLogger.info('Translation completed: ${result.translatedText}', tag: 'Translation');

      // Create overlay from result
      final overlay = TranslationOverlay(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: result.textRegion ?? const Rect.fromLTWH(50, 50, 200, 100),
        translatedText: result.translatedText,
        originalText: result.originalText,
        fontSize: 14.0,
      );

      state = state.copyWith(
        overlays: [overlay],
        bubbleState: TranslationBubbleState.complete,
      );

      AppLogger.info('Translation overlay created', tag: 'Translation');

      // Auto-reset to idle after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(
        bubbleState: TranslationBubbleState.idle,
      );
    } catch (e) {
      AppLogger.error('Translation failed', error: e, tag: 'Translation');
      state = state.copyWith(
        bubbleState: TranslationBubbleState.error,
        errorMessage: e.toString(),
      );

      // Auto-reset to idle after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      state = state.copyWith(
        bubbleState: TranslationBubbleState.idle,
        errorMessage: null,
      );
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
}

/// Provider for translation state
final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  return TranslationNotifier();
});
