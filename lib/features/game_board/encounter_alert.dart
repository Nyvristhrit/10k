import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tenk_skin.dart';
import '../../domain/models/game_state.dart';
import '../../domain/services/encounter_summary.dart';
import '../../shared/trash/trash_taunts.dart';
import '../../shared/widgets/player_visuals.dart';
import '../../l10n/l10n.dart';

/// Titre d'une rencontre selon le nombre de joueurs percutés.
String encounterTitle(int count, {bool trash = false}) {
  if (trash) return Taunts.encounterTitle(count);
  if (count >= 4) return tr('Tsunami de points !', 'Points tsunami!');
  if (count == 3) return tr('Cascade de points !', 'Points cascade!');
  if (count == 2) return tr('Pluie de points !', 'Points shower!');
  return tr('Rencontre !', 'Encounter!');
}

/// Affiche l'alerte à valider après une rencontre (ou cascade).
///
/// [state] est l'état après la rencontre.
Future<void> showEncounterAlert(
  BuildContext context, {
  required GameState state,
  required EncounterSummary summary,
}) {
  HapticFeedback.heavyImpact();
  final jibe = Taunts.encounterJibe(summary.count);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) =>
        _EncounterAlertDialog(state: state, summary: summary, jibe: jibe),
  );
}

class _EncounterAlertDialog extends StatelessWidget {
  const _EncounterAlertDialog({
    required this.state,
    required this.summary,
    required this.jibe,
  });

  final GameState state;
  final EncounterSummary summary;

  /// La petite pique du mode trash, tirée à l'ouverture pour rester stable.
  final String jibe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trash = TenkSkin.of(context).trash;
    final marker = state.playerById(summary.markerId);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(trash ? '☠️' : '💥', style: const TextStyle(fontSize: 46)),
              const SizedBox(height: 6),
              Text(
                encounterTitle(summary.count, trash: trash),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              if (marker != null)
                Text(
                  tr('${emojiFor(marker)} ${marker.displayName} tombe sur ${marker.score}', '${emojiFor(marker)} ${marker.displayName} lands on ${marker.score}'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, color: scheme.onSurfaceVariant),
                ),
              if (trash) ...[
                const SizedBox(height: 8),
                Text(
                  jibe,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 18),
              for (final v in summary.victims) _victimRow(context, v, trash),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54)),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(trash ? Taunts.encounterAck : tr('OK, compris', 'OK, got it'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _victimRow(BuildContext context, EncounterVictim v, bool trash) {
    final victim = state.playerById(v.playerId);
    if (victim == null) return const SizedBox.shrink();
    final color = colorFor(victim, trash: trash);
    final bg = AppTheme.fromArgb(color.backgroundArgb);
    final fg = AppTheme.fromArgb(color.foregroundArgb);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emojiFor(victim), style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              victim.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: fg, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('−${v.amountLost}',
                  style: TextStyle(
                      color: fg, fontSize: 20, fontWeight: FontWeight.w900)),
              Text('→ ${victim.score}',
                  style: TextStyle(
                      color: fg.withValues(alpha: 0.8), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
