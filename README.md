# 10K

Application Android qui remplace la feuille de score du jeu de dés « 10 000 ».
On lance les vrais dés autour de la table ; l'appli tient les scores, les vies
et applique les règles.

Entièrement hors ligne, sans compte ni publicité. Disponible en français et en
anglais.

## Installer

En attendant le Play Store, l'APK est distribué sur GitHub :

- [Page de téléchargement](https://nyvristhrit.github.io/10k/), avec les
  étapes d'installation
- [Dernière Release](https://github.com/Nyvristhrit/10k/releases/latest)

## Fonctionnalités

- Une grande tuile colorée par joueur, scores animés
- Règles du 10 000 gérées automatiquement : sortie, vies, rencontres,
  objectif exact, dernière chance
- Réglages de partie : objectif, vies, minimum de sortie, règles spéciales
- Annulation de la dernière action et historique de la partie
- Plateau de dés virtuel pour jouer sans dés
- Statistiques, records et alias pour suivre les joueurs d'une partie à
  l'autre
- Thème clair ou sombre, mode paysage

## Le jeu

Le but est d'atteindre exactement 10 000 points. Tomber pile sur le score
d'un adversaire déclenche une « rencontre » qui lui retire son dernier gain.
Quand un joueur atteint 10 000, les autres ont une dernière chance de le
déloger. Les règles détaillées sont dans
[`docs/SPECIFICATION.md`](docs/SPECIFICATION.md).

## Développement

Prérequis : Flutter (stable, Dart 3.12 ou plus) et le SDK Android.

```bash
flutter pub get
flutter test                 # tests du moteur et des écrans
flutter run                  # sur un appareil Android branché
flutter build apk --release --target-platform android-arm,android-arm64
```

Structure de `lib/` :

- `domain/` : moteur de jeu en Dart pur, sans dépendance Flutter
- `application/` : état de l'appli (Riverpod)
- `data/` : sauvegarde en fichiers JSON, catalogues de noms
- `features/` : écrans
- `shared/`, `app/` : widgets communs, thème
- `l10n/` : textes français et anglais

Documentation :

- [`CHANGELOG.md`](CHANGELOG.md) : historique des versions et procédure de
  publication
- [`docs/DECISIONS.md`](docs/DECISIONS.md) : choix techniques justifiés
- [`docs/BACKLOG.md`](docs/BACKLOG.md) : reste à faire

## Licence

[MIT](LICENSE)

## Crédits

Les sons du mode trash viennent des archives de Yle
([Freesound](https://freesound.org/s/425594/), CC BY 4.0).

Merci à Fanch, Khorven et Victor pour l'initiation au 10 000.
