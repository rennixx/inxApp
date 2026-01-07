import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../domain/entities/manga.dart';
import 'vertical_reader_screen.dart';
import 'widgets/floating_translation_bubble.dart';
import 'widgets/translation_provider.dart';

/// Wrapper for reader screen with guaranteed bubble visibility
class ReaderWrapper extends ConsumerStatefulWidget {
  final Manga manga;

  const ReaderWrapper({
    super.key,
    required this.manga,
  });

  @override
  ConsumerState<ReaderWrapper> createState() => _ReaderWrapperState();
}

class _ReaderWrapperState extends ConsumerState<ReaderWrapper> {
  bool _bubbleVisible = true;

  @override
  Widget build(BuildContext context) {
    final translationState = ref.watch(translationProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Reader screen content
          VerticalReaderScreen(manga: widget.manga),

          // Debug info overlay
          Positioned(
            top: 80,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bubble State: ${translationState.bubbleState.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Bubble Visible: $_bubbleVisible',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Is Create Mode: ${translationState.isCreateMode}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // Floating Translation Bubble (Always visible for testing)
          if (_bubbleVisible)
            Positioned(
              left: 20,
              top: 150,
              child: GestureDetector(
                onTap: () {
                  print('Bubble tapped!');
                  ref.read(translationProvider.notifier).startTranslation();
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getBubbleColor(translationState.bubbleState),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getBubbleColor(translationState.bubbleState).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getBubbleIcon(translationState.bubbleState),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBubbleColor(TranslationBubbleState state) {
    switch (state) {
      case TranslationBubbleState.idle:
        return const Color(0xFF6C5CE7);
      case TranslationBubbleState.processing:
        return const Color(0xFF00B894);
      case TranslationBubbleState.complete:
        return const Color(0xFF00B894);
      case TranslationBubbleState.error:
        return const Color(0xFFE74C3C);
    }
  }

  IconData _getBubbleIcon(TranslationBubbleState state) {
    switch (state) {
      case TranslationBubbleState.idle:
        return PhosphorIcons.magicWand(PhosphorIconsStyle.fill);
      case TranslationBubbleState.processing:
        return PhosphorIcons.spinner(PhosphorIconsStyle.fill);
      case TranslationBubbleState.complete:
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
      case TranslationBubbleState.error:
        return PhosphorIcons.warningCircle(PhosphorIconsStyle.fill);
    }
  }
}
