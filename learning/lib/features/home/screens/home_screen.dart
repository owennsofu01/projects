import 'package:flutter/material.dart';

import '../../../ads/ads_manager.dart';
import '../../../core/sync/sync_status_bar.dart';
import '../../../core/widgets/notched_nav_bar.dart';
import '../../catalog/screens/catalog_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../reports/screens/report_screen.dart';
import '../../sales/screens/sale_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  late final List<Widget> _tabs = [
    DashboardScreen(),
    const CatalogScreen(),
    SaleListScreen(),
    ExpenseListScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SyncStatusBar(),
          const AnchoredBannerAd(),
          NotchedNavBar(
            selectedIndex: _index,
            onSelected: (index) => setState(() => _index = index),
            items: const [
              NotchedNavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard,
                label: 'Dashboard',
              ),
              NotchedNavItem(
                icon: Icons.inventory_2_outlined,
                selectedIcon: Icons.inventory_2,
                label: 'Catalog',
              ),
              // Middle item: the raised center button.
              NotchedNavItem(
                icon: Icons.point_of_sale_outlined,
                selectedIcon: Icons.point_of_sale,
                label: 'Sales',
              ),
              NotchedNavItem(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: 'Expenses',
              ),
              NotchedNavItem(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'Reports',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
