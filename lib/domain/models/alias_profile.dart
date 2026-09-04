import 'package:equatable/equatable.dart';

/// Un alias de table mémorisé sur l'appareil, avec sa couleur perso (§
/// évolution « alias joueur »).
///
/// Indépendant d'une partie précise : c'est ce registre qui alimente la
/// modalité de sélection rapide (au moment d'assigner un alias à un joueur)
/// et l'écran « Alias & profils » (bilan par personne, renommage).
class AliasProfile extends Equatable {
  const AliasProfile({required this.alias, required this.colorArgb});

  /// Toujours préfixé de `@` (ex. `@Ben`).
  final String alias;

  /// Couleur choisie par la personne pour repérer sa carte (0xAARRGGBB).
  final int colorArgb;

  AliasProfile copyWith({String? alias, int? colorArgb}) => AliasProfile(
        alias: alias ?? this.alias,
        colorArgb: colorArgb ?? this.colorArgb,
      );

  Map<String, dynamic> toJson() => {'alias': alias, 'colorArgb': colorArgb};

  static AliasProfile fromJson(Map<String, dynamic> j) => AliasProfile(
        alias: j['alias'] as String,
        colorArgb: j['colorArgb'] as int,
      );

  @override
  List<Object?> get props => [alias, colorArgb];
}
