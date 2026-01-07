import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/utils/logger.dart';

/// Supported OCR languages
enum OcrLanguage {
  japanese('ja'),
  korean('ko'),
  chinese('zh'),
  english('en'),
  latin('latin');

  final String languageCode;
  const OcrLanguage(this.languageCode);
}

/// Detected text region with metadata
class TextRegion {
  final String text;
  final Rect boundingBox;
  final List<Offset> cornerPoints;
  final double confidence;
  final OcrLanguage detectedLanguage;

  TextRegion({
    required this.text,
    required this.boundingBox,
    required this.cornerPoints,
    required this.confidence,
    required this.detectedLanguage,
  });

  factory TextRegion.fromTextBlock(TextBlock block, OcrLanguage language) {
    return TextRegion(
      text: block.text,
      boundingBox: block.boundingBox,
      cornerPoints: block.cornerPoints.map((p) => Offset(p.x.toDouble(), p.y.toDouble())).toList(),
      confidence: 0.8, // ML Kit doesn't provide confidence per block
      detectedLanguage: language,
    );
  }

  factory TextRegion.fromTextLine(TextLine line, OcrLanguage language) {
    return TextRegion(
      text: line.text,
      boundingBox: line.boundingBox,
      cornerPoints: line.cornerPoints.map((p) => Offset(p.x.toDouble(), p.y.toDouble())).toList(),
      confidence: 0.8, // ML Kit doesn't provide confidence per line
      detectedLanguage: language,
    );
  }
}

/// Image preprocessing options
class ImagePreprocessingOptions {
  final bool enhanceContrast;
  final bool sharpen;
  final bool binarize;
  final double contrastFactor;
  final double sharpenFactor;

  const ImagePreprocessingOptions({
    this.enhanceContrast = true,
    this.sharpen = true,
    this.binarize = false,
    this.contrastFactor = 1.2,
    this.sharpenFactor = 0.3,
  });

  static const none = ImagePreprocessingOptions(
    enhanceContrast: false,
    sharpen: false,
    binarize: false,
  );
}

/// OCR result with all detected text regions
class OcrResult {
  final List<TextRegion> textRegions;
  final String fullText;
  final OcrLanguage languageUsed;
  final int processingTimeMs;

  OcrResult({
    required this.textRegions,
    required this.fullText,
    required this.languageUsed,
    required this.processingTimeMs,
  });

  /// Get text regions filtered by minimum confidence
  List<TextRegion> getHighConfidenceRegions(double threshold) {
    return textRegions.where((region) => region.confidence >= threshold).toList();
  }

  /// Get text regions sorted by position (top to bottom, left to right)
  List<TextRegion> getSortedRegions() {
    final sorted = List<TextRegion>.from(textRegions);
    sorted.sort((a, b) {
      final yCompare = a.boundingBox.top.compareTo(b.boundingBox.top);
      if (yCompare != 0) return yCompare;
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });
    return sorted;
  }
}

/// ML Kit Text Recognition service
class OcrService {
  OcrService._();

  static final Map<OcrLanguage, TextRecognizer> _recognizers = {};

  /// Initialize OCR for a specific language
  static Future<void> initializeLanguage(OcrLanguage language) async {
    if (kIsWeb) {
      AppLogger.warning('OCR not supported on web', tag: 'OcrService');
      return;
    }

    if (_recognizers.containsKey(language)) {
      AppLogger.info('OCR already initialized for $language', tag: 'OcrService');
      return;
    }

    try {
      final recognizer = TextRecognizer();

      // Test the recognizer
      // Note: ML Kit doesn't have an explicit init, we create it and it's ready
      _recognizers[language] = recognizer;

      AppLogger.info('OCR initialized for $language', tag: 'OcrService');
    } catch (e) {
      AppLogger.error('Failed to initialize OCR for $language', error: e, tag: 'OcrService');
      rethrow;
    }
  }

  /// Initialize multiple languages
  static Future<void> initializeLanguages(List<OcrLanguage> languages) async {
    await Future.wait(
      languages.map((lang) => initializeLanguage(lang)),
    );
  }

  /// Check if language is initialized
  static bool isLanguageInitialized(OcrLanguage language) {
    return _recognizers.containsKey(language);
  }

  /// Perform OCR on an image file
  static Future<OcrResult> processImage(
    String imagePath, {
    OcrLanguage language = OcrLanguage.japanese,
    ImagePreprocessingOptions options = const ImagePreprocessingOptions(),
  }) async {
    if (kIsWeb) {
      // Mock OCR for web demonstration
      AppLogger.info('Using mock OCR for web demo', tag: 'OcrService');
      await Future.delayed(const Duration(milliseconds: 500));

      // Return mock data simulating detected Japanese text
      final mockRegion = TextRegion(
        text: 'こんにちは世界', // "Hello World" in Japanese
        boundingBox: const Rect.fromLTWH(100, 100, 300, 100),
        cornerPoints: [
          const Offset(100, 100),
          const Offset(400, 100),
          const Offset(400, 200),
          const Offset(100, 200),
        ],
        confidence: 0.95,
        detectedLanguage: language,
      );

      return OcrResult(
        textRegions: [mockRegion],
        fullText: 'こんにちは世界',
        languageUsed: language,
        processingTimeMs: 500,
      );
    }

    if (!_recognizers.containsKey(language)) {
      await initializeLanguage(language);
    }

    final recognizer = _recognizers[language]!;
    final stopwatch = Stopwatch()..start();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      AppLogger.info('Processing image with $language OCR', tag: 'OcrService');

      final RecognizedText recognizedText = await recognizer.processImage(inputImage);

      stopwatch.stop();

      // Extract LINES instead of BLOCKS for more granular text detection
      // This gives us individual text lines instead of grouped blocks
      final textRegions = <TextRegion>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          textRegions.add(TextRegion.fromTextLine(line, language));
        }
      }

      final result = OcrResult(
        textRegions: textRegions,
        fullText: recognizedText.text,
        languageUsed: language,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      AppLogger.info(
        'OCR complete: ${textRegions.length} regions (${recognizedText.blocks.length} blocks, ${textRegions.length} lines) in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'OcrService',
      );

      return result;
    } catch (e) {
      AppLogger.error('OCR processing failed', error: e, tag: 'OcrService');
      rethrow;
    }
  }

  /// Perform OCR on image bytes (for web/in-memory images)
  static Future<OcrResult> processImageBytes(
    Uint8List imageBytes, {
    OcrLanguage language = OcrLanguage.japanese,
    int imageWidth = 800,
    int imageHeight = 1200,
    ImagePreprocessingOptions options = const ImagePreprocessingOptions(),
  }) async {
    if (kIsWeb) {
      // Mock OCR for web demonstration
      AppLogger.info('Using mock OCR for web demo (from bytes)', tag: 'OcrService');
      await Future.delayed(const Duration(milliseconds: 500));

      // Return mock data simulating detected Japanese text
      final mockRegion = TextRegion(
        text: 'こんにちは世界', // "Hello World" in Japanese
        boundingBox: const Rect.fromLTWH(100, 100, 300, 100),
        cornerPoints: [
          const Offset(100, 100),
          const Offset(400, 100),
          const Offset(400, 200),
          const Offset(100, 200),
        ],
        confidence: 0.95,
        detectedLanguage: language,
      );

      return OcrResult(
        textRegions: [mockRegion],
        fullText: 'こんにちは世界',
        languageUsed: language,
        processingTimeMs: 500,
      );
    }

    if (!_recognizers.containsKey(language)) {
      await initializeLanguage(language);
    }

    final recognizer = _recognizers[language]!;
    final stopwatch = Stopwatch()..start();

    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(imageWidth.toDouble(), imageHeight.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: imageWidth,
        ),
      );

      AppLogger.info('Processing image bytes with $language OCR', tag: 'OcrService');

      final RecognizedText recognizedText = await recognizer.processImage(inputImage);

      stopwatch.stop();

      final textRegions = recognizedText.blocks.map((block) {
        return TextRegion.fromTextBlock(block, language);
      }).toList();

      final result = OcrResult(
        textRegions: textRegions,
        fullText: recognizedText.text,
        languageUsed: language,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      AppLogger.info(
        'OCR complete: ${textRegions.length} regions in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'OcrService',
      );

      return result;
    } catch (e) {
      AppLogger.error('OCR processing failed', error: e, tag: 'OcrService');
      rethrow;
    }
  }

  /// Auto-detect language and perform OCR
  static Future<OcrResult> processImageAutoDetect(
    String imagePath, {
    List<OcrLanguage> languagesToTry = const [
      OcrLanguage.japanese,
      OcrLanguage.korean,
      OcrLanguage.chinese,
      OcrLanguage.english,
    ],
    ImagePreprocessingOptions options = const ImagePreprocessingOptions(),
  }) async {
    AppLogger.info('Auto-detecting language for OCR', tag: 'OcrService');

    // Try each language, return the one with most text regions
    OcrResult? bestResult;

    for (final language in languagesToTry) {
      try {
        final result = await processImage(
          imagePath,
          language: language,
          options: options,
        );

        if (bestResult == null ||
            result.textRegions.length > bestResult.textRegions.length) {
          bestResult = result;

          // If we found significant text, use this language
          if (result.textRegions.length >= 3) {
            AppLogger.info('Auto-detected language: $language', tag: 'OcrService');
            return result;
          }
        }
      } catch (e) {
        AppLogger.warning('Failed to process with $language', tag: 'OcrService');
        continue;
      }
    }

    return bestResult ?? OcrResult(
      textRegions: [],
      fullText: '',
      languageUsed: OcrLanguage.english,
      processingTimeMs: 0,
    );
  }

  /// Extract text from specific region (speech bubble)
  static Future<String> extractTextFromRegion(
    String imagePath,
    Rect region, {
    OcrLanguage language = OcrLanguage.japanese,
  }) async {
    final result = await processImage(imagePath, language: language);

    // Find text regions that intersect with the specified region
    final matchingRegions = result.textRegions.where((textRegion) {
      return _rectsIntersect(textRegion.boundingBox, region);
    }).toList();

    // Sort by position and concatenate
    matchingRegions.sort((a, b) {
      final yCompare = a.boundingBox.top.compareTo(b.boundingBox.top);
      if (yCompare != 0) return yCompare;
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });

    return matchingRegions.map((r) => r.text).join('\n');
  }

  /// Check if two rectangles intersect
  static bool _rectsIntersect(Rect a, Rect b) {
    return !(
      a.right < b.left ||
      a.left > b.right ||
      a.bottom < b.top ||
      a.top > b.bottom
    );
  }

  /// Close and clean up recognizers
  static Future<void> close() async {
    for (final recognizer in _recognizers.values) {
      await recognizer.close();
    }
    _recognizers.clear();
    AppLogger.info('OCR service closed', tag: 'OcrService');
  }

  /// Close specific language recognizer
  static Future<void> closeLanguage(OcrLanguage language) async {
    final recognizer = _recognizers.remove(language);
    if (recognizer != null) {
      await recognizer.close();
      AppLogger.info('Closed OCR for $language', tag: 'OcrService');
    }
  }
}
