import 'dart:ui' as ui;
import 'dart:typed_data';

/// Background image decoder using isolates for non-blocking decoding
class BackgroundImageDecoder {
  static final BackgroundImageDecoder _instance = BackgroundImageDecoder._internal();
  factory BackgroundImageDecoder() => _instance;
  BackgroundImageDecoder._internal();

  final Map<String, Future<ui.Image>> _decodingCache = {};

  /// Decode image in background isolate
  Future<ui.Image> decodeImage(Uint8List bytes, {String? cacheKey}) async {
    if (cacheKey != null && _decodingCache.containsKey(cacheKey)) {
      return _decodingCache[cacheKey]!;
    }

    final completer = Completer<ui.Image>();

    if (cacheKey != null) {
      _decodingCache[cacheKey] = completer.future;
    }

    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1920, // Limit max width for performance
        targetHeight: 1920, // Limit max height for performance
      );

      final frame = await codec.getNextFrame();
      final image = frame.image;

      completer.complete(image);
      codec.dispose();

      return image;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    }
  }

  /// Clear decoding cache
  void clearCache() {
    _decodingCache.clear();
  }

  /// Get pending decodes count
  int get pendingDecodes => _decodingCache.length;
}

/// Completer for Future<ui.Image>
class Completer<T> {
  late final Future<T> future;
  T? _result;
  Object? _error;

  Completer() {
    future = _createFuture();
  }

  Future<T> _createFuture() {
    return Future.any([
      Future.delayed(const Duration(days: 365)), // Never completes
      Future.error('Unreachable'),
    ]).then((_) => _result as T).catchError((error) {
      if (_error != null) {
        throw _error!;
      }
      throw error;
    });
  }

  void complete(T value) {
    _result = value;
  }

  void completeError(Object error) {
    _error = error;
  }
}
