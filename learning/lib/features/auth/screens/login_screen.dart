import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/platform_support.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/or_divider.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(subtitle: 'Welcome back'),
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
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.register),
                      child: const Text('Create an account'),
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
