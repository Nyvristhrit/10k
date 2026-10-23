import 'dart:math';

import 'package:flutter/material.dart';

/// Taches marron du « bon dernier » (mode trash) : il se salit un peu plus à
/// chaque bouton qu'il touche. À poser **entre le fond et le contenu** d'une
/// tuile ou d'une fenêtre : les taches repeignent le fond, le texte reste
/// lisible par-dessus (et les taps passent au travers).
///
/// Un seul marron, opaque : deux taches qui se chevauchent donnent le même
/// marron uni, sans teintes empilées. Les taches grossissent au fil de la
/// partie, si bien que la tuile du dernier finit presque entièrement marron,
/// constellée de gouttelettes — la saleté de tous les derniers successifs.
///
/// Chaque tache a une forme et une place fixes (tirées d'après son numéro) :
/// elles ne bougent pas d'un affichage à l'autre, et quand le titre passe à
/// un autre joueur, il récupère exactement les mêmes. La dernière arrivée
/// « éclate » avec un petit rebond.
class CradoStains extends StatefulWidget {
  const CradoStains({required this.count, super.key});

  /// Nombre de taches accumulées (seules les [maxVisible] premières sont
  /// dessinées, au-delà la carte est déjà bien sale).
  final int count;

  static const int maxVisible = 60;

  /// Le marron, unique.
  static const Color brown = Color(0xFF5A3A1C);

  @override
  State<CradoStains> createState() => _CradoStainsState();
}

class _CradoStainsState extends State<CradoStains>
    with SingleTickerProviderStateMixin {
  // Créé d'emblée (pas en `late` paresseux) : une tuile restée propre ne le
  // toucherait qu'à sa destruction, trop tard pour lui trouver une horloge.
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant CradoStains old) {
    super.didUpdateWidget(old);
    if (widget.count > old.count) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pop,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _StainsPainter(
            count: min(widget.count, CradoStains.maxVisible),
            // Le rebond ne concerne que la dernière tache, et seulement tant
            // qu'on n'a pas dépassé le plafond (sinon rien de neuf à montrer).
            newestScale: widget.count > CradoStains.maxVisible
                ? 1
                : Curves.elasticOut.transform(_pop.value),
          ),
        ),
      ),
    );
  }
}

class _StainsPainter extends CustomPainter {
  _StainsPainter({required this.count, required this.newestScale});

  final int count;
  final double newestScale;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < count; i++) {
      final rnd = Random(i * 7919 + 13);
      final center = Offset(
        size.width * (0.06 + 0.88 * rnd.nextDouble()),
        size.height * (0.08 + 0.84 * rnd.nextDouble()),
      );
      // Les premières taches sont petites ; les suivantes, de plus en plus
      // grosses, finissent par recouvrir toute la tuile.
      final growth = 1 + 1.6 * i / CradoStains.maxVisible;
      final radius =
          size.shortestSide * (0.05 + 0.05 * rnd.nextDouble()) * growth;
      final scale = i == count - 1 ? newestScale : 1.0;
      if (scale <= 0) continue;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale);
      _splat(canvas, rnd, radius);
      canvas.restore();
    }
  }

  /// Une éclaboussure : un pâté aux bords irréguliers, dont quelques pointes
  /// partent en coulures, et des gouttes détachées projetées autour.
  void _splat(Canvas canvas, Random rnd, double r) {
    final paint = Paint()..color = CradoStains.brown;

    // Pâté central : contour bosselé, avec ici et là une pointe projetée.
    const points = 16;
    final pts = <Offset>[
      for (var k = 0; k < points; k++)
        Offset.fromDirection(
          2 * pi * k / points + rnd.nextDouble() * 0.2,
          r *
              (rnd.nextDouble() < 0.25
                  ? 1.25 + 0.45 * rnd.nextDouble() // pointe
                  : 0.75 + 0.3 * rnd.nextDouble()),
        ),
    ];
    final path = Path();
    for (var k = 0; k < points; k++) {
      final mid = (pts[k] + pts[(k + 1) % points]) / 2;
      if (k == 0) {
        path.moveTo(mid.dx, mid.dy);
      } else {
        path.quadraticBezierTo(pts[k].dx, pts[k].dy, mid.dx, mid.dy);
      }
    }
    final first = (pts[0] + pts[1]) / 2;
    path.quadraticBezierTo(pts[0].dx, pts[0].dy, first.dx, first.dy);
    path.close();
    canvas.drawPath(path, paint);

    // Gouttes projetées, plus petites à mesure qu'elles s'éloignent, en
    // gerbe d'un même côté (l'éclaboussure a une direction).
    final heading = rnd.nextDouble() * 2 * pi;
    final drops = 4 + rnd.nextInt(5);
    for (var d = 0; d < drops; d++) {
      final angle = heading + (rnd.nextDouble() - 0.5) * 2.4;
      final far = rnd.nextDouble();
      final at = Offset.fromDirection(angle, r * (1.5 + 1.3 * far));
      canvas.drawCircle(at, r * (0.24 - 0.16 * far) * (0.6 + 0.4 * rnd.nextDouble()),
          paint);
    }
  }

  @override
  bool shouldRepaint(_StainsPainter old) =>
      old.count != count || old.newestScale != newestScale;
}
