import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/business_profile_controller.dart';
import '../models/business_profile.dart';

/// Edits the shop details printed on receipts.
class BusinessProfileScreen extends StatelessWidget {
  BusinessProfileScreen({super.key});

  final BusinessProfileController controller =
      Get.find<BusinessProfileController>();

  late final BusinessProfile _initial = controller.profile.value;
  late final TextEditingController nameCtrl = TextEditingController(
    text: _initial.name,
  );
  late final TextEditingController phoneCtrl = TextEditingController(
    text: _initial.phone,
  );
  late final TextEditingController addressCtrl = TextEditingController(
    text: _initial.address,
  );
  late final TextEditingController footerCtrl = TextEditingController(
    text: _initial.footer,
  );

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    final success = await controller.save(
      BusinessProfile(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        footer: footerCtrl.text.trim(),
      ),
    );
    if (success) {
      Get.back();
      showSuccessSnackbar('Business details saved');
    }
  }

  String? _optional(String? _) => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              Text(
                'Shown on the receipts you share with customers.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: nameCtrl,
                label: 'Shop / business name',
                icon: Icons.storefront_outlined,
              ),
              AppTextField(
                controller: phoneCtrl,
                label: 'Phone (optional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _optional,
              ),
              AppTextField(
                controller: addressCtrl,
                label: 'Address (optional)',
                icon: Icons.place_outlined,
                validator: _optional,
              ),
              AppTextField(
                controller: footerCtrl,
                label: 'Receipt message (optional, e.g. "Thank you!")',
                icon: Icons.chat_bubble_outline,
                validator: _optional,
              ),
              const SizedBox(height: 24),
              Obx(
                () => AppPrimaryButton(
                  label: 'SAVE',
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
