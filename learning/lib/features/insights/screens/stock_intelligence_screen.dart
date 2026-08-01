import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/insight_controller.dart';
import '../models/product_insight.dart';
import '../widgets/recommendation_style.dart';

class StockIntelligenceScreen extends StatelessWidget {
  StockIntelligenceScreen({super.key});

  final InsightController controller = Get.find<InsightController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Intelligence')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.insights.isEmpty) {
          return const EmptyState(
            icon: Icons.insights_outlined,
            message: 'Add products and record sales to see recommendations',
          );
        }

        final grouped = <StockRecommendation, List<ProductInsight>>{
          for (final type in StockRecommendation.values)
            type: controller.insights
                .where((i) => i.recommendation == type)
                .toList(),
        };

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Based on sales activity over the last '
              '${InsightController.lookbackDays} days, across '
              '${controller.insights.length} products.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            for (final type in StockRecommendation.values)
              if (grouped[type]!.isNotEmpty) ...[
                _CategorySection(type: type, items: grouped[type]!),
                const SizedBox(height: 20),
              ],
          ],
        );
      }),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.type, required this.items});

  final StockRecommendation type;
  final List<ProductInsight> items;

  @override
  Widget build(BuildContext context) {
    final style = recommendationStyles[type]!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(style.icon, color: style.color, size: 20),
            const SizedBox(width: 8),
            Text(
              '${type.label} (${items.length})',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: style.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          type.description,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items) _InsightCard(item: item, style: style),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.item, required this.style});

  final ProductInsight item;
  final RecommendationStyle style;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.stock} in stock',
                    style: TextStyle(
                      color: style.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.reason, style: textTheme.bodySmall),
            const SizedBox(height: 10),
            Obx(
              () => Row(
                children: [
                  _stat(context, 'Sold', '${item.unitsSold}'),
                  const SizedBox(width: 16),
                  _stat(
                    context,
                    'Revenue',
                    AppFormatter.currency(item.revenue),
                  ),
                  const SizedBox(width: 16),
                  _stat(context, 'Profit', AppFormatter.currency(item.profit)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
