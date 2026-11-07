import 'package:flutter/material.dart';

/// The labelled "+ Add …" button used on every list screen.
class AddFab extends StatelessWidget {
  const AddFab({
    super.key,
    required this.label,
    required this.onPressed,
    required this.heroTag,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback onPressed;

  /// Must be unique per screen that can be on screen at the same time.
  final Object heroTag;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
