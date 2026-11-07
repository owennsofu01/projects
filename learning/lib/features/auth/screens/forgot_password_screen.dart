import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final AuthController auth = Get.find<AuthController>();

  final emailCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    final success = await auth.resetPassword(emailCtrl.text.trim());
    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset your password',
      subtitle:
          "Enter your account email and we'll send you a link to reset it.",
      footer: AuthFooterLink(
        question: 'Remembered it?',
        action: 'Back to login',
        onTap: Get.back,
      ),
      children: [
        Form(
          key: formKey,
          child: AppTextField(
            controller: emailCtrl,
            label: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: FormValidators.email,
          ),
        ),
        const SizedBox(height: 4),
        Obx(
          () => AppPrimaryButton(
            label: 'Send reset link',
            isLoading: auth.isLoading.value,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
