import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatelessWidget {
  ExpenseListScreen({super.key});

  final ExpenseController controller = Get.find<ExpenseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expenses-fab',
        onPressed: () => Get.to(() => AddExpenseScreen()),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: controller.expensesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;

          if (expenses.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No expenses recorded',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final expense = expenses[index];

              return Card(
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
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
