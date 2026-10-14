import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sync_status_controller.dart';

/// Slim strip shown above the bottom navigation while offline or while
/// changes are still on their way to the server; hidden otherwise.
class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = Get.find<SyncStatusController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final online = sync.isOnline.value;
      final pending = sync.hasPendingWrites.value;

      final ({IconData icon, String text, Color background, Color foreground})?
      status = !online
          ? (
              icon: Icons.cloud_off_outlined,
              text: pending
                  ? "Offline — changes are saved on this phone and will sync "
                        "when you're back online"
                  : "You're offline — you can keep recording sales and "
                        "expenses",
              background: colorScheme.inverseSurface,
              foreground: colorScheme.onInverseSurface,
            )
          : pending
          ? (
              icon: Icons.cloud_sync_outlined,
              text: 'Syncing changes…',
              background: colorScheme.secondaryContainer,
              foreground: colorScheme.onSecondaryContainer,
            )
          : null;

      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: status == null
            ? const SizedBox(width: double.infinity)
            : Material(
                color: status.background,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(status.icon, size: 18, color: status.foreground),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          status.text,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: status.foreground),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
    });
  }
}
