import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches live conversion rates out of ZMW — the currency amounts are
/// actually recorded in — from the free exchangerate-api.com mirror.
class ExchangeRateService {
  static final _uri = Uri.parse('https://open.er-api.com/v6/latest/ZMW');

  /// Returns a map of currency code -> units of that currency per 1 ZMW.
  Future<Map<String, double>> fetchRates() async {
    final response = await http.get(_uri);
    if (response.statusCode != 200) {
      throw Exception('Exchange rate request failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['result'] != 'success') {
      throw Exception('Exchange rate API returned an error');
    }

    final rates = body['rates'] as Map<String, dynamic>;
    return rates.map((code, value) => MapEntry(code, (value as num).toDouble()));
  }
}
