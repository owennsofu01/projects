/// What the business should do about a product, based on its recent sales
/// pace relative to how much stock is on hand.
enum StockRecommendation { restock, promote, reduce, maintain }

extension StockRecommendationLabel on StockRecommendation {
  String get label => switch (this) {
    StockRecommendation.restock => 'Restock',
    StockRecommendation.promote => 'Promote',
    StockRecommendation.reduce => 'Reduce',
    StockRecommendation.maintain => 'Maintain',
  };

  String get description => switch (this) {
    StockRecommendation.restock => 'Selling fast and running low — reorder soon',
    StockRecommendation.promote => 'A top performer — lean into it',
    StockRecommendation.reduce => 'Moving slowly — capital is tied up in this stock',
    StockRecommendation.maintain => 'Performing steadily — no action needed',
  };
}

/// A single product's computed sales/stock analysis over the lookback
/// window, plus the resulting recommendation and the plain-language reason
/// for it.
class ProductInsight {
  final String productId;
  final String productName;
  final int stock;
  final int unitsSold;
  final double revenue;
  final double profit;

  /// Units sold per day over the lookback window.
  final double velocityPerDay;

  /// How many more days the current stock lasts at [velocityPerDay]. Null
  /// when there's no sales velocity to project from (nothing sold, or out
  /// of stock already).
  final double? daysOfStockRemaining;

  final StockRecommendation recommendation;
  final String reason;

  const ProductInsight({
    required this.productId,
    required this.productName,
    required this.stock,
    required this.unitsSold,
    required this.revenue,
    required this.profit,
    required this.velocityPerDay,
    required this.daysOfStockRemaining,
    required this.recommendation,
    required this.reason,
  });
}
