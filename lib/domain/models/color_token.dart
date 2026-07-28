import 'package:equatable/equatable.dart';

/// Une couleur de tuile attribuable à un joueur (§7, §24.3).
///
/// Les couleurs sont stockées en ARGB (entier 0xAARRGGBB) pour rester
/// indépendantes de Flutter dans la couche domaine.
class ColorToken extends Equatable {
  const ColorToken({
    required this.id,
    required this.backgroundArgb,
    required this.foregroundArgb,
    this.accentArgb,
  });

  /// Identifiant technique unique et stable (ex. `cobalt`).
  final String id;

  /// Couleur de fond de la tuile (0xAARRGGBB).
  final int backgroundArgb;

  /// Couleur du texte recommandée pour un contraste suffisant.
  final int foregroundArgb;

  /// Couleur d'accent facultative (halo, bordure…).
  final int? accentArgb;

  @override
  List<Object?> get props => [id];
}
