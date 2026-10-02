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
- [ ] **Play Store** — audit fait le 2026-10-02 : le **contenu passe**
      (liste trash adoucie, DECISIONS F-006 ; aucune donnée collectée, pas de
      permission Internet, targetSdk 36 OK). Reste, **reporté par Ben à plus
      tard** :
  - [ ] **Compte Play Console au nom de sa société** (pas en perso) →
        récupérer d'abord un **numéro D-U-N-S** (gratuit, exigé par Google
        pour un compte « organisation »). Avantage : un compte organisation
        n'est pas soumis au test fermé obligatoire (12 testeurs × 14 jours)
        imposé aux comptes personnels récents.
  - [ ] **Signature release** (ligne ci-dessus) — clé dédiée, à sauvegarder.
  - [ ] **Build `.aab`** (`flutter build appbundle`) au lieu de l'APK.
  - [ ] **Retirer le bouton Ko-fi de la version Play Store** (onglet « À
        propos », `info_screen.dart`) : un lien de don dans l'appli risque
        un refus (règles de paiement Google Play). Le garder dans la version
        GitHub et sur la page de téléchargement.
  - [ ] **Mettre à jour les mentions légales** (`docs/mentions-legales.html`)
        quand l'appli passera sous la société : raison sociale, forme
        juridique, SIRET, adresse du siège, directeur de la publication,
        e-mail de contact (aujourd'hui : éditeur particulier anonyme, contact
        via les Issues GitHub). Idem « Éditeur » dans la politique de
        confidentialité si besoin.
  - [ ] Questionnaire de classification (IARC) : **déclarer le mode trash**
        (contenu caché compris) ; formulaire « Sécurité des données » :
        aucune donnée collectée. URL de confidentialité à donner :
        `https://nyvristhrit.github.io/10k/confidentialite.html`.
  - [ ] Fiche Play Store : captures d'écran, description, bannière.
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

## 💡 Idées à décider plus tard

- [ ] **Bruitages de prout (mode trash)** — idée de Ben, 2026-10-02, pas
      encore validée. Quand le joueur 💩 (dernier, `lastPlaceId`) saisit son
      score, chaque appui sur +1000/+500/+100 joue un prout tiré au hasard
      parmi 6–8 sons différents. Interrupteur dans les réglages (section
      trash). Sons à **générer par programme** (pas de droits d'auteur) ou
      CC0 ; nécessite un paquet audio (ex. `audioplayers`). Suit le volume
      « médias ». Question ouverte : seulement le 💩, ou tout le monde en
      mode trash ?

## Idées post-V1 (rappel spec §38)
Calculateur de combinaisons de dés (deviner/valider une combinaison à partir
des valeurs du plateau de dés virtuel — la sélection visuelle des dés et les
statistiques, elles, sont faites), profils de règles maison, réaction en
chaîne configurable, sons/voix, export, iOS…
