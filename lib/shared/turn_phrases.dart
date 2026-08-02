import 'dart:math';

import 'trash/trash_taunts.dart';

/// Banque de phrases du joueur actif (Annexe B).
///
/// `{name}` est remplacé par le nom affiché. On évite de répéter deux fois de
/// suite la même phrase. Deux registres cohabitent : le ton **normal**
/// (encourageant) et le ton **trash** (voir [Taunts]), chacun avec sa propre
/// mémoire de la dernière phrase tirée.
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

  /// Une phrase pour [name]. En mode [trash], on pioche dans la banque de
  /// piques plutôt que dans les encouragements.
  String forName(String name, {bool trash = false}) {
    final bank = trash ? Taunts.turnPhrases : _templates;
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
