import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/product_profitability_controller.dart';
import '../models/product_profit_row.dart';

/// All products in one sortable table, with all-time units sold and profit
/// per product — the total-picture counterpart to the product cards, which
/// only show current stock and pricing.
class ProductProfitabilityScreen extends StatelessWidget {
  ProductProfitabilityScreen({super.key});

  final ProductProfitabilityController controller =
      Get.find<ProductProfitabilityController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Profitability')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.rows.isEmpty) {
          return const EmptyState(
            icon: Icons.table_chart_outlined,
            message: 'Add products to see their profitability here',
          );
        }

        return Column(
          children: [
            _PeriodBar(controller: controller),
            _FilterBar(controller: controller),
            _TotalsBar(controller: controller),
            Expanded(child: _buildTable()),
          ],
        );
      }),
    );
  }

  Widget _buildTable() {
    if (controller.isPeriodLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.visibleRows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EmptyState(
                icon: Icons.filter_alt_off_outlined,
                message: 'No products match these filters',
              ),
              if (controller.hasActiveFilters)
                TextButton(
                  onPressed: controller.clearFilters,
                  child: const Text('Clear filters'),
                ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Stock'), numeric: true),
            DataColumn(label: Text('Unit Cost'), numeric: true),
            DataColumn(label: Text('Total Cost'), numeric: true),
            DataColumn(label: Text('Selling'), numeric: true),
            DataColumn(label: Text('Sold'), numeric: true),
            DataColumn(label: Text('Profit'), numeric: true),
            DataColumn(label: Text('Expected Profit'), numeric: true),
          ],
          rows: [for (final row in controller.visibleRows) _buildRow(row)],
        ),
      ),
    );
  }

  DataRow _buildRow(ProductProfitRow row) {
    final isProfitable = row.profit >= 0;
    final isExpectedProfitable = row.expectedProfit >= 0;
    return DataRow(
      cells: [
        DataCell(Text(row.productName)),
        DataCell(Text(row.stock.toString())),
        DataCell(Text(AppFormatter.currency(row.costPrice))),
        DataCell(Text(AppFormatter.currency(row.totalCost))),
        DataCell(Text(AppFormatter.currency(row.sellingPrice))),
        DataCell(Text(row.unitsSold.toString())),
        DataCell(
          Text(
            AppFormatter.currency(row.profit),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isProfitable ? AppColors.profit : AppColors.expense,
            ),
          ),
        ),
        DataCell(
          Text(
            AppFormatter.currency(row.expectedProfit),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isExpectedProfitable
                  ? AppColors.profit
                  : AppColors.expense,
            ),
          ),
        ),
      ],
    );
  }
}

/// Switches the table between all-time and a single month's sales.
class _PeriodBar extends StatelessWidget {
  const _PeriodBar({required this.controller});

  final ProductProfitabilityController controller;

  /// The current month plus the 23 before it.
  List<DateTime> get _recentMonths {
    final now = DateTime.now();
    return [for (var i = 0; i < 24; i++) DateTime(now.year, now.month - i)];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Obx(() {
        final month = controller.selectedMonth.value;
        return Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
              onPressed: controller.previousMonth,
            ),
            Expanded(
              child: Center(
                child: PopupMenuButton<DateTime?>(
                  tooltip: 'Choose period',
                  initialValue: month,
                  onSelected: controller.selectMonth,
                  itemBuilder: (_) => [
                    const PopupMenuItem<DateTime?>(
                      value: null,
                      child: Text('All time'),
                    ),
                    const PopupMenuDivider(),
                    for (final m in _recentMonths)
                      PopupMenuItem<DateTime?>(
                        value: m,
                        child: Text(AppFormatter.month(m)),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          month == null
                              ? 'All time'
                              : AppFormatter.month(month),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
              onPressed: controller.canGoToNextMonth
                  ? controller.nextMonth
                  : null,
            ),
          ],
        );
      }),
    );
  }
}

/// Product name search plus a profit-status filter.
class _FilterBar extends StatefulWidget {
  const _FilterBar({required this.controller});

  final ProductProfitabilityController controller;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  late final TextEditingController _searchController = TextEditingController(
    text: widget.controller.searchQuery.value,
  );
  late final Worker _clearWorker;

  static const _labels = {
    ProfitFilter.all: 'All',
    ProfitFilter.profitable: 'Profitable',
    ProfitFilter.loss: 'Loss',
    ProfitFilter.notSold: 'Not sold',
  };

  @override
  void initState() {
    super.initState();
    // Keep the field in sync when filters are cleared from elsewhere.
    _clearWorker = ever(widget.controller.searchQuery, (query) {
      if (_searchController.text != query) _searchController.text = query;
    });
  }

  @override
  void dispose() {
    _clearWorker.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => widget.controller.searchQuery.value = value,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: Obx(
                () => widget.controller.searchQuery.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            widget.controller.searchQuery.value = '',
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  for (final filter in ProfitFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_labels[filter]!),
                        selected:
                            widget.controller.profitFilter.value == filter,
                        onSelected: (_) =>
                            widget.controller.profitFilter.value = filter,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.controller});

  final ProductProfitabilityController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Obx(
        () => Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 20,
          runSpacing: 16,
          children: [
            _stat(
              context,
              'Products',
              controller.visibleRows.length.toString(),
            ),
            _stat(
              context,
              'Units Sold',
              controller.visibleUnitsSold.toString(),
            ),
            _stat(
              context,
              controller.selectedMonth.value == null
                  ? 'Total Profit'
                  : '${AppFormatter.month(controller.selectedMonth.value!)} Profit',
              AppFormatter.currency(controller.visibleProfit),
              valueColor: controller.visibleProfit >= 0
                  ? AppColors.profit
                  : AppColors.expense,
            ),
            _stat(
              context,
              'Stock Cost',
              AppFormatter.currency(controller.visibleCost),
            ),
            _stat(
              context,
              'Expected Profit',
              AppFormatter.currency(controller.visibleExpectedProfit),
              valueColor: controller.visibleExpectedProfit >= 0
                  ? AppColors.profit
                  : AppColors.expense,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
