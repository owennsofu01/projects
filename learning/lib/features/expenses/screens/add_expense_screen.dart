import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';

class AddExpenseScreen extends StatelessWidget {
  AddExpenseScreen({super.key});

  final ExpenseController controller = Get.find<ExpenseController>();

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController categoryCtrl = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> _saveExpense() async {
    if (!formKey.currentState!.validate()) return;

    final expense = ExpenseModel(
      id: '',
      title: titleCtrl.text.trim(),
      amount: double.parse(amountCtrl.text),
      category: categoryCtrl.text.trim(),
      date: DateTime.now(),
    );

    final success = await controller.addExpense(expense);
    if (success) {
      Get.back();
      showSuccessSnackbar('Expense added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              AppTextField(
                controller: titleCtrl,
                label: 'Expense Title',
                icon: Icons.receipt_long,
              ),
              AppTextField(
                controller: amountCtrl,
                label: 'Amount',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: FormValidators.positiveNumber,
              ),
              AppTextField(
                controller: categoryCtrl,
                label: 'Category (optional)',
                icon: Icons.category,
              ),
              const SizedBox(height: 24),
              Obx(
                () => AppPrimaryButton(
                  label: 'SAVE EXPENSE',
                  isLoading: controller.isSaving.value,
                  onPressed: _saveExpense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
