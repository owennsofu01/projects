import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../insights/controllers/insight_controller.dart';
import '../../insights/screens/stock_intelligence_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../controllers/dashboard_controller.dart';
import '../services/dashboard_service.dart';
import '../widgets/expense_breakdown_chart.dart';
import '../widgets/sales_trend_chart.dart';
import '../widgets/stock_intelligence_card.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.find<DashboardController>();
  final AuthController auth = Get.find<AuthController>();
  final InsightController insightController = Get.find<InsightController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Obx(() {
            final count = insightController.restockCount;
            return IconButton(
              onPressed: () => Get.to(() => StockIntelligenceScreen()),
              tooltip: 'Stock alerts',
              icon: Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
            );
          }),
          IconButton(
            onPressed: () => Get.to(() => SettingsScreen()),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: auth.logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Material's compact/medium/expanded breakpoints: below 600 is a
          // phone, so charts stay stacked; at/above it there's room to run
          // the two analytics cards side by side instead of one long
          // scrolling column.
          final isWide = constraints.maxWidth >= 700;
          final horizontalPadding = constraints.maxWidth >= 600 ? 24.0 : 16.0;

          return Center(
            child: ConstrainedBox(
              // Caps line length / card width on tablet, desktop and web so
              // content doesn't stretch edge-to-edge and become hard to scan.
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                children: [
                  const SectionHeader('Today'),
                  const SizedBox(height: 12),
                  _summaryRow(controller.todaySales, controller.todayExpenses),
                  const SizedBox(height: 24),
                  const SectionHeader('This Month'),
                  const SizedBox(height: 12),
                  _summaryRow(controller.monthSales, controller.monthExpenses),
                  const SizedBox(height: 24),
                  const SectionHeader('Analytics'),
                  const SizedBox(height: 12),
                  if (isWide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SalesTrendChart(controller: controller),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ExpenseBreakdownChart(
                              controller: controller,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    SalesTrendChart(controller: controller),
                    const SizedBox(height: 16),
                    ExpenseBreakdownChart(controller: controller),
                  ],
                  const SizedBox(height: 24),
                  const SectionHeader('Recommendations'),
                  const SizedBox(height: 12),
                  StockIntelligenceCard(controller: insightController),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _summaryRow(Stream<SalesSummary> sales, Stream<double> expenses) {
    return StreamBuilder<SalesSummary>(
      stream: sales,
      builder: (context, salesSnap) {
        final summary = salesSnap.data ?? SalesSummary.zero;

        return StreamBuilder<double>(
          stream: expenses,
          builder: (context, expenseSnap) {
            final expenseTotal = expenseSnap.data ?? 0.0;

            return Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Sales',
                    value: summary.totalAmount,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Expenses',
                    value: expenseTotal,
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Profit',
                    value: summary.totalProfit,
                    color: AppColors.profit,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
