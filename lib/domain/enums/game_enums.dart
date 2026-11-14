/// Énumérations du domaine.
library;

/// État global d'une partie.
enum GameStatus {
  /// Préparation : on ajoute/renomme/supprime les joueurs, on règle les options.
  setup,

  /// Partie en cours (mode guidé ou libre).
  inProgress,

  /// Dernière chance : un joueur a atteint 10 000, les autres ont un ultime tour.
  finalChance,

  /// Partie terminée : un gagnant est désigné.
  finished,

  /// Partie archivée par l'utilisateur.
  archived,
}

/// Mode de déroulement des tours.
enum TurnMode {
  /// Guidé (défaut) : un seul joueur actif à la fois, ordre imposé, manches comptées.
  guided,

  /// Libre : aucun ordre imposé, toutes les tuiles actives sont jouables.
  free,
}

/// Pas de saisie du score. Défaut : 100.
enum ScoreStep {
  /// Multiples de 50 (option).
  fifty(50),

  /// Multiples de 100 (défaut).
  hundred(100);

  const ScoreStep(this.value);

  /// Valeur numérique du pas (50 ou 100).
  final int value;
}

/// Statut d'un gain dans la pile d'un joueur.
enum GainStatus {
  /// Gain encore présent dans le total du joueur.
  active,

  /// Gain retiré du total, mais conservé dans l'historique.
  cancelled,
}

/// Raison d'annulation d'un gain.
enum GainCancelReason {
  /// Annulé par le troisième échec du joueur.
  thirdMiss,

  /// Annulé parce qu'un adversaire a « rencontré » le joueur.
  encounter,

  /// Annulé par l'annulation (undo) de l'action qui l'avait créé.
  undone,
}

/// Type d'une action utilisateur.
enum GameActionType {
  playerAdded,
  playerRenamed,
  playerAliasSet,
  playerRemovedBeforeStart,
  gameStarted,
  scoreRecorded,
  passRecorded,
  overshootRecorded,
  playerLeft,
  gameFinished,
  actionUndone,
}

/// Type d'un effet élémentaire produit par une action. Une action peut en
/// produire plusieurs ; chacun est réversible pour l'annulation.
enum GameEffectType {
  scoreGainCreated,
  lifeLost,
  livesRestored,
  playerEnteredGame,
  gainCancelledByThirdMiss,
  gainCancelledByEncounter,
  encounterTriggered,
  roundAdvanced,
  currentPlayerChanged,
  finalChanceStarted,
  finalChanceConsumed,
  winnerCandidateChanged,
  playerMarkedAsLeft,
  gameStatusChanged,
}

/// Raison d'une fin de tour sans gain.
enum PassReason {
  /// Le joueur appuie volontairement sur « Passer ».
  manualPass,

  /// Le tour devient un échec car le score aurait dépassé 10 000.
  overshoot,
}
