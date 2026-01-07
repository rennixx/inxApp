import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/entities/settings.dart';
import '../settings_screen.dart';

/// Reader preferences section
class ReaderPreferencesSection extends ConsumerWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const ReaderPreferencesSection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SettingsSectionHeader(
          title: 'Reader Preferences',
          subtitle: 'Customize your reading experience',
          icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.regular),
        ),

        // Brightness control
        SettingsSliderTile(
          title: 'Brightness',
          subtitle: 'Adjust screen brightness',
          value: settings.brightness,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          labelFormatter: (value) => '${(value * 100).toInt()}%',
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(brightness: value));
          },
        ),

        // Auto-scroll speed
        SettingsSliderTile(
          title: 'Auto-scroll Speed',
          subtitle: 'Speed for automatic page scrolling',
          value: settings.autoScrollSpeed,
          min: 0.1,
          max: 2.0,
          divisions: 19,
          labelFormatter: (value) => '${value.toStringAsFixed(1)}x',
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(autoScrollSpeed: value));
          },
        ),

        // Page turn animation
        SettingsListTile(
          title: 'Page Turn Animation',
          subtitle: settings.pageTurnAnimation.description,
          leading: PhosphorIcons.magicWand(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF6C5CE7),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings.pageTurnAnimation.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
          onTap: () => _showPageTurnAnimationDialog(context),
        ),

        // Volume key navigation
        SettingsSwitchTile(
          title: 'Volume Key Navigation',
          subtitle: 'Use volume keys to turn pages',
          value: settings.volumeKeyNavigation,
          leading: PhosphorIcons.speakerHigh(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF00CED1),
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(volumeKeyNavigation: value));
          },
        ),

        // Double tap to zoom
        SettingsSwitchTile(
          title: 'Double Tap to Zoom',
          subtitle: 'Double tap to zoom in/out of pages',
          value: settings.doubleTapToZoom,
          leading: PhosphorIcons.magnifyingGlassPlus(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFFFF9800),
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(doubleTapToZoom: value));
          },
        ),

        // Zoom level
        if (settings.doubleTapToZoom)
          SettingsSliderTile(
            title: 'Zoom Level',
            subtitle: 'Default zoom level when double-tapping',
            value: settings.zoomLevel,
            min: 1.0,
            max: 3.0,
            divisions: 20,
            labelFormatter: (value) => '${value.toStringAsFixed(1)}x',
            onChanged: (value) {
              onSettingsChanged(settings.copyWith(zoomLevel: value));
            },
          ),
      ],
    );
  }

  void _showPageTurnAnimationDialog(BuildContext context) {
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Page Turn Animation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...PageTurnAnimation.values.map((animation) {
                final isSelected = settings.pageTurnAnimation == animation;
                return ListTile(
                  leading: Icon(
                    _getAnimationIcon(animation),
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                  ),
                  title: Text(
                    animation.label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    animation.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          PhosphorIcons.check(PhosphorIconsStyle.fill),
                          color: const Color(0xFF6C5CE7),
                        )
                      : null,
                  onTap: () {
                    onSettingsChanged(settings.copyWith(pageTurnAnimation: animation));
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAnimationIcon(PageTurnAnimation animation) {
    switch (animation) {
      case PageTurnAnimation.none:
        return PhosphorIcons.prohibit(PhosphorIconsStyle.regular);
      case PageTurnAnimation.slide:
        return PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.regular);
      case PageTurnAnimation.fade:
        return PhosphorIcons.circle(PhosphorIconsStyle.regular);
      case PageTurnAnimation.curl:
        return PhosphorIcons.bookOpen(PhosphorIconsStyle.regular);
      case PageTurnAnimation.scale:
        return PhosphorIcons.arrowsOut(PhosphorIconsStyle.regular);
    }
  }
}
