import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/game_state.dart';
import '../../domain/services/encounter_summary.dart';
import '../../shared/widgets/player_visuals.dart';

/// Titre d'une rencontre selon le nombre de joueurs percutés (même vocabulaire
/// que l'animation : pluie / cascade / tsunami).
String encounterTitle(int count) {
  if (count >= 4) return 'Tsunami de points !';
  if (count == 3) return 'Cascade de points !';
  if (count == 2) return 'Pluie de points !';
  return 'Rencontre !';
}

/// Affiche le message à valider quand une rencontre (ou cascade) se produit.
///
/// [state] est l'état **après** la rencontre : on y lit les nouveaux totaux.
Future<void> showEncounterAlert(
  BuildContext context, {
  required GameState state,
  required EncounterSummary summary,
}) {
  HapticFeedback.heavyImpact();
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (_) => _EncounterAlertDialog(state: state, summary: summary),
  );
}

class _EncounterAlertDialog extends StatelessWidget {
  const _EncounterAlertDialog({required this.state, required this.summary});

  final GameState state;
  final EncounterSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              const Text('💥', style: TextStyle(fontSize: 46)),
              const SizedBox(height: 6),
              Text(
                encounterTitle(summary.count),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              if (marker != null)
                Text(
                  '${emojiFor(marker)} ${marker.displayName} tombe sur ${marker.score}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, color: scheme.onSurfaceVariant),
                ),
              const SizedBox(height: 18),
              for (final v in summary.victims) _victimRow(context, v),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54)),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK, compris',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _victimRow(BuildContext context, EncounterVictim v) {
    final victim = state.playerById(v.playerId);
    if (victim == null) return const SizedBox.shrink();
    final color = colorFor(victim);
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
