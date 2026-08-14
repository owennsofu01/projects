import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/platform_support.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_header.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/or_divider.dart';

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Create your account',
                      subtitle: 'Start tracking profit in minutes',
                    ),
                    Form(
                      key: formKey,
                      child: AuthCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: nameCtrl,
                              label: 'Full Name',
                              icon: Icons.person_outline,
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
                            AppTextField(
                              controller: confirmPassCtrl,
                              label: 'Confirm Password',
                              icon: Icons.lock_outline,
                              obscureText: true,
                              validator: _validateConfirmPassword,
                            ),
                            const SizedBox(height: 4),
                            Obx(
                              () => AppPrimaryButton(
                                label: 'CREATE ACCOUNT',
                                isLoading: auth.isLoading.value,
                                onPressed: _register,
                              ),
                            ),
                            if (supportsAppleSignIn ||
                                supportsGoogleSignIn) ...[
                              const OrDivider(),
                              if (supportsGoogleSignIn) ...[
                                Obx(
                                  () => GoogleSignInButton(
                                    onPressed: auth.isLoading.value
                                        ? null
                                        : auth.signInWithGoogle,
                                  ),
                                ),
                                if (supportsAppleSignIn)
                                  const SizedBox(height: 12),
                              ],
                              if (supportsAppleSignIn)
                                Obx(
                                  () => SignInWithAppleButton(
                                    borderRadius: BorderRadius.circular(14),
                                    onPressed: auth.isLoading.value
                                        ? null
                                        : auth.signInWithApple,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.login),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          children: [
                            const TextSpan(
                              text: 'Already have an account? ',
                            ),
                            TextSpan(
                              text: 'Login',
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
    );
  }
}
