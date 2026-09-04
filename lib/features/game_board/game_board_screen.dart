import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/services/game_transition.dart';
import '../../domain/services/trash_targets.dart';
import '../../shared/trash/trash_taunts.dart';
import '../../shared/turn_phrases.dart';
import '../../shared/widgets/app_background.dart';
import '../dice_tray/dice_tray_screen.dart';
import '../game_result/game_result_screen.dart';
import '../info/info_screen.dart';
import '../score_entry/score_entry_sheet.dart';
import 'game_actions.dart';
import 'game_history_screen.dart';
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
  bool? _phraseTrash;
  String _phrase = '';
  bool _resultShown = false;

  /// Une clé stable par joueur : permet à Flutter de *déplacer* la tuile (par ex.
  /// de la vedette vers la grille) sans la recréer, ce qui préserve l'animation
  /// du score qui grimpe et le halo.
  final Map<String, GlobalKey> _tileKeys = {};
  GlobalKey _keyFor(String id) =>
      _tileKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void dispose() {
    // Ce plateau est le seul écran à réclamer le verrou d'écran (§ réglage
    // « Garder l'écran allumé ») : on le relâche systématiquement en le
    // quittant, qu'il ait été activé ou non.
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écran allumé pendant la partie seulement, et seulement si le réglage
    // est actif (économie de batterie). On le suit à chaque reconstruction
    // plutôt que de ne le lire qu'une fois : `enable`/`disable` sont idempotents
    // côté plateforme, et ça couvre le cas où le réglage change en route.
    if (ref.watch(keepScreenOnEnabledProvider)) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    // Navigue vers le résultat dès que la partie est terminée.
    //
    // On diffère l'ouverture au *post-frame* : la pop-up de saisie de score se
    // referme d'elle-même (via `Navigator.pop`) dans la micro-tâche qui suit la
    // validation ; en poussant l'écran de résultat après la frame, on garantit
    // que ce `pop` ferme bien la pop-up — et non l'écran de victoire qu'on vient
    // d'ouvrir. Sans ce délai, les deux se télescopaient (course), la pop-up
    // restait ouverte sur une partie déjà terminée, et plus aucun score ne
    // pouvait être validé.
    ref.listen(gameControllerProvider, (prev, next) {
      final status = next.value?.status;
      if (status == GameStatus.finished && !_resultShown) {
        _resultShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GameResultScreen()));
        });
      }
    });

    final game = ref.watch(gameControllerProvider).value;
    // Dépendance au gel des scores : rebâtit les tuiles quand on fige/révèle les
    // totaux autour d'une rencontre (les tuiles lisent la valeur dans `_tile`).
    ref.watch(frozenScoresProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_title(game)),
        actions: [
          if (ref.watch(diceTrayEnabledProvider))
            IconButton(
              icon: const Icon(Icons.casino_outlined),
              tooltip: 'Lancer des dés',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiceTrayScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique de la partie',
            onPressed: () => _openHistory(context),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Annuler la dernière action',
            onPressed: game?.lastActiveAction == null
                ? null
                : () => ref.read(gameControllerProvider.notifier).undo(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Règles du jeu',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InfoScreen()),
            ),
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
    final trash = TenkSkin.of(context).trash;
    // Le bonnet d'âne du mode trash : le bon dernier perd son totem.
    final shamedId = trash ? lastPlaceId(game) : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text(
            _bannerText(game, currentId, trash),
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
            child: _playerGrid(context, game, players, currentId, shamedId),
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
      List<Player> players, String? currentId, String? shamedId) {
    final n = players.length;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final hasActive =
        currentId != null && players.any((p) => p.id == currentId);
    if (hasActive && n >= 5) {
      final active = players.firstWhere((p) => p.id == currentId);
      final rest = [
        for (final p in players)
          if (p.id != currentId) p
      ];
      final restCols = _restColumns(rest.length, landscape: landscape);
      final spotlight = Padding(
        padding: const EdgeInsets.all(6),
        child:
            _tile(context, game, active, currentId, shamedId, compact: false),
      );
      final restGrid = _grid(context, game, rest, currentId, shamedId,
          cols: restCols);
      // En paysage, la largeur excédentaire (pas la hauteur) : la vedette
      // passe à côté du reste plutôt qu'au-dessus, sinon les deux se
      // retrouvent écrasées en hauteur sur un écran large et court.
      return landscape
          ? Row(children: [
              Expanded(flex: 4, child: spotlight),
              Expanded(flex: 6, child: restGrid),
            ])
          : Column(children: [
              Expanded(flex: 5, child: spotlight),
              Expanded(flex: 7, child: restGrid),
            ]);
    }
    final cols = _columnsFor(n, landscape: landscape);
    return _grid(context, game, players, currentId, shamedId, cols: cols);
  }

  /// Nombre de colonnes de la grille principale. En portrait, on privilégie
  /// des blocs pleine largeur (une colonne jusqu'à 4 joueurs) ; en paysage,
  /// l'écran est large et court, donc on étale plutôt les tuiles en largeur
  /// pour éviter des blocs écrasés.
  int _columnsFor(int n, {required bool landscape}) {
    if (landscape) {
      if (n <= 2) return 2;
      if (n <= 4) return 2;
      if (n <= 8) return 4;
      return 4;
    }
    if (n <= 4) return 1;
    if (n <= 8) return 2;
    return 3;
  }

  /// Colonnes de la grille secondaire (sous/à côté de la vedette).
  int _restColumns(int restCount, {required bool landscape}) {
    if (landscape) return restCount <= 6 ? 3 : 4;
    return restCount <= 8 ? 2 : 3;
  }

  /// Grille « plein écran » avec un nombre de colonnes donné. Chaque rangée se
  /// partage la hauteur à parts égales ; les tuiles d'une rangée se partagent la
  /// largeur.
  Widget _grid(BuildContext context, GameState game, List<Player> players,
      String? currentId, String? shamedId,
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
                            currentId, shamedId,
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
  Widget _tile(BuildContext context, GameState game, Player p,
      String? currentId, String? shamedId,
      {required bool compact}) {
    // Pendant l'alerte de rencontre, on affiche l'ancien total figé ; à la
    // fermeture, le gel est levé et le compteur rejoint la vraie valeur.
    final overrideScore = ref.read(frozenScoresProvider)[p.id];
    return PlayerBoardTile(
      key: _keyFor(p.id),
      player: p,
      isActive: p.id == currentId,
      maxLives: game.rules.maxLives,
      compact: compact,
      overrideScore: overrideScore,
      shamed: p.id == shamedId,
      onTap: () => _onTapTile(context, game, p),
      onLongPress: () => _confirmLeave(context, p),
    );
  }

  Widget _bottomBar(BuildContext context, GameState game, String? currentId) {
    final trash = TenkSkin.of(context).trash;
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
                      trash ? Taunts.freeModeHint : 'Touche une tuile pour jouer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              trash
                  ? Taunts.leaveHint
                  : 'Appui long sur un joueur pour le faire quitter la partie',
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

  void _openHistory(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameHistoryScreen()),
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
    // Partie terminée : plus aucune saisie (en mode libre, la branche par défaut
    // renverrait `true` à tort, laissant croire qu'on peut encore jouer).
    if (game.status == GameStatus.finished ||
        game.status == GameStatus.archived) {
      return false;
    }
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
      final trash = TenkSkin.of(context).trash;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(trash
                ? Taunts.alreadyPlayed(player.displayName)
                : '${player.displayName} a déjà joué son tour.')),
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

  String _bannerText(GameState game, String? currentId, bool trash) {
    if (game.status == GameStatus.finalChance) {
      final fc = game.finalChanceState!;
      final remaining = fc.pendingPlayerIds.length;
      final current = fc.currentPlayerId == null
          ? null
          : game.playerById(fc.currentPlayerId!);
      if (current != null) {
        return trash
            ? 'Dernière chance de ${current.displayName} ($remaining derrière)'
            : 'Dernière chance — ${current.displayName} ($remaining à jouer)';
      }
      return trash ? 'Dernière chance. Ou pas.' : 'Dernière chance !';
    }
    if (game.rules.turnMode != TurnMode.guided) {
      return trash
          ? Taunts.freeModeHint
          : 'Touche la tuile d\'un joueur pour saisir son score.';
    }
    final current = currentId == null ? null : game.playerById(currentId);
    if (current == null) return trash ? 'Alors, on joue ?' : 'À vous de jouer';
    if (_phraseForId != current.id || _phraseTrash != trash) {
      _phraseForId = current.id;
      _phraseTrash = trash;
      _phrase = _phrases.forName(current.displayName, trash: trash);
    }
    return _phrase;
  }
}
