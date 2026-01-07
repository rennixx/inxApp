import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/services/translation_pipeline_service.dart';
import '../../../../data/services/gemini_service.dart';
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

  TranslationState({
    this.overlays = const [],
    this.bubbleState = TranslationBubbleState.idle,
    this.overlayOpacity = 0.95,
    this.showOriginalText = false,
    this.showOverlays = true,
    this.isCreateMode = false,
    this.errorMessage,
  });

  TranslationState copyWith({
    List<TranslationOverlay>? overlays,
    TranslationBubbleState? bubbleState,
    double? overlayOpacity,
    bool? showOriginalText,
    bool? showOverlays,
    bool? isCreateMode,
    String? errorMessage,
  }) {
    return TranslationState(
      overlays: overlays ?? this.overlays,
      bubbleState: bubbleState ?? this.bubbleState,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      showOriginalText: showOriginalText ?? this.showOriginalText,
      showOverlays: showOverlays ?? this.showOverlays,
      isCreateMode: isCreateMode ?? this.isCreateMode,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for managing translation overlays and bubble state
class TranslationNotifier extends StateNotifier<TranslationState> {
  TranslationNotifier() : super(TranslationState());

  /// Start translation process (bubble tapped)
  Future<void> startTranslation() async {
    state = state.copyWith(
      bubbleState: TranslationBubbleState.processing,
      errorMessage: null,
    );

    try {
      // Check if pipeline is initialized
      if (!TranslationPipelineService.isInitialized) {
        throw Exception('Translation pipeline not initialized. Please check your API key.');
      }

      // For demo purposes, we'll simulate a translation
      // In production, this would trigger the full pipeline on current page
      await Future.delayed(const Duration(seconds: 1));

      // Simulate successful translation
      state = state.copyWith(
        bubbleState: TranslationBubbleState.complete,
      );

      // Auto-reset to idle after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(
        bubbleState: TranslationBubbleState.idle,
      );
    } catch (e) {
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
