import '../../domain/models/color_token.dart';

/// Palette des 12 couleurs de tuile (format `0xFFRRGGBB`). `accentArgb` est
/// une version claire, pour le halo du joueur actif.
///
/// Les `id` sont enregistrés dans les parties : ne pas les renommer.
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

  /// La même palette en néon, pour le mode trash. Mêmes `id`, chaque teinte
  /// garde sa famille.
  static const List<ColorToken> toxic = [
    ColorToken(id: 'cobalt', backgroundArgb: 0xFF1B4DFF, foregroundArgb: _white, accentArgb: 0xFF7BA0FF),
    ColorToken(id: 'orange', backgroundArgb: 0xFFFF5A00, foregroundArgb: _white, accentArgb: 0xFFFFA13D),
    ColorToken(id: 'forest', backgroundArgb: 0xFF00C24A, foregroundArgb: _white, accentArgb: 0xFF76FF03),
    ColorToken(id: 'ruby', backgroundArgb: 0xFFFF0044, foregroundArgb: _white, accentArgb: 0xFFFF6B8E),
    ColorToken(id: 'purple', backgroundArgb: 0xFF8A00FF, foregroundArgb: _white, accentArgb: 0xFFC77BFF),
    ColorToken(id: 'teal', backgroundArgb: 0xFF00C2B2, foregroundArgb: _white, accentArgb: 0xFF3DFFEB),
    ColorToken(id: 'raspberry', backgroundArgb: 0xFFFF00A0, foregroundArgb: _white, accentArgb: 0xFFFF6BCB),
    ColorToken(id: 'amber', backgroundArgb: 0xFFD4E000, foregroundArgb: _ink, accentArgb: 0xFFF2FF4D),
    ColorToken(id: 'indigo', backgroundArgb: 0xFF5B00FF, foregroundArgb: _white, accentArgb: 0xFF9D6BFF),
    ColorToken(id: 'cyan', backgroundArgb: 0xFF00B8E6, foregroundArgb: _white, accentArgb: 0xFF5CE8FF),
    ColorToken(id: 'brown', backgroundArgb: 0xFF6B8E00, foregroundArgb: _white, accentArgb: 0xFFB4FF00),
    ColorToken(id: 'slate', backgroundArgb: 0xFF404A5C, foregroundArgb: _white, accentArgb: 0xFFA3FF3D),
  ];

  /// Nombre de couleurs disponibles (= nombre max de joueurs).
  static int get count => all.length;

  /// Retrouve une couleur par son id (ou `null`), en néon si [toxicPalette].
  static ColorToken? byId(String id, {bool toxicPalette = false}) {
    for (final c in toxicPalette ? toxic : all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Couleur de tuile correspondant à une couleur de profil d'alias (ARGB).
  ///
  /// Compat : d'anciens profils ont une couleur hors palette ; on la ramène à
  /// la famille équivalente, sinon à la teinte la plus proche en RVB.
  static ColorToken tileForArgb(int argb) {
    for (final c in all) {
      if (c.backgroundArgb == argb) return c;
    }
    final legacy = _legacyAccents[argb];
    if (legacy != null) return byId(legacy)!;
    int dist(int a, int b) {
      var d = 0;
      for (final shift in const [16, 8, 0]) {
        final x = ((a >> shift) & 0xFF) - ((b >> shift) & 0xFF);
        d += x * x;
      }
      return d;
    }

    return all.reduce((best, c) =>
        dist(c.backgroundArgb, argb) < dist(best.backgroundArgb, argb)
            ? c
            : best);
  }

  /// Anciennes couleurs d'accent des profils sans équivalent exact en tuile.
  static const Map<int, String> _legacyAccents = {
    0xFF6366F1: 'indigo',
    0xFF0EA5E9: 'cyan',
  };
}
