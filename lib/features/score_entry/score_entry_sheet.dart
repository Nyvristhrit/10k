import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tenk_skin.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/errors/game_rule_violation.dart';
import '../../domain/models/game_rules.dart';
import '../../domain/models/player.dart';
import '../../domain/services/encounter_summary.dart';
import '../../domain/services/game_transition.dart';
import '../../domain/services/trash_targets.dart';
import '../../shared/trash/trash_taunts.dart';
import '../../shared/widgets/player_visuals.dart';
import '../game_board/encounter_alert.dart';
import '../game_board/game_actions.dart';

/// Palette de la saisie de score.
const Color _addGreen = Color(0xFF10B981); // vert émeraude des gros boutons «+»
const Color _validateGreen = Color(0xFF0E9E6E); // vert du bouton Valider
const Color _subtractRed = Color(0xFFE11D48); // rouge des petits «−»
const Color _offWhite = Color(0xFFF3FBF7); // blanc cassé du texte des boutons

/// Ouvre la fenêtre centrée de saisie du score d'un joueur (§10).
///
/// Grosse pop-up au milieu de l'écran avec de gros boutons, pour une saisie
/// lisible et rapide autour de la table.
Future<void> showScoreEntrySheet(
  BuildContext context,
  WidgetRef ref, {
  required Player player,
  required GameRules rules,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _ScoreEntryDialog(player: player, rules: rules),
  );
}

class _ScoreEntryDialog extends ConsumerStatefulWidget {
  const _ScoreEntryDialog({required this.player, required this.rules});

  final Player player;
  final GameRules rules;

  @override
  ConsumerState<_ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends ConsumerState<_ScoreEntryDialog> {
  int _amount = 0;
  String? _message;
  bool _busy = false;

  GameRules get rules => widget.rules;
  Player get player => widget.player;

  bool get _canValidate {
    if (_amount <= 0) return false;
    if (_amount % rules.scoreStep != 0) return false;
    // Tant que le total est à zéro (jamais sorti, ou retombé à 0), il faut
    // atteindre le minimum de sortie pour rentrer.
    if (player.score == 0 && _amount < rules.minimumEntryScore) {
      return false;
    }
    return true;
  }

  void _add(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _amount = (_amount + delta).clamp(0, 1 << 30);
      _message = null;
    });
  }

  void _clear() => setState(() {
        _amount = 0;
        _message = null;
      });

  Future<void> _validate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final controller = ref.read(gameControllerProvider.notifier);
    final result = await controller.recordScore(player.id, _amount);
    if (!mounted) return;

    if (result is Success) {
      HapticFeedback.mediumImpact();
      // Rencontre déclenchée ? On la montre à valider avant de refermer la
      // saisie (réglable dans les options).
      final summary =
          rules.encounterAlertsEnabled ? encounterOf(result.transition) : null;
      if (summary != null) {
        // Fige les totaux impactés (marqueur + victimes) à leur ancienne valeur
        // pendant l'alerte. Une fois validée, on lève le gel : les compteurs
        // rejoignent leur vraie valeur en s'animant — le marqueur qui grimpe,
        // les victimes qui décroissent — bien en vue, plutôt que caché derrière
        // la fenêtre.
        final freeze = ref.read(frozenScoresProvider.notifier);
        final prev = result.transition.previousState;
        final held = <String, int>{};
        final marker = prev.playerById(summary.markerId);
        if (marker != null) held[summary.markerId] = marker.score;
        for (final v in summary.victims) {
          final p = prev.playerById(v.playerId);
          if (p != null) held[v.playerId] = p.score;
        }
        freeze.state = held;

        await showEncounterAlert(context,
            state: result.transition.nextState, summary: summary);
        if (mounted) Navigator.of(context).pop();
        // On referme d'abord la saisie, puis on révèle la décroissance sur le
        // plateau redevenu visible.
        Future.delayed(const Duration(milliseconds: 240),
            () => freeze.state = const {});
        return;
      }
      Navigator.of(context).pop();
      return;
    }
    if (result is Failure) {
      switch (result.violation.code) {
        case GameRuleViolationCode.entryMinimumNotReached:
          setState(() {
            _busy = false;
            _message = 'Minimum de sortie : ${rules.minimumEntryScore} points.';
          });
        case GameRuleViolationCode.confirmationRequiredForOvershoot:
          setState(() => _busy = false);
          await _confirmOvershoot();
        default:
          setState(() {
            _busy = false;
            _message = 'Score invalide.';
          });
      }
    }
  }

  Future<void> _confirmOvershoot() async {
    final total = player.score + _amount;
    final trash = TenkSkin.of(context).trash;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(trash ? Taunts.overshootTitle : 'Dépassement'),
        content: Text(trash
            ? Taunts.overshootBody(
                player.displayName, total, rules.targetScore)
            : 'Ce score ferait monter ${player.displayName} à $total points.\n'
                'Dépasser ${rules.targetScore} compte comme un échec, et le '
                'score ne sera pas enregistré.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(trash ? Taunts.overshootCancel : 'Corriger')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(trash ? Taunts.overshootAccept : 'Confirmer l\'échec')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(gameControllerProvider.notifier)
        .recordScore(player.id, _amount, confirmed: true);
    if (mounted && result is Success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(player);
    final accent = Color(color.accentArgb ?? color.backgroundArgb);
    final scheme = Theme.of(context).colorScheme;
    final trash = TenkSkin.of(context).trash;
    final game = ref.watch(gameControllerProvider).value;
    final shamedId = trash && game != null ? lastPlaceId(game) : null;

    // Coupures affichées : la plus grosse en haut pour taper vite.
    final steps = <int>[1000, 500, 100, if (rules.scoreStep == 50) 50];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                      emojiInGame(player, trash: trash, shamedId: shamedId),
                      style: const TextStyle(fontSize: 34)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${player.displayName} — score du tour',
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$_amount',
                style: TextStyle(
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    letterSpacing: -2,
                    height: 1),
              ),
              const SizedBox(height: 6),
              Text('Total après validation : ${player.score + _amount}',
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
              const SizedBox(height: 20),
              for (final step in steps) ...[
                _StepRow(
                  amount: step,
                  onAdd: () => _add(step),
                  onSubtract: _amount >= step ? () => _add(-step) : null,
                ),
                const SizedBox(height: 12),
              ],
              if (_message != null) ...[
                const SizedBox(height: 4),
                Text(_message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFFFFB4A9), fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          foregroundColor: scheme.onSurfaceVariant,
                          side: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.5))),
                      onPressed: _amount == 0 ? null : _clear,
                      child: const Text('Effacer',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _validateGreen,
                        foregroundColor: _offWhite,
                        disabledBackgroundColor:
                            _validateGreen.withValues(alpha: 0.30),
                        disabledForegroundColor:
                            _offWhite.withValues(alpha: 0.55),
                        minimumSize: const Size.fromHeight(58),
                      ),
                      onPressed: _canValidate && !_busy ? _validate : null,
                      child: Text(_amount > 0 ? 'Valider +$_amount' : 'Valider',
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        await handlePass(context, ref, player);
                        if (mounted) navigator.pop();
                      },
                style:
                    TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
                icon: const Icon(Icons.block, size: 18),
                label: Text('Passer le tour de ${player.displayName}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une ligne de coupure : à gauche un petit bouton rouge « − » (≈10 %) pour
/// retirer la valeur, à droite le gros bouton vert « +N » (≈90 %).
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.amount,
    required this.onAdd,
    required this.onSubtract,
  });

  final int amount;
  final VoidCallback onAdd;
  final VoidCallback? onSubtract;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _subtractRed.withValues(alpha: 0.90),
                foregroundColor: _offWhite,
                disabledBackgroundColor: _subtractRed.withValues(alpha: 0.20),
                disabledForegroundColor: _offWhite.withValues(alpha: 0.35),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: onSubtract,
              child: const Text('−',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 9,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _addGreen,
                foregroundColor: _offWhite,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: onAdd,
              child: Text('+$amount',
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
