# 10K — notes pour reprendre le projet

Appli Android **Flutter/Dart**, offline, qui remplace la feuille de score du
jeu de dés « 10 000 ». Le user (Ben) est **peu technique** : expliquer sans
jargon, guider pas à pas, une action à la fois. Il teste sur son **vrai
téléphone Android en USB** (Pixel 8 Pro, pas d'émulateur).

## À lire en premier

- **`CHANGELOG.md`** — historique des versions et **contexte des dernières
  sessions** (quoi, pourquoi, ce qui a été corrigé). Commence par là.
- **`docs/DECISIONS.md`** — choix techniques et fonctionnels justifiés
  (pourquoi tel package, tel contournement de bug, telle règle par défaut).
- **`docs/BACKLOG.md`** — reste à faire (peut être partiellement obsolète :
  vérifier contre `CHANGELOG.md` avant de s'y fier).
- **`docs/SPECIFICATION.md`** — règles du jeu du 10 000 en détail.

## Environnement de dev (chemins non évidents)

- Flutter : `D:\Developpement\Flutter SDK\flutter\bin\flutter.bat` (⚠️ espace
  dans le chemin, toléré, mais souvent hors du `PATH` du terminal — appeler
  par chemin complet si `flutter` échoue).
- Android SDK / `adb` : `C:\Users\Ninte\AppData\Local\Android\Sdk\platform-tools\adb.exe`.
- JDK : Temurin 17.
- Device Pixel 8 Pro : id `37071FDJG005AE`. Passe parfois en `unauthorized`
  après un débranchement — il faut que Ben déverrouille le téléphone et
  accepte la popup de débogage USB.
- `kotlin.incremental=false` dans `android/gradle.properties` : nécessaire
  car le projet est sur `D:\` et le cache pub sur `C:\` (bug connu du
  compilateur Kotlin sur Windows entre deux lecteurs différents — voir
  DECISIONS A-008). Ne pas retirer sans re-tester un build complet.

## Commandes courantes

```bash
flutter pub get
flutter test                          # suite de tests (moteur + widgets)
flutter analyze
flutter build apk --debug             # build rapide, pour vérifier que ça compile
flutter build apk --release           # build à installer sur le Pixel
adb -s 37071FDJG005AE install -r build/app/outputs/flutter-apk/app-release.apk
                                      # met à jour sur le Pixel de Ben EN GARDANT ses données
```

⚠️ **Préférer `adb install -r` à `flutter install`** pour le téléphone de
Ben : `flutter install` annonce « Uninstalling old version… » (risque
d'effacer parties, alias et réglages — le 2026-10-02 les données ont
pourtant survécu, mais ne pas compter dessus). `adb install -r` remplace
l'appli en conservant ses données.

**Lire/modifier les données de l'appli sur le Pixel** (parties
`app_flutter/games/*.json`, réglages `app_flutter/settings.json`) : la
version release n'est pas « debuggable », donc `run-as` refuse. Debug et
release sont signées avec la même clé (debug) : `adb install -r` de
`app-debug.apk` (données conservées) → `adb shell run-as com.bquillere.tenk …`
→ réinstaller `app-release.apk` avec `-r`. **Dans Git Bash, toujours
`export MSYS_NO_PATHCONV=1`** avant des commandes adb avec des chemins
Android (`/data/local/tmp/…`), sinon Git Bash les réécrit en chemins Windows
— le 2026-10-02 ça a vidé `settings.json` (`cat absent > settings.json`),
restauré depuis une copie. Toujours copier le fichier avant d'y écrire.

## Distribution (GitHub)

- Dépôt public : [github.com/Nyvristhrit/10k](https://github.com/Nyvristhrit/10k).
- Page de téléchargement (GitHub Pages, servie depuis `main:/docs`) :
  [nyvristhrit.github.io/10k](https://nyvristhrit.github.io/10k/). Le bouton
  télécharge toujours `.../releases/latest/download/10K.apk` — **l'asset de
  chaque Release doit impérativement s'appeler exactement `10K.apk`**, sinon
  ce lien casse.
- `gh` (GitHub CLI) est installé et **déjà authentifié** sur la machine de
  Ben (compte `Nyvristhrit`, jeton dans le trousseau Windows credential
  manager) : `"/c/Program Files/GitHub CLI/gh.exe"` si pas dans le `PATH` du
  terminal courant.
- Procédure de publication complète : voir la fin de `CHANGELOG.md`.
- `10K.apk` à la racine du dépôt est **gitignoré** (trop lourd pour Git) —
  copié à la main avant chaque `gh release create`, jamais commité.

## Architecture (résumé)

`lib/domain` (Dart pur, testé, aucune dépendance Flutter/Riverpod) →
`lib/application` (Riverpod : controllers + providers) → `lib/data`
(persistance JSON, catalogues) → `lib/features` (écrans) + `lib/shared`
(widgets/animations réutilisables) + `lib/app` (thème, `TenkSkin`).

Le **mode trash** (easter egg, 7 tapes sur la dédicace dans « À propos »)
est transporté par `TenkSkin`, une `ThemeExtension` — n'importe quel widget y
accède via `TenkSkin.of(context)` sans passer par Riverpod.

## Attentes du user sur la direction artistique

Tuiles qui remplissent l'écran, scores très grands et animés, ressenti
« wow » plutôt que minimal, animations maison sans dépendance graphique
externe (`CustomPainter`/`AnimationController`). Voir `CHANGELOG.md` pour le
détail des passes de DA successives.
