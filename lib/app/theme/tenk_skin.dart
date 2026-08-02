import 'package:flutter/material.dart';

import '../../shared/trash/trash_taunts.dart';

/// Habillage de l'appli, transporté **dans le thème** ([ThemeExtension]).
///
/// Plutôt que de faire descendre un booléen « mode trash » d'écran en écran,
/// on l'accroche au thème : n'importe quel widget (y compris une pop-up ouverte
/// par `showDialog`) peut demander `TenkSkin.of(context)` et adapter son fond,
/// ses couleurs fluo, l'icône de ses vies ou son ton.
/// Les 6 stries arc-en-ciel du logo d'origine (et de l'icône de l'appli).
const List<Color> _classicStripes = [
  Color(0xFFE11D48), // rouge
  Color(0xFFF97316), // orange
  Color(0xFFFACC15), // jaune
  Color(0xFF22C55E), // vert
  Color(0xFF3B82F6), // bleu
  Color(0xFF8B5CF6), // violet
];

/// Le vert « déchet radioactif » qui remplit les cœurs en mode trash.
const Color _toxicGreen = Color(0xFF76FF03);

/// Les mêmes, passées au néon : le logo en négatif du mode trash.
const List<Color> _trashStripes = [
  Color(0xFFFF00A0), // magenta
  Color(0xFFFF00E5), // fuchsia
  Color(0xFF9D00FF), // violet électrique
  Color(0xFF7B00FF), // indigo fluo
  Color(0xFF00F0FF), // cyan
  Color(0xFFB4FF00), // vert acide
];

@immutable
class TenkSkin extends ThemeExtension<TenkSkin> {
  const TenkSkin({
    required this.trash,
    required this.backgroundGradient,
    required this.titleStripes,
    required this.neon,
    required this.neonAlt,
    required this.lifeIcon,
    required this.lifeIconOutline,
    required this.lifeColor,
    required this.fallingEmojis,
    required this.corner,
  });

  /// Le mode trash est-il actif ? Seul drapeau à consulter pour changer de ton.
  final bool trash;

  /// Dégradé de fond général (voir `AppBackground`).
  final List<Color> backgroundGradient;

  /// Les 6 couleurs des stries du logo « 10K » de l'accueil.
  final List<Color> titleStripes;

  /// Couleurs vives de l'habillage (halos, bandeaux, titres).
  final Color neon;
  final Color neonAlt;

  /// Icônes des jauges de vie : plein / vide.
  final IconData lifeIcon;
  final IconData lifeIconOutline;

  /// Couleur qui remplit le cœur : rouge sang à l'origine, vert toxique sous
  /// néon (le même cœur, mais rempli d'autre chose).
  final Color lifeColor;

  /// Emojis qui tombent en fond d'accueil.
  final List<String> fallingEmojis;

  /// Arrondi de base des boutons et des cartes.
  ///
  /// Volontairement **identique dans tous les habillages** : le mode trash
  /// change les couleurs et le ton, pas la direction artistique. Des angles
  /// durs à côté de blocs arrondis donnaient un ensemble incohérent.
  final double corner;

  /// L'habillage courant. Repli sur le skin sage si le thème n'en porte pas
  /// (cas d'un widget testé isolément).
  static TenkSkin of(BuildContext context) =>
      Theme.of(context).extension<TenkSkin>() ?? classic;

  /// Habillage d'origine : arc-en-ciel, cœurs rouges, ton bienveillant.
  static const TenkSkin classic = TenkSkin(
    trash: false,
    backgroundGradient: [
      Color(0xFF201F2B),
      Color(0xFF141319),
      Color(0xFF0B0A0F),
    ],
    titleStripes: _classicStripes,
    neon: Color(0xFF6366F1),
    neonAlt: Color(0xFF8B5CF6),
    lifeIcon: Icons.favorite,
    lifeIconOutline: Icons.favorite_border,
    lifeColor: Color(0xFFFF3B57),
    fallingEmojis: ['🎲'],
    corner: 18,
  );

  /// Variante claire du skin d'origine (seul le fond change).
  static const TenkSkin classicLight = TenkSkin(
    trash: false,
    backgroundGradient: [
      Color(0xFFFBFAFF),
      Color(0xFFF1F0F9),
      Color(0xFFE7E5F2),
    ],
    titleStripes: _classicStripes,
    neon: Color(0xFF6366F1),
    neonAlt: Color(0xFF8B5CF6),
    lifeIcon: Icons.favorite,
    lifeIconOutline: Icons.favorite_border,
    lifeColor: Color(0xFFFF3B57),
    fallingEmojis: ['🎲'],
    corner: 18,
  );

  /// Habillage trash « nuit » : néon sur noir violacé, jauges en flammes.
  static const TenkSkin trashDark = TenkSkin(
    trash: true,
    backgroundGradient: [
      Color(0xFF2B0140),
      Color(0xFF120020),
      Color(0xFF04000A),
    ],
    titleStripes: _trashStripes,
    neon: Color(0xFFFF00A0),
    neonAlt: Color(0xFF00F0FF),
    lifeIcon: Icons.favorite,
    lifeIconOutline: Icons.favorite_border,
    lifeColor: _toxicGreen,
    fallingEmojis: Taunts.fallingEmojis,
    corner: 18,
  );

  /// Habillage trash « jour » : le même en négatif, blanc acide.
  static const TenkSkin trashLight = TenkSkin(
    trash: true,
    backgroundGradient: [
      Color(0xFFFFFFFF),
      Color(0xFFFFE6F8),
      Color(0xFFEBD4FF),
    ],
    titleStripes: _trashStripes,
    neon: Color(0xFFD6008A),
    neonAlt: Color(0xFF00B4C4),
    lifeIcon: Icons.favorite,
    lifeIconOutline: Icons.favorite_border,
    lifeColor: _toxicGreen,
    fallingEmojis: Taunts.fallingEmojis,
    corner: 18,
  );

  @override
  TenkSkin copyWith({
    bool? trash,
    List<Color>? backgroundGradient,
    List<Color>? titleStripes,
    Color? neon,
    Color? neonAlt,
    IconData? lifeIcon,
    IconData? lifeIconOutline,
    Color? lifeColor,
    List<String>? fallingEmojis,
    double? corner,
  }) {
    return TenkSkin(
      trash: trash ?? this.trash,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      titleStripes: titleStripes ?? this.titleStripes,
      neon: neon ?? this.neon,
      neonAlt: neonAlt ?? this.neonAlt,
      lifeIcon: lifeIcon ?? this.lifeIcon,
      lifeIconOutline: lifeIconOutline ?? this.lifeIconOutline,
      lifeColor: lifeColor ?? this.lifeColor,
      fallingEmojis: fallingEmojis ?? this.fallingEmojis,
      corner: corner ?? this.corner,
    );
  }

  /// Passer du skin sage au skin trash est un basculement franc, pas un fondu :
  /// on bascule à mi-course plutôt que d'interpoler des identités visuelles qui
  /// n'ont rien à voir (les couleurs intermédiaires seraient boueuses).
  @override
  TenkSkin lerp(covariant TenkSkin? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
