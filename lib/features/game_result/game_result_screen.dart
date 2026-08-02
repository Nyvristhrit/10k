import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
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
    if (trash) _ensureTrashLines(game, shamedId);
    final ranking = [...game.players]
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : a.seatIndex.compareTo(b.seatIndex);
      });
    final winner = game.winnerPlayerId == null
        ? null
        : game.playerById(game.winnerPlayerId!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
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
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900)),
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
          Expanded(
            child: ListView.separated(
              itemCount: ranking.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => Entrance(
                delay: Duration(milliseconds: 440 + i * 90),
                offset: const Offset(0, 18),
                child: _row(i + 1, ranking[i], trash, shamedId),
              ),
            ),
          ),
          if (trash && _loserLine != null) ...[
            Entrance(
              delay: const Duration(milliseconds: 520),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
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
          ],
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
        ],
      ),
    );
  }

  Widget _row(int rank, Player player, bool trash, String? shamedId) {
    final token = colorFor(player);
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

/// Grande pastille ronde aux couleurs du vainqueur, avec son animal en grand.
class _WinnerBadge extends StatelessWidget {
  const _WinnerBadge({required this.winner});

  final Player winner;

  @override
  Widget build(BuildContext context) {
    final token = colorFor(winner);
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
