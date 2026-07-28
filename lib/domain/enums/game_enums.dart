/// Énumérations du domaine (les « listes de valeurs figées » du jeu).
///
/// Une énumération = un type qui ne peut prendre qu'un ensemble fermé de valeurs.
/// Cela empêche les erreurs : un statut de partie ne peut être QUE l'une de ces
/// valeurs, jamais un texte libre.
///
/// Référence : SPECIFICATION.md §24.1, §24.8, §25.2.
library;

/// État global d'une partie. Machine à états décrite au §26.
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

/// Mode de déroulement des tours (§9).
enum TurnMode {
  /// Guidé (défaut) : un seul joueur actif à la fois, ordre imposé, manches comptées.
  guided,

  /// Libre : aucun ordre imposé, toutes les tuiles actives sont jouables.
  free,
}

/// Pas de saisie du score (§10.3). Défaut : 100.
enum ScoreStep {
  /// Multiples de 50 (option).
  fifty(50),

  /// Multiples de 100 (défaut).
  hundred(100);

  const ScoreStep(this.value);

  /// Valeur numérique du pas (50 ou 100).
  final int value;
}

/// Statut d'un gain dans la pile d'un joueur (§24.5, §13).
enum GainStatus {
  /// Gain encore présent dans le total du joueur.
  active,

  /// Gain retiré du total, mais conservé dans l'historique.
  cancelled,
}

/// Raison d'annulation d'un gain (§18.4).
enum GainCancelReason {
  /// Annulé par le troisième échec du joueur.
  thirdMiss,

  /// Annulé parce qu'un adversaire a « rencontré » le joueur.
  encounter,

  /// Annulé par l'annulation (undo) de l'action qui l'avait créé.
  undone,
}

/// Type d'une action utilisateur complète (§24.1).
enum GameActionType {
  playerAdded,
  playerRenamed,
  playerRemovedBeforeStart,
  gameStarted,
  scoreRecorded,
  passRecorded,
  overshootRecorded,
  playerLeft,
  gameFinished,
  actionUndone,
}

/// Type d'un effet élémentaire produit par une action (§24.8).
///
/// Une action (ex. « marquer +500 ») peut produire plusieurs effets
/// (créer un gain, restaurer les vies, déclencher une rencontre…). Chaque effet
/// est réversible pour permettre l'annulation atomique.
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

/// Raison d'un passage / d'une fin de tour sans gain (§25.2).
enum PassReason {
  /// Le joueur appuie volontairement sur « Passer ».
  manualPass,

  /// Le tour devient un échec car le score aurait dépassé 10 000.
  overshoot,
}
