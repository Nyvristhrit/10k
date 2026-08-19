import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Pilote les épithètes trash ajoutées par la table (réglages), mémorisées
/// via `SettingsRepository`. Piochées en plus du catalogue de base quand le
/// mode trash tire un nom par défaut.
class CustomAdjectivesController extends Notifier<List<String>> {
  @override
  List<String> build() =>
      ref.read(settingsRepositoryProvider).loadCustomTrashAdjectives();

  void add(String adjective) {
    final trimmed = adjective.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) return;
    state = [...state, trimmed];
    ref.read(settingsRepositoryProvider).saveCustomTrashAdjectives(state);
  }

  void remove(String adjective) {
    state = state.where((a) => a != adjective).toList();
    ref.read(settingsRepositoryProvider).saveCustomTrashAdjectives(state);
  }
}
