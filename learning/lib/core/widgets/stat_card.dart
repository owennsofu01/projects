import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/formatters.dart';
import 'icon_badge.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final double value;
  final Color color;

  /// When set, the card shows this icon in a small [color] badge.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final valueText = Obx(
      () => Text(
        AppFormatter.currency(value),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: color,
        ),
      ),
    );

    if (icon == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              valueText,
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon!, color: color, size: 18),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: valueText),
          ],
        ),
      ),
    );
  }
}
