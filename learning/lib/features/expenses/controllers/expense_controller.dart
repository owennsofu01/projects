import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';

class ExpenseController extends GetxController {
  final ExpenseService _service = ExpenseService();
  final String userId;

  ExpenseController(this.userId);

  RxBool isSaving = false.obs;

  Stream<List<ExpenseModel>> get expensesStream => _service.getExpenses(userId);

  Future<bool> addExpense(ExpenseModel expense) async {
    try {
      isSaving.value = true;
      await _service.addExpense(userId, expense);
      return true;
    } catch (e) {
      showErrorSnackbar('Could not save expense. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
