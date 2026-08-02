import '../enums/game_enums.dart';
import '../models/game_state.dart';

/// Un fait marquant rattaché à un joueur (« celui qui a perdu le plus de
/// points », « le plus gros coup »…), avec la valeur qui lui vaut ce titre.
class PlayerFact {
  const PlayerFact({required this.playerId, required this.value});

  final String playerId;
  final int value;
}

/// Le bilan chiffré d'une partie, reconstruit à partir du journal d'actions et
/// des piles de gains.
///
/// Rien n'est stocké en plus dans l'état : tout se recalcule à la demande, ce
/// qui garantit des chiffres cohérents même après des annulations.
class GameFacts {
  const GameFacts({
    required this.roundsPlayed,
    required this.turnsPlayed,
    this.biggestLoser,
    this.wrecker,
    this.biggestHit,
    this.mostMisses,
  });

  /// Nombre de manches jouées (0 en mode libre, qui n'en compte pas).
  final int roundsPlayed;

  /// Nombre de tours joués, tous joueurs confondus (marqués, passés, ratés).
  final int turnsPlayed;

  /// Celui qui a perdu le plus de points (rencontres + 3ᵉ échecs).
  final PlayerFact? biggestLoser;

  /// Celui qui a fait le plus de victimes en tombant pile sur leur total.
  final PlayerFact? wrecker;

  /// Le plus gros score marqué en un seul tour.
  final PlayerFact? biggestHit;

  /// Celui qui a raté (ou passé) le plus de tours.
  final PlayerFact? mostMisses;

  /// Y a-t-il au moins un fait à raconter ?
  bool get hasHighlights =>
      biggestLoser != null ||
      wrecker != null ||
      biggestHit != null ||
      mostMisses != null;

  /// Calcule le bilan d'une partie.
  static GameFacts of(GameState game) {
    final lost = <String, int>{};
    final hits = <String, int>{};
    final wrecked = <String, int>{};
    final misses = <String, int>{};

    // Points perdus et plus gros coup, lus dans les piles de gains. Les gains
    // annulés par un « retour arrière » sont ignorés : ce n'est pas un revers
    // de jeu, c'est une correction de saisie.
    for (final player in game.players) {
      for (final gain in player.gains) {
        if (gain.cancelReason == GainCancelReason.undone) continue;
        if (gain.amount > (hits[player.id] ?? 0)) {
          hits[player.id] = gain.amount;
        }
        if (gain.status == GainStatus.cancelled) {
          lost[player.id] = (lost[player.id] ?? 0) + gain.amount;
        }
      }
    }

    var roundsPlayed = game.roundState?.roundNumber ?? 0;
    var turnsPlayed = 0;

    for (final action in game.actions) {
      if (action.isUndone) continue;

      final round = action.roundNumber;
      if (round != null && round > roundsPlayed) roundsPlayed = round;

      final id = action.primaryPlayerId;
      switch (action.type) {
        case GameActionType.scoreRecorded:
          turnsPlayed++;
        case GameActionType.passRecorded:
        case GameActionType.overshootRecorded:
          turnsPlayed++;
          if (id != null) misses[id] = (misses[id] ?? 0) + 1;
        default:
          break;
      }

      // Chaque gain annulé par une rencontre est une victime de plus au
      // compteur de celui qui a marqué.
      if (id != null) {
        final victims = action.effects
            .where((e) => e.type == GameEffectType.gainCancelledByEncounter)
            .length;
        if (victims > 0) wrecked[id] = (wrecked[id] ?? 0) + victims;
      }
    }

    return GameFacts(
      roundsPlayed: roundsPlayed,
      turnsPlayed: turnsPlayed,
      biggestLoser: _top(lost),
      wrecker: _top(wrecked),
      biggestHit: _top(hits),
      mostMisses: _top(misses),
    );
  }

  /// Le meilleur d'une table de scores — ou `null` si elle est vide, ou si
  /// personne ne se détache : un titre partagé n'a aucune saveur.
  static PlayerFact? _top(Map<String, int> tally) {
    String? bestId;
    var bestValue = 0;
    var tiedAtBest = false;

    tally.forEach((id, value) {
      if (value > bestValue) {
        bestId = id;
        bestValue = value;
        tiedAtBest = false;
      } else if (value == bestValue && bestId != null) {
        tiedAtBest = true;
      }
    });

    if (bestId == null || bestValue <= 0 || tiedAtBest) return null;
    return PlayerFact(playerId: bestId!, value: bestValue);
  }
}
