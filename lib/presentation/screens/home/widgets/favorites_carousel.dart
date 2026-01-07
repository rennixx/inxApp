import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/entities/manga.dart';
import '../../../widgets/netflix_manga_card.dart';

/// Favorites carousel widget
class FavoritesCarousel extends StatelessWidget {
  final List<Manga> manga;
  final ValueChanged<Manga> onMangaTap;

  const FavoritesCarousel({
    super.key,
    required this.manga,
    required this.onMangaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (manga.isEmpty) {
      return const SizedBox.shrink();
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.heart(PhosphorIconsStyle.fill),
                  color: const Color(0xFFF44336),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Favorites',
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
                    color: const Color(0xFFF44336),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${manga.length}',
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
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: manga.length,
              itemBuilder: (context, index) {
                final item = manga[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: 120,
                    child: NetflixMangaCard(
                      manga: item,
                      onTap: () => onMangaTap(item),
                      showProgress: true,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
