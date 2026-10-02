import 'dart:io';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/data/repositories/settings_repository.dart';
import 'package:tenk/domain/commands/game_command.dart';

/// Alias joueur (§ évolution « alias joueur ») : renommer un profil doit se
/// répercuter sur l'historique des parties déjà enregistrées, pour que les
/// statistiques restent cohérentes avec le nouveau nom.
void main() {
  late Directory dir;
  late ProviderContainer container;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tenk_alias_profiles_');
    container = ProviderContainer(overrides: [
      gameRepositoryProvider.overrideWithValue(InMemoryGameRepository()),
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(dir)),
    ]);
  });
  tearDown(() {
    container.dispose();
    dir.deleteSync(recursive: true);
  });

  test('register crée un profil avec une couleur assignée', () {
    final notifier = container.read(aliasProfilesProvider.notifier);
    notifier.register('@Ben');

    final profiles = container.read(aliasProfilesProvider);
    expect(profiles, hasLength(1));
    expect(profiles.single.alias, '@Ben');

    // Un deuxième enregistrement du même alias ne duplique pas l'entrée.
    notifier.register('@Ben');
    expect(container.read(aliasProfilesProvider), hasLength(1));
  });

  test(
      'la couleur ne s\'impose à la tuile que si « Appliquer à ma tuile » '
      'est coché, et ce choix est mémorisé', () {
    final notifier = container.read(aliasProfilesProvider.notifier);
    notifier.register('@Ben', color: const Color(0xFF7C3AED)); // purple
    expect(notifier.tileColorIdFor('@Ben'), isNull,
        reason: 'désactivé par défaut');

    notifier.setColor('@Ben', const Color(0xFF7C3AED), applyToTile: true);
    expect(notifier.tileColorIdFor('@Ben'), 'purple');
    expect(SettingsRepository(dir).loadAliasProfiles().single.applyToTile,
        isTrue);

    // Changer la couleur sans préciser l'option la conserve.
    notifier.setColor('@Ben', const Color(0xFF059669));
    expect(notifier.tileColorIdFor('@Ben'), 'forest');
    expect(notifier.tileColorIdFor('@Inconnu'), isNull);
  });

  test('rename met à jour le registre ET les parties déjà terminées',
      () async {
    final repo = container.read(gameRepositoryProvider);
    final gameNotifier = container.read(gameControllerProvider.notifier);
    final aliasNotifier = container.read(aliasProfilesProvider.notifier);

    aliasNotifier.register('@Ben');

    // Termine une partie où « Ben » gagne.
    await gameNotifier.newGame();
    await gameNotifier.dispatch(const AddPlayer(displayName: 'Alpha'));
    await gameNotifier.dispatch(const AddPlayer(displayName: 'Beta'));
    final players = container.read(gameControllerProvider).value!.players;
    await gameNotifier.setPlayerAlias(players[0].id, '@Ben');
    await gameNotifier.dispatch(const StartGame());
    final ids = container.read(gameControllerProvider).value!.players;
    await gameNotifier.dispatch(RecordScore(playerId: ids[0].id, amount: 10000));
    await gameNotifier.dispatch(PassTurn(playerId: ids[1].id));
    final finishedId = container.read(gameControllerProvider).value!.id;

    await aliasNotifier.rename('@Ben', 'Benji');

    expect(container.read(aliasProfilesProvider).single.alias, '@Benji');

    final reloaded = await repo.loadGame(finishedId);
    expect(reloaded!.players.first.alias, '@Benji');
  });
}
