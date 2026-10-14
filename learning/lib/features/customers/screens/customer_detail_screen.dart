import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';
import '../models/ledger_entry.dart';
import 'add_customer_screen.dart';

/// One customer's balance and account history, with actions to record a
/// payment or contact them about what they owe.
class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final CustomerController controller = Get.find<CustomerController>();

  // Created once so rebuilds don't resubscribe to Firestore.
  late final Stream<CustomerModel?> _customer = controller.watchCustomer(
    widget.customerId,
  );
  late final Stream<List<LedgerEntry>> _ledger = controller.ledger(
    widget.customerId,
  );

  Future<void> _recordPayment(CustomerModel customer) async {
    final result = await showDialog<({double amount, String note})>(
      context: context,
      builder: (_) => _PaymentDialog(balance: customer.balance),
    );
    if (result == null) return;

    final success = await controller.recordPayment(
      customer.id,
      amount: result.amount,
      note: result.note,
    );
    if (success) showSuccessSnackbar('Payment recorded');
  }

  Future<void> _delete(CustomerModel customer) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${customer.name}?',
      message:
          'Their payment history will be deleted too. Past sales stay in '
          'your records.',
    );
    if (!confirmed) return;

    final success = await controller.deleteCustomer(customer.id);
    if (success) {
      Get.back();
      showSuccessSnackbar('Customer deleted');
    }
  }

  Future<void> _call(CustomerModel customer) =>
      _launch(Uri(scheme: 'tel', path: customer.phone));

  Future<void> _remindOnWhatsApp(CustomerModel customer) {
    final digits = customer.phone.replaceAll(RegExp(r'\D'), '');
    final message =
        'Hi ${customer.name}, this is a friendly reminder that your '
        'balance with us is ${AppFormatter.currency(customer.balance)}. '
        'Thank you!';
    return _launch(Uri.https('wa.me', '/$digits', {'text': message}));
  }

  Future<void> _launch(Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) showErrorSnackbar('Could not open ${uri.scheme} link');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CustomerModel?>(
      stream: _customer,
      builder: (context, snapshot) {
        final customer = snapshot.data;

        if (customer == null) {
          return Scaffold(
            appBar: AppBar(),
            body: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const EmptyState(
                    icon: Icons.person_off_outlined,
                    message: 'Customer not found',
                  ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    Get.to(() => AddCustomerScreen(customer: customer)),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(customer),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _BalanceCard(
                    customer: customer,
                    onRecordPayment: () => _recordPayment(customer),
                    onCall: customer.phone.isEmpty
                        ? null
                        : () => _call(customer),
                    onRemind: customer.phone.isEmpty || !customer.owesMoney
                        ? null
                        : () => _remindOnWhatsApp(customer),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<LedgerEntry>>(
                    stream: _ledger,
                    builder: (context, snapshot) {
                      final entries = snapshot.data;
                      if (entries == null) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (entries.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: EmptyState(
                            icon: Icons.history,
                            message: 'No credit sales or payments yet',
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final entry in entries)
                            _LedgerTile(entry: entry),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.customer,
    required this.onRecordPayment,
    required this.onCall,
    required this.onRemind,
  });

  final CustomerModel customer;
  final VoidCallback onRecordPayment;
  final VoidCallback? onCall;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.owesMoney ? 'Owes you' : 'Balance',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Obx(
              () => Text(
                customer.owesMoney
                    ? AppFormatter.currency(customer.balance)
                    : 'Settled',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: customer.owesMoney
                      ? AppColors.expense
                      : AppColors.income,
                ),
              ),
            ),
            if (customer.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(customer.phone, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: customer.owesMoney ? onRecordPayment : null,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Record payment'),
                ),
                if (onCall != null)
                  OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                if (onRemind != null)
                  OutlinedButton.icon(
                    onPressed: onRemind,
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp reminder'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.type == LedgerEntryType.payment;
    final color = isPayment ? AppColors.income : AppColors.expense;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isPayment ? Icons.south_west : Icons.north_east,
          color: color,
        ),
        title: Text(isPayment ? 'Payment received' : 'Credit sale'),
        subtitle: Text(
          [
            AppFormatter.date(entry.date),
            if (entry.note.isNotEmpty) entry.note,
          ].join('\n'),
        ),
        isThreeLine: entry.note.isNotEmpty,
        trailing: Obx(
          () => Text(
            '${isPayment ? '−' : '+'}${AppFormatter.currency(entry.amount)}',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.balance});

  final double balance;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _amountCtrl = TextEditingController(
    text: widget.balance.toStringAsFixed(2),
  );
  final TextEditingController _noteCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null) return 'Enter a valid amount';
    if (amount <= 0) return 'Must be greater than 0';
    if (amount > widget.balance + 0.005) return 'More than what is owed';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      amount: double.parse(_amountCtrl.text.trim()),
      note: _noteCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: _validateAmount,
              decoration: InputDecoration(
                labelText: 'Amount',
                helperText:
                    'Owes ${widget.balance.toStringAsFixed(2)} in total',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Mobile money',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
