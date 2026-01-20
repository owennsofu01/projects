import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../controllers/sale_controller.dart';
import '../models/product-model.dart';

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

  void recordSale() {
    if (!formKey.currentState!.validate()) return;
    if (selectedProduct == null) {
      Get.snackbar('Error', 'Select a product');
      return;
    }

    final int quantity = int.parse(qtyCtrl.text);

    if (quantity > selectedProduct!.stock) {
      Get.snackbar('Error', 'Insufficient stock');
      return;
    }

    saleController.recordSale(selectedProduct!, quantity);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Sale'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              // Product dropdown
              Obx(() {
                return DropdownButtonFormField<ProductModel>(
                  value: selectedProduct,
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
                  decoration: _decoration('Product'),
                );
              }),

              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid number';
                  if (int.parse(value) <= 0) return 'Must be greater than 0';
                  return null;
                },
                decoration: _decoration('Quantity Sold'),
              ),

              const SizedBox(height: 16),

              // Price preview
              if (selectedProduct != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Selling Price', selectedProduct!.sellingPrice),
                        _row('Available Stock', selectedProduct!.stock),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: recordSale,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'RECORD SALE',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
