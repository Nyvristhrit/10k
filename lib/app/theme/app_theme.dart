import 'package:flutter/material.dart';

import 'tenk_skin.dart';

/// Thème visuel de l'application (§29.1).
///
/// Deux ambiances : **nuit** (sombre, l'historique de l'appli) et **jour**
/// (clair). Le choix est piloté depuis l'accueil (bascule lune/soleil) et
/// mémorisé. Les tuiles des joueurs gardent leurs couleurs vives dans les deux.
///
/// Chaque ambiance existe en deux habillages : le **sage** (arc-en-ciel) et le
/// **trash** (néon cyberpunk), déblocable en secret. L'habillage voyage dans le
/// thème via [TenkSkin].
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

  // ── Ambiance trash (néon cyberpunk : fluo sur noir violacé) ───────────────
  static const Color trashBackground = Color(0xFF08000F);
  static const Color trashSurface = Color(0xFF1A0026);
  static const Color trashLightBackground = Color(0xFFFFF4FC);
  static const Color trashLightSurface = Color(0xFFFFFFFF);

  /// Teintes d'accent du mode trash : les mêmes emplacements que
  /// [accentSeeds] (même longueur, donc le tirage du lancement reste valable),
  /// mais poussées au fluo.
  static const List<Color> trashAccentSeeds = [
    Color(0xFFFF00A0), // magenta
    Color(0xFF00F0FF), // cyan
    Color(0xFFB4FF00), // vert acide
    Color(0xFF9D00FF), // violet électrique
    Color(0xFFFF3D00), // orange fluo
    Color(0xFF00FF9D), // menthe fluo
    Color(0xFFFF0055), // rouge fluo
    Color(0xFF7B00FF), // indigo fluo
    Color(0xFFFFEA00), // jaune fluo
    Color(0xFFFF00E5), // fuchsia
  ];

  static ThemeData dark({Color seed = _seed}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(surface: surface);
    return _base(scheme, background, TenkSkin.classic);
  }

  static ThemeData light({Color seed = _seed}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(surface: lightSurface);
    return _base(scheme, lightBackground, TenkSkin.classicLight);
  }

  /// Ambiance nuit du mode trash. On force une saturation élevée : le rendu
  /// « fromSeed » adoucit les fluos, on remet donc les couleurs vives à la main
  /// sur les rôles qui portent l'identité (primaire, secondaire).
  static ThemeData trashDark({Color seed = trashNeon}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: trashSurface,
      primary: seed,
      onPrimary: Colors.black,
      secondary: TenkSkin.trashDark.neonAlt,
      onSecondary: Colors.black,
    );
    return _base(scheme, trashBackground, TenkSkin.trashDark);
  }

  /// Ambiance jour du mode trash : le même néon, en négatif sur blanc acide.
  static ThemeData trashLight({Color seed = trashNeon}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: trashLightSurface,
      primary: _darken(seed),
      onPrimary: Colors.white,
    );
    return _base(scheme, trashLightBackground, TenkSkin.trashLight);
  }

  static const Color trashNeon = Color(0xFFFF00A0);

  /// Assombrit une teinte fluo pour qu'elle reste lisible sur fond blanc.
  static Color _darken(Color c) => Color.fromARGB(
        255,
        (c.r * 255 * 0.78).round(),
        (c.g * 255 * 0.78).round(),
        (c.b * 255 * 0.78).round(),
      );

  /// Squelette commun à toutes les ambiances (composants, arrondis, police).
  static ThemeData _base(ColorScheme scheme, Color scaffoldBg, TenkSkin skin) {
    return ThemeData(
      extensions: [skin],
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
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
            // Le trash respire le néon d'enseigne : lettres espacées, angles durs.
            letterSpacing: skin.trash ? 1.2 : 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(skin.corner),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(skin.corner),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(skin.corner + 4)),
      ),
    );
  }

  /// Convertit un entier ARGB (0xAARRGGBB) en [Color].
  static Color fromArgb(int argb) => Color(argb);
}
