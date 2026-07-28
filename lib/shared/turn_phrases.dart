import 'dart:math';

/// Banque de phrases du joueur actif (Annexe B).
///
/// `{name}` est remplacé par le nom affiché. On évite de répéter deux fois de
/// suite la même phrase.
class TurnPhrases {
  TurnPhrases({Random? random}) : _random = random ?? Random();

  final Random _random;
  int _lastIndex = -1;

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

  String forName(String name) {
    var index = _random.nextInt(_templates.length);
    if (_templates.length > 1 && index == _lastIndex) {
      index = (index + 1) % _templates.length;
    }
    _lastIndex = index;
    return _templates[index].replaceAll('{name}', name);
  }
}
