import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers/app_providers.dart';
import '../features/home/home_screen.dart';
import 'theme/app_theme.dart';

/// Racine de l'application 10K.
class TenkApp extends ConsumerWidget {
  const TenkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final trash = ref.watch(trashModeProvider);
    final index = ref.watch(accentSeedIndexProvider);

    // Même tirage de lancement, deux palettes : sage ou fluo. Basculer le mode
    // trash change donc l'accent instantanément, sans re-tirer au sort.
    final palette = trash ? AppTheme.trashAccentSeeds : AppTheme.accentSeeds;
    final seed = palette[index % palette.length];

    return MaterialApp(
      title: '10K',
      debugShowCheckedModeBanner: false,
      theme: trash ? AppTheme.trashLight(seed: seed) : AppTheme.light(seed: seed),
      darkTheme:
          trash ? AppTheme.trashDark(seed: seed) : AppTheme.dark(seed: seed),
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
