import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_state.dart';
import '../../shared/animations/entrance.dart';
import '../../shared/animations/falling_dice.dart';
import '../../shared/widgets/app_background.dart';
import '../game_board/game_board_screen.dart';
import '../game_result/game_result_screen.dart';
import '../game_setup/game_setup_screen.dart';
import '../info/info_screen.dart';

/// Écran d'accueil (§20.1).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gameControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            const Positioned.fill(child: FallingDice()),
            // Voile flou : transforme les dés en silhouettes douces derrière.
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: (dark ? Colors.black : Colors.white)
                        .withValues(alpha: dark ? 0.14 : 0.32),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur : $e')),
                  data: (game) => _content(context, ref, game),
                ),
              ),
            ),
            // Bascule jour/nuit dans le coin haut-gauche : la nuit on voit un
            // soleil (pour passer au jour), le jour une lune (pour passer à la
            // nuit).
            Positioned(
              top: 0,
              left: 4,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
                  iconSize: 28,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                  tooltip: dark ? 'Passer en mode jour' : 'Passer en mode nuit',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).toggle();
                  },
                ),
              ),
            ),
            // Petit « ? » dans le coin : aide, règles et à propos.
            Positioned(
              top: 0,
              right: 4,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.help_outline),
                  iconSize: 30,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  tooltip: 'Aide & règles du jeu',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InfoScreen()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, GameState? game) {
    final theme = Theme.of(context);
    final hasActive = game != null;

    return Column(
      children: [
        const Spacer(flex: 2),
        const Entrance(delay: Duration(milliseconds: 80), child: _BobbingDice()),
        const SizedBox(height: 12),
        Entrance(
          delay: const Duration(milliseconds: 220),
          child: FractionallySizedBox(
            widthFactor: 0.585,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              // On peint le dégradé arc-en-ciel DIRECTEMENT dans les lettres
              // (via `foreground`) plutôt qu'avec un ShaderMask par-dessus un
              // texte blanc : ainsi il n'y a plus de blanc dessous qui « perce »
              // au bout du 1 et du K en mode sombre. Stries franches (couleurs
              // doublées), avec le rouge et le violet un peu plus larges pour
              // bien remplir les pointes.
              child: Text('10K',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 1.0,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE11D48), Color(0xFFE11D48), // rouge
                          Color(0xFFF97316), Color(0xFFF97316), // orange
                          Color(0xFFFACC15), Color(0xFFFACC15), // jaune
                          Color(0xFF22C55E), Color(0xFF22C55E), // vert
                          Color(0xFF3B82F6), Color(0xFF3B82F6), // bleu
                          Color(0xFF8B5CF6), Color(0xFF8B5CF6), // violet
                        ],
                        stops: [
                          0.0, 0.2059, // rouge (élargi)
                          0.2059, 0.3529, // orange
                          0.3529, 0.5, // jaune
                          0.5, 0.6471, // vert
                          0.6471, 0.7941, // bleu
                          0.7941, 1.0, // violet (élargi)
                        ],
                      ).createShader(const Rect.fromLTWH(0, 0, 240, 120)),
                  )),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Entrance(
          delay: const Duration(milliseconds: 340),
          child: Text('Compagnon de jeu du 10 000',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        const Spacer(flex: 3),
        Entrance(
          delay: const Duration(milliseconds: 460),
          child: FilledButton(
            onPressed: () => _onNewGame(context, ref, hasActive),
            child: const Text('Nouvelle partie'),
          ),
        ),
        if (hasActive) ...[
          const SizedBox(height: 14),
          Entrance(
            delay: const Duration(milliseconds: 560),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              onPressed: () => _openGame(context, game),
              child: Text(_isOver(game.status)
                  ? 'Voir le résultat'
                  : 'Reprendre la partie'),
            ),
          ),
        ],
        const Spacer(flex: 2),
      ],
    );
  }

  Future<void> _onNewGame(
      BuildContext context, WidgetRef ref, bool hasActive) async {
    HapticFeedback.mediumImpact();
    final navigator = Navigator.of(context);
    if (hasActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remplacer la partie en cours ?'),
          content: const Text(
              'Une partie est déjà en cours. En créer une nouvelle l\'effacera.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remplacer')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(gameControllerProvider.notifier).newGame();
    navigator.push(
        MaterialPageRoute(builder: (_) => const GameSetupScreen()));
  }

  /// Une partie déjà jouée jusqu'au bout (gagnant désigné, ou archivée).
  bool _isOver(GameStatus status) =>
      status == GameStatus.finished || status == GameStatus.archived;

  void _openGame(BuildContext context, GameState game) {
    HapticFeedback.selectionClick();
    final Widget target;
    if (game.status == GameStatus.setup) {
      target = const GameSetupScreen();
    } else if (_isOver(game.status)) {
      // Partie terminée : on renvoie directement vers le classement, pas vers
      // le plateau (qui, la partie finie, serait figé et sans issue).
      target = const GameResultScreen();
    } else {
      target = const GameBoardScreen();
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => target));
  }
}

/// Le grand dé de l'accueil, qui flotte doucement (montée/descente + légère
/// bascule) pour égayer la page.
class _BobbingDice extends StatefulWidget {
  const _BobbingDice();

  @override
  State<_BobbingDice> createState() => _BobbingDiceState();
}

class _BobbingDiceState extends State<_BobbingDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -10 + 20 * t),
          child: Transform.rotate(angle: (-0.06 + 0.12 * t), child: child),
        );
      },
      child: const Text('🎲', style: TextStyle(fontSize: 82)),
    );
  }
}
