/// One row of the all-time product profitability table: a product joined
/// with its cumulative sales activity.
class ProductProfitRow {
  final String productId;
  final String productName;
  final int stock;
  final double costPrice;
  final double sellingPrice;
  final int unitsSold;
  final double profit;

  const ProductProfitRow({
    required this.productId,
    required this.productName,
    required this.stock,
    required this.costPrice,
    required this.sellingPrice,
    required this.unitsSold,
    required this.profit,
  });

  /// Cost tied up in the remaining [stock] at the current unit cost — what
  /// it would take to replace it, or what's still "on the shelf" in cost
  /// terms.
  double get totalCost => costPrice * stock;

  /// Profit still on the table if the remaining [stock] all sold at the
  /// current selling price — a forward-looking projection, unlike [profit]
  /// which is what's already been realized from past sales.
  double get expectedProfit => (sellingPrice - costPrice) * stock;
}
