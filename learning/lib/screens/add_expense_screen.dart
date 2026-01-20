import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expense_controller.dart';

import '../models/expenses-model.dart';

class AddExpenseScreen extends StatelessWidget {
  AddExpenseScreen({super.key});

  final ExpenseController controller = Get.find<ExpenseController>();

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController categoryCtrl = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void saveExpense() {
    if (!formKey.currentState!.validate()) return;

    final expense = ExpenseModel(
      id: '',
      title: titleCtrl.text.trim(),
      amount: double.parse(amountCtrl.text),
      category: categoryCtrl.text.trim(),
      date: DateTime.now(),
    );

    controller.addExpense(expense);

    Get.back();
    Get.snackbar('Success', 'Expense added');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              _input(
                controller: titleCtrl,
                label: 'Expense Title',
                icon: Icons.receipt_long,
              ),
              _input(
                controller: amountCtrl,
                label: 'Amount',
                icon: Icons.attach_money,
                keyboard: TextInputType.number,
              ),
              _input(
                controller: categoryCtrl,
                label: 'Category (optional)',
                icon: Icons.category,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'SAVE EXPENSE',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
