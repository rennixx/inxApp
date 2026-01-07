import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/entities/manga.dart';
import '../../../widgets/manga_grid_item.dart';

/// Recently added section widget
class RecentlyAddedSection extends StatelessWidget {
  final List<Manga> manga;
  final ValueChanged<Manga> onMangaTap;

  const RecentlyAddedSection({
    super.key,
    required this.manga,
    required this.onMangaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (manga.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayManga = manga.take(6).toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
                  color: const Color(0xFF00CED1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recently Added',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CED1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${displayManga.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: displayManga.length,
              itemBuilder: (context, index) {
                final item = displayManga[index];
                return MangaGridItem(
                  manga: item,
                  onTap: () => onMangaTap(item),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
