import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Pluie de dés en arrière-plan, à placer derrière un voile flou.
///
/// Pilotée par un temps continu (Ticker) : chaque dé boucle indépendamment et
/// repart hors écran, sans saut visible.
class FallingDice extends StatefulWidget {
  const FallingDice({this.count = 16, this.emojis = const ['🎲'], super.key});

  final int count;

  /// Emojis piochés à tour de rôle pour la pluie.
  final List<String> emojis;

  @override
  State<FallingDice> createState() => _FallingDiceState();
}

class _FallingDiceState extends State<FallingDice>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker;
  late List<_Die> _dice = _build();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _seconds.value = elapsed.inMicroseconds / 1e6;
    })
      ..start();
  }

  List<_Die> _build() {
    final rnd = Random(11);
    final emojis = widget.emojis.isEmpty ? const ['🎲'] : widget.emojis;
    return List.generate(widget.count, (i) {
      final size = 26 + rnd.nextDouble() * 44;
      final painter = TextPainter(
        text: TextSpan(
            text: emojis[i % emojis.length], style: TextStyle(fontSize: size)),
        textDirection: TextDirection.ltr,
      )..layout();
      return _Die(
        x: rnd.nextDouble(),
        phase: rnd.nextDouble(),
        // Vitesse en « chutes par seconde » (période ~ 9 à 16 s).
        speed: 0.06 + rnd.nextDouble() * 0.05,
        spin: (rnd.nextBool() ? 1 : -1) * (0.15 + rnd.nextDouble() * 0.35),
        sway: 0.01 + rnd.nextDouble() * 0.05,
        swayFreq: 0.6 + rnd.nextDouble() * 1.6,
        baseAngle: rnd.nextDouble() * 2 * pi,
        painter: painter,
      );
    });
  }

  @override
  void didUpdateWidget(covariant FallingDice old) {
    super.didUpdateWidget(old);
    // Les TextPainter sont figés à la création : on reconstruit la pluie si
    // les emojis changent.
    if (!listEquals(old.emojis, widget.emojis) || old.count != widget.count) {
      _dice = _build();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: ValueListenableBuilder<double>(
          valueListenable: _seconds,
          builder: (context, s, _) => CustomPaint(
            painter: _DicePainter(_dice, s),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Die {
  const _Die({
    required this.x,
    required this.phase,
    required this.speed,
    required this.spin,
    required this.sway,
    required this.swayFreq,
    required this.baseAngle,
    required this.painter,
  });

  final double x;
  final double phase;
  final double speed;
  final double spin;
  final double sway;
  final double swayFreq;
  final double baseAngle;
  final TextPainter painter;
}

class _DicePainter extends CustomPainter {
  _DicePainter(this.dice, this.seconds);

  final List<_Die> dice;
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dice) {
      // Progression continue dans [0,1) : off-écran en haut à 0, en bas à 1.
      final tt = ((seconds * d.speed) + d.phase) % 1.0;
      final y = tt * (size.height + 160) - 80;
      final x = (d.x + sin(tt * d.swayFreq * 2 * pi) * d.sway) * size.width;
      final w = d.painter.size.width;
      final h = d.painter.size.height;

      canvas.save();
      canvas.translate(x, y);
      // Rotation continue (indépendante de la boucle de chute).
      canvas.rotate(d.baseAngle + seconds * d.spin * 2 * pi);
      d.painter.paint(canvas, Offset(-w / 2, -h / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DicePainter old) => old.seconds != seconds;
}
