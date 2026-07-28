import 'package:equatable/equatable.dart';

import 'gain.dart';

/// Un joueur de la partie (§24.5).
///
/// Choix de conception (A-003, DECISIONS.md) : la pile de gains est **portée
/// directement par le joueur** dans la couche domaine. Le score n'est jamais
/// une valeur mutée à part : c'est toujours la somme des gains actifs
/// (invariant 5). La couche persistance normalisera ensuite en tables.
class Player extends Equatable {
  const Player({
    required this.id,
    required this.avatarId,
    required this.colorId,
    required this.displayName,
    required this.seatIndex,
    required this.createdAt,
    this.lives = 3,
    this.hasEnteredGame = false,
    this.hasLeftGame = false,
    this.gains = const [],
  });

  final String id;
  final String avatarId;
  final String colorId;

  /// Nom affiché (nom d'animal par défaut, ou nom personnalisé).
  final String displayName;

  /// Position autour de la table (ordre d'ajout).
  final int seatIndex;

  final DateTime createdAt;

  /// Cœurs restants.
  final int lives;

  /// Le joueur a-t-il déjà « sorti » (premier score valide). Ne redevient
  /// jamais `false` pendant la partie (§11.3).
  final bool hasEnteredGame;

  /// Le joueur a-t-il quitté la partie (§17).
  final bool hasLeftGame;

  /// Pile de gains du joueur (actifs et annulés), tous confondus.
  final List<Gain> gains;

  /// Gains encore actifs, du plus ancien au plus récent (ordre de la pile).
  List<Gain> get activeGains {
    final list = gains.where((g) => g.isActive).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return List.unmodifiable(list);
  }

  /// Alias explicite : la pile des gains actifs (bas → sommet).
  List<Gain> get activeGainStack => activeGains;

  /// Score = somme des montants des gains actifs (invariant 5).
  int get score => activeGains.fold(0, (sum, g) => sum + g.amount);

  /// Le gain actif le plus récent (sommet de la pile), ou `null`.
  Gain? get lastActiveGain {
    final active = activeGains;
    return active.isEmpty ? null : active.last;
  }

  bool get hasActiveGain => activeGains.isNotEmpty;

  /// Un joueur qui a quitté ne peut plus agir.
  bool get isEligibleToPlay => !hasLeftGame;

  Player copyWith({
    String? displayName,
    int? seatIndex,
    int? lives,
    bool? hasEnteredGame,
    bool? hasLeftGame,
    List<Gain>? gains,
  }) {
    return Player(
      id: id,
      avatarId: avatarId,
      colorId: colorId,
      displayName: displayName ?? this.displayName,
      seatIndex: seatIndex ?? this.seatIndex,
      createdAt: createdAt,
      lives: lives ?? this.lives,
      hasEnteredGame: hasEnteredGame ?? this.hasEnteredGame,
      hasLeftGame: hasLeftGame ?? this.hasLeftGame,
      gains: gains ?? this.gains,
    );
  }

  @override
  List<Object?> get props => [
        id,
        avatarId,
        colorId,
        displayName,
        seatIndex,
        lives,
        hasEnteredGame,
        hasLeftGame,
        gains,
      ];
}
