import 'package:equatable/equatable.dart';

/// Un alias de table mémorisé sur l'appareil, avec sa couleur perso (§
/// évolution « alias joueur »).
///
/// Indépendant d'une partie précise : c'est ce registre qui alimente la
/// modalité de sélection rapide (au moment d'assigner un alias à un joueur)
/// et l'écran « Alias & profils » (bilan par personne, renommage).
class AliasProfile extends Equatable {
  const AliasProfile({
    required this.alias,
    required this.colorArgb,
    this.applyToTile = false,
  });

  /// Toujours préfixé de `@` (ex. `@Ben`).
  final String alias;

  /// Couleur choisie par la personne pour repérer sa carte (0xAARRGGBB).
  final int colorArgb;

  /// La tuile du joueur prend-elle cette couleur (au lieu d'une couleur tirée
  /// au hasard) quand on lui donne cet alias ? Sinon, seule la pastille de
  /// l'alias est colorée. Désactivé par défaut (voir DECISIONS F-007).
  final bool applyToTile;

  AliasProfile copyWith({String? alias, int? colorArgb, bool? applyToTile}) =>
      AliasProfile(
        alias: alias ?? this.alias,
        colorArgb: colorArgb ?? this.colorArgb,
        applyToTile: applyToTile ?? this.applyToTile,
      );

  Map<String, dynamic> toJson() => {
        'alias': alias,
        'colorArgb': colorArgb,
        'applyToTile': applyToTile,
      };

  static AliasProfile fromJson(Map<String, dynamic> j) => AliasProfile(
        alias: j['alias'] as String,
        colorArgb: j['colorArgb'] as int,
        applyToTile: j['applyToTile'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [alias, colorArgb, applyToTile];
}
