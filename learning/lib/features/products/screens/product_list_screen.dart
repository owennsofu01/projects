import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/add_fab.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/list_row.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../widgets/purchase_history_sheet.dart';
import 'add_product_screen.dart';

/// The Products tab of the catalog. Shown without its own app bar.
class ProductListScreen extends StatelessWidget {
  ProductListScreen({super.key});

  final ProductController controller = Get.find<ProductController>();

  void _add() => Get.to(() => AddProductScreen());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AddFab(
        heroTag: 'products-fab',
        label: 'Add product',
        onPressed: _add,
      ),
      body: Obx(() {
        final products = controller.products;
        if (products.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products yet',
            message:
                'Add what you sell with its cost and price to start '
                'tracking stock and profit.',
            actionLabel: 'Add product',
            onAction: _add,
          );
        }

        final attention = products.where((p) => p.needsAttention).toList();
        final rest = products.where((p) => !p.needsAttention).toList();

        return GroupedListView(
          sections: [
            if (attention.isNotEmpty)
              ListSection(
                title: 'Needs restocking',
                trailing: Text('${attention.length}'),
                rows: [for (final p in attention) _row(context, p)],
              ),
            if (rest.isNotEmpty)
              ListSection(
                title: attention.isEmpty ? 'All products' : 'In stock',
                trailing: Text('${rest.length}'),
                rows: [for (final p in rest) _row(context, p)],
              ),
          ],
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
            child: const Text('Add stock'),
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

  Future<void> _deleteProduct(
    BuildContext context,
    ProductModel product,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${product.name}?',
      message:
          'This removes the product and its purchase history. This can\'t be undone.',
    );
    if (!confirmed) return;

    final success = await controller.deleteProduct(product.id);
    if (success) {
      showSuccessSnackbar('${product.name} deleted');
    }
  }

  Widget _row(BuildContext context, ProductModel product) {
    final stockColor = product.isOutOfStock
        ? AppColors.expense
        : product.isLowStock
        ? AppColors.warning
        : null;

    return ListRow(
      onTap: () => Get.to(() => AddProductScreen(product: product)),
      leading: RowAvatar(product.name),
      title: product.name,
      subtitle: Obx(
        () => Text(
          'Sells ${AppFormatter.currency(product.sellingPrice)}'
          '  ·  Cost ${AppFormatter.currency(product.costPrice)}',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          product.needsAttention
              ? StatusPill(
                  product.isOutOfStock ? 'Out' : '${product.stock} left',
                  color: stockColor!,
                  icon: Icons.warning_amber_rounded,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${product.stock}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'in stock',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
          PopupMenuButton<_ProductAction>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (action) {
              switch (action) {
                case _ProductAction.restock:
                  _showRestockDialog(context, controller, product);
                case _ProductAction.history:
                  showPurchaseHistorySheet(context, controller, product);
                case _ProductAction.edit:
                  Get.to(() => AddProductScreen(product: product));
                case _ProductAction.delete:
                  _deleteProduct(context, product);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ProductAction.restock,
                child: ListTile(
                  leading: Icon(Icons.add_box_outlined),
                  title: Text('Restock'),
                ),
              ),
              PopupMenuItem(
                value: _ProductAction.history,
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Purchase history'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _ProductAction.edit,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: _ProductAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ProductAction { restock, history, edit, delete }
