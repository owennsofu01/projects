import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final AuthController auth = Get.find<AuthController>();

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void login() {
    if (!formKey.currentState!.validate()) return;

    auth.login(email: emailCtrl.text.trim(), password: passCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              _input(emailCtrl, 'Email'),
              _input(passCtrl, 'Password', isPassword: true),
              const SizedBox(height: 24),
              Obx(
                () => ElevatedButton(
                  onPressed: auth.isLoading.value ? null : login,
                  child: auth.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text('LOGIN'),
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed('/register'),
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
