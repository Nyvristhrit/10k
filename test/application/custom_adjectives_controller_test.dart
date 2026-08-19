import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/application/controllers/custom_adjectives_controller.dart';
import 'package:tenk/application/providers/app_providers.dart';
import 'package:tenk/data/repositories/settings_repository.dart';

void main() {
  late Directory dir;
  late ProviderContainer container;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tenk_custom_adjectives_');
    container = ProviderContainer(overrides: [
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(dir)),
    ]);
  });
  tearDown(() {
    container.dispose();
    dir.deleteSync(recursive: true);
  });

  test('ajoute et retire une épithète, mémorisée entre deux instances', () {
    container.read(customTrashAdjectivesProvider.notifier).add('Aubergine');
    expect(container.read(customTrashAdjectivesProvider), ['Aubergine']);

    // Relecture à froid (nouvelle instance du dépôt, comme au redémarrage).
    final reloaded = SettingsRepository(dir);
    expect(reloaded.loadCustomTrashAdjectives(), ['Aubergine']);

    container.read(customTrashAdjectivesProvider.notifier).remove('Aubergine');
    expect(container.read(customTrashAdjectivesProvider), isEmpty);
  });

  test('ignore les doublons et les entrées vides', () {
    final notifier = container.read(customTrashAdjectivesProvider.notifier);
    notifier.add('Aubergine');
    notifier.add('Aubergine');
    notifier.add('   ');
    expect(container.read(customTrashAdjectivesProvider), ['Aubergine']);
  });

  test('plafonne à ${CustomAdjectivesController.maxCount} épithètes', () {
    final notifier = container.read(customTrashAdjectivesProvider.notifier);
    for (var i = 0; i < CustomAdjectivesController.maxCount + 5; i++) {
      notifier.add('Adjectif$i');
    }
    expect(container.read(customTrashAdjectivesProvider).length,
        CustomAdjectivesController.maxCount);
  });
}
