import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import '../../core/utils/logger.dart';
import '../services/web_file_storage.dart';

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
    try {
      AppLogger.info('Burning translation onto image: $imagePath', tag: 'ImageEditor');

      // Load the original image bytes
      Uint8List bytes;

      if (kIsWeb) {
        // On web, load from WebFileStorage
        final webBytes = WebFileStorage.getFile(imagePath);
        if (webBytes == null) {
          throw Exception('Image not found in web storage: $imagePath');
        }
        bytes = webBytes;
      } else {
        // On native platforms, load from file
        final file = File(imagePath);
        bytes = await file.readAsBytes();
      }

      // Decode image using the image package (cross-platform)
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final width = image.width;
      final height = image.height;

      AppLogger.info('Original image size: ${width}x$height', tag: 'ImageEditor');
      AppLogger.info('Text region: ${region.width.toStringAsFixed(0)}x${region.height.toStringAsFixed(0)} at (${region.left.toStringAsFixed(0)}, ${region.top.toStringAsFixed(0)})', tag: 'ImageEditor');

      // Convert region coordinates to integers
      final x1 = region.left.round();
      final y1 = region.top.round();
      final x2 = (region.left + region.width).round();
      final y2 = (region.top + region.height).round();

      // Create white background rectangle over the text region
      final bgColor = img.ColorRgb8(
        (backgroundColor.r * 255.0).round() & 0xff,
        (backgroundColor.g * 255.0).round() & 0xff,
        (backgroundColor.b * 255.0).round() & 0xff,
      );

      // Fill the region with white background (with opacity simulation)
      // Note: The image package doesn't support alpha blending directly on the main image
      // So we'll use a solid fill for now
      img.fillRect(
        image,
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        color: bgColor,
      );

      // Draw the translated text
      // Note: The image package has limited font support
      // We'll use a basic font for now
      final textColorRgb = img.ColorRgb8(
        (textColor.r * 255.0).round() & 0xff,
        (textColor.g * 255.0).round() & 0xff,
        (textColor.b * 255.0).round() & 0xff,
      );

      // Calculate font size (scaled for the image package)
      final scaledFontSize = fontSize.round();

      // Draw text centered in the region
      // Note: The image package doesn't support complex text layout
      // We'll draw a simple text for now
      try {
        // Try to use a built-in font
        img.drawString(
          image,
          translatedText,
          font: img.arial24,
          x: x1 + (x2 - x1) ~/ 2,
          y: y1 + (y2 - y1) ~/ 2,
          color: textColorRgb,
        );
      } catch (e) {
        // If font drawing fails, fall back to a simple rectangle with text indication
        AppLogger.warning('Font drawing failed, using fallback: $e', tag: 'ImageEditor');

        // Draw a colored border around the region to indicate translation
        img.drawRect(
          image,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: textColorRgb,
          thickness: 2,
        );
      }

      // Encode the edited image to PNG
      final editedBytes = img.encodePng(image);

      // Save the edited image
      if (kIsWeb) {
        // On web, save to WebFileStorage
        final outputPath = '${imagePath}_edited_${DateTime.now().millisecondsSinceEpoch}.png';
        WebFileStorage.storeFile(outputPath, editedBytes);

        AppLogger.info('Edited image saved to web storage: $outputPath', tag: 'ImageEditor');

        return ImageEditResult(
          editedImagePath: outputPath,
          originalWidth: width,
          originalHeight: height,
          textRegionsCount: 1,
        );
      } else {
        // On native platforms, save to file system
        final tempDir = await getTemporaryDirectory();
        final editDir = Directory(path.join(tempDir.path, 'edited_images'));
        if (!await editDir.exists()) {
          await editDir.create(recursive: true);
        }

        final fileName = '${path.basenameWithoutExtension(imagePath)}_edited_${DateTime.now().millisecondsSinceEpoch}.png';
        final editedFile = File(path.join(editDir.path, fileName));
        await editedFile.writeAsBytes(editedBytes);

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
      }
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
      // Web implementation
      final bytes = WebFileStorage.getFile(imagePath);
      if (bytes == null) {
        throw Exception('Image not found in web storage: $imagePath');
      }

      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final x1 = region.left.round();
      final y1 = region.top.round();
      final x2 = (region.left + region.width).round();
      final y2 = (region.top + region.height).round();

      final color = img.ColorRgb8(
        (fillColor.r * 255.0).round() & 0xff,
        (fillColor.g * 255.0).round() & 0xff,
        (fillColor.b * 255.0).round() & 0xff,
      );
      img.fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: color);

      final editedBytes = img.encodePng(image);
      final outputPath = '${imagePath}_cleaned_${DateTime.now().millisecondsSinceEpoch}.png';
      WebFileStorage.storeFile(outputPath, editedBytes);

      return ImageEditResult(
        editedImagePath: outputPath,
        originalWidth: image.width,
        originalHeight: image.height,
        textRegionsCount: 1,
      );
    }

    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final x1 = region.left.round();
      final y1 = region.top.round();
      final x2 = (region.left + region.width).round();
      final y2 = (region.top + region.height).round();

      final color = img.ColorRgb8(
        (fillColor.r * 255.0).round() & 0xff,
        (fillColor.g * 255.0).round() & 0xff,
        (fillColor.b * 255.0).round() & 0xff,
      );
      img.fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: color);

      final editedBytes = img.encodePng(image);

      final tempDir = await getTemporaryDirectory();
      final editDir = Directory(path.join(tempDir.path, 'edited_images'));
      if (!await editDir.exists()) {
        await editDir.create(recursive: true);
      }

      final fileName = '${path.basenameWithoutExtension(imagePath)}_cleaned_${DateTime.now().millisecondsSinceEpoch}.png';
      final editedFile = File(path.join(editDir.path, fileName));
      await editedFile.writeAsBytes(editedBytes);

      AppLogger.info('Cleaned text region saved to: ${editedFile.path}', tag: 'ImageEditor');

      return ImageEditResult(
        editedImagePath: editedFile.path,
        originalWidth: image.width,
        originalHeight: image.height,
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
    if (stamps.isEmpty) {
      throw ArgumentError('At least one translation stamp is required');
    }

    try {
      AppLogger.info('Burning ${stamps.length} translations onto image: $imagePath', tag: 'ImageEditor');

      // Load the original image
      Uint8List bytes;

      if (kIsWeb) {
        final webBytes = WebFileStorage.getFile(imagePath);
        if (webBytes == null) {
          throw Exception('Image not found in web storage: $imagePath');
        }
        bytes = webBytes;
      } else {
        final file = File(imagePath);
        bytes = await file.readAsBytes();
      }

      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Apply each translation stamp
      for (final stamp in stamps) {
        final x1 = stamp.region.left.round();
        final y1 = stamp.region.top.round();
        final x2 = (stamp.region.left + stamp.region.width).round();
        final y2 = (stamp.region.top + stamp.region.height).round();

        // Draw white background
        final bgColor = img.ColorRgb8(
          (stamp.backgroundColor.r * 255.0).round() & 0xff,
          (stamp.backgroundColor.g * 255.0).round() & 0xff,
          (stamp.backgroundColor.b * 255.0).round() & 0xff,
        );
        img.fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: bgColor);

        // Draw text
        final textColor = img.ColorRgb8(
          (stamp.textColor.r * 255.0).round() & 0xff,
          (stamp.textColor.g * 255.0).round() & 0xff,
          (stamp.textColor.b * 255.0).round() & 0xff,
        );

        try {
          img.drawString(
            image,
            stamp.text,
            font: img.arial24,
            x: x1 + (x2 - x1) ~/ 2,
            y: y1 + (y2 - y1) ~/ 2,
            color: textColor,
          );
        } catch (e) {
          // Fallback to border
          img.drawRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: textColor, thickness: 2);
        }
      }

      final editedBytes = img.encodePng(image);

      if (kIsWeb) {
        final outputPath = '${imagePath}_edited_${DateTime.now().millisecondsSinceEpoch}.png';
        WebFileStorage.storeFile(outputPath, editedBytes);

        return ImageEditResult(
          editedImagePath: outputPath,
          originalWidth: image.width,
          originalHeight: image.height,
          textRegionsCount: stamps.length,
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final editDir = Directory(path.join(tempDir.path, 'edited_images'));
        if (!await editDir.exists()) {
          await editDir.create(recursive: true);
        }

        final fileName = '${path.basenameWithoutExtension(imagePath)}_edited_${DateTime.now().millisecondsSinceEpoch}.png';
        final editedFile = File(path.join(editDir.path, fileName));
        await editedFile.writeAsBytes(editedBytes);

        AppLogger.info('Edited image with ${stamps.length} translations saved to: ${editedFile.path}', tag: 'ImageEditor');

        return ImageEditResult(
          editedImagePath: editedFile.path,
          originalWidth: image.width,
          originalHeight: image.height,
          textRegionsCount: stamps.length,
        );
      }
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
