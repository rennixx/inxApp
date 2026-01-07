import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../settings_screen.dart';

/// Storage management section
class StorageManagementSection extends ConsumerWidget {
  const StorageManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SettingsSectionHeader(
          title: 'Storage Management',
          subtitle: 'Manage app storage and cache',
          icon: PhosphorIcons.hardDrives(PhosphorIconsStyle.regular),
        ),

        // Storage usage display
        SettingsListTile(
          title: 'Storage Used',
          subtitle: 'Total storage used by app',
          leading: PhosphorIcons.chartPie(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF6C5CE7),
          trailing: FutureBuilder<StorageInfo>(
            future: _getStorageInfo(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  snapshot.data!.usedMB,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }
              return const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                ),
              );
            },
          ),
        ),

        // Cache size
        SettingsListTile(
          title: 'Translation Cache',
          subtitle: 'Storage used for translation cache',
          leading: PhosphorIcons.database(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF00CED1),
          trailing: FutureBuilder<StorageInfo>(
            future: _getStorageInfo(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.data!.cacheMB,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                );
              }
              return const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                ),
              );
            },
          ),
          onTap: () => _showCacheDialog(context),
        ),

        // Import location
        SettingsListTile(
          title: 'Import Location',
          subtitle: 'Default folder for importing manga',
          leading: PhosphorIcons.folder(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFFFF9800),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '/Download',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 4),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
          onTap: () => _showImportLocationDialog(context),
        ),

        // Clear cache button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                PhosphorIcons.trash(PhosphorIconsStyle.regular),
                color: const Color(0xFFF44336),
              ),
              label: const Text(
                'Clear All Cache',
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: const Color(0xFFF44336).withValues(alpha: 0.3),
                  ),
                ),
              ),
              onPressed: () => _confirmClearCache(context),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Future<StorageInfo> _getStorageInfo() async {
    // Simulate storage info
    await Future.delayed(const Duration(milliseconds: 500));
    return StorageInfo(
      usedMB: '245 MB',
      cacheMB: '128 MB',
      totalMB: '2048 MB',
    );
  }

  void _showCacheDialog(BuildContext context) {
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
                  'Translation Cache',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        PhosphorIcons.files(PhosphorIconsStyle.regular),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      title: const Text(
                        'Cached Translations',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        '128 MB • 245 files',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Icon(
                        PhosphorIcons.clock(PhosphorIconsStyle.regular),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      title: const Text(
                        'Last Cleanup',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        '7 days ago',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          PhosphorIcons.broom(PhosphorIconsStyle.regular),
                          size: 18,
                        ),
                        label: const Text('Clean Old'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6C5CE7),
                          side: const BorderSide(
                            color: Color(0xFF6C5CE7),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _clearOldCache(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          PhosphorIcons.trash(PhosphorIconsStyle.regular),
                          size: 18,
                        ),
                        label: const Text('Clear All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF44336),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _clearAllCache(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportLocationDialog(BuildContext context) {
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
                  'Select Import Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.downloadSimple(PhosphorIconsStyle.regular),
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                title: const Text(
                  'Downloads',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  '/storage/emulated/0/Download',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.fileText(PhosphorIconsStyle.regular),
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                title: const Text(
                  'Documents',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  '/storage/emulated/0/Documents',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: Icon(
                  PhosphorIcons.folderPlus(PhosphorIconsStyle.regular),
                  color: const Color(0xFF6C5CE7),
                ),
                title: const Text(
                  'Browse...',
                  style: TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Clear All Cache?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will delete all cached translations. They will be re-downloaded when needed.',
          style: TextStyle(
            color: Colors.white54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6C5CE7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllCache(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }

  void _clearOldCache(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Old cache files cleared'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _clearAllCache(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All cache cleared'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }
}

/// Storage info model
class StorageInfo {
  final String usedMB;
  final String cacheMB;
  final String totalMB;

  StorageInfo({
    required this.usedMB,
    required this.cacheMB,
    required this.totalMB,
  });
}
