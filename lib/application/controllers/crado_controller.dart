import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Réglages du « bon dernier » (mode trash) : celui dont le totem est
/// remplacé par un 💩 pète à chaque bouton de la saisie de score et se
/// couvre de taches. Chaque gag se désactive séparément.
class CradoSettings {
  const CradoSettings({this.farts = true, this.stains = true});

  /// Un prout à chaque bouton touché dans la saisie du score.
  final bool farts;

  /// Une tache marron de plus sur sa tuile à chaque bouton touché.
  final bool stains;

  bool get any => farts || stains;

  CradoSettings copyWith({bool? farts, bool? stains}) => CradoSettings(
        farts: farts ?? this.farts,
        stains: stains ?? this.stains,
      );
}

/// Pilote [CradoSettings], mémorisés via `SettingsRepository` (défaut : tout
/// activé — on est déjà en mode trash, il a fallu le débloquer exprès).
class CradoSettingsController extends Notifier<CradoSettings> {
  @override
  CradoSettings build() {
    final repo = ref.read(settingsRepositoryProvider);
    return CradoSettings(
      farts: repo.loadCradoFartsEnabled(),
      stains: repo.loadCradoStainsEnabled(),
    );
  }

  void setFarts(bool enabled) {
    state = state.copyWith(farts: enabled);
    ref.read(settingsRepositoryProvider).saveCradoFartsEnabled(enabled);
  }

  void setStains(bool enabled) {
    state = state.copyWith(stains: enabled);
    ref.read(settingsRepositoryProvider).saveCradoStainsEnabled(enabled);
  }
}

/// Les taches accumulées dans une partie. Elles appartiennent au **titre** de
/// bon dernier, pas à un joueur : quand un autre devient bon dernier, il
/// récupère toute la saleté. Remises à zéro à chaque nouvelle partie, et
/// mémorisées pour survivre à une fermeture de l'appli en cours de partie.
class CradoStainsController extends Notifier<({String? gameId, int count})> {
  @override
  ({String? gameId, int count}) build() =>
      ref.read(settingsRepositoryProvider).loadCradoStains();

  /// Nombre de taches de la partie [gameId] (0 pour une autre partie).
  int countFor(String gameId) => state.gameId == gameId ? state.count : 0;

  /// Une tache de plus dans la partie [gameId].
  void splash(String gameId) {
    state = (gameId: gameId, count: countFor(gameId) + 1);
    ref
        .read(settingsRepositoryProvider)
        .saveCradoStains(gameId: gameId, count: state.count);
  }
}
