import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/data/serialization/game_serialization.dart';
import 'package:tenk/domain/commands/game_command.dart';
import 'package:tenk/domain/enums/game_enums.dart';
import 'package:tenk/domain/models/game_rules.dart';
import 'package:tenk/domain/models/game_state.dart';
import 'package:tenk/domain/services/game_engine.dart';
import 'package:tenk/domain/services/game_transition.dart';

GameEngine makeEngine() {
  var counter = 0;
  return GameEngine(
    idGenerator: () => 'id${counter++}',
    clock: () => DateTime(2026, 1, 1, 12),
    random: Random(7),
  );
}

GameState ok(EngineResult r) => (r as Success).transition.nextState;

/// Effectue un aller-retour complet : état -> JSON -> texte -> JSON -> état.
GameState roundTrip(GameState s) {
  final text = jsonEncode(GameSerialization.toJson(s));
  final decoded = jsonDecode(text) as Map<String, dynamic>;
  return GameSerialization.fromJson(decoded);
}

int scoreOf(GameState s, String id) => s.playerById(id)!.score;

void main() {
  test('aller-retour d\'une partie complexe : identité préservée', () {
    final e = makeEngine();
    var s = e.createGame(rules: const GameRules(turnMode: TurnMode.free));
    for (var i = 0; i < 4; i++) {
      s = ok(e.apply(s, const AddPlayer()));
    }
    s = ok(e.apply(s, const StartGame()));
    final ids = s.players.map((p) => p.id).toList();
    final a = ids[0], renard = ids[1], panda = ids[2], x = ids[3];

    // Construit la rencontre multiple (Annexe C.7).
    s = ok(e.apply(s, RecordScore(playerId: renard, amount: 1000)));
    s = ok(e.apply(s, RecordScore(playerId: renard, amount: 800)));
    s = ok(e.apply(s, RecordScore(playerId: renard, amount: 500)));
    s = ok(e.apply(s, RecordScore(playerId: panda, amount: 1800)));
    s = ok(e.apply(s, RecordScore(playerId: x, amount: 2300)));
    s = ok(e.apply(s, RecordScore(playerId: a, amount: 1800)));

    final restored = roundTrip(s);

    // Les joueurs (avec leurs piles de gains) sont égaux au sens de la valeur.
    expect(restored.players, s.players);
    expect(restored.status, s.status);
    expect(restored.actions.length, s.actions.length);
    expect(scoreOf(restored, renard), 1000);
    expect(scoreOf(restored, panda), 0);

    // L'annulation fonctionne toujours après rechargement (effets préservés).
    final undoneOriginal = ok(e.apply(s, const UndoLastAction()));
    final undoneRestored = ok(e.apply(restored, const UndoLastAction()));
    expect(scoreOf(undoneRestored, renard), scoreOf(undoneOriginal, renard));
    expect(scoreOf(undoneRestored, panda), scoreOf(undoneOriginal, panda));
    expect(scoreOf(undoneRestored, renard), 1800);
    expect(scoreOf(undoneRestored, panda), 1800);
  });

  test('aller-retour en phase de dernière chance', () {
    final e = makeEngine();
    var s = e.createGame(rules: const GameRules(turnMode: TurnMode.free));
    for (var i = 0; i < 3; i++) {
      s = ok(e.apply(s, const AddPlayer()));
    }
    s = ok(e.apply(s, const StartGame()));
    final ids = s.players.map((p) => p.id).toList();

    s = ok(e.apply(s, RecordScore(playerId: ids[0], amount: 10000)));
    expect(s.status, GameStatus.finalChance);

    final restored = roundTrip(s);
    expect(restored.status, GameStatus.finalChance);
    expect(restored.finalChanceState!.currentCandidatePlayerId, ids[0]);
    expect(restored.finalChanceState!.pendingPlayerIds,
        s.finalChanceState!.pendingPlayerIds);
    expect(restored.players, s.players);

    // On peut continuer à jouer normalement après rechargement.
    final next = e.apply(restored, PassTurn(playerId: ids[1]));
    expect(next, isA<Success>());
  });
}
