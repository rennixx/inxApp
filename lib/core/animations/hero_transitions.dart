import 'package:flutter/material.dart';

/// Custom page route with animation
class AnimatedPageRoute extends PageRouteBuilder {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final SlideDirection slideDirection;

  AnimatedPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.slideDirection = SlideDirection.right,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(animation, secondaryAnimation, child, curve, slideDirection);
          },
        );

  static Widget _buildTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    Curve curve,
    SlideDirection slideDirection,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    switch (slideDirection) {
      case SlideDirection.left:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      case SlideDirection.right:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      case SlideDirection.up:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      case SlideDirection.down:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      case SlideDirection.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      case SlideDirection.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
    }
  }
}

/// Slide direction enum
enum SlideDirection {
  left,
  right,
  up,
  down,
  fade,
  scale,
}

/// Hero animation wrapper for manga details
class HeroTransition {
  static const String coverTag = 'manga_cover';
  static const String titleTag = 'manga_title';
  static const String authorTag = 'manga_author';

  /// Create hero widget for cover image
  static Widget buildCoverHero({
    required Widget child,
    required String mangaId,
  }) {
    return Hero(
      tag: '${coverTag}_$mangaId',
      child: child,
    );
  }

  /// Create hero widget for title
  static Widget buildTitleHero({
    required Widget child,
    required String mangaId,
  }) {
    return Hero(
      tag: '${titleTag}_$mangaId',
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }

  /// Create hero widget for author
  static Widget buildAuthorHero({
    required Widget child,
    required String mangaId,
  }) {
    return Hero(
      tag: '${authorTag}_$mangaId',
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// Shared axis transition (Material Design 3 style)
class SharedAxisTransition extends PageRouteBuilder {
  final Widget child;
  final SharedAxisTransitionType transitionType;
  final Duration duration;

  SharedAxisTransition({
    required this.child,
    required this.transitionType,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transitionType) {
              case SharedAxisTransitionType.scaled:
                return _buildScaledTransition(animation, secondaryAnimation, child);
              case SharedAxisTransitionType.horizontal:
                return _buildHorizontalTransition(animation, secondaryAnimation, child);
              case SharedAxisTransitionType.vertical:
                return _buildVerticalTransition(animation, secondaryAnimation, child);
            }
          },
        );

  static Widget _buildScaledTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return Transform.scale(
          scale: 0.8 + (0.2 * curvedAnimation.value),
          child: Opacity(
            opacity: curvedAnimation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget _buildHorizontalTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          )),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget _buildVerticalTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          )),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

enum SharedAxisTransitionType {
  scaled,
  horizontal,
  vertical,
}

/// Fade through transition (for switching between tabs/pages with similar content)
class FadeThroughTransition extends PageRouteBuilder {
  final Widget child;
  final Duration duration;

  FadeThroughTransition({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            );

            final fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOut,
              ),
            );

            return Stack(
              children: [
                FadeTransition(
                  opacity: fadeOutAnimation,
                  child: child,
                ),
                FadeTransition(
                  opacity: fadeInAnimation,
                  child: child,
                ),
              ],
            );
          },
        );
}

/// Container transform (Material Design 3 style)
class ContainerTransform extends PageRouteBuilder {
  final Widget child;
  final Duration duration;

  ContainerTransform({
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final curveValue = Curves.easeInOut.transform(animation.value);

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..scale(0.8 + (0.2 * curveValue))
                    ..translate(0.0, 50 * (1 - curveValue)),
                  child: Opacity(
                    opacity: curveValue,
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
        );
}

/// Zoom in page transition
class ZoomInTransition extends PageRouteBuilder {
  final Widget child;
  final Duration duration;

  ZoomInTransition({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );

            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                ),
                child: child,
              ),
            );
          },
        );
}

/// Slide out page transition (for dismissing screens)
class SlideOutTransition extends PageRouteBuilder {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;

  SlideOutTransition({
    required this.child,
    this.direction = SlideDirection.down,
    this.duration = const Duration(milliseconds: 250),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            );

            Offset beginOffset;
            switch (direction) {
              case SlideDirection.up:
                beginOffset = const Offset(0, -1);
                break;
              case SlideDirection.down:
                beginOffset = const Offset(0, 1);
                break;
              case SlideDirection.left:
                beginOffset = const Offset(-1, 0);
                break;
              case SlideDirection.right:
                beginOffset = const Offset(1, 0);
                break;
              default:
                beginOffset = Offset.zero;
            }

            return SlideTransition(
              position: Tween<Offset>(
                begin: beginOffset,
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                ),
                child: child,
              ),
            );
          },
        );
}

/// Animated dialog with scale and fade
class AnimatedDialog extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedDialog({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
