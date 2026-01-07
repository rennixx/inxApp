import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../domain/entities/manga.dart';
import '../../../core/theme/glass_container.dart';
import '../../../core/theme/shimmer_loading.dart';
import '../../../data/services/web_file_storage.dart';

/// Netflix-style glassmorphic manga card
class NetflixMangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? aspectRatio;
  final bool showProgress;

  const NetflixMangaCard({
    super.key,
    required this.manga,
    this.onTap,
    this.onLongPress,
    this.aspectRatio = 0.65,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with Progress
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cover Image
                _buildCoverImage(context),

                // Favorite Badge
                if (manga.isFavorited)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildFavoriteBadge(),
                  ),

                // Progress Bar
                if (showProgress && manga.readingProgress > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildProgressBar(context),
                  ),
              ],
            ),
          ),

          // Info Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  manga.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Metadata Row
                Row(
                  children: [
                    // File Type Icon
                    Icon(
                      _getFileTypeIcon(manga.fileType),
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),

                    const SizedBox(width: 4),

                    // Pages
                    Text(
                      '${manga.currentPage}/${manga.totalPages}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                    ),

                    const Spacer(),

                    // Last Read
                    if (manga.lastRead != null)
                      Icon(
                        PhosphorIcons.clock(PhosphorIconsStyle.regular),
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.5),
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
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
        ),
      );
    } else if (kIsWeb) {
      // Web platform: try to load from WebFileStorage
      final bytes = WebFileStorage.getFile(manga.filePath);
      if (bytes != null) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder(context);
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: child,
              );
            },
          ),
        );
      }
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Icon(
          _getFileTypeIcon(manga.fileType),
          size: 48,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildFavoriteBadge() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336).withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF44336).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        PhosphorIcons.heart(PhosphorIconsStyle.fill),
        size: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Container(
      height: 3,
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
    );
  }

  IconData _getFileTypeIcon(FileType type) {
    switch (type) {
      case FileType.cbz:
        return PhosphorIcons.fileArchive(PhosphorIconsStyle.regular);
      case FileType.pdf:
        return PhosphorIcons.filePdf(PhosphorIconsStyle.regular);
      case FileType.image:
        return PhosphorIcons.image(PhosphorIconsStyle.regular);
      case FileType.folder:
        return PhosphorIcons.folder(PhosphorIconsStyle.regular);
      default:
        return PhosphorIcons.file(PhosphorIconsStyle.regular);
    }
  }
}

/// Loading skeleton for Netflix-style cards
class NetflixMangaCardSkeleton extends StatelessWidget {
  final double? aspectRatio;

  const NetflixMangaCardSkeleton({
    super.key,
    this.aspectRatio = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerMangaCard(aspectRatio: aspectRatio);
  }
}
