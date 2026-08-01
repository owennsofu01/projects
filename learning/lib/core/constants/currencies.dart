class AppCurrency {
  final String code;
  final String symbol;
  final String name;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  @override
  bool operator ==(Object other) => other is AppCurrency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// The currency amounts are actually recorded in throughout the app —
/// every stored product/sale/expense number is a ZMW amount. Every other
/// [AppCurrency] is a *display* conversion off of this one, applied live
/// via [ExchangeRateService].
const kBaseCurrency = AppCurrency(
  code: 'ZMW',
  symbol: 'K',
  name: 'Zambian Kwacha',
);

const kDefaultCurrency = kBaseCurrency;

const kSupportedCurrencies = [
  kBaseCurrency,
  AppCurrency(code: 'USD', symbol: '\$', name: 'US Dollar'),
  AppCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
  AppCurrency(code: 'GBP', symbol: '£', name: 'British Pound'),
  AppCurrency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
  AppCurrency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  AppCurrency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  AppCurrency(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar'),
  AppCurrency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
  AppCurrency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
];
