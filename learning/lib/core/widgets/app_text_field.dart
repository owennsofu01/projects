import 'package:flutter/material.dart';

import '../utils/validators.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final String? Function(String?)? validator;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  // Fields marked obscureText start hidden, but the user can reveal them —
  // a plain obscureText: true with no way to check what was typed is a
  // common source of failed logins, especially on mobile keyboards.
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: _obscured,
        readOnly: widget.readOnly,
        validator: widget.readOnly
            ? null
            : (widget.validator ?? FormValidators.required),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: widget.readOnly
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: widget.icon != null
              ? Icon(widget.icon, size: 20)
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  tooltip: _obscured ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscured = !_obscured),
                )
              : null,
        ),
      ),
    );
  }
}
