import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/commands/game_command.dart';
import '../../domain/enums/game_enums.dart';
import '../../domain/errors/game_rule_violation.dart';
import '../../domain/models/game_rules.dart';
import '../../domain/models/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/game_engine.dart';
import '../../domain/services/game_transition.dart';
import '../providers/app_providers.dart';

/// Fait le lien entre l'interface et le moteur : chaque commande réussie est
/// sauvegardée avant que le nouvel état soit publié.
class GameController extends AsyncNotifier<GameState?> {
  @override
  Future<GameState?> build() async {
    return ref.read(gameRepositoryProvider).loadActiveGame();
  }

  GameEngine get _engine => ref.read(gameEngineProvider);
  GameRepository get _repo => ref.read(gameRepositoryProvider);

  /// Crée une nouvelle partie vide. L'ancienne est effacée si elle n'était
  /// pas terminée, sinon conservée pour les statistiques.
  Future<void> newGame({GameRules rules = const GameRules()}) async {
    final previous = state.value;
    if (previous != null && !_isTerminal(previous.status)) {
      await _repo.deleteGame(previous.id);
    }
    final created = _engine.createGame(rules: rules);
    await _repo.saveSnapshot(created);
    state = AsyncData(created);
  }

  bool _isTerminal(GameStatus status) =>
      status == GameStatus.finished || status == GameStatus.archived;

  /// Applique une commande. Renvoie le résultat (succès ou violation) pour que
  /// l'écran puisse afficher un message ou une confirmation.
  Future<EngineResult> dispatch(GameCommand command) async {
    final current = state.value;
    if (current == null) {
      // Ne devrait pas arriver depuis l'UI (aucune partie chargée).
      return const Failure(
          GameRuleViolation(GameRuleViolationCode.gameNotStarted));
    }
    final result = _engine.apply(current, command);
    if (result is Success) {
      final next = result.transition.nextState;
      await _repo.saveSnapshot(next);
      state = AsyncData(next);
    }
    return result;
  }

  // Raccourcis de préparation.
  Future<EngineResult> addPlayer() => dispatch(AddPlayer(
        trashNames: ref.read(trashModeProvider),
        trashAdjectives: ref.read(trashAdjectivesProvider),
      ));
  Future<EngineResult> renamePlayer(String id, String name) =>
      dispatch(RenamePlayer(playerId: id, newName: name));
  Future<EngineResult> setPlayerAlias(String id, String? alias,
          {String? preferredColorId}) =>
      dispatch(SetPlayerAlias(
          playerId: id, alias: alias, preferredColorId: preferredColorId));
  Future<EngineResult> removePlayer(String id) =>
      dispatch(RemovePlayerBeforeStart(playerId: id));
  Future<EngineResult> updateRules(GameRules rules) =>
      dispatch(UpdateRules(rules: rules));
  Future<EngineResult> startGame() => dispatch(const StartGame());

  // Raccourcis en partie.
  Future<EngineResult> selectPlayer(String id) =>
      dispatch(SelectGuidedPlayer(playerId: id));
  Future<EngineResult> recordScore(String id, int amount,
          {bool confirmed = false}) =>
      dispatch(RecordScore(playerId: id, amount: amount, confirmed: confirmed));
  Future<EngineResult> passTurn(String id,
          {PassReason reason = PassReason.manualPass, bool confirmed = false}) =>
      dispatch(PassTurn(playerId: id, reason: reason, confirmed: confirmed));
  Future<EngineResult> leaveGame(String id) =>
      dispatch(LeaveGame(playerId: id));
  Future<EngineResult> movePlayer(String id, {required String toSeatOf}) =>
      dispatch(MovePlayer(playerId: id, targetPlayerId: toSeatOf));
  Future<EngineResult> undo() => dispatch(const UndoLastAction());

  /// Revient à l'état juste après [actionId] en annulant une à une les actions
  /// plus récentes. Renvoie `false` si l'action est introuvable ou annulée.
  Future<bool> revertToAction(String actionId) async {
    var current = state.value;
    if (current == null) return false;
    if (!current.actions.any((a) => a.id == actionId && !a.isUndone)) {
      return false;
    }
    while (current!.lastActiveAction?.id != actionId) {
      final result = _engine.apply(current, const UndoLastAction());
      if (result is! Success) return false;
      current = result.transition.nextState;
    }
    await _repo.saveSnapshot(current);
    state = AsyncData(current);
    return true;
  }

  /// Renomme un alias dans la partie en cours, sans passer par le moteur (ce
  /// n'est pas un coup de jeu). Utilisé par [AliasProfilesController.rename].
  Future<void> renameAliasInPlace(String oldAlias, String newAlias) async {
    final current = state.value;
    if (current == null) return;
    final players = current.players
        .map((p) => p.alias == oldAlias ? p.copyWith(alias: newAlias) : p)
        .toList();
    final next = current.copyWith(players: players);
    await _repo.saveSnapshot(next);
    state = AsyncData(next);
  }
}
