import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/domain/commands/game_command.dart';
import 'package:tenk/domain/enums/game_enums.dart';
import 'package:tenk/domain/models/game_rules.dart';
import 'package:tenk/domain/models/game_state.dart';
import 'package:tenk/domain/services/game_engine.dart';
import 'package:tenk/domain/services/game_transition.dart';
import 'package:tenk/domain/services/trash_targets.dart';

/// Démarre une partie en mode libre avec `n` joueurs.
({GameEngine engine, GameState state, List<String> ids}) start(int n) {
  var counter = 0;
  final engine = GameEngine(
    idGenerator: () => 'id${counter++}',
    clock: () => DateTime(2026, 1, 1),
    random: Random(42),
  );
  var s = engine.createGame(rules: const GameRules(turnMode: TurnMode.free));
  for (var i = 0; i < n; i++) {
    s = ok(engine.apply(s, const AddPlayer()));
  }
  return (
    engine: engine,
    state: ok(engine.apply(s, const StartGame())),
    ids: s.players.map((p) => p.id).toList()
  );
}

GameState ok(EngineResult r) {
  expect(r, isA<Success>(),
      reason: r is Failure ? r.violation.toString() : 'attendu Success');
  return (r as Success).transition.nextState;
}

void main() {
  group('Bonnet d\'âne du mode trash', () {
    test('personne n\'est désigné tant que tout le monde est à zéro', () {
      final g = start(3);
      expect(lastPlaceId(g.state), isNull);
    });

    test('désigne le joueur strictement dernier une fois la partie lancée', () {
      final g = start(3);
      var s = g.state;
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 1000)));
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[1], amount: 500)));
      // Le troisième n'a pas encore marqué : c'est lui, le dernier.
      expect(lastPlaceId(s), g.ids[2]);
    });

    test('aucun bonnet d\'âne en cas d\'ex æquo à la dernière place', () {
      final g = start(3);
      var s = g.state;
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 1000)));
      // Les deux autres sont à égalité (0) : on n'humilie personne.
      expect(lastPlaceId(s), isNull);
    });

    test('suit le classement quand le dernier change', () {
      final g = start(2);
      var s = g.state;
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 1000)));
      expect(lastPlaceId(s), g.ids[1]);

      // Le retardataire double son adversaire : le bonnet d'âne change de tête.
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[1], amount: 1500)));
      expect(lastPlaceId(s), g.ids[0]);
    });

    test('ignore les joueurs qui ont quitté la table', () {
      final g = start(3);
      var s = g.state;
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 1000)));
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[1], amount: 500)));
      expect(lastPlaceId(s), g.ids[2]);

      // Le dernier s'en va : le bonnet d'âne revient à celui qui reste derrière.
      s = ok(g.engine.apply(s, LeaveGame(playerId: g.ids[2])));
      expect(lastPlaceId(s), g.ids[1]);
    });

    test('pas de bonnet d\'âne s\'il ne reste qu\'un joueur en lice', () {
      final g = start(2);
      var s = g.state;
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 1000)));
      s = ok(g.engine.apply(s, LeaveGame(playerId: g.ids[1])));
      expect(lastPlaceId(s), isNull);
    });
  });
}
