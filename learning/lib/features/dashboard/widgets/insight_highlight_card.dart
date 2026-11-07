import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../insights/controllers/insight_controller.dart';
import '../../insights/models/product_insight.dart';
import '../../insights/screens/stock_intelligence_screen.dart';

/// A dark callout that surfaces the single most useful stock insight,
/// tappable through to the full Stock Intelligence screen.
class InsightHighlightCard extends StatelessWidget {
  const InsightHighlightCard({super.key, required this.controller});

  final InsightController controller;

  // Most urgent first.
  static const _priority = [
    StockRecommendation.restock,
    StockRecommendation.reduce,
    StockRecommendation.promote,
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final insights = controller.insights;
      final (headline, detail) = _message(insights);

      return _DarkCard(
        onTap: insights.isEmpty
            ? null
            : () => Get.to(() => StockIntelligenceScreen()),
        headline: headline,
        detail: detail,
      );
    });
  }

  (String, String) _message(List<ProductInsight> insights) {
    if (controller.isLoading.value) {
      return ('Analysing your stock…', 'This only takes a moment.');
    }
    if (insights.isEmpty) {
      return (
        'Insights appear as you sell.',
        'Add products and record sales to get stock advice.',
      );
    }
    for (final type in _priority) {
      final matches = insights.where((i) => i.recommendation == type).toList();
      if (matches.isEmpty) continue;
      final n = matches.length;
      final noun = n == 1 ? 'product' : 'products';
      final headline = switch (type) {
        StockRecommendation.restock => '$n $noun need restocking soon.',
        StockRecommendation.reduce => '$n $noun are moving slowly.',
        _ => '$n top $noun worth promoting.',
      };
      final first = matches.first;
      return (headline, '${first.productName}: ${first.reason}');
    }
    return ('All stock looks healthy.', 'No action needed right now.');
  }
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({
    required this.headline,
    required this.detail,
    required this.onTap,
  });

  final String headline;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF23272D) : AppColors.ink;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_outlined,
                            size: 13,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock insight',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headline,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.brandGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
