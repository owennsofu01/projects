import 'package:flutter/material.dart';

import '../../core/constants/game_mode_registry.dart';
import '../../core/widgets/coming_soon_screen.dart';

class Match3Screen extends StatelessWidget {
  const Match3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = GameModeRegistry.byId('match3');
    return ComingSoonScreen(title: mode.title, icon: mode.icon, accentColor: mode.accentColor);
  }
}
