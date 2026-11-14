import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalogs/adjective_catalog.dart';
import '../providers/app_providers.dart';

/// Pilote la liste modifiable des épithètes du mode trash, mémorisée via
/// `SettingsRepository`.
class TrashAdjectivesController extends Notifier<List<String>> {
  /// Taille maximale de la liste.
  static const int maxCount = 100;

  @override
  List<String> build() {
    // Une liste par langue : changer de langue recharge la bonne.
    final language = ref.watch(languageProvider);
    return ref
        .read(settingsRepositoryProvider)
        .loadTrashAdjectives(language: language);
  }

  void add(String adjective) {
    final trimmed = adjective.trim();
    if (trimmed.isEmpty || state.contains(trimmed) || state.length >= maxCount) {
      return;
    }
    _set([...state, trimmed]);
  }

  void remove(String adjective) =>
      _set(state.where((a) => a != adjective).toList());

  /// Revient à la liste par défaut (les ajouts perso sont perdus).
  void resetToDefaults() => _set(List.of(AdjectiveCatalog.trashDefaults));

  void _set(List<String> adjectives) {
    state = adjectives;
    ref
        .read(settingsRepositoryProvider)
        .saveTrashAdjectives(state, language: ref.read(languageProvider));
  }
}
