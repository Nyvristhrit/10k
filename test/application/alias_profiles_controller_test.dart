import 'dart:io';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/repositories/in_memory_game_repository.dart';
import 'package:tenk/data/repositories/settings_repository.dart';
import 'package:tenk/domain/commands/game_command.dart';

/// Profils d'alias : le renommage se répercute sur les parties enregistrées.
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
    notifier.register('@Alex');

    final profiles = container.read(aliasProfilesProvider);
    expect(profiles, hasLength(1));
    expect(profiles.single.alias, '@Alex');

    // Un deuxième enregistrement du même alias ne duplique pas l'entrée.
    notifier.register('@Alex');
    expect(container.read(aliasProfilesProvider), hasLength(1));
  });

  test(
      'la couleur ne s\'impose à la tuile que si « Appliquer à ma tuile » '
      'est coché, et ce choix est mémorisé', () {
    final notifier = container.read(aliasProfilesProvider.notifier);
    notifier.register('@Alex', color: const Color(0xFF7C3AED)); // purple
    expect(notifier.tileColorIdFor('@Alex'), isNull,
        reason: 'désactivé par défaut');

    notifier.setColor('@Alex', const Color(0xFF7C3AED), applyToTile: true);
    expect(notifier.tileColorIdFor('@Alex'), 'purple');
    expect(SettingsRepository(dir).loadAliasProfiles().single.applyToTile,
        isTrue);

    // Changer la couleur sans préciser l'option la conserve.
    notifier.setColor('@Alex', const Color(0xFF059669));
    expect(notifier.tileColorIdFor('@Alex'), 'forest');
    expect(notifier.tileColorIdFor('@Inconnu'), isNull);
  });

  test('rename met à jour le registre ET les parties déjà terminées',
      () async {
    final repo = container.read(gameRepositoryProvider);
    final gameNotifier = container.read(gameControllerProvider.notifier);
    final aliasNotifier = container.read(aliasProfilesProvider.notifier);

    aliasNotifier.register('@Alex');

    // Termine une partie où « Alex » gagne.
    await gameNotifier.newGame();
    await gameNotifier.dispatch(const AddPlayer(displayName: 'Alpha'));
    await gameNotifier.dispatch(const AddPlayer(displayName: 'Beta'));
    final players = container.read(gameControllerProvider).value!.players;
    await gameNotifier.setPlayerAlias(players[0].id, '@Alex');
    await gameNotifier.dispatch(const StartGame());
    final ids = container.read(gameControllerProvider).value!.players;
    await gameNotifier.dispatch(RecordScore(playerId: ids[0].id, amount: 10000));
    await gameNotifier.dispatch(PassTurn(playerId: ids[1].id));
    final finishedId = container.read(gameControllerProvider).value!.id;

    await aliasNotifier.rename('@Alex', 'Alexis');

    expect(container.read(aliasProfilesProvider).single.alias, '@Alexis');

    final reloaded = await repo.loadGame(finishedId);
    expect(reloaded!.players.first.alias, '@Alexis');
  });
}
