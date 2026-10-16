import '../../products/models/product_model.dart';
import '../../services/models/service_model.dart';

/// One line in an in-progress checkout: a product or a service.
class CartItem {
  /// Set for a product line; null for a service line.
  final ProductModel? product;

  /// Set for a service line; null for a product line.
  final ServiceModel? service;
  final int quantity;

  /// Price per unit/job for this sale. Products always sell at their
  /// selling price; a service's price can be changed at checkout.
  final double unitPrice;

  CartItem({required ProductModel this.product, required this.quantity})
    : service = null,
      unitPrice = product.sellingPrice;

  CartItem.service({
    required ServiceModel this.service,
    required this.quantity,
    double? unitPrice,
  }) : product = null,
       unitPrice = unitPrice ?? service.price;

  const CartItem._({
    required this.product,
    required this.service,
    required this.quantity,
    required this.unitPrice,
  });

  bool get isService => service != null;

  String get name => product?.name ?? service!.name;

  /// Unique within a cart, so adding the same item twice merges lines.
  String get key =>
      product != null ? 'product:${product!.id}' : 'service:${service!.id}';

  double get total => unitPrice * quantity;

  /// Materials cost of a service line. Product lines are costed from
  /// their purchase batches at checkout instead.
  double get serviceCost => (service?.materialsCost ?? 0) * quantity;

  CartItem copyWith({ProductModel? product, int? quantity, double? unitPrice}) {
    final newProduct = product ?? this.product;
    return CartItem._(
      product: newProduct,
      service: service,
      quantity: quantity ?? this.quantity,
      // A product's price follows its latest selling price.
      unitPrice: newProduct != null
          ? newProduct.sellingPrice
          : unitPrice ?? this.unitPrice,
    );
  }
}
