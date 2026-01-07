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

class _ZoomableImagePageState extends State<ZoomableImagePage>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  double _previousScale = 1.0;
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

  void _onScaleStart(ScaleStartDetails details) {
    setState(() {
      _previousScale = _scale;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = _previousScale * details.scale;
      // Clamp scale between 1.0 and 5.0
      _scale = _scale.clamp(1.0, 5.0);
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // Reset scale if it's close to 1.0
    if (_scale < 1.1) {
      setState(() {
        _scale = 1.0;
        _transformationController.value = Matrix4.identity();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        // On web, InteractiveViewer has mouse tracker issues, so we just show the image
        child: kIsWeb ? _buildImage() : InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 5.0,
          constrained: false,
          child: _buildImage(),
        ),
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
            return Container(
              height: 800,
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.error, color: Colors.white),
              ),
            );
          },
        );
      }

      // Placeholder for loading
      return Container(
        height: 800,
        color: Colors.grey.withValues(alpha: widget.brightness * 0.3),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Check if it's a local file or network URL
    if (widget.imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: widget.imagePath,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          height: 800,
          color: Colors.grey.withValues(alpha: widget.brightness * 0.3),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 800,
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.error, color: Colors.white),
          ),
        ),
      );
    }

    // Local file (native platforms)
    final file = File(widget.imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 800,
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.error, color: Colors.white),
            ),
          );
        },
      );
    }

    // Placeholder for loading
    return Container(
      height: 800,
      color: Colors.grey.withValues(alpha: widget.brightness * 0.3),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
