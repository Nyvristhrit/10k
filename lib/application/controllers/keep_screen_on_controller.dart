import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Pilote le réglage « garder l'écran allumé pendant la partie », mémorisé
/// via `SettingsRepository`. N'active jamais le verrou lui-même : c'est
/// [GameBoardScreen] qui décide, en croisant ce réglage avec le fait d'être
/// réellement à l'écran du plateau.
class KeepScreenOnController extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).loadKeepScreenOnEnabled();

  void set(bool enabled) {
    state = enabled;
    ref.read(settingsRepositoryProvider).saveKeepScreenOnEnabled(enabled);
  }
}
