import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController auth = Get.find<AuthController>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  UserModel? _user;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = await auth.fetchProfile();
    if (!mounted) return;
    setState(() {
      _user = user;
      nameCtrl.text = user?.name ?? '';
      emailCtrl.text = user?.email ?? '';
      _loading = false;
    });
  }

  Future<void> _saveName() async {
    if (!formKey.currentState!.validate()) return;
    await auth.updateName(nameCtrl.text.trim());
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete account?',
      message:
          'This permanently deletes your account and all products, sales, '
          'and expenses. This cannot be undone.',
      confirmLabel: 'Delete account',
    );
    if (!confirmed) return;

    setState(() => _deleting = true);
    final success = await _deleteWithReauth();
    if (!mounted) return;
    setState(() => _deleting = false);
    if (success) {
      showSuccessSnackbar('Account deleted');
    }
  }

  Future<bool> _deleteWithReauth() async {
    try {
      return await auth.deleteAccount();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        showErrorSnackbar(mapAuthError(e));
        return false;
      }
      if (!auth.hasPasswordProvider) {
        showErrorSnackbar(
          'For your security, please sign out, sign back in, then try '
          'deleting your account again.',
        );
        return false;
      }

      final password = await _promptPassword();
      if (password == null || password.isEmpty) return false;

      try {
        await auth.reauthenticateWithPassword(password);
      } catch (e) {
        showErrorSnackbar(mapAuthError(e));
        return false;
      }
      return _deleteWithReauth();
    }
  }

  Future<String?> _promptPassword() {
    final passwordCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm your password'),
        content: TextField(
          controller: passwordCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Password'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(passwordCtrl.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _Avatar(name: _user?.name ?? '')),
                  const SizedBox(height: 28),
                  Form(
                    key: formKey,
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
                          readOnly: true,
                        ),
                        if (_user != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Member since ${AppFormatter.date(_user!.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Obx(
                          () => AppPrimaryButton(
                            label: 'SAVE CHANGES',
                            isLoading: auth.isLoading.value,
                            onPressed: _saveName,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _DangerZone(
                    isDeleting: _deleting,
                    onDelete: _confirmDeleteAccount,
                  ),
                ],
              ),
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGradient.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onDelete, required this.isDeleting});

  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
        color: colorScheme.error.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Danger Zone',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Deleting your account permanently removes your profile, '
            'products, sales, and expenses. This cannot be undone.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isDeleting ? null : onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            icon: isDeleting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onError,
                    ),
                  )
                : const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
