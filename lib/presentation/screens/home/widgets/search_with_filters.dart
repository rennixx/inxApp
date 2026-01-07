import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/entities/manga.dart';

/// Search state with debouncing and filters
class SearchWithFiltersState {
  final String query;
  final String sortBy;
  final String filterStatus;
  final String filterLanguage;
  final bool isSearching;
  final List<Manga> results;

  SearchWithFiltersState({
    this.query = '',
    this.sortBy = 'recent',
    this.filterStatus = 'all',
    this.filterLanguage = 'all',
    this.isSearching = false,
    this.results = const [],
  });

  SearchWithFiltersState copyWith({
    String? query,
    String? sortBy,
    String? filterStatus,
    String? filterLanguage,
    bool? isSearching,
    List<Manga>? results,
  }) {
    return SearchWithFiltersState(
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      filterStatus: filterStatus ?? this.filterStatus,
      filterLanguage: filterLanguage ?? this.filterLanguage,
      isSearching: isSearching ?? this.isSearching,
      results: results ?? this.results,
    );
  }
}

/// Search notifier with debouncing
class SearchWithFiltersNotifier extends StateNotifier<SearchWithFiltersState> {
  Timer? _debounceTimer;
  final List<Manga> _allManga;

  SearchWithFiltersNotifier(this._allManga) : super(SearchWithFiltersState());

  void setQuery(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately but don't search yet
    state = state.copyWith(query: query, isSearching: query.isNotEmpty);

    if (query.isEmpty) {
      state = state.copyWith(results: [], isSearching: false);
      return;
    }

    // Debounce search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
    if (state.query.isNotEmpty) {
      _performSearch();
    }
  }

  void setFilterStatus(String status) {
    state = state.copyWith(filterStatus: status);
    if (state.query.isNotEmpty) {
      _performSearch();
    }
  }

  void setFilterLanguage(String language) {
    state = state.copyWith(filterLanguage: language);
    if (state.query.isNotEmpty) {
      _performSearch();
    }
  }

  void _performSearch() {
    final query = state.query.toLowerCase();
    var results = _allManga.where((manga) {
      // Text search
      final matchesQuery = manga.title.toLowerCase().contains(query) ||
          (manga.author?.toLowerCase().contains(query) ?? false);

      if (!matchesQuery) return false;

      // Status filter
      if (state.filterStatus != 'all') {
        switch (state.filterStatus) {
          case 'reading':
            if (manga.readingProgress == 0 || manga.readingProgress >= 1.0) return false;
            break;
          case 'completed':
            if (manga.readingProgress < 1.0) return false;
            break;
          case 'unread':
            if (manga.readingProgress > 0) return false;
            break;
        }
      }

      return true;
    }).toList();

    // Sort results
    switch (state.sortBy) {
      case 'recent':
        results.sort((a, b) => b.lastRead?.compareTo(a.lastRead ?? DateTime.now()) ?? 0);
        break;
      case 'name':
        results.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'progress':
        results.sort((a, b) => b.readingProgress.compareTo(a.readingProgress));
        break;
      case 'favorites':
        results.sort((a, b) => b.isFavorited == a.isFavorited ? 0 : (b.isFavorited ? 1 : -1));
        break;
    }

    state = state.copyWith(results: results, isSearching: false);
  }

  void clear() {
    _debounceTimer?.cancel();
    state = SearchWithFiltersState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Search provider
final searchWithFiltersProvider =
    StateNotifierProvider.family<SearchWithFiltersNotifier, SearchWithFiltersState, List<Manga>>(
  (ref, mangaList) {
    return SearchWithFiltersNotifier(mangaList);
  },
);

/// Search widget with filters and sorting
class SearchWithFiltersWidget extends ConsumerWidget {
  final List<Manga> manga;
  final ValueChanged<Manga>? onMangaTap;

  const SearchWithFiltersWidget({
    super.key,
    required this.manga,
    this.onMangaTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchWithFiltersProvider(manga));

    return Column(
      children: [
        // Search bar
        _buildSearchBar(context, ref, searchState),
        // Filters
        if (searchState.query.isNotEmpty) _buildFilters(context, ref, searchState),
        // Results
        if (searchState.query.isNotEmpty)
          Expanded(
            child: _buildResults(context, searchState),
          ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, SearchWithFiltersState state) {
    return Container(
      margin: const EdgeInsets.all(16),
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
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search manga...',
                hintStyle: TextStyle(
                  color: Colors.white54,
                ),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                ref.read(searchWithFiltersProvider(manga).notifier).setQuery(value);
              },
            ),
          ),
          if (state.query.isNotEmpty)
            IconButton(
              icon: Icon(
                PhosphorIcons.x(PhosphorIconsStyle.regular),
                color: Colors.white,
              ),
              onPressed: () {
                ref.read(searchWithFiltersProvider(manga).notifier).clear();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, SearchWithFiltersState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Sort dropdown
          _buildFilterChip(
            label: _getSortLabel(state.sortBy),
            icon: PhosphorIcons.arrowsDownUp(PhosphorIconsStyle.regular),
            onTap: () => _showSortOptions(context, ref),
          ),
          // Status filter
          _buildFilterChip(
            label: _getStatusLabel(state.filterStatus),
            icon: PhosphorIcons.books(PhosphorIconsStyle.regular),
            onTap: () => _showStatusOptions(context, ref),
          ),
          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${state.results.length} results',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required PhosphorIconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchWithFiltersState state) {
    if (state.isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
              color: Colors.white.withValues(alpha: 0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final manga = state.results[index];
        return _buildMangaCard(manga);
      },
    );
  }

  Widget _buildMangaCard(Manga manga) {
    return GestureDetector(
      onTap: () => onMangaTap?.call(manga),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIcons.bookOpen(PhosphorIconsStyle.regular),
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 32,
                    key: ValueKey('manga_placeholder_${manga.id}'),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (manga.author != null)
                    Text(
                      manga.author!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (manga.readingProgress > 0)
                    LinearProgressIndicator(
                      value: manga.readingProgress,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'recent':
        return 'Recent';
      case 'name':
        return 'A-Z';
      case 'progress':
        return 'Progress';
      case 'favorites':
        return 'Favorites';
      default:
        return 'Sort';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'reading':
        return 'Reading';
      case 'completed':
        return 'Completed';
      case 'unread':
        return 'Unread';
      default:
        return 'All';
    }
  }

  void _showSortOptions(BuildContext context, WidgetRef ref) {
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSortOption(context, ref, 'Recent', 'recent', PhosphorIcons.clock(PhosphorIconsStyle.regular)),
              _buildSortOption(context, ref, 'A-Z', 'name', PhosphorIcons.sortAscending(PhosphorIconsStyle.regular)),
              _buildSortOption(context, ref, 'Progress', 'progress', PhosphorIcons.chartLine(PhosphorIconsStyle.regular)),
              _buildSortOption(context, ref, 'Favorites', 'favorites', PhosphorIcons.heart(PhosphorIconsStyle.regular)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, WidgetRef ref, String label, String value, PhosphorIconData icon) {
    final state = ref.watch(searchWithFiltersProvider(manga));
    final isSelected = state.sortBy == value;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              PhosphorIcons.check(PhosphorIconsStyle.fill),
              color: const Color(0xFF6C5CE7),
            )
          : null,
      onTap: () {
        ref.read(searchWithFiltersProvider(manga).notifier).setSortBy(value);
        Navigator.of(context).pop();
      },
    );
  }

  void _showStatusOptions(BuildContext context, WidgetRef ref) {
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filter by Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusOption(context, ref, 'All', 'all', PhosphorIcons.books(PhosphorIconsStyle.regular)),
              _buildStatusOption(context, ref, 'Reading', 'reading', PhosphorIcons.bookOpen(PhosphorIconsStyle.regular)),
              _buildStatusOption(context, ref, 'Completed', 'completed', PhosphorIcons.checkCircle(PhosphorIconsStyle.regular)),
              _buildStatusOption(context, ref, 'Unread', 'unread', PhosphorIcons.eye(PhosphorIconsStyle.regular)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(BuildContext context, WidgetRef ref, String label, String value, PhosphorIconData icon) {
    final state = ref.watch(searchWithFiltersProvider(manga));
    final isSelected = state.filterStatus == value;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              PhosphorIcons.check(PhosphorIconsStyle.fill),
              color: const Color(0xFF6C5CE7),
            )
          : null,
      onTap: () {
        ref.read(searchWithFiltersProvider(manga).notifier).setFilterStatus(value);
        Navigator.of(context).pop();
      },
    );
  }
}
