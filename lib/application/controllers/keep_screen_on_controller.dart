import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Pilote le réglage « garder l'écran allumé », mémorisé via
/// `SettingsRepository`. Le verrou lui-même est géré par [GameBoardScreen].
class KeepScreenOnController extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).loadKeepScreenOnEnabled();

  void set(bool enabled) {
    state = enabled;
    ref.read(settingsRepositoryProvider).saveKeepScreenOnEnabled(enabled);
  }
}
