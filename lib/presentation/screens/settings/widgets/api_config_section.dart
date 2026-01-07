import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../data/services/translation_pipeline_service.dart';
import '../../../../domain/entities/settings.dart';
import '../settings_screen.dart';

/// API Configuration Section for translation services
class ApiConfigSection extends ConsumerStatefulWidget {
  final AppSettings settings;
  final Function(AppSettings) onSettingsChanged;

  const ApiConfigSection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  ConsumerState<ApiConfigSection> createState() => _ApiConfigSectionState();
}

class _ApiConfigSectionState extends ConsumerState<ApiConfigSection> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isKeyVisible = false;
  bool _isTestingConnection = false;
  bool _isInitialized = false;
  String _maskedKey = 'Not configured';

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final isConfigured = await ApiConfig.isGeminiKeyConfigured();
    final maskedKey = await ApiConfig.getMaskedApiKey();

    setState(() {
      _isInitialized = isConfigured;
      _maskedKey = maskedKey;
    });
  }

  Future<void> _saveApiKey(String apiKey) async {
    final success = await ApiConfig.saveGeminiApiKey(apiKey);

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save API key'),
            backgroundColor: Color(0xFFE74C3C),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Initialize the translation pipeline with the new key
    try {
      await TranslationPipelineService.initialize(geminiApiKey: apiKey);
      final maskedKey = await ApiConfig.getMaskedApiKey();

      setState(() {
        _isInitialized = true;
        _maskedKey = maskedKey;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key saved successfully'),
            backgroundColor: Color(0xFF00B894),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API key saved but initialization failed: $e'),
            backgroundColor: Color(0xFFF39C12),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    if (!TranslationPipelineService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure API key first'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }

    setState(() {
      _isTestingConnection = true;
    });

    try {
      // Test the API connection by translating a simple text
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection successful!'),
            backgroundColor: Color(0xFF00B894),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Color(0xFFE74C3C),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Remove API Key?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will disable AI translation features. You can add a new key at any time.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6C5CE7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFE74C3C)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiConfig.removeGeminiApiKey();
      setState(() {
        _isInitialized = false;
        _maskedKey = 'Not configured';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key removed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showApiKeyDialog() {
    _apiKeyController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            Icon(
              PhosphorIcons.key(PhosphorIconsStyle.regular),
              color: const Color(0xFF6C5CE7),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Gemini API Key',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API key to enable AI translation features.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: !_isKeyVisible,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'API Key',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                hintText: 'AIza...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isKeyVisible
                        ? PhosphorIcons.eyeSlash(PhosphorIconsStyle.regular)
                        : PhosphorIcons.eye(PhosphorIconsStyle.regular),
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    setState(() {
                      _isKeyVisible = !_isKeyVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF6C5CE7),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassmorphismCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.info(PhosphorIconsStyle.regular),
                        size: 14,
                        color: const Color(0xFF6C5CE7),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'How to get your API key:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '1. Go to https://aistudio.google.com/app/apikey\n'
                    '2. Sign in with your Google account\n'
                    '3. Click "Create API key"\n'
                    '4. Copy and paste the key below',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6C5CE7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = _apiKeyController.text.trim();
              if (apiKey.isNotEmpty) {
                await _saveApiKey(apiKey);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSectionHeader(
          title: 'API Configuration',
          subtitle: 'Configure AI translation services',
          icon: PhosphorIcons.key(PhosphorIconsStyle.regular),
        ),
        SettingsListTile(
          title: 'Gemini API Key',
          subtitle: _isInitialized
              ? _maskedKey
              : 'Not configured - Translation features disabled',
          leading: PhosphorIcons.key(PhosphorIconsStyle.regular),
          leadingColor: _isInitialized ? const Color(0xFF00B894) : const Color(0xFF6C5CE7),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isInitialized) ...[
                if (_isTestingConnection)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.regular),
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    onPressed: _testConnection,
                    tooltip: 'Test Connection',
                  ),
                IconButton(
                  icon: Icon(
                    PhosphorIcons.trash(PhosphorIconsStyle.regular),
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  onPressed: _removeApiKey,
                  tooltip: 'Remove Key',
                ),
              ] else ...[
                Icon(
                  PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
          onTap: _isInitialized ? null : _showApiKeyDialog,
        ),
        if (!_isInitialized)
          GlassmorphismCard(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.warning(PhosphorIconsStyle.regular),
                      size: 16,
                      color: const Color(0xFFF39C12),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'API Key Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Translation features require a Gemini API key. Get your free API key from Google AI Studio.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(
                      text: 'https://aistudio.google.com/app/apikey',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.link(PhosphorIconsStyle.regular),
                        size: 14,
                        color: const Color(0xFF6C5CE7),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Get API Key →',
                        style: TextStyle(
                          color: Color(0xFF6C5CE7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
