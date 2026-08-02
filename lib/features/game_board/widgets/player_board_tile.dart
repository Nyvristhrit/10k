import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/models/player.dart';
import '../../../shared/animations/count_up_text.dart';
import '../../../shared/widgets/player_visuals.dart';

/// Tuile d'un joueur sur le plateau (§8.1), avec dégradé, ombre colorée et,
/// pour le joueur actif, un halo doux qui pulse lentement (§8.4).
class PlayerBoardTile extends StatefulWidget {
  const PlayerBoardTile({
    required this.player,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
    this.maxLives = 3,
    this.compact = false,
    this.overrideScore,
    super.key,
  });

  final Player player;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int maxLives;
  final bool compact;

  /// Score à afficher à la place du vrai total, le temps de l'alerte de
  /// rencontre (voir `frozenScoresProvider`). `null` = affiche le vrai score.
  final int? overrideScore;

  /// Le total réellement affiché sur la tuile.
  int get displayScore => overrideScore ?? player.score;

  @override
  State<PlayerBoardTile> createState() => _PlayerBoardTileState();
}

class _PlayerBoardTileState extends State<PlayerBoardTile>
    with TickerProviderStateMixin {
  static const Color _hitRed = Color(0xFFFF3B57);

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  // Effet « touché » : joué quand le joueur perd une vie ou des points. Sa
  // valeur va de 1 (impact) à 0 (repos) → sert à la fois à la secousse et au
  // rougissement de la bordure/du halo.
  late final AnimationController _hit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  bool _pressed = false;

  @override
  void didUpdateWidget(covariant PlayerBoardTile old) {
    super.didUpdateWidget(old);
    final lostLife = widget.player.lives < old.player.lives;
    // On se base sur le score AFFICHÉ : ainsi la secousse « touché » joue au
    // moment où le compteur décroît réellement (à la levée du gel), pas pendant
    // que l'alerte masque encore le plateau.
    final lostPoints = widget.displayScore < old.displayScore;
    if (lostLife || lostPoints) {
      _hit.reverse(from: 1.0); // 1 → 0 : impact puis retour au calme
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    _hit.dispose();
    super.dispose();
  }

  Color _shift(Color c, double factor) {
    return Color.fromARGB(
      255,
      (c.r * 255 * factor).clamp(0, 255).round(),
      (c.g * 255 * factor).clamp(0, 255).round(),
      (c.b * 255 * factor).clamp(0, 255).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = colorFor(widget.player);
    final base = Color(token.backgroundArgb);
    final accent = Color(token.accentArgb ?? token.backgroundArgb);
    final fg = Color(token.foregroundArgb);
    final player = widget.player;
    final last = player.lastActiveGain;

    return AnimatedBuilder(
      animation: Listenable.merge([_glow, _hit]),
      builder: (context, child) {
        final t = widget.isActive ? _glow.value : 0.0;
        // Intensité du « touché » (1 à l'impact, 0 au repos) et secousse
        // horizontale qui oscille en s'amortissant.
        final hit = _hit.value;
        final shakeX =
            hit == 0 ? 0.0 : sin((1 - hit) * pi * 6) * 8.0 * hit;

        // Bordure : blanche (active/inactive) qui vire au rouge quand touché.
        final baseBorderColor = widget.isActive
            ? Colors.white.withValues(alpha: 0.55 + 0.35 * t)
            : Colors.white.withValues(alpha: 0.06);
        final borderColor = Color.lerp(baseBorderColor, _hitRed, hit)!;
        final borderWidth =
            (widget.isActive ? 2.5 : 1.0) + 1.5 * hit;

        return Transform.translate(
          offset: Offset(shakeX, 0),
          child: GestureDetector(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_shift(base, 1.12), _shift(base, 0.82)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: borderWidth),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isActive ? accent : base).withValues(
                          alpha: widget.isActive ? 0.35 + 0.30 * t : 0.20),
                      blurRadius: widget.isActive ? 26 + 12 * t : 14,
                      spreadRadius: widget.isActive ? 1 : 0,
                      offset: const Offset(0, 8),
                    ),
                    // Halo rouge de dégât, superposé et fondu au repos.
                    if (hit > 0)
                      BoxShadow(
                        color: _hitRed.withValues(alpha: 0.55 * hit),
                        blurRadius: 30 * hit,
                        spreadRadius: 2 * hit,
                      ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emojiFor(player),
                    style: TextStyle(fontSize: widget.compact ? 26 : 32)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    player.displayName,
                    style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: widget.compact ? 15 : 19),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _Hearts(
                    lives: player.lives,
                    maxLives: widget.maxLives,
                    compact: widget.compact),
              ],
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: CountUpText(
                    value: widget.displayScore,
                    // Un peu plus lent que par défaut : on veut bien voir le
                    // compteur grimper à la marque et décroître à la rencontre.
                    duration: const Duration(milliseconds: 1100),
                    style: TextStyle(
                        color: fg,
                        fontSize: 96,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1),
                  ),
                ),
              ),
            ),
            Text(
              last == null
                  ? 'Dernier gain : —'
                  : 'Dernier gain : +${last.amount}',
              style: TextStyle(
                  color: fg.withValues(alpha: 0.82),
                  fontSize: widget.compact ? 12 : 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rangée de cœurs façon « conteneurs de vie » (Zelda) : une capsule sombre
/// tient des cœurs rouges bien visibles. Quand un cœur est perdu, son intérieur
/// tombe et s'efface, ne laissant que le contour vide.
class _Hearts extends StatelessWidget {
  const _Hearts({
    required this.lives,
    required this.maxLives,
    required this.compact,
  });

  final int lives;
  final int maxLives;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 18.0 : 22.0;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 7, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxLives, (i) {
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : (compact ? 2 : 3)),
            child: _Heart(filled: i < lives, size: size),
          );
        }),
      ),
    );
  }
}

/// Un cœur : contour (conteneur) toujours visible, intérieur rouge par-dessus.
/// À la perte, l'intérieur chute + s'efface via une petite animation.
class _Heart extends StatefulWidget {
  const _Heart({required this.filled, required this.size});

  final bool filled;
  final double size;

  @override
  State<_Heart> createState() => _HeartState();
}

class _HeartState extends State<_Heart> with SingleTickerProviderStateMixin {
  static const Color _red = Color(0xFFFF3B57);

  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void didUpdateWidget(covariant _Heart old) {
    super.didUpdateWidget(old);
    if (old.filled && !widget.filled) {
      _drop.forward(from: 0); // cœur perdu → l'intérieur tombe
    } else if (!old.filled && widget.filled) {
      _drop.reset(); // cœur regagné (annulation) → réapparaît plein
    }
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Le conteneur (contour) : toujours là.
          Icon(Icons.favorite, size: s, color: Colors.black.withValues(alpha: 0.35)),
          Icon(Icons.favorite_border,
              size: s, color: Colors.white.withValues(alpha: 0.85)),
          // L'intérieur rouge, qui tombe quand on perd le cœur.
          AnimatedBuilder(
            animation: _drop,
            builder: (context, child) {
              final falling = _drop.isAnimating || _drop.isCompleted;
              final show = widget.filled || falling;
              if (!show) return const SizedBox.shrink();
              final v = _drop.value;
              final drop = falling ? Curves.easeIn.transform(v) : 0.0;
              final opacity = falling ? (1 - v).clamp(0.0, 1.0) : 1.0;
              return Transform.translate(
                offset: Offset(0, drop * s * 1.6),
                child: Transform.rotate(
                  angle: drop * 0.5,
                  child: Opacity(
                    opacity: opacity.toDouble(),
                    child: child,
                  ),
                ),
              );
            },
            child: Icon(Icons.favorite, size: s * 0.82, color: _red),
          ),
        ],
      ),
    );
  }
}
