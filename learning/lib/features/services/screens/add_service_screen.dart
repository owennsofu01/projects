import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/service_controller.dart';
import '../models/service_model.dart';

class AddServiceScreen extends StatelessWidget {
  AddServiceScreen({super.key, this.service});

  /// When set, the screen edits this service instead of creating a new one.
  final ServiceModel? service;

  final ServiceController controller = Get.find<ServiceController>();

  late final TextEditingController nameCtrl = TextEditingController(
    text: service?.name,
  );
  late final TextEditingController priceCtrl = TextEditingController(
    text: service?.price.toStringAsFixed(2),
  );
  late final TextEditingController materialsCtrl = TextEditingController(
    text: service?.materialsCost.toStringAsFixed(2),
  );

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool get isEditing => service != null;

  static String? _optionalAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = num.tryParse(value.trim());
    if (number == null) return 'Enter a valid number';
    if (number < 0) return 'Cannot be negative';
    return null;
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    final name = nameCtrl.text.trim();
    if (controller.nameTaken(name, exceptId: service?.id)) {
      showErrorSnackbar('You already have a service called $name');
      return;
    }

    final existing = service;
    final now = DateTime.now();
    final price = double.parse(priceCtrl.text.trim());
    final materials = double.tryParse(materialsCtrl.text.trim()) ?? 0;

    final success = existing == null
        ? await controller.addService(
            ServiceModel(
              id: '',
              name: name,
              price: price,
              materialsCost: materials,
              createdAt: now,
              updatedAt: now,
            ),
          )
        : await controller.updateService(
            ServiceModel(
              id: existing.id,
              name: name,
              price: price,
              materialsCost: materials,
              createdAt: existing.createdAt,
              updatedAt: now,
            ),
          );

    if (success) {
      Get.back();
      showSuccessSnackbar(isEditing ? 'Service updated' : 'Service added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Service' : 'Add Service')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              AppTextField(
                controller: nameCtrl,
                label: 'Service name',
                icon: Icons.content_cut,
              ),
              AppTextField(
                controller: priceCtrl,
                label: 'Usual price',
                icon: Icons.price_check,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: FormValidators.positiveNumber,
              ),
              AppTextField(
                controller: materialsCtrl,
                label: 'Materials cost per job (optional)',
                icon: Icons.shopping_basket_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _optionalAmount,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'What each job uses up, like extensions, relaxer or '
                  'blades. Profit per job is the price minus this. You can '
                  'change the price on each sale.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => AppPrimaryButton(
                  label: isEditing ? 'SAVE CHANGES' : 'SAVE SERVICE',
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
