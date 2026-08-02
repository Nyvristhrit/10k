import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Pilote le **mode trash** et le mémorise via `SettingsRepository`.
///
/// Le mode se débloque en tapant 7 fois la carte de dédicace de l'écran
/// « À propos » (clin d'œil aux options développeur d'Android), et se coupe de
/// la même façon.
class TrashModeController extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).loadTrashMode();

  /// Bascule le mode et renvoie le nouvel état (pratique pour afficher le bon
  /// message de confirmation dans la foulée).
  bool toggle() {
    final next = !state;
    state = next;
    ref.read(settingsRepositoryProvider).saveTrashMode(next);
    return next;
  }
}
