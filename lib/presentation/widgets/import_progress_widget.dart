import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/services/import_queue_service.dart';
import '../../core/theme/glassmorphism.dart';

class ImportProgressWidget extends StatelessWidget {
  final ImportQueueState state;
  final VoidCallback? onCancel;

  const ImportProgressWidget({
    super.key,
    required this.state,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == ImportStatus.idle && !state.isProcessing) {
      return const SizedBox.shrink();
    }

    return GlassmorphismContainer(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (state.currentOperation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        state.currentOperation!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (state.isProcessing && onCancel != null)
                IconButton(
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.regular)),
                  onPressed: onCancel,
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),

          // Overall Progress
          if (state.totalFiles > 0) ...[
            const SizedBox(height: 16),
            _buildProgressBar(
              context,
              progress: state.overallProgress,
              label: '${state.completedFiles}/${state.totalFiles} files',
            ),
          ],

          // Task List
          if (state.tasks.isNotEmpty && state.isProcessing) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 8),
            ...state.tasks.take(3).map((task) => _buildTaskItem(context, task)),
            if (state.tasks.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '+ ${state.tasks.length - 3} more files',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],

          // Summary
          if (state.status == ImportStatus.completed) ...[
            const SizedBox(height: 16),
            _buildSummary(context),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color iconColor;

    switch (state.status) {
      case ImportStatus.scanning:
        iconData = PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular);
        iconColor = const Color(0xFF2196F3);
        break;
      case ImportStatus.importing:
        iconData = PhosphorIcons.arrowClockwise(PhosphorIconsStyle.regular);
        iconColor = const Color(0xFF2196F3);
        break;
      case ImportStatus.completed:
        iconData = PhosphorIcons.check(PhosphorIconsStyle.regular);
        iconColor = const Color(0xFF4CAF50);
        break;
      case ImportStatus.error:
        iconData = PhosphorIcons.warning(PhosphorIconsStyle.regular);
        iconColor = const Color(0xFFF44336);
        break;
      default:
        iconData = PhosphorIcons.info(PhosphorIconsStyle.regular);
        iconColor = Colors.white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context, {
    required double progress,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label != null)
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, ImportTask task) {
    IconData iconData;
    Color iconColor;

    switch (task.status) {
      case ImportStatus.importing:
        iconData = PhosphorIcons.spinner(PhosphorIconsStyle.regular);
        iconColor = const Color(0xFF2196F3);
        break;
      case ImportStatus.completed:
        iconData = PhosphorIcons.check(PhosphorIconsStyle.regular);
        iconColor = const Color(0xFF4CAF50);
        break;
      case ImportStatus.error:
        iconData = PhosphorIcons.x(PhosphorIconsStyle.regular);
        iconColor = const Color(0xFFF44336);
        break;
      default:
        iconData = PhosphorIcons.clock(PhosphorIconsStyle.regular);
        iconColor = Colors.white.withValues(alpha: 0.5);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: task.status == ImportStatus.importing
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  )
                : Icon(
                    iconData,
                    color: iconColor,
                    size: 16,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (task.error != null)
            IconButton(
              icon: Icon(PhosphorIcons.warning(PhosphorIconsStyle.regular), size: 16),
              onPressed: () => _showErrorDialog(context, task),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Imported ${state.completedFiles} of ${state.totalFiles} files successfully',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (state.status) {
      case ImportStatus.scanning:
        return 'Scanning files...';
      case ImportStatus.importing:
        return 'Importing files...';
      case ImportStatus.completed:
        return 'Import completed';
      case ImportStatus.error:
        return 'Import failed';
      default:
        return 'Preparing...';
    }
  }

  void _showErrorDialog(BuildContext context, ImportTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${task.title}'),
            const SizedBox(height: 8),
            Text(
              task.error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
