import 'package:flutter/material.dart';

/// Affiche un entier qui « monte » en s'animant quand sa valeur change, avec un
/// léger effet de pop. Idéal pour les scores : quand un joueur marque, le
/// nombre grimpe visiblement au lieu de sauter d'un coup.
class CountUpText extends StatefulWidget {
  const CountUpText({
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 650),
    this.prefix = '',
    this.textAlign,
    super.key,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final String prefix;
  final TextAlign? textAlign;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late int _from = widget.value;
  late int _to = widget.value;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didUpdateWidget(covariant CountUpText old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _to;
      _to = widget.value;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_c.value);
        final current = (_from + (_to - _from) * t).round();
        // Bosse d'échelle qui culmine au milieu de l'animation puis retombe.
        final pop = 1 + 0.16 * (1 - (2 * _c.value - 1).abs());
        return Transform.scale(
          scale: pop,
          child: Text('${widget.prefix}$current',
              style: widget.style, textAlign: widget.textAlign),
        );
      },
    );
  }
}
