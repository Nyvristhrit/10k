import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/app/app.dart';
import 'package:tenk/app/theme/tenk_skin.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/data/repositories/settings_repository.dart';
import 'package:tenk/features/info/info_screen.dart';
import 'package:tenk/shared/trash/trash_taunts.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('tenk_trash_'));
  tearDown(() => dir.deleteSync(recursive: true));

  ProviderContainer containerWith(SettingsRepository settings) =>
      ProviderContainer(overrides: [
        gameRepositoryProvider.overrideWithValue(InMemoryGameRepository()),
        settingsRepositoryProvider.overrideWithValue(settings),
      ]);

  /// Ouvre la fiche d'info sur l'onglet « À propos ».
  Future<void> openAbout(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: InfoScreen()),
    ));
    await tester.tap(find.text('À propos'));
    await tester.pumpAndSettle();
  }

  final dedication = find.textContaining('Imaginé par Ben');

  testWidgets('sept tapes sur la dédicace débloquent le mode trash',
      (tester) async {
    final container = containerWith(SettingsRepository(dir));
    addTearDown(container.dispose);
    await openAbout(tester, container);

    expect(container.read(trashModeProvider), isFalse);

    // Six tapes ne suffisent pas : le mode doit se mériter.
    for (var i = 0; i < Taunts.unlockTaps - 1; i++) {
      await tester.tap(dedication);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(container.read(trashModeProvider), isFalse);

    // La septième bascule, et l'appli l'annonce.
    await tester.tap(dedication);
    await tester.pumpAndSettle();
    expect(container.read(trashModeProvider), isTrue);
    expect(find.text(Taunts.unlockedTitle), findsOneWidget);
  });

  testWidgets('le choix est mémorisé pour la prochaine ouverture',
      (tester) async {
    final settings = SettingsRepository(dir);
    final container = containerWith(settings);
    addTearDown(container.dispose);
    await openAbout(tester, container);

    for (var i = 0; i < Taunts.unlockTaps; i++) {
      await tester.tap(dedication);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    // Le réglage a bien été écrit sur le disque, pas seulement en mémoire.
    expect(SettingsRepository(dir).loadTrashMode(), isTrue);
  });

  testWidgets('sept tapes de plus rendent l\'appli fréquentable',
      (tester) async {
    final settings = SettingsRepository(dir)..saveTrashMode(true);
    final container = containerWith(settings);
    addTearDown(container.dispose);
    await openAbout(tester, container);

    expect(container.read(trashModeProvider), isTrue);
    for (var i = 0; i < Taunts.unlockTaps; i++) {
      await tester.tap(dedication);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(container.read(trashModeProvider), isFalse);
    expect(find.text(Taunts.lockedTitle), findsOneWidget);
  });

  testWidgets('l\'accueil arbore le badge TRASH et l\'habillage néon',
      (tester) async {
    final container = containerWith(SettingsRepository(dir)..saveTrashMode(true));
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const TenkApp(),
    ));
    // L'accueil anime en boucle (dés qui tombent) : durée fixe, pas de settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('10K'), findsOneWidget);
    expect(find.text(Taunts.badge), findsOneWidget);
    expect(find.text(Taunts.tagline), findsOneWidget);

    // Le thème porte bien l'habillage trash (fond néon, cœurs verts).
    final skin = TenkSkin.of(tester.element(find.text(Taunts.badge)));
    expect(skin.trash, isTrue);
    expect(skin.lifeIcon, Icons.favorite);
    expect(skin.lifeColor, isNot(TenkSkin.classic.lifeColor));
    // Les arrondis, eux, restent ceux de la DA d'origine.
    expect(skin.corner, TenkSkin.classic.corner);
  });

  testWidgets('sans déblocage, l\'accueil reste sage', (tester) async {
    final container = containerWith(SettingsRepository(dir));
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const TenkApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text(Taunts.badge), findsNothing);
    expect(find.text('Compagnon de jeu du 10 000'), findsOneWidget);
  });
}
