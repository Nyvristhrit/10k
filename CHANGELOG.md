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

1. `flutter build apk --release`, `flutter install -d <device-id>` pour tester
   sur le Pixel de Ben.
2. Copier l'APK à la racine du dépôt : `cp build/app/outputs/flutter-apk/app-release.apk 10K.apk`
   (ce fichier est gitignoré — jamais commité, seulement diffusé via les
   Releases).
3. `gh release create vX.Y.Z "10K.apk#10K.apk" --repo Nyvristhrit/10k --title "10K vX.Y.Z" --notes "..."`
   — **l'asset doit impérativement s'appeler `10K.apk`** (le lien de la page
   de téléchargement est câblé sur ce nom exact).
4. Ajouter une section ici (CHANGELOG.md) avec les changements.
5. Mettre à jour `docs/index.html` : la pastille `.version-pill` (numéro de
   version) et le bloc `.changelog` (nouvelle entrée en tête, garder les 2-3
   dernières visibles suffit — le lien « historique complet » renvoie déjà
   vers ce fichier).
6. `gh` est déjà installé et authentifié sur la machine de Ben (compte
   GitHub `Nyvristhrit`, jeton dans le trousseau Windows) — pas besoin de
   relancer `gh auth login`, sauf expiration.
