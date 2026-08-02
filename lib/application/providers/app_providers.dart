import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/game_engine.dart';
import '../controllers/game_controller.dart';
import '../controllers/theme_controller.dart';

/// Dépôt de persistance. Surchargé dans `main()` avec l'implémentation fichier
/// branchée sur le dossier de documents de l'appareil.
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => throw UnimplementedError(
      'gameRepositoryProvider doit être surchargé dans main().'),
);

/// Dépôt des réglages généraux (thème…). Surchargé dans `main()`.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError(
      'settingsRepositoryProvider doit être surchargé dans main().'),
);

/// Thème courant (jour/nuit), mémorisé entre les sessions.
final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Couleur d'accent de l'UI, tirée au hasard **à chaque ouverture** de l'appli
/// (le provider n'est créé qu'une fois par lancement). Petit détail ludique et
/// multicolore ; volontairement pas mémorisé pour changer à chaque fois.
final accentSeedProvider = Provider<Color>((ref) {
  final seeds = AppTheme.accentSeeds;
  return seeds[Random().nextInt(seeds.length)];
});

/// Moteur de jeu (logique pure).
final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

/// Partie active courante (null s'il n'y en a pas).
final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameState?>(GameController.new);

/// Scores « gelés » le temps d'afficher l'alerte de rencontre.
///
/// Quand une rencontre se produit avec l'alerte activée, on fige les totaux
/// concernés (le marqueur et ses victimes) à leur **ancienne** valeur pendant
/// que le message est affiché. Une fois le message validé, on vide cette carte :
/// les compteurs rejoignent alors leur vraie valeur en s'animant — le marqueur
/// qui grimpe, les victimes qui décroissent — bien visible, plutôt que caché
/// derrière la fenêtre. Clé = id du joueur, valeur = score à afficher en attendant.
final frozenScoresProvider =
    StateProvider<Map<String, int>>((ref) => const {});
