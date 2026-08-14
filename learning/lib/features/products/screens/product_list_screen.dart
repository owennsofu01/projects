import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../widgets/purchase_history_sheet.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatelessWidget {
  ProductListScreen({super.key});

  final ProductController controller = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'products-fab',
        onPressed: () => Get.to(() => AddProductScreen()),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.products.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'No products added yet',
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // A catalog of self-contained cards makes good use of extra
            // width, unlike a chronological list — so widen into columns
            // on tablet/desktop instead of just capping the line length.
            final columns = constraints.maxWidth >= 1100
                ? 3
                : (constraints.maxWidth >= 700 ? 2 : 1);
            final horizontalPadding = constraints.maxWidth >= 600
                ? 24.0
                : 16.0;

            final products = controller.products;
            final rowCount = (products.length / columns).ceil();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  itemCount: rowCount,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, rowIndex) {
                    final start = rowIndex * columns;
                    final rowProducts = products.skip(start).take(columns);

                    if (columns == 1) {
                      return _productCard(context, rowProducts.first);
                    }

                    // IntrinsicHeight + stretch so every card in the row
                    // shares the tallest card's height (e.g. one with a
                    // low-stock chip and one without), matching how a
                    // real grid lays out unevenly-tall cells.
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final product in rowProducts) ...[
                            if (product != rowProducts.first)
                              const SizedBox(width: 12),
                            Expanded(child: _productCard(context, product)),
                          ],
                          for (var i = rowProducts.length; i < columns; i++)
                            const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _showRestockDialog(
    BuildContext context,
    ProductController controller,
    ProductModel product,
  ) async {
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController(
      text: product.costPrice.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<(int, double)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restock ${product.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Quantity to add',
                  prefixIcon: Icon(Icons.add_box_outlined),
                ),
                validator: FormValidators.positiveInteger,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: costCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Cost per unit (this batch)',
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Purchase batches can have different costs',
                ),
                validator: FormValidators.positiveNumber,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop((
                  int.parse(qtyCtrl.text.trim()),
                  double.parse(costCtrl.text.trim()),
                ));
              }
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final (quantity, costPrice) = result;

    final success = await controller.restockProduct(
      product.id,
      quantity,
      costPrice,
    );
    if (success) {
      showSuccessSnackbar('Added $quantity to ${product.name}\'s stock');
    }
  }

  Widget _productCard(BuildContext context, ProductModel product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      showPurchaseHistorySheet(context, controller, product),
                  icon: const Icon(Icons.history),
                  tooltip: 'Purchase history',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton.filledTonal(
                  onPressed: () =>
                      _showRestockDialog(context, controller, product),
                  icon: const Icon(Icons.add_box_outlined),
                  tooltip: 'Restock',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (product.needsAttention) ...[
              const SizedBox(height: 4),
              _StockStatusChip(product: product),
            ],
            const SizedBox(height: 8),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _info('Latest Cost', AppFormatter.currency(product.costPrice)),
                  _info(
                    'Selling',
                    AppFormatter.currency(product.sellingPrice),
                  ),
                  _info('Stock', product.stock.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StockStatusChip extends StatelessWidget {
  const _StockStatusChip({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final isOut = product.isOutOfStock;
    final color = isOut ? AppColors.expense : AppColors.warning;
    final label = isOut ? 'Out of stock' : '${product.stock} left — low stock';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
