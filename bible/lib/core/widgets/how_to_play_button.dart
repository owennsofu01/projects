import 'package:flutter/material.dart';

/// AppBar action that opens a numbered "How to Play" dialog.
/// Drop into any game's entry-screen AppBar actions: `HowToPlayButton(title: ..., steps: [...])`.
class HowToPlayButton extends StatelessWidget {
  const HowToPlayButton({super.key, required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: 'How to play',
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(steps[i], style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it'))],
        ),
      ),
    );
  }
}
