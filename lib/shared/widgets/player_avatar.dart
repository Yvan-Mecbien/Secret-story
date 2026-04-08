import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlayerAvatar extends StatelessWidget {
  final dynamic user;
  final double size;
  final bool showBorder;
  const PlayerAvatar(
      {super.key, required this.user, this.size = 40, this.showBorder = false});

  @override
  Widget build(BuildContext context) {
    final color = (user.groupColor as Color?) ?? AppColors.primary;
    final initials = (user.initials as String?) ?? '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: color, width: 2.5)
            : Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.35)),
      ),
    );
  }
}
