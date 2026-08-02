import 'dart:math';

/// Banque de textes du **mode trash** (déblocable en tapant 7 fois la carte de
/// dédicace de l'écran « À propos », façon options développeur d'Android).
///
/// Le mode trash ne change **aucune règle** : uniquement le ton et l'habillage.
/// L'appli passe de « compagnon bienveillant » à « commentateur odieux ».
/// On chambre les joueurs comme à une vraie table entre potes : c'est piquant,
/// jamais méchant sur ce qu'ils sont — uniquement sur la façon dont ils jouent.
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
  static const String tagline = 'Le 10 000, sans la politesse';

  /// Emojis qui pleuvent en fond d'accueil (au lieu du seul dé).
  static const List<String> fallingEmojis = ['🎲', '💀', '🔥', '💩', '☠️', '🤡'];

  /// Ce qui remplace les cœurs dans les jauges de vie.
  static const String lifeEmoji = '💉';

  // ── Déblocage (compteur de tapes) ─────────────────────────────────────────

  /// Nombre de tapes sur la carte de dédicace pour basculer le mode.
  static const int unlockTaps = 7;

  /// Message d'étape affiché pendant le comptage, ou `null` s'il n'y a rien à
  /// dire (trop tôt, ou c'est la tape finale — l'appelant gère la bascule).
  ///
  /// [taps] est le nombre de tapes déjà effectuées, [active] l'état courant du
  /// mode trash (on annonce alors une extinction plutôt qu'un déblocage).
  static String? unlockHint(int taps, {required bool active}) {
    final left = unlockTaps - taps;
    if (left <= 0 || left > 3) return null;
    if (active) {
      return left == 1
          ? 'Encore 1 et on redevient poli.'
          : 'Plus que $left avant de retrouver les bonnes manières.';
    }
    return left == 1
        ? 'Encore 1. Tu vas le regretter.'
        : 'Plus que $left avant que ça dégénère.';
  }

  /// Texte de l'écran de bascule.
  static const String unlockedTitle = 'MODE TRASH ACTIVÉ';
  static const String unlockedBody =
      'Les règles ne changent pas. Le ton, si.\n'
      'L\'appli va désormais commenter vos performances. Sans filtre, et sans '
      'la moindre bienveillance.\n\n'
      'Pour revenir à la version fréquentable : retape 7 fois la même carte.';
  static const String lockedTitle = 'Retour à la civilisation';
  static const String lockedBody =
      'L\'appli redevient polie. C\'était bien tenté.';

  /// Bandeau affiché dans « À propos » tant que le mode est actif.
  static const String activeBanner =
      'Mode trash actif. Les joueurs sont prévenus (ou pas).';

  // ── Plateau : phrase du joueur actif ──────────────────────────────────────

  /// Phrases du joueur dont c'est le tour. `{name}` = nom affiché.
  static const List<String> turnPhrases = [
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

  /// Consigne du bas de plateau en mode libre.
  static const String freeModeHint =
      'Touche une tuile. Assume ensuite ce qui va suivre.';

  /// Indice de l'appui long.
  static const String leaveHint =
      'Appui long sur un joueur pour l\'éjecter de la table';

  /// Reproche quand on touche un joueur qui a déjà joué.
  static String alreadyPlayed(String name) => _fill(
        _pick(const [
          '{name} a déjà joué. Et pas très bien.',
          '{name} est déjà passé. Une fois suffisait largement.',
          'C\'est fait pour {name}. On ne repasse pas les plats.',
          '{name} a eu sa chance. Il l\'a gâchée.',
        ]),
        name,
      );

  // ── Troisième échec ───────────────────────────────────────────────────────

  static String thirdMissTitle(String name) => _fill(
        _pick(const [
          'Troisième échec. Bravo {name} 👏',
          '{name}, trois de suite. Un vrai talent.',
          'Et de trois, {name}. Impressionnant.',
        ]),
        name,
      );

  /// [lost] = points qui vont sauter, `null` si le joueur n'avait rien à perdre.
  static String thirdMissBody(String name, int? lost) {
    if (lost == null) {
      return 'Trois ratés d\'affilée. Heureusement pour toi, tu n\'avais '
          'strictement rien à perdre. Le vide reste le vide.';
    }
    return 'Trois ratés d\'affilée. Tu vas donc rendre gentiment tes $lost '
        'points, sous les yeux de tout le monde.\n\n'
        'Alors, on accepte sa défaite ?';
  }

  static const String thirdMissAccept = 'J\'assume';
  static const String thirdMissCancel = 'Pitié, non';

  // ── Dépassement de l'objectif ─────────────────────────────────────────────

  static const String overshootTitle = 'Tu sais compter ?';

  static String overshootBody(String name, int total, int target) =>
      'Ça mettrait $name à $total points. L\'objectif est $target.\n'
      'Pas $total. $target.\n\n'
      'Valide si tu veux : ce sera un échec, et toute la table l\'aura vu.';

  static const String overshootAccept = 'Assumer la honte';
  static const String overshootCancel = 'Je recompte';

  // ── Départ d'un joueur ────────────────────────────────────────────────────

  static String leaveTitle(String name) => 'On éjecte $name ?';

  static String leaveBody(String name) =>
      '$name ne jouera plus. Son score restera affiché au classement, comme '
      'une pierre tombale.\n\n'
      '(Tu pourras annuler avec la flèche « retour arrière », si la pitié te '
      'reprend.)';

  static const String leaveAccept = 'Qu\'il dégage';
  static const String leaveCancel = 'On le garde';

  // ── Rencontres ────────────────────────────────────────────────────────────

  /// Titre de l'alerte selon le nombre de joueurs percutés.
  static String encounterTitle(int count) {
    if (count >= 4) return 'MASSACRE À LA TABLE';
    if (count == 3) return 'Carnage.';
    if (count == 2) return 'Double ration !';
    return 'Dans les dents !';
  }

  /// Petite pique sous le titre de l'alerte de rencontre.
  static String encounterJibe(int count) => _pick(
        count >= 2
            ? const [
                'Plusieurs vies gâchées d\'un coup. Du beau travail.',
                'Ça sent le règlement de comptes.',
                'Personne n\'avait rien demandé. Tant pis pour eux.',
                'On applaudit le carnage.',
              ]
            : const [
                'Ça, ça va laisser des traces.',
                'Une belle collection de points, envolée.',
                'Le silence gêné, c\'est normal.',
                'Rien de personnel. Enfin si, un peu.',
              ],
      );

  static const String encounterAck = 'Savoure';

  // ── Résultat ──────────────────────────────────────────────────────────────

  static const String victoryTitle = 'GAGNÉ';

  /// Commentaire sur le vainqueur.
  static String winnerLine(String name) => _fill(
        _pick(const [
          '{name} gagne. Les autres existent encore, techniquement.',
          '{name} rafle tout. Personne n\'a vraiment lutté.',
          'Victoire de {name}. On feindra la surprise.',
          '{name} gagne, et compte bien vous le rappeler longtemps.',
        ]),
        name,
      );

  /// Le roast du bon dernier, affiché en bas du classement.
  static String loserLine(String name, int score) => _fill(
        _pick(const [
          '{name} termine dernier avec {score} points. On ne rit pas. Enfin si.',
          'Bonnet d\'âne pour {name} : {score} points, et beaucoup d\'excuses.',
          '{name} ferme la marche à {score} points. Quelqu\'un devait le faire.',
          'Dernier : {name}, {score} points. La table s\'en souviendra.',
          '{name} finit à {score} points. Les dés n\'y sont pour rien.',
        ]).replaceAll('{score}', '$score'),
        name,
      );

  /// Emoji qui remplace le totem du dernier au classement.
  static const String shameEmoji = '💩';

  // ── Faits marquants (palmarès de fin de partie) ───────────────────────────

  /// Titre de la section.
  static const String factsTitle = 'LE PALMARÈS DE LA HONTE';

  /// Libellés des faits. `{name}` et `{value}` sont remplis par l'écran de
  /// résultat ; `title` est le titre décerné, `line` le commentaire.
  static const factLoser = (
    emoji: '💸',
    title: 'Le gros naze',
    line: '{name} a bradé {value} points en route.',
  );
  static const factWrecker = (
    emoji: '💥',
    title: 'La brute',
    line: '{name} a fracassé {value} adversaires en tombant pile dessus.',
  );
  static const factHit = (
    emoji: '🎯',
    title: 'Le coup de bol',
    line: '{name} a sorti {value} points d\'un coup. Un accident.',
  );
  static const factMisses = (
    emoji: '🪦',
    title: 'Le boulet',
    line: '{name} a raté {value} tours. Un vrai métier.',
  );

  /// Remplit un libellé de fait.
  static String fact(String template, String name, int value) =>
      _fill(template, name).replaceAll('{value}', '$value');
}
