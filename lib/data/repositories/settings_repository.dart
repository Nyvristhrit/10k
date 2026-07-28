import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Réglages généraux de l'appli (hors règles de jeu), stockés dans un petit
/// fichier JSON du dossier de documents. Pour l'instant : le thème (jour/nuit).
///
/// Volontairement minimaliste et synchrone : c'est un unique petit fichier, lu
/// une fois au démarrage et réécrit à chaque changement.
class SettingsRepository {
  SettingsRepository(this._directory);

  final Directory _directory;

  File get _file => File('${_directory.path}/settings.json');

  /// Lit le mode de thème mémorisé (défaut : nuit).
  ThemeMode loadThemeMode() {
    try {
      if (!_file.existsSync()) return ThemeMode.dark;
      final map = jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>;
      return switch (map['themeMode']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.dark,
      };
    } catch (_) {
      return ThemeMode.dark;
    }
  }

  /// Mémorise le mode de thème choisi.
  void saveThemeMode(ThemeMode mode) {
    try {
      final name = mode == ThemeMode.light ? 'light' : 'dark';
      _file.writeAsStringSync(jsonEncode(<String, String>{'themeMode': name}));
    } catch (_) {
      // Un échec d'écriture du réglage ne doit jamais faire planter l'appli.
    }
  }
}
