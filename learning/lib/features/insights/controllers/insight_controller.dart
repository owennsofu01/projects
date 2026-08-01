import 'dart:async';

import 'package:get/get.dart';

import '../../products/controllers/product_controller.dart';
import '../../products/models/product_model.dart';
import '../models/product_insight.dart';
import '../services/insight_service.dart';

/// Rule-based Stock Intelligence engine: turns recent sales velocity +
/// current stock into a Restock/Promote/Reduce/Maintain call per product.
///
/// This is deliberately a transparent heuristic, not a trained model —
/// each recommendation carries the plain-language reason it fired, so the
/// "why" is always visible rather than a black box.
class InsightController extends GetxController {
  /// How far back sales are looked at to estimate current velocity.
  static const lookbackDays = 30;

  /// At or below this many days of projected stock left, restock now.
  static const restockDaysThreshold = 7.0;

  /// Beyond this many days of projected stock, capital is sitting idle.
  static const overstockDaysThreshold = 60.0;

  /// Share of profitable sellers (by profit, ranked) called out as
  /// "Promote" rather than just "Maintain".
  static const promoteShare = 0.2;

  final ProductController _productController = Get.find<ProductController>();
  final InsightService _service = InsightService();
  final String userId;

  InsightController(this.userId);

  final RxList<ProductInsight> insights = <ProductInsight>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<Map<String, ProductSalesAggregate>>? _salesSub;
  Map<String, ProductSalesAggregate> _salesByProduct = {};
  Worker? _productsWorker;

  int get restockCount => insights
      .where((i) => i.recommendation == StockRecommendation.restock)
      .length;

  @override
  void onInit() {
    super.onInit();
    _salesSub = _service
        .salesByProductSince(userId, days: lookbackDays)
        .listen((data) {
          _salesByProduct = data;
          _recompute();
        });
    _productsWorker = ever(_productController.products, (_) => _recompute());
    _recompute();
  }

  @override
  void onClose() {
    _salesSub?.cancel();
    _productsWorker?.dispose();
    super.onClose();
  }

  void _recompute() {
    final products = _productController.products;
    if (products.isEmpty) {
      insights.value = [];
      isLoading.value = false;
      return;
    }

    final analyzed = [
      for (final product in products) _analyze(product, _salesByProduct[product.id]),
    ];

    final promoteIds = _topPerformerIds(analyzed);

    insights.value = analyzed
        .map((i) => promoteIds.contains(i.productId) ? _promote(i) : i)
        .toList()
      ..sort(_byUrgency);

    isLoading.value = false;
  }

  /// Among products still classed "maintain" (i.e. not already flagged for
  /// restock/reduce), the top [promoteShare] by profit are worth calling
  /// out as performers to lean into.
  Set<String> _topPerformerIds(List<ProductInsight> analyzed) {
    final candidates =
        analyzed
            .where(
              (i) =>
                  i.recommendation == StockRecommendation.maintain &&
                  i.profit > 0,
            )
            .toList()
          ..sort((a, b) => b.profit.compareTo(a.profit));

    final count = (candidates.length * promoteShare).ceil();
    return candidates.take(count).map((i) => i.productId).toSet();
  }

  ProductInsight _promote(ProductInsight insight) {
    return ProductInsight(
      productId: insight.productId,
      productName: insight.productName,
      stock: insight.stock,
      unitsSold: insight.unitsSold,
      revenue: insight.revenue,
      profit: insight.profit,
      velocityPerDay: insight.velocityPerDay,
      daysOfStockRemaining: insight.daysOfStockRemaining,
      recommendation: StockRecommendation.promote,
      reason:
          'One of your top earners — ${insight.unitsSold} sold in the last '
          '$lookbackDays days with strong profit contribution',
    );
  }

  int _byUrgency(ProductInsight a, ProductInsight b) {
    const order = {
      StockRecommendation.restock: 0,
      StockRecommendation.promote: 1,
      StockRecommendation.reduce: 2,
      StockRecommendation.maintain: 3,
    };
    return order[a.recommendation]!.compareTo(order[b.recommendation]!);
  }

  ProductInsight _analyze(ProductModel product, ProductSalesAggregate? sales) {
    final agg = sales ?? ProductSalesAggregate.zero;
    final velocity = agg.quantity / lookbackDays;
    final daysOfStock = velocity > 0 ? product.stock / velocity : null;

    final StockRecommendation recommendation;
    final String reason;

    if (product.isOutOfStock) {
      recommendation = StockRecommendation.restock;
      reason = agg.quantity > 0
          ? 'Out of stock — sold ${agg.quantity} in the last $lookbackDays days'
          : 'Out of stock';
    } else if (daysOfStock != null && daysOfStock <= restockDaysThreshold) {
      recommendation = StockRecommendation.restock;
      final days = daysOfStock.round();
      reason =
          'Only ~$days day${days == 1 ? '' : 's'} of stock left at the '
          'current sales pace';
    } else if (agg.quantity == 0) {
      recommendation = StockRecommendation.reduce;
      reason =
          'No sales in the last $lookbackDays days — ${product.stock} '
          'units tied up in stock';
    } else if (daysOfStock != null && daysOfStock > overstockDaysThreshold) {
      recommendation = StockRecommendation.reduce;
      reason =
          'Overstocked — about ${daysOfStock.round()} days of stock at '
          'the current sales pace';
    } else {
      recommendation = StockRecommendation.maintain;
      reason =
          '${agg.quantity} sold in the last $lookbackDays days — '
          'performing steadily';
    }

    return ProductInsight(
      productId: product.id,
      productName: product.name,
      stock: product.stock,
      unitsSold: agg.quantity,
      revenue: agg.revenue,
      profit: agg.profit,
      velocityPerDay: velocity,
      daysOfStockRemaining: daysOfStock,
      recommendation: recommendation,
      reason: reason,
    );
  }
}
