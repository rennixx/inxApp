import 'dart:ui';
import 'package:flutter/material.dart';

/// Pull-to-refresh indicator with glassmorphic styling
class GlassRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? indicatorColor;
  final double indicatorSize;

  const GlassRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.indicatorColor,
    this.indicatorSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: indicatorColor ?? const Color(0xFF2196F3),
      backgroundColor: Colors.transparent,
      displacement: 60,
      strokeWidth: 3,
      child: child,
    );
  }
}

/// Glassmorphic loading overlay for pull-to-refresh
class GlassRefreshOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final double progress;
  final double indicatorSize;

  const GlassRefreshOverlay({
    super.key,
    required this.isLoading,
    this.message,
    this.progress = 0.0,
    this.indicatorSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: indicatorSize,
                      height: indicatorSize,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        color: const Color(0xFF2196F3),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message ?? 'Refreshing...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (progress > 0)
                            Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom refresh header with glass effect
class GlassRefreshHeader extends StatelessWidget {
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final double? indicatorValue;

  const GlassRefreshHeader({
    super.key,
    this.refreshTriggerPullDistance = 80.0,
    this.refreshIndicatorExtent = 60.0,
    this.indicatorValue,
  });

  @override
  Widget build(BuildContext context) {
    if (indicatorValue == null || indicatorValue! <= 0) {
      return const SizedBox.shrink();
    }

    final clampedValue = indicatorValue!.clamp(0.0, 1.0);

    return Container(
      height: refreshIndicatorExtent * clampedValue,
      alignment: Alignment.center,
      child: Opacity(
        opacity: clampedValue,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2196F3),
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pull to refresh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple pull-to-refresh wrapper with glass styling
class GlassPullToRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;

  const GlassPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.isLoading = false,
    this.loadingMessage,
  });

  @override
  State<GlassPullToRefresh> createState() => _GlassPullToRefreshState();
}

class _GlassPullToRefreshState extends State<GlassPullToRefresh> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: const Color(0xFF2196F3),
          backgroundColor: Colors.transparent,
          displacement: 80,
          strokeWidth: 3,
          child: widget.child,
        ),
        if (widget.isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF2196F3),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.loadingMessage ?? 'Refreshing...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
