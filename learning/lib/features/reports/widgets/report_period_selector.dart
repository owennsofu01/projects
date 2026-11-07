import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../models/report_range.dart';

/// Today / Week / Month / Custom picker, with the exact dates underneath.
class ReportPeriodSelector extends StatelessWidget {
  const ReportPeriodSelector({
    super.key,
    required this.range,
    required this.onChanged,
  });

  final ReportRange range;
  final ValueChanged<ReportRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lastDay = range.end.subtract(const Duration(days: 1));
    final sameDay = DateUtils.isSameDay(range.start, lastDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ReportPreset>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ReportPreset.today, label: Text('Today')),
              ButtonSegment(value: ReportPreset.thisWeek, label: Text('Week')),
              ButtonSegment(
                value: ReportPreset.thisMonth,
                label: Text('Month'),
              ),
              ButtonSegment(value: ReportPreset.custom, label: Text('Custom')),
            ],
            selected: {range.preset},
            onSelectionChanged: (s) => _select(context, s.first),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                sameDay
                    ? AppFormatter.date(range.start)
                    : '${AppFormatter.date(range.start)} – '
                          '${AppFormatter.date(lastDay)}',
                style: textTheme.bodySmall,
              ),
            ),
            if (range.preset == ReportPreset.custom)
              GestureDetector(
                onTap: () => _pickCustom(context),
                child: Text(
                  'Change',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _select(BuildContext context, ReportPreset preset) {
    switch (preset) {
      case ReportPreset.today:
        onChanged(ReportRange.today());
      case ReportPreset.thisWeek:
        onChanged(ReportRange.thisWeek());
      case ReportPreset.thisMonth:
        onChanged(ReportRange.thisMonth());
      case ReportPreset.custom:
        _pickCustom(context);
    }
  }

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: range.preset == ReportPreset.custom
          ? DateTimeRange(
              start: range.start,
              end: range.end.subtract(const Duration(days: 1)),
            )
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
    );
    if (picked == null) return;
    onChanged(ReportRange.custom(picked.start, picked.end));
  }
}
