import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/add_fab.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/list_row.dart';
import '../controllers/service_controller.dart';
import '../models/service_model.dart';
import 'add_service_screen.dart';

/// The Services tab of the catalog. Shown without its own app bar.
class ServiceListScreen extends StatelessWidget {
  ServiceListScreen({super.key});

  final ServiceController controller = Get.find<ServiceController>();

  void _add() => Get.to(() => AddServiceScreen());

  Future<void> _delete(BuildContext context, ServiceModel service) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${service.name}?',
      message: 'Past sales of this service stay in your sales and reports.',
    );
    if (!confirmed) return;

    if (await controller.deleteService(service.id)) {
      showSuccessSnackbar('${service.name} deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AddFab(
        heroTag: 'services-fab',
        label: 'Add service',
        onPressed: _add,
      ),
      body: Obx(() {
        final services = controller.services;
        if (services.isEmpty) {
          return EmptyState(
            icon: Icons.handyman_outlined,
            title: 'No services yet',
            message: 'Add what you charge for, like a haircut or a repair.',
            actionLabel: 'Add service',
            onAction: _add,
          );
        }

        return GroupedListView(
          sections: [
            ListSection(
              title:
                  '${services.length} '
                  '${services.length == 1 ? 'service' : 'services'}',
              rows: [for (final s in services) _row(context, s)],
            ),
          ],
        );
      }),
    );
  }

  Widget _row(BuildContext context, ServiceModel service) {
    final losing = service.profitPerJob < 0;
    return ListRow(
      onTap: () => Get.to(() => AddServiceScreen(service: service)),
      leading: RowAvatar(service.name),
      title: service.name,
      subtitle: Obx(
        () => Text(
          service.materialsCost > 0
              ? 'Materials ${AppFormatter.currency(service.materialsCost)}'
              : 'No materials cost',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RowAmount(
            service.price,
            caption: () =>
                '${AppFormatter.currency(service.profitPerJob)} profit',
            captionColor: losing ? AppColors.expense : AppColors.income,
          ),
          _RowMenu(
            onEdit: () => Get.to(() => AddServiceScreen(service: service)),
            onDelete: () => _delete(context, service),
          ),
        ],
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: onEdit,
          child: const ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
          ),
        ),
        PopupMenuItem(
          value: onDelete,
          child: const ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }
}
