import 'package:equatable/equatable.dart';

/// État de la phase de dernière chance (§24.10, §16).
///
/// Déclenchée quand un joueur atteint exactement la cible. Tous les autres
/// joueurs actifs disposent d'un unique dernier tour.
class FinalChanceState extends Equatable {
  const FinalChanceState({
    required this.triggerActionId,
    required this.initialCandidatePlayerId,
    required this.currentCandidatePlayerId,
    this.pendingPlayerIds = const [],
    this.completedPlayerIds = const [],
    this.currentPlayerId,
  });

  /// Action qui a déclenché la phase.
  final String triggerActionId;

  /// Premier joueur à avoir atteint la cible.
  final String initialCandidatePlayerId;

  /// Candidat courant à la victoire (peut changer via une rencontre à la cible).
  final String currentCandidatePlayerId;

  /// Joueurs qui n'ont pas encore joué leur dernière chance.
  final List<String> pendingPlayerIds;

  /// Joueurs ayant consommé leur dernière chance.
  final List<String> completedPlayerIds;

  /// Joueur actif dans la phase (mode guidé).
  final String? currentPlayerId;

  FinalChanceState copyWith({
    String? currentCandidatePlayerId,
    List<String>? pendingPlayerIds,
    List<String>? completedPlayerIds,
    String? currentPlayerId,
    bool clearCurrentPlayer = false,
  }) {
    return FinalChanceState(
      triggerActionId: triggerActionId,
      initialCandidatePlayerId: initialCandidatePlayerId,
      currentCandidatePlayerId:
          currentCandidatePlayerId ?? this.currentCandidatePlayerId,
      pendingPlayerIds: pendingPlayerIds ?? this.pendingPlayerIds,
      completedPlayerIds: completedPlayerIds ?? this.completedPlayerIds,
      currentPlayerId:
          clearCurrentPlayer ? null : (currentPlayerId ?? this.currentPlayerId),
    );
  }

  @override
  List<Object?> get props => [
        triggerActionId,
        initialCandidatePlayerId,
        currentCandidatePlayerId,
        pendingPlayerIds,
        completedPlayerIds,
        currentPlayerId,
      ];
}
