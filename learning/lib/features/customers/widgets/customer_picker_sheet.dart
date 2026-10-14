import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';
import '../screens/add_customer_screen.dart';

/// Bottom sheet for choosing who a sale is for. Pops with the chosen
/// customer (including one created from here), or nothing if dismissed.
Future<CustomerModel?> showCustomerPicker(BuildContext context) {
  return showModalBottomSheet<CustomerModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _CustomerPicker(),
  );
}

class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker();

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  final CustomerController controller = Get.find<CustomerController>();
  String _query = '';

  Future<void> _addNew() async {
    final created = await Get.to<CustomerModel>(() => AddCustomerScreen());
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search customers',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
            title: const Text('Add new customer'),
            onTap: _addNew,
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final query = _query.trim().toLowerCase();
              final customers = controller.customers
                  .where(
                    (c) =>
                        c.name.toLowerCase().contains(query) ||
                        c.phone.contains(query),
                  )
                  .toList();

              return ListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
                ),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(customer),
                    leading: CircleAvatar(
                      child: Text(customer.name.characters.first.toUpperCase()),
                    ),
                    title: Text(customer.name),
                    subtitle: customer.phone.isEmpty
                        ? null
                        : Text(customer.phone),
                    trailing: customer.owesMoney
                        ? Text(
                            'Owes ${AppFormatter.currency(customer.balance)}',
                            style: const TextStyle(color: AppColors.expense),
                          )
                        : null,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
