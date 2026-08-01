import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../controllers/dashboard_controller.dart';
import 'chart_card.dart';
import 'chart_empty_state.dart';

/// Qualitative palette distinct from the app's income/expense/profit
/// semantic colors (green/red/blue) — category slices here aren't
/// "good/bad", so reusing red for every slice would misleadingly imply
/// severity rather than just identity.
const _categoryPalette = [
  Color(0xFF4F46E5), // indigo
  Color(0xFFF59E0B), // amber
  Color(0xFF0EA5E9), // sky
  Color(0xFFA855F7), // purple
  Color(0xFF64748B), // slate ("Other")
];

class ExpenseBreakdownChart extends StatelessWidget {
  const ExpenseBreakdownChart({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Expense Breakdown',
      subtitle: 'This month, by category',
      child: StreamBuilder<Map<String, double>>(
        stream: controller.monthExpenseBreakdown,
        builder: (context, snapshot) {
          final data = snapshot.data;

          if (data == null) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final total = data.values.fold<double>(0, (a, b) => a + b);
          if (data.isEmpty || total <= 0) {
            return const ChartEmptyState(
              icon: Icons.pie_chart_outline_rounded,
              message: 'No expenses recorded this month',
            );
          }

          return _Donut(data: data, total: total);
        },
      ),
    );
  }
}

class _Slice {
  const _Slice(this.label, this.amount, this.color);
  final String label;
  final double amount;
  final Color color;
}

class _Donut extends StatelessWidget {
  const _Donut({required this.data, required this.total});

  final Map<String, double> data;
  final double total;

  static const _maxSlices = 4;

  List<_Slice> get _slices {
    final entries = data.entries.toList();
    final top = entries.take(_maxSlices).toList();
    final rest = entries.skip(_maxSlices);
    final otherTotal = rest.fold<double>(0, (a, e) => a + e.value);

    final slices = [
      for (var i = 0; i < top.length; i++)
        _Slice(top[i].key, top[i].value, _categoryPalette[i]),
    ];
    if (otherTotal > 0) {
      slices.add(_Slice('Other', otherTotal, _categoryPalette.last));
    }
    return slices;
  }

  @override
  Widget build(BuildContext context) {
    final slices = _slices;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 44,
                  sections: [
                    for (final slice in slices)
                      PieChartSectionData(
                        value: slice.amount,
                        color: slice.color,
                        radius: 26,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppFormatter.compactCurrency(total),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Total',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final slice in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: slice.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slice.label,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(slice.amount / total * 100).round()}%',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
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
