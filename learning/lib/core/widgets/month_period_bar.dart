import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/formatters.dart';

/// Picks "All time" or one of the last 24 months, with previous/next
/// arrows. [selectedMonth] is the first day of the month, or null for
/// all time.
class MonthPeriodBar extends StatelessWidget {
  const MonthPeriodBar({
    super.key,
    required this.selectedMonth,
    required this.onSelected,
  });

  final Rxn<DateTime> selectedMonth;
  final ValueChanged<DateTime?> onSelected;

  static DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// The current month plus the 23 before it.
  List<DateTime> get _recentMonths {
    final current = _currentMonth;
    return [
      for (var i = 0; i < 24; i++) DateTime(current.year, current.month - i),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Obx(() {
        final month = selectedMonth.value;
        final canGoNext = month != null && month.isBefore(_currentMonth);
        return Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                final from = month ?? _currentMonth;
                onSelected(DateTime(from.year, from.month - 1));
              },
            ),
            Expanded(
              child: Center(
                child: PopupMenuButton<DateTime?>(
                  tooltip: 'Choose period',
                  initialValue: month,
                  onSelected: onSelected,
                  itemBuilder: (_) => [
                    const PopupMenuItem<DateTime?>(
                      value: null,
                      child: Text('All time'),
                    ),
                    const PopupMenuDivider(),
                    for (final m in _recentMonths)
                      PopupMenuItem<DateTime?>(
                        value: m,
                        child: Text(AppFormatter.month(m)),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          month == null
                              ? 'All time'
                              : AppFormatter.month(month),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoNext
                  ? () => onSelected(DateTime(month.year, month.month + 1))
                  : null,
            ),
          ],
        );
      }),
    );
  }
}
