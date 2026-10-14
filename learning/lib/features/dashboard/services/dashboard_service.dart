import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_collections.dart';

/// Aggregate sales totals over a date range, computed from a single
/// Firestore listener rather than querying the same collection twice.
class SalesSummary {
  final double totalAmount;
  final double totalProfit;

  const SalesSummary({required this.totalAmount, required this.totalProfit});

  static const zero = SalesSummary(totalAmount: 0, totalProfit: 0);
}

/// One day's sales in a trend series, zero-filled for days with no sales so
/// charts always render a continuous, evenly-spaced axis.
class DailySales {
  final DateTime day;
  final double amount;
  final double profit;

  const DailySales({
    required this.day,
    required this.amount,
    required this.profit,
  });
}

/// One day's expense total in a trend series, zero-filled like [DailySales].
class DailyExpense {
  final DateTime day;
  final double amount;

  const DailyExpense({required this.day, required this.amount});
}

/// One calendar month's sales activity in a trend series, zero-filled
/// like [DailySales].
class MonthlySales {
  final DateTime month;
  final double amount;
  final double profit;

  const MonthlySales({
    required this.month,
    required this.amount,
    required this.profit,
  });
}

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<SalesSummary> salesSummarySince(String userId, DateTime from) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
          double totalAmount = 0;
          double totalProfit = 0;
          for (final doc in snapshot.docs) {
            totalAmount += (doc['totalAmount'] as num).toDouble();
            totalProfit += (doc['profit'] as num).toDouble();
          }
          return SalesSummary(
            totalAmount: totalAmount,
            totalProfit: totalProfit,
          );
        });
  }

  Stream<double> expenseTotalSince(String userId, DateTime from) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.expenses)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<double>(
            0,
            (total, doc) => total + (doc['amount'] as num).toDouble(),
          ),
        );
  }

  /// Sales bucketed by day for the trailing [days] days (including today),
  /// oldest first.
  Stream<List<DailySales>> dailySalesSeries(String userId, {int days = 7}) {
    final from = _startOfDay(DateTime.now().subtract(Duration(days: days - 1)));

    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
          final amountByDay = <DateTime, double>{};
          final profitByDay = <DateTime, double>{};

          for (final doc in snapshot.docs) {
            final day = _startOfDay((doc['date'] as Timestamp).toDate());
            amountByDay[day] =
                (amountByDay[day] ?? 0) +
                (doc['totalAmount'] as num).toDouble();
            profitByDay[day] =
                (profitByDay[day] ?? 0) + (doc['profit'] as num).toDouble();
          }

          return List.generate(days, (i) {
            final day = from.add(Duration(days: i));
            return DailySales(
              day: day,
              amount: amountByDay[day] ?? 0,
              profit: profitByDay[day] ?? 0,
            );
          });
        });
  }

  /// Expenses bucketed by day for the trailing [days] days, mirroring
  /// [dailySalesSeries] so the two can be zipped by index in the UI.
  Stream<List<DailyExpense>> dailyExpenseSeries(String userId, {int days = 7}) {
    final from = _startOfDay(DateTime.now().subtract(Duration(days: days - 1)));

    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.expenses)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
          final amountByDay = <DateTime, double>{};

          for (final doc in snapshot.docs) {
            final day = _startOfDay((doc['date'] as Timestamp).toDate());
            amountByDay[day] =
                (amountByDay[day] ?? 0) + (doc['amount'] as num).toDouble();
          }

          return List.generate(days, (i) {
            final day = from.add(Duration(days: i));
            return DailyExpense(day: day, amount: amountByDay[day] ?? 0);
          });
        });
  }

  /// Expense totals grouped by category since [from], sorted descending.
  Stream<Map<String, double>> expenseBreakdownByCategory(
    String userId,
    DateTime from,
  ) {
    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.expenses)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
          final totals = <String, double>{};
          for (final doc in snapshot.docs) {
            final category = (doc['category'] as String?)?.trim();
            final key = (category == null || category.isEmpty)
                ? 'Other'
                : category;
            totals[key] =
                (totals[key] ?? 0) + (doc['amount'] as num).toDouble();
          }
          final sorted = totals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return {for (final e in sorted) e.key: e.value};
        });
  }

  /// Sales bucketed by calendar month for the trailing [months] months
  /// (including the current one), oldest first.
  Stream<List<MonthlySales>> monthlySalesSeries(
    String userId, {
    int months = 12,
  }) {
    final from = _monthsAgo(months - 1);

    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.sales)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
          final amountByMonth = <DateTime, double>{};
          final profitByMonth = <DateTime, double>{};

          for (final doc in snapshot.docs) {
            final month = _startOfMonth((doc['date'] as Timestamp).toDate());
            amountByMonth[month] =
                (amountByMonth[month] ?? 0) +
                (doc['totalAmount'] as num).toDouble();
            profitByMonth[month] =
                (profitByMonth[month] ?? 0) + (doc['profit'] as num).toDouble();
          }

          return List.generate(months, (i) {
            final month = DateTime(from.year, from.month + i);
            return MonthlySales(
              month: month,
              amount: amountByMonth[month] ?? 0,
              profit: profitByMonth[month] ?? 0,
            );
          });
        });
  }

  /// Expense totals bucketed by calendar month, mirroring
  /// [monthlySalesSeries] so the two can be zipped by index in the UI.
  Stream<List<double>> monthlyExpenseSeries(String userId, {int months = 12}) {
    final from = _monthsAgo(months - 1);

    return _db
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.expenses)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
          final amountByMonth = <DateTime, double>{};
          for (final doc in snapshot.docs) {
            final month = _startOfMonth((doc['date'] as Timestamp).toDate());
            amountByMonth[month] =
                (amountByMonth[month] ?? 0) + (doc['amount'] as num).toDouble();
          }
          return List.generate(
            months,
            (i) => amountByMonth[DateTime(from.year, from.month + i)] ?? 0,
          );
        });
  }

  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month);

  DateTime _monthsAgo(int months) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - months);
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
