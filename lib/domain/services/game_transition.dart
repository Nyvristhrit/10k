import '../errors/game_rule_violation.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';

/// Résultat structuré d'une action réussie (§25).
///
/// Le moteur ne montre aucune modale : il renvoie ces données que l'interface
/// transforme en confirmations ou animations.
class GameTransition {
  const GameTransition({
    required this.previousState,
    required this.nextState,
    this.action,
    this.userMessages = const [],
  });

  final GameState previousState;
  final GameState nextState;

  /// Action créée par la commande (absente pour une simple sélection).
  final GameAction? action;

  /// Messages destinés à l'utilisateur (informations non bloquantes).
  final List<String> userMessages;
}

/// Résultat d'un appel au moteur : succès ou violation de règle.
sealed class EngineResult {
  const EngineResult();

  bool get isSuccess => this is Success;
  bool get isFailure => this is Failure;
}

class Success extends EngineResult {
  const Success(this.transition);
  final GameTransition transition;
}

class Failure extends EngineResult {
  const Failure(this.violation);
  final GameRuleViolation violation;
}
