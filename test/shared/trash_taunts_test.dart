import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/shared/trash/trash_taunts.dart';
import 'package:tenk/shared/turn_phrases.dart';

void main() {
  group('Compteur de déblocage', () {
    test('reste muet tant qu\'on est loin du compte', () {
      for (var taps = 1; taps <= 3; taps++) {
        expect(Taunts.unlockHint(taps, active: false), isNull,
            reason: '$taps tapes ne devraient rien annoncer');
      }
    });

    test('décompte les trois dernières tapes', () {
      expect(Taunts.unlockHint(4, active: false), contains('3'));
      expect(Taunts.unlockHint(5, active: false), contains('2'));
      expect(Taunts.unlockHint(6, active: false), isNotNull);
    });

    test('annonce l\'extinction quand le mode est déjà actif', () {
      final hint = Taunts.unlockHint(6, active: true)!;
      expect(hint.toLowerCase(), contains('poli'));
    });

    test('ne dit plus rien une fois le seuil atteint (l\'appelant bascule)', () {
      expect(Taunts.unlockHint(Taunts.unlockTaps, active: false), isNull);
      expect(Taunts.unlockHint(Taunts.unlockTaps + 1, active: false), isNull);
    });
  });

  group('Piques', () {
    test('toutes les phrases de tour nomment le joueur', () {
      for (final p in Taunts.turnPhrases) {
        expect(p, contains('{name}'), reason: 'phrase sans {name} : $p');
      }
    });

    test('le roast du dernier reprend son nom et son score', () {
      final line = Taunts.loserLine('Crevette', 2300);
      expect(line, contains('Crevette'));
      expect(line, contains('2300'));
      expect(line, isNot(contains('{')));
    });

    test('le commentaire du vainqueur le nomme sans laisser de gabarit', () {
      final line = Taunts.winnerLine('Panda');
      expect(line, contains('Panda'));
      expect(line, isNot(contains('{')));
    });

    test('le titre de rencontre monte avec le nombre de victimes', () {
      expect(Taunts.encounterTitle(1), isNotEmpty);
      expect(Taunts.encounterTitle(2), isNot(Taunts.encounterTitle(1)));
      expect(Taunts.encounterTitle(5), Taunts.encounterTitle(4));
    });

    test('le troisième échec s\'adapte à ce qu\'il reste à perdre', () {
      expect(Taunts.thirdMissBody('Lézard', 800), contains('800'));
      expect(Taunts.thirdMissBody('Lézard', null), isNot(contains('800')));
    });
  });

  group('Banque de phrases du tour', () {
    test('substitue le nom dans les deux registres', () {
      final phrases = TurnPhrases(random: Random(1));
      expect(phrases.forName('Otarie'), contains('Otarie'));
      expect(phrases.forName('Otarie', trash: true), contains('Otarie'));
    });

    test('ne répète jamais deux fois de suite la même pique', () {
      final phrases = TurnPhrases(random: Random(7));
      var previous = phrases.forName('Panda', trash: true);
      for (var i = 0; i < 40; i++) {
        final next = phrases.forName('Panda', trash: true);
        expect(next, isNot(previous));
        previous = next;
      }
    });

    test('les deux registres gardent une mémoire séparée', () {
      // Alterner normal/trash ne doit pas faire croire à une répétition :
      // chaque banque suit son propre dernier tirage.
      final phrases = TurnPhrases(random: Random(3));
      final normal = <String>{};
      final trash = <String>{};
      for (var i = 0; i < 30; i++) {
        normal.add(phrases.forName('Ours'));
        trash.add(phrases.forName('Ours', trash: true));
      }
      expect(normal.length, greaterThan(1));
      expect(trash.length, greaterThan(1));
      // Les deux banques sont bien distinctes.
      expect(normal.intersection(trash), isEmpty);
    });
  });
}
