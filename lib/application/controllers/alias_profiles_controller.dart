import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalogs/color_catalog.dart';
import '../../domain/models/alias_profile.dart';
import '../providers/app_providers.dart';

/// Profils d'alias enregistrés sur l'appareil (via `SettingsRepository`).
class AliasProfilesController extends Notifier<List<AliasProfile>> {
  /// Au-delà, la liste deviendrait difficile à parcourir.
  static const int maxCount = 40;

  @override
  List<AliasProfile> build() =>
      ref.read(settingsRepositoryProvider).loadAliasProfiles();

  /// Crée le profil s'il est nouveau, avec [color] ou à défaut une couleur
  /// stable dérivée de l'alias.
  void register(String alias, {Color? color}) {
    if (alias.isEmpty || state.any((p) => p.alias == alias)) return;
    final profile = AliasProfile(
      alias: alias,
      colorArgb: (color ?? _autoColorFor(alias)).toARGB32(),
    );
    state = state.length >= maxCount
        ? [...state.skip(1), profile] // le plus ancien cède sa place
        : [...state, profile];
    _persist();
  }

  /// Change la couleur d'un profil et, si précisé, son application à la tuile.
  void setColor(String alias, Color color, {bool? applyToTile}) {
    state = [
      for (final p in state)
        if (p.alias == alias)
          p.copyWith(colorArgb: color.toARGB32(), applyToTile: applyToTile)
        else
          p,
    ];
    _persist();
  }

  /// Renomme un alias, y compris dans toutes les parties enregistrées, pour
  /// garder des statistiques cohérentes.
  Future<void> rename(String oldAlias, String newAlias) async {
    final normalized = newAlias.startsWith('@') ? newAlias : '@$newAlias';
    if (normalized == oldAlias) return;
    state = [
      for (final p in state)
        if (p.alias == oldAlias) p.copyWith(alias: normalized) else p,
    ];
    _persist();

    final repo = ref.read(gameRepositoryProvider);
    final games = await repo.loadFinishedGames();
    for (final game in games) {
      if (!game.players.any((p) => p.alias == oldAlias)) continue;
      final players = game.players
          .map((p) => p.alias == oldAlias
              ? p.copyWith(alias: normalized)
              : p)
          .toList();
      await repo.saveSnapshot(game.copyWith(players: players));
    }

    // Partie en cours : correction directe, sans passer par le moteur.
    final controller = ref.read(gameControllerProvider.notifier);
    final current = ref.read(gameControllerProvider).value;
    if (current != null && current.players.any((p) => p.alias == oldAlias)) {
      await controller.renameAliasInPlace(oldAlias, normalized);
    }
  }

  void remove(String alias) {
    state = state.where((p) => p.alias != alias).toList();
    _persist();
  }

  void _persist() =>
      ref.read(settingsRepositoryProvider).saveAliasProfiles(state);

  /// Le profil d'un alias, ou `null` s'il n'en a pas encore.
  AliasProfile? profileOf(String alias) {
    for (final p in state) {
      if (p.alias == alias) return p;
    }
    return null;
  }

  /// Id de couleur de tuile à imposer au joueur qui reçoit cet alias, ou
  /// `null` (pas de profil, ou option « Appliquer à ma tuile » désactivée).
  String? tileColorIdFor(String alias) {
    final profile = profileOf(alias);
    if (profile == null || !profile.applyToTile) return null;
    return ColorCatalog.tileForArgb(profile.colorArgb).id;
  }

  /// Couleur par défaut, toujours la même pour un alias donné.
  static Color _autoColorFor(String alias) {
    final tiles = ColorCatalog.all;
    return Color(tiles[alias.hashCode.abs() % tiles.length].backgroundArgb);
  }
}
