import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/alias_profile.dart';
import '../catalogs/adjective_catalog.dart';

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

  /// Épithètes du mode trash utilisées pour tirer les noms — **la liste
  /// complète**, entièrement modifiable par la table dans les réglages
  /// (depuis la v1.6.1 ; voir DECISIONS F-006).
  ///
  /// Tant que la table n'y a pas touché : la liste par défaut
  /// ([AdjectiveCatalog.trash]). Reprise des versions ≤ 1.6.0, qui ne
  /// mémorisaient que les ajouts perso (`customTrashAdjectives`) en plus d'un
  /// catalogue figé : ces ajouts sont conservés, à la suite de la liste par
  /// défaut.
  List<String> loadTrashAdjectives() {
    final data = _read();
    final raw = data['trashAdjectives'];
    if (raw is List) return raw.whereType<String>().toList();
    final legacy = data['customTrashAdjectives'];
    final custom =
        legacy is List ? legacy.whereType<String>() : const <String>[];
    return {...AdjectiveCatalog.trash, ...custom}.toList();
  }

  /// Mémorise la liste complète d'épithètes trash.
  void saveTrashAdjectives(List<String> adjectives) =>
      _write('trashAdjectives', adjectives);

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

  /// Le plateau de dés virtuel est-il proposé (icône sur le plateau) ? Réglage
  /// général, indépendant d'une partie (défaut : oui) — à désactiver si on
  /// joue avec de vrais dés, pour libérer une icône.
  bool loadDiceTrayEnabled() {
    final raw = _read()['diceTrayEnabled'];
    return raw is bool ? raw : true;
  }

  /// Mémorise le réglage du plateau de dés virtuel.
  void saveDiceTrayEnabled(bool enabled) =>
      _write('diceTrayEnabled', enabled);

  /// Mode trash : le bon dernier pète-t-il à chaque bouton de la
  /// saisie du score (défaut : oui) ?
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

  /// Taches accumulées par le bon dernier, pour la partie [gameId] seulement
  /// (une nouvelle partie repart propre).
  ({String? gameId, int count}) loadCradoStains() {
    final raw = _read()['cradoStains'];
    if (raw is Map && raw['gameId'] is String && raw['count'] is int) {
      return (gameId: raw['gameId'] as String, count: raw['count'] as int);
    }
    return (gameId: null, count: 0);
  }

  void saveCradoStains({required String gameId, required int count}) =>
      _write('cradoStains', {'gameId': gameId, 'count': count});

  /// Tous les profils d'alias déjà créés sur l'appareil (§ évolution « alias
  /// joueur ») : de quoi les reproposer d'une partie à l'autre sans les
  /// retaper, et alimenter l'écran « Alias & profils ».
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

  /// La dernière version notable dont le joueur a déjà vu les nouveautés
  /// (popup « Quoi de neuf » à l'ouverture de l'appli). `null` si jamais
  /// enregistré (première ouverture, ou mise à jour depuis une version
  /// antérieure à l'ajout de cette fonctionnalité).
  String? loadLastSeenWhatsNewVersion() {
    final raw = _read()['lastSeenWhatsNewVersion'];
    return raw is String ? raw : null;
  }

  /// Mémorise la version dont les nouveautés viennent d'être montrées (ou
  /// qu'il n'y a pas lieu de montrer, cf. `WhatsNewCatalog`).
  void saveLastSeenWhatsNewVersion(String version) =>
      _write('lastSeenWhatsNewVersion', version);

  /// Y a-t-il déjà des réglages enregistrés sur cet appareil ? Sert à
  /// distinguer une toute première installation (rien à montrer dans le
  /// popup « Quoi de neuf », il n'y a pas d'« avant ») d'une mise à jour
  /// depuis une version où cette clé n'existait pas encore.
  bool hasAnySettings() => _read().isNotEmpty;
}
