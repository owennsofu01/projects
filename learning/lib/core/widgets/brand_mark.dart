import 'package:flutter/material.dart';

/// The app icon on a rounded tile.
///
/// The icon art (assets/icon/app_icon.png) has an off-white background baked
/// in, so it always sits on a matching light tile — that keeps it looking
/// intentional on both light pages and the teal splash/onboarding.
class LogoTile extends StatelessWidget {
  const LogoTile({super.key, this.size = 64});

  final double size;

  static const _tileColor = Color(0xFFFAFAFA);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: _tileColor,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.16),
        child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.contain),
      ),
    );
  }
}
