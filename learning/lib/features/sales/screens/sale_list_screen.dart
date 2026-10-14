import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../customers/screens/customer_list_screen.dart';
import '../controllers/sale_controller.dart';
import '../models/sale_model.dart';
import 'record_sale_screen.dart';

class SaleListScreen extends StatelessWidget {
  SaleListScreen({super.key});

  final SaleController controller = Get.find<SaleController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            tooltip: 'Customers',
            icon: const Icon(Icons.people_outline),
            onPressed: () => Get.to(() => const CustomerListScreen()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'sales-fab',
        onPressed: () => Get.to(() => const RecordSaleScreen()),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<SaleModel>>(
        stream: controller.salesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final receipts = _groupByReceipt(snapshot.data!);

          if (receipts.isEmpty) {
            return const EmptyState(
              icon: Icons.point_of_sale_outlined,
              message: 'No sales recorded yet',
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 600
                  ? 24.0
                  : 16.0;

              return Center(
                child: ConstrainedBox(
                  // A transaction log reads best as one column even on
                  // wide screens — cap the width instead of turning it
                  // into a grid, and just give it more breathing room.
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    itemCount: receipts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _ReceiptCard(lines: receipts[index]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Groups line items into receipts, keeping the newest-first order of
  /// [sales] (lines of one receipt share a timestamp, so stay adjacent).
  List<List<SaleModel>> _groupByReceipt(List<SaleModel> sales) {
    final byReceipt = <String, List<SaleModel>>{};
    for (final sale in sales) {
      byReceipt.putIfAbsent(sale.receiptId, () => []).add(sale);
    }
    return byReceipt.values.toList();
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.lines});

  final List<SaleModel> lines;

  String get _customerSuffix {
    final name = lines.first.customerName;
    return name == null ? '' : '  •  $name';
  }

  @override
  Widget build(BuildContext context) {
    final total = lines.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final profit = lines.fold<double>(0, (sum, s) => sum + s.profit);
    final date = lines.first.date;

    if (lines.length == 1) {
      final sale = lines.first;
      return Card(
        child: ListTile(
          leading: const Icon(Icons.point_of_sale),
          title: Text(sale.productName),
          subtitle: Obx(
            () => Text(
              '${sale.quantity} × ${AppFormatter.currency(sale.sellingPrice)}'
              '  •  ${AppFormatter.date(date)}$_customerSuffix',
            ),
          ),
          trailing: _Amounts(total: total, profit: profit),
        ),
      );
    }

    final units = lines.fold<int>(0, (sum, s) => sum + s.quantity);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.receipt_long),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          '${lines.length} products · $units units',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${lines.map((s) => s.productName).join(', ')}\n'
          '${AppFormatter.date(date)}$_customerSuffix',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _Amounts(total: total, profit: profit),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final sale in lines)
            Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${sale.productName}  ·  ${sale.quantity} × '
                        '${AppFormatter.currency(sale.sellingPrice)}',
                      ),
                    ),
                    Text(
                      AppFormatter.currency(sale.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Amounts extends StatelessWidget {
  const _Amounts({required this.total, required this.profit});

  final double total;
  final double profit;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            AppFormatter.currency(total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '+${AppFormatter.currency(profit)}',
            style: const TextStyle(fontSize: 12, color: AppColors.income),
          ),
        ],
      ),
    );
  }
}
