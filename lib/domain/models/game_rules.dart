import 'package:equatable/equatable.dart';

import '../enums/game_enums.dart';

/// Règles d'une partie. Toutes sont stockées, même celles qui ne sont pas
/// encore configurables.
class GameRules extends Equatable {
  const GameRules({
    this.targetScore = 10000,
    this.exactTargetRequired = true,
    this.scoreStep = 100,
    this.minimumEntryScore = 300,
    this.maxLives = 3,
    this.turnMode = TurnMode.guided,
    this.confirmThirdMiss = true,
    this.encounterEnabled = true,
    this.encounterAlertsEnabled = true,
    this.encounterAffectsAllMatches = true,
    this.encounterChainsEnabled = true,
    this.overshootCountsAsMiss = true,
    this.finalChanceEnabled = true,
  });

  /// Score à atteindre pour gagner. Défaut : 10 000.
  final int targetScore;

  /// La victoire nécessite d'atteindre exactement `targetScore`.
  final bool exactTargetRequired;

  /// Pas de saisie du score : 100 (défaut) ou 50 (option).
  final int scoreStep;

  /// Minimum pour « sortir » (premier score valide). 0 = aucune sortie.
  final int minimumEntryScore;

  /// Nombre de cœurs. Défaut : 3.
  final int maxLives;

  /// Mode de tours (guidé par défaut).
  final TurnMode turnMode;

  /// Confirmer avant l'annulation du dernier gain au troisième échec.
  final bool confirmThirdMiss;

  /// La règle de rencontre est-elle active ?
  final bool encounterEnabled;

  /// Afficher une alerte à valider lors d'une rencontre. Activé par défaut.
  final bool encounterAlertsEnabled;

  /// Une rencontre touche-t-elle toutes les victimes à égalité (ou une seule) ?
  final bool encounterAffectsAllMatches;

  /// Rencontres en cascade (une victime qui redescend peut en percuter une
  /// autre). Activé par défaut.
  final bool encounterChainsEnabled;

  /// Un dépassement de la cible compte comme un échec.
  final bool overshootCountsAsMiss;

  /// La phase de dernière chance est-elle active ?
  final bool finalChanceEnabled;

  GameRules copyWith({
    int? targetScore,
    bool? exactTargetRequired,
    int? scoreStep,
    int? minimumEntryScore,
    int? maxLives,
    TurnMode? turnMode,
    bool? confirmThirdMiss,
    bool? encounterEnabled,
    bool? encounterAlertsEnabled,
    bool? encounterAffectsAllMatches,
    bool? encounterChainsEnabled,
    bool? overshootCountsAsMiss,
    bool? finalChanceEnabled,
  }) {
    return GameRules(
      targetScore: targetScore ?? this.targetScore,
      exactTargetRequired: exactTargetRequired ?? this.exactTargetRequired,
      scoreStep: scoreStep ?? this.scoreStep,
      minimumEntryScore: minimumEntryScore ?? this.minimumEntryScore,
      maxLives: maxLives ?? this.maxLives,
      turnMode: turnMode ?? this.turnMode,
      confirmThirdMiss: confirmThirdMiss ?? this.confirmThirdMiss,
      encounterEnabled: encounterEnabled ?? this.encounterEnabled,
      encounterAlertsEnabled:
          encounterAlertsEnabled ?? this.encounterAlertsEnabled,
      encounterAffectsAllMatches:
          encounterAffectsAllMatches ?? this.encounterAffectsAllMatches,
      encounterChainsEnabled:
          encounterChainsEnabled ?? this.encounterChainsEnabled,
      overshootCountsAsMiss:
          overshootCountsAsMiss ?? this.overshootCountsAsMiss,
      finalChanceEnabled: finalChanceEnabled ?? this.finalChanceEnabled,
    );
  }

  @override
  List<Object?> get props => [
        targetScore,
        exactTargetRequired,
        scoreStep,
        minimumEntryScore,
        maxLives,
        turnMode,
        confirmThirdMiss,
        encounterEnabled,
        encounterAlertsEnabled,
        encounterAffectsAllMatches,
        encounterChainsEnabled,
        overshootCountsAsMiss,
        finalChanceEnabled,
      ];
}
