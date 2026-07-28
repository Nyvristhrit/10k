import 'package:flutter/material.dart';

/// Thème visuel de l'application (§29.1).
///
/// Deux ambiances : **nuit** (sombre, l'historique de l'appli) et **jour**
/// (clair). Le choix est piloté depuis l'accueil (bascule lune/soleil) et
/// mémorisé. Les tuiles des joueurs gardent leurs couleurs vives dans les deux.
class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'SpaceGrotesk';

  // ── Ambiance nuit (encre neutre / charbon, sans dominante bleue) ──────────
  static const Color background = Color(0xFF121118);
  static const Color surface = Color(0xFF1D1B26);
  static const Color surfaceHigh = Color(0xFF272433);

  /// Dégradé de fond de l'ambiance nuit (voir [AppBackground]).
  static const List<Color> darkBackgroundGradient = [
    Color(0xFF201F2B),
    Color(0xFF141319),
    Color(0xFF0B0A0F),
  ];

  // ── Ambiance jour (blanc cassé chaleureux, doux pour les yeux) ────────────
  static const Color lightBackground = Color(0xFFF4F3FA);
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Dégradé de fond de l'ambiance jour.
  static const List<Color> lightBackgroundGradient = [
    Color(0xFFFBFAFF),
    Color(0xFFF1F0F9),
    Color(0xFFE7E5F2),
  ];

  static const Color _seed = Color(0xFF6366F1);

  /// Palette de teintes d'accent piochées au hasard à chaque ouverture (petit
  /// clin d'œil multicolore). Toutes vives et harmonieuses en jour comme en
  /// nuit une fois passées dans `ColorScheme.fromSeed`.
  static const List<Color> accentSeeds = [
    Color(0xFF6366F1), // indigo
    Color(0xFF2563EB), // cobalt
    Color(0xFF0EA5E9), // cyan
    Color(0xFF0D9488), // teal
    Color(0xFF059669), // émeraude
    Color(0xFFEA580C), // orange
    Color(0xFFE11D48), // rubis
    Color(0xFFDB2777), // framboise
    Color(0xFF7C3AED), // violet
    Color(0xFFF59E0B), // ambre
  ];

  static ThemeData dark({Color seed = _seed}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(surface: surface);
    return _base(scheme, background);
  }

  static ThemeData light({Color seed = _seed}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(surface: lightSurface);
    return _base(scheme, lightBackground);
  }

  /// Squelette commun aux deux ambiances (composants, arrondis, police).
  static ThemeData _base(ColorScheme scheme, Color scaffoldBg) {
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, fontFamily: fontFamily),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }

  /// Convertit un entier ARGB (0xAARRGGBB) en [Color].
  static Color fromArgb(int argb) => Color(argb);
}
