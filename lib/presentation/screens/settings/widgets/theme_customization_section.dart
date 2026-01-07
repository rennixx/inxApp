import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/entities/settings.dart';
import '../settings_screen.dart';

/// Theme customization section
class ThemeCustomizationSection extends ConsumerWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const ThemeCustomizationSection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SettingsSectionHeader(
          title: 'Theme Customization',
          subtitle: 'Personalize the app appearance',
          icon: PhosphorIcons.paintBrush(PhosphorIconsStyle.regular),
        ),

        // Theme mode
        SettingsListTile(
          title: 'Theme Mode',
          subtitle: _getThemeModeLabel(settings.themeMode),
          leading: PhosphorIcons.moon(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF6C5CE7),
          trailing: Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
          onTap: () => _showThemeModeDialog(context),
        ),

        // OLED mode
        SettingsSwitchTile(
          title: 'OLED Mode',
          subtitle: 'Pure black background for OLED screens',
          value: settings.useOLEDMode,
          leading: PhosphorIcons.monitor(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF00CED1),
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(useOLEDMode: value));
          },
        ),

        // Accent color
        SettingsListTile(
          title: 'Accent Color',
          subtitle: 'Primary theme color',
          leading: PhosphorIcons.circle(PhosphorIconsStyle.fill),
          leadingColor: settings.accentColor,
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: settings.accentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          onTap: () => _showAccentColorDialog(context),
        ),

        // Font size
        SettingsSliderTile(
          title: 'Font Size',
          subtitle: 'Base font size for text content',
          value: settings.fontSize,
          min: 10,
          max: 20,
          divisions: 10,
          labelFormatter: (value) => '${value.toInt()}sp',
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(fontSize: value));
          },
        ),

        // UI Density
        SettingsListTile(
          title: 'UI Density',
          subtitle: settings.uiDensity.label,
          leading: PhosphorIcons.rows(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFFFF9800),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings.uiDensity.label,
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
          onTap: () => _showUIDensityDialog(context),
        ),
      ],
    );
  }

  void _showThemeModeDialog(BuildContext context) {
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
                  'Theme Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...ThemeMode.values.map((mode) {
                final isSelected = settings.themeMode == mode;
                return ListTile(
                  leading: Icon(
                    _getThemeModeIcon(mode),
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                  ),
                  title: Text(
                    _getThemeModeLabel(mode),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    _getThemeModeDescription(mode),
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
                    onSettingsChanged(settings.copyWith(themeMode: mode));
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccentColorDialog(BuildContext context) {
    final colors = [
      const Color(0xFF6C5CE7), // Purple
      const Color(0xFFF44336), // Red
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF2196F3), // Blue
      const Color(0xFF9C27B0), // Deep Purple
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
    ];

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
                  'Accent Color',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: colors.map((color) {
                    final isSelected = settings.accentColor == color;
                    return GestureDetector(
                      onTap: () {
                        onSettingsChanged(settings.copyWith(accentColor: color));
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                PhosphorIcons.check(PhosphorIconsStyle.fill),
                                color: Colors.white,
                                size: 24,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUIDensityDialog(BuildContext context) {
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
                  'UI Density',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...UIDensity.values.map((density) {
                final isSelected = settings.uiDensity == density;
                return ListTile(
                  leading: Icon(
                    _getDensityIcon(density),
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                  ),
                  title: Text(
                    density.label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${(density.scaleFactor * 100).toInt()}% scale',
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
                    onSettingsChanged(settings.copyWith(uiDensity: density));
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow system theme';
      case ThemeMode.light:
        return 'Always light mode';
      case ThemeMode.dark:
        return 'Always dark mode';
    }
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return PhosphorIcons.desktop(PhosphorIconsStyle.regular);
      case ThemeMode.light:
        return PhosphorIcons.sun(PhosphorIconsStyle.regular);
      case ThemeMode.dark:
        return PhosphorIcons.moon(PhosphorIconsStyle.regular);
    }
  }

  IconData _getDensityIcon(UIDensity density) {
    switch (density) {
      case UIDensity.compact:
        return PhosphorIcons.minus(PhosphorIconsStyle.regular);
      case UIDensity.medium:
        return PhosphorIcons.equals(PhosphorIconsStyle.regular);
      case UIDensity.spacious:
        return PhosphorIcons.plus(PhosphorIconsStyle.regular);
    }
  }
}
