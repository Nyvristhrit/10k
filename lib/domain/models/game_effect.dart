import '../enums/game_enums.dart';

/// Un effet élémentaire produit par une action (§24.8).
///
/// Une action utilisateur (ex. « marquer +500 ») se décompose en plusieurs
/// effets atomiques. Chaque effet mémorise `previousValue`/`nextValue` pour
/// permettre l'annulation intégrale (A-002 dans DECISIONS.md).
class GameEffect {
  const GameEffect({
    required this.id,
    required this.type,
    this.targetPlayerId,
    this.gainId,
    this.delta,
    this.previousValue,
    this.nextValue,
    this.metadata = const {},
  });

  final String id;
  final GameEffectType type;

  /// Joueur concerné par l'effet, le cas échéant.
  final String? targetPlayerId;

  /// Gain concerné, le cas échéant.
  final String? gainId;

  /// Variation numérique, le cas échéant (ex. montant d'un gain, +/- de vie).
  final int? delta;

  /// Valeur avant l'effet (type compatible JSON : int, String, bool, List…).
  final Object? previousValue;

  /// Valeur après l'effet.
  final Object? nextValue;

  /// Métadonnées libres et sérialisables.
  final Map<String, Object?> metadata;
}
