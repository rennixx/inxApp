import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Floating draggable translation bubble with animated states
class FloatingTranslationBubble extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final TranslationBubbleState state;
  final String? errorMessage;

  const FloatingTranslationBubble({
    super.key,
    required this.onTap,
    this.onDismiss,
    this.state = TranslationBubbleState.idle,
    this.errorMessage,
  });

  @override
  State<FloatingTranslationBubble> createState() => _FloatingTranslationBubbleState();
}

class _FloatingTranslationBubbleState extends State<FloatingTranslationBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  Offset _position = const Offset(20, 100);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );

    if (widget.state == TranslationBubbleState.idle) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FloatingTranslationBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      switch (widget.state) {
        case TranslationBubbleState.idle:
          _animationController.repeat(reverse: true);
          break;
        case TranslationBubbleState.processing:
          _animationController.repeat();
          break;
        case TranslationBubbleState.complete:
        case TranslationBubbleState.error:
          _animationController.stop();
          _animationController.reset();
          break;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      _isDragging = true;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      // Constrain to screen bounds
      final screenSize = MediaQuery.sizeOf(context);
      _position = Offset(
        _position.dx.clamp(0.0, screenSize.width - 60),
        _position.dy.clamp(0.0, screenSize.height - 60),
      );
    });
  }

  Color _getBubbleColor() {
    switch (widget.state) {
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

  IconData _getBubbleIcon() {
    switch (widget.state) {
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: _handleDragUpdate,
        onPanEnd: _handleDragEnd,
        onTap: () {
          if (!_isDragging) {
            widget.onTap();
          }
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            double scale = 1.0;
            double rotation = 0.0;

            if (widget.state == TranslationBubbleState.idle) {
              scale = _pulseAnimation.value;
            } else if (widget.state == TranslationBubbleState.processing) {
              rotation = _rotateAnimation.value;
            }

            return Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: rotation,
                child: _buildBubble(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _getBubbleColor(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getBubbleColor().withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            _getBubbleIcon(),
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

enum TranslationBubbleState {
  /// Bubble is idle and waiting for user interaction
  idle,

  /// Translation is in progress
  processing,

  /// Translation completed successfully
  complete,

  /// Translation failed
  error,
}
