import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../insights/controllers/insight_controller.dart';
import '../../insights/screens/stock_intelligence_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// Large "Dashboard" title with a welcome line, plus round action buttons
/// for stock alerts and settings.
class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key, required this.insightController});

  final InsightController insightController;

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  late final Future<String?> _name = Get.find<AuthController>()
      .fetchProfile()
      .then((user) => user?.name.trim().split(' ').first)
      .catchError((_) => null);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: textTheme.headlineMedium),
              const SizedBox(height: 2),
              FutureBuilder<String?>(
                future: _name,
                builder: (context, snap) {
                  final name = snap.data;
                  final greeting = (name == null || name.isEmpty)
                      ? 'Welcome back 👋'
                      : 'Welcome back, $name 👋';
                  return Text(greeting, style: textTheme.bodyMedium);
                },
              ),
            ],
          ),
        ),
        Obx(() {
          final count = widget.insightController.restockCount;
          return _RoundButton(
            tooltip: 'Stock alerts',
            onTap: () => Get.to(() => StockIntelligenceScreen()),
            child: Badge(
              label: Text('$count'),
              isLabelVisible: count > 0,
              child: const Icon(Icons.notifications_outlined, size: 22),
            ),
          );
        }),
        const SizedBox(width: 8),
        _RoundButton(
          tooltip: 'Settings',
          onTap: () => Get.to(() => SettingsScreen()),
          child: const Icon(Icons.settings_outlined, size: 22),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
  });

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surfaceContainerLow,
        shape: CircleBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(dimension: 48, child: Center(child: child)),
        ),
      ),
    );
  }
}
