import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/entities/manga.dart';

class ReaderControlsOverlay extends StatelessWidget {
  final Manga manga;
  final int currentPage;
  final int totalPages;
  final double brightness;
  final bool autoScrollEnabled;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<double> onBrightnessChanged;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onToggleTranslation;
  final VoidCallback onClose;

  const ReaderControlsOverlay({
    super.key,
    required this.manga,
    required this.currentPage,
    required this.totalPages,
    required this.brightness,
    required this.autoScrollEnabled,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onBrightnessChanged,
    required this.onToggleAutoScroll,
    required this.onToggleTranslation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top bar
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _buildTopBar(context),
        ),

        // Side navigation buttons
        Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          child: Center(child: _buildPreviousButton()),
        ),

        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(child: _buildNextButton()),
        ),

        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomControls(context),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onClose,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    manga.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (manga.author != null)
                    Text(
                      manga.author!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                autoScrollEnabled
                    ? PhosphorIcons.arrowFatLinesDown(PhosphorIconsStyle.fill)
                    : PhosphorIcons.arrowFatLinesDown(PhosphorIconsStyle.regular),
                color: autoScrollEnabled ? const Color(0xFF2196F3) : Colors.white,
              ),
              onPressed: onToggleAutoScroll,
              tooltip: 'Auto-scroll',
            ),
            IconButton(
              icon: Icon(
                PhosphorIcons.translate(PhosphorIconsStyle.regular),
                color: const Color(0xFF6C5CE7),
              ),
              onPressed: onToggleTranslation,
              tooltip: 'Translation',
            ),
            IconButton(
              icon: Icon(
                PhosphorIcons.gear(PhosphorIconsStyle.regular),
                color: Colors.white,
              ),
              onPressed: () => _showSettingsSheet(context),
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousButton() {
    return AnimatedOpacity(
      opacity: currentPage > 0 ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
            color: Colors.white,
          ),
          onPressed: currentPage > 0 ? onPreviousPage : null,
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return AnimatedOpacity(
      opacity: currentPage < totalPages - 1 ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
            color: Colors.white,
          ),
          onPressed: currentPage < totalPages - 1 ? onNextPage : null,
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              PhosphorIcons.sun(PhosphorIconsStyle.regular),
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF2196F3),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF2196F3).withValues(alpha: 0.3),
                ),
                child: Slider(
                  value: brightness,
                  min: 0.2,
                  max: 1.0,
                  onChanged: onBrightnessChanged,
                ),
              ),
            ),
            Icon(
              PhosphorIcons.sunDim(PhosphorIconsStyle.fill),
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Reader Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildSettingTile(
                context,
                icon: PhosphorIcons.arrowsOutSimple(PhosphorIconsStyle.regular),
                title: 'Zoom Mode',
                subtitle: 'Pinch to zoom images',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: PhosphorIcons.eye(PhosphorIconsStyle.regular),
                title: 'Reading Mode',
                subtitle: 'Vertical scroll',
                onTap: () {},
              ),
              _buildSettingTile(
                context,
                icon: PhosphorIcons.clock(PhosphorIconsStyle.regular),
                title: 'Keep Screen On',
                subtitle: 'Prevent screen from sleeping',
                onTap: () {},
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeTrackColor: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
