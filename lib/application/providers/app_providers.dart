import 'dart:math';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../domain/models/alias_profile.dart';
import '../../domain/models/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/game_engine.dart';
import '../../shared/trash/fart_player.dart';
import '../controllers/alias_profiles_controller.dart';
import '../controllers/crado_controller.dart';
import '../controllers/dice_tray_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/keep_screen_on_controller.dart';
import '../controllers/language_controller.dart';
import '../../l10n/l10n.dart';
import '../controllers/theme_controller.dart';
import '../controllers/trash_adjectives_controller.dart';
import '../controllers/trash_controller.dart';

/// Dépôt de persistance. Surchargé dans `main()` avec l'implémentation fichier.
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

/// Langue de l'interface (français / anglais), mémorisée entre les sessions.
final languageProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);

/// Mode trash : habillage néon et commentaires acides, mémorisé.
final trashModeProvider =
    NotifierProvider<TrashModeController, bool>(TrashModeController.new);

/// Épithètes du mode trash utilisées pour les noms, modifiables dans les réglages.
final trashAdjectivesProvider =
    NotifierProvider<TrashAdjectivesController, List<String>>(
        TrashAdjectivesController.new);

/// Réglage « garder l'écran allumé pendant la partie » (mémorisé, défaut oui).
final keepScreenOnEnabledProvider =
    NotifierProvider<KeepScreenOnController, bool>(
        KeepScreenOnController.new);

/// Réglage « dés dans l'appli » (icône sur le plateau, mémorisé, défaut oui).
final diceTrayEnabledProvider =
    NotifierProvider<DiceTrayController, bool>(DiceTrayController.new);

/// Réglages du « bon dernier » du mode trash (prouts, taches), mémorisés.
final cradoSettingsProvider =
    NotifierProvider<CradoSettingsController, CradoSettings>(
        CradoSettingsController.new);

/// Taches accumulées par le bon dernier dans la partie en cours.
final cradoStainsProvider = NotifierProvider<CradoStainsController,
    ({String? gameId, int count})>(CradoStainsController.new);

/// Lecteur des prouts du bon dernier. Surchargé dans les tests (pas d'audio).
final fartPlayerProvider = Provider<FartPlayer>((ref) {
  final player = FartPlayer();
  ref.onDispose(player.dispose);
  return player;
});

/// Profils d'alias enregistrés sur l'appareil.
final aliasProfilesProvider =
    NotifierProvider<AliasProfilesController, List<AliasProfile>>(
        AliasProfilesController.new);

/// Indice de la teinte d'accent, tiré au hasard à chaque lancement. C'est un
/// indice et non une couleur : la palette dépend de l'habillage.
final accentSeedIndexProvider = Provider<int>((ref) => Random().nextInt(1 << 20));

/// Moteur de jeu (logique pure).
final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

/// Partie active courante (null s'il n'y en a pas).
final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameState?>(GameController.new);

/// Toutes les parties terminées de l'appareil. `autoDispose` : relu à chaque
/// ouverture de l'écran de stats.
final finishedGamesProvider = FutureProvider.autoDispose<List<GameState>>(
  (ref) => ref.read(gameRepositoryProvider).loadFinishedGames(),
);

/// Scores figés pendant l'alerte de rencontre (id du joueur -> ancien score).
/// Vidée à la fermeture de l'alerte, pour que les compteurs s'animent ensuite.
final frozenScoresProvider =
    StateProvider<Map<String, int>>((ref) => const {});
