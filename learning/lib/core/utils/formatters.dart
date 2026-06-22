class AppFormatter {
  AppFormatter._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String currency(double value) => '\$${value.toStringAsFixed(2)}';

  static String date(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}
