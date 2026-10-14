import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../ads/ads_manager.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../products/controllers/product_controller.dart';
import '../../products/models/product_model.dart';
import '../controllers/sale_controller.dart';
import '../models/cart_item.dart';

/// Checkout screen: build a cart of one or more products, then record them
/// all as one sale (one receipt).
class RecordSaleScreen extends StatefulWidget {
  const RecordSaleScreen({super.key});

  @override
  State<RecordSaleScreen> createState() => _RecordSaleScreenState();
}

class _RecordSaleScreenState extends State<RecordSaleScreen> {
  final ProductController productController = Get.find<ProductController>();
  final SaleController saleController = Get.find<SaleController>();

  /// Keyed by product id so adding the same product twice merges lines.
  final Map<String, CartItem> _cart = {};

  double get _total => _cart.values.fold(0, (sum, item) => sum + item.total);
  int get _unitCount =>
      _cart.values.fold(0, (sum, item) => sum + item.quantity);

  /// The latest version of [product] from the live product list, so stock
  /// limits reflect sales made elsewhere while this screen is open.
  ProductModel _live(ProductModel product) =>
      productController.products.firstWhereOrNull((p) => p.id == product.id) ??
      product;

  void _add(ProductModel product) {
    final live = _live(product);
    final inCart = _cart[live.id]?.quantity ?? 0;
    if (inCart >= live.stock) {
      showErrorSnackbar('Only ${live.stock} ${live.name} in stock');
      return;
    }
    setState(() {
      _cart[live.id] = CartItem(product: live, quantity: inCart + 1);
    });
  }

  void _setQuantity(String productId, int quantity) {
    final item = _cart[productId];
    if (item == null) return;
    final live = _live(item.product);

    setState(() {
      if (quantity <= 0) {
        _cart.remove(productId);
      } else {
        if (quantity > live.stock) {
          showErrorSnackbar('Only ${live.stock} ${live.name} in stock');
        }
        _cart[productId] = item.copyWith(
          product: live,
          quantity: quantity.clamp(1, live.stock),
        );
      }
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      showErrorSnackbar('Add at least one product');
      return;
    }

    final items = [
      for (final item in _cart.values)
        item.copyWith(product: _live(item.product)),
    ];
    final success = await saleController.checkout(items);
    if (!success) return;

    Get.back();
    _showResult(items);
    Get.find<InterstitialAdController>().maybeShowAfterAction();
  }

  void _showResult(List<CartItem> items) {
    final outOfStock = <String>[];
    final low = <String>[];
    for (final item in items) {
      final remaining = item.product.stock - item.quantity;
      if (remaining <= 0) {
        outOfStock.add(item.product.name);
      } else if (remaining <= item.product.reorderLevel) {
        low.add('${item.product.name} ($remaining left)');
      }
    }

    if (outOfStock.isEmpty && low.isEmpty) {
      showSuccessSnackbar(
        'Sale recorded — ${AppFormatter.currency(_totalOf(items))}',
      );
      return;
    }

    showWarningSnackbar(
      outOfStock.isNotEmpty ? 'Out of stock' : 'Time to reorder',
      [
        'Sale recorded.',
        if (outOfStock.isNotEmpty)
          'Now out of stock: ${outOfStock.join(', ')}.',
        if (low.isNotEmpty) 'Running low: ${low.join(', ')}.',
      ].join(' '),
    );
  }

  double _totalOf(List<CartItem> items) =>
      items.fold(0, (sum, item) => sum + item.total);

  Future<void> _openPicker() async {
    final product = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProductPicker(
        products: productController.products,
        inCart: {for (final e in _cart.entries) e.key: e.value.quantity},
      ),
    );
    if (product != null) _add(product);
  }

  Future<void> _editQuantity(CartItem item) async {
    final ctrl = TextEditingController(text: item.quantity.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.product.name),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Quantity',
            helperText: '${_live(item.product).stock} in stock',
          ),
          onSubmitted: (value) =>
              Navigator.of(context).pop(int.tryParse(value)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(int.tryParse(ctrl.text)),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null) _setQuantity(item.product.id, result);
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    message: 'Add products to start a sale',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openPicker,
                    icon: const Icon(Icons.add),
                    label: const Text('Add product'),
                  ),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final item in items) ...[
                      _CartLine(
                        item: item,
                        onIncrement: () => _add(item.product),
                        onDecrement: () =>
                            _setQuantity(item.product.id, item.quantity - 1),
                        onRemove: () => _setQuantity(item.product.id, 0),
                        onEditQuantity: () => _editQuantity(item),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: _openPicker,
                      icon: const Icon(Icons.add),
                      label: const Text('Add another product'),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _CheckoutBar(
              lineCount: items.length,
              unitCount: _unitCount,
              total: _total,
              saleController: saleController,
              onCheckout: _checkout,
            ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onEditQuantity,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback onEditQuantity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppFormatter.currency(item.product.sellingPrice)} each',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppFormatter.currency(item.total),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: item.quantity == 1 ? 'Remove' : 'Decrease',
                onPressed: onDecrement,
                icon: Icon(
                  item.quantity == 1
                      ? Icons.delete_outline
                      : Icons.remove_circle_outline,
                ),
              ),
              InkWell(
                onTap: onEditQuantity,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Increase',
                onPressed: onIncrement,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.lineCount,
    required this.unitCount,
    required this.total,
    required this.saleController,
    required this.onCheckout,
  });

  final int lineCount;
  final int unitCount;
  final double total;
  final SaleController saleController;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      color: colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '$lineCount product${lineCount == 1 ? '' : 's'} · '
                    '$unitCount unit${unitCount == 1 ? '' : 's'}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => Text(
                      AppFormatter.currency(total),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(
                () => AppPrimaryButton(
                  label: 'COMPLETE SALE',
                  isLoading: saleController.isSaving.value,
                  onPressed: onCheckout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Searchable product list; pops with the tapped product.
class _ProductPicker extends StatefulWidget {
  const _ProductPicker({required this.products, required this.inCart});

  final List<ProductModel> products;
  final Map<String, int> inCart;

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _query.trim().toLowerCase();
    final products =
        widget.products
            .where((p) => p.name.toLowerCase().contains(query))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: widget.products.length > 8,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search products',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    message: 'No matching products',
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final inCart = widget.inCart[product.id] ?? 0;
                      final available = product.stock - inCart;
                      final enabled = available > 0;

                      return ListTile(
                        enabled: enabled,
                        onTap: () => Navigator.of(context).pop(product),
                        title: Text(product.name),
                        subtitle: Text(
                          product.stock <= 0
                              ? 'Out of stock'
                              : '${product.stock} in stock'
                                    '${inCart > 0 ? ' · $inCart in cart' : ''}',
                          style: TextStyle(
                            color: product.needsAttention
                                ? colorScheme.error
                                : null,
                          ),
                        ),
                        trailing: Obx(
                          () => Text(
                            AppFormatter.currency(product.sellingPrice),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
