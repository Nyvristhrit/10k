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
import '../../shared/trash/crado_stains.dart';
import '../../shared/trash/trash_taunts.dart';
import '../../shared/widgets/player_visuals.dart';
import '../game_board/encounter_alert.dart';
import '../../l10n/l10n.dart';

/// Palette de la saisie de score.
const Color _addGreen = Color(0xFF10B981); // vert émeraude des gros boutons «+»
const Color _validateGreen = Color(0xFF0E9E6E); // vert du bouton Valider
const Color _subtractRed = Color(0xFFE11D48); // rouge des petits «−»
const Color _offWhite = Color(0xFFF3FBF7); // blanc cassé du texte des boutons

/// Espace entre deux gros boutons «+N».
const double _kRowGap = 12;

/// Ouvre la fenêtre de saisie du score d'un joueur.
Future<void> showScoreEntrySheet(
  BuildContext context,
  WidgetRef ref, {
  required Player player,
  required GameRules rules,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.86),
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
    // Total à zéro : il faut atteindre le minimum de sortie.
    if (player.score == 0 && _amount < rules.minimumEntryScore) {
      return false;
    }
    return true;
  }

  /// Le joueur est-il le bon dernier (mode trash) ? Évalué à l'ouverture.
  late final bool _isCrado = () {
    final game = ref.read(gameControllerProvider).value;
    return TenkSkin.of(context).trash &&
        game != null &&
        lastPlaceId(game) == player.id;
  }();

  /// Gag du bon dernier à chaque bouton touché : un prout et une tache.
  void _cradoTap() {
    if (!_isCrado) return;
    final crado = ref.read(cradoSettingsProvider);
    if (crado.farts) ref.read(fartPlayerProvider).play();
    final game = ref.read(gameControllerProvider).value;
    if (crado.stains && game != null) {
      ref.read(cradoStainsProvider.notifier).splash(game.id);
    }
  }

  void _add(int delta) {
    HapticFeedback.selectionClick();
    _cradoTap();
    setState(() {
      _amount = (_amount + delta).clamp(0, 1 << 30);
      _message = null;
    });
  }

  void _clear() {
    _cradoTap();
    setState(() {
      _amount = 0;
      _message = null;
    });
  }

  Future<void> _validate() async {
    if (_busy) return;
    _cradoTap();
    setState(() => _busy = true);
    final controller = ref.read(gameControllerProvider.notifier);
    final result = await controller.recordScore(player.id, _amount);
    if (!mounted) return;

    if (result is Success) {
      HapticFeedback.mediumImpact();
      // Rencontre : on l'affiche avant de refermer la saisie (si activé).
      final summary =
          rules.encounterAlertsEnabled ? encounterOf(result.transition) : null;
      if (summary != null) {
        // Fige les totaux concernés pendant l'alerte ; le gel est levé ensuite
        // pour que les compteurs s'animent à découvert.
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
        // Referme la saisie avant de lever le gel.
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
            _message = tr('Minimum de sortie : ${rules.minimumEntryScore} points.', 'Minimum to get in: ${rules.minimumEntryScore} points.');
          });
        case GameRuleViolationCode.confirmationRequiredForOvershoot:
          setState(() => _busy = false);
          await _confirmOvershoot();
        default:
          setState(() {
            _busy = false;
            _message = tr('Score invalide.', 'Invalid score.');
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
        title: Text(trash ? Taunts.overshootTitle : tr('Dépassement', 'Overshoot')),
        content: Text(trash
            ? Taunts.overshootBody(
                player.displayName, total, rules.targetScore)
            : tr(
                'Ce score ferait monter ${player.displayName} à $total points.\n'
                    'Dépasser ${rules.targetScore} compte comme un échec, et le '
                    'score ne sera pas enregistré.',
                'This score would take ${player.displayName} to $total points.\n'
                    'Going past ${rules.targetScore} counts as a miss, and the '
                    'score won\'t be recorded.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(trash ? Taunts.overshootCancel : tr('Corriger', 'Fix it'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(trash ? Taunts.overshootAccept : tr('Confirmer l\'échec', 'Confirm the miss'))),
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
    final trash = TenkSkin.of(context).trash;
    final color = colorFor(player, trash: trash);
    final accent = Color(color.accentArgb ?? color.backgroundArgb);
    final scheme = Theme.of(context).colorScheme;
    final game = ref.watch(gameControllerProvider).value;
    final shamedId = trash && game != null ? lastPlaceId(game) : null;
    final stains = _isCrado && ref.watch(cradoSettingsProvider).stains
        ? ref.watch(cradoStainsProvider.select(
            (s) => s.gameId == game?.id ? s.count : 0))
        : 0;

    // Coupures affichées : la plus grosse en haut pour taper vite.
    final steps = <int>[1000, 500, 100, if (rules.scoreStep == 50) 50];

    // Les boutons «+N» se partagent la hauteur restante (≈ 330 px pris par le
    // reste), bornée en bas (petits écrans) et en haut (tablettes).
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    final rowHeight =
        ((maxHeight - 330) / steps.length - _kRowGap).clamp(84.0, 150.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        // Halo aux couleurs du joueur, comme sur la tuile active.
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: accent.withValues(alpha: 0.60),
                blurRadius: 46,
                spreadRadius: 3),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
        child: Stack(
          children: [
            // Taches du bon dernier, sous les boutons.
            Positioned.fill(child: CradoStains(count: stains)),
            _content(context, scheme, trash, shamedId, accent, steps,
                rowHeight),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ColorScheme scheme, bool trash,
      String? shamedId, Color accent, List<int> steps, double rowHeight) {
    return SingleChildScrollView(
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
                child: Text(tr('${player.displayName} — score du tour', '${player.displayName} — turn score'),
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
          Text(tr('Total après validation : ${player.score + _amount}', 'Total after confirming: ${player.score + _amount}'),
              style:
                  TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 20),
          for (final step in steps) ...[
            _StepRow(
              amount: step,
              height: rowHeight,
              onAdd: () => _add(step),
              onSubtract: _amount >= step ? () => _add(-step) : null,
            ),
            const SizedBox(height: _kRowGap),
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
                      minimumSize: const Size.fromHeight(72),
                      foregroundColor: scheme.onSurfaceVariant,
                      side: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.5))),
                  onPressed: _amount == 0 ? null : _clear,
                  child: Text(tr('Effacer', 'Clear'),
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
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
                    minimumSize: const Size.fromHeight(72),
                  ),
                  onPressed: _canValidate && !_busy ? _validate : null,
                  child: Text(_amount > 0 ? tr('Valider +$_amount', 'Confirm +$_amount') : tr('Valider', 'Confirm'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une ligne de coupure : petit bouton « − » à gauche, gros « +N » à droite.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.amount,
    required this.height,
    required this.onAdd,
    required this.onSubtract,
  });

  final int amount;
  final double height;
  final VoidCallback onAdd;
  final VoidCallback? onSubtract;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900)),
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
                      fontSize: 50, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
