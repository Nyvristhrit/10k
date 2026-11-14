import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/app/app.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/catalogs/adjective_catalog.dart';
import 'package:tenk/data/catalogs/animal_catalog.dart';
import 'package:tenk/data/catalogs/whats_new_catalog.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/data/repositories/settings_repository.dart';
import 'package:tenk/domain/commands/game_command.dart';
import 'package:tenk/domain/services/game_engine.dart';
import 'package:tenk/domain/services/game_transition.dart';
import 'package:tenk/l10n/l10n.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('tenk_language_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Widget app() => ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(InMemoryGameRepository()),
          settingsRepositoryProvider.overrideWithValue(SettingsRepository(dir)),
        ],
        child: const TenkApp(),
      );

  Future<void> settle(WidgetTester tester) async {
    // Animations infinies à l'accueil : pas de pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets('le bouton EN passe l\'appli en anglais, et c\'est mémorisé',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.text('Nouvelle partie'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await settle(tester);
    expect(find.text('New game'), findsOneWidget);
    expect(find.text('FR'), findsOneWidget);

    final saved = jsonDecode(File('${dir.path}/settings.json').readAsStringSync());
    expect(saved['language'], 'en');

    // Et retour au français.
    await tester.tap(find.text('FR'));
    await settle(tester);
    expect(find.text('Nouvelle partie'), findsOneWidget);
  });

  testWidgets('sans choix enregistré, suit la langue du téléphone',
      (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
    addTearDown(() =>
        tester.platformDispatcher.localeTestValue = const Locale('fr', 'FR'));
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.text('New game'), findsOneWidget);
  });

  test('en anglais, un nom tiré = épithète anglaise + espèce anglaise', () {
    L10n.current = AppLanguage.en;
    final engine = GameEngine();
    var state = engine.createGame();
    for (var i = 0; i < 6; i++) {
      final r = engine.apply(state, const AddPlayer());
      state = (r as Success).transition.nextState;
    }
    for (final p in state.players) {
      final avatar = AnimalCatalog.byId(p.avatarId)!;
      final species = avatar.localizedSpecies.isEmpty
          ? [avatar.defaultName]
          : avatar.localizedSpecies;
      final matching = species.where((s) => p.displayName.endsWith(s)).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      expect(matching, isNotEmpty,
          reason: '« ${p.displayName} » devrait finir par une espèce anglaise');
      final epithet = p.displayName
          .substring(0, p.displayName.length - matching.first.length)
          .trim();
      expect(AdjectiveCatalog.safeEn, contains(epithet));
    }
  });

  test('épithètes trash : une liste par langue', () {
    final repo = SettingsRepository(dir);
    expect(repo.loadTrashAdjectives(language: AppLanguage.en),
        AdjectiveCatalog.trashEn);
    repo.saveTrashAdjectives(['Potato'], language: AppLanguage.en);
    expect(repo.loadTrashAdjectives(language: AppLanguage.en), ['Potato']);
    // La liste française n'est pas touchée.
    expect(repo.loadTrashAdjectives(language: AppLanguage.fr),
        AdjectiveCatalog.trash);
  });

  test('chaque animal avec des espèces a aussi ses espèces anglaises', () {
    for (final a in AnimalCatalog.all) {
      expect(a.defaultEnglishName, isNotNull, reason: a.id);
      if (a.species.isNotEmpty) {
        expect(a.speciesEn, isNotEmpty, reason: a.id);
      }
    }
  });

  test('chaque « Quoi de neuf » a sa version anglaise', () {
    for (final r in WhatsNewCatalog.releases) {
      expect(r.itemsEn.length, r.items.length, reason: r.version);
    }
  });
}
