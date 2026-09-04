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

/// Types d'action qui représentent un « coup » jouable, affiché comme carte.
///
/// Les actions de préparation (ajout de joueur, réglages…) ne sont jamais
/// visibles ici : l'historique ne s'ouvre qu'en partie, où seules ces
/// actions-là peuvent encore exister.
const _kMoveTypes = {
  GameActionType.scoreRecorded,
  GameActionType.passRecorded,
  GameActionType.overshootRecorded,
  GameActionType.playerLeft,
};

/// Historique de la partie, groupé par manche décroissante (§ évolution
/// « consulter et revenir en arrière »).
///
/// Ouvert par un appui long sur la flèche retour du plateau. Chaque carte est
/// un coup joué ; y toucher propose de revenir exactement à cet instant (tout
/// ce qui a suivi est annulé, un coup à la fois, via le moteur).
class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).value;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Historique de la partie')),
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
    // Le plus récent en premier partout : le dernier coup joué de la manche
    // en cours tout en haut, jusqu'au tout premier coup de la manche 1 tout en
    // bas — sans rupture au passage d'une manche à l'autre.
    final moves = game.actions
        .where((a) => _kMoveTypes.contains(a.type) && !a.isUndone)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (moves.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun coup joué pour l\'instant.',
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
              guided && round > 0 ? 'Manche $round' : 'Partie',
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
                    child: Text('maintenant',
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
        title: const Text('Revenir à ce moment ?'),
        content: Text(remaining == 1
            ? 'Le dernier coup joué sera annulé.'
            : '$remaining coups joués depuis seront annulés.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Revenir ici')),
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
          const SnackBar(content: Text('Impossible de revenir à ce moment.')));
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
  final name = player?.displayName ?? 'Un joueur';
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
        detail = 'Percute $names';
      }
      final thirdMiss = _findEffect(
          action.effects, GameEffectType.gainCancelledByThirdMiss);
      if (thirdMiss != null) {
        detail = 'Troisième échec : dernier gain annulé';
      }
      return _MoveDescription(headline: '$name marque +$amount', detail: detail);
    case GameActionType.overshootRecorded:
      return _MoveDescription(
        headline: '$name dépasse le score cible',
        detail: action.attemptedScore == null
            ? null
            : 'Tentative de ${action.attemptedScore} refusée',
      );
    case GameActionType.passRecorded:
      final thirdMiss = _findEffect(
          action.effects, GameEffectType.gainCancelledByThirdMiss);
      return _MoveDescription(
        headline: '$name passe son tour',
        detail: thirdMiss == null ? null : 'Troisième échec : dernier gain annulé',
      );
    case GameActionType.playerLeft:
      return _MoveDescription(headline: '$name quitte la partie');
    default:
      return _MoveDescription(headline: name);
  }
}
