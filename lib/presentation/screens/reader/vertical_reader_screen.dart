import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../domain/entities/manga.dart';
import '../../../data/services/image_loader_service.dart';
import 'widgets/reader_controls_overlay.dart';
import 'widgets/reading_progress_bar.dart';
import 'widgets/zoomable_image_page.dart';
import 'widgets/floating_translation_bubble.dart';
import 'widgets/translation_overlay.dart';
import 'widgets/translation_provider.dart';

class VerticalReaderScreen extends ConsumerStatefulWidget {
  final Manga manga;

  const VerticalReaderScreen({
    super.key,
    required this.manga,
  });

  @override
  ConsumerState<VerticalReaderScreen> createState() => _VerticalReaderScreenState();
}

class _VerticalReaderScreenState extends ConsumerState<VerticalReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  bool _uiVisible = true;
  bool _autoScrollEnabled = false;
  double _brightness = 1.0;
  int _currentPage = 0;
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    _initializeReader();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeReader() async {
    final imagePaths = await ImageLoaderService.extractImages(
      widget.manga.filePath,
      widget.manga.fileType,
    );

    if (mounted) {
      setState(() {
        _imagePaths = imagePaths;
      });

      // Set the first image as the current translation target
      if (imagePaths.isNotEmpty) {
        ref.read(translationProvider.notifier).setCurrentImagePath(imagePaths[0]);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final progress = currentScroll / maxScroll;

      // Update reading progress
      ref.read(readerProgressProvider.notifier).updateProgress(
            widget.manga.id,
            (progress * _imagePaths.length).floor(),
            _imagePaths.length,
          );

      // Update current page
      final currentPage = (progress * _imagePaths.length).floor();
      if (_imagePaths.isNotEmpty && currentPage >= 0 && currentPage < _imagePaths.length) {
        setState(() {
          _currentPage = currentPage;
        });

        // Update translation provider with current image path
        ref.read(translationProvider.notifier).setCurrentImagePath(_imagePaths[currentPage]);
      }
    }
  }

  void _toggleUI() {
    setState(() {
      _uiVisible = !_uiVisible;
    });
  }

  void _toggleAutoScroll() {
    setState(() {
      _autoScrollEnabled = !_autoScrollEnabled;
    });

    if (_autoScrollEnabled) {
      _startAutoScroll();
    }
  }

  void _toggleTranslationMode() {
    ref.read(translationProvider.notifier).setCreateMode(true);
    setState(() {
      _uiVisible = true;
    });
  }

  void _startAutoScroll() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!_autoScrollEnabled || !mounted) return false;

      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (_scrollController.position.pixels < maxScroll) {
          _scrollController.animateTo(
            _scrollController.position.pixels + 2,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
          return true;
        }
      }
      return false;
    });
  }

  void _goToPreviousPage() {
    // For vertical scrolling ListView, we don't use PageController
    // Instead, we scroll up by one page height
    if (_scrollController.hasClients) {
      final currentPosition = _scrollController.position.pixels;
      final targetPosition = currentPosition - _scrollController.position.viewportDimension;
      if (targetPosition >= 0) {
        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _goToNextPage() {
    // For vertical scrolling ListView, we don't use PageController
    // Instead, we scroll down by one page height
    if (_scrollController.hasClients) {
      final currentPosition = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetPosition = currentPosition + _scrollController.position.viewportDimension;
      if (targetPosition <= maxScroll) {
        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onBrightnessChanged(double value) {
    setState(() {
      _brightness = value;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationState = ref.watch(translationProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Reader Content
          GestureDetector(
            onTap: _toggleUI,
            onLongPress: () {
              // Long press to show translation menu
            },
            child: _buildReaderContent(),
          ),

          // Reading Progress Bar
          if (_imagePaths.isNotEmpty && _uiVisible)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ReadingProgressBar(
                currentPage: _currentPage,
                totalPages: _imagePaths.length,
                scrollController: _scrollController,
              ),
            ),

          // Translation Overlays
          if (translationState.showOverlays && translationState.overlays.isNotEmpty)
            Positioned.fill(
              child: TranslationOverlayPainter(
                overlays: translationState.overlays,
                opacity: translationState.overlayOpacity,
                showOriginal: translationState.showOriginalText,
              ),
            ),

          // Floating Translation Bubble
          Positioned(
            left: 20,
            top: 100,
            child: FloatingTranslationBubble(
              state: translationState.bubbleState,
              errorMessage: translationState.errorMessage,
              onTap: () {
                print('Bubble tapped! Starting translation...');
                ref.read(translationProvider.notifier).startTranslation();
              },
            ),
          ),

          // Debug overlay (remove in production)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Auto: ${translationState.autoTranslateEnabled == true ? "ON" : "OFF"}',
                    style: TextStyle(
                      color: translationState.autoTranslateEnabled == true ? const Color(0xFF00B894) : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Bubble: ${translationState.bubbleState.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Page: $_currentPage/${_imagePaths.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Translated: ${translationState.translatedPages?.length ?? 0}',
                    style: const TextStyle(color: Color(0xFF6C5CE7), fontSize: 10),
                  ),
                  if (translationState.currentImagePath != null)
                    Text(
                      'Has Image: Yes',
                      style: const TextStyle(color: Color(0xFF00B894), fontSize: 10),
                    ),
                  Text(
                    'Overlays: ${translationState.overlays.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // Translation Controls (when visible)
          if (_uiVisible && translationState.isCreateMode)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: TranslationOverlayControls(
                opacity: translationState.overlayOpacity,
                showOriginal: translationState.showOriginalText,
                showOverlays: translationState.showOverlays,
                onOpacityChanged: (value) =>
                    ref.read(translationProvider.notifier).setOverlayOpacity(value),
                onToggleOriginal: () =>
                    ref.read(translationProvider.notifier).toggleOriginalText(),
                onToggleOverlays: () =>
                    ref.read(translationProvider.notifier).toggleOverlayVisibility(),
                onClearOverlays: () =>
                    ref.read(translationProvider.notifier).clearOverlays(),
                onCreateMode: () =>
                    ref.read(translationProvider.notifier).setCreateMode(true),
              ),
            ),

          // Controls Overlay
          if (_uiVisible)
            ReaderControlsOverlay(
              manga: widget.manga,
              currentPage: _currentPage,
              totalPages: _imagePaths.length,
              brightness: _brightness,
              autoScrollEnabled: _autoScrollEnabled,
              onPreviousPage: _goToPreviousPage,
              onNextPage: _goToNextPage,
              onBrightnessChanged: _onBrightnessChanged,
              onToggleAutoScroll: _toggleAutoScroll,
              onToggleTranslation: _toggleTranslationMode,
              onClose: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildReaderContent() {
    // Check if it's a PDF file on web (not supported yet)
    if (kIsWeb && widget.manga.fileType == FileType.pdf) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.filePdf(PhosphorIconsStyle.fill),
              size: 64,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'PDF reading is not yet supported on web',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please use CBZ files or images for web reading',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_imagePaths.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Container(
      color: Colors.black.withValues(alpha: _brightness),
      child: ListView.builder(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        itemCount: _imagePaths.length,
        itemBuilder: (context, index) {
          return ZoomableImagePage(
            imagePath: _imagePaths[index],
            page: index,
            brightness: _brightness,
          );
        },
      ),
    );
  }
}

// Provider for reading progress
final readerProgressProvider = StateNotifierProvider<ReaderProgressNotifier, ReaderProgressState>((ref) {
  return ReaderProgressNotifier();
});

class ReaderProgressState {
  final String? mangaId;
  final int currentPage;
  final int totalPages;
  final double progress;

  ReaderProgressState({
    this.mangaId,
    this.currentPage = 0,
    this.totalPages = 0,
    this.progress = 0.0,
  });

  ReaderProgressState copyWith({
    String? mangaId,
    int? currentPage,
    int? totalPages,
    double? progress,
  }) {
    return ReaderProgressState(
      mangaId: mangaId ?? this.mangaId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      progress: progress ?? this.progress,
    );
  }
}

class ReaderProgressNotifier extends StateNotifier<ReaderProgressState> {
  ReaderProgressNotifier() : super(ReaderProgressState());

  Future<void> updateProgress(String mangaId, int page, int total) async {
    final progress = total > 0 ? page / total : 0.0;

    state = state.copyWith(
      mangaId: mangaId,
      currentPage: page,
      totalPages: total,
      progress: progress,
    );

    // TODO: Save to repository
  }

  void reset() {
    state = ReaderProgressState();
  }
}
