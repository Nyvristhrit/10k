import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Pluie festive de l'emoji du vainqueur (sa « crevette », son « panda »…).
///
/// Une nuée de l'animal gagnant tombe et tournoie doucement en surimpression,
/// pour une fin de partie spectaculaire. Entièrement peinte à la main (aucune
/// dépendance) : un seul [TextPainter] est mis en page puis réutilisé pour
/// chaque goutte, avec une simple mise à l'échelle sur le canvas.
///
/// L'animation est pilotée par un temps **continu** (Ticker), comme les dés de
/// l'accueil : chaque goutte boucle indépendamment et repart hors écran, sans
/// le « saut » visible qu'aurait un compteur qui revient brutalement à zéro.
class EmojiRainOverlay extends StatefulWidget {
  const EmojiRainOverlay({
    required this.emoji,
    this.count = 26,
    super.key,
  });

  final String emoji;
  final int count;

  @override
  State<EmojiRainOverlay> createState() => _EmojiRainOverlayState();
}

class _EmojiRainOverlayState extends State<EmojiRainOverlay>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker;

  late List<_Drop> _pieces = _build();
  late TextPainter _painter = _layout(widget.emoji);

  static const double _baseFont = 44;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _seconds.value = elapsed.inMicroseconds / 1e6;
    })
      ..start();
  }

  List<_Drop> _build() {
    final rnd = Random(7);
    return List.generate(widget.count, (i) {
      return _Drop(
        x: rnd.nextDouble(),
        phase: rnd.nextDouble(),
        scale: 0.5 + rnd.nextDouble() * 0.8,
        sway: 0.02 + rnd.nextDouble() * 0.07,
        swayFreq: 0.6 + rnd.nextDouble() * 1.6,
        // Vitesse en « chutes par seconde » (période ~ 6 à 11 s).
        speed: 0.09 + rnd.nextDouble() * 0.08,
        spin: (rnd.nextBool() ? 1 : -1) * (0.1 + rnd.nextDouble() * 0.3),
        baseAngle: (rnd.nextDouble() - 0.5) * 0.8,
      );
    });
  }

  TextPainter _layout(String emoji) {
    final tp = TextPainter(
      text: TextSpan(
          text: emoji, style: const TextStyle(fontSize: _baseFont)),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  @override
  void didUpdateWidget(covariant EmojiRainOverlay old) {
    super.didUpdateWidget(old);
    if (old.emoji != widget.emoji) _painter = _layout(widget.emoji);
    if (old.count != widget.count) _pieces = _build();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.9,
        child: RepaintBoundary(
          child: ValueListenableBuilder<double>(
            valueListenable: _seconds,
            builder: (context, s, _) => CustomPaint(
              painter: _EmojiRainPainter(_pieces, s, _painter),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _Drop {
  const _Drop({
    required this.x,
    required this.phase,
    required this.scale,
    required this.sway,
    required this.swayFreq,
    required this.speed,
    required this.spin,
    required this.baseAngle,
  });

  final double x;
  final double phase;
  final double scale;
  final double sway;
  final double swayFreq;
  final double speed;
  final double spin;
  final double baseAngle;
}

class _EmojiRainPainter extends CustomPainter {
  _EmojiRainPainter(this.pieces, this.seconds, this.painter);

  final List<_Drop> pieces;
  final double seconds;
  final TextPainter painter;

  @override
  void paint(Canvas canvas, Size size) {
    final w = painter.width;
    final h = painter.height;
    for (final p in pieces) {
      // Progression continue dans [0,1) : off-écran en haut à 0, en bas à 1.
      final tt = ((seconds * p.speed) + p.phase) % 1.0;
      final y = tt * (size.height + 100) - 50;
      final x = (p.x + sin(tt * p.swayFreq * 2 * pi) * p.sway) * size.width;

      canvas.save();
      canvas.translate(x, y);
      // Rotation continue (indépendante de la boucle de chute).
      canvas.rotate(p.baseAngle + seconds * p.spin * 2 * pi);
      canvas.scale(p.scale);
      painter.paint(canvas, Offset(-w / 2, -h / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EmojiRainPainter old) =>
      old.seconds != seconds || old.painter != painter;
}
