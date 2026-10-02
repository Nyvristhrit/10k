import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalogs/color_catalog.dart';
import '../../domain/models/alias_profile.dart';
import '../providers/app_providers.dart';

/// Registre de tous les profils d'alias créés sur l'appareil, mémorisé via
/// `SettingsRepository` (§ évolution « alias joueur »). Alimente la modalité
/// de sélection rapide (assigner un alias à un joueur) et l'écran « Alias &
/// profils » (bilan par personne, renommage, couleur).
class AliasProfilesController extends Notifier<List<AliasProfile>> {
  /// Au-delà, la liste deviendrait difficile à parcourir.
  static const int maxCount = 40;

  @override
  List<AliasProfile> build() =>
      ref.read(settingsRepositoryProvider).loadAliasProfiles();

  /// Crée le profil s'il est nouveau, avec la [color] donnée (en pratique la
  /// couleur de tuile du joueur à qui on vient de donner cet alias) ou, à
  /// défaut, une couleur piochée de façon stable à partir de l'alias. Ne fait
  /// rien s'il existe déjà.
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

  /// Change la couleur d'un profil existant, et (si précisé) si elle
  /// s'applique à la tuile du joueur.
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

  /// Renomme un alias — **et le répercute sur toutes les parties déjà
  /// enregistrées** (terminées, et la partie en cours le cas échéant) pour
  /// que l'historique et les statistiques restent cohérents avec le
  /// nouveau nom.
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

    // La partie en cours (si elle porte cet alias) ne repasse pas par le
    // moteur : c'est une correction de registre, pas une règle du jeu.
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

  /// Couleur de tuile (id du `ColorCatalog`) à imposer au joueur qui reçoit
  /// cet alias — `null` si l'alias n'a pas de profil ou si son option
  /// « Appliquer à ma tuile » est désactivée.
  String? tileColorIdFor(String alias) {
    final profile = profileOf(alias);
    if (profile == null || !profile.applyToTile) return null;
    return ColorCatalog.tileForArgb(profile.colorArgb).id;
  }

  /// Couleur stable (toujours la même pour un alias donné) piochée dans la
  /// palette des tuiles — sert de défaut tant que la personne n'a pas choisi
  /// la sienne.
  static Color _autoColorFor(String alias) {
    final tiles = ColorCatalog.all;
    return Color(tiles[alias.hashCode.abs() % tiles.length].backgroundArgb);
  }
}
