import 'dart:math';

import '../../l10n/l10n.dart';

/// Textes du mode trash (débloqué en tapant 7 fois la dédicace dans
/// « À propos »). Le mode ne change aucune règle, seulement le ton.
///
/// La version anglaise ([tr]) est une adaptation, pas une traduction littérale.
class Taunts {
  const Taunts._();

  static final Random _rnd = Random();

  static String _pick(List<String> lines) => lines[_rnd.nextInt(lines.length)];

  static String _fill(String template, String name) =>
      template.replaceAll('{name}', name);

  // ── Identité ──────────────────────────────────────────────────────────────

  /// Le mot accolé au logo sur l'accueil.
  static const String badge = 'TRASH';

  /// Accroche de l'accueil, à la place de « Compagnon de jeu du 10 000 ».
  static String get tagline =>
      tr('Le 10 000, sans la politesse', '10,000, minus the manners');

  /// Emojis qui pleuvent en fond d'accueil (au lieu du seul dé).
  static const List<String> fallingEmojis = ['🎲', '💀', '🔥', '💩', '☠️', '🤡'];

  // ── Déblocage (compteur de tapes) ─────────────────────────────────────────

  /// Nombre de tapes sur la carte de dédicace pour basculer le mode.
  static const int unlockTaps = 7;

  /// Message affiché pendant le comptage, ou `null` s'il n'y a rien à dire.
  ///
  /// [taps] : tapes déjà faites ; [active] : état courant du mode trash.
  static String? unlockHint(int taps, {required bool active}) {
    final left = unlockTaps - taps;
    if (left <= 0 || left > 3) return null;
    if (active) {
      return left == 1
          ? tr('Encore 1 et on redevient poli.',
              'One more and we\'re polite again.')
          : tr('Plus que $left avant de retrouver les bonnes manières.',
              '$left more before good manners return.');
    }
    return left == 1
        ? tr('Encore 1. Tu vas le regretter.', 'One more. You\'ll regret it.')
        : tr('Plus que $left avant que ça dégénère.',
            '$left more before things go downhill.');
  }

  /// Texte de l'écran de bascule.
  static String get unlockedTitle =>
      tr('MODE TRASH ACTIVÉ', 'TRASH MODE ENABLED');
  static String get unlockedBody => tr(
      'Les règles ne changent pas. Le ton, si.\n'
          'L\'appli va désormais commenter vos performances. Sans filtre, et sans '
          'la moindre bienveillance.\n\n'
          'Pour revenir à la version fréquentable : retape 7 fois la même carte.',
      'The rules don\'t change. The tone does.\n'
          'From now on, the app will comment on your performance. No filter, '
          'and not a shred of kindness.\n\n'
          'To get the respectable version back: tap the same card 7 times again.');
  static String get lockedTitle =>
      tr('Retour à la civilisation', 'Back to civilization');
  static String get lockedBody => tr(
      'L\'appli redevient polie. C\'était bien tenté.',
      'The app is polite again. Nice try, though.');

  /// Bandeau affiché dans « À propos » tant que le mode est actif.
  static String get activeBanner => tr(
      'Mode trash actif. Les joueurs sont prévenus (ou pas).',
      'Trash mode on. Players have been warned (or not).');

  // ── Plateau : phrase du joueur actif ──────────────────────────────────────

  /// Phrases du joueur dont c'est le tour. `{name}` = nom affiché.
  static List<String> get turnPhrases => trList(_turnPhrasesFr, _turnPhrasesEn);

  static const List<String> _turnPhrasesFr = [
    'Bon. {name}. Va peut-être falloir te rattraper là.',
    '{name}, essaie de ne pas tout foirer cette fois.',
    'Allez {name}, montre-nous l\'étendue de ta médiocrité.',
    'C\'est à {name}. La table retient son bâillement.',
    '{name}, les dés ne sont pas responsables de ton niveau.',
    'Vas-y {name}, rate ça proprement au moins.',
    '{name} lance. Personne n\'y croit. Même pas {name}.',
    'Dépêche-toi {name}, on a une vie.',
    'Tu peux passer directement {name}, ça ira plus vite.',
    '{name}, statistiquement tu vas te vautrer. Mais tente.',
    'Les dés te détestent, {name}. Prouve-leur qu\'ils ont raison.',
    'Secoue-moi ces dés {name}, et ta dignité avec.',
    'À toi {name}. La honte n\'attend que ça.',
    '{name}, souviens-toi : le but, c\'est de marquer des points.',
    'Tour de {name}. On note tout, tu sais.',
    'Fais rouler, {name}. Le ridicule ne tue pas. Vérifions.',
    'Personne ne mise sur toi, {name}. Personne.',
    '{name}, ton tour. Fais court, ce sera moins gênant.',
    'On y croyait plus. {name} daigne jouer.',
    '{name}, tu veux qu\'on t\'explique les règles encore une fois ?',
    'Chers spectateurs, {name} va encore nous décevoir.',
    'Ça va {name} ? Besoin d\'un coussin, d\'un plaid, d\'un talent ?',
    '{name} entre en scène. La médiocrité aussi.',
    'Bonne chance {name}. Tu vas en avoir besoin. Beaucoup.',
    '{name}, les dés t\'ont vu arriver et ils ont soupiré.',
    'Ton tour {name}. Essaie de faire mieux que ta vie.',
    'Attention, {name} va jouer. Cachez les enfants.',
    '{name}, même la table a pitié. C\'est dire.',
    'Roule {name}. Et arrête de souffler sur les dés, ça marche pas.',
    '{name}, le talent c\'est comme les points : tu en as pas.',
  ];

  static const List<String> _turnPhrasesEn = [
    'Right. {name}. Might be time to catch up.',
    '{name}, try not to mess it all up this time.',
    'Go on {name}, show us the full extent of your mediocrity.',
    '{name}\'s turn. The table stifles a yawn.',
    '{name}, the dice are not to blame for your skill level.',
    'Go ahead {name}, at least fail with some style.',
    '{name} rolls. Nobody believes in it. Not even {name}.',
    'Hurry up {name}, some of us have lives.',
    'You could just pass, {name}. It\'d be quicker.',
    '{name}, statistically you\'re going to faceplant. But sure, try.',
    'The dice hate you, {name}. Prove them right.',
    'Shake those dice {name}, and your dignity with them.',
    'Your go, {name}. Shame is waiting for you.',
    '{name}, reminder: the goal is to score points.',
    '{name}\'s turn. We\'re writing everything down, you know.',
    'Roll, {name}. Embarrassment never killed anyone. Let\'s check.',
    'Nobody\'s betting on you, {name}. Nobody.',
    '{name}, your turn. Keep it short, it\'ll be less awkward.',
    'We\'d given up hope. {name} deigns to play.',
    '{name}, want us to explain the rules one more time?',
    'Dear viewers, {name} is about to disappoint us again.',
    'You OK {name}? Need a cushion, a blanket, some talent?',
    '{name} takes the stage. So does mediocrity.',
    'Good luck {name}. You\'ll need it. A lot.',
    '{name}, the dice saw you coming and sighed.',
    'Your turn {name}. Try to do better than your life choices.',
    'Heads up, {name} is about to play. Hide the children.',
    '{name}, even the table feels sorry for you. That says a lot.',
    'Roll {name}. And stop blowing on the dice, it doesn\'t work.',
    '{name}, talent is like points: you don\'t have any.',
  ];

  /// Consigne du bas de plateau en mode libre.
  static String get freeModeHint => tr(
      'Touche une tuile. Assume ensuite ce qui va suivre.',
      'Tap a tile. Then own whatever happens next.');

  /// Indice de l'appui long.
  static String get leaveHint => tr(
      'Appui long sur un joueur : glisse pour le changer de place, '
          'relâche pour l\'éjecter de la table',
      'Long-press a player: drag to move them, '
          'let go to kick them off the table');

  /// Reproche quand on touche un joueur qui a déjà joué.
  static String alreadyPlayed(String name) => _fill(
        _pick(trList(const [
          '{name} a déjà joué. Et pas très bien.',
          '{name} est déjà passé. Une fois suffisait largement.',
          'C\'est fait pour {name}. On ne repasse pas les plats.',
          '{name} a eu sa chance. Il l\'a gâchée.',
        ], const [
          '{name} already played. Not very well, either.',
          '{name} already went. Once was more than enough.',
          '{name} is done. No second helpings.',
          '{name} had their chance. And blew it.',
        ])),
        name,
      );

  // ── Troisième échec ───────────────────────────────────────────────────────

  static String thirdMissTitle(String name) => _fill(
        _pick(trList(const [
          'Troisième échec. Bravo {name} 👏',
          '{name}, trois de suite. Un vrai talent.',
          'Et de trois, {name}. Impressionnant.',
        ], const [
          'Third miss. Well done {name} 👏',
          '{name}, three in a row. A real gift.',
          'And that\'s three, {name}. Impressive.',
        ])),
        name,
      );

  /// [lost] = points qui vont sauter, `null` si le joueur n'avait rien à perdre.
  static String thirdMissBody(String name, int? lost) {
    if (lost == null) {
      return tr(
          'Trois ratés d\'affilée. Heureusement pour toi, tu n\'avais '
              'strictement rien à perdre. Le vide reste le vide.',
          'Three misses in a row. Luckily for you, you had absolutely '
              'nothing to lose. Nothing stays nothing.');
    }
    return tr(
        'Trois ratés d\'affilée. Tu vas donc rendre gentiment tes $lost '
            'points, sous les yeux de tout le monde.\n\n'
            'Alors, on accepte sa défaite ?',
        'Three misses in a row. So you\'ll kindly hand back your $lost '
            'points, in front of everyone.\n\n'
            'So, accepting defeat?');
  }

  static String get thirdMissAccept => tr('J\'assume', 'I own it');
  static String get thirdMissCancel => tr('Pitié, non', 'Please, no');

  // ── Dépassement de l'objectif ─────────────────────────────────────────────

  static String get overshootTitle => tr('Tu sais compter ?', 'Can you count?');

  static String overshootBody(String name, int total, int target) => tr(
      'Ça mettrait $name à $total points. L\'objectif est $target.\n'
          'Pas $total. $target.\n\n'
          'Valide si tu veux : ce sera un échec, et toute la table l\'aura vu.',
      'That would put $name on $total points. The target is $target.\n'
          'Not $total. $target.\n\n'
          'Confirm if you like: it\'ll be a miss, and the whole table saw it.');

  static String get overshootAccept =>
      tr('Assumer la honte', 'Embrace the shame');
  static String get overshootCancel => tr('Je recompte', 'Let me recount');

  // ── Départ d'un joueur ────────────────────────────────────────────────────

  static String leaveTitle(String name) =>
      tr('On éjecte $name ?', 'Kick $name out?');

  static String leaveBody(String name) => tr(
      '$name ne jouera plus. Son score restera affiché au classement, comme '
          'une pierre tombale.\n\n'
          '(Tu pourras annuler avec la flèche « retour arrière », si la pitié te '
          'reprend.)',
      '$name won\'t play anymore. Their score will stay on the leaderboard, '
          'like a tombstone.\n\n'
          '(You can undo with the “back” arrow, if pity gets the better of '
          'you.)');

  static String get leaveAccept => tr('Qu\'il dégage', 'Get them out');
  static String get leaveCancel => tr('On le garde', 'Let them stay');

  // ── Rencontres ────────────────────────────────────────────────────────────

  /// Titre de l'alerte selon le nombre de joueurs percutés.
  static String encounterTitle(int count) {
    if (count >= 4) return tr('MASSACRE À LA TABLE', 'MASSACRE AT THE TABLE');
    if (count == 3) return tr('Carnage.', 'Carnage.');
    if (count == 2) return tr('Double ration !', 'Double helping!');
    return tr('Dans les dents !', 'Right in the teeth!');
  }

  /// Petite pique sous le titre de l'alerte de rencontre.
  static String encounterJibe(int count) => _pick(
        count >= 2
            ? trList(const [
                'Plusieurs vies gâchées d\'un coup. Du beau travail.',
                'Ça sent le règlement de comptes.',
                'Personne n\'avait rien demandé. Tant pis pour eux.',
                'On applaudit le carnage.',
              ], const [
                'Several lives ruined at once. Lovely work.',
                'Smells like a settling of scores.',
                'Nobody asked for this. Too bad for them.',
                'A round of applause for the carnage.',
              ])
            : trList(const [
                'Ça, ça va laisser des traces.',
                'Une belle collection de points, envolée.',
                'Le silence gêné, c\'est normal.',
                'Rien de personnel. Enfin si, un peu.',
              ], const [
                'That one\'s going to leave a mark.',
                'A lovely collection of points, gone.',
                'The awkward silence is normal.',
                'Nothing personal. Well, a little.',
              ]),
      );

  static String get encounterAck => tr('Savoure', 'Savor it');

  // ── Résultat ──────────────────────────────────────────────────────────────

  static String get victoryTitle => tr('GAGNÉ', 'WINNER');

  /// Commentaire sur le vainqueur.
  static String winnerLine(String name) => _fill(
        _pick(trList(const [
          '{name} gagne. Les autres existent encore, techniquement.',
          '{name} rafle tout. Personne n\'a vraiment lutté.',
          'Victoire de {name}. On feindra la surprise.',
          '{name} gagne, et compte bien vous le rappeler longtemps.',
        ], const [
          '{name} wins. The others still exist, technically.',
          '{name} takes it all. Nobody really put up a fight.',
          'Victory for {name}. We\'ll pretend to be surprised.',
          '{name} wins, and will be reminding you for a long time.',
        ])),
        name,
      );

  /// Le roast du bon dernier, affiché en bas du classement.
  static String loserLine(String name, int score) => _fill(
        _pick(trList(const [
          '{name} termine dernier avec {score} points. On ne rit pas. Enfin si.',
          'Bonnet d\'âne pour {name} : {score} points, et beaucoup d\'excuses.',
          '{name} ferme la marche à {score} points. Quelqu\'un devait le faire.',
          'Dernier : {name}, {score} points. La table s\'en souviendra.',
          '{name} finit à {score} points. Les dés n\'y sont pour rien.',
        ], const [
          '{name} finishes last with {score} points. We\'re not laughing. OK, we are.',
          'Dunce cap for {name}: {score} points, and plenty of excuses.',
          '{name} brings up the rear with {score} points. Someone had to.',
          'Last: {name}, {score} points. The table will remember.',
          '{name} ends on {score} points. The dice had nothing to do with it.',
        ])).replaceAll('{score}', '$score'),
        name,
      );

  /// Emoji qui remplace le totem du dernier au classement.
  static const String shameEmoji = '💩';

  // ── Faits marquants (palmarès de fin de partie) ───────────────────────────

  /// Titre de la section.
  static String get factsTitle =>
      tr('LE PALMARÈS DE LA HONTE', 'THE HALL OF SHAME');

  /// Libellés des faits. `{name}` et `{value}` sont remplis par l'écran de
  /// résultat ; `title` est le titre décerné, `line` le commentaire.
  static ({String emoji, String title, String line}) get factLoser => (
        emoji: '💸',
        title: tr('Le gros naze', 'The big loser'),
        line: tr('{name} a bradé {value} points en route.',
            '{name} threw away {value} points along the way.'),
      );
  static ({String emoji, String title, String line}) get factWrecker => (
        emoji: '💥',
        title: tr('La brute', 'The brute'),
        line: tr(
            '{name} a fracassé {value} adversaires en tombant pile dessus.',
            '{name} smashed {value} opponents by landing right on them.'),
      );
  static ({String emoji, String title, String line}) get factHit => (
        emoji: '🎯',
        title: tr('Le coup de bol', 'The lucky shot'),
        line: tr('{name} a sorti {value} points d\'un coup. Un accident.',
            '{name} scored {value} points in one go. An accident.'),
      );
  static ({String emoji, String title, String line}) get factMisses => (
        emoji: '🪦',
        title: tr('Le boulet', 'The dead weight'),
        line: tr('{name} a raté {value} tours. Un vrai métier.',
            '{name} missed {value} turns. A true professional.'),
      );

  /// Remplit un libellé de fait.
  static String fact(String template, String name, int value) =>
      _fill(template, name).replaceAll('{value}', '$value');
}
