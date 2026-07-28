# 🎲 10K — Compagnon de jeu du 10 000

Application Android **100 % hors ligne** qui remplace la feuille de score du
jeu de dés **10 000**. On lance les vrais dés autour de la table, et l'appli
tient les scores, les vies et applique les règles à votre place.

> Fini les feuilles de score : du papier au téléphone. 10K pose le jeu au
> centre de la table, en grand et en couleurs.

## ✨ Fonctionnalités

- **Score au centre de la table** : grosses tuiles colorées, un joueur par
  tuile, score géant qui grimpe en s'animant.
- **Toutes les règles du 10 000** gérées automatiquement : sortie à 300, pile
  de gains, 3 cœurs, 3ᵉ échec, « rencontre », objectif exact à 10 000,
  dernière chance.
- **Modes guidé ou libre** : l'appli propose l'ordre des tours, ou vous laisse
  jouer librement.
- **Réglages de partie** : objectif, nombre de cœurs, minimum de sortie, pas de
  score, règles spéciales… tout est ajustable.
- **Mode jour / nuit** avec bascule, mémorisé.
- **Annulation** de la dernière action à tout moment — aucune erreur n'est
  définitive.
- **Soigné et vivant** : animations maison (dés qui tombent sur l'accueil,
  cœurs façon Zelda, effet de dégât, confettis de victoire), couleur d'accent
  tirée au hasard à chaque ouverture, titre arc-en-ciel.

## 🕹️ Le jeu du 10 000

But : atteindre **exactement 10 000 points**. Chaque joueur lance les dés à son
tour et marque des points ; certaines combinaisons rapportent gros, d'autres
font tout perdre. Tomber pile sur le total d'un adversaire déclenche une
« rencontre » qui lui annule son dernier gain. Premier à 10 000 pile : les
autres ont une dernière chance, puis on classe !

## 🛠️ Technique

- **Flutter / Dart**, Material 3, thème sombre & clair.
- **Architecture propre** : domaine (Dart pur, testé) → application (Riverpod)
  → data (persistance en fichiers JSON, sans base de données).
- **Zéro connexion, zéro compte, zéro donnée envoyée** : tout reste sur le
  téléphone.
- Animations **sans aucune dépendance graphique externe** (CustomPainter,
  AnimationController), pour une appli légère.

### Lancer le projet

```bash
flutter pub get
flutter run          # sur un appareil Android branché
flutter test         # la suite de tests (moteur de jeu + parcours d'écran)
```

## 📄 Licence

Voir [`LICENSE`](LICENSE).

---

*Imaginé par Ben, vibecodé avec Claude. Dédicace à Fanch, Khorven et Victor
pour cette introduction aux 10 000 ! 🍻*
