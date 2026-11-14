# Changelog

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/). Chaque
version correspond à une Release GitHub dont l'asset `10K.apk` est proposé
sur la [page de téléchargement](https://nyvristhrit.github.io/10k/).

Voir aussi `docs/DECISIONS.md` (choix justifiés), `docs/BACKLOG.md` (reste à
faire) et `docs/SPECIFICATION.md` (règles du jeu).

## [v1.8.0] - 2026-11-14

### Ajouté
- L'appli est disponible en anglais. Bouton « EN » / « FR » sur l'accueil,
  choix mémorisé ; au premier lancement, l'appli suit la langue du téléphone.
- Tout est traduit, y compris les règles, « Quoi de neuf », le mode trash et
  les noms d'animaux (« Sneaky Panda »). Les noms déjà donnés ne changent pas.
- Note technique : `tr('fr', 'en')` sans fichiers `.arb` (DECISIONS A-015).
- Page de téléchargement, confidentialité et mentions légales en anglais
  (`docs/en/`), avec un lien English / Français sur chaque page.

### Modifié
- Nouvel identifiant d'appli : `com.qubestudio.tenk` (DECISIONS A-016).
  Android l'installe comme une nouvelle appli : désinstaller l'ancienne
  version (ses parties ne sont pas reprises).
- Commentaires du code et documentation raccourcis et nettoyés.
- Politique de confidentialité corrigée : le lien Ko-fi est sur le site, pas
  dans l'appli.
- Signature release prête pour le Play Store : `android/key.properties` est
  utilisé s'il existe (clé debug sinon).

### Supprimé
- Ancienne copie de la spécification à la racine (doublon de
  `docs/SPECIFICATION.md`), notes de questions déjà tranchées, dossiers
  vides.

## [v1.7.1] - 2026-10-23

### Ajouté
- L'icône de l'appli prend les couleurs du mode trash quand il est actif. Le
  changement se fait en quittant l'appli (DECISIONS A-014).
- « Quoi de neuf » annonce les retouches de la mise à jour v1.7.0.

## [v1.7.0, mise à jour] - 2026-10-23

APK de la Release v1.7.0 remplacé sans changer de numéro (même
`versionCode`).

### Modifié
- Prouts du bon dernier : 8 vrais enregistrements (Yle, CC BY 4.0) au lieu de
  sons synthétisés. Crédit en bas de « À propos » (DECISIONS A-013).
- Taches du bon dernier : plusieurs nuances de marron, effet camouflage.
- Règles, onglet « L'appli » : nouvelle fiche « Changer un joueur de place ».

## [v1.7.0] - 2026-10-23

### Ajouté
- Changer un joueur de place en partie : appui long sur une tuile puis
  glisser-déposer. Nouvelle commande `MovePlayer`, absente de l'historique.
- Mode trash, le bon dernier 💩 : un prout à chaque bouton de la saisie et une
  tache marron de plus sur sa tuile. Les taches passent au nouveau dernier.
  Deux interrupteurs dans les paramètres de la partie.

### Retiré
- Lien Ko-fi dans « À propos » (règles de paiement du Play Store). Il reste
  sur la page de téléchargement. Package `url_launcher` retiré.

### Corrigé
- Temps de jeu cumulé (Stats) : ne compte plus la préparation ni les pauses
  (écarts entre saisies plafonnés à 10 min, `GameStats.playTimeOf`).

## [v1.6.1] - 2026-10-02

### Ajouté
- Pages « Confidentialité » et « Mentions légales » sur le site.
- Police du site hébergée localement (plus d'appel à Google Fonts).

### Modifié
- Saisie du score : bouton « Passer le tour » retiré (trop proche de
  « Valider ») ; boutons +1000/+500/+100 plus grands.
- Fenêtre de saisie mieux détachée du fond (halo à la couleur du joueur).
- Alias : option « Appliquer à ma tuile » pour garder sa couleur
  (DECISIONS F-007).
- Mode trash : liste d'épithètes adoucie et entièrement modifiable, 100 max
  (DECISIONS F-006).
- Règle du sombrero malgache : il faut l'annoncer avant de relancer.

## [v1.6.0] - 2026-09-16

### Corrigé
- Une rencontre redonne toujours 3 vies à la victime (DECISIONS F-003).
- Un 3ᵉ échec pouvait laisser deux joueurs au même score sans rencontre
  (DECISIONS F-005).
- Les épithètes des noms par défaut ne se répètent plus entre joueurs.
- Plateau de dés : contraste des points garanti (`_withMinContrast`).
- Plateau de dés : 5 dés au lieu de 6.

### Modifié
- Nom sur les tuiles : taille fixe, tronqué par « … » s'il est trop long.
- Dépendances mises à jour (versions mineures uniquement).

## [v1.5.0] - 2026-09-04

### Ajouté
- Fenêtre « Quoi de neuf » après une mise à jour, une seule fois
  (`whats_new_catalog.dart`).

### Modifié
- Page de téléchargement : le lien Ko-fi devient un vrai bouton.

### Corrigé
- Dernière chance : un joueur délogé peut retenter sa chance, sans limite
  (DECISIONS A-012).

## [v1.4.0] - 2026-09-04

### Ajouté
- Écran « Stats & records » : parties jouées, temps de jeu, tours,
  rencontres, manches moyennes par objectif, records.
- Alias joueur (`@Ben`) pour suivre une personne d'une partie à l'autre.
- Écran « Alias & profils » : victoires, renommage, couleur, suppression.
- Les parties terminées sont conservées (DECISIONS A-010).

### Corrigé
- Dés marron avec certaines teintes aléatoires (DECISIONS A-011).

## [v1.3.3] - 2026-09-04

### Ajouté
- Réglage « Dés dans l'appli » pour masquer le plateau de dés.
- Couleur aléatoire du plateau de dés à chaque ouverture.

### Corrigé
- Noms de joueur coupés en plein mot sur les tuiles étroites.
- Halo du joueur actif plus visible.

### Modifié
- Catalogue de noms resserré (variantes trop longues retirées).

## [v1.3.2] - 2026-09-04

### Corrigé
- « À propos » n'affiche plus le numéro de build à côté de la version.

## [v1.3.1] - 2026-09-04

### Ajouté
- Lien de soutien Ko-fi dans « À propos » et sur la page de téléchargement.

### Modifié
- Mode trash : les épithètes perso sortent deux fois plus souvent.
- Catalogue d'épithètes retravaillé (écriture inclusive pour le mode sage).

## [v1.3.0] - 2026-09-04

### Ajouté
- Historique de la partie (icône 🕐) : liste des coups par manche, retour à
  un coup passé (`GameController.revertToAction`).
- Plateau de dés virtuel (icône 🎲) pour jouer sans dés physiques.

## [v1.2.1] - 2026-08-19

### Corrigé
- Éditeur d'épithètes trash : le champ de saisie se distingue enfin du texte
  d'aide.

## [v1.2.0] - 2026-08-19

### Corrigé
- Page de téléchargement : logo « 10K » en SVG, étapes d'installation
  lisibles.

### Modifié
- Éditeur d'épithètes trash : aide plus claire, compteur, 20 max.

## [v1.1.0] - 2026-08-19

### Ajouté
- Interrupteur du mode trash plus visible dans « À propos ».
- Noms par défaut « Espèce + Épithète » et éditeur d'épithètes perso.
- Écran toujours allumé pendant la partie (`wakelock_plus`, voir
  DECISIONS A-008).
- Mode paysage.
- Dépôt GitHub public et page de téléchargement (DECISIONS A-009).

### Corrigé
- Une rencontre qui vide la pile d'un joueur restaure de nouveau ses vies.

## Avant les Releases GitHub

Développement initial (juillet-août 2026), détail dans l'historique Git :
- Moteur de jeu en Dart pur, testé, avec les variantes du groupe (sombrero
  malgache, suites, brelan, carré, main pleine).
- Sauvegarde locale en JSON ; écrans accueil, préparation, plateau, résultat,
  réglages, règles.
- Rencontres en cascade et alertes de rencontre.
- Mode trash, débloqué par 7 tapes sur la dédicace.
- Thème clair/sombre, police Space Grotesk, icône dessinée en code.

---

## Publier une nouvelle version

1. Monter `version:` dans `pubspec.yaml` (ex. `1.8.0+12` → `1.8.1+13`). C'est
   la version affichée dans « À propos ».
2. `flutter build apk --release`
3. Tester sur le téléphone :
   `adb -s <device-id> install -r build/app/outputs/flutter-apk/app-release.apk`
4. Copier l'APK à la racine (fichier ignoré par Git) :
   `cp build/app/outputs/flutter-apk/app-release.apk 10K.apk`
5. Créer la Release. L'asset doit s'appeler exactement `10K.apk` :
   `gh release create vX.Y.Z "10K.apk#10K.apk" --repo Nyvristhrit/10k --title "10K vX.Y.Z" --notes "..."`
6. Ajouter une section dans ce fichier, même pour un petit correctif.
7. Mettre à jour la pastille `.version-pill` de `docs/index.html` et `docs/en/index.html`.
8. Seulement si la version apporte un changement visible pour les joueurs :
   - ajouter une entrée au bloc `.changelog` de `docs/index.html` et `docs/en/index.html` (version anglaise) ;
   - ajouter la même entrée à `WhatsNewCatalog.releases`
     (`lib/data/catalogs/whats_new_catalog.dart`), la plus récente en dernier.
