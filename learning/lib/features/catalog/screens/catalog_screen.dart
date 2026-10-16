import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../products/screens/product_list_screen.dart';
import '../../products/screens/product_profitability_screen.dart';
import '../../services/screens/service_list_screen.dart';
import '../../services/screens/service_performance_screen.dart';

/// Everything the business sells: products (stocked) and services.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });

  late final List<Widget> _pages = [ProductListScreen(), ServiceListScreen()];

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onServices = _tabs.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          IconButton(
            onPressed: () => onServices
                ? Get.to(() => ServicePerformanceScreen())
                : Get.to(() => ProductProfitabilityScreen()),
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: onServices
                ? 'Service performance'
                : 'Product profitability',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'),
            Tab(icon: Icon(Icons.content_cut), text: 'Services'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: _pages),
    );
  }
}
