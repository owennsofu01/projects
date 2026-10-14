import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/scanner/barcode_scanner_screen.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class AddProductScreen extends StatelessWidget {
  AddProductScreen({super.key, this.product});

  /// When set, the screen edits this product instead of creating a new one.
  final ProductModel? product;

  final ProductController controller = Get.find<ProductController>();

  late final TextEditingController nameCtrl = TextEditingController(
    text: product?.name,
  );
  late final TextEditingController costCtrl = TextEditingController(
    text: product?.costPrice.toStringAsFixed(2),
  );
  late final TextEditingController sellingCtrl = TextEditingController(
    text: product?.sellingPrice.toStringAsFixed(2),
  );
  late final TextEditingController stockCtrl = TextEditingController(
    text: product?.stock.toString(),
  );
  late final TextEditingController barcodeCtrl = TextEditingController(
    text: product?.barcode,
  );
  late final TextEditingController reorderCtrl = TextEditingController(
    text: (product?.reorderLevel ?? ProductModel.lowStockThreshold).toString(),
  );

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool get isEditing => product != null;

  Future<void> _scanBarcode() async {
    final code = await Get.to<String>(() => const BarcodeScannerScreen());
    if (code != null) barcodeCtrl.text = code;
  }

  Future<void> _saveProduct() async {
    if (!formKey.currentState!.validate()) return;

    final barcode = barcodeCtrl.text.trim();
    final clash = controller.findByBarcode(barcode);
    if (clash != null && clash.id != product?.id) {
      showErrorSnackbar('${clash.name} already uses barcode $barcode');
      return;
    }

    final existing = product;
    final now = DateTime.now();
    final newCostPrice = double.parse(costCtrl.text);
    bool success;

    if (existing == null) {
      success = await controller.addProduct(
        ProductModel(
          id: '',
          name: nameCtrl.text.trim(),
          costPrice: newCostPrice,
          sellingPrice: double.parse(sellingCtrl.text),
          stock: int.parse(stockCtrl.text),
          reorderLevel: int.parse(reorderCtrl.text),
          barcode: barcode,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      success = await controller.updateProduct(
        ProductModel(
          id: existing.id,
          name: nameCtrl.text.trim(),
          costPrice: newCostPrice,
          sellingPrice: double.parse(sellingCtrl.text),
          stock: existing.stock,
          reorderLevel: int.parse(reorderCtrl.text),
          barcode: barcode,
          createdAt: existing.createdAt,
          updatedAt: now,
        ),
      );

      final newStock = int.parse(stockCtrl.text);
      if (success && newStock != existing.stock) {
        success = await controller.updateStock(
          existing.id,
          newStock,
          newCostPrice,
        );
      }
    }

    if (success) {
      Get.back();
      showSuccessSnackbar(
        isEditing
            ? 'Product updated successfully'
            : 'Product added successfully',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Product' : 'Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              AppTextField(
                controller: nameCtrl,
                label: 'Product Name',
                icon: Icons.inventory,
              ),
              AppTextField(
                controller: costCtrl,
                label: 'Cost Price',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: FormValidators.positiveNumber,
              ),
              AppTextField(
                controller: sellingCtrl,
                label: 'Selling Price',
                icon: Icons.price_check,
                keyboardType: TextInputType.number,
                validator: FormValidators.positiveNumber,
              ),
              AppTextField(
                controller: stockCtrl,
                label: isEditing
                    ? 'Stock Quantity (correction — use Restock for purchases)'
                    : 'Stock Quantity',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: isEditing
                    ? FormValidators.nonNegativeInteger
                    : FormValidators.positiveInteger,
              ),
              AppTextField(
                controller: reorderCtrl,
                label: 'Low-stock alert at (units left)',
                icon: Icons.notifications_active_outlined,
                keyboardType: TextInputType.number,
                validator: FormValidators.nonNegativeInteger,
              ),
              AppTextField(
                controller: barcodeCtrl,
                label: 'Barcode (optional)',
                icon: Icons.qr_code_2,
                validator: (_) => null,
                suffixIcon: IconButton(
                  tooltip: 'Scan barcode',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => AppPrimaryButton(
                  label: isEditing ? 'SAVE CHANGES' : 'SAVE PRODUCT',
                  isLoading: controller.isSaving.value,
                  onPressed: _saveProduct,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
