import 'package:flutter/material.dart';

class ChartLegendItem {
  const ChartLegendItem(this.label, this.color);

  final String label;
  final Color color;
}

/// A row of color-swatch + label pairs, used under chart titles so series
/// are identified by more than color alone (paired with distinct line
/// styles/positions in the chart itself).
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});

  final List<ChartLegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(item.label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}
