import 'package:flutter/material.dart';

/// Groups the auth form (fields, primary action, alt sign-in methods) into
/// one grounded panel instead of leaving them floating directly on the
/// gradient backdrop. Uses `surfaceContainerHigh` rather than `surface` —
/// the scaffold background is already `colorScheme.surface`, so the card
/// would be visually indistinguishable from the page behind it otherwise,
/// especially in dark mode where the shadow below barely reads.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
