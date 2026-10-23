import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/app/app.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/catalogs/whats_new_catalog.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/data/repositories/settings_repository.dart';
import 'package:tenk/domain/commands/game_command.dart';
import 'package:tenk/domain/enums/game_enums.dart';
import 'package:tenk/domain/models/game_rules.dart';
import 'package:tenk/domain/models/game_state.dart';
import 'package:tenk/domain/services/game_engine.dart';
import 'package:tenk/domain/services/game_transition.dart';
import 'package:tenk/features/game_board/widgets/player_board_tile.dart';
import 'package:tenk/shared/trash/fart_player.dart';

/// Lecteur muet qui compte les prouts demandés.
class _FakeFarts extends FartPlayer {
  int played = 0;

  @override
  Future<void> play() async => played++;
}

/// Le « bon dernier » du mode trash pète et se salit à chaque
/// bouton de la saisie du score ; les autres joueurs, non.
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('tenk_crado_'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// Partie libre : Alpha à 500, Bravo à 600 (pas 500 : ce serait une
  /// rencontre !), Charlie seul dernier à 0.
  GameState seededGame() {
    final engine = GameEngine();
    GameState ok(EngineResult r) => (r as Success).transition.nextState;
    var s = engine.createGame(rules: const GameRules(turnMode: TurnMode.free));
    for (final name in ['Alpha', 'Bravo', 'Charlie']) {
      s = ok(engine.apply(s, AddPlayer(displayName: name)));
    }
    s = ok(engine.apply(s, const StartGame()));
    s = ok(engine.apply(
        s, RecordScore(playerId: s.players[0].id, amount: 500)));
    s = ok(engine.apply(
        s, RecordScore(playerId: s.players[1].id, amount: 600)));
    return s;
  }

  Future<(_FakeFarts, ProviderContainer)> openBoard(WidgetTester tester,
      {bool farts = true, bool stains = true}) async {
    final settings = SettingsRepository(dir)
      ..saveTrashMode(true)
      // Pas de fenêtre « Quoi de neuf » par-dessus l'accueil.
      ..saveLastSeenWhatsNewVersion(WhatsNewCatalog.releases.last.version)
      ..saveCradoFartsEnabled(farts)
      ..saveCradoStainsEnabled(stains);
    final repo = InMemoryGameRepository();
    await repo.saveSnapshot(seededGame());
    final fartsPlayer = _FakeFarts();
    final container = ProviderContainer(overrides: [
      gameRepositoryProvider.overrideWithValue(repo),
      settingsRepositoryProvider.overrideWithValue(settings),
      fartPlayerProvider.overrideWithValue(fartsPlayer),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const TenkApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Reprendre la partie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return (fartsPlayer, container);
  }

  Future<void> openSheetOf(WidgetTester tester, String name) async {
    await tester.tap(find.text(name).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pump(const Duration(milliseconds: 100));
  }

  int stainsOf(WidgetTester tester, String name) => tester
      .widget<PlayerBoardTile>(find.byWidgetPredicate((w) =>
          w is PlayerBoardTile &&
          w.player.displayName == name &&
          w.key != null))
      .stains;

  testWidgets('le bon dernier pète et se tache à chaque bouton',
      (tester) async {
    final (farts, _) = await openBoard(tester);

    await openSheetOf(tester, 'Charlie');
    await tapButton(tester, '+100');
    await tapButton(tester, '+100');
    await tapButton(tester, 'Effacer');
    expect(farts.played, 3);

    await tester.ensureVisible(find.byIcon(Icons.close));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(stainsOf(tester, 'Charlie'), 3);
    expect(stainsOf(tester, 'Alpha'), 0);
  });

  testWidgets('les autres joueurs restent propres et silencieux',
      (tester) async {
    final (farts, container) = await openBoard(tester);

    await openSheetOf(tester, 'Alpha');
    await tapButton(tester, '+100');
    expect(farts.played, 0);
    expect(container.read(cradoStainsProvider).count, 0);
  });

  test('les taches repartent de zéro à chaque nouvelle partie', () {
    final container = ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(dir)),
    ]);
    addTearDown(container.dispose);
    final stains = container.read(cradoStainsProvider.notifier);

    stains
      ..splash('partie-1')
      ..splash('partie-1');
    expect(stains.countFor('partie-1'), 2);
    expect(stains.countFor('partie-2'), 0);

    stains.splash('partie-2');
    expect(stains.countFor('partie-2'), 1);
    expect(stains.countFor('partie-1'), 0);
  });

  testWidgets('chaque gag se désactive dans les réglages', (tester) async {
    final (farts, container) =
        await openBoard(tester, farts: false, stains: true);

    await openSheetOf(tester, 'Charlie');
    await tapButton(tester, '+100');
    expect(farts.played, 0);
    expect(container.read(cradoStainsProvider).count, 1);
  });
}
