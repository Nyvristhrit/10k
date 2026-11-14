/// Langue de l'interface (français / anglais).
///
/// Chaque texte est écrit sur place dans ses deux versions :
///
/// ```dart
/// Text(tr('Nouvelle partie', 'New game'))
/// ```
///
/// La langue est globale ([L10n.current]) pour être accessible depuis le
/// domaine, sans Flutter. `TenkApp` reconstruit l'interface quand elle change.
library;

enum AppLanguage {
  fr('fr'),
  en('en');

  const AppLanguage(this.code);

  /// Code ISO enregistré dans les réglages (`settings.json`).
  final String code;

  static AppLanguage? fromCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return null;
  }
}

class L10n {
  const L10n._();

  /// Langue en cours. Français par défaut (et dans les tests).
  static AppLanguage current = AppLanguage.fr;

  static bool get isEnglish => current == AppLanguage.en;
}

/// Le texte [fr] ou [en] selon la langue en cours.
String tr(String fr, String en) => L10n.isEnglish ? en : fr;

/// Choisit l'une des deux listes selon la langue en cours.
List<T> trList<T>(List<T> fr, List<T> en) => L10n.isEnglish ? en : fr;
