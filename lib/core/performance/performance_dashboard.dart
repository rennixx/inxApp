import 'dart:async';
import 'package:flutter/material.dart';
import 'performance_monitor.dart';
import 'battery_optimizer.dart';
import 'memory_manager.dart';
import 'power_profile_manager.dart';
import 'dynamic_memory_manager.dart';
import 'background_processing_manager.dart';

/// Performance monitoring dashboard with real-time metrics
class PerformanceDashboard extends StatefulWidget {
  final bool enabled;

  const PerformanceDashboard({
    super.key,
    this.enabled = true,
  });

  @override
  State<PerformanceDashboard> createState() => PerformanceDashboardState();
}

class PerformanceDashboardState extends State<PerformanceDashboard> {
  // Monitoring state
  bool _isMonitoring = false;
  OverlayEntry? _dashboardOverlay;

  // Metrics
  final List<double> _fpsHistory = [];
  final List<double> _memoryHistory = [];
  final List<double> _batteryHistory = [];
  static const int _maxHistoryLength = 60;

  // Update timer
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  /// Start monitoring
  void _startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    PerformanceMonitor().startMonitoring();

    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateMetrics();
    });
  }

  /// Stop monitoring
  void _stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _updateTimer?.cancel();
    PerformanceMonitor().stopMonitoring();
  }

  /// Update metrics
  void _updateMetrics() {
    if (!_isMonitoring) return;

    final monitor = PerformanceMonitor();
    final summary = monitor.getSummary();

    // Update FPS history
    _fpsHistory.add(summary.currentFPS);
    if (_fpsHistory.length > _maxHistoryLength) {
      _fpsHistory.removeAt(0);
    }

    // Update memory history
    _memoryHistory.add(summary.memoryUsage.currentMB.toDouble());
    if (_memoryHistory.length > _maxHistoryLength) {
      _memoryHistory.removeAt(0);
    }

    // Update battery history
    final powerStatus = BatteryOptimizer().getPowerStatus();
    _batteryHistory.add(powerStatus.throttleSeconds.toDouble());
    if (_batteryHistory.length > _maxHistoryLength) {
      _batteryHistory.removeAt(0);
    }

    // Notify dashboard if visible
    _dashboardOverlay?.markNeedsBuild();
  }

  /// Toggle dashboard visibility
  void toggleDashboard(BuildContext context) {
    if (_dashboardOverlay != null) {
      _hideDashboard();
    } else {
      _showDashboard(context);
    }
  }

  /// Show dashboard overlay
  void _showDashboard(BuildContext context) {
    _dashboardOverlay = OverlayEntry(
      builder: (context) => _PerformanceDashboardWidget(
        fpsHistory: _fpsHistory,
        memoryHistory: _memoryHistory,
        batteryHistory: _batteryHistory,
        onClose: () => _hideDashboard(),
      ),
    );

    Overlay.of(context).insert(_dashboardOverlay!);
  }

  /// Hide dashboard overlay
  void _hideDashboard() {
    _dashboardOverlay?.remove();
    _dashboardOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Performance dashboard widget
class _PerformanceDashboardWidget extends StatefulWidget {
  final List<double> fpsHistory;
  final List<double> memoryHistory;
  final List<double> batteryHistory;
  final VoidCallback onClose;

  const _PerformanceDashboardWidget({
    required this.fpsHistory,
    required this.memoryHistory,
    required this.batteryHistory,
    required this.onClose,
  });

  @override
  State<_PerformanceDashboardWidget> createState() => _PerformanceDashboardWidgetState();
}

class _PerformanceDashboardWidgetState extends State<_PerformanceDashboardWidget> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Performance Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MetricsSection(
                fpsHistory: widget.fpsHistory,
                memoryHistory: widget.memoryHistory,
                batteryHistory: widget.batteryHistory,
              ),
              const SizedBox(height: 16),
              _DetailedStatsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Metrics section with graphs
class _MetricsSection extends StatelessWidget {
  final List<double> fpsHistory;
  final List<double> memoryHistory;
  final List<double> batteryHistory;

  const _MetricsSection({
    required this.fpsHistory,
    required this.memoryHistory,
    required this.batteryHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGraph(
          title: 'FPS',
          data: fpsHistory,
          color: _getFPSColor(fpsHistory.isNotEmpty ? fpsHistory.last : 60),
          minValue: 0,
          maxValue: 60,
        ),
        const SizedBox(height: 12),
        _MetricGraph(
          title: 'Memory (MB)',
          data: memoryHistory,
          color: Colors.blue,
          minValue: 0,
          maxValue: 512,
        ),
      ],
    );
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.yellow;
    return Colors.red;
  }
}

/// Metric graph widget
class _MetricGraph extends StatelessWidget {
  final String title;
  final List<double> data;
  final Color color;
  final double minValue;
  final double maxValue;

  const _MetricGraph({
    required this.title,
    required this.data,
    required this.color,
    required this.minValue,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = data.isNotEmpty ? data.last : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currentValue.toStringAsFixed(1),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: _GraphPainter(
              data: data,
              color: color,
              minValue: minValue,
              maxValue: maxValue,
            ),
          ),
        ),
      ],
    );
  }
}

/// Graph painter for metric visualization
class _GraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minValue;
  final double maxValue;

  _GraphPainter({
    required this.data,
    required this.color,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final width = size.width;
    final height = size.height;
    final step = width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final normalizedValue = (data[i] - minValue) / (maxValue - minValue);
      final y = height - (normalizedValue * height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(width, height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Detailed statistics section
class _DetailedStatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final memoryInfo = MemoryManager().getMemoryInfo();
    final profileStats = PowerProfileManager().getStatistics();
    final memStats = DynamicMemoryManager().getStatistics();
    final bgManager = BackgroundProcessingManager();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Statistics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _StatRow('Power Profile', profileStats.profileLabel),
        _StatRow('Battery', '${profileStats.batteryFormatted} (${profileStats.chargingStatus})'),
        _StatRow('Thermal State', bgManager.thermalState.label),
        _StatRow('Memory Usage', memoryInfo.usageFormatted),
        _StatRow('Memory Pressure', memoryInfo.pressure.label),
        _StatRow('Device Memory', '${memStats.memoryClassLabel} (${memStats.deviceRAMMB}MB)'),
        _StatRow('Tracked Objects', '${memStats.trackedObjects}'),
        _StatRow('Queued Tasks', '${bgManager.queueSize}'),
        _StatRow('Image Quality', '${(profileStats.imageQuality * 100).toStringAsFixed(0)}%'),
        _StatRow('Preload Pages', '${profileStats.preloadPageCount}'),
        _StatRow('Max Translations', '${profileStats.maxConcurrentTranslations}'),
      ],
    );
  }
}

/// Stat row widget
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thermal state extension
extension ThermalStateExtension on ThermalState {
  String get label {
    switch (this) {
      case ThermalState.nominal:
        return 'Nominal';
      case ThermalState.fair:
        return 'Fair';
      case ThermalState.serious:
        return 'Serious';
      case ThermalState.critical:
        return 'Critical';
    }
  }
}

/// Memory pressure extension
extension MemoryPressureExtension on MemoryPressure {
  String get label {
    switch (this) {
      case MemoryPressure.low:
        return 'Low';
      case MemoryPressure.medium:
        return 'Medium';
      case MemoryPressure.high:
        return 'High';
    }
  }
}
