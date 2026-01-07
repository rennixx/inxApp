import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/manga_repository.dart';
import '../../domain/entities/manga.dart';
import '../../data/services/web_file_storage.dart';
import 'import_provider.dart';

class MangaLibraryState {
  final List<Manga> manga;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  MangaLibraryState({
    this.manga = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  MangaLibraryState copyWith({
    List<Manga>? manga,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return MangaLibraryState(
      manga: manga ?? this.manga,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Manga> get filteredManga {
    if (searchQuery.isEmpty) return manga;
    final query = searchQuery.toLowerCase();
    return manga.where((m) =>
      m.title.toLowerCase().contains(query) ||
      (m.author?.toLowerCase().contains(query) ?? false) ||
      m.tags.any((t) => t.toLowerCase().contains(query))
    ).toList();
  }

  List<Manga> get favorites => manga.where((m) => m.isFavorited).toList();
  List<Manga> get recentlyRead => manga.where((m) => m.lastRead != null).toList()
    ..sort((a, b) => b.lastRead!.compareTo(a.lastRead!));
}

class MangaLibraryNotifier extends StateNotifier<MangaLibraryState> {
  final MangaRepository _repository;

  MangaLibraryNotifier(this._repository) : super(MangaLibraryState()) {
    loadLibrary();
  }

  Future<void> loadLibrary() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // On web, read from WebFileStorage
      // On native platforms, read from SQLite via repository
      final manga = kIsWeb
          ? WebFileStorage.getAllManga()
          : await _repository.getMangaList();

      state = state.copyWith(
        manga: manga,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> toggleFavorite(String id) async {
    if (kIsWeb) {
      // On web, update the manga in WebFileStorage
      final mangaList = WebFileStorage.getAllManga();
      final manga = mangaList.firstWhere((m) => m.id == id);

      // Create updated manga with toggled favorite
      final updatedManga = Manga(
        id: manga.id,
        title: manga.title,
        filePath: manga.filePath,
        fileType: manga.fileType,
        fileSize: manga.fileSize,
        coverPath: manga.coverPath,
        author: manga.author,
        tags: manga.tags,
        currentPage: manga.currentPage,
        totalPages: manga.totalPages,
        readingProgress: manga.readingProgress,
        isFavorited: !manga.isFavorited,
        lastRead: manga.lastRead,
        createdAt: manga.createdAt,
        updatedAt: DateTime.now(),
      );

      // Re-index the updated manga
      WebFileStorage.indexManga(manga.filePath, updatedManga);
    } else {
      // On native platforms, use repository
      await _repository.toggleFavorite(id);
    }
    await loadLibrary();
  }

  Future<void> deleteManga(String id) async {
    if (kIsWeb) {
      // On web, remove from WebFileStorage
      final mangaList = WebFileStorage.getAllManga();
      final manga = mangaList.firstWhere((m) => m.id == id);
      WebFileStorage.removeManga(manga.filePath);
    } else {
      // On native platforms, use repository
      await _repository.deleteManga(id);
    }
    await loadLibrary();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> searchManga(String query) async {
    if (query.isEmpty) {
      await loadLibrary();
      return;
    }

    state = state.copyWith(isLoading: true, searchQuery: query);

    try {
      final results = await _repository.searchManga(query);
      state = state.copyWith(
        manga: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadLibrary();
  }
}

final mangaLibraryProvider = StateNotifierProvider<MangaLibraryNotifier, MangaLibraryState>((ref) {
  final repository = ref.watch(mangaRepositoryProvider);
  return MangaLibraryNotifier(repository);
});
