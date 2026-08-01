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

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ProductModel product = controller.products[index];

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
                          onPressed: () => showPurchaseHistorySheet(
                            context,
                            controller,
                            product,
                          ),
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
                          _info(
                            'Latest Cost',
                            AppFormatter.currency(product.costPrice),
                          ),
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
