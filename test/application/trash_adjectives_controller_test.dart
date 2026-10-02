import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/application/controllers/trash_adjectives_controller.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/catalogs/adjective_catalog.dart';
import 'package:tenk/data/repositories/settings_repository.dart';

void main() {
  late Directory dir;
  late ProviderContainer container;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tenk_trash_adjectives_');
    container = ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(dir)),
    ]);
  });
  tearDown(() {
    container.dispose();
    dir.deleteSync(recursive: true);
  });

  test('démarre sur la liste par défaut', () {
    expect(container.read(trashAdjectivesProvider), AdjectiveCatalog.trash);
  });

  test('ajoute et retire une épithète, mémorisée entre deux instances', () {
    final notifier = container.read(trashAdjectivesProvider.notifier);
    notifier.add('Aubergine');
    expect(container.read(trashAdjectivesProvider).last, 'Aubergine');

    // Relecture à froid (nouvelle instance du dépôt, comme au redémarrage).
    expect(SettingsRepository(dir).loadTrashAdjectives().last, 'Aubergine');

    notifier.remove('Aubergine');
    expect(container.read(trashAdjectivesProvider), AdjectiveCatalog.trash);
  });

  test('peut retirer une épithète par défaut, et la retrouver en rétablissant',
      () {
    final notifier = container.read(trashAdjectivesProvider.notifier);
    final first = AdjectiveCatalog.trash.first;
    notifier.remove(first);
    expect(container.read(trashAdjectivesProvider), isNot(contains(first)));
    expect(SettingsRepository(dir).loadTrashAdjectives(),
        isNot(contains(first)));

    notifier.add('Aubergine');
    notifier.resetToDefaults();
    expect(container.read(trashAdjectivesProvider), AdjectiveCatalog.trash);
  });

  test('ignore les doublons et les entrées vides', () {
    final notifier = container.read(trashAdjectivesProvider.notifier);
    notifier.add('Aubergine');
    notifier.add('Aubergine');
    notifier.add('   ');
    expect(
        container
            .read(trashAdjectivesProvider)
            .where((a) => a == 'Aubergine' || a.trim().isEmpty),
        ['Aubergine']);
  });

  test('plafonne à ${TrashAdjectivesController.maxCount} épithètes', () {
    final notifier = container.read(trashAdjectivesProvider.notifier);
    for (var i = 0; i < TrashAdjectivesController.maxCount + 5; i++) {
      notifier.add('Adjectif$i');
    }
    expect(container.read(trashAdjectivesProvider).length,
        TrashAdjectivesController.maxCount);
  });
}
