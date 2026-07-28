import 'package:equatable/equatable.dart';

/// État d'une manche en mode guidé ordinaire (§24.9, §9.1).
///
/// Une manche = un cycle où chaque joueur actif doit jouer une fois.
class RoundState extends Equatable {
  const RoundState({
    required this.roundNumber,
    this.currentPlayerId,
    this.pendingPlayerIds = const [],
    this.completedPlayerIds = const [],
  });

  final int roundNumber;

  /// Joueur actif actuel.
  final String? currentPlayerId;

  /// Joueurs qui n'ont pas encore joué dans cette manche.
  final List<String> pendingPlayerIds;

  /// Joueurs qui ont déjà joué dans cette manche.
  final List<String> completedPlayerIds;

  RoundState copyWith({
    int? roundNumber,
    String? currentPlayerId,
    bool clearCurrentPlayer = false,
    List<String>? pendingPlayerIds,
    List<String>? completedPlayerIds,
  }) {
    return RoundState(
      roundNumber: roundNumber ?? this.roundNumber,
      currentPlayerId:
          clearCurrentPlayer ? null : (currentPlayerId ?? this.currentPlayerId),
      pendingPlayerIds: pendingPlayerIds ?? this.pendingPlayerIds,
      completedPlayerIds: completedPlayerIds ?? this.completedPlayerIds,
    );
  }

  @override
  List<Object?> get props => [
        roundNumber,
        currentPlayerId,
        pendingPlayerIds,
        completedPlayerIds,
      ];
}
