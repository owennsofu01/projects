import 'package:get/get.dart';

import '../currency/currency_controller.dart';

class AppFormatter {
  AppFormatter._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Converts a stored ZMW [amount] into the user's selected display
  /// currency and formats it. Call sites that display this should be
  /// wrapped in `Obx` so they update when the currency or live rates
  /// change.
  static String currency(double amount) {
    final controller = Get.find<CurrencyController>();
    final converted = controller.convert(amount);
    return '${controller.currency.value.symbol}${converted.toStringAsFixed(2)}';
  }

  static String date(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  static String weekday(DateTime date) => _weekdays[date.weekday - 1];

  /// Compact currency for chart axes/labels, e.g. 1200 -> "1.2K". [amount]
  /// is a stored ZMW value, converted the same way as [currency].
  static String compactCurrency(double amount) {
    final controller = Get.find<CurrencyController>();
    final symbol = controller.currency.value.symbol;
    final converted = controller.convert(amount);
    final abs = converted.abs();
    final sign = converted < 0 ? '-' : '';
    if (abs >= 1000000) {
      return '$sign$symbol${(abs / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '$sign$symbol${(abs / 1000).toStringAsFixed(1)}K';
    }
    return '$sign$symbol${abs.toStringAsFixed(0)}';
  }
}
