import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../providers/app_providers.dart';

/// Pilote la langue de l'interface et la mémorise via `SettingsRepository`.
///
/// Sans choix explicite : français si le téléphone est en français, anglais
/// sinon.
class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final saved = ref.read(settingsRepositoryProvider).loadLanguage();
    final language = saved ?? _deviceLanguage();
    L10n.current = language;
    return language;
  }

  static AppLanguage _deviceLanguage() {
    // Via le binding pour que les tests puissent simuler la langue.
    final code =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return code == 'fr' ? AppLanguage.fr : AppLanguage.en;
  }

  void set(AppLanguage language) {
    if (language == state) return;
    L10n.current = language;
    state = language;
    ref.read(settingsRepositoryProvider).saveLanguage(language);
  }

  /// Passe à l'autre langue (bouton FR/EN de l'accueil).
  void toggle() =>
      set(state == AppLanguage.fr ? AppLanguage.en : AppLanguage.fr);
}
