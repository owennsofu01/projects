import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../insights/controllers/insight_controller.dart';
import '../../insights/models/product_insight.dart';
import '../../insights/screens/stock_intelligence_screen.dart';
import '../../insights/widgets/recommendation_style.dart';

/// Dashboard entry point into the Stock Intelligence feature: a glanceable
/// count per recommendation category, tappable through to the full
/// breakdown with reasons.
class StockIntelligenceCard extends StatelessWidget {
  const StockIntelligenceCard({super.key, required this.controller});

  final InsightController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      if (controller.insights.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Add products and record sales to unlock stock '
              'recommendations here.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }

      final counts = {
        for (final type in StockRecommendation.values)
          type: controller.insights
              .where((i) => i.recommendation == type)
              .length,
      };

      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.to(() => StockIntelligenceScreen()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stock Intelligence',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in StockRecommendation.values)
                      if (counts[type]! > 0) _CountChip(type: type, count: counts[type]!),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.type, required this.count});

  final StockRecommendation type;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = recommendationStyles[type]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 6),
          Text(
            '${type.label}: $count',
            style: TextStyle(
              color: style.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
