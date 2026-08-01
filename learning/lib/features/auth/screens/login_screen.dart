import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/legal_links.dart';
import '../../../core/utils/platform_support.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/or_divider.dart';
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
                        title: 'Welcome back',
                        subtitle: 'Sign in to keep tracking your profit',
                      ),
                      AppTextField(
                        controller: emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: FormValidators.email,
                      ),
                      AppTextField(
                        controller: passCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              Get.to(() => ForgotPasswordScreen()),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => AppPrimaryButton(
                          label: 'LOGIN',
                          isLoading: auth.isLoading.value,
                          onPressed: _login,
                        ),
                      ),
                      if (supportsAppleSignIn) ...[
                        const OrDivider(),
                        Obx(
                          () => SignInWithAppleButton(
                            onPressed: auth.isLoading.value
                                ? null
                                : auth.signInWithApple,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.register),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Create one',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: openPrivacyPolicy,
                        child: Text(
                          'Privacy Policy',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
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
