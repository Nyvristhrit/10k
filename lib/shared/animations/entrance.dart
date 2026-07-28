import 'package:flutter/material.dart';

/// Fait apparaître son enfant en fondu + léger glissement, après un délai.
///
/// Enchaînés avec des délais croissants, plusieurs `Entrance` créent une
/// arrivée « en cascade » (titre, sous-titre, boutons…) qui donne du peps.
class Entrance extends StatefulWidget {
  const Entrance({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = const Offset(0, 26),
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(
              widget.offset.dx * (1 - curved.value),
              widget.offset.dy * (1 - curved.value),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
