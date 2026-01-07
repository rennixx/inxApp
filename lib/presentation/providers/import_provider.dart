import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/manga_repository.dart';
import '../../data/services/file_scanner.dart';
import '../../data/services/import_queue_service.dart';
import '../../data/services/web_file_storage.dart';
import '../../core/utils/logger.dart';
import 'manga_library_provider.dart';

final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  return MangaRepository();
});

final fileScannerProvider = Provider<FileScanner>((ref) {
  return FileScanner();
});

final importQueueServiceProvider = Provider<ImportQueueService>((ref) {
  final mangaRepository = ref.watch(mangaRepositoryProvider);
  final fileScanner = ref.watch(fileScannerProvider);

  final service = ImportQueueService(
    mangaRepository: mangaRepository,
    fileScanner: fileScanner,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

final importQueueStateProvider = StreamProvider<ImportQueueState>((ref) {
  final service = ref.watch(importQueueServiceProvider);
  return service.stateStream;
});

final importQueueNotifierProvider = StateNotifierProvider<ImportQueueNotifier, ImportQueueState>((ref) {
  final service = ref.watch(importQueueServiceProvider);

  return ImportQueueNotifier(service, ref);
});

class ImportQueueNotifier extends StateNotifier<ImportQueueState> {
  final ImportQueueService _service;
  final Ref _ref;

  ImportQueueNotifier(this._service, this._ref) : super(_service.state) {
    _service.stateStream.listen((newState) {
      if (mounted) {
        state = newState;
      }
    });
  }

  Future<void> importFiles(List<String> filePaths) async {
    await _service.importFiles(filePaths);
  }

  Future<void> importFromPicker() async {
    final scanner = FileScanner();
    final result = await scanner.pickFiles();

    if (result.imported.isEmpty && result.errors.isEmpty) {
      return;
    }

    // On web, manga are already stored in WebFileStorage by _createMangaFromBytes
    // On native, we need to import them via the service
    if (kIsWeb) {
      // For web, the manga are already indexed in WebFileStorage
      AppLogger.info('Imported ${result.imported.length} files on web', tag: 'ImportQueueNotifier');

      // Show any errors that occurred
      if (result.errors.isNotEmpty) {
        for (final error in result.errors) {
          AppLogger.error('Import error: $error', tag: 'ImportQueueNotifier');
        }
      }

      // Invalidate the library provider to trigger a refresh
      _ref.invalidate(mangaLibraryProvider);
    } else {
      // For native platforms, use the import queue service
      await _service.importFiles(result.imported.map((m) => m.filePath).toList());
    }
  }

  Future<void> importFromDirectory() async {
    final scanner = FileScanner();
    final result = await scanner.pickDirectory();
    if (result.imported.isNotEmpty || result.errors.isNotEmpty) {
      await _service.importFiles(result.imported.map((m) => m.filePath).toList());
    }
  }

  Future<void> cancelImport() async {
    await _service.cancelImport();
  }

  Future<void> clearQueue() async {
    await _service.clearQueue();
  }
}
