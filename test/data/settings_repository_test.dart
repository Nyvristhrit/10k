import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/data/catalogs/adjective_catalog.dart';
import 'package:tenk/data/repositories/settings_repository.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('tenk_settings_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('valeurs par défaut quand aucun fichier n\'existe', () {
    final repo = SettingsRepository(dir);
    expect(repo.loadThemeMode(), ThemeMode.dark);
    expect(repo.loadTrashMode(), isFalse);
    expect(repo.loadTrashAdjectives(), AdjectiveCatalog.trash);
    expect(repo.loadKeepScreenOnEnabled(), isTrue);
    expect(repo.loadDiceTrayEnabled(), isTrue);
  });

  test('mémorise le réglage des dés dans l\'appli', () {
    final repo = SettingsRepository(dir);
    repo.saveDiceTrayEnabled(false);

    final reloaded = SettingsRepository(dir);
    expect(reloaded.loadDiceTrayEnabled(), isFalse);
  });

  test('mémorise la liste complète des épithètes trash', () {
    final repo = SettingsRepository(dir);
    repo.saveTrashAdjectives(['Aubergine', 'Chapardeur']);

    final reloaded = SettingsRepository(dir);
    expect(reloaded.loadTrashAdjectives(), ['Aubergine', 'Chapardeur']);
  });

  test('une liste vidée par la table reste vide', () {
    SettingsRepository(dir).saveTrashAdjectives([]);
    expect(SettingsRepository(dir).loadTrashAdjectives(), isEmpty);
  });

  test('reprend les ajouts perso des versions ≤ 1.6.0', () {
    // Ancien format : seuls les ajouts perso étaient mémorisés, en plus d'un
    // catalogue figé dans l'appli.
    File('${dir.path}/settings.json').writeAsStringSync(
        jsonEncode({'customTrashAdjectives': ['Aubergine', 'Chapardeur']}));
    expect(SettingsRepository(dir).loadTrashAdjectives(),
        [...AdjectiveCatalog.trash, 'Aubergine', 'Chapardeur']);
  });

  test('mémorise le thème et le mode trash', () {
    final repo = SettingsRepository(dir);
    repo.saveThemeMode(ThemeMode.light);
    repo.saveTrashMode(true);

    // Relecture à froid (comme au redémarrage de l'appli).
    final reloaded = SettingsRepository(dir);
    expect(reloaded.loadThemeMode(), ThemeMode.light);
    expect(reloaded.loadTrashMode(), isTrue);
  });

  test('écrire un réglage n\'efface pas l\'autre', () {
    final repo = SettingsRepository(dir);
    repo.saveTrashMode(true);
    repo.saveThemeMode(ThemeMode.light); // ne doit pas perdre le mode trash
    expect(repo.loadTrashMode(), isTrue);

    repo.saveTrashMode(false); // ne doit pas perdre le thème
    expect(repo.loadThemeMode(), ThemeMode.light);
    expect(repo.loadTrashMode(), isFalse);
  });

  test('un fichier illisible retombe sur les valeurs par défaut', () {
    File('${dir.path}/settings.json').writeAsStringSync('{ pas du json');
    final repo = SettingsRepository(dir);
    expect(repo.loadThemeMode(), ThemeMode.dark);
    expect(repo.loadTrashMode(), isFalse);
  });
}
