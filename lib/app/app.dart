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
    final seed = ref.watch(accentSeedProvider);
    return MaterialApp(
      title: '10K',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seed: seed),
      darkTheme: AppTheme.dark(seed: seed),
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
