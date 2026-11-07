import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/legal_links.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/social_sign_in_buttons.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final AuthController auth = Get.find<AuthController>();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void _login() {
    if (!formKey.currentState!.validate()) return;
    auth.login(email: emailCtrl.text.trim(), password: passCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to keep tracking your sales, stock and profit.',
      footer: Column(
        children: [
          AuthFooterLink(
            question: "Don't have an account?",
            action: 'Sign up',
            onTap: () => Get.toNamed(AppRoutes.register),
          ),
          TextButton(
            onPressed: openPrivacyPolicy,
            child: Text('Privacy Policy', style: textTheme.bodySmall),
          ),
        ],
      ),
      children: [
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Get.to(() => ForgotPasswordScreen()),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => AppPrimaryButton(
            label: 'Login',
            isLoading: auth.isLoading.value,
            onPressed: _login,
          ),
        ),
        SocialSignInButtons(auth: auth),
      ],
    );
  }
}
