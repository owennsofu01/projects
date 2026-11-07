import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/platform_support.dart';
import '../controllers/auth_controller.dart';
import 'google_sign_in_button.dart';
import 'or_divider.dart';

/// "or" divider followed by Google and Apple sign-in, on the platforms
/// that support each. Renders nothing when neither is available.
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    if (!supportsGoogleSignIn && !supportsAppleSignIn) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final busy = auth.isLoading.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OrDivider(),
          if (supportsGoogleSignIn)
            GoogleSignInButton(onPressed: busy ? null : auth.signInWithGoogle),
          if (supportsGoogleSignIn && supportsAppleSignIn)
            const SizedBox(height: 12),
          if (supportsAppleSignIn)
            SignInWithAppleButton(
              text: 'Continue with Apple',
              height: 52,
              style: SignInWithAppleButtonStyle.whiteOutlined,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              onPressed: busy ? null : auth.signInWithApple,
            ),
        ],
      );
    });
  }
}
