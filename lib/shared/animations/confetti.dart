import 'dart:math';

import 'package:flutter/material.dart';

/// Pluie de confettis colorés, en surimpression, pour fêter une victoire.
///
/// Entièrement peinte à la main (aucune dépendance). Tombe en continu avec un
/// léger balancement et une rotation, chaque confetti ayant sa propre phase.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    this.count = 80,
    this.colors = const [
      Color(0xFF2563EB),
      Color(0xFFEA580C),
      Color(0xFF059669),
      Color(0xFFE11D48),
      Color(0xFF7C3AED),
      Color(0xFFF59E0B),
      Color(0xFF22D3EE),
    ],
    super.key,
  });

  final int count;
  final List<Color> colors;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  late final List<_Confetto> _pieces = _build();

  List<_Confetto> _build() {
    final rnd = Random(42);
    return List.generate(widget.count, (i) {
      return _Confetto(
        x: rnd.nextDouble(),
        phase: rnd.nextDouble(),
        size: 6 + rnd.nextDouble() * 8,
        sway: 0.03 + rnd.nextDouble() * 0.08,
        swayFreq: 1 + rnd.nextDouble() * 3,
        spin: (rnd.nextBool() ? 1 : -1) * (2 + rnd.nextDouble() * 4),
        color: widget.colors[i % widget.colors.length],
        speed: 0.8 + rnd.nextDouble() * 0.7,
        round: rnd.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _ConfettiPainter(_pieces, _c.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Confetto {
  const _Confetto({
    required this.x,
    required this.phase,
    required this.size,
    required this.sway,
    required this.swayFreq,
    required this.spin,
    required this.color,
    required this.speed,
    required this.round,
  });

  final double x;
  final double phase;
  final double size;
  final double sway;
  final double swayFreq;
  final double spin;
  final Color color;
  final double speed;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Confetto> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final tt = ((t * p.speed) + p.phase) % 1.0;
      final y = tt * (size.height + 60) - 30;
      final x = (p.x + sin(tt * p.swayFreq * 2 * pi) * p.sway) * size.width;
      // Fondu léger sur les tout derniers instants de chute.
      final fade = tt > 0.92 ? (1 - tt) / 0.08 : 1.0;
      final paint = Paint()..color = p.color.withValues(alpha: fade);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(tt * p.spin * 2 * pi);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
