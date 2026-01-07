import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../providers/settings_provider.dart';
import 'widgets/reader_preferences_section.dart';
import 'widgets/translation_settings_section.dart';
import 'widgets/api_config_section.dart';
import 'widgets/storage_management_section.dart';
import 'widgets/theme_customization_section.dart';
import 'widgets/performance_settings_section.dart';
import 'widgets/about_section.dart';

/// Main settings screen with all configuration sections
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                PhosphorIcons.arrowLeft(PhosphorIconsStyle.regular),
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Settings Sections
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Reader Preferences
                ReaderPreferencesSection(
                  settings: settings,
                  onSettingsChanged: (newSettings) {
                    ref.read(settingsProvider.notifier).updateSettings(newSettings);
                  },
                ),

                // Translation Settings
                TranslationSettingsSection(
                  settings: settings,
                  onSettingsChanged: (newSettings) {
                    ref.read(settingsProvider.notifier).updateSettings(newSettings);
                  },
                ),

                // API Configuration
                ApiConfigSection(
                  settings: settings,
                  onSettingsChanged: (newSettings) {
                    ref.read(settingsProvider.notifier).updateSettings(newSettings);
                  },
                ),

                // Storage Management
                const StorageManagementSection(),

                // Performance Settings
                PerformanceSettingsSection(
                  settings: settings,
                  onSettingsChanged: (newSettings) {
                    ref.read(settingsProvider.notifier).updateSettings(newSettings);
                  },
                ),

                // Theme Customization
                ThemeCustomizationSection(
                  settings: settings,
                  onSettingsChanged: (newSettings) {
                    ref.read(settingsProvider.notifier).updateSettings(newSettings);
                  },
                ),

                // About & Help
                const AboutSection(),

                // Bottom spacing
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings section header
class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings list tile with glassmorphism effect
class SettingsListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? leading;
  final Color? leadingColor;

  const SettingsListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(
              leading,
              color: leadingColor ?? Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Settings switch tile
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? leading;
  final Color? leadingColor;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.leading,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      leadingColor: leadingColor,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onTap: () => onChanged?.call(!value),
    );
  }
}

/// Settings slider tile
class SettingsSliderTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double>? onChanged;
  final String Function(double)? labelFormatter;

  const SettingsSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 10,
    this.onChanged,
    this.labelFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                labelFormatter?.call(value) ?? value.toString(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: const Color(0xFF6C5CE7),
          ),
        ],
      ),
    );
  }
}
