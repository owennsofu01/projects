import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/icon_badge.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/dashboard_controller.dart';
import '../services/dashboard_service.dart';

/// Two side-by-side cards — this week's sales and profit — each with the
/// change against last week and a 7-day sparkline.
class WeekTrendCards extends StatefulWidget {
  const WeekTrendCards({super.key, required this.controller});

  final DashboardController controller;

  @override
  State<WeekTrendCards> createState() => _WeekTrendCardsState();
}

class _WeekTrendCardsState extends State<WeekTrendCards> {
  late final Stream<List<DailySales>> _series =
      widget.controller.twoWeekSalesSeries;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DailySales>>(
      stream: _series,
      builder: (context, snap) {
        final days = snap.data ?? const <DailySales>[];
        // Oldest first: the first 7 days are last week, the rest this week.
        final split = days.length > 7 ? days.length - 7 : 0;
        final lastWeek = days.sublist(0, split);
        final thisWeek = days.sublist(split);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TrendCard(
                title: 'Week Sales',
                icon: Icons.point_of_sale_outlined,
                color: AppColors.brandTeal,
                current: [for (final d in thisWeek) d.amount],
                previous: [for (final d in lastWeek) d.amount],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TrendCard(
                title: 'Week Profit',
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.brandGreen,
                current: [for (final d in thisWeek) d.profit],
                previous: [for (final d in lastWeek) d.profit],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.current,
    required this.previous,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<double> current;
  final List<double> previous;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = current.fold(0.0, (a, b) => a + b);
    final previousTotal = previous.fold(0.0, (a, b) => a + b);
    final change = _percentChange(total, previousTotal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedAmount(
                total,
                style: textTheme.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            _ChangeLabel(change: change),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: RevealFromLeft(
                // Restart once data arrives, not while the line is empty.
                key: ValueKey(current.length),
                child: _Sparkline(values: current, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Null when there's no previous value to compare against.
  static double? _percentChange(double now, double before) {
    if (before == 0) return null;
    return (now - before) / before.abs() * 100;
  }
}

class _ChangeLabel extends StatelessWidget {
  const _ChangeLabel({required this.change});

  final double? change;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = change;

    if (value == null) {
      return Text('No data last week', style: textTheme.bodySmall);
    }

    final up = value >= 0;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${up ? '+' : ''}${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: up ? AppColors.income : AppColors.expense,
            ),
          ),
          const TextSpan(text: '  vs last week'),
        ],
      ),
      style: textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2,
            dotData: FlDotData(
              // Mark only today's point, like the reference design.
              checkToShowDot: (spot, _) => spot.x == values.length - 1,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3.5,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                strokeWidth: 2,
                strokeColor: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
