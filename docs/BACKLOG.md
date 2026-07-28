# BACKLOG — 10K

> Ce qui reste à faire, classé par thème. Mis à jour le 27 juillet 2026.
> État actuel : moteur + persistance + accueil + préparation + plateau interactif
> (saisie de score, passer, annuler, dernière chance, écran de victoire) **faits et
> testés sur appareil réel**. 45 tests automatiques verts.

---

## 🎨 Ressenti / « wow » (direction artistique et motion)

- [ ] **Mise en page qui remplit l'écran (idée utilisateur, prioritaire côté ressenti).**
  À 2–4 joueurs, les tuiles devraient **occuper toute la hauteur disponible** (façon
  flexbox) au lieu d'un ratio fixe : moins de vide, blocs plus grands. Le **score**
  devrait alors être **beaucoup plus grand** (taille adaptée à la hauteur de la tuile).
  → Remplacer la grille à `childAspectRatio` fixe par une disposition qui étire les
  tuiles (Column + Expanded à 1 colonne ; grille adaptative à 2 colonnes) et une taille
  de police de score responsive (FittedBox / calcul selon la hauteur).
- [ ] **Police d'affichage** caractérielle pour les scores (chiffres), **embarquée** dans
  l'app (pas de `google_fonts` en ligne — garder le hors-ligne). Télécharger un .ttf sous
  licence libre, l'ajouter aux assets et au thème.
- [ ] **Animation du score** : le nombre qui « défile » de l'ancien vers le nouveau total.
- [ ] **`+500` volant** : petite étiquette du gain qui apparaît puis s'estompe sur la tuile.
- [ ] **Cœurs animés** : vidage/remplissage progressif lors des échecs et des réussites.
- [ ] **Confettis / effet de victoire** sur l'écran de résultat.
- [ ] **Retour haptique** plus riche (léger sur +100, plus marqué sur validation / échec /
      victoire). Respecter le réglage système de réduction des animations.
- [ ] **Transitions de page** plus douces entre accueil → préparation → plateau.

## ⚙️ Fonctionnalités manquantes (V1)

- [ ] **Écran de paramètres de partie** (à faire en priorité — prévu « demain ») :
      mode guidé/libre, sortie minimale (aucune/300/500/1000/perso), multiples de 50,
      confirmation du 3ᵉ échec. Aujourd'hui `newGame()` utilise toujours les défauts.
- [ ] **Écran d'historique** détaillé (§18) : liste chronologique des actions, rencontres,
      gains annulés, filtre par joueur.
- [ ] **Faire quitter un joueur** depuis le plateau (menu) + confirmation (§17).
- [ ] **Écran des parties terminées** (§20.8) + « Rejouer avec les mêmes noms » (§20.7).
- [ ] **Suppression de toutes les données locales** dans un écran de réglages généraux (§37).
- [ ] **Bouton « Passer » fixe** en mode guidé conforme au mock (déjà présent en bas ; à
      affiner visuellement).

## 📦 Livraison / release

- [ ] **Icône d'application** personnalisée (aujourd'hui : icône Flutter par défaut).
- [ ] **Signature release** : keystore dédié, mots de passe hors dépôt, `.gitignore`,
      procédure documentée (§36.3). Aujourd'hui l'APK release est signé en debug par défaut.
- [ ] **Nom de version / notes de version** ; README (lancer, tester, générer l'APK).

## 🧱 Dette technique / robustesse

- [ ] **Compléter le catalogue animal** aux 137 identités de l'Annexe A (aujourd'hui ~80).
- [ ] **`maxLives` configurable** dans le moteur (codé en dur à 3 ; cf. DECISIONS A-005).
- [ ] Réévaluer l'**override `path_provider_android`** (< 2.3.0) quand `jni`/Gradle sera
      stabilisé (cf. DECISIONS A-007).
- [ ] Découper les **résolveurs** (turn/encounter/final_chance) hors du moteur si utile
      (cf. DECISIONS A-004).
- [ ] Étendre les **tests de widgets et d'intégration** (§32, §33) : saisie, confirmations,
      dernière chance à l'écran, reprise après fermeture.
- [ ] Réponses de **Fanch** aux 4 questions de règles (cf. `QUESTIONS_POUR_FANCH.md`) :
      confirmer ou ajuster les décisions par défaut F-001..F-004 de `DECISIONS.md`.

---

## Idées post-V1 (rappel spec §38)
Calculateur de combinaisons de dés, sélection visuelle des dés, profils de règles maison,
réaction en chaîne configurable, sons/voix, statistiques, export, mode tablette, iOS…
