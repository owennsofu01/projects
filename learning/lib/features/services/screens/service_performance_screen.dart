import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/month_period_bar.dart';
import '../controllers/service_performance_controller.dart';

/// Jobs, revenue and profit per service, for one month or all time.
class ServicePerformanceScreen extends StatelessWidget {
  ServicePerformanceScreen({super.key});

  final ServicePerformanceController controller =
      Get.find<ServicePerformanceController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Performance')),
      body: Column(
        children: [
          MonthPeriodBar(
            selectedMonth: controller.selectedMonth,
            onSelected: controller.selectMonth,
          ),
          _TotalsBar(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.rows.isEmpty) {
                return const EmptyState(
                  icon: Icons.content_cut,
                  message: 'Add services to see how they perform here',
                );
              }
              return _buildTable();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Service')),
            DataColumn(label: Text('Jobs'), numeric: true),
            DataColumn(label: Text('Revenue'), numeric: true),
            DataColumn(label: Text('Avg price'), numeric: true),
            DataColumn(label: Text('Materials'), numeric: true),
            DataColumn(label: Text('Profit'), numeric: true),
          ],
          rows: [
            for (final row in controller.rows)
              DataRow(
                cells: [
                  DataCell(
                    Text(row.isCurrent ? row.name : '${row.name} (deleted)'),
                  ),
                  DataCell(Text(row.jobs.toString())),
                  DataCell(Text(AppFormatter.currency(row.revenue))),
                  DataCell(Text(AppFormatter.currency(row.averagePrice))),
                  DataCell(Text(AppFormatter.currency(row.cost))),
                  DataCell(
                    Text(
                      AppFormatter.currency(row.profit),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: row.profit >= 0
                            ? AppColors.profit
                            : AppColors.expense,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.controller});

  final ServicePerformanceController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget stat(String label, String value, {Color? color}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainerHighest,
      child: Obx(
        () => Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 20,
          runSpacing: 16,
          children: [
            stat('Jobs', controller.totalJobs.toString()),
            stat('Revenue', AppFormatter.currency(controller.totalRevenue)),
            stat(
              'Profit',
              AppFormatter.currency(controller.totalProfit),
              color: controller.totalProfit >= 0
                  ? AppColors.profit
                  : AppColors.expense,
            ),
          ],
        ),
      ),
    );
  }
}
