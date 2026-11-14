import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/alias_profile.dart';
import '../../l10n/l10n.dart';
import '../catalogs/adjective_catalog.dart';

/// Réglages généraux de l'appli (hors règles de jeu), dans un petit fichier
/// JSON. Accès synchrone ; chaque écriture relit puis fusionne le contenu
/// existant pour ne pas écraser les autres réglages.
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
      // Un échec d'écriture ne doit pas faire planter l'appli.
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

  /// Langue choisie, ou `null` pour suivre celle du téléphone.
  AppLanguage? loadLanguage() {
    final raw = _read()['language'];
    return AppLanguage.fromCode(raw is String ? raw : null);
  }

  /// Mémorise la langue choisie.
  void saveLanguage(AppLanguage language) => _write('language', language.code);

  /// Le mode trash est-il débloqué ? (défaut : non)
  bool loadTrashMode() => _read()['trashMode'] == true;

  /// Mémorise l'état du mode trash.
  void saveTrashMode(bool enabled) => _write('trashMode', enabled);

  /// Liste complète des épithètes trash (modifiable), par langue :
  /// `trashAdjectives` (fr) et `trashAdjectivesEn` (en).
  ///
  /// Par défaut : [AdjectiveCatalog.trash]. Compat : l'ancienne clé
  /// `customTrashAdjectives` (ajouts seuls) est ajoutée à la liste par défaut.
  List<String> loadTrashAdjectives({AppLanguage? language}) {
    final data = _read();
    if ((language ?? L10n.current) == AppLanguage.en) {
      final raw = data['trashAdjectivesEn'];
      if (raw is List) return raw.whereType<String>().toList();
      return List.of(AdjectiveCatalog.trashEn);
    }
    final raw = data['trashAdjectives'];
    if (raw is List) return raw.whereType<String>().toList();
    final legacy = data['customTrashAdjectives'];
    final custom =
        legacy is List ? legacy.whereType<String>() : const <String>[];
    return {...AdjectiveCatalog.trash, ...custom}.toList();
  }

  /// Mémorise la liste complète d'épithètes trash.
  void saveTrashAdjectives(List<String> adjectives, {AppLanguage? language}) =>
      _write(
          (language ?? L10n.current) == AppLanguage.en
              ? 'trashAdjectivesEn'
              : 'trashAdjectives',
          adjectives);

  /// L'écran reste-t-il allumé pendant une partie ? (défaut : oui)
  bool loadKeepScreenOnEnabled() {
    final raw = _read()['keepScreenOnEnabled'];
    return raw is bool ? raw : true;
  }

  /// Mémorise le réglage d'écran toujours allumé.
  void saveKeepScreenOnEnabled(bool enabled) =>
      _write('keepScreenOnEnabled', enabled);

  /// Le plateau de dés virtuel est-il proposé ? (défaut : oui)
  bool loadDiceTrayEnabled() {
    final raw = _read()['diceTrayEnabled'];
    return raw is bool ? raw : true;
  }

  /// Mémorise le réglage du plateau de dés virtuel.
  void saveDiceTrayEnabled(bool enabled) =>
      _write('diceTrayEnabled', enabled);

  /// Mode trash : le bon dernier pète-t-il à la saisie du score ? (défaut : oui)
  bool loadCradoFartsEnabled() {
    final raw = _read()['cradoFartsEnabled'];
    return raw is bool ? raw : true;
  }

  void saveCradoFartsEnabled(bool enabled) =>
      _write('cradoFartsEnabled', enabled);

  /// Mode trash : le bon dernier se couvre-t-il de taches (défaut : oui) ?
  bool loadCradoStainsEnabled() {
    final raw = _read()['cradoStainsEnabled'];
    return raw is bool ? raw : true;
  }

  void saveCradoStainsEnabled(bool enabled) =>
      _write('cradoStainsEnabled', enabled);

  /// Taches accumulées par le bon dernier dans la partie [gameId].
  ({String? gameId, int count}) loadCradoStains() {
    final raw = _read()['cradoStains'];
    if (raw is Map && raw['gameId'] is String && raw['count'] is int) {
      return (gameId: raw['gameId'] as String, count: raw['count'] as int);
    }
    return (gameId: null, count: 0);
  }

  void saveCradoStains({required String gameId, required int count}) =>
      _write('cradoStains', {'gameId': gameId, 'count': count});

  /// Profils d'alias enregistrés sur l'appareil.
  List<AliasProfile> loadAliasProfiles() {
    final raw = _read()['aliasProfiles'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AliasProfile.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Mémorise la liste des profils d'alias.
  void saveAliasProfiles(List<AliasProfile> profiles) =>
      _write('aliasProfiles', profiles.map((p) => p.toJson()).toList());

  /// Dernière version dont « Quoi de neuf » a été vu, ou `null` si jamais
  /// enregistrée.
  String? loadLastSeenWhatsNewVersion() {
    final raw = _read()['lastSeenWhatsNewVersion'];
    return raw is String ? raw : null;
  }

  /// Mémorise la dernière version vue dans « Quoi de neuf ».
  void saveLastSeenWhatsNewVersion(String version) =>
      _write('lastSeenWhatsNewVersion', version);

  /// Y a-t-il déjà des réglages enregistrés ? Distingue une première
  /// installation d'une mise à jour.
  bool hasAnySettings() => _read().isNotEmpty;
}
