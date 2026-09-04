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

/// Orchestrateur entre l'interface et le moteur.
///
/// Chaque commande est appliquée par le moteur puis, en cas de succès,
/// l'instantané est persisté avant que le nouvel état ne soit publié à l'UI
/// (§28.4). L'UI n'exécute jamais de logique métier elle-même.
class GameController extends AsyncNotifier<GameState?> {
  @override
  Future<GameState?> build() async {
    return ref.read(gameRepositoryProvider).loadActiveGame();
  }

  GameEngine get _engine => ref.read(gameEngineProvider);
  GameRepository get _repo => ref.read(gameRepositoryProvider);

  /// Crée une nouvelle partie vide (remplace l'éventuelle partie active).
  Future<void> newGame({GameRules rules = const GameRules()}) async {
    final previous = state.value;
    if (previous != null) {
      await _repo.deleteGame(previous.id);
    }
    final created = _engine.createGame(rules: rules);
    await _repo.saveSnapshot(created);
    state = AsyncData(created);
  }

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
        customTrashAdjectives: ref.read(customTrashAdjectivesProvider),
      ));
  Future<EngineResult> renamePlayer(String id, String name) =>
      dispatch(RenamePlayer(playerId: id, newName: name));
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
  Future<EngineResult> undo() => dispatch(const UndoLastAction());

  /// Revient à l'état juste après l'action [actionId] (écran d'historique) :
  /// annule une par une toutes les actions plus récentes, dans l'ordre
  /// inverse, en réutilisant l'annulation atomique déjà testée du moteur.
  /// Renvoie `false` sans rien modifier si l'action est introuvable ou déjà
  /// annulée.
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
}
