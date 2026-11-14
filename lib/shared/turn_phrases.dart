import 'dart:math';

import '../l10n/l10n.dart';
import 'trash/trash_taunts.dart';

/// Phrases du joueur actif, ton normal ou trash (voir [Taunts]).
///
/// `{name}` est remplacé par le nom affiché ; la même phrase ne sort pas deux
/// fois de suite.
class TurnPhrases {
  TurnPhrases({Random? random}) : _random = random ?? Random();

  final Random _random;
  int _lastNormal = -1;
  int _lastTrash = -1;

  static const List<String> _templates = [
    '{name}, à toi de jouer !',
    '{name}, lance tes dés !',
    'Fais-les rouler, {name} !',
    'Que la chance soit avec toi, {name} !',
    '{name}, fais trembler la table !',
    'À toi de briller, {name} !',
    'Les dés t\'attendent, {name} !',
    '{name}, c\'est ton moment !',
    'En piste, {name} !',
    '{name}, tente ta chance !',
    'C\'est parti, {name} !',
    '{name}, vise juste !',
    'À ton tour, {name} !',
    '{name}, fais monter le score !',
  ];

  static const List<String> _templatesEn = [
    '{name}, your turn to play!',
    '{name}, roll your dice!',
    'Let them roll, {name}!',
    'May luck be with you, {name}!',
    '{name}, make the table shake!',
    'Time to shine, {name}!',
    'The dice are waiting, {name}!',
    '{name}, this is your moment!',
    'You\'re up, {name}!',
    '{name}, try your luck!',
    'Here we go, {name}!',
    '{name}, aim true!',
    'Your turn, {name}!',
    '{name}, push that score up!',
  ];

  /// Une phrase pour [name], piquante en mode [trash].
  String forName(String name, {bool trash = false}) {
    final bank =
        trash ? Taunts.turnPhrases : trList(_templates, _templatesEn);
    final last = trash ? _lastTrash : _lastNormal;

    var index = _random.nextInt(bank.length);
    if (bank.length > 1 && index == last) {
      index = (index + 1) % bank.length;
    }
    if (trash) {
      _lastTrash = index;
    } else {
      _lastNormal = index;
    }
    return bank[index].replaceAll('{name}', name);
  }
}
