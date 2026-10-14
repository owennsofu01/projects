import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';

/// Adds a customer, or edits one when [customer] is given. When adding,
/// pops with the new [CustomerModel] so callers (e.g. checkout) can select
/// it straight away.
class AddCustomerScreen extends StatelessWidget {
  AddCustomerScreen({super.key, this.customer});

  final CustomerModel? customer;

  final CustomerController controller = Get.find<CustomerController>();

  late final TextEditingController nameCtrl = TextEditingController(
    text: customer?.name,
  );
  late final TextEditingController phoneCtrl = TextEditingController(
    text: customer?.phone,
  );

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool get isEditing => customer != null;

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final existing = customer;

    if (existing != null) {
      final success = await controller.updateCustomer(
        existing.id,
        name: name,
        phone: phone,
      );
      if (success) {
        Get.back();
        showSuccessSnackbar('Customer updated');
      }
      return;
    }

    final created = await controller.addCustomer(name: name, phone: phone);
    if (created != null) {
      Get.back(result: created);
      showSuccessSnackbar('Customer added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Customer' : 'Add Customer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              AppTextField(
                controller: nameCtrl,
                label: 'Name',
                icon: Icons.person_outline,
              ),
              AppTextField(
                controller: phoneCtrl,
                label: 'Phone (optional, include country code)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (_) => null,
              ),
              const SizedBox(height: 24),
              Obx(
                () => AppPrimaryButton(
                  label: isEditing ? 'SAVE CHANGES' : 'SAVE CUSTOMER',
                  isLoading: controller.isSaving.value,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
