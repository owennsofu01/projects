import 'package:flutter/material.dart';

import '../../core/constants/game_mode_registry.dart';
import '../../core/widgets/coming_soon_screen.dart';

class GuessWhoScreen extends StatelessWidget {
  const GuessWhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = GameModeRegistry.byId('guess_who');
    return ComingSoonScreen(title: mode.title, icon: mode.icon, accentColor: mode.accentColor);
  }
}
