# BACKLOG — 10K

> Ce qui reste à faire, classé par thème. Mis à jour le 4 septembre 2026.
> **Pour le détail de ce qui a déjà été livré (dont tout ce qui était encore
> listé ici en juillet/août), voir `CHANGELOG.md`** — le « ressenti wow »,
> l'écran de paramètres, l'historique de partie, le plateau de dés, les
> statistiques et les alias joueur sont faits depuis. Ce fichier ne garde que
> ce qui reste réellement ouvert.

---

## ⚙️ Fonctionnalités manquantes

- [ ] **Écran des parties terminées** (§20.8) : liste chronologique des
      parties passées (une ligne par partie — date, joueurs, gagnant), à
      distinguer de l'écran « Stats & records » (déjà fait, bilan agrégé) et
      « Alias & profils » (déjà fait, bilan par personne) qui ne montrent pas
      le détail partie par partie.
- [ ] **« Rejouer avec les mêmes noms »** (§20.7) depuis cet écran, une fois
      qu'il existe.
- [ ] **Suppression de toutes les données locales** dans un écran de réglages
      généraux (§37) — d'autant plus utile maintenant qu'une partie terminée
      n'est plus jamais effacée automatiquement (cf. DECISIONS A-010).

## 📦 Livraison / release

- [ ] **Signature release officielle** : keystore dédié, mots de passe hors
      dépôt, procédure documentée (§36.3). Aujourd'hui l'APK est signé en
      debug (suffisant pour la distribution GitHub actuelle, pas pour le Play
      Store).
- [ ] **Play Store** : compte Play Console (25 $ à vie), build `.aab`,
      visuels — voir la conversation avec Ben pour le détail des étapes.
      Distribution GitHub (voir `CHANGELOG.md`) en attendant.

## 🧱 Dette technique / robustesse

- [ ] **Compléter le catalogue animal** aux 137 identités de l'Annexe A
      (aujourd'hui ~80).
- [ ] Réévaluer l'**override `path_provider_android`** (< 2.3.0) quand
      `jni`/Gradle sera stabilisé (cf. DECISIONS A-007).
- [ ] Réévaluer `kotlin.incremental=false` (cf. DECISIONS A-008) si le projet
      est un jour déplacé sur le même lecteur que le cache pub.
- [ ] Découper les **résolveurs** (turn/encounter/final_chance) hors du
      moteur si utile (cf. DECISIONS A-004).
- [ ] Étendre les **tests de widgets et d'intégration** (§32, §33) : saisie,
      confirmations, dernière chance à l'écran, reprise après fermeture.
- [ ] Réponses de **Fanch** aux 4 questions de règles (cf.
      `QUESTIONS_POUR_FANCH.md`) : confirmer ou ajuster les décisions par
      défaut F-001..F-004 de `DECISIONS.md`.

---

## Idées post-V1 (rappel spec §38)
Calculateur de combinaisons de dés (deviner/valider une combinaison à partir
des valeurs du plateau de dés virtuel — la sélection visuelle des dés et les
statistiques, elles, sont faites), profils de règles maison, réaction en
chaîne configurable, sons/voix, export, iOS…
