import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/dashboard_controller.dart';
import '../services/dashboard_service.dart';
import 'chart_card.dart';
import 'chart_empty_state.dart';
import 'chart_legend.dart';

/// Net profit (gross profit from sales minus expenses) per month over the
/// last 12 months — the long-range counterpart to [SalesTrendChart].
class MonthlyProfitChart extends StatefulWidget {
  const MonthlyProfitChart({super.key, required this.controller});

  final DashboardController controller;

  @override
  State<MonthlyProfitChart> createState() => _MonthlyProfitChartState();
}

class _MonthlyProfitChartState extends State<MonthlyProfitChart> {
  // Created once so parent rebuilds don't resubscribe to Firestore.
  late final Stream<List<MonthlySales>> _sales =
      widget.controller.yearSalesSeries;
  late final Stream<List<double>> _expenses =
      widget.controller.yearExpenseSeries;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Monthly Net Profit',
      subtitle: 'Last 12 months · profit minus expenses',
      child: StreamBuilder<List<MonthlySales>>(
        stream: _sales,
        builder: (context, salesSnap) {
          return StreamBuilder<List<double>>(
            stream: _expenses,
            builder: (context, expenseSnap) {
              final sales = salesSnap.data;
              final expenses = expenseSnap.data;

              if (sales == null || expenses == null) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final months = [
                for (var i = 0; i < sales.length; i++)
                  _MonthNet(sales: sales[i], expenses: expenses[i]),
              ];

              if (months.every((m) => m.sales.amount == 0 && m.expenses == 0)) {
                return const ChartEmptyState(
                  icon: Icons.bar_chart_rounded,
                  message: 'No sales or expenses in the last 12 months',
                );
              }

              return _Chart(months: months);
            },
          );
        },
      ),
    );
  }
}

class _MonthNet {
  const _MonthNet({required this.sales, required this.expenses});

  final MonthlySales sales;
  final double expenses;

  double get net => sales.profit - expenses;
}

class _Chart extends StatelessWidget {
  const _Chart({required this.months});

  final List<_MonthNet> months;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final nets = months.map((m) => m.net);
    final maxNet = nets.fold<double>(0, (a, b) => a > b ? a : b);
    final minNet = nets.fold<double>(0, (a, b) => a < b ? a : b);
    // Headroom above/below the extremes; avoid a degenerate 0..0 range.
    final chartMaxY = maxNet <= 0 ? (minNet < 0 ? 0.0 : 1.0) : maxNet * 1.2;
    final chartMinY = minNet < 0 ? minNet * 1.2 : 0.0;
    final interval = (chartMaxY - chartMinY) / 4;

    final yearNet = nets.fold<double>(0, (a, b) => a + b);
    final thisMonthNet = months.last.net;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _figure(context, 'This month', thisMonthNet),
            _figure(context, '12-month total', yearNet),
          ],
        ),
        const SizedBox(height: 12),
        ChartLegend(
          items: [
            ChartLegendItem('Net profit', AppColors.income),
            ChartLegendItem('Net loss', AppColors.expense),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // On narrow phones, label every other month so the
              // three-letter names don't collide.
              final labelEvery = constraints.maxWidth / months.length < 30
                  ? 2
                  : 1;

              return BarChart(
                BarChartData(
                  minY: chartMinY,
                  maxY: chartMaxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    horizontalInterval: interval,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: colorScheme.outline,
                        strokeWidth: 1,
                      ),
                    ],
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colorScheme.inverseSurface,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final m = months[group.x];
                        return BarTooltipItem(
                          '${AppFormatter.month(m.sales.month)}\n',
                          TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.left,
                          children: [
                            TextSpan(
                              text:
                                  'Sales ${AppFormatter.currency(m.sales.amount)}\n'
                                  'Gross profit ${AppFormatter.currency(m.sales.profit)}\n'
                                  'Expenses ${AppFormatter.currency(m.expenses)}\n'
                                  'Net ${AppFormatter.currency(m.net)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: interval,
                        getTitlesWidget: (value, meta) => Text(
                          AppFormatter.compactCurrency(value),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          // Count back from the current month so it is
                          // always labelled.
                          final fromEnd = months.length - 1 - index;
                          if (index < 0 ||
                              index >= months.length ||
                              fromEnd % labelEvery != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              AppFormatter.shortMonth(
                                months[index].sales.month,
                              ),
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < months.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [_rod(months[i].net, constraints.maxWidth)],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  BarChartRodData _rod(double net, double chartWidth) {
    final isLoss = net < 0;
    const radius = Radius.circular(4);
    return BarChartRodData(
      fromY: 0,
      toY: net,
      color: isLoss ? AppColors.expense : AppColors.income,
      width: (chartWidth / months.length * 0.5).clamp(6, 22),
      borderRadius: isLoss
          ? const BorderRadius.vertical(bottom: radius)
          : const BorderRadius.vertical(top: radius),
    );
  }

  Widget _figure(BuildContext context, String label, double value) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppFormatter.currency(value),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: value < 0 ? AppColors.expense : AppColors.income,
          ),
        ),
      ],
    );
  }
}
