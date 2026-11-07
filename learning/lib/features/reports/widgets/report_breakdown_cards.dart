import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/report_controller.dart';

/// Three small figures: number of sales, average sale and gross margin.
class ReportKpiRow extends StatelessWidget {
  const ReportKpiRow({super.key, required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final margin = controller.grossMargin;
    return Row(
      children: [
        Expanded(
          child: _Kpi(
            label: 'Transactions',
            value: Text('${controller.transactionCount}'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Kpi(
            label: 'Avg. sale',
            value: MoneyText(controller.averageSale),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Kpi(
            label: 'Gross margin',
            value: Text(margin == null ? '—' : '${margin.toStringAsFixed(1)}%'),
          ),
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.bodySmall, maxLines: 1),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle.merge(
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                child: value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expense totals per category as labelled horizontal bars.
class ExpenseCategoryCard extends StatelessWidget {
  const ExpenseCategoryCard({super.key, required this.controller});

  final ReportController controller;

  static const _palette = [
    AppColors.brandTeal,
    AppColors.brandGreen,
    AppColors.brandCyan,
    AppColors.warning,
    AppColors.brandCharcoal,
  ];
  static const _maxRows = 5;

  @override
  Widget build(BuildContext context) {
    final all = controller.expensesByCategory;
    final total = controller.totalExpenses;

    // Keep the list short: fold everything past the top rows into one.
    final rows = all.take(_maxRows - 1).toList();
    if (all.length > _maxRows - 1) {
      final rest = all.skip(_maxRows - 1);
      rows.add(
        rest.length == 1
            ? rest.first
            : MapEntry(
                '${rest.length} other categories',
                rest.fold(0.0, (sum, e) => sum + e.value),
              ),
      );
    }

    return _SectionCard(
      title: 'Expenses by category',
      child: rows.isEmpty
          ? const _Empty('No expenses in this period')
          : Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _BarRow(
                    label: rows[i].key,
                    amount: rows[i].value,
                    share: total == 0 ? 0 : rows[i].value / total,
                    color: _palette[i % _palette.length],
                  ),
              ],
            ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.amount,
    required this.share,
    required this.color,
  });

  final String label;
  final double amount;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${(share * 100).round()}%  ', style: textTheme.bodySmall),
              MoneyText(amount, style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          GrowIn(
            builder: (context, t) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: share * t,
                minHeight: 6,
                color: color,
                backgroundColor: track,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The best-selling products and services by revenue.
class TopItemsCard extends StatelessWidget {
  const TopItemsCard({super.key, required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.topItems.take(5).toList();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      title: 'Top sellers',
      child: items.isEmpty
          ? const _Empty('No sales in this period')
          : Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == 0
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: i == 0
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[i].name,
                                style: textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Obx(
                                () => Text(
                                  '${items[i].quantity} '
                                  '${items[i].isService ? 'jobs' : 'sold'}'
                                  '  ·  '
                                  '${AppFormatter.currency(items[i].profit)} '
                                  'profit',
                                  style: textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        MoneyText(
                          items[i].revenue,
                          style: textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
