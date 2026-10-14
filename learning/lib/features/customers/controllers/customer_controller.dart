import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../models/customer_model.dart';
import '../models/ledger_entry.dart';
import '../services/customer_service.dart';

class CustomerController extends GetxController {
  final CustomerService _service = CustomerService();
  final String userId;

  CustomerController(this.userId);

  final RxList<CustomerModel> customers = <CustomerModel>[].obs;
  final RxBool isSaving = false.obs;

  List<CustomerModel> get debtors =>
      customers.where((c) => c.owesMoney).toList()
        ..sort((a, b) => b.balance.compareTo(a.balance));

  double get totalOwed =>
      customers.fold(0, (sum, c) => sum + (c.owesMoney ? c.balance : 0));

  @override
  void onInit() {
    customers.bindStream(_service.getCustomers(userId));
    super.onInit();
  }

  Stream<CustomerModel?> watchCustomer(String customerId) =>
      _service.watchCustomer(userId, customerId);

  Stream<List<LedgerEntry>> ledger(String customerId) =>
      _service.getLedger(userId, customerId);

  Future<CustomerModel?> addCustomer({
    required String name,
    required String phone,
  }) async {
    try {
      isSaving.value = true;
      return await _service.addCustomer(userId, name: name, phone: phone);
    } catch (e) {
      showErrorSnackbar('Could not save customer. Please try again.');
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateCustomer(
    String customerId, {
    required String name,
    required String phone,
  }) async {
    try {
      isSaving.value = true;
      await _service.updateCustomer(
        userId,
        customerId,
        name: name,
        phone: phone,
      );
      return true;
    } catch (e) {
      showErrorSnackbar('Could not update customer. Please try again.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      await _service.deleteCustomer(userId, customerId);
      return true;
    } catch (e) {
      showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> recordPayment(
    String customerId, {
    required double amount,
    String note = '',
  }) async {
    try {
      isSaving.value = true;
      await _service.recordPayment(
        userId,
        customerId,
        amount: amount,
        note: note,
      );
      return true;
    } catch (e) {
      showErrorSnackbar(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
