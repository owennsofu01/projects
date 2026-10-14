import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../models/business_profile.dart';
import '../models/receipt.dart';

class ReceiptShareService {
  /// Plain-text receipt — works in any messaging app, including SMS.
  String toText(Receipt receipt, BusinessProfile business) {
    final buffer = StringBuffer();
    if (business.name.isNotEmpty) buffer.writeln(business.name);
    if (business.address.isNotEmpty) buffer.writeln(business.address);
    if (business.phone.isNotEmpty) buffer.writeln(business.phone);
    buffer
      ..writeln('Receipt #${receipt.number}')
      ..writeln('${AppFormatter.date(receipt.date)} ${time(receipt.date)}');
    if (receipt.customerName != null) {
      buffer.writeln('Customer: ${receipt.customerName}');
    }
    buffer.writeln('--------------------');
    for (final line in receipt.lines) {
      buffer.writeln(
        '${line.quantity} × ${line.name} @ '
        '${AppFormatter.currency(line.unitPrice)} = '
        '${AppFormatter.currency(line.total)}',
      );
    }
    buffer
      ..writeln('--------------------')
      ..writeln('TOTAL: ${AppFormatter.currency(receipt.total)}');
    if (receipt.creditAmount > 0) {
      buffer
        ..writeln('Paid: ${AppFormatter.currency(receipt.paid)}')
        ..writeln('On account: ${AppFormatter.currency(receipt.creditAmount)}');
    }
    buffer.writeln(business.footer.isNotEmpty ? business.footer : 'Thank you!');
    return buffer.toString().trimRight();
  }

  /// Renders the widget under [boundary] to a PNG and opens the share
  /// sheet with it.
  Future<void> shareImage(
    RenderRepaintBoundary boundary,
    Receipt receipt,
  ) async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw Exception('Could not create the receipt image');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt-${receipt.number}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: 'Receipt #${receipt.number}',
      ),
    );
  }

  Future<void> shareText(Receipt receipt, BusinessProfile business) {
    return SharePlus.instance.share(
      ShareParams(
        text: toText(receipt, business),
        subject: 'Receipt #${receipt.number}',
      ),
    );
  }

  /// 24-hour "HH:mm" for the receipt header.
  static String time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
