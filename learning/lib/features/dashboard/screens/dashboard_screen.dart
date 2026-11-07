import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../budgets/controllers/budget_controller.dart';
import '../../customers/controllers/customer_controller.dart';
import '../../insights/controllers/insight_controller.dart';
import '../../products/controllers/product_profitability_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../services/dashboard_service.dart';
import '../widgets/budget_card.dart';
import '../widgets/customer_credit_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/expense_breakdown_chart.dart';
import '../widgets/insight_highlight_card.dart';
import '../widgets/monthly_profit_chart.dart';
import '../widgets/product_profitability_card.dart';
import '../widgets/sales_trend_chart.dart';
import '../widgets/stock_intelligence_card.dart';
import '../widgets/today_hero_card.dart';
import '../widgets/week_trend_cards.dart';
import '../widgets/weekly_overview_card.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.find<DashboardController>();
  final InsightController insightController = Get.find<InsightController>();
  final CustomerController customerController = Get.find<CustomerController>();
  final BudgetController budgetController = Get.find<BudgetController>();
  final ProductProfitabilityController profitabilityController =
      Get.find<ProductProfitabilityController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  MediaQuery.paddingOf(context).top + 16,
                  horizontalPadding,
                  24,
                ),
                children: [
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 0),
                    child: DashboardHeader(
                      insightController: insightController,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 70),
                    child: TodayHeroCard(controller: controller),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: WeekTrendCards(controller: controller),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 210),
                    child: InsightHighlightCard(controller: insightController),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 280),
                    child: WeeklyOverviewCard(controller: controller),
                  ),
                  const SizedBox(height: 28),
                  const SectionHeader('This Month'),
                  const SizedBox(height: 12),
                  _summaryRow(controller.monthSales, controller.monthExpenses),
                  const SizedBox(height: 24),
                  const SectionHeader('Inventory, Credit & Budgets'),
                  const SizedBox(height: 12),
                  ProductProfitabilityCard(controller: profitabilityController),
                  const SizedBox(height: 12),
                  CustomerCreditCard(controller: customerController),
                  const SizedBox(height: 12),
                  BudgetCard(controller: budgetController),
                  const SizedBox(height: 24),
                  const SectionHeader('Analytics'),
                  const SizedBox(height: 12),
                  MonthlyProfitChart(controller: controller),
                  const SizedBox(height: 16),
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
                    icon: Icons.trending_up_rounded,
                    value: summary.totalAmount,
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Expenses',
                    icon: Icons.receipt_long_outlined,
                    value: expenseTotal,
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Profit',
                    icon: Icons.account_balance_wallet_outlined,
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
