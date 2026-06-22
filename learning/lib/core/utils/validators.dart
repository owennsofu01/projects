class FormValidators {
  FormValidators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value) {
    return (value == null || value.trim().isEmpty) ? 'Required' : null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return _emailPattern.hasMatch(value.trim()) ? null : 'Enter a valid email';
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = num.tryParse(value.trim());
    if (number == null) return 'Enter a valid number';
    if (number <= 0) return 'Must be greater than 0';
    return null;
  }

  static String? positiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = int.tryParse(value.trim());
    if (number == null) return 'Enter a whole number';
    if (number <= 0) return 'Must be greater than 0';
    return null;
  }
}
