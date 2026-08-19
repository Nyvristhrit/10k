# DECISIONS.md — Journal des décisions techniques et fonctionnelles

> Ce fichier consigne toute décision importante, comme l'exige la spécification (§0.7, §39).
> Chaque décision : date, contexte, choix, raison. Toute modification d'une règle du jeu
> doit incrémenter la version de `SPECIFICATION.md` et ajouter une ligne ici.

---

## 2026-07-27 — Fondation du projet (Phase 0)

### D-001 · Nom de package Dart interne = `tenk`
- **Contexte :** Dart interdit un nom de package commençant par un chiffre ; « 10k » est invalide.
- **Choix :** package/projet Dart = `tenk`. Le **nom affiché** de l'application reste « 10K » (défini plus tard dans le manifeste Android, purement cosmétique).
- **Raison :** contrainte technique du langage.

### D-002 · Environnement de développement (voie légère, sans Android Studio)
- **Choix :** Flutter 3.44.8 stable ; SDK Android installé via le nouvel outil Google `android.exe` (`~/AppData/AndroidCLI`) plutôt qu'Android Studio ; JDK Temurin 17.
- **Raison :** installation plus légère, pas besoin de l'IDE complet. `flutter doctor` = tout vert.
- **Note :** le SDK Flutter est dans un chemin contenant un espace (`D:\Developpement\Flutter SDK`), toléré par Flutter 3.x.

### D-003 · Plateformes du projet = Android uniquement
- **Choix :** `flutter create --platforms=android`. Pas d'iOS, web ni desktop.
- **Raison :** périmètre V1 = APK Android (spec §2.1). Les autres cibles pourront être ajoutées plus tard sans blocage.

---

## Décisions fonctionnelles PAR DÉFAUT (en attente de confirmation)

> Ces 4 points étaient ambigus dans la spécification. Choix par défaut appliqués pour ne
> pas bloquer le développement du moteur. À reconfirmer avec le groupe de joueurs
> (cf. `QUESTIONS_POUR_FANCH.md` à la racine). Révisables : ils sont isolés dans le moteur.

### F-001 · Détection des victimes d'une rencontre = instantané figé (snapshot)
- **Question :** lors d'une rencontre multiple, la liste des victimes est-elle figée au moment
  où le marqueur atteint son total, ou recalculée au fur et à mesure des annulations ?
- **Choix par défaut :** **figée**. On calcule la liste des adversaires à égalité *avant* toute
  annulation, puis on applique. Aucune annulation ne peut modifier la liste des victimes.
- **Raison :** cohérent avec « pas de réaction en chaîne en V0.2 » (spec §14.5, invariant 14).

### F-002 · Rencontre « normale » pendant la phase de dernière chance
- **Question :** pendant `FINAL_CHANCE`, une rencontre sur un score autre que 10 000 s'applique-t-elle ?
- **Choix par défaut :** **oui**, la règle de rencontre s'applique à tout score (spec §16.4 : « la
  rencontre continue de s'appliquer »). En revanche, elle **ne redonne jamais un tour** à une victime.
- **Raison :** cohérent avec « le candidat délogé ne reçoit pas de nouveau tour » (spec §16.4).

### F-003 · Rencontre qui vide la pile → 3 vies restaurées
- **Question :** si une rencontre retire le dernier gain d'une victime (pile devient vide),
  ses vies repassent-elles à 3 ?
- **Choix par défaut :** **oui** (spec §14.6 + invariant 10 : « joueur sans gain actif → vies normalisées à 3 »).
- **Raison :** application stricte de l'invariant 10. Effet de bord assumé : être rencontré à
  1 vie / 1 gain « rend » les cœurs. À valider en playtest.

### F-004 · Départage d'égalité au classement final
- **Question :** deux perdants à égalité de score, comment les classer ?
- **Choix par défaut :** **ordre autour de la table** (`seatIndex` croissant).
- **Raison :** non spécifié (spec §20.7) ; ordre de table = critère stable et neutre.

---

## Décisions d'architecture

### A-001 · Source de vérité à la reprise = snapshot ; journal = vérification
- **Contexte :** la spec (§27.4) veut que le snapshot soit reconstructible depuis les actions
  non annulées. L'undo laisse les actions marquées `isUndone` dans le journal.
- **Choix :** au chargement d'une partie, le **snapshot courant** fait foi. La reconstruction
  depuis le journal (en ignorant les `isUndone`) sert uniquement de **test d'invariant**, pas de
  mécanisme de chargement en production.
- **Raison :** évite toute divergence subtile entre journal et état réel ; chargement rapide.

### A-003 · Pile de gains portée par le joueur dans le domaine
- **Contexte :** la spec (§24.5) modélise `Player.gainIds` + une liste centrale `GameState.gains`.
- **Choix :** dans la couche domaine, chaque `Player` porte directement sa `List<Gain>`. Le
  score reste dérivé (somme des gains actifs, invariant 5). La normalisation en tables
  (persistance Drift) se fera dans la couche `data`.
- **Raison :** rend le moteur plus simple et purement fonctionnel ; le score se calcule localement.

### A-004 · Résolveurs consolidés dans le moteur (V1)
- **Choix :** la logique de tours / rencontres / dernière chance est implémentée en méthodes
  privées de `GameEngine` (au lieu de fichiers `turn_resolver`/`encounter_resolver`/
  `final_chance_resolver` séparés listés au §28.3).
- **Raison :** cohésion et lisibilité pour la V1 ; extraction possible plus tard sans changer l'API.

### A-005 · Undo via effets réversibles
- **Choix :** chaque mutation d'un champ suivi (vies, gains, statut, manche, dernière chance,
  départ) émet un `GameEffect` avec `previousValue`/`nextValue`. `UndoLastAction` rejoue les
  effets de la dernière action à l'envers. Testé sur la rencontre multiple (Annexe C.7).
- **Raison :** annulation atomique automatique et fiable, et fournit aussi le détail pour l'historique (§18).
- **Limite V1 :** `maxLives` est traité comme 3 dans le moteur (valeur fixe V1) ; à généraliser
  si les vies deviennent configurables.

### D-004 · Catalogue animal partiel
- **Choix :** `AnimalCatalog` contient ~80 identités représentatives (sur les 137 de l'Annexe A).
- **Raison :** suffisant pour toute la logique et les tests (unicité, familles). Compléter les
  entrées restantes est une simple tâche de données, sans impact sur le moteur.

### A-006 · Persistance par fichiers JSON (au lieu de Drift) pour la V1
- **Contexte :** la spec §27.2 recommande Drift/SQLite, mais autorise « une solution locale
  équivalente documentée ».
- **Choix :** stockage de chaque partie dans un fichier `<documents>/games/<id>.json`
  (l'état complet sérialisé, journal inclus). Écriture atomique (fichier temporaire puis
  renommage ; secours via `.tmp` au chargement après arrêt brutal).
- **Raison :** une V1 a une seule partie active + un historique ; l'historique est déjà dans
  l'instantané. Le fichier JSON est plus simple, offline, sans génération de code ni bibliothèque
  native, et entièrement testable hors appareil. Migration vers Drift possible plus tard si des
  besoins de requêtes apparaissent.
- **Testé :** aller-retour d'un état complexe (rencontre multiple), annulation après rechargement,
  reprise en dernière chance, bascule terminée→historique. La sérialisation vit dans
  `data/serialization`, le port `GameRepository` dans `domain/repositories`, les implémentations
  (fichier + mémoire) dans `data/repositories`.
- **Reste à faire (sur appareil) :** brancher le dossier racine sur le dossier de documents Android
  via `path_provider` (adaptateur mince), lors de la construction de l'UI.

### A-007 · Épinglage de `path_provider_android` en 2.2.x
- **Contexte :** `path_provider_android` 2.3.x tire un paquet natif `jni` dont le script de
  build Android casse la compilation Gradle (« Could not find method kotlin() »).
- **Choix :** `dependency_overrides: path_provider_android: ">=2.2.0 <2.3.0"` (résout en 2.2.23,
  implémentation en canal de plateforme classique, sans `jni`).
- **Raison :** l'APK se construit alors sans problème. À revoir quand l'écosystème `jni`/Gradle
  sera stabilisé (on pourra retirer l'override).

### A-008 · Cache incrémental Kotlin désactivé (`kotlin.incremental=false`)
- **Contexte :** l'ajout de `wakelock_plus` (mode « écran toujours allumé ») a
  introduit `package_info_plus` en dépendance transitive, son premier plugin
  Kotlin natif compilé pour la première fois. Le build échouait avec
  `this and base files have different roots` (Kotlin `relativeTo` incapable de
  comparer des chemins sur deux lecteurs différents : le projet est sur `D:\`,
  le cache pub sur `C:\Users\...\Pub\Cache`).
- **Choix :** `kotlin.incremental=false` dans `android/gradle.properties`.
- **Raison :** bug connu du compilateur Kotlin sous Windows quand projet et
  cache pub ne partagent pas la même racine de lecteur. Coût : compilation
  légèrement plus lente (pas d'incrémental), sans impact sur le résultat.

### A-002 · Undo par valeurs stockées
- **Choix :** chaque `GameEffect` stocke `previousValue`/`nextValue`. L'annulation ré-applique
  les `previousValue` plutôt que de recalculer.
- **Raison :** robuste pour les actions complexes (rencontre multiple + dernière chance), fidèle
  à l'exigence d'annulation atomique intégrale (spec §19).
