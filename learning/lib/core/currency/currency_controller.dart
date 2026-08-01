import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../constants/currencies.dart';
import '../constants/firestore_collections.dart';
import '../utils/app_snackbars.dart';
import 'exchange_rate_service.dart';

/// Persists the user's preferred display currency on their Firestore user
/// doc (`currencyCode`), so it stays consistent across devices like the
/// rest of their account data.
///
/// Stored amounts are always ZMW (see [kBaseCurrency]). When the selected
/// display currency differs, [convert] applies a live rate fetched from
/// [ExchangeRateService] — the underlying stored amount is never mutated,
/// only how it's displayed.
class CurrencyController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ExchangeRateService _rateService = ExchangeRateService();
  final String userId;

  CurrencyController(this.userId);

  Rx<AppCurrency> currency = Rx<AppCurrency>(kDefaultCurrency);
  RxBool isSaving = false.obs;

  /// Units of the selected currency per 1 ZMW. Empty while rates are
  /// loading or if the fetch failed — [convert] falls back to a 1:1 (ZMW)
  /// rate in that case rather than showing a broken/blank amount.
  final RxMap<String, double> rates = <String, double>{}.obs;
  RxBool ratesLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrency();
    _loadRates();
  }

  Future<void> _loadCurrency() async {
    final doc = await _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();

    final code = doc.data()?['currencyCode'] as String?;
    if (code == null) return;

    currency.value = kSupportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => kDefaultCurrency,
    );
  }

  Future<void> _loadRates() async {
    try {
      ratesLoading.value = true;
      rates.assignAll(await _rateService.fetchRates());
    } catch (e) {
      // Silently fall back to 1:1 ZMW display — a rate-fetch hiccup
      // shouldn't block the rest of the app from working.
    } finally {
      ratesLoading.value = false;
    }
  }

  /// Converts a stored ZMW [amount] into the selected display currency.
  double convert(double amount) {
    if (currency.value.code == kBaseCurrency.code) return amount;
    final rate = rates[currency.value.code];
    if (rate == null) return amount;
    return amount * rate;
  }

  Future<void> setCurrency(AppCurrency newCurrency) async {
    if (newCurrency == currency.value) return;

    try {
      isSaving.value = true;
      await _db.collection(FirestoreCollections.users).doc(userId).update({
        'currencyCode': newCurrency.code,
      });
      currency.value = newCurrency;
      showSuccessSnackbar('Currency changed to ${newCurrency.name}');
    } catch (e) {
      showErrorSnackbar('Could not update currency. Please try again.');
    } finally {
      isSaving.value = false;
    }
  }
}
