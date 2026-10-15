import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../budgets/controllers/budget_controller.dart';
import '../../budgets/models/budget_model.dart';
import '../../budgets/screens/budget_screen.dart';

/// Dashboard entry point into budgets: how many categories are close to
/// or over their monthly limit, tappable through to the full list.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.controller});

  final BudgetController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final statuses = controller.statuses;
      final over = statuses.where((s) => s.level == BudgetLevel.over).toList();
      final near = statuses.where((s) => s.level == BudgetLevel.near).toList();

      final String subtitle;
      final Color? accent;
      if (statuses.isEmpty) {
        subtitle = 'Set monthly limits for expense categories';
        accent = null;
      } else if (over.isNotEmpty) {
        subtitle = over.length == 1
            ? '${over.first.budget.category} is over its limit'
            : '${over.length} categories over their limit';
        accent = AppColors.expense;
      } else if (near.isNotEmpty) {
        subtitle = near.length == 1
            ? '${near.first.budget.category} is nearly used up'
            : '${near.length} categories nearly used up';
        accent = AppColors.warning;
      } else {
        subtitle =
            'All ${statuses.length} budget${statuses.length == 1 ? '' : 's'} '
            'on track this month';
        accent = AppColors.income;
      }

      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.to(() => BudgetScreen()),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.savings_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budgets',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: accent ?? colorScheme.onSurfaceVariant,
                          fontWeight: over.isEmpty && near.isEmpty
                              ? null
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    });
  }
}
