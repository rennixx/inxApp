import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Represents a translated text overlay positioned on a manga page
class TranslationOverlay {
  final String id;
  final Rect position;
  final String translatedText;
  final String originalText;
  final double fontSize;

  TranslationOverlay({
    required this.id,
    required this.position,
    required this.translatedText,
    required this.originalText,
    this.fontSize = 14.0,
  });

  TranslationOverlay copyWith({
    String? id,
    Rect? position,
    String? translatedText,
    String? originalText,
    double? fontSize,
  }) {
    return TranslationOverlay(
      id: id ?? this.id,
      position: position ?? this.position,
      translatedText: translatedText ?? this.translatedText,
      originalText: originalText ?? this.originalText,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

/// Widget that displays translated text overlays on manga pages
class TranslationOverlayPainter extends StatelessWidget {
  final List<TranslationOverlay> overlays;
  final double opacity;
  final bool showOriginal;
  final VoidCallback? onOverlayTap;

  const TranslationOverlayPainter({
    super.key,
    required this.overlays,
    this.opacity = 0.95,
    this.showOriginal = false,
    this.onOverlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: overlays.map((overlay) {
        return _TranslationOverlayWidget(
          overlay: overlay,
          opacity: opacity,
          showOriginal: showOriginal,
          onTap: onOverlayTap,
        );
      }).toList(),
    );
  }
}

class _TranslationOverlayWidget extends StatelessWidget {
  final TranslationOverlay overlay;
  final double opacity;
  final bool showOriginal;
  final VoidCallback? onTap;

  const _TranslationOverlayWidget({
    required this.overlay,
    required this.opacity,
    required this.showOriginal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = showOriginal ? overlay.originalText : overlay.translatedText;

    return Positioned(
      left: overlay.position.left,
      top: overlay.position.top,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: overlay.position.width,
          height: overlay.position.height,
          constraints: BoxConstraints(
            minWidth: 80.0,
            minHeight: 40.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              displayText,
              style: GoogleFonts.notoSans(
                fontSize: overlay.fontSize,
                color: Colors.black87,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: null,
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for creating new translation overlays by tapping on the page
class TranslationOverlayCreator extends StatefulWidget {
  final Size pageSize;
  final Function(Rect) onOverlayCreated;

  const TranslationOverlayCreator({
    super.key,
    required this.pageSize,
    required this.onOverlayCreated,
  });

  @override
  State<TranslationOverlayCreator> createState() => _TranslationOverlayCreatorState();
}

class _TranslationOverlayCreatorState extends State<TranslationOverlayCreator> {
  Offset? _startPosition;
  Offset? _currentPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _startPosition = details.localPosition;
          _currentPosition = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _currentPosition = details.localPosition;
        });
      },
      onPanEnd: (details) {
        if (_startPosition != null && _currentPosition != null) {
          final rect = Rect.fromPoints(
            _startPosition!,
            _currentPosition!,
          );

          // Only create if rect has meaningful size
          if (rect.width > 20 && rect.height > 20) {
            widget.onOverlayCreated(rect);
          }
        }

        setState(() {
          _startPosition = null;
          _currentPosition = null;
        });
      },
      child: Container(
        width: widget.pageSize.width,
        height: widget.pageSize.height,
        color: Colors.transparent,
        child: CustomPaint(
          painter: _SelectionPainter(
            startPosition: _startPosition,
            currentPosition: _currentPosition,
          ),
        ),
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  final Offset? startPosition;
  final Offset? currentPosition;

  _SelectionPainter({
    this.startPosition,
    this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (startPosition != null && currentPosition != null) {
      final rect = Rect.fromPoints(startPosition!, currentPosition!);

      final paint = Paint()
        ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = const Color(0xFF6C5CE7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      // Draw corner handles
      _drawCornerHandle(canvas, rect.topLeft);
      _drawCornerHandle(canvas, rect.topRight);
      _drawCornerHandle(canvas, rect.bottomLeft);
      _drawCornerHandle(canvas, rect.bottomRight);
    }
  }

  void _drawCornerHandle(Canvas canvas, Offset position) {
    final handlePaint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 6.0, handlePaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return startPosition != oldDelegate.startPosition ||
        currentPosition != oldDelegate.currentPosition;
  }
}

/// Controls for managing translation overlays
class TranslationOverlayControls extends StatelessWidget {
  final double opacity;
  final bool showOriginal;
  final bool showOverlays;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onToggleOriginal;
  final VoidCallback onToggleOverlays;
  final VoidCallback onClearOverlays;
  final VoidCallback onCreateMode;

  const TranslationOverlayControls({
    super.key,
    required this.opacity,
    required this.showOriginal,
    required this.showOverlays,
    required this.onOpacityChanged,
    required this.onToggleOriginal,
    required this.onToggleOverlays,
    required this.onClearOverlays,
    required this.onCreateMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOpacitySlider(),
          const SizedBox(height: 8.0),
          _buildToggleButtons(),
        ],
      ),
    );
  }

  Widget _buildOpacitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.opacity,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Overlay Opacity',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: opacity,
          onChanged: onOpacityChanged,
          min: 0.3,
          max: 1.0,
          divisions: 7,
          activeColor: const Color(0xFF6C5CE7),
        ),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildToggleButton(
          icon: Icons.translate,
          label: showOriginal ? 'Original' : 'Translated',
          isActive: showOriginal,
          onPressed: onToggleOriginal,
        ),
        _buildToggleButton(
          icon: showOverlays ? Icons.visibility : Icons.visibility_off,
          label: 'Show',
          isActive: showOverlays,
          onPressed: onToggleOverlays,
        ),
        _buildToggleButton(
          icon: Icons.add_box,
          label: 'Add',
          isActive: false,
          onPressed: onCreateMode,
        ),
        _buildToggleButton(
          icon: Icons.clear_all,
          label: 'Clear',
          isActive: false,
          onPressed: onClearOverlays,
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: isActive ? const Color(0xFF6C5CE7) : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
