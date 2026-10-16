import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/service_controller.dart';
import '../models/service_model.dart';
import 'add_service_screen.dart';

/// The Services tab of the catalog. Shown without its own app bar.
class ServiceListScreen extends StatelessWidget {
  ServiceListScreen({super.key});

  final ServiceController controller = Get.find<ServiceController>();

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
      floatingActionButton: FloatingActionButton(
        heroTag: 'services-fab',
        tooltip: 'Add service',
        onPressed: () => Get.to(() => AddServiceScreen()),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        final services = controller.services;
        if (services.isEmpty) {
          return const EmptyState(
            icon: Icons.content_cut,
            message:
                'No services yet. Add what you charge for, like a haircut '
                'or braids.',
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: services.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _serviceCard(context, services[index]),
            ),
          ),
        );
      }),
    );
  }

  Widget _serviceCard(BuildContext context, ServiceModel service) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => AddServiceScreen(service: service)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.materialsCost > 0
                            ? 'Materials ${AppFormatter.currency(service.materialsCost)} · '
                                  'profit ${AppFormatter.currency(service.profitPerJob)} per job'
                            : 'No materials cost',
                        style: textTheme.bodySmall?.copyWith(
                          color: service.profitPerJob < 0
                              ? AppColors.expense
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Obx(
                () => Text(
                  AppFormatter.currency(service.price),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<_ServiceAction>(
                tooltip: 'More',
                onSelected: (action) {
                  switch (action) {
                    case _ServiceAction.edit:
                      Get.to(() => AddServiceScreen(service: service));
                    case _ServiceAction.delete:
                      _delete(context, service);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ServiceAction.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ServiceAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ServiceAction { edit, delete }
