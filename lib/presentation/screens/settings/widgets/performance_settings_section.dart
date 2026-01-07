import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/performance/power_profile_manager.dart';
import '../../../../core/performance/performance_dashboard.dart';
import '../../../../core/performance/dynamic_memory_manager.dart';
import '../../../../core/performance/background_processing_manager.dart';
import '../../../../domain/entities/settings.dart';
import '../settings_screen.dart';

/// Performance and power settings section
class PerformanceSettingsSection extends ConsumerStatefulWidget {
  final AppSettings settings;
  final Function(AppSettings) onSettingsChanged;

  const PerformanceSettingsSection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  ConsumerState<PerformanceSettingsSection> createState() => _PerformanceSettingsSectionState();
}

class _PerformanceSettingsSectionState extends ConsumerState<PerformanceSettingsSection> {
  final PowerProfileManager _powerProfileManager = PowerProfileManager();
  bool _dashboardEnabled = false;

  @override
  void initState() {
    super.initState();
    _powerProfileManager.addProfileChangeListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _powerProfileManager.removeProfileChangeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged(PowerProfile profile) {
    setState(() {}); // Rebuild when profile changes
  }

  void _showProfileSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Power Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...PowerProfile.values.map((profile) {
                final isSelected = _powerProfileManager.currentProfile == profile;
                return ListTile(
                  leading: Text(
                    profile.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    profile.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    profile.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                          color: const Color(0xFF6C5CE7),
                        )
                      : null,
                  onTap: () {
                    _powerProfileManager.setProfile(profile);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SwitchListTile(
                  title: const Text(
                    'Auto-switch profiles',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Automatically switch based on battery level',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  value: false, // TODO: Get from power profile manager
                  onChanged: (value) {
                    if (value) {
                      _powerProfileManager.enableAutoSwitch();
                    } else {
                      _powerProfileManager.disableAutoSwitch();
                    }
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showPerformanceDashboard(BuildContext context) {
    // Show performance dashboard overlay
    // This would typically be done through a global key or navigator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Performance dashboard enabled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMemoryInfo(BuildContext context) {
    final memStats = DynamicMemoryManager().getStatistics();
    final bgManager = BackgroundProcessingManager();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Memory Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _MemoryInfoTile('Device Memory', '${memStats.memoryClassLabel} (${memStats.deviceRAMMB}MB)'),
              _MemoryInfoTile('Max Cache Size', memStats.maxImageCacheFormatted),
              _MemoryInfoTile('Max Preload Pages', '${memStats.maxPreloadPages}'),
              _MemoryInfoTile('Pages Ahead/Behind', '${memStats.maxPagesAhead}/${memStats.maxPagesBehind}'),
              _MemoryInfoTile('Tracked Objects', '${memStats.trackedObjects}'),
              _MemoryInfoTile('Texture Pool Size', '${memStats.texturePoolSize}'),
              _MemoryInfoTile('Loaded Pages', '${memStats.loadedPagesCount}'),
              _MemoryInfoTile('Queued Tasks', '${bgManager.queueSize}'),
              _MemoryInfoTile('Battery Level', '${bgManager.batteryLevel.toStringAsFixed(0)}%'),
              _MemoryInfoTile('Thermal State', bgManager.thermalState.label),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileStats = _powerProfileManager.getStatistics();

    return Column(
      children: [
        SettingsSectionHeader(
          title: 'Performance',
          subtitle: 'Power and memory optimization',
          icon: PhosphorIcons.gauge(PhosphorIconsStyle.regular),
        ),
        SettingsListTile(
          title: 'Power Profile',
          subtitle: profileStats.profileLabel,
          leading: PhosphorIcons.lightning(PhosphorIconsStyle.regular),
          leadingColor: _getProfileColor(_powerProfileManager.currentProfile),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profileStats.batteryFormatted,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          onTap: () => _showProfileSelector(context),
        ),
        SettingsSwitchTile(
          title: 'Performance Dashboard',
          subtitle: 'Show real-time FPS and memory metrics',
          value: _dashboardEnabled,
          onChanged: (value) {
            setState(() {
              _dashboardEnabled = value;
            });
            if (value) {
              _showPerformanceDashboard(context);
            }
          },
          leading: PhosphorIcons.chartLine(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF00B894),
        ),
        SettingsListTile(
          title: 'Memory Information',
          subtitle: 'View memory usage and device info',
          leading: PhosphorIcons.memory(PhosphorIconsStyle.regular),
          leadingColor: const Color(0xFF6C5CE7),
          trailing: Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.regular),
            size: 16,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          onTap: () => _showMemoryInfo(context),
        ),
      ],
    );
  }

  Color _getProfileColor(PowerProfile profile) {
    switch (profile) {
      case PowerProfile.batterySaver:
        return const Color(0xFFE74C3C);
      case PowerProfile.dataSaver:
        return const Color(0xFFF39C12);
      case PowerProfile.balanced:
        return const Color(0xFF6C5CE7);
      case PowerProfile.performance:
        return const Color(0xFF00B894);
    }
  }
}

class _MemoryInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _MemoryInfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
