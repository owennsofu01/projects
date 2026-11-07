import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/money_text.dart';
import '../../expenses/models/expense_model.dart';
import '../../sales/models/sale_model.dart';

enum _Tab { sales, expenses }

/// Sales and expenses for the period in one card, switchable, showing the
/// most recent few with an option to see them all.
class ReportTransactions extends StatefulWidget {
  const ReportTransactions({
    super.key,
    required this.sales,
    required this.expenses,
  });

  final List<SaleModel> sales;
  final List<ExpenseModel> expenses;

  @override
  State<ReportTransactions> createState() => _ReportTransactionsState();
}

class _ReportTransactionsState extends State<ReportTransactions> {
  static const _preview = 8;

  _Tab _tab = _Tab.sales;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rows = _tab == _Tab.sales
        ? [for (final s in _sorted(widget.sales, (s) => s.date)) _saleRow(s)]
        : [
            for (final e in _sorted(widget.expenses, (e) => e.date))
              _expenseRow(e),
          ];
    final visible = _showAll ? rows : rows.take(_preview).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transactions', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_Tab>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _Tab.sales,
                label: Text('Sales ${widget.sales.length}'),
              ),
              ButtonSegment(
                value: _Tab.expenses,
                label: Text('Expenses ${widget.expenses.length}'),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() {
              _tab = s.first;
              _showAll = false;
            }),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _tab == _Tab.sales
                        ? 'No sales in this period'
                        : 'No expenses in this period',
                    style: textTheme.bodyMedium,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const Divider(indent: 16, endIndent: 16),
                      visible[i],
                    ],
                    if (rows.length > _preview) ...[
                      const Divider(),
                      TextButton(
                        onPressed: () => setState(() => _showAll = !_showAll),
                        child: Text(
                          _showAll ? 'Show less' : 'Show all ${rows.length}',
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  /// Newest first.
  List<T> _sorted<T>(List<T> items, DateTime Function(T) date) =>
      [...items]..sort((a, b) => date(b).compareTo(date(a)));

  Widget _saleRow(SaleModel sale) {
    return _Row(
      icon: sale.isService
          ? Icons.handyman_outlined
          : Icons.shopping_bag_outlined,
      color: AppColors.brandTeal,
      title: sale.productName,
      subtitle: Obx(
        () => Text(
          '${sale.quantity} × ${AppFormatter.currency(sale.sellingPrice)}'
          '  ·  ${AppFormatter.date(sale.date)}',
        ),
      ),
      amount: MoneyText(sale.totalAmount),
    );
  }

  Widget _expenseRow(ExpenseModel expense) {
    return _Row(
      icon: Icons.receipt_long_outlined,
      color: AppColors.expense,
      title: expense.title,
      subtitle: Text(
        '${expense.category.trim().isEmpty ? 'Other' : expense.category}'
        '  ·  ${AppFormatter.date(expense.date)}',
      ),
      amount: MoneyText(
        expense.amount,
        deduction: true,
        style: const TextStyle(color: AppColors.expense),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final IconData icon;
  final Color color;
  final String title;
  final Widget subtitle;
  final Widget amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: subtitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DefaultTextStyle.merge(style: textTheme.titleSmall, child: amount),
        ],
      ),
    );
  }
}
