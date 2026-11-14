import '../models/game_state.dart';

/// Port de persistance des parties (couche domaine).
///
/// L'implémentation concrète vit dans la couche `data`. Le domaine ne connaît
/// que ce contrat.
abstract interface class GameRepository {
  /// Enregistre (ou remplace) l'instantané d'une partie, de façon atomique.
  Future<void> saveSnapshot(GameState state);

  /// Charge la partie active la plus récente, ou `null`.
  Future<GameState?> loadActiveGame();

  /// Charge les parties terminées ou archivées, les plus récentes d'abord.
  Future<List<GameState>> loadFinishedGames();

  /// Charge une partie précise par son id.
  Future<GameState?> loadGame(String id);

  /// Supprime une partie.
  Future<void> deleteGame(String id);

  /// Supprime toutes les données locales.
  Future<void> deleteAll();
}
