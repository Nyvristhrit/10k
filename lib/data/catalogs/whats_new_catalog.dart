import '../../l10n/l10n.dart';

/// Une version notable et ses nouveautés visibles pour le joueur.
///
/// À garder en phase avec le bloc `.changelog` de `docs/index.html` (et `docs/en/`).
class WhatsNewRelease {
  const WhatsNewRelease(
      {required this.version, required this.items, required this.itemsEn});

  /// Numéro de version (`X.Y.Z`), sans le `v` — comparé terme à terme.
  final String version;

  /// Nouveautés en français.
  final List<String> items;

  /// Les mêmes nouveautés, en anglais.
  final List<String> itemsEn;

  /// Les nouveautés dans la langue de l'interface.
  List<String> get localizedItems => trList(items, itemsEn);
}

class WhatsNewCatalog {
  /// Du plus ancien au plus récent.
  static const List<WhatsNewRelease> releases = [
    WhatsNewRelease(version: '1.1.0', itemsEn: [
      'Fix: lives are properly restored to 3 when an encounter completely empties a player\'s stack.',
      'Trash mode toggle made easier to spot.',
      'Scout-style default player names (species + epithet), with a custom epithet editor in trash mode.',
      'Screen stays on during the game (can be turned off).',
      'Landscape mode for tablets.',
    ], items: [
      'Correction : les vies se restaurent bien à 3 quand une rencontre vide entièrement la pile d\'un joueur.',
      'Toggle du mode trash rendu plus visible.',
      'Noms de joueur par défaut façon totem scout (espèce + épithète), avec éditeur d\'épithètes perso en mode trash.',
      'Écran toujours allumé pendant la partie (réglable).',
      'Mode paysage pour utilisation sur tablette.',
    ]),
    WhatsNewRelease(version: '1.2.0', itemsEn: [
      'Trash epithet editor (settings) made clearer and capped at 20.',
      'Visual fixes on the download page (logo, landscape mode).',
    ], items: [
      'Éditeur d\'épithètes trash (réglages) clarifié et plafonné à 20.',
      'Corrections visuelles de la page de téléchargement (logo, mode paysage).',
    ]),
    WhatsNewRelease(version: '1.3.0', itemsEn: [
      'Game history: browse every move round by round, and go back in time by tapping one of them.',
      'Built-in virtual dice tray: roll, keep and re-roll dice right in the app if you don\'t have any at hand.',
    ], items: [
      'Historique de la partie : consulte tous les coups joués manche par manche, et reviens en arrière en touchant l\'un d\'eux.',
      'Plateau de dés virtuel intégré : lance, garde et relance des dés directement dans l\'appli si tu n\'en as pas sous la main.',
    ]),
    WhatsNewRelease(version: '1.3.3', itemsEn: [
      'Fix: long player names (especially in trash mode) were cut mid-word — the text now shrinks to fit entirely on the tile.',
      'The glow around the player whose turn it is is more visible.',
      'New setting to hide the built-in dice if you play with real ones; they also get a random color each time.',
    ], items: [
      'Correction : les noms de joueur trop longs (surtout en mode trash) n\'étaient plus coupés en plein mot — le texte rétrécit désormais pour tenir en entier sur la tuile.',
      'Le halo du joueur dont c\'est le tour est plus visible.',
      'Nouveau réglage pour masquer les dés intégrés si tu joues avec de vrais dés, qui adoptent aussi une teinte aléatoire à chaque ouverture.',
    ]),
    WhatsNewRelease(version: '1.4.0', itemsEn: [
      'New “Stats & records” screen: games played, total play time, average rounds per target score, biggest score…',
      'Player aliases (kept from one game to the next) and an “Aliases & profiles” screen: wins per person, custom color, renaming.',
    ], items: [
      'Nouvel écran « Stats & records » : parties jouées, temps de jeu cumulé, manches moyennes par score cible, plus gros carton…',
      'Alias de joueur (stable d\'une partie à l\'autre) et écran « Alias & profils » : victoires par personne, couleur perso, renommage.',
    ]),
    WhatsNewRelease(version: '1.5.0', itemsEn: [
      'Last chance: a dislodged player can now try again and dislodge the opponent back — unlimited rematches, until a candidate survives a full round without being dislodged.',
      'This “What\'s new” window: a summary of new features shows up automatically after an update.',
    ], items: [
      'Dernière chance : un joueur délogé peut désormais retenter sa chance et redéloger l\'adversaire — la revanche est illimitée, jusqu\'à ce qu\'un candidat traverse un tour complet sans se faire déloger.',
      'Cette fenêtre « Quoi de neuf » : un résumé des nouveautés s\'affiche automatiquement après une mise à jour.',
    ]),
    WhatsNewRelease(version: '1.6.0', itemsEn: [
      'Fixed a real encounter bug: a third miss could drop a player exactly onto another player\'s score without triggering an encounter (both players then stayed stuck on the same total).',
      'An encounter now always gives the victim 3 lives back, even without fully emptying their stack.',
      'Long player names are now cut with “…” instead of shown in tiny letters.',
      'The virtual dice tray now shows 5 dice (instead of 6), and the pips stay readable whatever the color drawn.',
      'Default name epithets (e.g. “Loser”, “Prankster”) no longer repeat between two players of the same game.',
    ], items: [
      'Correction d\'un vrai bug de rencontre : un troisième échec pouvait faire retomber un joueur exactement sur le score d\'un autre sans déclencher de rencontre (deux joueurs restaient alors bloqués au même total).',
      'Une rencontre redonne désormais toujours 3 vies à la victime, même sans vider complètement sa pile.',
      'Les noms de joueur trop longs sont maintenant tronqués par « … » plutôt qu\'affichés en tout petit.',
      'Le plateau de dés virtuel affiche bien 5 dés (au lieu de 6), et la couleur des points reste lisible quelle que soit la teinte tirée.',
      'Les épithètes des noms par défaut (ex. « Tocard », « Farceur ») ne se répètent plus entre deux joueurs de la même partie.',
    ]),
    WhatsNewRelease(version: '1.7.0', itemsEn: [
      'Move a player to another seat mid-game: long-press their tile, then drag it onto another player to take their place. Released without moving, it still offers to make them leave the game.',
      'Total play time in the stats is fixed: it no longer counts setup or long breaks (a game left open until the next day…).',
      'The hidden mode becomes even more… fragrant. 💩',
    ], items: [
      'Change un joueur de place en pleine partie : appui long sur sa tuile, puis glisse-la sur un autre joueur pour prendre sa place. Relâchée sans bouger, elle propose toujours de faire quitter la partie.',
      'Le temps de jeu cumulé des stats est corrigé : il ne compte plus la préparation ni les longues pauses (partie laissée ouverte jusqu\'au lendemain…).',
      'Le mode caché devient encore plus… parfumé. 💩',
    ]),
    WhatsNewRelease(version: '1.7.1', itemsEn: [
      'The app rules now explain how to move a player to another seat (long-press their tile, then drag).',
      'The hidden mode smells even stronger: real sound effects, stains that turn into camouflage… and the phone icon switching to its colors.',
    ], items: [
      'Les règles de l\'appli expliquent maintenant comment changer un joueur de place (appui long sur sa tuile, puis glisser).',
      'Le mode caché sent encore plus fort : de vrais bruitages, des taches qui tournent au camouflage… et l\'icône du téléphone qui se met à ses couleurs.',
    ]),
    WhatsNewRelease(version: '1.8.0', items: [
      'L\'appli parle anglais ! Touche « EN » en haut de l\'accueil pour passer en anglais, « FR » pour revenir en français.',
    ], itemsEn: [
      'The app now speaks English! Tap “EN” at the top of the home screen to switch to English, “FR” to go back to French.',
    ]),
  ];

  /// Les versions postérieures à [seenVersion], des plus anciennes aux plus
  /// récentes.
  static List<WhatsNewRelease> since(String seenVersion) {
    return releases.where((r) => _compare(r.version, seenVersion) > 0).toList();
  }

  /// Compare deux versions `X.Y.Z` numériquement terme à terme (un terme
  /// manquant ou invalide vaut 0).
  static int _compare(String a, String b) {
    final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }
}
