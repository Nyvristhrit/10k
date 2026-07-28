import '../../domain/models/color_token.dart';

/// Palette des 12 couleurs de tuile (§7).
///
/// Palette « fraîche » retravaillée (teintes vives et harmonieuses, façon
/// Coolors / Tailwind), pensée pour un rendu premium en dégradé avec texte
/// blanc. `accentArgb` est une version claire de la teinte, utilisée pour le
/// halo du joueur actif. Format `0xFFRRGGBB`.
///
/// Les identifiants (`id`) restent stables pour ne pas casser les parties déjà
/// sauvegardées ; seules les valeurs de couleur ont été rafraîchies.
class ColorCatalog {
  const ColorCatalog._();

  static const int _white = 0xFFFFFFFF;
  static const int _ink = 0xFF1A1204; // texte foncé pour l'ambre

  static const List<ColorToken> all = [
    ColorToken(id: 'cobalt', backgroundArgb: 0xFF2563EB, foregroundArgb: _white, accentArgb: 0xFF60A5FA),
    ColorToken(id: 'orange', backgroundArgb: 0xFFEA580C, foregroundArgb: _white, accentArgb: 0xFFFB923C),
    ColorToken(id: 'forest', backgroundArgb: 0xFF059669, foregroundArgb: _white, accentArgb: 0xFF34D399),
    ColorToken(id: 'ruby', backgroundArgb: 0xFFE11D48, foregroundArgb: _white, accentArgb: 0xFFFB7185),
    ColorToken(id: 'purple', backgroundArgb: 0xFF7C3AED, foregroundArgb: _white, accentArgb: 0xFFA78BFA),
    ColorToken(id: 'teal', backgroundArgb: 0xFF0D9488, foregroundArgb: _white, accentArgb: 0xFF2DD4BF),
    ColorToken(id: 'raspberry', backgroundArgb: 0xFFDB2777, foregroundArgb: _white, accentArgb: 0xFFF472B6),
    ColorToken(id: 'amber', backgroundArgb: 0xFFF59E0B, foregroundArgb: _ink, accentArgb: 0xFFFCD34D),
    ColorToken(id: 'indigo', backgroundArgb: 0xFF4F46E5, foregroundArgb: _white, accentArgb: 0xFF818CF8),
    ColorToken(id: 'cyan', backgroundArgb: 0xFF0E7490, foregroundArgb: _white, accentArgb: 0xFF22D3EE),
    ColorToken(id: 'brown', backgroundArgb: 0xFFB45309, foregroundArgb: _white, accentArgb: 0xFFFBBF24),
    ColorToken(id: 'slate', backgroundArgb: 0xFF475569, foregroundArgb: _white, accentArgb: 0xFF94A3B8),
  ];

  /// Nombre de couleurs disponibles (= nombre max de joueurs).
  static int get count => all.length;

  /// Retrouve une couleur par son id (ou `null`).
  static ColorToken? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
