import 'package:equatable/equatable.dart';

import '../enums/game_enums.dart';

/// Un gain : un score positif validé, ajouté au sommet de la pile d'un joueur (§13, §24.6).
///
/// Chaque gain est un objet distinct. Un gain annulé n'est jamais supprimé :
/// il passe simplement en statut `cancelled` et reste dans l'historique.
class Gain extends Equatable {
  const Gain({
    required this.id,
    required this.playerId,
    required this.amount,
    required this.createdByActionId,
    required this.createdAt,
    required this.sequence,
    this.status = GainStatus.active,
    this.cancelledByActionId,
    this.cancelReason,
    this.cancelledAt,
  });

  /// Identifiant unique du gain.
  final String id;

  /// Joueur propriétaire.
  final String playerId;

  /// Montant du gain (toujours strictement positif).
  final int amount;

  /// Action qui a créé ce gain.
  final String createdByActionId;

  /// Horodatage de création.
  final DateTime createdAt;

  /// Numéro d'ordre monotone de création (départage fiable de « dernier gain »
  /// même si deux gains partagent le même `createdAt`).
  final int sequence;

  /// Actif ou annulé.
  final GainStatus status;

  /// Action qui a annulé ce gain, le cas échéant.
  final String? cancelledByActionId;

  /// Raison de l'annulation, le cas échéant.
  final GainCancelReason? cancelReason;

  /// Horodatage d'annulation, le cas échéant.
  final DateTime? cancelledAt;

  bool get isActive => status == GainStatus.active;

  Gain copyWith({
    GainStatus? status,
    String? cancelledByActionId,
    GainCancelReason? cancelReason,
    DateTime? cancelledAt,
    bool clearCancellation = false,
  }) {
    return Gain(
      id: id,
      playerId: playerId,
      amount: amount,
      createdByActionId: createdByActionId,
      createdAt: createdAt,
      sequence: sequence,
      status: status ?? this.status,
      cancelledByActionId: clearCancellation
          ? null
          : (cancelledByActionId ?? this.cancelledByActionId),
      cancelReason:
          clearCancellation ? null : (cancelReason ?? this.cancelReason),
      cancelledAt:
          clearCancellation ? null : (cancelledAt ?? this.cancelledAt),
    );
  }

  @override
  List<Object?> get props => [
        id,
        playerId,
        amount,
        createdByActionId,
        sequence,
        status,
        cancelledByActionId,
        cancelReason,
        cancelledAt,
      ];
}
