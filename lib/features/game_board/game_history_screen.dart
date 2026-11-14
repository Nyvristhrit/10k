import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_action.dart';
import '../../domain/models/game_effect.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/services/encounter_summary.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/player_visuals.dart';
import '../../l10n/l10n.dart';

/// Types d'action affichés comme un coup dans l'historique.
const _kMoveTypes = {
  GameActionType.scoreRecorded,
  GameActionType.passRecorded,
  GameActionType.overshootRecorded,
  GameActionType.playerLeft,
};

/// Historique de la partie, par manche décroissante. Toucher un coup propose
/// d'y revenir (les coups suivants sont annulés).
class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(tr('Historique de la partie', 'Game history'))),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: game == null
              ? const SizedBox.shrink()
              : _body(context, ref, game),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, GameState game) {
    // Le plus récent en premier, y compris d'une manche à l'autre.
    final moves = game.actions
        .where((a) => _kMoveTypes.contains(a.type) && !a.isUndone)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (moves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tr('Aucun coup joué pour l\'instant.', 'No moves played yet.'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final grouped = <int, List<GameAction>>{};
    for (final move in moves) {
      grouped.putIfAbsent(move.roundNumber ?? 0, () => []).add(move);
    }
    final rounds = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final guided = game.rules.turnMode == TurnMode.guided;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final round in rounds) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              guided && round > 0 ? tr('Manche $round', 'Round $round') : tr('Partie', 'Game'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final action in grouped[round]!)
            _MoveCard(
              game: game,
              action: action,
              remaining: moves
                  .where((m) => m.createdAt.isAfter(action.createdAt))
                  .length,
            ),
        ],
      ],
    );
  }
}

class _MoveCard extends ConsumerWidget {
  const _MoveCard({
    required this.game,
    required this.action,
    required this.remaining,
  });

  final GameState game;
  final GameAction action;

  /// Nombre de coups plus récents qui seraient annulés en revenant ici.
  final int remaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trash = TenkSkin.of(context).trash;
    final player =
        action.primaryPlayerId == null ? null : game.playerById(action.primaryPlayerId!);
    final color = player == null ? null : colorFor(player, trash: trash);
    final bg = color == null
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : AppTheme.fromArgb(color.backgroundArgb);
    final fg = color == null
        ? Theme.of(context).colorScheme.onSurface
        : AppTheme.fromArgb(color.foregroundArgb);
    final description = _describe(game, action, player);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: remaining == 0 ? null : () => _confirmRevert(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player == null ? '❓' : emojiFor(player),
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description.headline,
                        style: TextStyle(
                            color: fg, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      if (description.detail != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description.detail!,
                          style: TextStyle(
                              color: fg.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                if (remaining > 0)
                  Icon(Icons.replay, color: fg.withValues(alpha: 0.7), size: 20)
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(tr('maintenant', 'now'),
                        style: TextStyle(
                            color: fg.withValues(alpha: 0.6), fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRevert(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Revenir à ce moment ?', 'Go back to this moment?')),
        content: Text(remaining == 1
            ? tr('Le dernier coup joué sera annulé.',
                'The last move will be undone.')
            : tr('$remaining coups joués depuis seront annulés.',
                '$remaining moves played since will be undone.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Annuler', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Revenir ici', 'Go back here'))),
        ],
      ),
    );
    if (confirmed != true) return;
    HapticFeedback.mediumImpact();
    final ok =
        await ref.read(gameControllerProvider.notifier).revertToAction(action.id);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text(tr('Impossible de revenir à ce moment.', 'Can\'t go back to this moment.'))));
    }
  }
}

class _MoveDescription {
  const _MoveDescription({required this.headline, this.detail});
  final String headline;
  final String? detail;
}

GameEffect? _findEffect(List<GameEffect> effects, GameEffectType type,
    {String? targetPlayerId}) {
  for (final e in effects) {
    if (e.type == type &&
        (targetPlayerId == null || e.targetPlayerId == targetPlayerId)) {
      return e;
    }
  }
  return null;
}

_MoveDescription _describe(GameState game, GameAction action, Player? player) {
  final name = player?.displayName ?? tr('Un joueur', 'A player');
  switch (action.type) {
    case GameActionType.scoreRecorded:
      final gain = _findEffect(action.effects, GameEffectType.scoreGainCreated,
          targetPlayerId: action.primaryPlayerId);
      final amount = gain?.delta ?? 0;
      final encounter = encounterOfAction(action);
      String? detail;
      if (encounter != null) {
        final names = encounter.victims.map((v) {
          final vp = game.playerById(v.playerId);
          final emoji = vp == null ? '' : '${emojiFor(vp)} ';
          return '$emoji${vp?.displayName ?? '?'} (−${v.amountLost})';
        }).join(', ');
        detail = tr('Percute $names', 'Hits $names');
      }
      final thirdMiss = _findEffect(
          action.effects, GameEffectType.gainCancelledByThirdMiss);
      if (thirdMiss != null) {
        detail = tr('Troisième échec : dernier gain annulé', 'Third miss: last gain cancelled');
      }
      return _MoveDescription(headline: tr('$name marque +$amount', '$name scores +$amount'), detail: detail);
    case GameActionType.overshootRecorded:
      return _MoveDescription(
        headline: tr('$name dépasse le score cible', '$name goes past the target'),
        detail: action.attemptedScore == null
            ? null
            : tr('Tentative de ${action.attemptedScore} refusée', 'Attempt of ${action.attemptedScore} refused'),
      );
    case GameActionType.passRecorded:
      final thirdMiss = _findEffect(
          action.effects, GameEffectType.gainCancelledByThirdMiss);
      return _MoveDescription(
        headline: tr('$name passe son tour', '$name passes'),
        detail: thirdMiss == null ? null : tr('Troisième échec : dernier gain annulé', 'Third miss: last gain cancelled'),
      );
    case GameActionType.playerLeft:
      return _MoveDescription(headline: tr('$name quitte la partie', '$name leaves the game'));
    default:
      return _MoveDescription(headline: name);
  }
}
