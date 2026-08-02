import 'package:flutter/material.dart';

enum GameModeStatus { available, comingSoon }

/// Static registry entry describing one mini-game tile on the home hub.
class GameMode {
  const GameMode({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.routePath,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String routePath;
  final GameModeStatus status;
}
