import '../enums/game_enums.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'encounter_summary.dart';
import 'game_facts.dart';

/// L'identité utilisée pour agréger un joueur d'une partie à l'autre : son
/// alias de table (« @Ben ») s'il en a un — stable et choisi par la table —
/// sinon son nom du jour (totem + épithète, tiré au hasard et donc peu
/// signifiant d'une partie à l'autre).
String _identity(Player p) => p.alias ?? p.displayName;

/// Un fait chiffré nommé, prêt à afficher (« Panda Facétieux — 3 victoires »).
class NamedStat {
  const NamedStat({required this.name, required this.value});

  final String name;
  final int value;
}

/// Bilan **entre toutes les parties terminées** de l'appareil (§ évolution
/// « stats & fun facts »), à ne pas confondre avec [GameFacts] qui résume
/// **une seule** partie.
///
/// Purement dérivé des parties conservées sur l'appareil (voir
/// `GameController.newGame` : une partie terminée n'est jamais effacée) —
/// rien n'est stocké en plus, tout se recalcule à la demande.
class GameStats {
  const GameStats({
    required this.gamesPlayed,
    required this.totalTurnsPlayed,
    required this.totalEncounters,
    required this.totalPlayTime,
    required this.averageRoundsByTarget,
    this.winsByIdentity = const {},
    this.biggestHit,
    this.topWinner,
    this.longestGameRounds,
    this.longestGameTarget,
  });

  /// Nombre de parties menées à leur terme.
  final int gamesPlayed;

  /// Tours joués, toutes parties et tous joueurs confondus.
  final int totalTurnsPlayed;

  /// Rencontres déclenchées, toutes parties confondues.
  final int totalEncounters;

  /// Temps de jeu cumulé (somme des durées créée→terminée quand connues).
  final Duration totalPlayTime;

  /// Nombre moyen de manches par partie, groupé par score cible (mode guidé
  /// seulement — le mode libre ne compte pas de manches).
  final Map<int, double> averageRoundsByTarget;

  /// Victoires par identité (alias, ou nom du jour à défaut) — alimente
  /// l'écran « Alias & profils » (une ligne par alias connu).
  final Map<String, int> winsByIdentity;

  /// Le plus gros score marqué en un seul coup, toutes parties confondues.
  final NamedStat? biggestHit;

  /// Le nom qui revient le plus souvent en gagnant (§ nuance : les noms par
  /// défaut sont tirés au hasard, ce classement n'a donc tout son sens que si
  /// la table utilise des noms personnalisés stables d'une partie à l'autre).
  final NamedStat? topWinner;

  /// La partie la plus longue (en manches), et son score cible.
  final int? longestGameRounds;
  final int? longestGameTarget;

  bool get hasData => gamesPlayed > 0;

  static const GameStats empty = GameStats(
    gamesPlayed: 0,
    totalTurnsPlayed: 0,
    totalEncounters: 0,
    totalPlayTime: Duration.zero,
    averageRoundsByTarget: {},
  );

  /// Calcule le bilan à partir des parties terminées (statut `finished` ou
  /// `archived` — les autres, en cours, n'ont pas encore de résultat).
  static GameStats of(List<GameState> games) {
    final finished = games
        .where((g) =>
            g.status == GameStatus.finished || g.status == GameStatus.archived)
        .toList();
    if (finished.isEmpty) return empty;

    var totalTurns = 0;
    var totalEncounters = 0;
    var totalPlayTime = Duration.zero;
    final roundsByTarget = <int, List<int>>{};
    final wins = <String, int>{};
    String? biggestHitName;
    var biggestHitValue = 0;
    int? longestRounds;
    int? longestTarget;

    for (final game in finished) {
      final facts = GameFacts.of(game);
      totalTurns += facts.turnsPlayed;

      if (game.finishedAt != null) {
        totalPlayTime += game.finishedAt!.difference(game.createdAt);
      }

      if (game.rules.turnMode == TurnMode.guided && facts.roundsPlayed > 0) {
        roundsByTarget
            .putIfAbsent(game.rules.targetScore, () => [])
            .add(facts.roundsPlayed);
        if (longestRounds == null || facts.roundsPlayed > longestRounds) {
          longestRounds = facts.roundsPlayed;
          longestTarget = game.rules.targetScore;
        }
      }

      if (facts.biggestHit != null &&
          facts.biggestHit!.value > biggestHitValue) {
        final player = game.playerById(facts.biggestHit!.playerId);
        if (player != null) {
          biggestHitValue = facts.biggestHit!.value;
          biggestHitName = _identity(player);
        }
      }

      for (final action in game.actions) {
        if (action.isUndone) continue;
        totalEncounters += encounterOfAction(action)?.count ?? 0;
      }

      final winner = game.winnerPlayerId == null
          ? null
          : game.playerById(game.winnerPlayerId!);
      if (winner != null) {
        final id = _identity(winner);
        wins[id] = (wins[id] ?? 0) + 1;
      }
    }

    final averages = {
      for (final entry in roundsByTarget.entries)
        entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
    };

    String? topWinnerName;
    var topWinnerCount = 0;
    wins.forEach((name, count) {
      if (count > topWinnerCount) {
        topWinnerName = name;
        topWinnerCount = count;
      }
    });

    return GameStats(
      gamesPlayed: finished.length,
      totalTurnsPlayed: totalTurns,
      totalEncounters: totalEncounters,
      totalPlayTime: totalPlayTime,
      averageRoundsByTarget: averages,
      winsByIdentity: wins,
      biggestHit: biggestHitName == null
          ? null
          : NamedStat(name: biggestHitName, value: biggestHitValue),
      topWinner: topWinnerName == null
          ? null
          : NamedStat(name: topWinnerName!, value: topWinnerCount),
      longestGameRounds: longestRounds,
      longestGameTarget: longestTarget,
    );
  }
}
