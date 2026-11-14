/// Violations de règles renvoyées par le moteur dans un `Failure`, plutôt
/// qu'une exception.
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

  // Préparation.
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
