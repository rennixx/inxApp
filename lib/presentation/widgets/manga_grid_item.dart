import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../domain/entities/manga.dart';
import '../../core/theme/glassmorphism.dart';
import '../../data/services/web_file_storage.dart';

class MangaGridItem extends StatelessWidget {
  final Manga manga;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;

  const MangaGridItem({
    super.key,
    required this.manga,
    this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCoverImage(context),
                if (manga.isFavorited) _buildFavoriteBadge(),
                if (manga.readingProgress > 0) _buildProgressIndicator(context),
              ],
            ),
          ),

          // Title and Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manga.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (manga.author != null) ...[
                      Icon(
                        PhosphorIcons.user(PhosphorIconsStyle.regular),
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          manga.author!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.bookOpen(PhosphorIconsStyle.regular),
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${manga.currentPage}/${manga.totalPages}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    if (manga.lastRead != null)
                      Text(
                        _formatDate(manga.lastRead!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    if (manga.coverPath != null && !kIsWeb) {
      // Native platform: use Image.file
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.file(
          manga.coverPath as File,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(context);
          },
        ),
      );
    } else if (kIsWeb && manga.coverPath != null) {
      // Web platform: load from WebFileStorage
      final bytes = WebFileStorage.getFile(manga.coverPath!);
      if (bytes != null) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(context);
            },
          ),
        );
      }
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    IconData iconData;

    switch (manga.fileType) {
      case FileType.cbz:
        iconData = PhosphorIcons.fileArchive(PhosphorIconsStyle.regular);
        break;
      case FileType.pdf:
        iconData = PhosphorIcons.filePdf(PhosphorIconsStyle.regular);
        break;
      case FileType.image:
        iconData = PhosphorIcons.image(PhosphorIconsStyle.regular);
        break;
      case FileType.folder:
        iconData = PhosphorIcons.folder(PhosphorIconsStyle.regular);
        break;
      default:
        iconData = PhosphorIcons.file(PhosphorIconsStyle.regular);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 48,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildFavoriteBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336).withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          PhosphorIcons.heart(PhosphorIconsStyle.fill),
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: LinearProgressIndicator(
          value: manga.readingProgress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }
}
