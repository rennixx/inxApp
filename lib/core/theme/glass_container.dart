import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Enhanced glassmorphic container with shadow, blur, and customizable effects
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? gradient;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool shadowEnabled;
  final double shadowOpacity;
  final double elevation;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.gradient,
    this.blur = AppConstants.glassBlur,
    this.opacity = AppConstants.glassOpacity,
    this.onTap,
    this.onLongPress,
    this.shadowEnabled = true,
    this.shadowOpacity = 0.1,
    this.elevation = 8,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border ??
            Border.all(
              color: const Color(AppConstants.glassBorder),
              width: 1,
            ),
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: opacity),
                Colors.white.withValues(alpha: opacity * 0.5),
              ],
            ),
        boxShadow: shadowEnabled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowOpacity),
                  blurRadius: elevation.toDouble(),
                  offset: Offset(0, elevation / 2),
                  spreadRadius: -elevation / 4,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap == null && onLongPress == null) {
      return container;
    }

    return Material(
      color: Colors.transparent,
      child: container,
    );
  }
}

/// Simplified glass card for common use cases
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final double? elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      margin: margin,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      elevation: elevation ?? 8,
      child: child,
    );
  }
}

/// Glass container with no blur (frosted glass effect)
class FrostedGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color tintColor;
  final double opacity;

  const FrostedGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.tintColor = Colors.white,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        color: tintColor.withValues(alpha: opacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}
