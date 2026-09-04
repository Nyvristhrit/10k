import 'dart:math';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';
import '../../domain/models/alias_profile.dart';
import '../../domain/models/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/game_engine.dart';
import '../controllers/alias_profiles_controller.dart';
import '../controllers/custom_adjectives_controller.dart';
import '../controllers/dice_tray_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/keep_screen_on_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/trash_controller.dart';

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

/// Mode trash : habillage néon et commentaires acides. Déblocable en secret
/// depuis l'écran « À propos », et mémorisé entre les sessions.
final trashModeProvider =
    NotifierProvider<TrashModeController, bool>(TrashModeController.new);

/// Épithètes trash ajoutées par la table (réglages), en plus du catalogue de
/// base — pour glisser des blagues ou des références perso dans les noms tirés.
final customTrashAdjectivesProvider =
    NotifierProvider<CustomAdjectivesController, List<String>>(
        CustomAdjectivesController.new);

/// Réglage « garder l'écran allumé pendant la partie » (mémorisé, défaut oui).
final keepScreenOnEnabledProvider =
    NotifierProvider<KeepScreenOnController, bool>(
        KeepScreenOnController.new);

/// Réglage « dés dans l'appli » (icône sur le plateau, mémorisé, défaut oui).
final diceTrayEnabledProvider =
    NotifierProvider<DiceTrayController, bool>(DiceTrayController.new);

/// Tous les profils d'alias créés sur l'appareil (§ évolution « alias
/// joueur »), proposés dans la modalité de sélection plutôt que retapés, et
/// affichés dans l'écran « Alias & profils ».
final aliasProfilesProvider =
    NotifierProvider<AliasProfilesController, List<AliasProfile>>(
        AliasProfilesController.new);

/// Rang de la teinte d'accent de l'UI, tiré au hasard **à chaque ouverture** de
/// l'appli (le provider n'est créé qu'une fois par lancement). Petit détail
/// ludique et multicolore ; volontairement pas mémorisé pour changer à chaque
/// fois. C'est un *indice* et non une couleur : la palette dans laquelle on
/// pioche dépend de l'habillage (sage ou trash), les deux ayant la même taille.
final accentSeedIndexProvider = Provider<int>((ref) => Random().nextInt(1 << 20));

/// Moteur de jeu (logique pure).
final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

/// Partie active courante (null s'il n'y en a pas).
final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameState?>(GameController.new);

/// Toutes les parties terminées de l'appareil (§ écran de statistiques).
/// `autoDispose` : relu à chaque ouverture de l'écran plutôt que mis en
/// cache, pour refléter la toute dernière partie sans logique de rafraîchissement.
final finishedGamesProvider = FutureProvider.autoDispose<List<GameState>>(
  (ref) => ref.read(gameRepositoryProvider).loadFinishedGames(),
);

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
