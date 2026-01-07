import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphic percentage indicator with circular and linear variants
class GlassPercentageIndicator extends StatelessWidget {
  final double percentage;
  final String? label;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final bool isCircular;

  const GlassPercentageIndicator({
    super.key,
    required this.percentage,
    this.label,
    this.size = 60,
    this.strokeWidth = 6,
    this.progressColor,
    this.backgroundColor,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isCircular) {
      return _buildCircularIndicator(context);
    }
    return _buildLinearIndicator(context);
  }

  Widget _buildCircularIndicator(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (backgroundColor ?? Colors.white.withValues(alpha: 0.1))
                  .withValues(alpha: 0.3),
            ),
          ),

          // Progress circle
          ShaderMask(
            shaderCallback: (bounds) {
              return SweepGradient(
                startAngle: -3.14 / 2,
                endAngle: 3.14 * 1.5,
                colors: [
                  progressColor ?? const Color(0xFF2196F3),
                  const Color(0xFF4CAF50),
                ],
                stops: const [0.0, 1.0],
                transform: const GradientRotation(3.14),
              ).createShader(bounds);
            },
            child: CircularProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          // Center content
          Center(
            child: Text(
              label ?? '${(percentage * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: size / 5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearIndicator(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          height: strokeWidth * 2,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(strokeWidth),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(strokeWidth),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? const Color(0xFF2196F3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Glassmorphic floating action button with Phosphor icons
class GlassFloatingActionButton extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool enableShadow;

  const GlassFloatingActionButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56,
    this.enableShadow = true,
  });

  @override
  State<GlassFloatingActionButton> createState() => _GlassFloatingActionButtonState();
}

class _GlassFloatingActionButtonState extends State<GlassFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (widget.backgroundColor ?? const Color(0xFF2196F3))
                    .withValues(alpha: 0.8),
                (widget.backgroundColor ?? const Color(0xFF4CAF50))
                    .withValues(alpha: 0.6),
              ],
            ),
            boxShadow: widget.enableShadow
                ? [
                    BoxShadow(
                      color: (widget.backgroundColor ?? const Color(0xFF2196F3))
                          .withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                alignment: Alignment.center,
                child: Icon(
                  widget.icon,
                  size: widget.size / 2.5,
                  color: widget.foregroundColor ?? Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) {
      return button;
    }

    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
      },
      onTapUp: (_) {
        _animationController.reverse();
      },
      onTapCancel: () {
        _animationController.reverse();
      },
      child: Tooltip(
        message: widget.tooltip!,
        child: button,
      ),
    );
  }
}

/// Glassmorphic FAB with extended label
class GlassExtendedFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool enableShadow;

  const GlassExtendedFloatingActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.enableShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (backgroundColor ?? const Color(0xFF2196F3)).withValues(alpha: 0.8),
            (backgroundColor ?? const Color(0xFF4CAF50)).withValues(alpha: 0.6),
          ],
        ),
        boxShadow: enableShadow
            ? [
                BoxShadow(
                  color: (backgroundColor ?? const Color(0xFF2196F3))
                      .withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: foregroundColor ?? Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick action button for common operations
class GlassQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool showBadge;
  final String? badgeValue;

  const GlassQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.showBadge = false,
    this.badgeValue,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color ?? Colors.white.withValues(alpha: 0.8),
                ),
                if (showBadge)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badgeValue ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
