import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Pilote le mode trash et le mémorise via `SettingsRepository`.
class TrashModeController extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).loadTrashMode();

  /// Bascule le mode et renvoie le nouvel état.
  bool toggle() {
    final next = !state;
    state = next;
    ref.read(settingsRepositoryProvider).saveTrashMode(next);
    return next;
  }
}
