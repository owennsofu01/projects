import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Max content width for list screens, so rows don't stretch on tablets.
const kListMaxWidth = 720.0;

/// One titled group of rows in a list.
class ListSection {
  const ListSection({this.title, this.trailing, required this.rows});

  final String? title;

  /// Shown on the right of the title, e.g. the day's total.
  final Widget? trailing;
  final List<Widget> rows;
}

/// The standard list screen body: optional [header] widgets, then each
/// section as one card of rows separated by hairlines. Sections are built
/// lazily, and there's room at the bottom for a floating button.
class GroupedListView extends StatelessWidget {
  const GroupedListView({
    super.key,
    required this.sections,
    this.header = const [],
  });

  final List<ListSection> sections;
  final List<Widget> header;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kListMaxWidth),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: header.length + sections.length,
          itemBuilder: (context, i) {
            if (i < header.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: header[i],
              );
            }
            return _SectionView(section: sections[i - header.length]);
          },
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section});

  final ListSection section;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rows = section.rows;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (section.title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      section.title!.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (section.trailing != null)
                    DefaultTextStyle.merge(
                      style: textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      child: section.trailing!,
                    ),
                ],
              ),
            ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(indent: 68),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Splits [items] (already newest first) into one group per calendar day.
List<(DateTime, List<T>)> groupByDay<T>(
  List<T> items,
  DateTime Function(T) dateOf,
) {
  final groups = <(DateTime, List<T>)>[];
  for (final item in items) {
    final d = dateOf(item);
    final day = DateTime(d.year, d.month, d.day);
    if (groups.isEmpty || groups.last.$1 != day) {
      groups.add((day, [item]));
    } else {
      groups.last.$2.add(item);
    }
  }
  return groups;
}

/// "Today", "Yesterday", or e.g. "Tue · 4 Nov 2026".
String dayLabel(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${AppFormatter.weekday(day)} · ${AppFormatter.date(day)}';
}
