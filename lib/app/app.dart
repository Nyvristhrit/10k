import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers/app_providers.dart';
import '../features/home/home_screen.dart';
import '../shared/app_icon.dart';
import 'theme/app_theme.dart';

/// Racine de l'application 10K.
class TenkApp extends ConsumerWidget {
  const TenkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final trash = ref.watch(trashModeProvider);
    final index = ref.watch(accentSeedIndexProvider);
    final language = ref.watch(languageProvider);

    // Même indice tiré au lancement, palette sage ou trash.
    final palette = trash ? AppTheme.trashAccentSeeds : AppTheme.accentSeeds;
    final seed = palette[index % palette.length];

    // L'icône suit le mode trash ; `sync` ne transmet qu'un changement.
    AppIcon.sync(trash: trash);

    return MaterialApp(
      // La clé change avec la langue : toute l'interface est reconstruite.
      key: ValueKey(language),
      title: '10K',
      locale: Locale(language.code),
      supportedLocales: const [Locale('fr'), Locale('en')],
      // Textes intégrés de Flutter (« Annuler » des sélecteurs, infobulles…).
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: trash ? AppTheme.trashLight(seed: seed) : AppTheme.light(seed: seed),
      darkTheme:
          trash ? AppTheme.trashDark(seed: seed) : AppTheme.dark(seed: seed),
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
