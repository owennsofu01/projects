import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final String userId = Get.find<AuthController>().userId;
  // Inject userId once at login
  final FirebaseFirestore db = FirebaseFirestore.instance;

  DateTime get todayStart =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime get monthStart =>
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  Stream<double> salesTotal(DateTime from) {
    return db
        .collection('users')
        .doc(userId)
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<double>(
            0,
            (sum, doc) => sum + (doc['totalAmount'] as num).toDouble(),
          ),
        );
  }

  Stream<double> expenseTotal(DateTime from) {
    return db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<double>(
            0,
            (sum, doc) => sum + (doc['amount'] as num).toDouble(),
          ),
        );
  }

  Stream<double> profitTotal(DateTime from) {
    return db
        .collection('users')
        .doc(userId)
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold<double>(
            0,
            (sum, doc) => sum + (doc['profit'] as num).toDouble(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _row(
              salesTotal(todayStart),
              expenseTotal(todayStart),
              profitTotal(todayStart),
            ),
            const SizedBox(height: 24),
            const Text(
              'This Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _row(
              salesTotal(monthStart),
              expenseTotal(monthStart),
              profitTotal(monthStart),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    Stream<double> sales,
    Stream<double> expenses,
    Stream<double> profit,
  ) {
    return Row(
      children: [
        Expanded(child: _card('Sales', sales, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _card('Expenses', expenses, Colors.red)),
        const SizedBox(width: 12),
        Expanded(child: _card('Profit', profit, Colors.green)),
      ],
    );
  }

  Widget _card(String title, Stream<double> stream, Color color) {
    return StreamBuilder<double>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0.0;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
