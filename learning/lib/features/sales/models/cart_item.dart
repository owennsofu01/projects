import '../../products/models/product_model.dart';

/// One product line in an in-progress checkout.
class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get total => product.sellingPrice * quantity;

  CartItem copyWith({ProductModel? product, int? quantity}) => CartItem(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
  );
}
