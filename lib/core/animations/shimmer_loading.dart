import 'package:flutter/material.dart';

/// Shimmer animation widget for loading states
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF1E1E1E),
    this.highlightColor = const Color(0xFF2A2A2A),
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// Custom gradient transform for sliding animation
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// AI Processing shimmer effect overlay
class AIProcessingShimmer extends StatelessWidget {
  final Size size;
  final Color accentColor;
  final bool isActive;

  const AIProcessingShimmer({
    super.key,
    required this.size,
    this.accentColor = const Color(0xFF6C5CE7),
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // Scanning line effect
          _buildScanningLine(),
          // Pulse dots
          _buildPulseDots(),
        ],
      ),
    );
  }

  Widget _buildScanningLine() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return CustomPaint(
          size: size,
          painter: _ScanningLinePainter(
            progress: value,
            color: accentColor,
          ),
        );
      },
    );
  }

  Widget _buildPulseDots() {
    return Positioned.fill(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return TweenAnimationBuilder<double>(
              key: ValueKey('pulse_$index'),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                final delay = index * 0.2;
                final adjustedValue = ((value - delay).clamp(0.0, 1.0));
                final opacity = (1 - adjustedValue).abs();

                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

/// Custom painter for scanning line effect
class _ScanningLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanningLinePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lineY = size.height * progress;

    // Gradient line
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.8),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromLTWH(0, lineY - 2, size.width, 4);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRect(
      Rect.fromLTWH(0, lineY - 10, size.width, 20),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanningLinePainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}

/// Shimmer widget for manga grid items
class MangaGridShimmer extends StatelessWidget {
  final double aspectRatio;

  const MangaGridShimmer({
    super.key,
    this.aspectRatio = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
            // Title placeholder
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer widget for text lines
class TextShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const TextShimmer({
    super.key,
    required this.width,
    this.height = 14,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Shimmer widget for circular avatars
class CircleShimmer extends StatelessWidget {
  final double diameter;

  const CircleShimmer({
    super.key,
    this.diameter = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
