import 'package:flutter/material.dart';

/// Styled per Google's branding guidelines for the "light" button variant:
/// fixed white background and dark grey text/border, not theme-adaptive —
/// matching how [SignInWithAppleButton] is used elsewhere in this app.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  static const _borderColor = Color(0xFF747775);
  static const _textColor = Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
          side: const BorderSide(color: _borderColor),
          shape: RoundedRectangleBorder(
            // Matches the app's 14px corner radius (buttons/cards/inputs)
            // rather than Google's default 8px, so it doesn't look like a
            // mismatched third-party widget dropped into the form.
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/google_logo.png',
              height: 18,
              width: 18,
            ),
            const SizedBox(width: 10),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
