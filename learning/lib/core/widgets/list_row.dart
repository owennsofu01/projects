import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/formatters.dart';

/// The standard row used by every list in the app: a leading tile, a title
/// with an optional subtitle, and an optional trailing widget.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;

  /// A [String] or a [Widget] (e.g. an `Obx` that formats currency).
  final Object? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    DefaultTextStyle.merge(
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      child: subtitle is Widget ? subtitle : Text('$subtitle'),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

/// A tinted rounded square with an icon — the default [ListRow] leading.
class RowIcon extends StatelessWidget {
  const RowIcon(this.icon, {super.key, this.color});

  final IconData icon;

  /// Defaults to the theme's primary color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: c),
    );
  }
}

/// A circle with a name's first letter — the [ListRow] leading for people
/// and named items.
class RowAvatar extends StatelessWidget {
  const RowAvatar(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trimmed = name.trim();
    return CircleAvatar(
      radius: 20,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: colorScheme.onPrimaryContainer),
      ),
    );
  }
}

/// A right-aligned amount with an optional small caption underneath,
/// e.g. a sale total with its profit.
class RowAmount extends StatelessWidget {
  const RowAmount(
    this.amount, {
    super.key,
    this.color,
    this.prefix = '',
    this.caption,
    this.captionColor,
  });

  final double amount;
  final Color? color;

  /// E.g. '−' for money going out.
  final String prefix;
  final String Function()? caption;
  final Color? captionColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$prefix${AppFormatter.currency(amount)}',
            style: textTheme.titleSmall?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!(),
              style: textTheme.bodySmall?.copyWith(color: captionColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small colored pill for statuses like "Low stock" or "Settled".
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
