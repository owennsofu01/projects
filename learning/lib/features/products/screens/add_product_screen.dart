import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

class AddProductScreen extends StatelessWidget {
  AddProductScreen({super.key});

  final ProductController controller = Get.find<ProductController>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
  final TextEditingController sellingCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> _saveProduct() async {
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

    final success = await controller.addProduct(product);
    if (success) {
      Get.back();
      showSuccessSnackbar('Product added successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
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
                label: 'Stock Quantity',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: FormValidators.positiveInteger,
              ),
              const SizedBox(height: 24),
              Obx(
                () => AppPrimaryButton(
                  label: 'SAVE PRODUCT',
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
