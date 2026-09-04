import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/app/app.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/data/repositories/settings_repository.dart';

/// Le mode paysage n'a jamais pu être testé sur un vrai appareil (aucune
/// tablette disponible) : on vérifie au moins ici, sur une taille d'écran
/// large et courte, qu'aucun écran ne déborde (`RenderFlex overflowed`) — le
/// bug qui avait fait verrouiller le portrait avant l'ouverture de la rotation.
void main() {
  // Un dossier de réglages dédié par test (et non `Directory.systemTemp`
  // partagé) : sinon un réglage écrit par un autre fichier de test qui
  // partage aussi ce dossier partagé (ex. `lastSeenWhatsNewVersion`) peut
  // faire apparaître un dialogue inattendu ici et bloquer les taps suivants.
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('tenk_landscape_'));
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets(
      'accueil et plateau (beaucoup de joueurs) ne débordent pas en paysage',
      (tester) async {
    // Écran large et court, façon tablette en paysage.
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(InMemoryGameRepository()),
          settingsRepositoryProvider
              .overrideWithValue(SettingsRepository(dir)),
        ],
        child: const TenkApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull, reason: 'accueil');

    await tester.tap(find.text('Nouvelle partie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'préparation');

    // Six joueurs : déclenche la mise en vedette (spotlight) du plateau.
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.textContaining('Ajouter un joueur'));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'préparation (6 joueurs)');

    await tester.tap(find.text('Commencer la partie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'plateau (spotlight)');
  });

  testWidgets('accueil et plateau ne débordent pas sur un petit paysage',
      (tester) async {
    // Le plus petit paysage plausible (petit téléphone posé à l'horizontale).
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(InMemoryGameRepository()),
          settingsRepositoryProvider
              .overrideWithValue(SettingsRepository(dir)),
        ],
        child: const TenkApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull, reason: 'accueil (petit paysage)');

    await tester.tap(find.text('Nouvelle partie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.textContaining('Ajouter un joueur'));
    await tester.pump();
    await tester.tap(find.textContaining('Ajouter un joueur'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Commencer la partie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'plateau (petit paysage)');
  });
}
