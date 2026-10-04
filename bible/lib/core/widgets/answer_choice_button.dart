import 'package:flutter/material.dart';

/// A full-width multiple-choice answer that turns green or red once answered.
class AnswerChoiceButton extends StatelessWidget {
  const AnswerChoiceButton({super.key, required this.label, required this.result, required this.onPressed});

  final String label;

  /// true = the correct answer, false = the wrong pick, null = neither/unanswered.
  final bool? result;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = switch (result) {
      true => Colors.green,
      false => Colors.red,
      null => null,
    };
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignment: Alignment.centerLeft,
        foregroundColor: color,
        disabledForegroundColor: color,
        backgroundColor: color?.withValues(alpha: 0.1),
        side: color != null ? BorderSide(color: color, width: 2) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          if (result == true) const Icon(Icons.check_circle, color: Colors.green),
          if (result == false) const Icon(Icons.cancel, color: Colors.red),
        ],
      ),
    );
  }
}
