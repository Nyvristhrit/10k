import 'package:equatable/equatable.dart';

/// Un alias mémorisé sur l'appareil, avec sa couleur, indépendant des parties.
class AliasProfile extends Equatable {
  const AliasProfile({
    required this.alias,
    required this.colorArgb,
    this.applyToTile = false,
  });

  /// Toujours préfixé de `@`.
  final String alias;

  /// Couleur choisie par la personne pour repérer sa carte (0xAARRGGBB).
  final int colorArgb;

  /// La tuile du joueur prend-elle cette couleur ? Sinon, seule la pastille
  /// de l'alias est colorée. Désactivé par défaut.
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
