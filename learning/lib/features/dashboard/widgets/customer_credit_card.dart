import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../customers/controllers/customer_controller.dart';
import '../../customers/screens/customer_list_screen.dart';

/// Dashboard entry point into the debtors book: total credit outstanding,
/// tappable through to the customers who owe it.
class CustomerCreditCard extends StatelessWidget {
  const CustomerCreditCard({super.key, required this.controller});

  final CustomerController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final debtors = controller.debtors;
      final owed = controller.totalOwed;

      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              Get.to(() => CustomerListScreen(onlyDebtors: debtors.isNotEmpty)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.people_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Owed to you',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        debtors.isEmpty
                            ? 'No outstanding customer credit'
                            : '${debtors.length} customer'
                                  '${debtors.length == 1 ? '' : 's'} · top: '
                                  '${debtors.first.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppFormatter.currency(owed),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: debtors.isEmpty ? null : AppColors.expense,
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
