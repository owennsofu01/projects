import 'package:flutter/material.dart';

import '../../core/constants/game_mode_registry.dart';
import '../../core/widgets/coming_soon_screen.dart';

class JigsawScreen extends StatelessWidget {
  const JigsawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = GameModeRegistry.byId('jigsaw');
    return ComingSoonScreen(title: mode.title, icon: mode.icon, accentColor: mode.accentColor);
  }
}
