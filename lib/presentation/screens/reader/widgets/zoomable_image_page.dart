import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/services/web_file_storage.dart';
import '../../../../core/utils/logger.dart';

class ZoomableImagePage extends StatefulWidget {
  final String imagePath;
  final int page;
  final double brightness;

  const ZoomableImagePage({
    super.key,
    required this.imagePath,
    required this.page,
    this.brightness = 1.0,
  });

  @override
  State<ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<ZoomableImagePage> {
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: kIsWeb
          ? _buildImage()
          : InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 5.0,
              constrained: true,
              child: _buildImage(),
            ),
    );
  }

  Widget _buildImage() {
    // On web, load from WebFileStorage
    if (kIsWeb) {
      final bytes = WebFileStorage.getFile(widget.imagePath);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            AppLogger.error('Failed to load image: $error', tag: 'ZoomableImagePage');
            return _buildErrorWidget();
          },
        );
      }

      // Placeholder for loading
      return _buildLoadingWidget();
    }

    // Check if it's a local file or network URL
    if (widget.imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: widget.imagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }

    // Local file (native platforms)
    try {
      final file = File(widget.imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            AppLogger.error('Failed to load image: $error', tag: 'ZoomableImagePage');
            return _buildErrorWidget();
          },
        );
      }
    } catch (e) {
      AppLogger.error('Error loading file: $e', tag: 'ZoomableImagePage');
    }

    // Placeholder for loading or error
    return _buildLoadingWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 800,
      color: Colors.grey.withValues(alpha: widget.brightness * 0.3),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 800,
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.error, color: Colors.white),
      ),
    );
  }
}
