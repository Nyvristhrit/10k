import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
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

  /// Crée le profil s'il est nouveau (couleur assignée automatiquement,
  /// piochée de façon stable à partir de l'alias) ; ne fait rien s'il existe
  /// déjà.
  void register(String alias) {
    if (alias.isEmpty || state.any((p) => p.alias == alias)) return;
    final profile = AliasProfile(
      alias: alias,
      colorArgb: _autoColorFor(alias).toARGB32(),
    );
    state = state.length >= maxCount
        ? [...state.skip(1), profile] // le plus ancien cède sa place
        : [...state, profile];
    _persist();
  }

  /// Change la couleur d'un profil existant.
  void setColor(String alias, Color color) {
    state = [
      for (final p in state)
        if (p.alias == alias) p.copyWith(colorArgb: color.toARGB32()) else p,
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

  /// Couleur stable (toujours la même pour un alias donné) piochée dans la
  /// palette d'accent de l'appli — sert de défaut tant que la personne n'a
  /// pas choisi la sienne.
  static Color _autoColorFor(String alias) {
    final seeds = AppTheme.accentSeeds;
    return seeds[alias.hashCode.abs() % seeds.length];
  }
}
