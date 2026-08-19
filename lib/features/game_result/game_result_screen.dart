import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/services/game_facts.dart';
import '../../domain/services/trash_targets.dart';
import '../../shared/trash/trash_taunts.dart';
import '../../shared/animations/confetti.dart';
import '../../shared/animations/emoji_rain.dart';
import '../../shared/animations/entrance.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/player_visuals.dart';
import '../game_setup/game_setup_screen.dart';

/// Écran de résultat / classement (§20.7).
class GameResultScreen extends ConsumerStatefulWidget {
  const GameResultScreen({super.key});

  @override
  ConsumerState<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends ConsumerState<GameResultScreen> {
  // Les piques du mode trash sont tirées au sort **une seule fois** et
  // conservées : sans ça, elles changeraient à chaque reconstruction de l'écran
  // (arrivée des confettis, animations…), ce qui serait illisible.
  String _winnerLine = '';
  String? _loserLine;
  bool _linesReady = false;

  void _ensureTrashLines(GameState game, String? shamedId) {
    if (_linesReady) return;
    _linesReady = true;
    final winner = game.winnerPlayerId == null
        ? null
        : game.playerById(game.winnerPlayerId!);
    if (winner != null) _winnerLine = Taunts.winnerLine(winner.displayName);
    final shamed = shamedId == null ? null : game.playerById(shamedId);
    if (shamed != null) {
      _loserLine = Taunts.loserLine(shamed.displayName, shamed.score);
    }
  }

  @override
  void initState() {
    super.initState();
    // Petite salve de vibration pour fêter la victoire.
    HapticFeedback.heavyImpact();
    Future<void>.delayed(const Duration(milliseconds: 180),
        () => HapticFeedback.mediumImpact());
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider).value;
    final winner = game?.winnerPlayerId == null
        ? null
        : game!.playerById(game.winnerPlayerId!);
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            // Pluie de l'animal du vainqueur, en fond de la fête.
            if (winner != null)
              Positioned.fill(child: EmojiRainOverlay(emoji: emojiFor(winner))),
            SafeArea(
              child: game == null
                  ? const Center(child: CircularProgressIndicator())
                  : _content(context, game),
            ),
            const Positioned.fill(child: ConfettiOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, GameState game) {
    final trash = TenkSkin.of(context).trash;
    final shamedId = trash ? lastPlaceId(game) : null;
    final facts = GameFacts.of(game);
    if (trash) _ensureTrashLines(game, shamedId);
    final ranking = [...game.players]
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.seatIndex.compareTo(b.seatIndex);
      });
    final winner = game.winnerPlayerId == null
        ? null
        : game.playerById(game.winnerPlayerId!);

    final header = <Widget>[
      const SizedBox(height: 20),
      const Entrance(
        delay: Duration(milliseconds: 60),
        offset: Offset(0, -12),
        child: _PoppingTrophy(),
      ),
      Entrance(
        delay: const Duration(milliseconds: 160),
        child: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
          ).createShader(r),
          child: Text(trash ? Taunts.victoryTitle : 'VICTOIRE',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3)),
        ),
      ),
      if (winner != null) ...[
        const SizedBox(height: 14),
        Entrance(
          delay: const Duration(milliseconds: 230),
          child: _WinnerBadge(winner: winner),
        ),
        const SizedBox(height: 12),
        Entrance(
          delay: const Duration(milliseconds: 300),
          child: Text(winner.displayName,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        ),
        if (trash)
          Entrance(
            delay: const Duration(milliseconds: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                _winnerLine,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        Entrance(
          delay: const Duration(milliseconds: 340),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: winner.score.toDouble()),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text('${v.round()} points',
                style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ),
      ],
      const SizedBox(height: 24),
    ];

    final rankingBody = <Widget>[
      for (var i = 0; i < ranking.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Entrance(
            delay: Duration(milliseconds: 440 + i * 90),
            offset: const Offset(0, 18),
            child: _row(i + 1, ranking[i], trash, shamedId),
          ),
        ),
      const SizedBox(height: 8),
      Entrance(
        delay: const Duration(milliseconds: 520),
        child: _TallySheet(facts: facts),
      ),
      if (trash && _loserLine != null)
        Entrance(
          delay: const Duration(milliseconds: 560),
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              _loserLine!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      if (trash && facts.hasHighlights)
        Entrance(
          delay: const Duration(milliseconds: 600),
          child: _HallOfShame(facts: facts, game: game),
        ),
      const SizedBox(height: 12),
    ];

    final buttons = <Widget>[
      Entrance(
        delay: const Duration(milliseconds: 500),
        child: FilledButton(
          onPressed: () => _newGame(context),
          child: const Text('Nouvelle partie'),
        ),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        child: const Text('Retour à l\'accueil'),
      ),
      const SizedBox(height: 12),
    ];

    // Classement, bilan et palmarès défilent ensemble : sinon, à 8 ou 12
    // joueurs, le bas de l'écran se battrait pour quelques pixels. En paysage
    // (écran court), on va plus loin et fait défiler l'en-tête (trophée,
    // gagnant) avec le reste, plutôt qu'un bloc fixe qui risquerait à lui
    // seul de déborder sur les téléphones les plus courts.
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (!landscape) ...header,
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [if (landscape) ...header, ...rankingBody],
            ),
          ),
          ...buttons,
        ],
      ),
    );
  }

  Widget _row(int rank, Player player, bool trash, String? shamedId) {
    final token = colorFor(player, trash: trash);
    return Container(
      decoration: BoxDecoration(
        color: Color(token.backgroundArgb).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('$rank',
              style: TextStyle(
                  color: Color(token.foregroundArgb),
                  fontWeight: FontWeight.w900,
                  fontSize: 18)),
          const SizedBox(width: 14),
          Text(emojiInGame(player, trash: trash, shamedId: shamedId),
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(player.displayName,
                style: TextStyle(
                    color: Color(token.foregroundArgb),
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
                overflow: TextOverflow.ellipsis),
          ),
          Text('${player.score}',
              style: TextStyle(
                  color: Color(token.foregroundArgb),
                  fontWeight: FontWeight.w900,
                  fontSize: 18)),
        ],
      ),
    );
  }

  Future<void> _newGame(BuildContext context) async {
    final navigator = Navigator.of(context);
    await ref.read(gameControllerProvider.notifier).newGame();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GameSetupScreen()),
      (route) => route.isFirst,
    );
  }
}

/// Le bilan de la partie : combien de manches et de tours il aura fallu.
/// Affiché dans les deux modes — c'est une info de jeu, pas une pique.
class _TallySheet extends StatelessWidget {
  const _TallySheet({required this.facts});

  final GameFacts facts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final skin = TenkSkin.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(skin.corner),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Le mode libre ne compte pas de manches : on n'affiche alors que les
          // tours, plutôt qu'un « 0 manches » trompeur.
          if (facts.roundsPlayed > 0)
            _Tally(
                emoji: '🔁',
                value: '${facts.roundsPlayed}',
                label: facts.roundsPlayed > 1 ? 'manches' : 'manche'),
          _Tally(
              emoji: '🎲',
              value: '${facts.turnsPlayed}',
              label: facts.turnsPlayed > 1 ? 'tours joués' : 'tour joué'),
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Le palmarès de la honte : les titres décernés en fin de partie (mode trash).
///
/// Chaque titre n'apparaît que s'il a un vainqueur incontesté — un « gros
/// naze » ex æquo, ça n'amuse personne.
class _HallOfShame extends StatelessWidget {
  const _HallOfShame({required this.facts, required this.game});

  final GameFacts facts;
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final skin = TenkSkin.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: skin.neon.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(skin.corner),
        border: Border.all(color: skin.neon.withValues(alpha: 0.55), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Taunts.factsTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: skin.neon,
            ),
          ),
          const SizedBox(height: 10),
          _line(context, facts.biggestLoser, Taunts.factLoser),
          _line(context, facts.wrecker, Taunts.factWrecker),
          _line(context, facts.biggestHit, Taunts.factHit),
          _line(context, facts.mostMisses, Taunts.factMisses),
          const SizedBox(height: 4),
          Text(
            'Rien de personnel. Enfin, un peu.',
            style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    PlayerFact? fact,
    ({String emoji, String title, String line}) copy,
  ) {
    if (fact == null) return const SizedBox.shrink();
    final player = game.playerById(fact.playerId);
    if (player == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900)),
                Text(
                  Taunts.fact(copy.line, player.displayName, fact.value),
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grande pastille ronde aux couleurs du vainqueur, avec son animal en grand.
class _WinnerBadge extends StatelessWidget {
  const _WinnerBadge({required this.winner});

  final Player winner;

  @override
  Widget build(BuildContext context) {
    final token = colorFor(winner, trash: TenkSkin.of(context).trash);
    final base = Color(token.backgroundArgb);
    final accent = Color(token.accentArgb ?? token.backgroundArgb);
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, base],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.55),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emojiFor(winner), style: const TextStyle(fontSize: 54)),
    );
  }
}

/// Le trophée qui « surgit » avec un léger rebond au chargement.
class _PoppingTrophy extends StatefulWidget {
  const _PoppingTrophy();

  @override
  State<_PoppingTrophy> createState() => _PoppingTrophyState();
}

class _PoppingTrophyState extends State<_PoppingTrophy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    return ScaleTransition(
      scale: scale,
      child: const Text('🏆', style: TextStyle(fontSize: 68)),
    );
  }
}
