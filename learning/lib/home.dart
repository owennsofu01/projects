import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screens/dashboard_screen.dart';
import 'screens/expense_list_screen.dart' show ExpenseListScreen;
import 'screens/product_list_screen.dart';
import 'screens/record_sale_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense & Sales Tracker'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _tile(
              icon: Icons.inventory,
              label: 'Products',
              onTap: () => Get.to(() => ProductListScreen()),
            ),
            _tile(
              icon: Icons.point_of_sale,
              label: 'Sales',
              onTap: () => Get.to(() => RecordSaleScreen()),
            ),
            _tile(
              icon: Icons.receipt_long,
              label: 'Expenses',
              onTap: () => Get.to(() => ExpenseListScreen()),
            ),
            _tile(
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () => Get.to(() => DashboardScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
