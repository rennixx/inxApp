import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../settings_screen.dart';

/// About & Help section
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SettingsSectionHeader(
          title: 'About & Help',
          subtitle: 'App information and support',
          icon: PhosphorIcons.info(PhosphorIconsStyle.regular),
        ),

        // App version
        SettingsListTile(
          title: 'Version',
          subtitle: 'INX Manga Reader v1.0.0',
          leading: PhosphorIcons.tag(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF6C5CE7),
        ),

        // Build info
        SettingsListTile(
          title: 'Build',
          subtitle: 'Phase 9 - Settings & Preferences',
          leading: PhosphorIcons.hammer(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF00CED1),
        ),

        // License
        SettingsListTile(
          title: 'License',
          subtitle: 'MIT License - Open Source',
          leading: PhosphorIcons.certificate(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF4CAF50),
          trailing: Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
          onTap: () => _showLicenseDialog(context),
        ),

        // GitHub repository
        SettingsListTile(
          title: 'GitHub Repository',
          subtitle: 'View source code and contribute',
          leading: PhosphorIcons.githubLogo(PhosphorIconsStyle.regular),
          leadingColor: Colors.white,
          trailing: Icon(
            PhosphorIcons.arrowSquareOut(PhosphorIconsStyle.regular),
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
          onTap: () => _launchUrl('https://github.com/your-username/inx'),
        ),

        // Report a bug
        SettingsListTile(
          title: 'Report a Bug',
          subtitle: 'Submit issues and feature requests',
          leading: PhosphorIcons.bug(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFFF44336),
          trailing: Icon(
            PhosphorIcons.arrowSquareOut(PhosphorIconsStyle.regular),
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
          onTap: () => _launchUrl('https://github.com/your-username/inx/issues'),
        ),

        // Help & Documentation
        SettingsListTile(
          title: 'Help & Documentation',
          subtitle: 'User guide and FAQs',
          leading: PhosphorIcons.book(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFFFF9800),
          trailing: Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
          onTap: () => _showHelpDialog(context),
        ),

        // Privacy Policy
        SettingsListTile(
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          leading: PhosphorIcons.shieldCheck(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF9C27B0),
          trailing: Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
          onTap: () => _showPrivacyDialog(context),
        ),

        // Credits
        SettingsListTile(
          title: 'Credits',
          subtitle: 'Libraries and acknowledgments',
          leading: PhosphorIcons.heart(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFFE91E63),
          trailing: Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
            color: Colors.white.withValues(alpha: 0.5),
            size: 16,
          ),
          onTap: () => _showCreditsDialog(context),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'MIT License',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '''
Copyright (c) 2024 INX Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Help & Documentation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHelpItem(
                    context,
                    icon: PhosphorIcons.file(PhosphorIconsStyle.regular),
                    title: 'Getting Started',
                    description: 'Learn how to import and read manga',
                  ),
                  _buildHelpItem(
                    context,
                    icon: PhosphorIcons.translate(PhosphorIconsStyle.regular),
                    title: 'Translation Guide',
                    description: 'Set up AI-powered translations',
                  ),
                  _buildHelpItem(
                    context,
                    icon: PhosphorIcons.gear(PhosphorIconsStyle.regular),
                    title: 'Settings Overview',
                    description: 'Customize your reading experience',
                  ),
                  _buildHelpItem(
                    context,
                    icon: PhosphorIcons.keyboard(PhosphorIconsStyle.regular),
                    title: 'Keyboard Shortcuts',
                    description: 'Navigate efficiently',
                  ),
                  _buildHelpItem(
                    context,
                    icon: PhosphorIcons.question(PhosphorIconsStyle.regular),
                    title: 'FAQs',
                    description: 'Frequently asked questions',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.7),
        size: 20,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '''
Privacy Policy for INX Manga Reader

Last Updated: January 2024

1. Data Collection
INX Manga Reader is a privacy-focused application. We do not collect any personal data or usage statistics.

2. Local Storage
All manga files, translations, and settings are stored locally on your device. No data is transmitted to external servers except for translation API calls.

3. Translation Services
When you use AI translation features, text content is sent to the selected translation provider (Google Gemini, OpenAI, or Anthropic). These services may process your content according to their own privacy policies.

4. Permissions
• Storage: Required to read manga files and save translations
• Internet: Required for AI translation features
• Volume Keys: Optional, for page navigation

5. Third-Party Services
This app uses the following third-party services:
- Google Gemini API (for translations)
- Phosphor Icons (UI icons)
- Flutter Framework

6. Contact
For any privacy concerns or questions, please contact us through our GitHub repository.

This policy may be updated as the app evolves. Continued use of the app constitutes acceptance of any changes.''',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreditsDialog(BuildContext context) {
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
                  'Credits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const ListTile(
                leading: FlutterLogo(size: 24),
                title: Text(
                  'Flutter Framework',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'UI Framework by Google',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                  color: const Color(0xFF4285F4),
                ),
                title: const Text(
                  'Phosphor Icons',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Icon library',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.sparkle(PhosphorIconsStyle.regular),
                  color: const Color(0xFF6C5CE7),
                ),
                title: const Text(
                  'Riverpod',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'State management',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.translate(PhosphorIconsStyle.regular),
                  color: const Color(0xFF4285F4),
                ),
                title: const Text(
                  'Google Gemini',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'AI Translation API',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    // TODO: Implement url_launcher when package is added
    // For now, just show a snackbar
    // final uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri);
    // }
  }
}
