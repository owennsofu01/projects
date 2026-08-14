import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/sale_controller.dart';
import '../models/sale_model.dart';
import 'record_sale_screen.dart';

class SaleListScreen extends StatelessWidget {
  SaleListScreen({super.key});

  final SaleController controller = Get.find<SaleController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
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

          final sales = snapshot.data!;

          if (sales.isEmpty) {
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
                    itemCount: sales.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sale = sales[index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.point_of_sale),
                          title: Text(sale.productName),
                          subtitle: Obx(
                            () => Text(
                              '${sale.quantity} × ${AppFormatter.currency(sale.sellingPrice)}'
                              '  •  ${AppFormatter.date(sale.date)}',
                            ),
                          ),
                          trailing: Obx(
                            () => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  AppFormatter.currency(sale.totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '+${AppFormatter.currency(sale.profit)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.income,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
