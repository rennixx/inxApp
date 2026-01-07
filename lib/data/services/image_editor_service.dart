import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/utils/logger.dart';

/// Result of image editing operation
class ImageEditResult {
  final String editedImagePath;
  final int originalWidth;
  final int originalHeight;
  final int textRegionsCount;

  ImageEditResult({
    required this.editedImagePath,
    required this.originalWidth,
    required this.originalHeight,
    required this.textRegionsCount,
  });
}

/// Service for editing manga images (burning translations, cleaning text, etc.)
class ImageEditorService {
  ImageEditorService._();

  static final Map<String, ImageEditResult> _editedCache = {};

  /// Burn translated text directly onto an image at specified regions
  static Future<ImageEditResult> burnTranslation({
    required String imagePath,
    required String translatedText,
    required Rect region,
    String? outputPath,
    double fontSize = 16.0,
    String fontFamily = 'Roboto',
    Color textColor = const Color(0xFF000000),
    Color backgroundColor = const Color(0xFFFFFFFF),
    double opacity = 0.95,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Image editing not supported on web');
    }

    try {
      AppLogger.info('Burning translation onto image: $imagePath', tag: 'ImageEditor');

      // Load the original image
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      // Decode the image
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final width = image.width;
      final height = image.height;

      AppLogger.info('Original image size: ${width}x$height', tag: 'ImageEditor');
      AppLogger.info('Text region: ${region.width.toStringAsFixed(0)}x${region.height.toStringAsFixed(0)} at (${region.left.toStringAsFixed(0)}, ${region.top.toStringAsFixed(0)})', tag: 'ImageEditor');

      // Create a recorder for the new image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the original image
      final srcRect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
      final dstRect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
      canvas.drawImage(image, Offset.zero, Paint());

      // Draw white background over the text region (erases original text)
      final bgPaint = Paint()
        ..color = backgroundColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill
        ..blendMode = ui.BlendMode.srcOver;

      canvas.drawRect(region, bgPaint);

      // Draw the translated text
      final textPainter = TextPainter(
        text: TextSpan(
          text: translatedText,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3,
        ellipsis: '...',
      );

      // Layout and draw the text centered in the region
      textPainter.layout(maxWidth: region.width);
      final textOffset = Offset(
        region.left + (region.width - textPainter.width) / 2,
        region.top + (region.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);

      // Convert to image
      final picture = recorder.endRecording();
      final imageInfo = await picture.toImage(width, height);
      final byteData = await imageInfo.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode edited image');
      }

      // Save the edited image
      final tempDir = await getTemporaryDirectory();
      final editDir = Directory(path.join(tempDir.path, 'edited_images'));
      if (!await editDir.exists()) {
        await editDir.create(recursive: true);
      }

      final fileName = '${path.basenameWithoutExtension(imagePath)}_edited_${DateTime.now().millisecondsSinceEpoch}.png';
      final editedFile = File(path.join(editDir.path, fileName));
      await editedFile.writeAsBytes(byteData.buffer.asUint8List());

      AppLogger.info('Edited image saved to: ${editedFile.path}', tag: 'ImageEditor');

      final result = ImageEditResult(
        editedImagePath: editedFile.path,
        originalWidth: width,
        originalHeight: height,
        textRegionsCount: 1,
      );

      // Cache the result
      _editedCache[imagePath] = result;

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to burn translation onto image', error: e, stackTrace: stackTrace, tag: 'ImageEditor');
      rethrow;
    }
  }

  /// Get edited image from cache if available
  static ImageEditResult? getCachedEdit(String imagePath) {
    return _editedCache[imagePath];
  }

  /// Clear edit cache
  static void clearCache() {
    _editedCache.clear();
  }

  /// Clean a text region by filling it with white/background color
  static Future<ImageEditResult> cleanTextRegion({
    required String imagePath,
    required Rect region,
    Color fillColor = const Color(0xFFFFFFFF),
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Image editing not supported on web');
    }

    try {
      // Load the original image
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      // Decode the image
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final width = image.width;
      final height = image.height;

      // Create a recorder for the new image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the original image
      canvas.drawImage(image, Offset.zero, Paint());

      // Fill the region with the specified color
      final paint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill
        ..blendMode = ui.BlendMode.srcOver;

      canvas.drawRect(region, paint);

      // Convert to image
      final picture = recorder.endRecording();
      final imageInfo = await picture.toImage(width, height);
      final byteData = await imageInfo.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode edited image');
      }

      // Save the edited image
      final tempDir = await getTemporaryDirectory();
      final editDir = Directory(path.join(tempDir.path, 'edited_images'));
      if (!await editDir.exists()) {
        await editDir.create(recursive: true);
      }

      final fileName = '${path.basenameWithoutExtension(imagePath)}_cleaned_${DateTime.now().millisecondsSinceEpoch}.png';
      final editedFile = File(path.join(editDir.path, fileName));
      await editedFile.writeAsBytes(byteData.buffer.asUint8List());

      AppLogger.info('Cleaned text region saved to: ${editedFile.path}', tag: 'ImageEditor');

      return ImageEditResult(
        editedImagePath: editedFile.path,
        originalWidth: width,
        originalHeight: height,
        textRegionsCount: 1,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clean text region', error: e, stackTrace: stackTrace, tag: 'ImageEditor');
      rethrow;
    }
  }

  /// Apply multiple translations to an image at once
  static Future<ImageEditResult> burnMultipleTranslations({
    required String imagePath,
    required List<TranslationStamp> stamps,
    String? outputPath,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Image editing not supported on web');
    }

    if (stamps.isEmpty) {
      throw ArgumentError('At least one translation stamp is required');
    }

    try {
      AppLogger.info('Burning ${stamps.length} translations onto image: $imagePath', tag: 'ImageEditor');

      // Load the original image
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      // Decode the image
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final width = image.width;
      final height = image.height;

      // Create a recorder for the new image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the original image
      canvas.drawImage(image, Offset.zero, Paint());

      // Apply each translation stamp
      for (final stamp in stamps) {
        // Draw white background over the text region
        final bgPaint = Paint()
          ..color = stamp.backgroundColor.withValues(alpha: stamp.opacity)
          ..style = PaintingStyle.fill
          ..blendMode = ui.BlendMode.srcOver;

        canvas.drawRect(stamp.region, bgPaint);

        // Draw the translated text
        final textPainter = TextPainter(
          text: TextSpan(
            text: stamp.text,
            style: TextStyle(
              color: stamp.textColor,
              fontSize: stamp.fontSize,
              fontFamily: stamp.fontFamily,
              fontWeight: FontWeight.w600,
              height: 1.1,
              letterSpacing: -0.3,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: stamp.maxLines ?? 3,
          ellipsis: '...',
        );

        // Layout and draw the text centered in the region
        textPainter.layout(maxWidth: stamp.region.width);
        final textOffset = Offset(
          stamp.region.left + (stamp.region.width - textPainter.width) / 2,
          stamp.region.top + (stamp.region.height - textPainter.height) / 2,
        );
        textPainter.paint(canvas, textOffset);
      }

      // Convert to image
      final picture = recorder.endRecording();
      final imageInfo = await picture.toImage(width, height);
      final byteData = await imageInfo.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode edited image');
      }

      // Save the edited image
      final tempDir = await getTemporaryDirectory();
      final editDir = Directory(path.join(tempDir.path, 'edited_images'));
      if (!await editDir.exists()) {
        await editDir.create(recursive: true);
      }

      final fileName = '${path.basenameWithoutExtension(imagePath)}_edited_${DateTime.now().millisecondsSinceEpoch}.png';
      final editedFile = File(path.join(editDir.path, fileName));
      await editedFile.writeAsBytes(byteData.buffer.asUint8List());

      AppLogger.info('Edited image with ${stamps.length} translations saved to: ${editedFile.path}', tag: 'ImageEditor');

      return ImageEditResult(
        editedImagePath: editedFile.path,
        originalWidth: width,
        originalHeight: height,
        textRegionsCount: stamps.length,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to burn multiple translations', error: e, stackTrace: stackTrace, tag: 'ImageEditor');
      rethrow;
    }
  }
}

/// Represents a translation stamp to be burned onto an image
class TranslationStamp {
  final String text;
  final Rect region;
  final double fontSize;
  final String fontFamily;
  final Color textColor;
  final Color backgroundColor;
  final double opacity;
  final int? maxLines;

  TranslationStamp({
    required this.text,
    required this.region,
    this.fontSize = 16.0,
    this.fontFamily = 'Roboto',
    this.textColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.opacity = 0.95,
    this.maxLines = 3,
  });
}
