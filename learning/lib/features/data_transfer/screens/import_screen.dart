import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../controllers/data_transfer_controller.dart';
import '../models/import_rows.dart';

/// Pick an .xlsx, check what was read from it, then import.
class ImportScreen extends StatelessWidget {
  ImportScreen({super.key});

  final DataTransferController controller = Get.find<DataTransferController>();

  Future<void> _import() async {
    final result = await controller.confirmImport();
    if (result == null) return;

    Get.back();
    final added = [
      if (result.productsAdded > 0)
        '${result.productsAdded} product${result.productsAdded == 1 ? '' : 's'}',
      if (result.expensesAdded > 0)
        '${result.expensesAdded} expense${result.expensesAdded == 1 ? '' : 's'}',
    ];
    final skipped = result.productsSkipped + result.expensesSkipped;
    final skippedText = skipped == 0
        ? ''
        : ' $skipped already in the app ${skipped == 1 ? 'was' : 'were'} '
              'skipped.';

    if (added.isEmpty) {
      showWarningSnackbar('Nothing new to import', skippedText.trim());
    } else {
      showSuccessSnackbar('Imported ${added.join(' and ')}.$skippedText');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      onPopInvokedWithResult: (_, _) => controller.clearFile(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Import from Excel')),
        body: Obx(() {
          final preview = controller.preview.value;
          final busy = controller.isBusy.value;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Add products and expenses from an Excel file (.xlsx) with a '
                '"Products" and/or "Expenses" sheet. Products already in the '
                'app (same name) and expenses already recorded are skipped.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: busy ? null : controller.shareTemplate,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Get the template'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : controller.pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  preview == null ? 'Choose file' : 'Choose a different file',
                ),
              ),
              if (busy && preview == null) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              if (preview != null) ...[
                const SizedBox(height: 24),
                Text(
                  controller.fileName.value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _PreviewSummary(preview: preview),
                if (preview.problems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Problems(problems: preview.problems),
                ],
                const SizedBox(height: 24),
                AppPrimaryButton(
                  label: 'IMPORT',
                  isLoading: busy,
                  onPressed: preview.isEmpty ? null : _import,
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.preview});

  final ImportPreview preview;

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String label, int count) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        '$count',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            row(
              Icons.inventory_2_outlined,
              'Products read',
              preview.products.length,
            ),
            row(
              Icons.receipt_long_outlined,
              'Expenses read',
              preview.expenses.length,
            ),
          ],
        ),
      ),
    );
  }
}

class _Problems extends StatelessWidget {
  const _Problems({required this.problems});

  final List<String> problems;

  static const _shown = 20;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${problems.length} row${problems.length == 1 ? '' : 's'} '
                    'will be left out',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final problem in problems.take(_shown))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $problem', style: textTheme.bodySmall),
              ),
            if (problems.length > _shown)
              Text(
                '…and ${problems.length - _shown} more',
                style: textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
