import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../models/stock_batch_model.dart';

Future<void> showPurchaseHistorySheet(
  BuildContext context,
  ProductController controller,
  ProductModel product,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PurchaseHistorySheet(
      controller: controller,
      product: product,
    ),
  );
}

class _PurchaseHistorySheet extends StatelessWidget {
  const _PurchaseHistorySheet({required this.controller, required this.product});

  final ProductController controller;
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purchase History',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                product.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<StockBatchModel>>(
                  stream: controller.batchesFor(product.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final batches = snapshot.data!;
                    if (batches.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'No purchase batches recorded yet',
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: batches.length,
                      separatorBuilder: (_, _) => const Divider(height: 20),
                      itemBuilder: (context, index) =>
                          _BatchRow(batch: batches[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.batch});

  final StockBatchModel batch;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final soldOut = batch.remainingQuantity <= 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppFormatter.date(batch.purchasedAt),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${batch.quantity} purchased @ ${AppFormatter.currency(batch.costPrice)}/unit',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          soldOut ? 'Sold out' : '${batch.remainingQuantity} left',
          style: textTheme.bodySmall?.copyWith(
            color: soldOut ? colorScheme.onSurfaceVariant : colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
