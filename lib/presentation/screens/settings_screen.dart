import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/glassmorphism.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    AppStrings.settingsTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // App Info
                  GlassmorphismCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF2196F3),
                                Color(0xFF4CAF50),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.appTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${AppConstants.appVersion}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settings Sections
                  _buildSettingSection(
                    context,
                    icon: PhosphorIcons.paintBrush(PhosphorIconsStyle.regular),
                    title: AppStrings.settingsTheme,
                    subtitle: 'Dark mode enabled',
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _buildSettingSection(
                    context,
                    icon: PhosphorIcons.hardDrives(PhosphorIconsStyle.regular),
                    title: AppStrings.settingsStorage,
                    subtitle: 'Manage storage location',
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _buildSettingSection(
                    context,
                    icon: PhosphorIcons.info(PhosphorIconsStyle.regular),
                    title: AppStrings.settingsAbout,
                    subtitle: 'About INX',
                    onTap: () {},
                  ),
                  const SizedBox(height: 32),

                  // Copyright
                  Center(
                    child: Text(
                      '© 2024 INX. All rights reserved.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassmorphismCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
            size: 20,
            color: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
