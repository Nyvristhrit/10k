/// Violations de règles métier renvoyées par le moteur (§25.3).
///
/// Le moteur ne lève jamais d'exception pour une erreur utilisateur normale :
/// il renvoie un `Failure(GameRuleViolation)`.
enum GameRuleViolationCode {
  notEnoughPlayers,
  maximumPlayersReached,
  gameAlreadyStarted,
  gameNotStarted,
  gameAlreadyFinished,
  playerNotFound,
  playerHasLeft,
  playerNotAllowedToPlay,
  playerAlreadyPlayedThisRound,
  invalidScoreStep,
  scoreMustBePositive,
  entryMinimumNotReached,
  confirmationRequiredForOvershoot,
  confirmationRequiredForThirdMiss,
  noActionToUndo,

  // Violations complémentaires utiles à la préparation.
  invalidPlayerName,
  noAvatarAvailable,
  noColorAvailable,
}

/// Une violation concrète : un code + un message lisible facultatif.
class GameRuleViolation {
  const GameRuleViolation(this.code, [this.message]);

  final GameRuleViolationCode code;
  final String? message;

  @override
  String toString() =>
      'GameRuleViolation(${code.name}${message == null ? '' : ': $message'})';
}
