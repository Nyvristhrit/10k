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
import '../../l10n/l10n.dart';

/// Plateau de jeu interactif.
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

  /// Clé stable par joueur : la tuile est déplacée (vedette/grille) sans être
  /// recréée, ce qui préserve ses animations.
  final Map<String, GlobalKey> _tileKeys = {};
  GlobalKey _keyFor(String id) =>
      _tileKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void dispose() {
    // Seul écran qui garde l'écran allumé : on relâche toujours le verrou.
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Appliqué à chaque build (idempotent) pour suivre un changement de réglage.
    if (ref.watch(keepScreenOnEnabledProvider)) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    // Ouvre le résultat en fin de partie. Différé après la frame pour que le
    // `pop` de la saisie de score ferme bien la saisie, et pas cet écran.
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
    // Rebâtit les tuiles quand les totaux sont figés/révélés (rencontre).
    ref.watch(frozenScoresProvider);
    // Idem pour les taches du bon dernier (mode trash).
    ref.watch(cradoStainsProvider);
    ref.watch(cradoSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_title(game)),
        actions: [
          if (ref.watch(diceTrayEnabledProvider))
            IconButton(
              icon: const Icon(Icons.casino_outlined),
              tooltip: tr('Lancer des dés', 'Roll dice'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiceTrayScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: tr('Historique de la partie', 'Game history'),
            onPressed: () => _openHistory(context),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: tr('Annuler la dernière action', 'Undo last action'),
            onPressed: game?.lastActiveAction == null
                ? null
                : () => ref.read(gameControllerProvider.notifier).undo(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: tr('Règles du jeu', 'Game rules'),
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
    if (game.status == GameStatus.finalChance) return tr('Dernière chance', 'Last chance');
    if (game.roundState != null) return tr('Manche ${game.roundState!.roundNumber}', 'Round ${game.roundState!.roundNumber}');
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

  /// Dispose les tuiles sur toute la hauteur.
  ///
  /// À partir de 5 joueurs, le joueur dont c'est le tour passe en vedette en
  /// haut, les autres en grille dessous.
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
      // En paysage, la vedette passe à côté de la grille plutôt qu'au-dessus.
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

  /// Nombre de colonnes de la grille principale (une seule jusqu'à 4 joueurs
  /// en portrait, plus en paysage).
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

  /// Grille plein écran : rangées de hauteur égale.
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

  /// Construit une tuile de joueur.
  ///
  /// Appui long : la tuile suit le doigt. Lâchée sur un autre joueur, elle
  /// prend sa place ; relâchée sur place, on propose de quitter la partie.
  Widget _tile(BuildContext context, GameState game, Player p,
      String? currentId, String? shamedId,
      {required bool compact}) {
    // Pendant l'alerte de rencontre, on affiche l'ancien total figé.
    final overrideScore = ref.read(frozenScoresProvider)[p.id];
    final stains = p.id == shamedId && ref.read(cradoSettingsProvider).stains
        ? ref.read(cradoStainsProvider.notifier).countFor(game.id)
        : 0;
    PlayerBoardTile build({Key? key}) => PlayerBoardTile(
          key: key,
          player: p,
          isActive: p.id == currentId,
          maxLives: game.rules.maxLives,
          compact: compact,
          overrideScore: overrideScore,
          shamed: p.id == shamedId,
          stains: stains,
          onTap: () => _onTapTile(context, game, p),
        );
    final tile = build(key: _keyFor(p.id));

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (details.data == p.id) return false;
        HapticFeedback.selectionClick();
        return true;
      },
      onAcceptWithDetails: (details) {
        HapticFeedback.mediumImpact();
        ref
            .read(gameControllerProvider.notifier)
            .movePlayer(details.data, toSeatOf: p.id);
      },
      builder: (context, candidates, _) {
        final hovered = candidates.isNotEmpty;
        return LongPressDraggable<String>(
          data: p.id,
          hapticFeedbackOnStart: true,
          onDragStarted: () {
            _dragSize = _keyFor(p.id).currentContext?.size;
            _dragOrigin = null;
            _dragDistance = 0;
          },
          onDragUpdate: (details) {
            final origin =
                _dragOrigin ??= details.globalPosition - details.delta;
            final d = (details.globalPosition - origin).distance;
            if (d > _dragDistance) _dragDistance = d;
          },
          onDragEnd: (details) {
            if (!details.wasAccepted && _dragDistance < _kStillDragTolerance) {
              _confirmLeave(context, p);
            }
          },
          // La tuile volante vit dans l'Overlay, hors du Scaffold : le
          // Material lui redonne les styles de texte.
          feedback: Builder(
            builder: (context) => Material(
              type: MaterialType.transparency,
              child: SizedBox.fromSize(
                size: _dragSize ?? const Size(160, 120),
                child: Transform.rotate(
                  angle: -0.03,
                  child: Transform.scale(scale: 1.06, child: build()),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: tile),
          child: AnimatedScale(
            scale: hovered ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: hovered ? 0.55 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: tile,
            ),
          ),
        );
      },
    );
  }

  /// Distance (px) sous laquelle une tuile relâchée est considérée comme
  /// restée sur place (appui long simple, pas un déplacement).
  static const double _kStillDragTolerance = 16;

  // Suivi du glisser en cours (une seule tuile à la fois).
  Size? _dragSize;
  Offset? _dragOrigin;
  double _dragDistance = 0;

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
                      label: Text(tr('Passer — ${current.displayName}', 'Pass — ${current.displayName}')),
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      trash ? Taunts.freeModeHint : tr('Touche une tuile pour jouer', 'Tap a tile to play'),
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
                  : tr(
                      'Appui long sur un joueur : glisse-le pour changer de '
                          'place, ou relâche pour le faire quitter',
                      'Long-press a player: drag to move them to another '
                          'seat, or let go to make them leave'),
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
    // Partie terminée : plus de saisie (sinon le mode libre renverrait `true`).
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
          title: Text(tr('Ce n\'est pas au tour de ${player.displayName}.', 'It\'s not ${player.displayName}\'s turn.')),
          content: Text(tr('Faire jouer ${player.displayName} maintenant ?', 'Let ${player.displayName} play now?')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('Annuler', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('Choisir ${player.displayName}', 'Pick ${player.displayName}'))),
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
                : tr('${player.displayName} a déjà joué son tour.', '${player.displayName} has already played this round.'))),
      );
    }
  }

  Future<void> _confirmLeave(BuildContext context, Player player) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Faire quitter ${player.displayName} ?', 'Remove ${player.displayName} from the game?')),
        content: Text(tr(
            '${player.displayName} ne jouera plus jusqu\'à la fin de la partie. '
                'Son score reste affiché dans le classement final.\n\n'
                '(Tu pourras annuler avec la flèche « retour arrière ».)',
            '${player.displayName} won\'t play again until the end of the game. '
                'Their score stays in the final rankings.\n\n'
                '(You can undo with the “back” arrow.)')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Annuler', 'Cancel'))),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB3261E)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Quitter la partie', 'Leave the game'))),
        ],
      ),
    );
    if (confirmed != true) return;
    final result =
        await ref.read(gameControllerProvider.notifier).leaveGame(player.id);
    if (result is Failure) {
      messenger.showSnackBar(SnackBar(
          content: Text(result.violation.message ??
              tr('Ce joueur ne peut pas quitter maintenant.', 'This player can\'t leave right now.'))));
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
            ? tr('Dernière chance de ${current.displayName} ($remaining derrière)', '${current.displayName}\'s last chance ($remaining behind)')
            : tr('Dernière chance — ${current.displayName} ($remaining à jouer)', 'Last chance — ${current.displayName} ($remaining to play)');
      }
      return trash ? tr('Dernière chance. Ou pas.', 'Last chance. Or not.') : tr('Dernière chance !', 'Last chance!');
    }
    if (game.rules.turnMode != TurnMode.guided) {
      return trash
          ? Taunts.freeModeHint
          : tr('Touche la tuile d\'un joueur pour saisir son score.', 'Tap a player\'s tile to enter their score.');
    }
    final current = currentId == null ? null : game.playerById(currentId);
    if (current == null) return trash ? tr('Alors, on joue ?', 'So, are we playing?') : tr('À vous de jouer', 'Your turn to play');
    if (_phraseForId != current.id || _phraseTrash != trash) {
      _phraseForId = current.id;
      _phraseTrash = trash;
      _phrase = _phrases.forName(current.displayName, trash: trash);
    }
    return _phrase;
  }
}
