import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Pilote les épithètes trash ajoutées par la table (réglages), mémorisées
/// via `SettingsRepository`. Piochées en plus du catalogue de base quand le
/// mode trash tire un nom par défaut.
class CustomAdjectivesController extends Notifier<List<String>> {
  /// Au-delà, la liste perso deviendrait plus grande que le catalogue de base
  /// lui-même — 20 laisse largement de quoi caser ses blagues.
  static const int maxCount = 20;

  @override
  List<String> build() =>
      ref.read(settingsRepositoryProvider).loadCustomTrashAdjectives();

  void add(String adjective) {
    final trimmed = adjective.trim();
    if (trimmed.isEmpty || state.contains(trimmed) || state.length >= maxCount) {
      return;
    }
    state = [...state, trimmed];
    ref.read(settingsRepositoryProvider).saveCustomTrashAdjectives(state);
  }

  void remove(String adjective) {
    state = state.where((a) => a != adjective).toList();
    ref.read(settingsRepositoryProvider).saveCustomTrashAdjectives(state);
  }
}
