import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Fond général de l'application : un dégradé radial avec une lueur douce vers
/// le haut, pour donner de la profondeur (§29.1). S'adapte à l'ambiance : encre
/// neutre profonde la nuit, blanc cassé chaleureux le jour.
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.75),
          radius: 1.35,
          colors: dark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.lightBackgroundGradient,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
