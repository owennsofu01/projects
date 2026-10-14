import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

/// Every saved customer with what they owe — the debtors book.
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key, this.onlyDebtors = false});

  /// Start with the "Owes money" filter on (e.g. when opened from the
  /// dashboard's "Owed to you" card).
  final bool onlyDebtors;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerController controller = Get.find<CustomerController>();

  String _query = '';
  late bool _onlyDebtors = widget.onlyDebtors;

  List<CustomerModel> _visible() {
    final query = _query.trim().toLowerCase();
    final source = _onlyDebtors ? controller.debtors : controller.customers;
    return source
        .where(
          (c) =>
              query.isEmpty ||
              c.name.toLowerCase().contains(query) ||
              c.phone.contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'customers-fab',
        tooltip: 'Add customer',
        onPressed: () => Get.to(() => AddCustomerScreen()),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Obx(() {
            final customers = _visible();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _OwedSummary(controller: controller),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search by name or phone',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: !_onlyDebtors,
                      onSelected: (_) => setState(() => _onlyDebtors = false),
                    ),
                    ChoiceChip(
                      label: Text('Owes money (${controller.debtors.length})'),
                      selected: _onlyDebtors,
                      onSelected: (_) => setState(() => _onlyDebtors = true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (customers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: EmptyState(
                      icon: Icons.people_outline,
                      message: controller.customers.isEmpty
                          ? 'No customers yet'
                          : 'No matching customers',
                    ),
                  )
                else
                  for (final customer in customers) ...[
                    _CustomerTile(customer: customer),
                    const SizedBox(height: 8),
                  ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _OwedSummary extends StatelessWidget {
  const _OwedSummary({required this.controller});

  final CustomerController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final debtorCount = controller.debtors.length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owed to you',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatter.currency(controller.totalOwed),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: debtorCount > 0 ? AppColors.expense : null,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              debtorCount == 0
                  ? 'All settled'
                  : '$debtorCount customer${debtorCount == 1 ? '' : 's'}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () =>
            Get.to(() => CustomerDetailScreen(customerId: customer.id)),
        leading: CircleAvatar(
          child: Text(customer.name.characters.first.toUpperCase()),
        ),
        title: Text(customer.name),
        subtitle: customer.phone.isEmpty ? null : Text(customer.phone),
        trailing: customer.owesMoney
            ? Text(
                AppFormatter.currency(customer.balance),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.expense,
                ),
              )
            : Text(
                'Settled',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
      ),
    );
  }
}
