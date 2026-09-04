import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/domain/commands/game_command.dart';
import 'package:tenk/domain/enums/game_enums.dart';
import 'package:tenk/domain/models/game_rules.dart';
import 'package:tenk/domain/models/game_state.dart';
import 'package:tenk/domain/services/game_engine.dart';
import 'package:tenk/domain/services/game_stats.dart';
import 'package:tenk/domain/services/game_transition.dart';

GameState ok(EngineResult r) {
  expect(r, isA<Success>(),
      reason: r is Failure ? r.violation.toString() : 'attendu Success');
  return (r as Success).transition.nextState;
}

/// Termine une partie à 2 joueurs (mode guidé) : A atteint la cible d'un
/// coup, B passe sa dernière chance -> A gagne. Utilise une horloge qui
/// avance à chaque appel, pour que `finishedAt - createdAt` soit mesurable.
({GameEngine engine, GameState state, String aId, String bId}) finishedGame({
  int targetScore = 10000,
  int startMinute = 0,
}) {
  var minute = startMinute;
  var counter = 0;
  final engine = GameEngine(
    idGenerator: () => 'id${counter++}',
    clock: () => DateTime(2026, 1, 1, 0, minute++),
    random: Random(42),
  );
  var s = engine.createGame(rules: GameRules(targetScore: targetScore));
  s = ok(engine.apply(s, const AddPlayer(displayName: 'Alpha')));
  s = ok(engine.apply(s, const AddPlayer(displayName: 'Beta')));
  s = ok(engine.apply(s, const StartGame()));
  final a = s.players[0].id;
  final b = s.players[1].id;

  s = ok(engine.apply(s, RecordScore(playerId: a, amount: targetScore)));
  expect(s.status, GameStatus.finalChance);
  s = ok(engine.apply(s, PassTurn(playerId: b)));
  return (engine: engine, state: s, aId: a, bId: b);
}

void main() {
  group('Bilan multi-parties (GameStats)', () {
    test('aucune partie : bilan vide', () {
      expect(GameStats.of(const []).hasData, isFalse);
    });

    test('ignore les parties encore en cours', () {
      var counter = 0;
      final engine = GameEngine(
        idGenerator: () => 'id${counter++}',
        clock: () => DateTime(2026, 1, 1),
      );
      var s = engine.createGame();
      s = ok(engine.apply(s, const AddPlayer()));
      s = ok(engine.apply(s, const AddPlayer()));
      s = ok(engine.apply(s, const StartGame()));

      expect(GameStats.of([s]).hasData, isFalse);
    });

    test('une partie terminée : gagnant, manches, temps de jeu', () {
      var minute = 0;
      var counter = 0;
      final engine = GameEngine(
        idGenerator: () => 'id${counter++}',
        clock: () => DateTime(2026, 1, 1, 0, minute++),
        random: Random(42),
      );
      var s = engine.createGame(rules: const GameRules(targetScore: 10000));
      s = ok(engine.apply(s, const AddPlayer(displayName: 'Alpha')));
      s = ok(engine.apply(s, const AddPlayer(displayName: 'Beta')));
      s = ok(engine.apply(s, const StartGame()));
      final a = s.players[0].id;
      final b = s.players[1].id;
      s = ok(engine.apply(s, RecordScore(playerId: a, amount: 10000)));
      s = ok(engine.apply(s, PassTurn(playerId: b)));

      expect(s.status, GameStatus.finished);
      final stats = GameStats.of([s]);
      expect(stats.gamesPlayed, 1);
      expect(stats.topWinner?.name, 'Alpha');
      expect(stats.topWinner?.value, 1);
      expect(stats.biggestHit?.name, 'Alpha');
      expect(stats.biggestHit?.value, 10000);
      expect(stats.averageRoundsByTarget[10000], isNotNull);
      expect(stats.totalPlayTime, isNot(Duration.zero));
    });

    test('moyenne des manches groupée par score cible', () {
      var counter = 0;
      final engine = GameEngine(
        idGenerator: () => 'id${counter++}',
        clock: () => DateTime(2026, 1, 1),
      );

      GameState playToTarget(int target) {
        var s = engine.createGame(rules: GameRules(targetScore: target));
        s = ok(engine.apply(s, const AddPlayer()));
        s = ok(engine.apply(s, const AddPlayer()));
        s = ok(engine.apply(s, const StartGame()));
        final a = s.players[0].id;
        final b = s.players[1].id;
        s = ok(engine.apply(s, RecordScore(playerId: a, amount: target)));
        s = ok(engine.apply(s, PassTurn(playerId: b)));
        return s;
      }

      final g1 = playToTarget(5000);
      final g2 = playToTarget(5000);
      final g3 = playToTarget(10000);

      final stats = GameStats.of([g1, g2, g3]);
      expect(stats.gamesPlayed, 3);
      expect(stats.averageRoundsByTarget.keys, containsAll([5000, 10000]));
    });

    test('utilise l\'alias plutôt que le totem tiré au hasard, s\'il existe',
        () {
      var counter = 0;
      final engine = GameEngine(
        idGenerator: () => 'id${counter++}',
        clock: () => DateTime(2026, 1, 1),
      );
      var s = engine.createGame();
      s = ok(engine.apply(s, const AddPlayer(displayName: 'Panda Malicieux')));
      s = ok(engine.apply(s, const AddPlayer()));
      final a = s.players[0].id;
      final b = s.players[1].id;
      s = ok(engine.apply(s, SetPlayerAlias(playerId: a, alias: 'Ben')));
      s = ok(engine.apply(s, const StartGame()));
      s = ok(engine.apply(s, RecordScore(playerId: a, amount: 10000)));
      s = ok(engine.apply(s, PassTurn(playerId: b)));

      final stats = GameStats.of([s]);
      expect(stats.topWinner?.name, '@Ben');
      expect(stats.biggestHit?.name, '@Ben');
    });

    test('additionne le temps de jeu de plusieurs parties', () {
      final g1 = finishedGame(startMinute: 0); // ~2 minutes (createdAt->finishedAt)
      final g2 = finishedGame(startMinute: 100);

      final stats = GameStats.of([g1.state, g2.state]);
      expect(stats.gamesPlayed, 2);
      expect(stats.totalPlayTime.inMinutes, greaterThan(0));
    });
  });
}
