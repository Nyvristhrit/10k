import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/app/app.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/data/repositories/settings_repository.dart';
import 'package:tenk/features/game_board/widgets/player_board_tile.dart';

/// Glisser-déposer des tuiles sur le plateau : appui long + glisser change un
/// joueur de place ; appui long relâché sur place propose toujours de le faire
/// quitter la partie.
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('tenk_reorder_'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// Ouvre un plateau de trois joueurs (mode guidé par défaut).
  Future<void> openBoard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(InMemoryGameRepository()),
          settingsRepositoryProvider.overrideWithValue(SettingsRepository(dir)),
        ],
        child: const TenkApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Nouvelle partie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.textContaining('Ajouter un joueur'));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Commencer la partie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  List<String> seatOrder(WidgetTester tester) {
    final container =
        ProviderScope.containerOf(tester.element(find.byType(Scaffold).last));
    final game = container.read(gameControllerProvider).value!;
    return game.activePlayers.map((p) => p.id).toList();
  }

  Finder tileOf(String id) => find.byWidgetPredicate(
      (w) => w is PlayerBoardTile && w.player.id == id && w.key != null);

  testWidgets('appui long + glisser sur un autre joueur : prend sa place',
      (tester) async {
    await openBoard(tester);
    final [a, b, c] = seatOrder(tester);

    final gesture = await tester.startGesture(tester.getCenter(tileOf(a)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    final target = tester.getCenter(tileOf(c));
    final start = tester.getCenter(tileOf(a));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(start, target, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(seatOrder(tester), [b, c, a]);
    expect(find.textContaining('Faire quitter'), findsNothing);
  });

  testWidgets('appui long relâché sur place : propose de faire quitter',
      (tester) async {
    await openBoard(tester);
    final order = seatOrder(tester);

    final gesture =
        await tester.startGesture(tester.getCenter(tileOf(order.first)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Faire quitter'), findsOneWidget);
    expect(seatOrder(tester), order);
  });
}
