import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenk/app/app.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/data/repositories/settings_repository.dart';

void main() {
  testWidgets('parcours accueil → préparation → démarrage', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(InMemoryGameRepository()),
          settingsRepositoryProvider
              .overrideWithValue(SettingsRepository(Directory.systemTemp)),
        ],
        child: const TenkApp(),
      ),
    );
    // L'accueil a une animation continue (bulles d'ambiance) : on ne peut pas
    // utiliser pumpAndSettle (jamais stable). On avance d'une durée fixe.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Accueil.
    expect(find.text('10K'), findsOneWidget);
    expect(find.text('Nouvelle partie'), findsOneWidget);

    // Nouvelle partie -> écran de préparation.
    await tester.tap(find.text('Nouvelle partie'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Préparation'), findsOneWidget);

    // Ajouter deux joueurs.
    await tester.tap(find.textContaining('Ajouter un joueur'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.textContaining('Ajouter un joueur'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Démarrer la partie.
    expect(find.text('Commencer la partie'), findsOneWidget);
    await tester.tap(find.text('Commencer la partie'));
    // Le plateau a lui aussi des animations infinies (halo) : durée fixe.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Plateau : la manche 1 est affichée (mode guidé par défaut).
    expect(find.text('Manche 1'), findsOneWidget);
  });
}
