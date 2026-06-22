import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/empty_state.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatelessWidget {
  ProductListScreen({super.key});

  final ProductController controller = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(
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
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _info('Cost', product.costPrice),
                        _info('Selling', product.sellingPrice),
                        _info('Stock', product.stock),
                      ],
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

  Widget _info(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
