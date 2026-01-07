import 'dart:async';
import '../repositories/manga_repository.dart';
import '../services/file_scanner.dart';
import '../../core/utils/logger.dart';

enum ImportStatus {
  idle,
  scanning,
  importing,
  completed,
  error,
}

class ImportTask {
  final String id;
  final String filePath;
  final String title;
  ImportStatus status;
  final String? error;
  final int? progress;
  final int? total;

  ImportTask({
    required this.id,
    required this.filePath,
    required this.title,
    this.status = ImportStatus.idle,
    this.error,
    this.progress,
    this.total,
  });

  ImportTask copyWith({
    String? id,
    String? filePath,
    String? title,
    ImportStatus? status,
    String? error,
    int? progress,
    int? total,
  }) {
    return ImportTask(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      status: status ?? this.status,
      error: error ?? this.error,
      progress: progress ?? this.progress,
      total: total ?? this.total,
    );
  }

  double get progressPercent {
    if (total == null || total == 0) return 0.0;
    return (progress ?? 0) / total!;
  }
}

class ImportQueueState {
  final ImportStatus status;
  final List<ImportTask> tasks;
  final int totalFiles;
  final int completedFiles;
  final int failedFiles;
  final String? currentOperation;
  final bool isProcessing;

  ImportQueueState({
    this.status = ImportStatus.idle,
    this.tasks = const [],
    this.totalFiles = 0,
    this.completedFiles = 0,
    this.failedFiles = 0,
    this.currentOperation,
    this.isProcessing = false,
  });

  ImportQueueState copyWith({
    ImportStatus? status,
    List<ImportTask>? tasks,
    int? totalFiles,
    int? completedFiles,
    int? failedFiles,
    String? currentOperation,
    bool? isProcessing,
  }) {
    return ImportQueueState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      totalFiles: totalFiles ?? this.totalFiles,
      completedFiles: completedFiles ?? this.completedFiles,
      failedFiles: failedFiles ?? this.failedFiles,
      currentOperation: currentOperation ?? this.currentOperation,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  double get overallProgress {
    if (totalFiles == 0) return 0.0;
    return completedFiles / totalFiles;
  }
}

class ImportQueueService {
  final MangaRepository _mangaRepository;
  final FileScanner _fileScanner;

  final _stateController = StreamController<ImportQueueState>.broadcast();
  ImportQueueState _state = ImportQueueState();

  ImportQueueState get state => _state;
  Stream<ImportQueueState> get stateStream => _stateController.stream;

  ImportQueueService({
    required MangaRepository mangaRepository,
    required FileScanner fileScanner,
  })  : _mangaRepository = mangaRepository,
        _fileScanner = fileScanner {
    _emitState();
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void _updateState(ImportQueueState Function(ImportQueueState) updater) {
    _state = updater(_state);
    _emitState();
  }

  Future<void> importFiles(List<String> filePaths) async {
    if (_state.isProcessing) {
      AppLogger.warning('Import already in progress', tag: 'ImportQueue');
      return;
    }

    try {
      _updateState((state) => state.copyWith(
        status: ImportStatus.scanning,
        isProcessing: true,
        totalFiles: filePaths.length,
        currentOperation: 'Scanning files...',
      ));

      final tasks = <ImportTask>[];
      for (int i = 0; i < filePaths.length; i++) {
        tasks.add(ImportTask(
          id: 'task_$i',
          filePath: filePaths[i],
          title: FileScanner.generateTitleFromPath(filePaths[i]),
          status: ImportStatus.idle,
        ));
      }

      _updateState((state) => state.copyWith(
        tasks: tasks,
        status: ImportStatus.importing,
        currentOperation: 'Importing files...',
      ));

      int completed = 0;
      int failed = 0;

      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];

        _updateTaskStatus(task.id, ImportStatus.importing, progress: 0);

        try {
          await _importSingleFile(task);
          completed++;
          _updateTaskStatus(task.id, ImportStatus.completed, progress: 1, total: 1);
        } catch (e) {
          failed++;
          _updateTaskStatus(task.id, ImportStatus.error, error: e.toString());
        }

        _updateState((state) => state.copyWith(
          completedFiles: completed,
          failedFiles: failed,
        ));
      }

      _updateState((state) => state.copyWith(
        status: ImportStatus.completed,
        isProcessing: false,
        currentOperation: 'Import completed',
      ));

      AppLogger.info('Import completed: $completed succeeded, $failed failed', tag: 'ImportQueue');
    } catch (e) {
      AppLogger.error('Import failed', error: e, tag: 'ImportQueue');
      _updateState((state) => state.copyWith(
        status: ImportStatus.error,
        isProcessing: false,
        currentOperation: 'Import failed: $e',
      ));
    }
  }

  Future<void> _importSingleFile(ImportTask task) async {
    try {
      final isValid = await _fileScanner.validateFile(task.filePath);
      if (!isValid) {
        throw Exception('Invalid or corrupted file');
      }

      final manga = await _fileScanner.createMangaFromFile(task.filePath);

      await _mangaRepository.addManga(manga);

      AppLogger.info('Imported: ${manga.title}', tag: 'ImportQueue');
    } catch (e) {
      AppLogger.error('Failed to import ${task.filePath}', error: e, tag: 'ImportQueue');
      rethrow;
    }
  }

  void _updateTaskStatus(
    String taskId,
    ImportStatus status, {
    String? error,
    int? progress,
    int? total,
  }) {
    final updatedTasks = _state.tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          status: status,
          error: error,
          progress: progress,
          total: total,
        );
      }
      return task;
    }).toList();

    _updateState((state) => state.copyWith(tasks: updatedTasks));
  }

  Future<void> cancelImport() async {
    if (!_state.isProcessing) return;

    _updateState((state) => state.copyWith(
      status: ImportStatus.idle,
      isProcessing: false,
      currentOperation: 'Import cancelled',
    ));

    AppLogger.info('Import cancelled', tag: 'ImportQueue');
  }

  Future<void> clearQueue() async {
    _updateState((state) => ImportQueueState());
    AppLogger.info('Queue cleared', tag: 'ImportQueue');
  }

  void dispose() {
    _stateController.close();
  }
}
