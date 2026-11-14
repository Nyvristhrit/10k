import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/domain/commands/game_command.dart';
import 'package:tenk/domain/enums/game_enums.dart';
import 'package:tenk/domain/models/game_rules.dart';
import 'package:tenk/domain/models/game_state.dart';
import 'package:tenk/domain/services/game_engine.dart';
import 'package:tenk/domain/services/game_facts.dart';
import 'package:tenk/domain/services/game_transition.dart';

GameState ok(EngineResult r) {
  expect(r, isA<Success>(),
      reason: r is Failure ? r.violation.toString() : 'attendu Success');
  return (r as Success).transition.nextState;
}

({GameEngine engine, GameState state, List<String> ids}) start(
  int n, {
  TurnMode mode = TurnMode.free,
}) {
  var counter = 0;
  final engine = GameEngine(
    idGenerator: () => 'id${counter++}',
    clock: () => DateTime(2026, 1, 1),
    random: Random(42),
  );
  var s = engine.createGame(rules: GameRules(turnMode: mode));
  for (var i = 0; i < n; i++) {
    s = ok(engine.apply(s, const AddPlayer()));
  }
  final started = ok(engine.apply(s, const StartGame()));
  return (
    engine: engine,
    state: started,
    ids: started.players.map((p) => p.id).toList()
  );
}

void main() {
  group('Bilan de partie', () {
    test('partie vierge : aucun tour, aucun fait', () {
      final facts = GameFacts.of(start(3).state);
      expect(facts.turnsPlayed, 0);
      expect(facts.hasHighlights, isFalse);
    });

    test('compte les tours joués, marqués comme ratés', () {
      final g = start(2);
      var s = g.state;
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 500)));
      s = ok(g.engine.apply(s, PassTurn(playerId: g.ids[1])));
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 300)));

      expect(GameFacts.of(s).turnsPlayed, 3);
    });

    test('le mode libre n\'affiche pas de manches', () {
      final g = start(2);
      final s =
          ok(g.engine.apply(g.state, RecordScore(playerId: g.ids[0], amount: 500)));
      expect(GameFacts.of(s).roundsPlayed, 0);
    });

    test('le mode guidé compte les manches', () {
      final g = start(2, mode: TurnMode.guided);
      var s = g.state;
      // Un tour complet de table = la manche passe à 2.
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 500)));
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[1], amount: 500)));
      expect(GameFacts.of(s).roundsPlayed, greaterThanOrEqualTo(2));
    });

    test('retient le plus gros coup', () {
      final g = start(2);
      var s = g.state;
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 500)));
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[1], amount: 1200)));

      final facts = GameFacts.of(s);
      expect(facts.biggestHit?.playerId, g.ids[1]);
      expect(facts.biggestHit?.value, 1200);
    });

    test('compte les tours ratés par joueur', () {
      final g = start(2);
      var s = g.state;
      s = ok(g.engine.apply(s, PassTurn(playerId: g.ids[0])));
      s = ok(g.engine.apply(s, PassTurn(playerId: g.ids[0])));
      s = ok(g.engine.apply(s, PassTurn(playerId: g.ids[1])));

      final facts = GameFacts.of(s);
      expect(facts.mostMisses?.playerId, g.ids[0]);
      expect(facts.mostMisses?.value, 2);
    });

    test('une rencontre désigne la brute et sa victime', () {
      final g = start(2);
      var s = g.state;
      // Les deux sortent, puis le second tombe pile sur le total du premier.
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 1000)));
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[1], amount: 400)));
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[1], amount: 600)));

      final facts = GameFacts.of(s);
      expect(facts.wrecker?.playerId, g.ids[1]);
      expect(facts.wrecker?.value, 1);
      // La victime a perdu son gain de 1000.
      expect(facts.biggestLoser?.playerId, g.ids[0]);
      expect(facts.biggestLoser?.value, 1000);
    });

    test('aucun titre décerné en cas d\'ex æquo', () {
      final g = start(2);
      var s = g.state;
      // Les deux joueurs ratent autant de tours l'un que l'autre.
      s = ok(g.engine.apply(s, PassTurn(playerId: g.ids[0])));
      s = ok(g.engine.apply(s, PassTurn(playerId: g.ids[1])));

      expect(GameFacts.of(s).mostMisses, isNull);
    });

    test('une action annulée ne compte plus dans le bilan', () {
      final g = start(2);
      var s = g.state;
      s = ok(g.engine.apply(s, RecordScore(playerId: g.ids[0], amount: 500)));
      expect(GameFacts.of(s).turnsPlayed, 1);

      s = ok(g.engine.apply(s, const UndoLastAction()));
      final facts = GameFacts.of(s);
      expect(facts.turnsPlayed, 0);
      // Le gain effacé par un retour arrière n'est pas une perte de jeu.
      expect(facts.biggestLoser, isNull);
      expect(facts.biggestHit, isNull);
    });
  });
}
