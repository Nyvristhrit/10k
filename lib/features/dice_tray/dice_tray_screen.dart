import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tenk_skin.dart';
import '../../shared/widgets/app_background.dart';

/// Nombre de dés du 10 000.
const int _kDiceCount = 6;

/// Palette dédiée aux dés : 12 teintes réparties **également** sur le cercle
/// chromatique (pas de mode/violet qui revient trop souvent — contrairement à
/// la palette d'accent générale de l'appli, plus resserrée sur les
/// bleus/violets). Générée en HSL plutôt que recopiée à la main : la
/// répartition égale garantit que deux tirages ne se ressemblent jamais trop,
/// et la saturation/luminosité sont réglées pour rester chatoyantes sans
/// virer criardes (mode sage) ou repousser vers le pastel (mode trash, plus
/// saturé pour le ton néon).
List<Color> _evenlySpacedPalette({
  required int count,
  required double saturation,
  required double lightness,
  double offsetDegrees = 0,
}) {
  final step = 360 / count;
  return [
    for (var i = 0; i < count; i++)
      HSLColor.fromAHSL(1, (offsetDegrees + i * step) % 360, saturation, lightness)
          .toColor(),
  ];
}

final List<Color> _diceAccentSeeds =
    _evenlySpacedPalette(count: 12, saturation: 0.68, lightness: 0.56);
final List<Color> _diceTrashAccentSeeds = _evenlySpacedPalette(
    count: 12, saturation: 0.92, lightness: 0.55, offsetDegrees: 15);

/// Noir strictement neutre (R=V=B), pour mélanger un accent sans jamais le
/// tirer vers une autre teinte — un noir même très légèrement bleuté ou
/// violacé suffit à faire virer un orange/jaune vers le marron ou l'olive
/// une fois mélangé.
const Color _neutralInk = Color(0xFF141414);

/// Teinte opposée sur le cercle chromatique (rotation de 180° en HSL) — un
/// magenta appelle un vert, un cyan appelle un orange, etc. Utilisée pour que
/// les points d'un dé (et son liseré « gardé ») ressortent nettement de sa
/// face au lieu de s'y fondre.
Color _complementaryHue(Color c) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withHue((hsl.hue + 180) % 360).toColor();
}

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
  bool _pressed = false;

  /// Teinte tirée au hasard à l'ouverture de cet écran, dans la palette dédiée
  /// aux dés (voir plus haut) — figée une fois choisie (pas de retirage à
  /// chaque reconstruction).
  Color? _accent;
  Color _accentFor(bool trash) {
    final palette = trash ? _diceTrashAccentSeeds : _diceAccentSeeds;
    return _accent ??= palette[_random.nextInt(palette.length)];
  }

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
    final trash = TenkSkin.of(context).trash;
    final accent = _accentFor(trash);
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
                Expanded(child: _mat(context, accent)),
                const SizedBox(height: 16),
                if (_anyHeld)
                  TextButton(
                    onPressed: _releaseAll,
                    child: const Text('Tout libérer'),
                  ),
                _rollButton(context, accent, label, unheld),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Le bouton de lancer : teinté par l'accent de la session (mélangé au
  /// blanc/noir uniquement — jamais à une autre teinte fixe, pour ne jamais
  /// retomber sur un mélange terreux), avec un petit rebond au clic.
  Widget _rollButton(
      BuildContext context, Color accent, String label, int unheld) {
    final enabled = unheld > 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = Color.lerp(accent, dark ? Colors.black : Colors.white,
        dark ? 0.25 : 0.15)!;
    final onButtonColor =
        ThemeData.estimateBrightnessForColor(buttonColor) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: enabled ? _roll : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              backgroundColor: buttonColor,
              disabledBackgroundColor: buttonColor.withValues(alpha: 0.35),
              foregroundColor: onButtonColor,
              disabledForegroundColor: onButtonColor.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: enabled ? 6 : 0,
              shadowColor: accent.withValues(alpha: 0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_hasRolled ? '🎲' : '✋', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Le tapis : un fond neutre et stable posé sous les dés (jamais teinté par
  /// l'accent — le mélanger à une couleur fixe est ce qui donnait des tons
  /// terreux ratés selon la teinte tirée). La couleur de la session vit
  /// uniquement sur les dés eux-mêmes. Grille 3×2 qui s'adapte à la place
  /// disponible (portrait comme paysage).
  Widget _mat(BuildContext context, Color accent) {
    final trash = TenkSkin.of(context).trash;
    final matColor = trash ? const Color(0xFF1A0026) : const Color(0xFF122A22);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(matColor, Colors.black, 0.15)!,
            matColor,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                    accent: accent,
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
    required this.accent,
    required this.onTap,
    super.key,
  });

  final int value;
  final bool held;
  final int spinToken;
  final double size;

  /// Teinte tirée au hasard à l'ouverture du plateau (voir
  /// `_DiceTrayScreenState._accentFor`).
  final Color accent;
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
    // Face teintée par l'accent tiré à l'ouverture — des dés roses, violets,
    // cyan… selon la partie, un peu comme le reste de la DA.
    // Mélangé au NOIR NEUTRE seulement (jamais à un noir teinté — c'est
    // justement ce genre de mélange entre deux teintes non liées qui donnait
    // des dés marron/olive ratés selon l'accent tiré, signalé par Ben).
    final base = trash
        ? Color.lerp(_neutralInk, widget.accent, 0.32)!
        : Color.lerp(Colors.white, widget.accent, 0.20)!;
    // Les points ET le liseré « gardé » prennent la même teinte
    // COMPLÉMENTAIRE de cet accent (opposée sur le cercle chromatique) :
    // les deux ressortent nettement de la face au lieu de s'y fondre, et
    // restent cohérents entre eux (signalé : ils ne matchaient pas).
    final complement = _complementaryHue(widget.accent);
    final pip = trash
        ? Color.lerp(complement, Colors.white, 0.2)!
        : Color.lerp(_neutralInk, complement, 0.55)!;
    final heldRing = trash
        ? Color.lerp(complement, Colors.white, 0.15)!
        : complement;

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
                  border:
                      widget.held ? Border.all(color: heldRing, width: 3) : null,
                  boxShadow: [
                    BoxShadow(
                      color: widget.held
                          ? heldRing.withValues(alpha: 0.55)
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
