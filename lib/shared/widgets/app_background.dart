import 'package:flutter/material.dart';

import '../../app/theme/tenk_skin.dart';

/// Fond général de l'application : un dégradé radial avec une lueur douce vers
/// le haut, pour donner de la profondeur (§29.1). Le dégradé vient de
/// l'habillage courant ([TenkSkin]) : encre neutre profonde la nuit, blanc cassé
/// chaleureux le jour — et noir violacé sous néon en mode trash.
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.75),
          radius: 1.35,
          colors: TenkSkin.of(context).backgroundGradient,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
