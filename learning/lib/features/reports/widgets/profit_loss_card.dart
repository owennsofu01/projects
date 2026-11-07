import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/report_controller.dart';

/// Headline net profit with its margin, followed by a compact profit &
/// loss statement for the period.
class ProfitLossCard extends StatelessWidget {
  const ProfitLossCard({super.key, required this.controller});

  final ReportController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final net = controller.netProfit;
    final netColor = net >= 0 ? AppColors.income : AppColors.expense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Net profit', style: textTheme.bodyMedium),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedAmount(
                      net,
                      style: textTheme.headlineMedium?.copyWith(
                        color: netColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                if (controller.netMargin != null)
                  _MarginPill(margin: controller.netMargin!, color: netColor),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'PROFIT & LOSS',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _Line('Revenue', controller.totalSales),
            _Line('Cost of sales', controller.costOfSales, deduction: true),
            const Divider(height: 16),
            _Line(
              'Gross profit',
              controller.totalProfit,
              emphasis: true,
              note: controller.grossMargin == null
                  ? null
                  : '${controller.grossMargin!.toStringAsFixed(1)}% margin',
            ),
            _Line(
              'Operating expenses',
              controller.totalExpenses,
              deduction: true,
            ),
            const Divider(height: 16),
            _Line('Net profit', net, emphasis: true, color: netColor),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(
    this.label,
    this.amount, {
    this.deduction = false,
    this.emphasis = false,
    this.note,
    this.color,
  });

  final String label;
  final double amount;
  final bool deduction;
  final bool emphasis;
  final String? note;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasis
        ? textTheme.titleSmall?.copyWith(color: color)
        : textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (note != null)
                    TextSpan(
                      text: '  $note',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              style: emphasis ? textTheme.titleSmall : textTheme.bodyMedium,
            ),
          ),
          MoneyText(amount, deduction: deduction && amount != 0, style: style),
        ],
      ),
    );
  }
}

class _MarginPill extends StatelessWidget {
  const _MarginPill({required this.margin, required this.color});

  final double margin;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${margin.toStringAsFixed(1)}% margin',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
