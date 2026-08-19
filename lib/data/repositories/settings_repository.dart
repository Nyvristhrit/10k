import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Réglages généraux de l'appli (hors règles de jeu), stockés dans un petit
/// fichier JSON du dossier de documents : le thème (jour/nuit) et le mode trash.
///
/// Volontairement minimaliste et synchrone : c'est un unique petit fichier, lu
/// une fois au démarrage et réécrit à chaque changement. Chaque écriture
/// **relit puis fusionne** le contenu existant, pour qu'un réglage n'efface
/// jamais l'autre.
class SettingsRepository {
  SettingsRepository(this._directory);

  final Directory _directory;

  File get _file => File('${_directory.path}/settings.json');

  Map<String, dynamic> _read() {
    try {
      if (!_file.existsSync()) return {};
      final decoded = jsonDecode(_file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  void _write(String key, Object value) {
    try {
      final map = _read()..[key] = value;
      _file.writeAsStringSync(jsonEncode(map));
    } catch (_) {
      // Un échec d'écriture d'un réglage ne doit jamais faire planter l'appli.
    }
  }

  /// Lit le mode de thème mémorisé (défaut : nuit).
  ThemeMode loadThemeMode() {
    return switch (_read()['themeMode']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
  }

  /// Mémorise le mode de thème choisi.
  void saveThemeMode(ThemeMode mode) =>
      _write('themeMode', mode == ThemeMode.light ? 'light' : 'dark');

  /// Le mode trash est-il débloqué ? (défaut : non — il se mérite.)
  bool loadTrashMode() => _read()['trashMode'] == true;

  /// Mémorise l'état du mode trash : une fois débloqué, il le reste jusqu'à ce
  /// qu'on le désactive volontairement.
  void saveTrashMode(bool enabled) => _write('trashMode', enabled);

  /// Épithètes trash ajoutées par la table (en plus du catalogue de base),
  /// pour glisser des blagues ou des références perso dans les noms tirés.
  List<String> loadCustomTrashAdjectives() {
    final raw = _read()['customTrashAdjectives'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }

  /// Mémorise la liste d'épithètes trash perso.
  void saveCustomTrashAdjectives(List<String> adjectives) =>
      _write('customTrashAdjectives', adjectives);

  /// L'écran doit-il rester allumé pendant une partie (défaut : oui) ? Réglage
  /// général, indépendant d'une partie — désactivable pour l'économie de
  /// batterie.
  bool loadKeepScreenOnEnabled() {
    final raw = _read()['keepScreenOnEnabled'];
    return raw is bool ? raw : true;
  }

  /// Mémorise le réglage d'écran toujours allumé.
  void saveKeepScreenOnEnabled(bool enabled) =>
      _write('keepScreenOnEnabled', enabled);
}
