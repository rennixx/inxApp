import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/glassmorphism.dart';
import '../../data/services/import_queue_service.dart';
import '../providers/import_provider.dart';
import '../widgets/import_progress_widget.dart';

class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(importQueueNotifierProvider);
    final importNotifier = ref.watch(importQueueNotifierProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.importTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Import Options
                        InkWell(
                          onTap: importState.isProcessing
                              ? null
                              : () => importNotifier.importFromPicker(),
                          borderRadius: BorderRadius.circular(16),
                          child: GlassmorphismCard(
                            padding: const EdgeInsets.all(24),
                            child: Opacity(
                              opacity: importState.isProcessing ? 0.5 : 1.0,
                              child: Column(
                                children: [
                                  Icon(
                                    PhosphorIcons.files(PhosphorIconsStyle.regular),
                                    size: 48,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppStrings.importFiles,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Select individual files to import',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Supported: CBZ, CBR, PDF, Images',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: importState.isProcessing || kIsWeb
                              ? null
                              : () => importNotifier.importFromDirectory(),
                          borderRadius: BorderRadius.circular(16),
                          child: GlassmorphismCard(
                            padding: const EdgeInsets.all(24),
                            child: Opacity(
                              opacity: importState.isProcessing || kIsWeb ? 0.5 : 1.0,
                              child: Column(
                                children: [
                                  Icon(
                                    PhosphorIcons.folder(PhosphorIconsStyle.regular),
                                    size: 48,
                                    color: kIsWeb
                                        ? Colors.grey
                                        : Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppStrings.importFolder,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    kIsWeb
                                        ? 'Not available on web (use file picker)'
                                        : 'Import an entire folder',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  if (kIsWeb) ...[
                                    const SizedBox(height: 8),
                                    Icon(
                                      PhosphorIcons.warning(PhosphorIconsStyle.regular),
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Statistics
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Import Statistics',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GlassmorphismCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.chartBar(PhosphorIconsStyle.regular)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Imported',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${importState.completedFiles} files',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (importState.failedFiles > 0)
                                Column(
                                  children: [
                                    Text(
                                      '${importState.failedFiles}',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                    ),
                                    Text(
                                      'failed',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Import Progress Overlay
            if (importState.isProcessing ||
                importState.status == ImportStatus.completed ||
                importState.status == ImportStatus.error)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ImportProgressWidget(
                  state: importState,
                  onCancel: importNotifier.cancelImport,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
