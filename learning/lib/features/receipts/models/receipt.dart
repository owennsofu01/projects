import '../../sales/models/cart_item.dart';
import '../../sales/models/sale_model.dart';

class ReceiptLine {
  final String name;
  final int quantity;
  final double unitPrice;

  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => unitPrice * quantity;
}

/// Everything needed to render or share one checkout's receipt, built
/// either from the cart just sold or from stored sale lines.
class Receipt {
  final String id;
  final DateTime date;
  final List<ReceiptLine> lines;
  final String? customerName;

  /// The part of [total] put on the customer's account rather than paid.
  final double creditAmount;

  const Receipt({
    required this.id,
    required this.date,
    required this.lines,
    this.customerName,
    this.creditAmount = 0,
  });

  double get total => lines.fold(0, (sum, line) => sum + line.total);
  double get paid => total - creditAmount;

  /// Short, human-friendly receipt number derived from the id.
  String get number =>
      id.substring(0, id.length < 8 ? id.length : 8).toUpperCase();

  factory Receipt.fromSales(List<SaleModel> sales) {
    final first = sales.first;
    return Receipt(
      id: first.receiptId,
      date: first.date,
      customerName: first.customerName,
      creditAmount: first.receiptCredit,
      lines: [
        for (final sale in sales)
          ReceiptLine(
            name: sale.productName,
            quantity: sale.quantity,
            unitPrice: sale.sellingPrice,
          ),
      ],
    );
  }

  factory Receipt.fromCart({
    required String id,
    required List<CartItem> items,
    String? customerName,
    double creditAmount = 0,
  }) {
    return Receipt(
      id: id,
      date: DateTime.now(),
      customerName: customerName,
      creditAmount: creditAmount,
      lines: [
        for (final item in items)
          ReceiptLine(
            name: item.product.name,
            quantity: item.quantity,
            unitPrice: item.product.sellingPrice,
          ),
      ],
    );
  }
}
