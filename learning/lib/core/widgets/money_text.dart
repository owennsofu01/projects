import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/formatters.dart';

/// A currency amount that re-formats when the display currency changes.
/// Set [deduction] to show it as a subtraction, e.g. "−K120.00".
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.deduction = false,
    this.textAlign,
  });

  final double amount;
  final TextStyle? style;
  final bool deduction;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Text(
        '${deduction ? '−' : ''}${AppFormatter.currency(amount)}',
        textAlign: textAlign,
        maxLines: 1,
        style: (style ?? const TextStyle()).copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
