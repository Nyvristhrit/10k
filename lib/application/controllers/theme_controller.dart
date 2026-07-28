import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Pilote le thème jour/nuit et le mémorise via [SettingsRepository].
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(settingsRepositoryProvider).loadThemeMode();

  /// Bascule nuit ↔ jour (utilisé par le bouton lune/soleil de l'accueil).
  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    ref.read(settingsRepositoryProvider).saveThemeMode(next);
  }
}
