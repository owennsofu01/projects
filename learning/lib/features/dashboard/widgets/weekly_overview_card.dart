import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/dashboard_controller.dart';
import '../services/dashboard_service.dart';

enum _Period { week, year }

/// A solid brand-colored card with a simple sales bar chart, switchable
/// between the last 7 days and the last 12 months.
class WeeklyOverviewCard extends StatefulWidget {
  const WeeklyOverviewCard({super.key, required this.controller});

  final DashboardController controller;

  @override
  State<WeeklyOverviewCard> createState() => _WeeklyOverviewCardState();
}

class _WeeklyOverviewCardState extends State<WeeklyOverviewCard> {
  _Period _period = _Period.week;

  late final Stream<List<DailySales>> _week = widget.controller.weekSalesSeries;
  late final Stream<List<MonthlySales>> _year =
      widget.controller.yearSalesSeries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _period == _Period.week
                      ? 'Weekly Overview'
                      : 'Yearly Overview',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              _PeriodPicker(
                value: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: _period == _Period.week
                ? StreamBuilder<List<DailySales>>(
                    stream: _week,
                    builder: (context, snap) => _Bars(
                      values: [for (final d in snap.data ?? []) d.amount],
                      labels: [
                        for (final d in snap.data ?? <DailySales>[])
                          AppFormatter.weekday(d.day).substring(0, 1),
                      ],
                    ),
                  )
                : StreamBuilder<List<MonthlySales>>(
                    stream: _year,
                    builder: (context, snap) => _Bars(
                      values: [for (final m in snap.data ?? []) m.amount],
                      labels: [
                        for (final m in snap.data ?? <MonthlySales>[])
                          AppFormatter.shortMonth(m.month).substring(0, 1),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.value, required this.onChanged});

  final _Period value;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_Period>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: 'Change period',
      itemBuilder: (_) => const [
        PopupMenuItem(value: _Period.week, child: Text('Week')),
        PopupMenuItem(value: _Period.year, child: Text('Year')),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == _Period.week ? 'Week' : 'Year',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final textTheme = Theme.of(context).textTheme;

    if (values.isEmpty) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: onPrimary),
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final last = values.length - 1;

    return GrowIn(
      builder: (context, t) => BarChart(
        BarChartData(
          maxY: maxValue <= 0 ? 1 : maxValue * 1.1,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: textTheme.labelSmall?.copyWith(
                        color: onPrimary.withValues(alpha: i == last ? 1 : 0.7),
                        fontWeight: i == last ? FontWeight.w700 : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  Theme.of(context).colorScheme.inverseSurface,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                AppFormatter.compactCurrency(rod.toY),
                TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i] * t,
                    width: values.length > 7 ? 14 : 22,
                    // Current period is solid; earlier ones are muted.
                    color: onPrimary.withValues(alpha: i == last ? 1 : 0.35),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxValue <= 0 ? 1 : maxValue * 1.1,
                      color: onPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
