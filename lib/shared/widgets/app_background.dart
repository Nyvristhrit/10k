import 'package:flutter/material.dart';

import '../../app/theme/tenk_skin.dart';

/// Fond général : dégradé radial fourni par l'habillage courant ([TenkSkin]).
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
