import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_state.dart';
import '../../domain/repositories/game_repository.dart';

/// Stockage en mémoire (tests, prototypage). Non persistant.
class InMemoryGameRepository implements GameRepository {
  final Map<String, GameState> _games = {};

  static const _activeStatuses = {
    GameStatus.setup,
    GameStatus.inProgress,
    GameStatus.finalChance,
  };

  @override
  Future<void> saveSnapshot(GameState state) async {
    _games[state.id] = state;
  }

  @override
  Future<GameState?> loadActiveGame() async {
    final active = _games.values
        .where((g) => _activeStatuses.contains(g.status))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return active.isEmpty ? null : active.first;
  }

  @override
  Future<List<GameState>> loadFinishedGames() async {
    final finished = _games.values
        .where((g) => !_activeStatuses.contains(g.status))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return finished;
  }

  @override
  Future<GameState?> loadGame(String id) async => _games[id];

  @override
  Future<void> deleteGame(String id) async {
    _games.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    _games.clear();
  }
}
