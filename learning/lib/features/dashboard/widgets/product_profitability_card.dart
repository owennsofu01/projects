import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../products/controllers/product_profitability_controller.dart';
import '../../products/screens/product_profitability_screen.dart';

/// Dashboard entry point into the product profitability table: cost/profit
/// tied up across the whole catalog at a glance, tappable through to the
/// full per-product breakdown.
class ProductProfitabilityCard extends StatelessWidget {
  const ProductProfitabilityCard({super.key, required this.controller});

  final ProductProfitabilityController controller;

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

      if (controller.rows.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Add products to see cost and profit totals here.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }

      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.to(() => ProductProfitabilityScreen()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Product Profitability',
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
                Row(
                  children: [
                    _metric(
                      context,
                      'Total Cost',
                      controller.totalCost,
                      AppColors.expense,
                    ),
                    _metric(
                      context,
                      'Profit',
                      controller.totalProfit,
                      AppColors.profit,
                    ),
                    _metric(
                      context,
                      'Expected Profit',
                      controller.totalExpectedProfit,
                      AppColors.profit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _metric(BuildContext context, String label, double value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatter.currency(value),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: value >= 0 ? color : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}
