import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/motion.dart';

/// Shared layout for the sign-in screens: optional back button, centered
/// logo, title and subtitle, the form, and a footer pinned to the bottom.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Shown at the bottom of the screen, e.g. "Don't have an account?".
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canPop = Navigator.of(context).canPop();

    var step = 0;
    Widget enter(Widget child) => FadeSlideIn(
      delay: Duration(milliseconds: 50 * step++),
      child: child,
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: canPop
                              ? const _BackButton()
                              : const SizedBox(height: 44),
                        ),
                        const SizedBox(height: 12),
                        enter(const Center(child: LogoTile(size: 64))),
                        const SizedBox(height: 20),
                        enter(
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        enter(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        enter(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: children,
                          ),
                        ),
                        const Spacer(),
                        if (footer != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 16),
                            child: Center(child: footer),
                          ),
                      ],
                    ),
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

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: CircleBorder(side: BorderSide(color: colorScheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: Get.back,
        child: const SizedBox.square(
          dimension: 44,
          child: Icon(Icons.arrow_back, size: 20),
        ),
      ),
    );
  }
}

/// "Question? Action" footer link, e.g. "Don't have an account? Sign up".
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onTap,
      child: Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: '$question '),
            TextSpan(
              text: action,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
