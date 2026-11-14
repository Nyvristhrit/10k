import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/data/repositories/file_game_repository.dart';
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
    random: Random(3),
  );
}

GameState ok(EngineResult r) => (r as Success).transition.nextState;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tenk_test_');
  });
  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('sauvegarde puis reprise d\'une partie en cours', () async {
    final engine = makeEngine();
    var s = engine.createGame(rules: const GameRules(turnMode: TurnMode.free));
    s = ok(engine.apply(s, const AddPlayer()));
    s = ok(engine.apply(s, const AddPlayer()));
    s = ok(engine.apply(s, const StartGame()));
    final ids = s.players.map((p) => p.id).toList();
    s = ok(engine.apply(s, RecordScore(playerId: ids.first, amount: 1500)));

    // Enregistrement après l'action.
    final repo = FileGameRepository(tempDir);
    await repo.saveSnapshot(s);

    // « Réouverture » : un nouveau dépôt sur le même dossier.
    final repo2 = FileGameRepository(tempDir);
    final loaded = await repo2.loadActiveGame();

    expect(loaded, isNotNull);
    expect(loaded!.id, s.id);
    expect(loaded.playerById(ids.first)!.score, 1500);
    expect(loaded.actions.length, s.actions.length); // action non dupliquée

    // On peut reprendre la partie et jouer immédiatement.
    final next = engine.apply(loaded, RecordScore(playerId: ids[1], amount: 500));
    expect(next, isA<Success>());
  });

  test('une partie terminée bascule dans l\'historique', () async {
    final repo = FileGameRepository(tempDir);
    final engine = makeEngine();
    var s = engine.createGame(rules: const GameRules(turnMode: TurnMode.free));
    s = ok(engine.apply(s, const AddPlayer()));
    s = ok(engine.apply(s, const AddPlayer()));
    s = ok(engine.apply(s, const StartGame()));
    final ids = s.players.map((p) => p.id).toList();

    // Un joueur atteint 10 000 puis l'autre passe -> partie terminée.
    s = ok(engine.apply(s, RecordScore(playerId: ids.first, amount: 10000)));
    await repo.saveSnapshot(s); // active (dernière chance)
    expect(await repo.loadActiveGame(), isNotNull);

    s = ok(engine.apply(s, PassTurn(playerId: ids[1])));
    await repo.saveSnapshot(s);

    expect(s.status, GameStatus.finished);
    expect(await repo.loadActiveGame(), isNull);
    final finished = await repo.loadFinishedGames();
    expect(finished.length, 1);
    expect(finished.first.winnerPlayerId, ids.first);
  });

  test('mise à jour : un seul fichier par partie', () async {
    final repo = FileGameRepository(tempDir);
    final engine = makeEngine();
    var s = engine.createGame();
    s = ok(engine.apply(s, const AddPlayer()));
    await repo.saveSnapshot(s);
    s = ok(engine.apply(s, const AddPlayer()));
    await repo.saveSnapshot(s);

    final gamesDir = Directory('${tempDir.path}/games');
    final files =
        await gamesDir.list().where((e) => e.path.endsWith('.json')).toList();
    expect(files.length, 1);
    final active = await repo.loadActiveGame();
    expect(active!.players.length, 2);
  });

  test('suppression de toutes les données locales', () async {
    final repo = FileGameRepository(tempDir);
    final engine = makeEngine();
    var s = engine.createGame();
    s = ok(engine.apply(s, const AddPlayer()));
    await repo.saveSnapshot(s);
    await repo.deleteAll();
    expect(await repo.loadActiveGame(), isNull);
    expect(await repo.loadFinishedGames(), isEmpty);
  });
}
