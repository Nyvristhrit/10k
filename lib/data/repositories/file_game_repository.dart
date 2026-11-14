import 'dart:convert';
import 'dart:io';

import '../../domain/enums/game_enums.dart';
import '../../domain/models/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../serialization/game_serialization.dart';

/// Stockage des parties en JSON, un fichier `<rootDir>/games/<id>.json` par
/// partie.
///
/// Écriture atomique (fichier `.tmp` puis renommage) ; si l'appli est coupée
/// pendant l'écriture, le `.tmp` sert de secours au chargement.
class FileGameRepository implements GameRepository {
  FileGameRepository(this.rootDir);

  /// Dossier racine (sur l'appareil : dossier de documents de l'application).
  final Directory rootDir;

  static const _activeStatuses = {
    GameStatus.setup,
    GameStatus.inProgress,
    GameStatus.finalChance,
  };

  Directory get _gamesDir => Directory('${rootDir.path}/games');
  File _fileFor(String id) => File('${_gamesDir.path}/$id.json');
  File _tmpFor(String id) => File('${_gamesDir.path}/$id.json.tmp');

  @override
  Future<void> saveSnapshot(GameState state) async {
    await _gamesDir.create(recursive: true);
    final tmp = _tmpFor(state.id);
    final target = _fileFor(state.id);
    final text = jsonEncode(GameSerialization.toJson(state));

    await tmp.writeAsString(text, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await tmp.rename(target.path);
  }

  @override
  Future<GameState?> loadActiveGame() async {
    final games = await _loadAll();
    final active = games.where((g) => _activeStatuses.contains(g.status)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return active.isEmpty ? null : active.first;
  }

  @override
  Future<List<GameState>> loadFinishedGames() async {
    final games = await _loadAll();
    final finished = games
        .where((g) => !_activeStatuses.contains(g.status))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return finished;
  }

  @override
  Future<GameState?> loadGame(String id) async {
    final file = _fileFor(id);
    final tmp = _tmpFor(id);
    if (await file.exists()) return _read(file);
    if (await tmp.exists()) return _read(tmp); // secours après arrêt brutal
    return null;
  }

  @override
  Future<void> deleteGame(String id) async {
    for (final f in [_fileFor(id), _tmpFor(id)]) {
      if (await f.exists()) await f.delete();
    }
  }

  @override
  Future<void> deleteAll() async {
    if (await _gamesDir.exists()) {
      await _gamesDir.delete(recursive: true);
    }
  }

  Future<List<GameState>> _loadAll() async {
    if (!await _gamesDir.exists()) return [];
    final games = <GameState>[];
    final seenIds = <String>{};
    await for (final entity in _gamesDir.list()) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.json')) continue;
      final state = await _read(entity);
      if (state != null && seenIds.add(state.id)) games.add(state);
    }
    return games;
  }

  Future<GameState?> _read(File file) async {
    try {
      final text = await file.readAsString();
      final json = jsonDecode(text) as Map<String, dynamic>;
      return GameSerialization.fromJson(json);
    } catch (_) {
      // Fichier illisible/corrompu : on l'ignore plutôt que de planter.
      return null;
    }
  }
}
