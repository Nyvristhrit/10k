import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Pilote le réglage « dés dans l'appli », mémorisé via `SettingsRepository`.
class DiceTrayController extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).loadDiceTrayEnabled();

  void set(bool enabled) {
    state = enabled;
    ref.read(settingsRepositoryProvider).saveDiceTrayEnabled(enabled);
  }
}
