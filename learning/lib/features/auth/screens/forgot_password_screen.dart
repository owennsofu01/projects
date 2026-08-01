import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: 'Reset your password',
                        subtitle:
                            "Enter your account email and we'll send you a "
                            'link to reset it',
                      ),
                      AppTextField(
                        controller: emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: FormValidators.email,
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => AppPrimaryButton(
                          label: 'SEND RESET LINK',
                          isLoading: auth.isLoading.value,
                          onPressed: _submit,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                            children: [
                              const TextSpan(text: 'Remembered it? '),
                              TextSpan(
                                text: 'Back to login',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
