import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../models/product-model.dart';

class AddProductScreen extends StatelessWidget {
  AddProductScreen({super.key});

  final ProductController controller = Get.find<ProductController>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
  final TextEditingController sellingCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void saveProduct() {
    if (!formKey.currentState!.validate()) return;

    final product = ProductModel(
      id: '',
      name: nameCtrl.text.trim(),
      costPrice: double.parse(costCtrl.text),
      sellingPrice: double.parse(sellingCtrl.text),
      stock: int.parse(stockCtrl.text),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    controller.addProduct(product);

    Get.back();
    Get.snackbar('Success', 'Product added successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              _input(
                controller: nameCtrl,
                label: 'Product Name',
                icon: Icons.inventory,
              ),
              _input(
                controller: costCtrl,
                label: 'Cost Price',
                icon: Icons.attach_money,
                keyboard: TextInputType.number,
              ),
              _input(
                controller: sellingCtrl,
                label: 'Selling Price',
                icon: Icons.price_check,
                keyboard: TextInputType.number,
              ),
              _input(
                controller: stockCtrl,
                label: 'Stock Quantity',
                icon: Icons.numbers,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'SAVE PRODUCT',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
