import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/manga.dart';
import '../providers/manga_library_provider.dart';
import '../widgets/manga_grid_item.dart';
import '../widgets/app_empty_state.dart';
import 'reader/vertical_reader_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(mangaLibraryProvider.notifier).loadLibrary());
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(mangaLibraryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    AppStrings.libraryTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular)),
                    onPressed: () => _showSearchDialog(context),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.sortAscending(PhosphorIconsStyle.regular)),
                    onPressed: () => _showSortDialog(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: libraryState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : libraryState.filteredManga.isEmpty
                      ? AppEmptyState(
                          icon: PhosphorIcons.filmStrip(PhosphorIconsStyle.regular),
                          title: AppStrings.libraryEmpty,
                          subtitle: AppStrings.libraryEmptyHint,
                        )
                      : _buildMangaGrid(libraryState.filteredManga),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMangaGrid(List<Manga> manga) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: manga.length,
      itemBuilder: (context, index) {
        final item = manga[index];
        return MangaGridItem(
          manga: item,
          onTap: () => _onMangaTap(item),
          onLongPress: () => _onMangaLongPress(item),
          onFavoriteToggle: () {
            ref.read(mangaLibraryProvider.notifier).toggleFavorite(item.id);
          },
        );
      },
    );
  }

  void _onMangaTap(Manga manga) {
    // TODO: Navigate to reader screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(manga.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (manga.author != null) Text('Author: ${manga.author}'),
            Text('Type: ${manga.fileType.name}'),
            Text('Pages: ${manga.currentPage}/${manga.totalPages}'),
            Text('Progress: ${manga.formattedProgress}'),
            if (manga.fileSize != null) Text('Size: ${manga.formattedFileSize}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VerticalReaderScreen(manga: manga),
                ),
              );
            },
            child: const Text('Read'),
          ),
        ],
      ),
    );
  }

  void _onMangaLongPress(Manga manga) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(manga.isFavorited
                  ? PhosphorIcons.heartBreak(PhosphorIconsStyle.regular)
                  : PhosphorIcons.heart(PhosphorIconsStyle.regular)),
              title: Text(manga.isFavorited ? 'Remove from favorites' : 'Add to favorites'),
              onTap: () {
                Navigator.pop(context);
                ref.read(mangaLibraryProvider.notifier).toggleFavorite(manga.id);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.trash(PhosphorIconsStyle.regular)),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(manga);
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.info(PhosphorIconsStyle.regular)),
              title: const Text('Details'),
              onTap: () {
                Navigator.pop(context);
                _onMangaTap(manga);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Library'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by title, author, or tags...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            ref.read(mangaLibraryProvider.notifier).setSearchQuery(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(mangaLibraryProvider.notifier).setSearchQuery('');
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(PhosphorIcons.textAa(PhosphorIconsStyle.regular)),
              title: const Text('Title'),
              onTap: () {
                Navigator.pop(context);
                // Sort by title
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.calendar(PhosphorIconsStyle.regular)),
              title: const Text('Date Added'),
              onTap: () {
                Navigator.pop(context);
                // Sort by date
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.bookOpen(PhosphorIconsStyle.regular)),
              title: const Text('Recently Read'),
              onTap: () {
                Navigator.pop(context);
                // Sort by recently read
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Manga manga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Manga?'),
        content: Text('Are you sure you want to delete "${manga.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(mangaLibraryProvider.notifier).deleteManga(manga.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
