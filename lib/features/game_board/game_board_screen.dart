import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/services/game_transition.dart';
import '../../shared/turn_phrases.dart';
import '../../shared/widgets/app_background.dart';
import '../game_result/game_result_screen.dart';
import '../score_entry/score_entry_sheet.dart';
import 'game_actions.dart';
import 'widgets/player_board_tile.dart';

/// Plateau de jeu interactif (§8, §9, §10, §12).
class GameBoardScreen extends ConsumerStatefulWidget {
  const GameBoardScreen({super.key});

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
  final TurnPhrases _phrases = TurnPhrases();
  String? _phraseForId;
  String _phrase = '';
  bool _resultShown = false;

  /// Une clé stable par joueur : permet à Flutter de *déplacer* la tuile (par ex.
  /// de la vedette vers la grille) sans la recréer, ce qui préserve l'animation
  /// du score qui grimpe et le halo.
  final Map<String, GlobalKey> _tileKeys = {};
  GlobalKey _keyFor(String id) =>
      _tileKeys.putIfAbsent(id, () => GlobalKey());

  @override
  Widget build(BuildContext context) {
    // Navigue vers le résultat dès que la partie est terminée.
    ref.listen(gameControllerProvider, (prev, next) {
      final status = next.value?.status;
      if (status == GameStatus.finished && !_resultShown) {
        _resultShown = true;
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GameResultScreen()));
      }
    });

    final game = ref.watch(gameControllerProvider).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_title(game)),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Annuler la dernière action',
            onPressed: game?.lastActiveAction == null
                ? null
                : () => ref.read(gameControllerProvider.notifier).undo(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: game == null
              ? const Center(child: CircularProgressIndicator())
              : _body(context, game),
        ),
      ),
    );
  }

  String _title(GameState? game) {
    if (game == null) return '10K';
    if (game.status == GameStatus.finalChance) return 'Dernière chance';
    if (game.roundState != null) return 'Manche ${game.roundState!.roundNumber}';
    return '10K';
  }

  Widget _body(BuildContext context, GameState game) {
    final players = game.activePlayers;
    final currentId = _currentAllowedId(game);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text(
            _bannerText(game, currentId),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: _playerGrid(context, game, players, currentId),
          ),
        ),
        _bottomBar(context, game, currentId),
      ],
    );
  }

  /// Dispose les tuiles pour qu'elles occupent 100 % de la hauteur.
  ///
  /// Quand il y a **beaucoup de joueurs** (5+), le joueur dont c'est le tour est
  /// mis **en vedette** : une grande tuile tout en haut, et le reste en grille
  /// en dessous. On sait ainsi tout de suite qui doit jouer, et on évite la
  /// tuile « orpheline » toute en largeur en bas. À 2-4 joueurs, on garde les
  /// gros blocs fixes (plus lisibles, et ils ne bougent pas d'un tour à l'autre).
  Widget _playerGrid(BuildContext context, GameState game,
      List<Player> players, String? currentId) {
    final n = players.length;
    final hasActive =
        currentId != null && players.any((p) => p.id == currentId);
    if (hasActive && n >= 5) {
      final active = players.firstWhere((p) => p.id == currentId);
      final rest = [
        for (final p in players)
          if (p.id != currentId) p
      ];
      final restCols = rest.length <= 8 ? 2 : 3;
      return Column(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: _tile(context, game, active, currentId, compact: false),
            ),
          ),
          Expanded(
              flex: 7,
              child: _grid(context, game, rest, currentId, cols: restCols)),
        ],
      );
    }
    // Une seule colonne jusqu'à 4 joueurs (50 %, 33 %, 25 %…), deux colonnes de
    // 5 à 8, trois au-delà.
    final cols = n <= 4 ? 1 : (n <= 8 ? 2 : 3);
    return _grid(context, game, players, currentId, cols: cols);
  }

  /// Grille « plein écran » avec un nombre de colonnes donné. Chaque rangée se
  /// partage la hauteur à parts égales ; les tuiles d'une rangée se partagent la
  /// largeur.
  Widget _grid(BuildContext context, GameState game, List<Player> players,
      String? currentId,
      {required int cols}) {
    final n = players.length;
    final rows = (n / cols).ceil();
    final compact = cols >= 2;

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < cols; c++)
                  if (r * cols + c < n)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: _tile(context, game, players[r * cols + c],
                            currentId,
                            compact: compact),
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }

  /// Construit une tuile de joueur. La clé globale stable permet à Flutter de
  /// « suivre » (déplacer) la tuile quand elle passe de la grille à la vedette,
  /// sans la recréer : le score continue de s'animer et le halo reste intact.
  Widget _tile(BuildContext context, GameState game, Player p, String? currentId,
      {required bool compact}) {
    return PlayerBoardTile(
      key: _keyFor(p.id),
      player: p,
      isActive: p.id == currentId,
      maxLives: game.rules.maxLives,
      compact: compact,
      onTap: () => _onTapTile(context, game, p),
      onLongPress: () => _confirmLeave(context, p),
    );
  }

  Widget _bottomBar(BuildContext context, GameState game, String? currentId) {
    final guided = game.rules.turnMode == TurnMode.guided;
    final current = currentId == null ? null : game.playerById(currentId);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (guided && current != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52)),
                      onPressed: () => handlePass(context, ref, current),
                      icon: const Icon(Icons.block, size: 18),
                      label: Text('Passer — ${current.displayName}'),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'Touche une tuile pour jouer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Appui long sur un joueur pour le faire quitter la partie',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logique d'interaction ────────────────────────────────────────────────

  String? _currentAllowedId(GameState game) {
    if (game.rules.turnMode != TurnMode.guided) return null;
    if (game.status == GameStatus.finalChance) {
      return game.finalChanceState?.currentPlayerId;
    }
    return game.roundState?.currentPlayerId;
  }

  bool _canPlay(GameState game, Player player) {
    if (player.hasLeftGame) return false;
    final guided = game.rules.turnMode == TurnMode.guided;
    if (game.status == GameStatus.finalChance) {
      final fc = game.finalChanceState;
      if (fc == null) return false;
      return guided
          ? fc.currentPlayerId == player.id
          : fc.pendingPlayerIds.contains(player.id);
    }
    return guided ? game.roundState?.currentPlayerId == player.id : true;
  }

  Future<void> _onTapTile(
      BuildContext context, GameState game, Player player) async {
    if (_canPlay(game, player)) {
      await showScoreEntrySheet(context, ref, player: player, rules: game.rules);
      return;
    }
    // Mode guidé en cours : proposer de faire jouer ce joueur hors ordre.
    final guided = game.rules.turnMode == TurnMode.guided;
    final canSelect = guided &&
        game.status == GameStatus.inProgress &&
        (game.roundState?.pendingPlayerIds.contains(player.id) ?? false);
    if (canSelect) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Ce n\'est pas au tour de ${player.displayName}.'),
          content: Text('Faire jouer ${player.displayName} maintenant ?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Choisir ${player.displayName}')),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(gameControllerProvider.notifier).selectPlayer(player.id);
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${player.displayName} a déjà joué son tour.')),
      );
    }
  }

  Future<void> _confirmLeave(BuildContext context, Player player) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Faire quitter ${player.displayName} ?'),
        content: Text(
            '${player.displayName} ne jouera plus jusqu\'à la fin de la partie. '
            'Son score reste affiché dans le classement final.\n\n'
            '(Tu pourras annuler avec la flèche « retour arrière ».)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB3261E)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Quitter la partie')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result =
        await ref.read(gameControllerProvider.notifier).leaveGame(player.id);
    if (result is Failure) {
      messenger.showSnackBar(SnackBar(
          content: Text(result.violation.message ??
              'Ce joueur ne peut pas quitter maintenant.')));
    }
  }

  String _bannerText(GameState game, String? currentId) {
    if (game.status == GameStatus.finalChance) {
      final fc = game.finalChanceState!;
      final remaining = fc.pendingPlayerIds.length;
      final current = fc.currentPlayerId == null
          ? null
          : game.playerById(fc.currentPlayerId!);
      if (current != null) {
        return 'Dernière chance — ${current.displayName} ($remaining à jouer)';
      }
      return 'Dernière chance !';
    }
    if (game.rules.turnMode != TurnMode.guided) {
      return 'Touche la tuile d\'un joueur pour saisir son score.';
    }
    final current = currentId == null ? null : game.playerById(currentId);
    if (current == null) return 'À vous de jouer';
    if (_phraseForId != current.id) {
      _phraseForId = current.id;
      _phrase = _phrases.forName(current.displayName);
    }
    return _phrase;
  }
}
