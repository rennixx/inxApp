import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Page transition types
enum PageTransitionType {
  fade,
  slide,
  scale,
  parallax,
}

/// Custom page turn animation
class PageTurnTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final PageTransitionType type;

  const PageTurnTransition({
    super.key,
    required this.child,
    required this.animation,
    this.type = PageTransitionType.parallax,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case PageTransitionType.fade:
        return _buildFadeTransition();
      case PageTransitionType.slide:
        return _buildSlideTransition();
      case PageTransitionType.scale:
        return _buildScaleTransition();
      case PageTransitionType.parallax:
        return _buildParallaxTransition();
    }
  }

  Widget _buildFadeTransition() {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  Widget _buildSlideTransition() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }

  Widget _buildScaleTransition() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  Widget _buildParallaxTransition() {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curveValue = Curves.easeOutCubic.transform(animation.value);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translate(0.0, 50 * (1 - curveValue))
            ..scale(0.95 + (0.05 * curveValue)),
          child: Opacity(
            opacity: curveValue,
            child: this.child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Parallax scrolling container for manga pages
class ParallaxScrollContainer extends StatefulWidget {
  final Widget child;
  final double parallaxFactor;
  final ScrollController? scrollController;

  const ParallaxScrollContainer({
    super.key,
    required this.child,
    this.parallaxFactor = 0.1,
    this.scrollController,
  });

  @override
  State<ParallaxScrollContainer> createState() => _ParallaxScrollContainerState();
}

class _ParallaxScrollContainerState extends State<ParallaxScrollContainer> {
  late ScrollController _internalController;
  ScrollController get _controller => widget.scrollController ?? _internalController;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _internalController = ScrollController();
    }
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _internalController.dispose();
    } else {
      _controller.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        setState(() {});
        return false;
      },
      child: CustomScrollView(
        controller: _controller,
        slivers: [
          SliverToBoxAdapter(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Vertical page turn with physics
class VerticalPageTurn extends StatelessWidget {
  final Widget child;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPageChanged;

  const VerticalPageTurn({
    super.key,
    required this.child,
    required this.currentPage,
    required this.totalPages,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      onPageChanged: onPageChanged != null ? (page) => onPageChanged!() : null,
      physics: const CustomPageTurnScrollPhysics(),
      itemCount: totalPages,
      itemBuilder: (context, index) {
        return AnimatedOpacity(
          opacity: index == currentPage ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 300),
          child: Transform.scale(
            scale: index == currentPage ? 1.0 : 0.95,
            child: child,
          ),
        );
      },
    );
  }
}

/// Custom scroll physics for page turning
class CustomPageTurnScrollPhysics extends ScrollPhysics {
  const CustomPageTurnScrollPhysics({super.parent});

  @override
  CustomPageTurnScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageTurnScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.5,
        stiffness: 100,
        damping: 0.7,
      );

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity * 0.9;
  }
}

/// Reading progress indicator with smooth animation
class ReadingProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color color;

  const ReadingProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.color = const Color(0xFF6C5CE7),
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalPages > 0 ? currentPage / totalPages : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Smooth momentum scrolling physics
class SmoothScrollPhysics extends ScrollPhysics {
  final double momentum;

  const SmoothScrollPhysics({
    this.momentum = 0.9,
    super.parent,
  });

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(
      momentum: momentum,
      parent: buildParent(ancestor),
    );
  }

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity * momentum;
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.8,
        stiffness: 80,
        damping: 0.6,
      );
}

/// Animated page number indicator
class AnimatedPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onTap;

  const AnimatedPageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: child,
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$currentPage / $totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
