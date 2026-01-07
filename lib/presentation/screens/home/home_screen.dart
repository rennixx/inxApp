import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../domain/entities/manga.dart';
import '../../../core/animations/hero_transitions.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../widgets/manga_grid_item.dart';
import '../reader/vertical_reader_screen.dart';
import '../../providers/manga_library_provider.dart';
import 'widgets/continue_reading_section.dart';
import 'widgets/recently_added_section.dart';
import 'widgets/favorites_carousel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show/hide search bar based on scroll position
    final showSearchBar = _scrollController.hasClients &&
        _scrollController.offset > 100;

    if (showSearchBar != _showSearchBar) {
      setState(() {
        _showSearchBar = showSearchBar;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    ref.read(homeSearchProvider.notifier).setSearchQuery(value);
  }

  void _openMangaDetails(Manga manga) {
    // Navigate to manga detail screen with hero animation
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MangaDetailScreen(manga: manga),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(mangaLibraryProvider);
    final filteredManga = _searchQuery.isEmpty
        ? libraryState.manga
        : libraryState.manga.where((manga) {
            final query = _searchQuery.toLowerCase();
            return manga.title.toLowerCase().contains(query) ||
                (manga.author?.toLowerCase().contains(query) ?? false);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
                        color: Colors.white,
                        size: 28,
                        key: const ValueKey('app_bar_icon'),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'INX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (libraryState.manga.isNotEmpty)
                    Text(
                      '${libraryState.manga.length} titles',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showSearchBar
                      ? PhosphorIcons.x(PhosphorIconsStyle.regular)
                      : PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
                  color: Colors.white,
                  key: ValueKey('search_$_showSearchBar'),
                ),
                onPressed: () {
                  setState(() {
                    if (_showSearchBar) {
                      _searchController.clear();
                      _onSearchChanged('');
                    }
                    _showSearchBar = !_showSearchBar;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  PhosphorIcons.gear(PhosphorIconsStyle.regular),
                  color: Colors.white,
                  key: const ValueKey('settings_icon'),
                ),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),

          // Search Bar (animated)
          if (_showSearchBar)
            SliverToBoxAdapter(
              child: AnimatedSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            ),

          // Continue Reading Section
          if (_getContinueReadingManga(libraryState.manga).isNotEmpty)
            ContinueReadingSection(
              manga: _getContinueReadingManga(libraryState.manga),
              onMangaTap: _openMangaDetails,
            ),

          // Favorites Carousel
          if (_getFavoriteManga(libraryState.manga).isNotEmpty)
            FavoritesCarousel(
              manga: _getFavoriteManga(libraryState.manga),
              onMangaTap: _openMangaDetails,
            ),

          // Recently Added Section
          RecentlyAddedSection(
            manga: _getRecentlyAddedManga(libraryState.manga),
            onMangaTap: _openMangaDetails,
          ),

          // All Manga Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final manga = filteredManga[index];
                  return MangaGridItem(
                    manga: manga,
                    onTap: () => _openMangaDetails(manga),
                    onLongPress: () => _showMangaOptions(manga),
                    onFavoriteToggle: () => _toggleFavorite(manga),
                  );
                },
                childCount: filteredManga.length,
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  List<Manga> _getContinueReadingManga(List<Manga> allManga) {
    return allManga
        .where((m) => m.readingProgress > 0 && m.readingProgress < 1.0)
        .toList()
      ..sort((a, b) => b.lastRead?.compareTo(a.lastRead ?? DateTime.now()) ?? 0);
  }

  List<Manga> _getFavoriteManga(List<Manga> allManga) {
    return allManga.where((m) => m.isFavorited).toList()
      ..sort((a, b) => b.lastRead?.compareTo(a.lastRead ?? DateTime.now()) ?? 0);
  }

  List<Manga> _getRecentlyAddedManga(List<Manga> allManga) {
    return allManga.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _toggleFavorite(Manga manga) {
    ref.read(mangaLibraryProvider.notifier).toggleFavorite(manga.id);
  }

  void _showMangaOptions(Manga manga) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMangaOptionsSheet(manga),
    );
  }

  Widget _buildMangaOptionsSheet(Manga manga) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                manga.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ListTile(
              leading: Icon(
                PhosphorIcons.bookOpen(PhosphorIconsStyle.regular),
                color: Colors.white,
              ),
              title: const Text(
                'Continue Reading',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _openReader(manga);
              },
            ),
            ListTile(
              leading: Icon(
                manga.isFavorited
                    ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                    : PhosphorIcons.heart(PhosphorIconsStyle.regular),
                color: manga.isFavorited
                    ? const Color(0xFFF44336)
                    : Colors.white,
              ),
              title: Text(
                manga.isFavorited ? 'Remove from Favorites' : 'Add to Favorites',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _toggleFavorite(manga);
              },
            ),
            ListTile(
              leading: Icon(
                PhosphorIcons.trash(PhosphorIconsStyle.regular),
                color: Colors.white,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDelete(manga);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openReader(Manga manga) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VerticalReaderScreen(manga: manga),
      ),
    );
  }

  void _confirmDelete(Manga manga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Delete Manga?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${manga.title}"?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6C5CE7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(mangaLibraryProvider.notifier).deleteManga(manga.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
                  color: Colors.white,
                ),
                title: const Text(
                  'Search Library',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _showSearchBar = true;
                  });
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.regular),
                  color: Colors.white,
                ),
                title: const Text(
                  'Import Files',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // Navigate to import screen
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.gear(PhosphorIconsStyle.regular),
                  color: Colors.white,
                ),
                title: const Text(
                  'Preferences',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // Navigate to preferences screen
                },
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.info(PhosphorIconsStyle.regular),
                  color: Colors.white,
                ),
                title: const Text(
                  'About',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAbout();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'INX Manga Reader',
      applicationVersion: '1.0.0',
      applicationLegalese: '\u00a9 2024 INX Project. All rights reserved.',
      children: [
        const Text(
          'A modern manga reader with OLED-optimized UI and AI-powered translation.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

/// Animated search bar widget
class AnimatedSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const AnimatedSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
              color: Colors.white,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search manga...',
                hintStyle: TextStyle(
                  color: Colors.white54,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                PhosphorIcons.x(PhosphorIconsStyle.regular),
                color: Colors.white,
              ),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}

/// Home search provider
final homeSearchProvider = StateNotifierProvider<HomeSearchNotifier, HomeSearchState>((ref) {
  return HomeSearchNotifier();
});

class HomeSearchState {
  final String searchQuery;
  final String sortBy;
  final String filterBy;

  HomeSearchState({
    this.searchQuery = '',
    this.sortBy = 'recent',
    this.filterBy = 'all',
  });

  HomeSearchState copyWith({
    String? searchQuery,
    String? sortBy,
    String? filterBy,
  }) {
    return HomeSearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      filterBy: filterBy ?? this.filterBy,
    );
  }
}

class HomeSearchNotifier extends StateNotifier<HomeSearchState> {
  HomeSearchNotifier() : super(HomeSearchState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setFilterBy(String filterBy) {
    state = state.copyWith(filterBy: filterBy);
  }
}

/// Manga detail screen (placeholder)
class MangaDetailScreen extends StatelessWidget {
  final Manga manga;

  const MangaDetailScreen({
    super.key,
    required this.manga,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: HeroTransition.buildCoverHero(
                mangaId: manga.id,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover image
                    _buildCoverImage(),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  HeroTransition.buildTitleHero(
                    mangaId: manga.id,
                    child: Text(
                      manga.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Author
                  if (manga.author != null)
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.user(PhosphorIconsStyle.regular),
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          manga.author!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    children: [
                      _buildStat(
                        icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.regular),
                        label: '${manga.currentPage}/${manga.totalPages}',
                      ),
                      const SizedBox(width: 24),
                      _buildStat(
                        icon: PhosphorIcons.chartLine(PhosphorIconsStyle.regular),
                        label: '${(manga.readingProgress * 100).toInt()}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
                          label: 'Read',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => VerticalReaderScreen(manga: manga),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: PhosphorIcons.heart(
                            manga.isFavorited
                                ? PhosphorIconsStyle.fill
                                : PhosphorIconsStyle.regular,
                          ),
                          label: manga.isFavorited ? 'Favorited' : 'Favorite',
                          color: manga.isFavorited
                              ? const Color(0xFFF44336)
                              : Colors.white,
                          onTap: () {
                            // Toggle favorite
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    // Implement cover image display
    return Container(
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }

  Widget _buildStat({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GlassmorphismCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
