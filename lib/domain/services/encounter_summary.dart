import '../enums/game_enums.dart';
import '../models/game_action.dart';
import 'game_transition.dart';

/// Résumé d'une rencontre (ou d'une cascade de rencontres) produite par une
/// action, **dérivé** de ses effets. Aucune logique de jeu ici : c'est une
/// simple lecture, partagée par l'alerte (message à valider) et l'animation
/// « pluie / cascade / tsunami de points ».
class EncounterSummary {
  const EncounterSummary({required this.markerId, required this.victims});

  /// Le joueur qui a déclenché la rencontre (le marqueur).
  final String markerId;

  /// Les victimes, dans l'ordre de la cascade (la première est percutée en
  /// premier ; les suivantes le sont par ricochet).
  final List<EncounterVictim> victims;

  /// Nombre de joueurs percutés.
  int get count => victims.length;
}

/// Une victime d'une rencontre et le montant qu'elle a perdu.
class EncounterVictim {
  const EncounterVictim({required this.playerId, required this.amountLost});

  final String playerId;
  final int amountLost;
}

/// Extrait la rencontre d'une transition, ou `null` s'il n'y en a pas eu.
EncounterSummary? encounterOf(GameTransition transition) =>
    encounterOfAction(transition.action);

/// Extrait la rencontre d'une action, ou `null` s'il n'y en a pas eu.
EncounterSummary? encounterOfAction(GameAction? action) {
  if (action == null) return null;

  String? markerId;
  final victims = <EncounterVictim>[];
  for (final e in action.effects) {
    switch (e.type) {
      case GameEffectType.encounterTriggered:
        markerId = e.targetPlayerId;
      case GameEffectType.gainCancelledByEncounter:
        victims.add(EncounterVictim(
          playerId: e.targetPlayerId!,
          amountLost: (e.delta ?? 0).abs(),
        ));
      default:
        break;
    }
  }

  if (markerId == null || victims.isEmpty) return null;
  return EncounterSummary(markerId: markerId, victims: victims);
}
