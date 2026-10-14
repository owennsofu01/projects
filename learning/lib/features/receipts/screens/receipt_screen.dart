import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/business_profile_controller.dart';
import '../models/business_profile.dart';
import '../models/receipt.dart';
import '../services/receipt_share_service.dart';
import 'business_profile_screen.dart';

/// A printable-looking receipt for one checkout, shareable as an image
/// (best for WhatsApp) or as plain text.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.receipt});

  final Receipt receipt;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final BusinessProfileController businessController =
      Get.find<BusinessProfileController>();
  final ReceiptShareService _shareService = ReceiptShareService();
  final GlobalKey _paperKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareImage() async {
    final boundary =
        _paperKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    setState(() => _sharing = true);
    try {
      await _shareService.shareImage(boundary, widget.receipt);
    } catch (e) {
      showErrorSnackbar('Could not share the receipt. Please try again.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareText() async {
    try {
      await _shareService.shareText(
        widget.receipt,
        businessController.profile.value,
      );
    } catch (e) {
      showErrorSnackbar('Could not share the receipt. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #${widget.receipt.number}'),
        actions: [
          IconButton(
            tooltip: 'Business details',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => Get.to(() => BusinessProfileScreen()),
          ),
        ],
      ),
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              children: [
                Obx(() {
                  final business = businessController.profile.value;
                  return Column(
                    children: [
                      if (business.name.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text(
                                'Add your shop name to receipts',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  Get.to(() => BusinessProfileScreen()),
                            ),
                          ),
                        ),
                      RepaintBoundary(
                        key: _paperKey,
                        child: _ReceiptPaper(
                          receipt: widget.receipt,
                          business: business,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareText,
                  icon: const Icon(Icons.notes),
                  label: const Text('Share text'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _shareImage,
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_outlined),
                  label: const Text('Share image'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The receipt itself. Always black-on-white (even in dark mode) so the
/// shared image looks like a paper receipt.
class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper({required this.receipt, required this.business});

  final Receipt receipt;
  final BusinessProfile business;

  static const _ink = Color(0xFF111111);
  static const _muted = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(color: _ink, fontSize: 13, height: 1.35);
    const muted = TextStyle(color: _muted, fontSize: 12, height: 1.35);
    final bold = base.copyWith(fontWeight: FontWeight.w700);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Obx(
        // Obx so amounts follow the selected display currency.
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              business.name.isNotEmpty ? business.name : 'Receipt',
              textAlign: TextAlign.center,
              style: base.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (business.address.isNotEmpty)
              Text(business.address, textAlign: TextAlign.center, style: muted),
            if (business.phone.isNotEmpty)
              Text(business.phone, textAlign: TextAlign.center, style: muted),
            const SizedBox(height: 12),
            _row('Receipt #', receipt.number, base, base),
            _row(
              'Date',
              '${AppFormatter.date(receipt.date)} '
                  '${ReceiptShareService.time(receipt.date)}',
              base,
              base,
            ),
            if (receipt.customerName != null)
              _row('Customer', receipt.customerName!, base, base),
            const _Dashes(),
            for (final line in receipt.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(line.name, style: base),
                    _row(
                      '  ${line.quantity} × '
                      '${AppFormatter.currency(line.unitPrice)}',
                      AppFormatter.currency(line.total),
                      muted,
                      base,
                    ),
                  ],
                ),
              ),
            const _Dashes(),
            _row(
              'TOTAL',
              AppFormatter.currency(receipt.total),
              bold.copyWith(fontSize: 15),
              bold.copyWith(fontSize: 15),
            ),
            if (receipt.creditAmount > 0) ...[
              const SizedBox(height: 4),
              _row('Paid', AppFormatter.currency(receipt.paid), base, base),
              _row(
                'On account',
                AppFormatter.currency(receipt.creditAmount),
                base,
                bold,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              business.footer.isNotEmpty ? business.footer : 'Thank you!',
              textAlign: TextAlign.center,
              style: muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String left,
    String right,
    TextStyle leftStyle,
    TextStyle rightStyle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(left, style: leftStyle)),
        const SizedBox(width: 12),
        Text(right, style: rightStyle, textAlign: TextAlign.right),
      ],
    );
  }
}

class _Dashes extends StatelessWidget {
  const _Dashes();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 8).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => const SizedBox(
                width: 4,
                height: 1,
                child: ColoredBox(color: _ReceiptPaper._muted),
              ),
            ),
          );
        },
      ),
    );
  }
}
