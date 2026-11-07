import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_sign_in_buttons.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final AuthController auth = Get.find<AuthController>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void _register() {
    if (!formKey.currentState!.validate()) return;

    auth.register(
      name: nameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      password: passCtrl.text.trim(),
    );
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value != passCtrl.text) return 'Passwords don\'t match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Start tracking sales, stock and profit in minutes.',
      footer: AuthFooterLink(
        question: 'Already have an account?',
        action: 'Login',
        // Came from Login: go back to it. Came from onboarding: replace.
        onTap: () => Navigator.of(context).canPop()
            ? Get.back()
            : Get.offNamed(AppRoutes.login),
      ),
      children: [
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: nameCtrl,
                label: 'Full name',
                icon: Icons.person_outline,
              ),
              AppTextField(
                controller: emailCtrl,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: FormValidators.email,
              ),
              AppTextField(
                controller: passCtrl,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              AppTextField(
                controller: confirmPassCtrl,
                label: 'Confirm password',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: _validateConfirmPassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Obx(
          () => AppPrimaryButton(
            label: 'Sign up',
            isLoading: auth.isLoading.value,
            onPressed: _register,
          ),
        ),
        SocialSignInButtons(auth: auth),
      ],
    );
  }
}
