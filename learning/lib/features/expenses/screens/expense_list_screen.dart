import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/add_fab.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/list_row.dart';
import '../../../core/widgets/money_text.dart';
import '../../budgets/controllers/budget_controller.dart';
import '../../budgets/screens/budget_screen.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final ExpenseController controller = Get.find<ExpenseController>();
  final BudgetController budgetController = Get.find<BudgetController>();

  late final Stream<List<ExpenseModel>> _expenses = controller.expensesStream;

  void _add() => Get.to(() => const AddExpenseScreen());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          Obx(() {
            final count = budgetController.needingAttention.length;
            return IconButton(
              onPressed: () => Get.to(() => BudgetScreen()),
              tooltip: 'Budgets',
              icon: Badge(
                label: Text('$count'),
                isLabelVisible: count > 0,
                child: const Icon(Icons.savings_outlined),
              ),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: AddFab(
        heroTag: 'expenses-fab',
        label: 'Add expense',
        onPressed: _add,
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expenses,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;
          if (expenses.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              message:
                  'Record rent, stock transport and other costs to see '
                  'your true profit.',
              actionLabel: 'Add expense',
              onAction: _add,
            );
          }

          return GroupedListView(
            sections: [
              for (final (day, items) in groupByDay(expenses, (e) => e.date))
                ListSection(
                  title: dayLabel(day),
                  trailing: MoneyText(
                    items.fold(0.0, (sum, e) => sum + e.amount),
                    deduction: true,
                  ),
                  rows: [for (final e in items) _row(e)],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(ExpenseModel expense) {
    final category = expense.category.trim();
    return ListRow(
      leading: const RowIcon(
        Icons.receipt_long_outlined,
        color: AppColors.expense,
      ),
      title: expense.title,
      subtitle: category.isEmpty ? 'Other' : category,
      trailing: RowAmount(
        expense.amount,
        prefix: '−',
        color: AppColors.expense,
      ),
    );
  }
}
