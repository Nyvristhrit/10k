import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenk/data/catalogs/adjective_catalog.dart';
import 'package:tenk/data/catalogs/animal_catalog.dart';
import 'package:tenk/domain/commands/game_command.dart';
import 'package:tenk/domain/enums/game_enums.dart';
import 'package:tenk/domain/errors/game_rule_violation.dart';
import 'package:tenk/domain/models/game_rules.dart';
import 'package:tenk/domain/models/game_state.dart';
import 'package:tenk/domain/models/player.dart';
import 'package:tenk/domain/services/encounter_summary.dart';
import 'package:tenk/domain/services/game_engine.dart';
import 'package:tenk/domain/services/game_transition.dart';

/// Faux générateur aléatoire qui renvoie toujours le même index (modulo la
/// borne demandée, pour ne jamais planter un tirage qui attend un index plus
/// petit — avatar, couleur…). Utile pour viser une position précise dans un
/// pool sans dépendre du hasard.
class _FixedRandom implements Random {
  const _FixedRandom(this._value);
  final int _value;

  @override
  int nextInt(int max) => _value % max;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

// ── Utilitaires de test ───────────────────────────────────────────────────────

GameEngine makeEngine() {
  var counter = 0;
  return GameEngine(
    idGenerator: () => 'id${counter++}',
    clock: () => DateTime(2026, 1, 1),
    random: Random(42),
  );
}

/// Attend un succès et renvoie l'état résultant.
GameState ok(EngineResult r) {
  expect(r, isA<Success>(),
      reason: r is Failure ? r.violation.toString() : 'attendu Success');
  return (r as Success).transition.nextState;
}

/// Attend un échec et renvoie le code de violation.
GameRuleViolationCode failCode(EngineResult r) {
  expect(r, isA<Failure>(), reason: 'attendu Failure');
  return (r as Failure).violation.code;
}

/// Démarre une partie prête à jouer, avec `n` joueurs.
({GameEngine engine, GameState state, List<String> ids}) start(
  int n, {
  TurnMode mode = TurnMode.free,
  int minEntry = 300,
  int step = 100,
}) {
  final engine = makeEngine();
  var s = engine.createGame(
      rules: GameRules(
          turnMode: mode, minimumEntryScore: minEntry, scoreStep: step));
  for (var i = 0; i < n; i++) {
    s = ok(engine.apply(s, const AddPlayer()));
  }
  s = ok(engine.apply(s, const StartGame()));
  return (engine: engine, state: s, ids: s.players.map((p) => p.id).toList());
}

Player playerOf(GameState s, String id) => s.playerById(id)!;
List<int> pile(GameState s, String id) =>
    s.playerById(id)!.activeGains.map((g) => g.amount).toList();
int scoreOf(GameState s, String id) => s.playerById(id)!.score;
int livesOf(GameState s, String id) => s.playerById(id)!.lives;

void main() {
  // ── §31.1 Préparation ──────────────────────────────────────────────────────
  group('Préparation', () {
    test('refuse le démarrage avec un seul joueur', () {
      final e = makeEngine();
      var s = e.createGame();
      s = ok(e.apply(s, const AddPlayer()));
      expect(failCode(e.apply(s, const StartGame())),
          GameRuleViolationCode.notEnoughPlayers);
    });

    test('autorise le démarrage avec deux joueurs', () {
      final r = start(2);
      expect(r.state.status, GameStatus.inProgress);
    });

    test('autorise douze joueurs, refuse le treizième', () {
      final e = makeEngine();
      var s = e.createGame();
      for (var i = 0; i < 12; i++) {
        s = ok(e.apply(s, const AddPlayer()));
      }
      expect(s.players.length, 12);
      expect(failCode(e.apply(s, const AddPlayer())),
          GameRuleViolationCode.maximumPlayersReached);
    });

    test('nom par défaut : une vraie espèce + une épithète sage du totem',
        () {
      final r = start(4);
      for (final p in r.state.players) {
        final avatar = AnimalCatalog.byId(p.avatarId)!;
        final especes =
            avatar.species.isEmpty ? [avatar.defaultFrenchName] : avatar.species;
        final matching = especes.where((e) => p.displayName.startsWith(e)).toList()
          ..sort((a, b) => b.length.compareTo(a.length));
        expect(matching, isNotEmpty,
            reason:
                '« ${p.displayName} » devrait commencer par une espèce de ${avatar.id}');
        final adjective = p.displayName.substring(matching.first.length).trim();
        expect(AdjectiveCatalog.safe.contains(adjective), true,
            reason: '« $adjective » devrait être une épithète sage');
      }
    });

    test('mode trash : nom par défaut pioche une épithète trash', () {
      final engine = makeEngine();
      var s = engine.createGame();
      s = ok(engine.apply(s, const AddPlayer(trashNames: true)));
      final name = s.players.single.displayName;
      final avatar = AnimalCatalog.byId(s.players.single.avatarId)!;
      final especes =
          avatar.species.isEmpty ? [avatar.defaultFrenchName] : avatar.species;
      final matching = especes.where((e) => name.startsWith(e)).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      final adjective = name.substring(matching.first.length).trim();
      expect(AdjectiveCatalog.trash.contains(adjective), true,
          reason: '« $adjective » devrait être une épithète trash');
    });

    test('mode trash : les épithètes perso rejoignent le pool', () {
      final engine = makeEngine();
      // Une nouvelle partie à chaque tirage (le cap de 12 joueurs empêcherait
      // d'accumuler assez d'essais dans une seule partie).
      var found = false;
      for (var i = 0; i < 300; i++) {
        final s = ok(engine.apply(engine.createGame(),
            const AddPlayer(
                trashNames: true, customTrashAdjectives: ['Aubergine'])));
        if (s.players.single.displayName.endsWith('Aubergine')) {
          found = true;
          break;
        }
      }
      expect(found, true,
          reason: 'L\'épithète perso devrait finir par sortir du tirage');
    });

    test('les épithètes perso comptent double dans le tirage', () {
      // Le poids double est obtenu en dupliquant l'épithète perso dans le
      // pool : deux positions distinctes doivent donc y mener toutes les
      // deux, ce qui est exactement le mécanisme qui double sa probabilité
      // face au catalogue de base.
      const custom = ['Aubergine'];
      final firstCopy = AdjectiveCatalog.trash.length;
      final secondCopy = AdjectiveCatalog.trash.length + custom.length;

      for (final index in [firstCopy, secondCopy]) {
        final engine = GameEngine(
          idGenerator: () => 'id',
          clock: () => DateTime(2026, 1, 1),
          random: _FixedRandom(index),
        );
        final s = ok(engine.apply(engine.createGame(),
            const AddPlayer(trashNames: true, customTrashAdjectives: custom)));
        expect(s.players.single.displayName.endsWith('Aubergine'), true,
            reason: 'index $index du pool devrait pointer sur l\'épithète perso');
      }
    });

    test('emojis (avatars) et couleurs uniques', () {
      final e = makeEngine();
      var s = e.createGame();
      for (var i = 0; i < 12; i++) {
        s = ok(e.apply(s, const AddPlayer()));
      }
      final avatars = s.players.map((p) => p.avatarId).toSet();
      final colors = s.players.map((p) => p.colorId).toSet();
      expect(avatars.length, 12);
      expect(colors.length, 12);
    });

    test('suppression avant départ : place libérée et positions recompactées',
        () {
      final e = makeEngine();
      var s = e.createGame();
      s = ok(e.apply(s, const AddPlayer()));
      s = ok(e.apply(s, const AddPlayer()));
      s = ok(e.apply(s, const AddPlayer()));
      final removedId = s.players[1].id;
      s = ok(e.apply(s, RemovePlayerBeforeStart(playerId: removedId)));
      expect(s.players.length, 2);
      expect(s.players.map((p) => p.seatIndex).toList(), [0, 1]);
    });

    test('renommage valide et refus d\'un nom vide', () {
      final e = makeEngine();
      var s = e.createGame();
      s = ok(e.apply(s, const AddPlayer()));
      final id = s.players.first.id;
      s = ok(e.apply(s, RenamePlayer(playerId: id, newName: 'Bertrand')));
      expect(playerOf(s, id).displayName, 'Bertrand');
      expect(failCode(e.apply(s, RenamePlayer(playerId: id, newName: '  '))),
          GameRuleViolationCode.invalidPlayerName);
    });

    test('verrouille les changements après démarrage', () {
      final r = start(2);
      expect(failCode(r.engine.apply(r.state, const AddPlayer())),
          GameRuleViolationCode.gameAlreadyStarted);
    });
  });

  // ── §31.2 Sortie ────────────────────────────────────────────────────────────
  group('Règle de sortie', () {
    test('refuse 200 avec une sortie à 300', () {
      final r = start(2, minEntry: 300);
      final a = r.ids.first;
      expect(failCode(r.engine.apply(r.state, RecordScore(playerId: a, amount: 200))),
          GameRuleViolationCode.entryMinimumNotReached);
    });

    test('accepte 300 comme première sortie', () {
      final r = start(2, minEntry: 300);
      final s = ok(r.engine.apply(r.state, RecordScore(playerId: r.ids.first, amount: 300)));
      expect(scoreOf(s, r.ids.first), 300);
      expect(playerOf(s, r.ids.first).hasEnteredGame, true);
    });

    test('passage avant sortie : aucune vie perdue', () {
      final r = start(2, minEntry: 300);
      final s = ok(r.engine.apply(r.state, PassTurn(playerId: r.ids.first)));
      expect(livesOf(s, r.ids.first), 3);
    });

    test('retombé à zéro : refuse 100, exige de nouveau le minimum de sortie',
        () {
      final r = start(2, minEntry: 300);
      final e = r.engine;
      final a = r.ids.first;
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 300)));
      // Trois échecs annulent le seul gain -> score 0.
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a, confirmed: true)));
      expect(scoreOf(s, a), 0);
      // Retombé à zéro : il faut refaire la sortie. 100 est refusé...
      expect(failCode(e.apply(s, RecordScore(playerId: a, amount: 100))),
          GameRuleViolationCode.entryMinimumNotReached);
      // ...mais 300 le fait rentrer de nouveau.
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 300)));
      expect(scoreOf(s, a), 300);
    });
  });

  // ── §31.3 / §31.4 Scores, vies et pile ─────────────────────────────────────
  group('Scores, vies et pile de gains', () {
    test('pile [1000,800,500] = 2300 et dernier gain 500', () {
      final r = start(2);
      final e = r.engine;
      final a = r.ids.first;
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 1000)));
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 800)));
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 500)));
      expect(pile(s, a), [1000, 800, 500]);
      expect(scoreOf(s, a), 2300);
      expect(playerOf(s, a).lastActiveGain!.amount, 500);
    });

    test('un score restaure les trois vies', () {
      final r = start(2);
      final e = r.engine;
      final a = r.ids.first;
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 1000)));
      s = ok(e.apply(s, PassTurn(playerId: a))); // 2 vies
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 400)));
      expect(livesOf(s, a), 3);
    });

    test('premier et deuxième échec retirent une vie', () {
      final r = start(2);
      final e = r.engine;
      final a = r.ids.first;
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 1000)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      expect(livesOf(s, a), 2);
      s = ok(e.apply(s, PassTurn(playerId: a)));
      expect(livesOf(s, a), 1);
    });

    test('troisième échec annule le dernier gain et restaure trois vies', () {
      final r = start(2);
      final e = r.engine;
      final a = r.ids.first;
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 1000)));
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 800)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a, confirmed: true)));
      expect(pile(s, a), [1000]);
      expect(scoreOf(s, a), 1000);
      expect(livesOf(s, a), 3);
    });

    test('troisième échec exige une confirmation', () {
      final r = start(2);
      final e = r.engine;
      final a = r.ids.first;
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 1000)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      expect(failCode(e.apply(s, PassTurn(playerId: a))),
          GameRuleViolationCode.confirmationRequiredForThirdMiss);
    });

    test('passage sans gain actif : aucune vie perdue', () {
      final r = start(2);
      final s = ok(r.engine.apply(r.state, PassTurn(playerId: r.ids.first)));
      expect(livesOf(s, r.ids.first), 3);
    });

    test('annuler successivement toute la pile', () {
      final r = start(2);
      final e = r.engine;
      final a = r.ids.first;
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 1000)));
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 800)));
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 500)));
      // 1er cycle de 3 échecs -> annule 500
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a, confirmed: true)));
      expect(scoreOf(s, a), 1800);
      // 2e cycle -> annule 800
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a, confirmed: true)));
      expect(scoreOf(s, a), 1000);
      // 3e cycle -> annule 1000
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a, confirmed: true)));
      expect(scoreOf(s, a), 0);
      expect(pile(s, a), isEmpty);
      expect(livesOf(s, a), 3);
    });

    test('refuse un score négatif ou nul', () {
      final r = start(2);
      expect(failCode(r.engine.apply(r.state, RecordScore(playerId: r.ids.first, amount: 0))),
          GameRuleViolationCode.scoreMustBePositive);
    });

    test('refuse un score qui ne respecte pas le pas', () {
      final r = start(2, step: 100);
      expect(failCode(r.engine.apply(r.state, RecordScore(playerId: r.ids.first, amount: 350))),
          GameRuleViolationCode.invalidScoreStep);
    });
  });

  // ── §31.5 Rencontres ────────────────────────────────────────────────────────
  group('Rencontres', () {
    test('scénario prioritaire (Annexe C.2) : recul puis perte du gain suivant',
        () {
      final r = start(2);
      final e = r.engine;
      final renard = r.ids[0];
      final pingouin = r.ids[1];

      var s = ok(e.apply(r.state, RecordScore(playerId: renard, amount: 1000)));
      s = ok(e.apply(s, RecordScore(playerId: renard, amount: 800)));
      s = ok(e.apply(s, RecordScore(playerId: renard, amount: 500)));
      expect(scoreOf(s, renard), 2300);

      // Pingouin arrive à 2300 -> rencontre, Renard perd 500.
      s = ok(e.apply(s, RecordScore(playerId: pingouin, amount: 2300)));
      expect(scoreOf(s, pingouin), 2300);
      expect(scoreOf(s, renard), 1800);
      expect(pile(s, renard), [1000, 800]);

      // Renard perd son dernier cœur (2 passages puis 3e échec).
      s = ok(e.apply(s, PassTurn(playerId: renard)));
      s = ok(e.apply(s, PassTurn(playerId: renard)));
      final beforeThird = s;
      s = ok(e.apply(s, PassTurn(playerId: renard, confirmed: true)));
      expect(scoreOf(s, renard), 1000);
      expect(pile(s, renard), [1000]);
      expect(livesOf(s, renard), 3);

      // Annulation du troisième échec -> retour exact à 1800 / 1 vie.
      final undone = ok(e.apply(s, const UndoLastAction()));
      expect(scoreOf(undone, renard), 1800);
      expect(pile(undone, renard), [1000, 800]);
      expect(livesOf(undone, renard), livesOf(beforeThird, renard));
    });

    test('conserve le score du joueur déclencheur', () {
      final r = start(2);
      final e = r.engine;
      var s = ok(e.apply(r.state, RecordScore(playerId: r.ids[0], amount: 1500)));
      s = ok(e.apply(s, RecordScore(playerId: r.ids[1], amount: 1500)));
      expect(scoreOf(s, r.ids[1]), 1500); // déclencheur conserve tout
      expect(scoreOf(s, r.ids[0]), 0); // victime perd son unique gain
    });

    test(
        'victime d\'une rencontre partielle : ne récupère pas ses cœurs '
        '(bug corrigé)', () {
      final r = start(2);
      final e = r.engine;
      final victim = r.ids[0];
      final marker = r.ids[1];
      var s = ok(e.apply(r.state, RecordScore(playerId: victim, amount: 900)));
      s = ok(e.apply(s, RecordScore(playerId: victim, amount: 400)));
      s = ok(e.apply(s, PassTurn(playerId: victim))); // vies 2
      s = ok(e.apply(s, RecordScore(playerId: marker, amount: 1300)));
      // Seul le dernier gain (400) part : la pile n'est pas vidée.
      expect(scoreOf(s, victim), 900);
      // Subir une rencontre n'est pas un tour joué : les cœurs restent à 2.
      expect(livesOf(s, victim), 2);
    });

    test(
        'victime d\'une rencontre qui vide sa pile : ressort comme au début, '
        'vies normalisées à 3 (F-003)', () {
      final r = start(2);
      final e = r.engine;
      final victim = r.ids[0];
      final marker = r.ids[1];
      var s = ok(e.apply(r.state, RecordScore(playerId: victim, amount: 900)));
      s = ok(e.apply(s, PassTurn(playerId: victim))); // vies 2, gain unique
      s = ok(e.apply(s, RecordScore(playerId: marker, amount: 900)));
      // Le seul gain de la victime part : la pile est vidée, elle retombe à 0.
      expect(scoreOf(s, victim), 0);
      // Retomber à 0 revient à ressortir du jeu : vies normalisées à 3.
      expect(livesOf(s, victim), 3);
      // Elle doit d'ailleurs refaire le score de sortie pour rejouer.
      expect(
          failCode(e.apply(s, RecordScore(playerId: victim, amount: 200))),
          GameRuleViolationCode.entryMinimumNotReached);
    });

    test('cascade : une victime qui redescend en percute une autre', () {
      // 4 joueurs : Renard monte haut, Panda se pose, X percute Renard qui,
      // en redescendant, vient percuter Panda à son tour.
      final r = start(4);
      final e = r.engine;
      final renard = r.ids[1];
      final panda = r.ids[2];
      final x = r.ids[3];

      var s = ok(e.apply(r.state, RecordScore(playerId: renard, amount: 1000)));
      s = ok(e.apply(s, RecordScore(playerId: renard, amount: 800)));
      s = ok(e.apply(s, RecordScore(playerId: renard, amount: 500)));
      expect(scoreOf(s, renard), 2300);
      s = ok(e.apply(s, RecordScore(playerId: panda, amount: 1800)));

      // X arrive à 2300 : percute Renard (-> 1800), qui percute Panda en
      // redescendant (-> 0). Effet cascade.
      final before = s;
      s = ok(e.apply(s, RecordScore(playerId: x, amount: 2300)));
      expect(scoreOf(s, x), 2300);
      expect(scoreOf(s, renard), 1800); // perd 500
      expect(scoreOf(s, panda), 0); // percuté par Renard qui redescend
      expect(pile(s, panda), isEmpty);

      // Une seule annulation restaure toute la cascade d'un coup.
      final undone = ok(e.apply(s, const UndoLastAction()));
      expect(scoreOf(undone, x), scoreOf(before, x));
      expect(scoreOf(undone, renard), 2300);
      expect(scoreOf(undone, panda), 1800);
      expect(pile(undone, renard), [1000, 800, 500]);
      expect(pile(undone, panda), [1800]);
    });

    test('cascade désactivable : une seule victime si chaînage coupé', () {
      final engine = makeEngine();
      var s = engine.createGame(
          rules: const GameRules(
              turnMode: TurnMode.free, encounterChainsEnabled: false));
      for (var i = 0; i < 4; i++) {
        s = ok(engine.apply(s, const AddPlayer()));
      }
      s = ok(engine.apply(s, const StartGame()));
      final ids = s.players.map((p) => p.id).toList();
      final renard = ids[1];
      final panda = ids[2];
      final x = ids[3];

      s = ok(engine.apply(s, RecordScore(playerId: renard, amount: 1000)));
      s = ok(engine.apply(s, RecordScore(playerId: renard, amount: 800)));
      s = ok(engine.apply(s, RecordScore(playerId: renard, amount: 500)));
      s = ok(engine.apply(s, RecordScore(playerId: panda, amount: 1800)));
      s = ok(engine.apply(s, RecordScore(playerId: x, amount: 2300)));
      expect(scoreOf(s, renard), 1800); // percuté
      expect(scoreOf(s, panda), 1800); // PAS de cascade : Panda intact
    });

    test('résumé de rencontre extrait le marqueur et les victimes', () {
      final r = start(2);
      final e = r.engine;
      final a = r.ids[0];
      final b = r.ids[1];
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 1500)));
      s = ok(e.apply(s, RecordScore(playerId: b, amount: 1500)));
      final summary = encounterOfAction(s.actions.last);
      expect(summary, isNotNull);
      expect(summary!.markerId, b);
      expect(summary.count, 1);
      expect(summary.victims.single.playerId, a);
      expect(summary.victims.single.amountLost, 1500);
    });

    test('résumé de cascade : victimes dans l\'ordre du ricochet', () {
      final r = start(4);
      final e = r.engine;
      final renard = r.ids[1];
      final panda = r.ids[2];
      final x = r.ids[3];
      var s = ok(e.apply(r.state, RecordScore(playerId: renard, amount: 1000)));
      s = ok(e.apply(s, RecordScore(playerId: renard, amount: 800)));
      s = ok(e.apply(s, RecordScore(playerId: renard, amount: 500)));
      s = ok(e.apply(s, RecordScore(playerId: panda, amount: 1800)));
      s = ok(e.apply(s, RecordScore(playerId: x, amount: 2300)));
      final summary = encounterOfAction(s.actions.last);
      expect(summary, isNotNull);
      expect(summary!.markerId, x);
      expect(summary.victims.map((v) => v.playerId).toList(), [renard, panda]);
    });

    test('ignore un joueur ayant quitté', () {
      final r = start(3, mode: TurnMode.free);
      final e = r.engine;
      final leaver = r.ids[0];
      final marker = r.ids[1];
      var s = ok(e.apply(r.state, RecordScore(playerId: leaver, amount: 1200)));
      s = ok(e.apply(s, LeaveGame(playerId: leaver)));
      s = ok(e.apply(s, RecordScore(playerId: marker, amount: 1200)));
      // Le partant n'est pas rencontré : il garde son score figé.
      expect(scoreOf(s, leaver), 1200);
      expect(scoreOf(s, marker), 1200);
    });
  });

  // ── §31.6 Objectif et dépassement ───────────────────────────────────────────
  group('Objectif et dépassement', () {
    test('accepte exactement 10 000 et déclenche la dernière chance', () {
      final r = start(2);
      final e = r.engine;
      final s = ok(e.apply(r.state, RecordScore(playerId: r.ids.first, amount: 10000)));
      expect(scoreOf(s, r.ids.first), 10000);
      expect(s.status, GameStatus.finalChance);
    });

    test('refuse un dépassement sans confirmation', () {
      final r = start(2);
      final e = r.engine;
      var s = ok(e.apply(r.state, RecordScore(playerId: r.ids.first, amount: 9700)));
      expect(failCode(e.apply(s, RecordScore(playerId: r.ids.first, amount: 400))),
          GameRuleViolationCode.confirmationRequiredForOvershoot);
    });

    test('dépassement confirmé = échec, aucun gain créé', () {
      final r = start(2);
      final e = r.engine;
      var s = ok(e.apply(r.state, RecordScore(playerId: r.ids.first, amount: 9700)));
      s = ok(e.apply(s, RecordScore(playerId: r.ids.first, amount: 400, confirmed: true)));
      expect(scoreOf(s, r.ids.first), 9700); // inchangé
      expect(livesOf(s, r.ids.first), 2); // une vie perdue
    });

    test('dépassement comme troisième échec (Annexe C.4)', () {
      final r = start(2);
      final e = r.engine;
      final a = r.ids.first;
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 3000)));
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 4000)));
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 2800)));
      expect(scoreOf(s, a), 9800);
      // Réduit à 1 vie.
      s = ok(e.apply(s, PassTurn(playerId: a)));
      s = ok(e.apply(s, PassTurn(playerId: a)));
      // Tente +300 -> 10100, confirme -> troisième échec, annule 2800.
      s = ok(e.apply(s, RecordScore(playerId: a, amount: 300, confirmed: true)));
      expect(scoreOf(s, a), 7000);
      expect(pile(s, a), [3000, 4000]);
      expect(livesOf(s, a), 3);
    });
  });

  // ── §31.7 Dernière chance ────────────────────────────────────────────────────
  group('Dernière chance', () {
    test('ordre circulaire correct en mode guidé, candidat initial exclu', () {
      final r = start(4, mode: TurnMode.guided);
      final e = r.engine;
      // Rend le joueur en siège 2 actif, puis il atteint 10 000.
      final panda = r.ids[2];
      var s = ok(e.apply(r.state, SelectGuidedPlayer(playerId: panda)));
      s = ok(e.apply(s, RecordScore(playerId: panda, amount: 10000)));
      expect(s.status, GameStatus.finalChance);
      final fc = s.finalChanceState!;
      expect(fc.pendingPlayerIds, [r.ids[3], r.ids[0], r.ids[1]]);
      expect(fc.currentPlayerId, r.ids[3]);
      expect(fc.pendingPlayerIds.contains(panda), false);
    });

    test('2 joueurs, mode libre : le dernier tour termine la partie', () {
      final r = start(2, mode: TurnMode.free);
      final e = r.engine;
      final a = r.ids[0];
      final b = r.ids[1];
      // A atteint 10 000 -> dernière chance, B a un ultime tour.
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 10000)));
      expect(s.status, GameStatus.finalChance);
      expect(s.finalChanceState!.pendingPlayerIds, [b]);
      // B joue un score qui n'atteint pas la cible -> la partie se termine, A gagne.
      s = ok(e.apply(s, RecordScore(playerId: b, amount: 500)));
      expect(s.status, GameStatus.finished);
      expect(s.winnerPlayerId, a);
    });

    test('2 joueurs, mode guidé : le dernier tour (passe) termine la partie', () {
      final r = start(2, mode: TurnMode.guided);
      final e = r.engine;
      final a = r.ids[0];
      final b = r.ids[1];
      var s = ok(e.apply(r.state, RecordScore(playerId: a, amount: 10000)));
      expect(s.status, GameStatus.finalChance);
      expect(s.finalChanceState!.currentPlayerId, b);
      // B passe sa dernière chance -> fin de partie, A gagne.
      s = ok(e.apply(s, PassTurn(playerId: b)));
      expect(s.status, GameStatus.finished);
      expect(s.winnerPlayerId, a);
    });

    test('rencontre à 10 000 : le candidat est délogé (Annexe C.5)', () {
      final r = start(3, mode: TurnMode.free);
      final e = r.engine;
      final ping = r.ids[0];
      final renard = r.ids[1];
      final panda = r.ids[2];

      var s = ok(e.apply(r.state, RecordScore(playerId: ping, amount: 10000)));
      expect(s.finalChanceState!.currentCandidatePlayerId, ping);

      // Renard utilise sa dernière chance et atteint aussi 10 000.
      s = ok(e.apply(s, RecordScore(playerId: renard, amount: 10000)));
      expect(scoreOf(s, renard), 10000);
      expect(scoreOf(s, ping) < 10000, true); // délogé
      expect(s.finalChanceState!.currentCandidatePlayerId, renard);

      // Panda joue sa dernière chance (passe) -> fin de partie, Renard gagne.
      s = ok(e.apply(s, PassTurn(playerId: panda)));
      expect(s.status, GameStatus.finished);
      expect(s.winnerPlayerId, renard);
    });
  });

  // ── §31.8 Tours guidés ───────────────────────────────────────────────────────
  group('Tours guidés', () {
    test('avance au joueur suivant puis incrémente la manche', () {
      final r = start(3, mode: TurnMode.guided);
      final e = r.engine;
      expect(r.state.roundState!.currentPlayerId, r.ids[0]);
      var s = ok(e.apply(r.state, RecordScore(playerId: r.ids[0], amount: 500)));
      expect(s.roundState!.currentPlayerId, r.ids[1]);
      s = ok(e.apply(s, RecordScore(playerId: r.ids[1], amount: 500)));
      expect(s.roundState!.currentPlayerId, r.ids[2]);
      s = ok(e.apply(s, PassTurn(playerId: r.ids[2])));
      // Fin de manche 1 -> manche 2, retour au premier.
      expect(s.roundState!.roundNumber, 2);
      expect(s.roundState!.currentPlayerId, r.ids[0]);
    });

    test('sélection hors ordre sans créer d\'échec (Annexe C.6)', () {
      final r = start(4, mode: TurnMode.guided);
      final e = r.engine;
      var s = ok(e.apply(r.state, RecordScore(playerId: r.ids[0], amount: 500)));
      s = ok(e.apply(s, RecordScore(playerId: r.ids[1], amount: 500)));
      // C actif ; on choisit D à la place.
      s = ok(e.apply(s, SelectGuidedPlayer(playerId: r.ids[3])));
      s = ok(e.apply(s, RecordScore(playerId: r.ids[3], amount: 500)));
      // C reste en attente, aucune vie perdue nulle part.
      expect(s.roundState!.pendingPlayerIds, [r.ids[2]]);
      expect(livesOf(s, r.ids[2]), 3);
    });

    test('refuse de jouer hors de son tour en mode guidé', () {
      final r = start(3, mode: TurnMode.guided);
      final e = r.engine;
      expect(failCode(e.apply(r.state, RecordScore(playerId: r.ids[1], amount: 500))),
          GameRuleViolationCode.playerNotAllowedToPlay);
    });
  });

  // ── §31.9 Annulation ──────────────────────────────────────────────────────────
  group('Annulation', () {
    test('annule un score simple', () {
      final r = start(2);
      final e = r.engine;
      var s = ok(e.apply(r.state, RecordScore(playerId: r.ids.first, amount: 500)));
      s = ok(e.apply(s, const UndoLastAction()));
      expect(scoreOf(s, r.ids.first), 0);
      expect(playerOf(s, r.ids.first).hasEnteredGame, false);
    });

    test('annule un passage', () {
      final r = start(2);
      final e = r.engine;
      var s = ok(e.apply(r.state, RecordScore(playerId: r.ids.first, amount: 500)));
      s = ok(e.apply(s, PassTurn(playerId: r.ids.first)));
      expect(livesOf(s, r.ids.first), 2);
      s = ok(e.apply(s, const UndoLastAction()));
      expect(livesOf(s, r.ids.first), 3);
    });

    test('annule le déclenchement de la dernière chance', () {
      final r = start(2);
      final e = r.engine;
      var s = ok(e.apply(r.state, RecordScore(playerId: r.ids.first, amount: 10000)));
      expect(s.status, GameStatus.finalChance);
      s = ok(e.apply(s, const UndoLastAction()));
      expect(s.status, GameStatus.inProgress);
      expect(s.finalChanceState, isNull);
      expect(scoreOf(s, r.ids.first), 0);
    });

    test('refuse l\'annulation sans action disponible', () {
      final r = start(2);
      expect(failCode(r.engine.apply(r.state, const UndoLastAction())),
          GameRuleViolationCode.noActionToUndo);
    });
  });
}
