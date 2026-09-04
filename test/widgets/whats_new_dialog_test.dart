import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/app/app.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/catalogs/whats_new_catalog.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/data/repositories/settings_repository.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('tenk_whats_new_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pumpApp(WidgetTester tester, SettingsRepository repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(InMemoryGameRepository()),
          settingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: const TenkApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets(
      'toute première installation : rien à montrer, juste mémorisé',
      (tester) async {
    final repo = SettingsRepository(dir);
    await pumpApp(tester, repo);

    expect(find.text('Quoi de neuf'), findsNothing);
    expect(repo.loadLastSeenWhatsNewVersion(),
        WhatsNewCatalog.releases.last.version);
  });

  testWidgets(
      'joueur existant en retard sur les nouveautés : popup affichée',
      (tester) async {
    final repo = SettingsRepository(dir)
      ..saveTrashMode(false) // simule un appareil déjà utilisé
      ..saveLastSeenWhatsNewVersion('1.2.0');
    await pumpApp(tester, repo);

    expect(find.text('Quoi de neuf'), findsOneWidget);
    // La dernière version notée doit apparaître.
    expect(find.text('v${WhatsNewCatalog.releases.last.version}'),
        findsOneWidget);
    // v1.2.0 déjà vu ne doit pas réapparaître.
    expect(find.text('v1.2.0'), findsNothing);

    await tester.tap(find.text('Super !'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Quoi de neuf'), findsNothing);
    expect(repo.loadLastSeenWhatsNewVersion(),
        WhatsNewCatalog.releases.last.version);
  });

  testWidgets(
      'joueur existant, clé jamais enregistrée : tout l\'historique notable '
      'est montré (pas juste la dernière version)', (tester) async {
    // Simule un appareil déjà utilisé, mis à jour avant l'ajout de cette
    // fonctionnalité : `lastSeenWhatsNewVersion` n'existe pas encore, mais
    // d'autres réglages si. Un joueur qui a sauté plusieurs versions d'un
    // coup ne doit rater aucune nouveauté notable.
    final repo = SettingsRepository(dir)..saveTrashMode(false);
    await pumpApp(tester, repo);

    expect(find.text('Quoi de neuf'), findsOneWidget);
    for (final release in WhatsNewCatalog.releases) {
      expect(find.text('v${release.version}'), findsOneWidget);
    }
  });

  testWidgets('déjà à jour : pas de popup', (tester) async {
    final repo = SettingsRepository(dir)
      ..saveLastSeenWhatsNewVersion(WhatsNewCatalog.releases.last.version);
    await pumpApp(tester, repo);

    expect(find.text('Quoi de neuf'), findsNothing);
  });
}
