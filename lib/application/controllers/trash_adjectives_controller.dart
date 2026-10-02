import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalogs/adjective_catalog.dart';
import '../providers/app_providers.dart';

/// Pilote la liste **complète** des épithètes du mode trash (réglages),
/// mémorisée via `SettingsRepository` : la table retire celles qui ne lui
/// plaisent pas, ajoute les siennes, ou revient à la liste par défaut. C'est
/// uniquement dans cette liste que le mode trash pioche les noms (v1.6.1,
/// voir DECISIONS F-006).
class TrashAdjectivesController extends Notifier<List<String>> {
  /// Largement de quoi caser la liste par défaut et ses propres blagues, sans
  /// que la liste devienne impossible à parcourir à l'écran.
  static const int maxCount = 100;

  @override
  List<String> build() =>
      ref.read(settingsRepositoryProvider).loadTrashAdjectives();

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
  void resetToDefaults() => _set(List.of(AdjectiveCatalog.trash));

  void _set(List<String> adjectives) {
    state = adjectives;
    ref.read(settingsRepositoryProvider).saveTrashAdjectives(state);
  }
}
