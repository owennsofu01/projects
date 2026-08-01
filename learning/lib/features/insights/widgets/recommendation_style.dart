import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/product_insight.dart';

class RecommendationStyle {
  const RecommendationStyle(this.color, this.icon);
  final Color color;
  final IconData icon;
}

const recommendationStyles = {
  StockRecommendation.restock: RecommendationStyle(
    AppColors.expense,
    Icons.local_shipping_outlined,
  ),
  StockRecommendation.promote: RecommendationStyle(
    AppColors.income,
    Icons.trending_up_rounded,
  ),
  StockRecommendation.reduce: RecommendationStyle(
    AppColors.warning,
    Icons.trending_down_rounded,
  ),
  StockRecommendation.maintain: RecommendationStyle(
    AppColors.profit,
    Icons.check_circle_outline_rounded,
  ),
};
