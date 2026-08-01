import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/dashboard_controller.dart';
import '../services/dashboard_service.dart';
import 'chart_card.dart';
import 'chart_empty_state.dart';
import 'chart_legend.dart';

class SalesTrendChart extends StatelessWidget {
  const SalesTrendChart({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Sales vs Expenses',
      subtitle: 'Last 7 days',
      child: StreamBuilder<List<DailySales>>(
        stream: controller.weekSalesSeries,
        builder: (context, salesSnap) {
          return StreamBuilder<List<DailyExpense>>(
            stream: controller.weekExpenseSeries,
            builder: (context, expenseSnap) {
              final sales = salesSnap.data;
              final expenses = expenseSnap.data;

              if (sales == null || expenses == null) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final hasData =
                  sales.any((d) => d.amount > 0) ||
                  expenses.any((d) => d.amount > 0);

              if (!hasData) {
                return const ChartEmptyState(
                  icon: Icons.show_chart_rounded,
                  message: 'No sales or expenses yet this week',
                );
              }

              return _Chart(sales: sales, expenses: expenses);
            },
          );
        },
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.sales, required this.expenses});

  final List<DailySales> sales;
  final List<DailyExpense> expenses;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final maxY = [
      ...sales.map((d) => d.amount),
      ...expenses.map((d) => d.amount),
    ].fold<double>(0, (a, b) => a > b ? a : b);
    // Give the chart headroom above the tallest point and avoid a
    // degenerate 0..0 range when there's no data on one series.
    final chartMaxY = maxY <= 0 ? 1.0 : maxY * 1.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartLegend(
          items: [
            ChartLegendItem('Sales', AppColors.income),
            ChartLegendItem('Expenses', AppColors.expense),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: chartMaxY,
              gridData: FlGridData(
                horizontalInterval: chartMaxY / 4,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.inverseSurface,
                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                    final label = spot.barIndex == 0 ? 'Sales' : 'Expenses';
                    return LineTooltipItem(
                      '$label\n${AppFormatter.currency(spot.y)}',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
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
                    interval: chartMaxY / 4,
                    getTitlesWidget: (value, meta) => Text(
                      AppFormatter.compactCurrency(value),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                      if (index < 0 || index >= sales.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          AppFormatter.weekday(sales[index].day),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                _line(
                  values: sales.map((d) => d.amount).toList(),
                  color: AppColors.income,
                  withArea: true,
                ),
                _line(
                  values: expenses.map((d) => d.amount).toList(),
                  color: AppColors.expense,
                  withArea: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _line({
    required List<double> values,
    required Color color,
    required bool withArea,
  }) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: true,
      curveSmoothness: 0.25,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: withArea
          ? BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.0),
                ],
              ),
            )
          : BarAreaData(show: false),
    );
  }
}
