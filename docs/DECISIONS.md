# Décisions

Choix techniques et fonctionnels du projet, avec leur raison. Les identifiants
(D-xxx, F-xxx, A-xxx) sont cités dans le code : ne pas les renommer.

Toute modification d'une règle du jeu doit aussi mettre à jour
`SPECIFICATION.md`.

## Projet (D)

### D-001 · Nom de package Dart : `tenk`
- Choix : le package s'appelle `tenk` ; le nom affiché reste « 10K ».
- Pourquoi : Dart interdit un nom de package qui commence par un chiffre.

### D-002 · Environnement de développement sans Android Studio
- Choix : Flutter stable, SDK Android installé via l'outil en ligne de commande
  de Google, JDK Temurin 17.
- Pourquoi : installation plus légère, l'IDE complet n'est pas nécessaire.
- Note : le chemin du SDK Flutter contient un espace, ce que Flutter tolère.

### D-003 · Android uniquement
- Choix : projet créé avec `--platforms=android`.
- Pourquoi : la V1 vise un APK Android. Les autres plateformes peuvent être
  ajoutées plus tard.

### D-004 · Catalogue animal partiel
- Choix : `AnimalCatalog` contient environ 85 identités sur les 137 de
  l'annexe A de la spec.
- Pourquoi : suffisant pour la logique et les tests. Compléter la liste est
  une simple tâche de données.

## Règles du jeu (F)

F-001 à F-004 sont des choix par défaut pris quand la spec était ambiguë.
Ils sont isolés dans le moteur et peuvent être revus.

### F-001 · Victimes d'une rencontre : liste figée
- Choix : la liste des adversaires touchés est calculée avant toute
  annulation, puis appliquée.
- Pourquoi : résultat prévisible, aucune annulation ne modifie la liste.
- Depuis : la réaction en chaîne a été activée par défaut
  (`encounterChainsEnabled`, spec §14.5). Une victime qui redescend sur le
  score d'un autre joueur déclenche une nouvelle rencontre.

### F-002 · Rencontre pendant la dernière chance
- Choix : la rencontre s'applique à tout score pendant la dernière chance.
- Pourquoi : la spec (§16.4) dit que la rencontre continue de s'appliquer.
- Voir A-012 pour la revanche après un délogement.

### F-003 · Une rencontre redonne toujours 3 vies
- Choix : la victime retrouve ses 3 vies, que sa pile soit vidée ou non.
  Implémenté dans `GameEngine._resolveEncounters`.
- Pourquoi : c'est la règle jouée par le groupe. Le choix initial (vies
  restaurées seulement si la pile est vidée) a été abandonné en v1.6.0.

### F-004 · Égalité au classement final
- Choix : deux perdants à égalité sont classés dans l'ordre autour de la
  table (`seatIndex` croissant).
- Pourquoi : non précisé par la spec ; critère stable et neutre.

### F-005 · Le troisième échec vérifie aussi les rencontres
- Choix : `_applyMiss` appelle `_resolveEncounters` après avoir annulé un
  gain, avec le même chaînage que pour un score validé.
- Pourquoi : un 3ᵉ échec pouvait faire retomber un joueur sur le score d'un
  adversaire sans déclencher de rencontre (deux joueurs bloqués au même
  score). Corrigé en v1.6.0, couvert par un test.

### F-006 · Épithètes trash adoucies et modifiables
- Choix : liste par défaut sans grossièretés ; la liste complète est stockée
  dans `settings.json` (`trashAdjectives`) et modifiable (retirer, ajouter
  jusqu'à 100, rétablir). Le moteur pioche uniquement dans cette liste.
- Pourquoi : le Play Store exige de déclarer tout le contenu de l'appli, même
  caché. Les anciennes insultes posaient problème.
- Migration : les ajouts perso d'avant la v1.6.1 (`customTrashAdjectives`)
  sont ajoutés à la suite de la nouvelle liste.
- Les piques (`trash_taunts.dart`) restent inchangées : elles chambrent sans
  grossièreté.

### F-007 · Un alias peut imposer sa couleur à la tuile
- Choix : le nuancier des profils propose les 12 couleurs de tuile. L'option
  « Appliquer à ma tuile » (`AliasProfile.applyToTile`, désactivée par
  défaut) donne la couleur du profil à la tuile, en échangeant avec le joueur
  qui l'avait.
- Pourquoi : certains joueurs veulent retrouver leur couleur à chaque partie,
  sans perdre le tirage aléatoire pour les autres.
- Les anciens profils sont ramenés à la couleur de tuile la plus proche
  (`ColorCatalog.tileForArgb`).

## Architecture (A)

### A-001 · À la reprise, le snapshot fait foi
- Choix : au chargement, l'état sauvegardé est utilisé tel quel. Rejouer le
  journal sert uniquement de test d'invariant.
- Pourquoi : chargement rapide, pas de divergence entre journal et état.

### A-002 · Annulation par valeurs stockées
- Choix : chaque `GameEffect` stocke `previousValue` et `nextValue` ;
  l'annulation réapplique les anciennes valeurs.
- Pourquoi : fiable même pour les actions complexes (rencontre multiple,
  dernière chance).

### A-003 · Chaque joueur porte sa pile de gains
- Choix : `Player` contient directement sa `List<Gain>` ; le score est la
  somme des gains actifs.
- Pourquoi : moteur plus simple, score calculé localement.

### A-004 · Résolveurs regroupés dans le moteur
- Choix : tours, rencontres et dernière chance sont des méthodes privées de
  `GameEngine`.
- Pourquoi : plus lisible pour la V1. Extraction possible sans changer l'API.

### A-005 · Annulation via effets réversibles
- Choix : chaque modification (vies, gains, statut, manche, dernière chance)
  émet un `GameEffect`. `UndoLastAction` rejoue les effets à l'envers.
- Pourquoi : annulation atomique et détail disponible pour l'historique.
- Limite : `maxLives` vaut 3 dans le moteur.

### A-006 · Persistance en fichiers JSON
- Choix : une partie = un fichier `<documents>/games/<id>.json`. Écriture
  atomique (fichier temporaire puis renommage).
- Pourquoi : plus simple que Drift/SQLite, sans génération de code, testable
  hors appareil. La spec autorise une solution locale équivalente.

### A-007 · `path_provider_android` bloqué en 2.2.x
- Choix : `dependency_overrides: path_provider_android: ">=2.2.0 <2.3.0"`.
- Pourquoi : la 2.3.x dépend de `jni`, qui casse le build Gradle. À retirer
  quand ce sera corrigé.

### A-008 · `kotlin.incremental=false`
- Choix : compilation Kotlin non incrémentale (`android/gradle.properties`).
- Pourquoi : bug du compilateur Kotlin sous Windows quand le projet (`D:\`)
  et le cache pub (`C:\`) sont sur deux lecteurs différents. Coût : build un
  peu plus lent.

### A-009 · Distribution via GitHub Releases et GitHub Pages
- Choix : chaque version est une Release `vX.Y.Z` avec un asset nommé
  exactement `10K.apk`. La page `docs/index.html` (GitHub Pages, branche
  `main`, dossier `/docs`) pointe vers `releases/latest/download/10K.apk`.
- Pourquoi : gratuit, rien à héberger, et le lien reste valable d'une version
  à l'autre.
- Procédure : voir la fin de `CHANGELOG.md`.

### A-010 · Les parties terminées sont conservées
- Choix : une nouvelle partie n'efface que les parties abandonnées (en
  préparation ou en cours). Les parties terminées restent sur l'appareil.
- Pourquoi : nécessaire pour les statistiques et les profils.
- À prévoir : un moyen de purger ces données (voir BACKLOG).

### A-011 · Couleurs aléatoires mélangées à du blanc ou du noir neutre
- Choix : une couleur tirée au hasard n'est mélangée qu'avec du blanc pur ou
  un noir strictement neutre (R = V = B), constante `_neutralInk`.
- Pourquoi : un noir légèrement teinté donnait des dés marron avec certaines
  teintes (orange, jaune).
- S'applique à toute future palette aléatoire mélangée à un fond.

### A-012 · Dernière chance : revanche illimitée
- Choix : chaque délogement remet tous les autres joueurs actifs en attente
  face au nouveau candidat. La phase se termine quand un candidat passe une
  manche complète sans être délogé.
- Pourquoi : c'est la règle jouée à table (remplace « pas de nouveau tour »
  de la spec V0.2).
- Une dernière chance peut donc durer longtemps : c'est voulu.

### A-013 · Prouts du bon dernier : enregistrements CC BY et `audioplayers`
- Choix : 8 extraits courts (OGG, environ 70 Ko au total) tirés de
  « Farts // pieruja » (Yle, [Freesound 425594](https://freesound.org/s/425594/),
  CC BY 4.0), lus avec `audioplayers` en mode `lowLatency`, 3 voix,
  `mixWithOthers`.
- Pourquoi : les sons générés par code sonnaient faux. La licence CC BY
  permet l'usage commercial avec crédit.
- Le crédit en bas de « À propos » (`info_screen.dart`) est obligatoire : ne
  pas le retirer.
- `FartPlayer` ignore les erreurs de lecture pour ne jamais bloquer la saisie.
- Les taches sont comptées par partie (`cradoStains` dans `settings.json`) et
  suivent le bon dernier.

### A-014 · Icône aux couleurs du mode trash
- Choix : deux `activity-alias` lancent `TenkActivity` : `.MainActivity`
  (icône classique) et `.TrashLauncher` (icône néon). Flutter indique l'icône
  voulue sur le canal `tenk/app_icon`, Kotlin bascule dans `onStop`.
- Pourquoi : basculer pendant l'utilisation peut fermer l'appli sur certains
  lanceurs. L'alias classique garde le nom `.MainActivity` pour ne pas casser
  les raccourcis existants.
- Images trash générées par `test/tools/generate_app_icon.dart` directement
  dans `android/app/src/main/res` (`flutter_launcher_icons` écraserait
  l'icône classique).
- Selon le lanceur, l'icône peut mettre un moment à changer.

### A-015 · Français et anglais sans fichiers de traduction
- Choix : chaque texte est écrit dans les deux langues avec
  `tr('français', 'english')` (`lib/l10n/l10n.dart`), sans fichiers `.arb`.
- Pourquoi : pour deux langues, plus lisible et rien à régénérer.
- La langue courante est globale (`L10n.current`) pour que le moteur et les
  catalogues y aient accès. Changer de langue reconstruit le `MaterialApp`.
- Choix mémorisé dans `settings.json` (`language`). Par défaut : langue du
  téléphone.
- Noms : espèces anglaises (`speciesEn`) et épithètes anglaises placées
  devant. Une liste d'épithètes trash par langue (`trashAdjectives`,
  `trashAdjectivesEn`).
- Ne jamais mettre `tr(…)` dans un `const`.

### A-016 · Identifiant de l'appli : `com.qubestudio.tenk`
- Choix : l'identifiant passe de `com.bquillere.tenk` à `com.qubestudio.tenk`
  (v1.8.0), avant la publication sur le Play Store.
- Pourquoi : l'identifiant devient définitif sur le Play Store ; on le veut
  neutre, au nom de Qube Studio.
- Conséquence : Android voit une nouvelle appli. Une installation antérieure
  n'est pas mise à jour et ses données ne sont pas reprises : il faut
  désinstaller l'ancienne version.
