import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tenk_skin.dart';
import '../../shared/widgets/app_background.dart';

/// Nombre de dés du 10 000.
const int _kDiceCount = 6;

/// Plateau de dés virtuel (§ évolution « jouer sans dés physiques »).
///
/// Un pur outil manuel : on lance, on met de côté les dés qui comptent (on les
/// touche pour les « garder »), on relance le reste — exactement le geste
/// réel. L'appli ne calcule rien à la place du joueur : il continue de saisir
/// son score lui-même sur le plateau, comme avec de vrais dés.
class DiceTrayScreen extends StatefulWidget {
  const DiceTrayScreen({super.key});

  @override
  State<DiceTrayScreen> createState() => _DiceTrayScreenState();
}

class _DiceTrayScreenState extends State<DiceTrayScreen> {
  final _random = Random();
  final List<int> _values = List.filled(_kDiceCount, 1);
  final List<bool> _held = List.filled(_kDiceCount, false);

  /// Jeton d'animation par dé : change uniquement pour les dés relancés, ce
  /// qui laisse les dés gardés parfaitement immobiles.
  final List<int> _spinTokens = List.filled(_kDiceCount, 0);

  int _tokenSeed = 0;
  bool _hasRolled = false;

  int get _heldCount => _held.where((h) => h).length;
  bool get _anyHeld => _heldCount > 0;

  void _roll() {
    setState(() {
      _tokenSeed++;
      for (var i = 0; i < _kDiceCount; i++) {
        if (_held[i]) continue;
        _values[i] = _random.nextInt(6) + 1;
        _spinTokens[i] = _tokenSeed * 100 + i;
      }
      _hasRolled = true;
    });
    HapticFeedback.mediumImpact();
  }

  void _toggleHold(int i) {
    if (!_hasRolled) return;
    setState(() => _held[i] = !_held[i]);
    HapticFeedback.selectionClick();
  }

  void _releaseAll() {
    setState(() => _held.fillRange(0, _kDiceCount, false));
  }

  @override
  Widget build(BuildContext context) {
    final unheld = _kDiceCount - _heldCount;
    final label = !_hasRolled
        ? 'Lancer les dés'
        : (unheld == 0 ? 'Tous gardés' : 'Relancer ($unheld)');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Dés')),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Text(
                  _hasRolled
                      ? 'Touche un dé pour le garder de côté, puis relance le reste.'
                      : 'Pas de dés sous la main ? Lance-les ici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Expanded(child: _mat(context)),
                const SizedBox(height: 16),
                if (_anyHeld)
                  TextButton(
                    onPressed: _releaseAll,
                    child: const Text('Tout libérer'),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: unheld == 0 ? null : _roll,
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Le tapis : un fond distinct posé sous les dés, avec une grille 3×2 qui
  /// s'adapte à la place disponible (portrait comme paysage).
  Widget _mat(BuildContext context) {
    final trash = TenkSkin.of(context).trash;
    final matColor = trash ? const Color(0xFF1A0026) : const Color(0xFF0F3D2E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: matColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const cols = 3;
          const rows = 2;
          const gap = 14.0;
          final sizeFromWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
          final sizeFromHeight = (constraints.maxHeight - gap * (rows - 1)) / rows;
          final dieSize = min(sizeFromWidth, sizeFromHeight).clamp(48.0, 140.0);

          return Center(
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < _kDiceCount; i++)
                  _Die(
                    key: ValueKey('dice_tray_die_$i'),
                    value: _values[i],
                    held: _held[i],
                    spinToken: _spinTokens[i],
                    size: dieSize,
                    onTap: () => _toggleHold(i),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Un dé, avec un faux relief (dégradé + ombre) et une petite animation de
/// lancer (tremblement + valeurs qui défilent) déclenchée par [spinToken].
class _Die extends StatefulWidget {
  const _Die({
    required this.value,
    required this.held,
    required this.spinToken,
    required this.size,
    required this.onTap,
    super.key,
  });

  final int value;
  final bool held;
  final int spinToken;
  final double size;
  final VoidCallback onTap;

  @override
  State<_Die> createState() => _DieState();
}

class _DieState extends State<_Die> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 550));
  final _random = Random();
  List<int> _flicker = const [];
  bool _rolling = false;

  @override
  void didUpdateWidget(covariant _Die old) {
    super.didUpdateWidget(old);
    if (old.spinToken != widget.spinToken) {
      _flicker = List.generate(8, (_) => _random.nextInt(6) + 1);
      final delay = Duration(milliseconds: _random.nextInt(140));
      setState(() => _rolling = true);
      Future.delayed(delay, () {
        if (!mounted) return;
        _c.forward(from: 0).then((_) {
          if (mounted) setState(() => _rolling = false);
        });
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trash = TenkSkin.of(context).trash;
    final skin = TenkSkin.of(context);
    final base = trash ? const Color(0xFF2A0033) : const Color(0xFFFFFDF6);
    final pip = trash ? skin.neon : const Color(0xFF2A2433);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final displayValue = _rolling && _flicker.isNotEmpty
              ? _flicker[(t * 20).floor().clamp(0, _flicker.length - 1)]
              : widget.value;
          final bounce = _rolling ? 1 + 0.16 * sin(pi * t) : 1.0;
          final wobble = _rolling ? sin(t * 26) * (1 - t) * 0.28 : 0.0;

          return Transform.rotate(
            angle: wobble,
            child: Transform.scale(
              scale: bounce,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.size * 0.22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(base, Colors.white, trash ? 0.06 : 0.35)!,
                      base,
                    ],
                  ),
                  border: widget.held
                      ? Border.all(color: skin.neonAlt, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: widget.held
                          ? skin.neonAlt.withValues(alpha: 0.55)
                          : Colors.black45,
                      blurRadius: widget.held ? 16 : 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _DiePipsPainter(displayValue, pip),
                  size: Size.square(widget.size),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dessine les points d'une face de dé (1 à 6), disposition classique.
class _DiePipsPainter extends CustomPainter {
  const _DiePipsPainter(this.value, this.color);

  final int value;
  final Color color;

  static const Map<int, List<Offset>> _layouts = {
    1: [Offset(0.5, 0.5)],
    2: [Offset(0.26, 0.26), Offset(0.74, 0.74)],
    3: [Offset(0.24, 0.24), Offset(0.5, 0.5), Offset(0.76, 0.76)],
    4: [
      Offset(0.26, 0.26),
      Offset(0.74, 0.26),
      Offset(0.26, 0.74),
      Offset(0.74, 0.74),
    ],
    5: [
      Offset(0.26, 0.26),
      Offset(0.74, 0.26),
      Offset(0.5, 0.5),
      Offset(0.26, 0.74),
      Offset(0.74, 0.74),
    ],
    6: [
      Offset(0.26, 0.22),
      Offset(0.74, 0.22),
      Offset(0.26, 0.5),
      Offset(0.74, 0.5),
      Offset(0.26, 0.78),
      Offset(0.74, 0.78),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = size.shortestSide * 0.085;
    for (final p in _layouts[value] ?? const []) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiePipsPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
