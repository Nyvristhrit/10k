# Changelog — 10K

> Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/). Chaque
> Release GitHub (`gh release create vX.Y.Z`) correspond à une section ici — le
> fichier `10K.apk` de chaque Release est ce que télécharge la page
> [nyvristhrit.github.io/10k](https://nyvristhrit.github.io/10k/).
>
> Ce fichier fait aussi office de **note de contexte pour reprendre le
> projet** (humain ou agent IA) : voir aussi `docs/DECISIONS.md` (choix
> techniques justifiés), `docs/BACKLOG.md` (reste à faire) et
> `docs/SPECIFICATION.md` (règles du jeu détaillées).

## [v1.5.0] — 2026-09-04

### Corrigé
- **Dernière chance : la revanche n'existait pas.** La règle V1 (spec §16.4,
  Annexe C.5) posait qu'un candidat délogé « ne reçoit pas de nouveau tour »
  — un seul passage par joueur. Ben a précisé la règle réellement jouée à
  table : si A est délogé par B, puis que B n'est pas délogé par C, **A doit
  pouvoir retenter sa chance** contre B, et ainsi de suite sans limite.
  Chaque délogement relance désormais une manche complète de dernière chance
  pour tous les autres joueurs actifs (y compris le camp délogé) ; la phase
  ne se termine que quand un candidat traverse un tour complet sans être
  délogé. Voir DECISIONS A-012.

### Ajouté
- **Fenêtre « Quoi de neuf »** à l'ouverture de l'appli après une mise à
  jour : résume les nouveautés de(s) version(s) notable(s) manquée(s), une
  seule fois, jamais au tout premier lancement (rien à rattraper). Catalogue
  dédié (`whats_new_catalog.dart`), volontairement distinct de ce fichier :
  n'y figurent que les versions avec un changement visible pour un joueur,
  comme sur la page de téléchargement (même logique que pour v1.2.1, déjà
  exclue de la page publique).

### Modifié
- Page de téléchargement : le bouton « Offrir un café sur Ko-fi » était un
  simple lien discret, peu visible — devenu un vrai bouton (pilule rose,
  plus grand), à la demande de Ben. Le bouton équivalent dans l'appli
  (écran « À propos ») restait déjà bien visible, inchangé.

## [v1.4.0] — 2026-09-04

### Ajouté
- **Stats & records** (bouton sur l'accueil) : bilan calculé à partir de
  *toutes* les parties terminées conservées sur l'appareil — parties jouées,
  temps de jeu cumulé, tours joués, rencontres déclenchées, **manches
  moyennes par score cible** (5 000/10 000/15 000…), plus gros carton, partie
  la plus longue (`GameStats`, `lib/domain/services/game_stats.dart`).
- **Une partie terminée n'est plus jamais effacée automatiquement.** Avant
  cette évolution, `GameController.newGame` effaçait systématiquement la
  partie précédente (y compris terminée) dès qu'une nouvelle partie
  démarrait : l'historique ne pouvait donc jamais s'accumuler. Seules les
  parties **abandonnées** (encore en préparation ou en cours) sont
  désormais effacées — voir DECISIONS A-010.
- **Alias joueur** : un petit bouton sous le nom de chaque totem (écran de
  préparation) permet de fixer un alias stable (`@Ben`), distinct du nom
  tiré au hasard — avec une modalité de sélection rapide parmi les alias déjà
  utilisés. Les statistiques utilisent l'alias en priorité sur le totem du
  jour, qui n'a sinon aucune valeur d'une partie à l'autre.
- **Écran « Alias & profils »** (icône à côté du « ? » sur l'accueil) :
  liste chaque alias avec son nombre de victoires ; permet de le renommer
  (répercuté automatiquement sur tout l'historique des parties), de lui
  choisir une couleur perso, de le supprimer, ou d'en créer un nouveau
  directement depuis cet écran.

### Corrigé
- **Dés marron/olive ratés selon la teinte tirée** (la palette aléatoire
  ajoutée en v1.3.3) : le noir utilisé pour assombrir la face (trash) et
  l'encre des points (sage) n'était pas strictement neutre (légère teinte
  bleu-violet) — mélangé à un orange ou un jaune, ça tournait au
  marron/caca d'oie. Remplacé par un noir strictement neutre partout (voir
  DECISIONS A-011).

## [v1.3.3] — 2026-09-04

> Plusieurs allers-retours le même jour (builds `+2` à `+5`) — la version
> publique reste `1.3.3` du début à la fin, seul le contenu a évolué.

### Ajouté
- **Réglage « Dés dans l'appli »** (Réglages → Dés) : permet de masquer
  l'icône 🎲 du plateau quand on joue avec de vrais dés. Réglage général,
  mémorisé, activé par défaut.
- **Teinte aléatoire du plateau de dés** : à chaque ouverture, une couleur
  tirée dans la palette sage ou trash (dés roses, violets, cyan…), comme
  l'accent général de l'appli — tapis et faces des dés en dégradé.

### Corrigé
- **Noms de joueur tronqués** (mode trash surtout, où espèce + épithète
  cumulent) : le nom sur la tuile était coupé en plein mot avec des « ... »
  sur les écrans où la tuile est étroite, jusqu'à 34 caractères dans le pire
  cas (ex. « Blaireau d'Europe Raclure de bidet »). La tuile
  (`player_board_tile.dart`) rétrécit maintenant le texte pour qu'il tienne
  en entier (`FittedBox`) au lieu de le tronquer — verrouillé par un test
  dédié.
- **Halo du joueur actif peu visible** : bordure plus épaisse, jamais trop
  pâle, halo plus large et plus intense — on passait facilement à côté pour
  repérer qui doit jouer.

### Modifié
- **Catalogue resserré** : suppression des variantes d'espèces et
  d'épithètes les plus longues quand une alternative plus courte existait
  déjà dans la même famille (ex. « Blaireau d'Europe » → « Blaireau »,
  « Superstitieux·se » retirée du pool sage) — le pire cas passe de 34 à 29-31
  caractères. Le `FittedBox` ci-dessus reste la protection définitive contre
  tout mot encore trop long.
- « Raclure de bidet » remplacée par « Relou » dans le catalogue trash (Ben).

## [v1.3.2] — 2026-09-04

### Corrigé
- Onglet « À propos » : la version affichait le numéro de build technique
  entre parenthèses (« Version 1.3.1 (2) ») en plus du numéro de version —
  confusant, sans utilité pour le joueur. N'affiche plus que « Version
  1.3.2 ».

## [v1.3.1] — 2026-09-04

### Ajouté
- **Lien de soutien (Ko-fi)** : carte « Envie de soutenir le projet ? » dans
  l'onglet « À propos » de l'appli (ouvre `ko-fi.com/qubestudio` dans le
  navigateur via `url_launcher`), et lien discret sous le bouton de
  téléchargement sur la page GitHub Pages. Purement facultatif, aucune
  donnée envoyée par ailleurs — cohérent avec le « 100 % hors ligne ».

### Modifié
- **Poids des épithètes perso (mode trash)** : les épithètes ajoutées à la
  table dans les réglages comptent maintenant **deux fois** dans le tirage
  du nom par défaut, face au catalogue de base (`GameEngine._scoutName`,
  dupliquées dans le pool avant tirage — verrouillé par un test dédié).
  Avant ce correctif, elles se noyaient dans les ~70 épithètes du catalogue
  et sortaient trop rarement.
- **Catalogue d'épithètes trash retravaillé par Ben** (`adjective_catalog.dart`) :
  liste resserrée (les personnalisées sortent d'autant plus souvent grâce au
  poids double ci-dessus) et ton plus mordant. Le catalogue sage est passé à
  une écriture inclusive (`·`).

## [v1.3.0] — 2026-09-04

### Ajouté
- **Historique de la partie** : une icône 🕐 sur le plateau ouvre la liste de
  tous les coups joués, groupés par manche (la plus récente en haut, la
  manche 1 en bas) et classés du plus récent au plus ancien dans chaque
  manche — comme un fil d'actualité. Toucher un coup passé propose d'y
  revenir exactement : tout ce qui a suivi est annulé, un coup à la fois, en
  réutilisant l'annulation atomique déjà testée du moteur
  (`GameController.revertToAction`, `lib/features/game_board/game_history_screen.dart`).
- **Plateau de dés virtuel** : une icône 🎲 sur le plateau ouvre un tapis avec
  6 dés animés (relief en dégradé, tremblement et défilement des faces au
  lancer, dessinés à la main en `CustomPainter` — aucun package graphique).
  On lance, on touche les dés à garder de côté, puis on relance le reste —
  pour jouer même sans dés physiques sous la main
  (`lib/features/dice_tray/dice_tray_screen.dart`). L'appli ne calcule rien à
  la place du joueur : le score se saisit toujours normalement sur le
  plateau.

## [v1.2.1] — 2026-08-19

### Corrigé
- Éditeur d'épithètes trash (réglages) : le texte d'aide et le champ de
  saisie avaient le même style visuel, sans bordure ni fond distinct → perçu
  comme un seul bloc de texte non interactif (« impossible d'écrire dedans »).
  Le champ a maintenant une bordure nette, un fond contrasté et un texte
  d'aide raccourci pour ne plus se confondre avec l'explication au-dessus.

## [v1.2.0] — 2026-08-19

### Corrigé
- Page de téléchargement : le logo « 10K » utilisait un dégradé CSS
  (`background-clip:text`) peu fiable selon les navigateurs → remplacé par un
  SVG. Deux passes de réglage ont suivi : l'angle des bandes suivait la boîte
  du texte au lieu du cadre du logo (corrigé en `gradientUnits=userSpaceOnUse`
  sur les coordonnées du viewBox), et la graisse semblait plus fine que dans
  l'appli (Space Grotesk n'a pas d'instance 900 sur le web, contrairement à la
  graisse simulée par Flutter → ajout d'un contour épais).
- Page de téléchargement : les 3 étapes d'installation s'affichaient en
  colonnes illisibles (bug flexbox : un `<span>` sans `flex:1` se resserrait
  au lieu de remplir la ligne).

### Modifié
- Éditeur d'épithètes trash (réglages, mode trash actif) : texte d'aide plus
  explicite sur le format attendu (une épithète à la fois, bouton « + »),
  compteur affiché, **plafonné à 20** épithètes perso (garde-fou aussi côté
  contrôleur, pas seulement l'UI).

## [v1.1.0] — 2026-08-19

### Corrigé
- **Bug de régression (F-003)** : une rencontre qui vide entièrement la pile
  d'un joueur (retour à 0, façon 3ᵉ échec) ne restaurait plus ses vies à 3.
  Le correctif du 1ᵉʳ août avait supprimé la restauration des vies pour
  *toutes* les rencontres (bon pour une touche partielle) au lieu de la
  garder pour le cas où la pile se vide entièrement.

### Ajouté
- **Toggle du mode trash rendu visible** : la carte de dédicace (onglet « À
  propos ») porte désormais un liseré néon + une pastille « RETAPE ×7 » une
  fois le mode actif (un ami de Ben ne retrouvait pas où retaper pour
  désactiver).
- **Noms par défaut façon totem scout** : « Espèce + Épithète » (ex.
  « Bouvreuil Facétieux »), ~80 épithètes sages et ~65 trash
  (`data/catalogs/adjective_catalog.dart`). Éditeur d'épithètes perso dans les
  réglages, visible en mode trash.
- **Écran toujours allumé pendant la partie**, réglable dans les paramètres
  (économie de batterie) — package `wakelock_plus`. A nécessité de
  contourner un bug Kotlin/Windows (`kotlin.incremental=false`, voir
  DECISIONS A-008 : le projet est sur `D:\`, le cache pub sur `C:\`, deux
  lecteurs différents que le compilateur Kotlin ne sait pas comparer).
- **Mode paysage** débloqué et adapté (accueil, plateau avec grille/vedette
  réorientée, écran de résultat) — pour un usage sur tablette. Portrait
  restait auparavant verrouillé (un bug de débordement en paysage, sur
  l'ancienne version, avait motivé ce verrouillage).
- **Mise à disposition publique** : dépôt GitHub
  ([Nyvristhrit/10k](https://github.com/Nyvristhrit/10k), public), page de
  téléchargement GitHub Pages (`docs/index.html`, servie depuis `main:/docs`)
  qui pointe vers `.../releases/latest/download/10K.apk` — ce lien reste
  valable d'une Release à l'autre tant que l'asset s'appelle `10K.apk`.

## Avant les Releases GitHub (pas de version taguée)

Développement initial (juillet–août 2026), résumé — voir l'historique Git
pour le détail commit par commit :
- Moteur de jeu (Dart pur, testé), toutes les règles du 10 000 dont les
  variantes dictées par Ben (sombrero malgache, suites, brelan/carré/main
  pleine).
- Persistance locale (fichiers JSON), écrans accueil / préparation / plateau
  / résultat / réglages / règles.
- Rencontres en cascade (BFS, plusieurs joueurs percutés en chaîne), alertes
  de rencontre à valider, variantes d'espèces pour les noms d'animaux.
- **Mode « trash »** : seconde personnalité de l'appli (néon, cœurs devenus
  flammes vertes, piques), déblocable en secret (7 tapes sur la dédicace).
- Passes de direction artistique successives (dégradés, halos, police Space
  Grotesk embarquée, thème clair/sombre, palmarès de fin de partie, icône
  d'appli dessinée en code).

---

## Comment publier une nouvelle version (rappel pour la suite)

0. **Bumper `version:` dans `pubspec.yaml`** (ex. `1.3.1+2` → `1.3.2+3`) —
   c'est ce numéro qui atterrit dans l'APK (`versionName`/`versionCode`
   Android) et que l'onglet « À propos » affiche (lu dynamiquement via
   `package_info_plus`, voir commit du 4 sept. 2026). L'oublier désynchronise
   la version affichée dans l'appli du tag Git/de la Release GitHub — c'est
   arrivé une fois (resté à `1.0.0+1` jusqu'à la v1.3.1), à ne pas reproduire.
1. `flutter build apk --release`, `flutter install -d <device-id>` pour tester
   sur le Pixel de Ben.
2. Copier l'APK à la racine du dépôt : `cp build/app/outputs/flutter-apk/app-release.apk 10K.apk`
   (ce fichier est gitignoré — jamais commité, seulement diffusé via les
   Releases).
3. `gh release create vX.Y.Z "10K.apk#10K.apk" --repo Nyvristhrit/10k --title "10K vX.Y.Z" --notes "..."`
   — **l'asset doit impérativement s'appeler `10K.apk`** (le lien de la page
   de téléchargement est câblé sur ce nom exact).
4. Ajouter une section ici (CHANGELOG.md) avec les changements — **toujours**,
   même pour un correctif mineur.
5. Mettre à jour `docs/index.html` : la pastille `.version-pill` (numéro de
   version, toujours à jour avec la dernière Release). Le bloc `.changelog`
   affiché sur la page, en revanche, **n'est pas censé lister chaque
   version** : seulement les versions avec un changement notable pour un
   joueur (nouvelle fonctionnalité, bug visible corrigé). Un correctif
   mineur/cosmétique (ex. v1.2.1) reste dans ce fichier et l'historique Git,
   mais ne mérite pas sa propre entrée sur la page publique — sinon la liste
   s'allonge trop vite. Dans le doute, ne pas ajouter d'entrée sur la page.
6. Si l'étape 5 ajoute une entrée : ajouter la **même** entrée à
   `lib/data/catalogs/whats_new_catalog.dart` (`WhatsNewCatalog.releases`,
   dans l'ordre chronologique, la plus récente en dernier). C'est ce
   catalogue qui alimente la fenêtre « Quoi de neuf » montrée dans l'appli à
   l'ouverture après une mise à jour — les deux listes doivent rester en
   phase. Un joueur qui a sauté plusieurs versions d'affilée voit
   l'historique complet des versions notables manquées, pas seulement la
   dernière (voir `HomeScreen._maybeShowWhatsNew`).
7. `gh` est déjà installé et authentifié sur la machine de Ben (compte
   GitHub `Nyvristhrit`, jeton dans le trousseau Windows) — pas besoin de
   relancer `gh auth login`, sauf expiration.
