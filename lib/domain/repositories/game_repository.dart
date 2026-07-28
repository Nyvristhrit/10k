import '../models/game_state.dart';

/// Port de persistance des parties (couche domaine).
///
/// L'implémentation concrète vit dans la couche `data`. Le domaine ne connaît
/// que ce contrat.
abstract interface class GameRepository {
  /// Enregistre (ou remplace) l'instantané courant d'une partie, de façon
  /// atomique (§27.3).
  Future<void> saveSnapshot(GameState state);

  /// Charge la partie active (en préparation ou en cours), la plus récente, ou
  /// `null` s'il n'y en a pas (§20.1 : une seule partie active à la fois).
  Future<GameState?> loadActiveGame();

  /// Charge les parties terminées ou archivées, les plus récentes d'abord.
  Future<List<GameState>> loadFinishedGames();

  /// Charge une partie précise par son id.
  Future<GameState?> loadGame(String id);

  /// Supprime une partie.
  Future<void> deleteGame(String id);

  /// Supprime toutes les données locales (§37).
  Future<void> deleteAll();
}
