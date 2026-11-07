import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/add_fab.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/list_row.dart';
import '../../../core/widgets/money_text.dart';
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

  void _add() => Get.to(() => AddCustomerScreen());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: AddFab(
        heroTag: 'customers-fab',
        label: 'Add customer',
        icon: Icons.person_add_alt_1_outlined,
        onPressed: _add,
      ),
      body: Obx(() {
        if (controller.customers.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: 'No customers yet',
            message:
                'Save regular customers to sell on credit and track '
                'what they owe.',
            actionLabel: 'Add customer',
            onAction: _add,
          );
        }

        final customers = _visible();
        return GroupedListView(
          header: [
            _OwedSummary(controller: controller),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search by name or phone',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
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
              ],
            ),
            if (customers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: EmptyState(
                  icon: Icons.search_off,
                  message: 'No customers match your search.',
                ),
              ),
          ],
          sections: [
            if (customers.isNotEmpty)
              ListSection(
                rows: [for (final c in customers) _CustomerTile(customer: c)],
              ),
          ],
        );
      }),
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
                  MoneyText(
                    controller.totalOwed,
                    style: textTheme.headlineSmall?.copyWith(
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
    return ListRow(
      onTap: () => Get.to(() => CustomerDetailScreen(customerId: customer.id)),
      leading: RowAvatar(customer.name),
      title: customer.name,
      subtitle: customer.phone.isEmpty ? null : customer.phone,
      trailing: customer.owesMoney
          ? RowAmount(
              customer.balance,
              color: AppColors.expense,
              caption: () => 'owes',
            )
          : const StatusPill('Settled', color: AppColors.income),
    );
  }
}
