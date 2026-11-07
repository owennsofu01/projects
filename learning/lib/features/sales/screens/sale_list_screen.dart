import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/add_fab.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/list_row.dart';
import '../../../core/widgets/money_text.dart';
import '../../customers/screens/customer_list_screen.dart';
import '../../receipts/models/receipt.dart';
import '../../receipts/screens/receipt_screen.dart';
import '../controllers/sale_controller.dart';
import '../models/sale_model.dart';
import 'record_sale_screen.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  final SaleController controller = Get.find<SaleController>();

  late final Stream<List<SaleModel>> _sales = controller.salesStream;

  void _add() => Get.to(() => const RecordSaleScreen());

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
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: AddFab(
        heroTag: 'sales-fab',
        label: 'New sale',
        onPressed: _add,
      ),
      body: StreamBuilder<List<SaleModel>>(
        stream: _sales,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final receipts = _groupByReceipt(snapshot.data!);
          if (receipts.isEmpty) {
            return EmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'No sales yet',
              message:
                  'Record your first sale to start tracking revenue '
                  'and profit.',
              actionLabel: 'New sale',
              onAction: _add,
            );
          }

          return GroupedListView(
            sections: [
              for (final (day, items) in groupByDay(
                receipts,
                (r) => r.first.date,
              ))
                ListSection(
                  title: dayLabel(day),
                  trailing: MoneyText(
                    items.fold(0.0, (sum, r) => sum + _total(r)),
                  ),
                  rows: [for (final r in items) _ReceiptRow(lines: r)],
                ),
            ],
          );
        },
      ),
    );
  }

  static double _total(List<SaleModel> lines) =>
      lines.fold(0, (sum, s) => sum + s.totalAmount);

  /// Groups line items into receipts, keeping the newest-first order of
  /// [sales] (lines of one receipt share a timestamp, so stay adjacent).
  List<List<SaleModel>> _groupByReceipt(List<SaleModel> sales) {
    final byReceipt = <String, List<SaleModel>>{};
    for (final sale in sales) {
      final key = sale.receiptId.isEmpty ? sale.id : sale.receiptId;
      byReceipt.putIfAbsent(key, () => []).add(sale);
    }
    return byReceipt.values.toList();
  }
}

/// One checkout: a single item, or several items on one receipt. Tapping
/// opens the receipt.
class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.lines});

  final List<SaleModel> lines;

  @override
  Widget build(BuildContext context) {
    final first = lines.first;
    final total = lines.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final profit = lines.fold<double>(0, (sum, s) => sum + s.profit);
    final single = lines.length == 1;
    final pending = lines.any((s) => s.isPendingSync);
    final customer = first.customerName;

    final title = single
        ? first.productName
        : '${lines.length} items · ${lines.map((s) => s.productName).join(', ')}';

    return ListRow(
      onTap: () =>
          Get.to(() => ReceiptScreen(receipt: Receipt.fromSales(lines))),
      leading: RowIcon(
        single
            ? (first.isService
                  ? Icons.handyman_outlined
                  : Icons.shopping_bag_outlined)
            : Icons.receipt_long_outlined,
      ),
      title: title,
      subtitle: Obx(() {
        final parts = [
          if (single)
            '${first.quantity} × ${AppFormatter.currency(first.sellingPrice)}'
          else
            '${lines.fold<int>(0, (sum, s) => sum + s.quantity)} units',
          if (customer != null) customer,
        ];
        return Row(
          children: [
            Flexible(
              child: Text(
                parts.join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (pending) ...[
              const SizedBox(width: 6),
              const Tooltip(
                message: 'Waiting to sync',
                child: Icon(Icons.cloud_upload_outlined, size: 14),
              ),
            ],
          ],
        );
      }),
      trailing: RowAmount(
        total,
        caption: () =>
            '${profit >= 0 ? '+' : ''}${AppFormatter.currency(profit)} profit',
        captionColor: profit >= 0 ? AppColors.income : AppColors.expense,
      ),
    );
  }
}
