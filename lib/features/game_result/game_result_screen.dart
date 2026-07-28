import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../shared/animations/confetti.dart';
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
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
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
              child: Text('VICTOIRE',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3)),
            ),
          ),
          if (winner != null) ...[
            const SizedBox(height: 10),
            Entrance(
              delay: const Duration(milliseconds: 260),
              child: Text('${emojiFor(winner)}  ${winner.displayName}',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800)),
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
                child: _row(i + 1, ranking[i]),
              ),
            ),
          ),
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

  Widget _row(int rank, Player player) {
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
          Text(emojiFor(player), style: const TextStyle(fontSize: 22)),
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
