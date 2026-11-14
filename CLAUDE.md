# 10K : notes pour reprendre le projet

Appli Android Flutter/Dart, hors ligne, qui remplace la feuille de score du
jeu de dés « 10 000 ». Package Dart : `tenk`. Application ID :
`com.qubestudio.tenk`.

Ben, le propriétaire, n'est pas développeur : expliquer simplement, une étape
à la fois. Il teste sur son Pixel 8 Pro branché en USB (pas d'émulateur).

## À lire

- `CHANGELOG.md` : versions livrées et procédure de publication (en fin de
  fichier).
- `docs/DECISIONS.md` : choix justifiés. Les identifiants (A-xxx, F-xxx,
  D-xxx) sont cités dans le code.
- `docs/BACKLOG.md` : reste à faire.
- `docs/SPECIFICATION.md` : règles du jeu.

## Environnement

- Flutter (Dart ^3.12), JDK 17.
- Chemins et appareil de test propres à la machine : `CLAUDE.local.md`
  (non versionné).
- `kotlin.incremental=false` (`android/gradle.properties`) est nécessaire
  quand le projet et le cache pub sont sur deux lecteurs différents
  (DECISIONS A-008). Ne pas retirer sans refaire un build complet.

## Commandes

```bash
flutter pub get
flutter test
flutter analyze
flutter build apk --debug      # vérifie que ça compile
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

- Installer avec `adb install -r`, pas `flutter install` (qui désinstalle
  d'abord et peut effacer les parties et réglages).
- Lire les données sur le téléphone (`app_flutter/games/*.json`,
  `app_flutter/settings.json`) : la version release refuse `run-as`.
  Installer `app-debug.apk` avec `-r` (même clé, données conservées), utiliser
  `adb shell run-as com.qubestudio.tenk …`, puis réinstaller la release avec
  `-r`.
- Dans Git Bash, faire `export MSYS_NO_PATHCONV=1` avant toute commande adb
  avec un chemin Android, sinon il est réécrit en chemin Windows (cela a déjà
  vidé `settings.json`). Toujours copier un fichier avant d'y écrire.

## Distribution

- Dépôt public : https://github.com/Nyvristhrit/10k
- Page de téléchargement (GitHub Pages, `main:/docs`) :
  https://nyvristhrit.github.io/10k/
- Le bouton pointe vers `releases/latest/download/10K.apk` : l'asset de
  chaque Release doit s'appeler exactement `10K.apk`.
- `10K.apk` à la racine est ignoré par Git, jamais commité.
- `gh` (GitHub CLI) est utilisé pour publier les Releases.

## Architecture

- `lib/domain` : moteur en Dart pur, testé, sans Flutter ni Riverpod.
- `lib/application` : controllers et providers Riverpod.
- `lib/data` : persistance JSON, catalogues.
- `lib/features` : écrans. `lib/shared` : widgets et animations communs.
- `lib/app` : thème et `TenkSkin`.
- `lib/l10n` : `tr('fr', 'en')`, langue courante dans `L10n.current`
  (DECISIONS A-015).
- Mode trash (7 tapes sur la dédicace dans « À propos ») : porté par
  `TenkSkin`, une `ThemeExtension`, accessible via `TenkSkin.of(context)`.

## Direction artistique

Tuiles qui remplissent l'écran, scores très grands et animés, rendu
spectaculaire plutôt que minimal. Animations faites maison
(`CustomPainter`, `AnimationController`), sans dépendance graphique.
