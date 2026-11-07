import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/motion.dart';
import '../controllers/report_controller.dart';
import '../widgets/profit_loss_card.dart';
import '../widgets/report_breakdown_cards.dart';
import '../widgets/report_period_selector.dart';
import '../widgets/report_transactions.dart';

class ReportScreen extends StatelessWidget {
  ReportScreen({super.key});

  final ReportController controller = Get.find<ReportController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Obx(() {
              final busy = controller.isExporting.value;
              return TextButton.icon(
                onPressed: busy ? null : controller.exportToExcel,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share, size: 18),
                label: const Text('Export'),
              );
            }),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadReport,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = constraints.maxWidth >= 600 ? 24.0 : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Obx(() {
                  final loading = controller.isLoading.value;
                  final empty =
                      controller.sales.isEmpty && controller.expenses.isEmpty;

                  // Each section fades in one after another.
                  var step = 0;
                  Widget section(Widget child) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 60 * step++),
                      child: child,
                    ),
                  );

                  return ListView(
                    padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
                    children: [
                      ReportPeriodSelector(
                        range: controller.range.value,
                        onChanged: controller.setRange,
                      ),
                      const SizedBox(height: 16),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (empty)
                        section(const _EmptyPeriod())
                      else ...[
                        section(ProfitLossCard(controller: controller)),
                        section(ReportKpiRow(controller: controller)),
                        section(TopItemsCard(controller: controller)),
                        section(ExpenseCategoryCard(controller: controller)),
                        const SizedBox(height: 8),
                        section(
                          ReportTransactions(
                            sales: controller.sales.toList(),
                            expenses: controller.expenses.toList(),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insert_chart_outlined,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text('No activity in this period', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Sales and expenses you record will be summarised here.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
