import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../budgets/controllers/budget_controller.dart';
import '../../budgets/widgets/category_field.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final ExpenseController controller = Get.find<ExpenseController>();
  final BudgetController budgetController = Get.find<BudgetController>();

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController categoryCtrl = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  List<String> _categories = const [];

  @override
  void initState() {
    super.initState();
    budgetController.expenseCategories().then((categories) {
      // Categories with a budget are worth suggesting even if unused yet.
      final names = {
        for (final c in categories) c.toLowerCase(): c,
        for (final b in budgetController.budgets) b.key: b.category,
      }.values.toList()..sort();
      if (mounted) setState(() => _categories = names);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
    categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!formKey.currentState!.validate()) return;

    final expense = ExpenseModel(
      id: '',
      title: titleCtrl.text.trim(),
      amount: double.parse(amountCtrl.text),
      category: categoryCtrl.text.trim(),
      date: DateTime.now(),
    );

    // Measured against this month's total before the save lands in it.
    final spentBefore = Map.of(budgetController.spentThisMonth);
    final success = await controller.addExpense(expense);
    if (success) {
      Get.back();
      final warned = budgetController.warnIfExpenseCrossesBudget(
        expense.category,
        expense.amount,
        spentBefore: spentBefore,
      );
      if (!warned) showSuccessSnackbar('Expense added');
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
              CategoryField(controller: categoryCtrl, suggestions: _categories),
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
