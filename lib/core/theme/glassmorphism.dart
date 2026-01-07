import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class GlassmorphismContainer extends StatelessWidget {
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

  const GlassmorphismContainer({
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Colors.white.withOpacity(opacity),
                Colors.white.withOpacity(opacity * 0.5),
              ],
            ),
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
  }
}

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismContainer(
      padding: padding,
      margin: margin,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}
