import 'package:flutter/material.dart';

/// Shared screen for the 10 game modes that are scaffolded (route + model
/// stub + content schema) but not yet playable. Swapping this out for real
/// gameplay later only touches that one feature folder.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.icon, required this.accentColor});

  final String title;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, size: 48, color: accentColor),
              ),
              const SizedBox(height: 24),
              Text(
                '$title is on the way',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This mini-game is scaffolded and ready for content — check back in a future update.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
