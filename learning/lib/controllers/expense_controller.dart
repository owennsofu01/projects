import 'package:get/get.dart';

import '../models/expenses-model.dart';
import '../services/expense_service.dart';

class ExpenseController extends GetxController {
  final ExpenseService _service = ExpenseService();
  final String userId;

  ExpenseController(this.userId);

  // ✅ Public stream (UI-safe)
  Stream<List<ExpenseModel>> get expensesStream {
    return _service.getExpenses(userId);
  }

  Future<void> addExpense(ExpenseModel expense) {
    return _service.addExpense(userId, expense);
  }
}
