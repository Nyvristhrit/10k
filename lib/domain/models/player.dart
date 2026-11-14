import 'package:equatable/equatable.dart';

import 'gain.dart';

/// Un joueur de la partie. Il porte sa pile de gains ; son score est toujours
/// la somme des gains actifs, jamais stocké à part.
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
    this.alias,
  });

  final String id;
  final String avatarId;
  final String colorId;

  /// Nom affiché (nom d'animal par défaut, ou nom personnalisé).
  final String displayName;

  /// Alias facultatif, préfixé de `@`. Stable d'une partie à l'autre, il sert
  /// d'identité pour les statistiques.
  final String? alias;

  /// Position autour de la table (ordre d'ajout).
  final int seatIndex;

  final DateTime createdAt;

  /// Cœurs restants.
  final int lives;

  /// Le joueur a-t-il déjà « sorti » (premier score valide) ? Ne redevient
  /// jamais `false`.
  final bool hasEnteredGame;

  /// Le joueur a-t-il quitté la partie ?
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

  /// Score = somme des gains actifs.
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
    String? colorId,
    String? displayName,
    int? seatIndex,
    int? lives,
    bool? hasEnteredGame,
    bool? hasLeftGame,
    List<Gain>? gains,
    String? alias,
    bool clearAlias = false,
  }) {
    return Player(
      id: id,
      avatarId: avatarId,
      colorId: colorId ?? this.colorId,
      displayName: displayName ?? this.displayName,
      seatIndex: seatIndex ?? this.seatIndex,
      createdAt: createdAt,
      lives: lives ?? this.lives,
      hasEnteredGame: hasEnteredGame ?? this.hasEnteredGame,
      hasLeftGame: hasLeftGame ?? this.hasLeftGame,
      gains: gains ?? this.gains,
      alias: clearAlias ? null : (alias ?? this.alias),
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
        alias,
      ];
}
