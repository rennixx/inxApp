import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/manga_collection.dart';

/// Collection state
class CollectionState {
  final List<MangaCollection> collections;
  final bool isLoading;
  final String? error;

  CollectionState({
    this.collections = const [],
    this.isLoading = false,
    this.error,
  });

  CollectionState copyWith({
    List<MangaCollection>? collections,
    bool? isLoading,
    String? error,
  }) {
    return CollectionState(
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Collection notifier
class CollectionNotifier extends StateNotifier<CollectionState> {
  CollectionNotifier() : super(CollectionState()) {
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: Load from local storage
      // For now, use default collections
      await Future.delayed(const Duration(milliseconds: 300));
      state = CollectionState(
        collections: MangaCollection.createDefaultCollections(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createCollection({
    required String name,
    String description = '',
    Color color = const Color(0xFF6C5CE7),
    IconData icon = Icons.folder,
  }) async {
    final newCollection = MangaCollection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      color: color,
      icon: icon,
      order: state.collections.length,
    );

    state = state.copyWith(
      collections: [...state.collections, newCollection],
    );

    // TODO: Save to local storage
  }

  Future<void> updateCollection(MangaCollection collection) async {
    final updatedCollections = state.collections.map((c) {
      return c.id == collection.id ? collection : c;
    }).toList();

    state = state.copyWith(collections: updatedCollections);

    // TODO: Save to local storage
  }

  Future<void> deleteCollection(String collectionId) async {
    state = state.copyWith(
      collections: state.collections.where((c) => c.id != collectionId).toList(),
    );

    // TODO: Save to local storage
  }

  Future<void> addMangaToCollection({
    required String collectionId,
    required String mangaId,
  }) async {
    final updatedCollections = state.collections.map((c) {
      if (c.id == collectionId) {
        return c.addManga(mangaId);
      }
      return c;
    }).toList();

    state = state.copyWith(collections: updatedCollections);

    // TODO: Save to local storage
  }

  Future<void> removeMangaFromCollection({
    required String collectionId,
    required String mangaId,
  }) async {
    final updatedCollections = state.collections.map((c) {
      if (c.id == collectionId) {
        return c.removeManga(mangaId);
      }
      return c;
    }).toList();

    state = state.copyWith(collections: updatedCollections);

    // TODO: Save to local storage
  }

  Future<void> reorderCollections(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final collections = List<MangaCollection>.from(state.collections);
    final item = collections.removeAt(oldIndex);
    collections.insert(newIndex, item);

    // Update order
    for (int i = 0; i < collections.length; i++) {
      collections[i] = collections[i].copyWith(order: i);
    }

    state = state.copyWith(collections: collections);

    // TODO: Save to local storage
  }

  /// Get manga IDs for a collection
  List<String> getMangaIds(String collectionId) {
    final collection = state.collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => throw Exception('Collection not found'),
    );
    return collection.mangaIds;
  }

  /// Get collections containing a manga
  List<MangaCollection> getCollectionsForManga(String mangaId) {
    return state.collections.where((c) => c.containsManga(mangaId)).toList();
  }
}

/// Collection provider
final collectionProvider =
    StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
  return CollectionNotifier();
});

/// Provider for collections containing a specific manga
final mangaCollectionsProvider = Provider.family<List<MangaCollection>, String>(
  (ref, mangaId) {
    final collectionState = ref.watch(collectionProvider);
    return collectionState.collections.where((c) => c.containsManga(mangaId)).toList();
  },
);
