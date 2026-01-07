import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/entities/settings.dart';
import '../settings_screen.dart';

/// Translation settings section
class TranslationSettingsSection extends ConsumerWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const TranslationSettingsSection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SettingsSectionHeader(
          title: 'Translation Settings',
          subtitle: 'Configure AI translation preferences',
          icon: PhosphorIcons.translate(PhosphorIconsStyle.regular),
        ),

        // Target language
        SettingsListTile(
          title: 'Target Language',
          subtitle: 'Language for translations',
          leading: PhosphorIcons.globe(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF6C5CE7),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getLanguageLabel(settings.targetLanguage),
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
          onTap: () => _showLanguageDialog(context),
        ),

        // AI Model
        SettingsListTile(
          title: 'AI Model',
          subtitle: settings.translationModel.description,
          leading: PhosphorIcons.robot(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF00CED1),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings.translationModel.label,
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
          onTap: () => _showModelDialog(context),
        ),

        // Translation quality
        SettingsListTile(
          title: 'Translation Quality',
          subtitle: settings.translationQuality.description,
          leading: PhosphorIcons.lightning(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFFFF9800),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings.translationQuality.label,
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
          onTap: () => _showQualityDialog(context),
        ),

        // Enable cache
        SettingsSwitchTile(
          title: 'Enable Translation Cache',
          subtitle: 'Cache translations to reduce API calls',
          value: settings.enableTranslationCache,
          leading: PhosphorIcons.database(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF4CAF50),
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(enableTranslationCache: value));
          },
        ),

        // Cache size limit
        if (settings.enableTranslationCache)
          SettingsSliderTile(
            title: 'Max Cache Size',
            subtitle: 'Maximum cache size in MB',
            value: settings.maxCacheSizeMB.toDouble(),
            min: 100,
            max: 2000,
            divisions: 19,
            labelFormatter: (value) => '${value.toInt()} MB',
            onChanged: (value) {
              onSettingsChanged(settings.copyWith(maxCacheSizeMB: value.toInt()));
            },
          ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languages = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'hi': 'Hindi',
    };

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
                  'Target Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...languages.entries.map((entry) {
                final isSelected = settings.targetLanguage == entry.key;
                return ListTile(
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          PhosphorIcons.check(PhosphorIconsStyle.fill),
                          color: const Color(0xFF6C5CE7),
                        )
                      : null,
                  onTap: () {
                    onSettingsChanged(settings.copyWith(targetLanguage: entry.key));
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

  void _showModelDialog(BuildContext context) {
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
                  'AI Translation Model',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...TranslationModel.values.map((model) {
                final isSelected = settings.translationModel == model;
                return ListTile(
                  leading: Icon(
                    _getModelIcon(model),
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                  ),
                  title: Text(
                    model.label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    model.description,
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
                    onSettingsChanged(settings.copyWith(translationModel: model));
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

  void _showQualityDialog(BuildContext context) {
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
                  'Translation Quality',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...TranslationQuality.values.map((quality) {
                final isSelected = settings.translationQuality == quality;
                return ListTile(
                  leading: Icon(
                    _getQualityIcon(quality),
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                  ),
                  title: Text(
                    quality.label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    quality.description,
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
                    onSettingsChanged(settings.copyWith(translationQuality: quality));
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

  String _getLanguageLabel(String code) {
    final languages = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'hi': 'Hindi',
    };
    return languages[code] ?? code.toUpperCase();
  }

  IconData _getModelIcon(TranslationModel model) {
    switch (model) {
      case TranslationModel.geminiPro:
        return PhosphorIcons.lightning(PhosphorIconsStyle.fill);
      case TranslationModel.geminiFlash:
        return PhosphorIcons.lightning(PhosphorIconsStyle.regular);
      case TranslationModel.gpt4:
        return PhosphorIcons.brain(PhosphorIconsStyle.regular);
      case TranslationModel.claude:
        return PhosphorIcons.sparkle(PhosphorIconsStyle.regular);
    }
  }

  IconData _getQualityIcon(TranslationQuality quality) {
    switch (quality) {
      case TranslationQuality.fast:
        return PhosphorIcons.gauge(PhosphorIconsStyle.regular);
      case TranslationQuality.balanced:
        return PhosphorIcons.scales(PhosphorIconsStyle.regular);
      case TranslationQuality.accurate:
        return PhosphorIcons.star(PhosphorIconsStyle.fill);
    }
  }
}
