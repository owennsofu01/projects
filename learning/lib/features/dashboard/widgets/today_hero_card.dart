import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/dashboard_controller.dart';
import '../services/dashboard_service.dart';

/// The headline card: today's profit in large type on a tinted panel, with
/// today's sales and expenses underneath.
class TodayHeroCard extends StatefulWidget {
  const TodayHeroCard({super.key, required this.controller});

  final DashboardController controller;

  @override
  State<TodayHeroCard> createState() => _TodayHeroCardState();
}

class _TodayHeroCardState extends State<TodayHeroCard> {
  late final Stream<SalesSummary> _sales = widget.controller.todaySales;
  late final Stream<double> _expenses = widget.controller.todayExpenses;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<SalesSummary>(
      stream: _sales,
      builder: (context, salesSnap) {
        final summary = salesSnap.data ?? SalesSummary.zero;
        return StreamBuilder<double>(
          stream: _expenses,
          builder: (context, expenseSnap) {
            final expenses = expenseSnap.data ?? 0;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Profit",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedAmount(
                                    summary.totalProfit,
                                    style: textTheme.headlineMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.savings_outlined,
                              size: 32,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
                      child: Obx(
                        () => Text(
                          'Sales ${AppFormatter.currency(summary.totalAmount)}'
                          '  ·  '
                          'Expenses ${AppFormatter.currency(expenses)}',
                          style: textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
