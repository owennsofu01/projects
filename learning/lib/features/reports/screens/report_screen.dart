import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../expenses/models/expense_model.dart';
import '../../sales/models/sale_model.dart';
import '../controllers/report_controller.dart';
import '../models/report_range.dart';

class ReportScreen extends StatelessWidget {
  ReportScreen({super.key});

  final ReportController controller = Get.find<ReportController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          Obx(
            () => IconButton(
              onPressed: controller.isExporting.value
                  ? null
                  : controller.exportToExcel,
              tooltip: 'Export to Excel',
              icon: controller.isExporting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadReport,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _rangeSelector(context),
              const SizedBox(height: 24),
              const SectionHeader('Summary'),
              const SizedBox(height: 12),
              _summaryCards(),
              const SizedBox(height: 24),
              SectionHeader('Sales (${controller.sales.length})'),
              const SizedBox(height: 12),
              if (controller.sales.isEmpty)
                _emptyHint('No sales in this period')
              else
                ...controller.sales.map(_saleTile),
              const SizedBox(height: 24),
              SectionHeader('Expenses (${controller.expenses.length})'),
              const SizedBox(height: 12),
              if (controller.expenses.isEmpty)
                _emptyHint('No expenses in this period')
              else
                ...controller.expenses.map(_expenseTile),
              const SizedBox(height: 24),
            ],
          );
        }),
      ),
    );
  }

  Widget _rangeSelector(BuildContext context) {
    return Obx(() {
      final selected = controller.range.value;

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _rangeChip(
            label: 'Today',
            selected: selected.preset == ReportPreset.today,
            onSelected: () => controller.setRange(ReportRange.today()),
          ),
          _rangeChip(
            label: 'This Week',
            selected: selected.preset == ReportPreset.thisWeek,
            onSelected: () => controller.setRange(ReportRange.thisWeek()),
          ),
          _rangeChip(
            label: 'This Month',
            selected: selected.preset == ReportPreset.thisMonth,
            onSelected: () => controller.setRange(ReportRange.thisMonth()),
          ),
          _rangeChip(
            label: selected.preset == ReportPreset.custom
                ? '${AppFormatter.date(selected.start)} – '
                      '${AppFormatter.date(selected.end.subtract(const Duration(days: 1)))}'
                : 'Custom',
            selected: selected.preset == ReportPreset.custom,
            onSelected: () => _pickCustomRange(context),
          ),
        ],
      );
    });
  }

  Widget _rangeChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
    );
    if (picked == null) return;
    await controller.setRange(ReportRange.custom(picked.start, picked.end));
  }

  Widget _summaryCards() {
    return Obx(
      () => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Sales',
                  value: controller.totalSales,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Expenses',
                  value: controller.totalExpenses,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Profit',
                  value: controller.totalProfit,
                  color: AppColors.profit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Net',
                  value: controller.netProfit,
                  color: AppColors.profit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _saleTile(SaleModel sale) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.point_of_sale),
          title: Text(sale.productName),
          subtitle: Obx(
            () => Text(
              '${sale.quantity} × ${AppFormatter.currency(sale.sellingPrice)}'
              '  •  ${AppFormatter.date(sale.date)}',
            ),
          ),
          trailing: Obx(
            () => Text(
              AppFormatter.currency(sale.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _expenseTile(ExpenseModel expense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.money_off),
          title: Text(expense.title),
          subtitle: Text(
            '${expense.category}  •  ${AppFormatter.date(expense.date)}',
          ),
          trailing: Obx(
            () => Text(
              AppFormatter.currency(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.expense,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyHint(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}
