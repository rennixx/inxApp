import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/media_item.dart';

class LibraryState {
  final List<MediaItem> items;
  final bool isLoading;
  final String? error;

  LibraryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  LibraryState copyWith({
    List<MediaItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return LibraryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier() : super(LibraryState());

  Future<void> loadLibrary() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Implement actual loading logic
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void addItem(MediaItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }
}

final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>(
  (ref) => LibraryNotifier(),
);
