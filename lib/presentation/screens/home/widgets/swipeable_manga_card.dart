import 'package:flutter/material.dart';
import '../../../../domain/entities/manga.dart';
import '../../../widgets/manga_grid_item.dart';

/// Swipe actions for manga items
enum SwipeAction {
  markRead,
  favorite,
  delete,
}

/// Swipeable manga card with actions
class SwipeableMangaCard extends StatefulWidget {
  final Manga manga;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;

  const SwipeableMangaCard({
    super.key,
    required this.manga,
    this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.onMarkRead,
    this.onDelete,
  });

  @override
  State<SwipeableMangaCard> createState() => _SwipeableMangaCardState();
}

class _SwipeableMangaCardState extends State<SwipeableMangaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isSwiping = false;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
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

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      // Limit the drag distance
      _dragOffset = _dragOffset.clamp(-150.0, 150.0);
    });

    if (!_isSwiping) {
      setState(() => _isSwiping = true);
      _animationController.forward();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final threshold = 100.0;

    if (_dragOffset > threshold) {
      // Swiped right - mark as read
      _performAction(SwipeAction.markRead);
    } else if (_dragOffset < -threshold) {
      // Swiped left - favorite
      _performAction(SwipeAction.favorite);
    } else {
      // Reset - didn't swipe far enough
      _resetSwipe();
    }
  }

  void _performAction(SwipeAction action) {
    // Trigger haptic feedback
    // HapticFeedback.mediumImpact();

    switch (action) {
      case SwipeAction.markRead:
        widget.onMarkRead?.call();
        break;
      case SwipeAction.favorite:
        widget.onFavoriteToggle?.call();
        break;
      case SwipeAction.delete:
        widget.onDelete?.call();
        break;
    }

    _resetSwipe();
  }

  void _resetSwipe() {
    setState(() {
      _dragOffset = 0.0;
      _isSwiping = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background actions
        _buildActionBackgrounds(),
        // Foreground card
        GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: MangaGridItem(
                manga: widget.manga,
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onFavoriteToggle: widget.onFavoriteToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBackgrounds() {
    return Positioned.fill(
      child: Row(
        children: [
          // Left side - mark as read
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                color: widget.manga.readingProgress >= 1.0
                    ? Colors.grey.withValues(alpha: 0.3)
                    : const Color(0xFF6C5CE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.manga.readingProgress >= 1.0
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.manga.readingProgress >= 1.0 ? 'Read' : 'Mark Read',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right side - favorite
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: widget.manga.isFavorited
                    ? Colors.grey.withValues(alpha: 0.3)
                    : const Color(0xFFF44336),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.manga.isFavorited
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.manga.isFavorited ? 'Favorited' : 'Favorite',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full swipeable card with delete option (long press to reveal delete)
class AdvancedSwipeableCard extends StatefulWidget {
  final Manga manga;
  final Widget child;
  final VoidCallback? onDelete;

  const AdvancedSwipeableCard({
    super.key,
    required this.manga,
    required this.child,
    this.onDelete,
  });

  @override
  State<AdvancedSwipeableCard> createState() => _AdvancedSwipeableCardState();
}

class _AdvancedSwipeableCardState extends State<AdvancedSwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showDelete = false;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() => _showDelete = true);
    _controller.forward();
    // HapticFeedback.heavyImpact();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() => _showDelete = false);
    _controller.reverse();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_showDelete) {
      setState(() {
        _dragOffset += details.delta.dx;
        _dragOffset = _dragOffset.clamp(-100.0, 0.0);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_showDelete && _dragOffset < -80) {
      widget.onDelete?.call();
    }
    setState(() => _dragOffset = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _showDelete ? null : _handleLongPressStart,
      onLongPressEnd: _showDelete ? null : _handleLongPressEnd,
      onHorizontalDragUpdate: _showDelete ? _handleDragUpdate : null,
      onHorizontalDragEnd: _showDelete ? _handleDragEnd : null,
      child: Stack(
        children: [
          // Delete background (shown on long press)
          if (_showDelete)
            Positioned.fill(
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Content
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 - (_controller.value * 0.05),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _showDelete
                            ? const Color(0xFFE74C3C)
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: child,
                  ),
                );
              },
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action button for manga grid
class MangaQuickActions extends StatelessWidget {
  final Manga manga;
  final VoidCallback? onMarkRead;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;

  const MangaQuickActions({
    super.key,
    required this.manga,
    this.onMarkRead,
    this.onFavorite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: manga.readingProgress >= 1.0
              ? Icons.check_circle
              : Icons.check_circle_outline,
          color: const Color(0xFF6C5CE7),
          onTap: onMarkRead,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: manga.isFavorited ? Icons.favorite : Icons.favorite_border,
          color: const Color(0xFFF44336),
          onTap: onFavorite,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.delete_outline,
          color: const Color(0xFFE74C3C),
          onTap: onDelete,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
      ),
    );
  }
}
