import '../enums/game_enums.dart';
import 'game_effect.dart';

/// Une action représente une intention utilisateur complète et tous ses
/// effets dérivés (§24.7).
///
/// C'est l'unité d'annulation : annuler « la dernière action » restaure
/// l'ensemble des effets qu'elle a produits.
class GameAction {
  const GameAction({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.effects,
    this.primaryPlayerId,
    this.roundNumber,
    this.attemptedScore,
    this.isUndone = false,
    this.undoneAt,
  });

  final String id;
  final GameActionType type;

  /// Joueur principalement concerné (ex. celui qui marque ou passe).
  final String? primaryPlayerId;

  final DateTime createdAt;

  /// Numéro de manche au moment de l'action (mode guidé).
  final int? roundNumber;

  /// Montant tenté, en cas de dépassement (aucun gain créé).
  final int? attemptedScore;

  /// Effets élémentaires, dans l'ordre d'application.
  final List<GameEffect> effects;

  /// L'action a-t-elle été annulée.
  final bool isUndone;

  final DateTime? undoneAt;

  GameAction copyWith({
    bool? isUndone,
    DateTime? undoneAt,
  }) {
    return GameAction(
      id: id,
      type: type,
      primaryPlayerId: primaryPlayerId,
      createdAt: createdAt,
      roundNumber: roundNumber,
      attemptedScore: attemptedScore,
      effects: effects,
      isUndone: isUndone ?? this.isUndone,
      undoneAt: undoneAt ?? this.undoneAt,
    );
  }
}
