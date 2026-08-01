import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../products/controllers/product_controller.dart';
import '../../products/models/product_model.dart';
import '../controllers/sale_controller.dart';

class RecordSaleScreen extends StatefulWidget {
  const RecordSaleScreen({super.key});

  @override
  State<RecordSaleScreen> createState() => _RecordSaleScreenState();
}

class _RecordSaleScreenState extends State<RecordSaleScreen> {
  final ProductController productController = Get.find<ProductController>();
  final SaleController saleController = Get.find<SaleController>();

  final TextEditingController qtyCtrl = TextEditingController();
  ProductModel? selectedProduct;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> _recordSale() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedProduct == null) {
      showErrorSnackbar('Select a product');
      return;
    }

    final int quantity = int.parse(qtyCtrl.text);

    if (quantity > selectedProduct!.stock) {
      showErrorSnackbar('Insufficient stock');
      return;
    }

    final success = await saleController.recordSale(selectedProduct!, quantity);
    if (success) {
      Get.back();
      showSuccessSnackbar('Sale recorded');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Sale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              Obx(() {
                return DropdownButtonFormField<ProductModel>(
                  initialValue: selectedProduct,
                  hint: const Text('Select Product'),
                  items: productController.products
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text('${p.name} (Stock: ${p.stock})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedProduct = value);
                  },
                  validator: (value) =>
                      value == null ? 'Select a product' : null,
                  decoration: const InputDecoration(labelText: 'Product'),
                );
              }),

              const SizedBox(height: 16),

              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                validator: FormValidators.positiveInteger,
                decoration: const InputDecoration(labelText: 'Quantity Sold'),
              ),

              const SizedBox(height: 16),

              if (selectedProduct != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => _row(
                            'Selling Price',
                            AppFormatter.currency(selectedProduct!.sellingPrice),
                          ),
                        ),
                        _row('Available Stock', '${selectedProduct!.stock}'),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              Obx(
                () => AppPrimaryButton(
                  label: 'RECORD SALE',
                  isLoading: saleController.isSaving.value,
                  onPressed: _recordSale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
