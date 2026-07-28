# 10K — Spécification complète du projet

> **Version du document :** 0.2  
> **Statut :** cadre fonctionnel consolidé, prêt à être donné à Claude Code  
> **Plateforme cible V1 :** Android  
> **Livrable principal :** APK installable  
> **Langue de l'application V1 :** français  
> **Nom de travail :** 10K  
> **Dernière mise à jour :** 27 juillet 2026

---

## 0. Instructions impératives pour Claude Code

Ce fichier est la **source de vérité fonctionnelle** du projet.

Avant toute modification du dépôt, Claude Code doit :

1. lire ce document intégralement ;
2. résumer l'architecture et les règles comprises ;
3. signaler uniquement les contradictions réellement bloquantes ;
4. ne jamais inventer ou modifier une règle de jeu silencieusement ;
5. développer le moteur de jeu et ses tests avant de construire les écrans complets ;
6. garder toute la logique métier hors des widgets Flutter ;
7. documenter les décisions techniques importantes dans `docs/DECISIONS.md` ;
8. maintenir ce document à jour lorsqu'une règle est officiellement modifiée.

Les termes suivants expriment le niveau d'exigence :

- **MUST** : obligatoire pour la V1 ;
- **SHOULD** : fortement recommandé, report possible seulement si documenté ;
- **MAY** : facultatif ou prévu pour une version ultérieure.

En cas de doute entre une interprétation implicite et une règle explicite de ce document, la règle explicite prévaut.

---

# 1. Vision du produit

10K est une application Android hors ligne permettant de gérer une partie du jeu de dés **10 000** autour d'une table.

L'application remplace la feuille de papier et le calcul mental en proposant :

- des tuiles de joueurs très lisibles ;
- un animal emoji aléatoire par joueur ;
- une couleur unique par joueur dans la partie ;
- une saisie rapide des scores par incréments ;
- une gestion automatique des vies ;
- une gestion automatique de l'annulation du dernier gain actif ;
- une règle de « rencontre » entre joueurs ;
- un objectif exact de 10 000 points ;
- un historique fiable ;
- l'annulation atomique de la dernière action ;
- une sauvegarde locale après chaque action.

L'application doit pouvoir être posée au centre de la table et utilisée rapidement par plusieurs personnes. L'interface doit privilégier les gros éléments tactiles, la compréhension immédiate et la fluidité de la partie.

---

# 2. Périmètre de la V1

## 2.1 Fonctionnalités obligatoires

La V1 MUST inclure :

- une application Flutter Android installable sous forme d'APK ;
- une utilisation entièrement hors ligne ;
- de 2 à 12 joueurs ;
- un catalogue étendu d'emojis animaux ;
- un animal unique par joueur dans une même partie ;
- une couleur unique par joueur dans une même partie ;
- un nom d'animal par défaut, modifiable avant le lancement ;
- un ordre des joueurs basé sur l'ordre d'ajout ;
- un mode guidé et un mode libre ;
- une grille à une ou deux colonnes, jamais trois ;
- une saisie rapide par `±100` et `±1000` ;
- une option de saisie par `±50`, désactivée par défaut ;
- une sortie minimale paramétrable, 300 points par défaut ;
- trois vies par joueur ;
- un bouton `Passer` ;
- la perte automatique du dernier gain après trois échecs ;
- une pile de gains successifs annulables ;
- la règle de rencontre ;
- l'objectif de 10 000 exactement ;
- le dépassement de 10 000 traité comme un échec ;
- une phase de dernière chance pour tous les autres joueurs ;
- un historique chronologique ;
- l'annulation complète de la dernière action ;
- la reprise d'une partie après fermeture de l'application ;
- un écran de fin et un classement ;
- la conservation de l'historique des joueurs ayant quitté la partie.

## 2.2 Hors périmètre de la V1

Les éléments suivants ne doivent pas ralentir la première livraison :

- version iOS ;
- compte utilisateur ;
- synchronisation cloud ;
- multijoueur entre plusieurs téléphones ;
- publicité ;
- achats intégrés ;
- calcul automatique des combinaisons de dés ;
- reconnaissance des dés par caméra ;
- modification arbitraire d'une ancienne action ;
- statistiques avancées ;
- partage en ligne ;
- sélection manuelle de l'animal ;
- nouveau tirage manuel de l'animal ;
- sélection manuelle de la couleur ;
- glisser-déposer de l'ordre des joueurs ;
- traduction multilingue.

---

# 3. Glossaire métier

## 3.1 Joueur actif

En mode guidé, le joueur dont c'est le tour. Sa tuile possède une bordure lumineuse animée.

## 3.2 Tour

Une action complète d'un joueur :

- validation d'un score positif ;
- passage sans point ;
- dépassement de 10 000 confirmé et transformé en échec.

## 3.3 Manche

En mode guidé, cycle dans lequel chaque joueur actif doit jouer une fois. Le mode libre ne gère pas les manches ordinaires.

## 3.4 Sortie

Premier score valide d'un joueur, supérieur ou égal au minimum configuré.

Exemple par défaut : un joueur doit enregistrer au moins 300 points pour « sortir ».

La sortie, une fois acquise, reste acquise jusqu'à la fin de la partie, même si le joueur redescend ensuite à zéro.

## 3.5 Gain actif

Score positif validé et encore présent dans le total du joueur.

Chaque gain est conservé séparément. Les gains actifs sont ordonnés chronologiquement et forment une pile.

## 3.6 Gain annulé

Ancien gain retiré du total par :

- un troisième échec ;
- une rencontre avec un autre joueur.

Le gain reste dans l'historique avec son motif d'annulation.

## 3.7 Échec

Tour sans score valable. Un échec est produit par :

- le bouton `Passer` ;
- un dépassement de 10 000 confirmé.

Un score inférieur au minimum de sortie n'est pas automatiquement un échec : il est simplement non validable. Le joueur doit corriger sa saisie ou utiliser `Passer`.

## 3.8 Vie

Un cœur rempli. Les vies visualisent la progression vers l'annulation du dernier gain actif.

## 3.9 Rencontre

Situation dans laquelle le score final du joueur qui vient de marquer est exactement égal au score d'un ou plusieurs adversaires actifs.

Chaque adversaire rencontré perd son gain actif le plus récent.

## 3.10 Phase de dernière chance

Phase déclenchée lorsqu'un joueur atteint exactement 10 000. Tous les autres joueurs actifs disposent alors d'un dernier tour.

---

# 4. Invariants du moteur de jeu

Ces règles MUST toujours être vraies.

1. Une partie possède entre 2 et 12 joueurs au lancement.
2. Deux joueurs d'une même partie ne partagent jamais le même emoji attribué.
3. Deux joueurs d'une même partie ne partagent jamais la même couleur de tuile.
4. Le score d'un joueur ne peut jamais être négatif.
5. Le score d'un joueur est égal à la somme de ses gains actifs.
6. Un gain annulé ne participe plus au total mais reste dans l'historique.
7. Le dernier gain annulable est le gain actif le plus récent.
8. Un score positif valide restaure immédiatement les trois vies du joueur qui marque.
9. Un joueur sans gain actif ne perd aucune vie lorsqu'il passe.
10. Lorsqu'un joueur n'a plus aucun gain actif, ses vies sont normalisées à trois.
11. Le troisième échec d'un joueur possédant un gain actif annule exactement un gain : le plus récent.
12. Après un troisième échec, les vies reviennent à trois, même si d'autres gains plus anciens restent actifs.
13. Une rencontre annule exactement un gain actif par victime rencontrée.
14. Une rencontre ne déclenche pas de réaction en chaîne en V0.2.
15. Seul le joueur qui vient réellement de valider un score peut déclencher une rencontre.
16. La victoire nécessite exactement 10 000 points.
17. Un score qui ferait dépasser 10 000 n'est pas ajouté.
18. Un dépassement confirmé compte comme un échec.
19. Chaque action utilisateur et toutes ses conséquences sont atomiques.
20. L'annulation de la dernière action restaure l'état intégral antérieur.
21. Une action validée est sauvegardée avant que l'interface n'autorise l'action suivante.

Formule centrale :

```text
scoreDuJoueur = somme(montant des gains dont le statut est ACTIF)
```

---

# 5. Création d'une partie

## 5.1 Nombre de joueurs

- Minimum : **2**.
- Maximum : **12**.
- Aucun mode solo.
- Pour les tests de développement, utiliser au moins deux joueurs.

Le bouton `Commencer la partie` reste désactivé tant que moins de deux joueurs sont présents.

Le bouton `Ajouter un joueur` devient désactivé lorsque douze joueurs sont présents.

## 5.2 Ajout d'un joueur

À chaque pression sur `+ Ajouter un joueur`, l'application attribue automatiquement :

- un emoji animal aléatoire non utilisé ;
- un nom français par défaut correspondant à cet emoji ;
- une couleur de tuile aléatoire non utilisée ;
- trois cœurs remplis ;
- un score de zéro ;
- une position correspondant à l'ordre d'ajout.

L'animal et la couleur sont tirés indépendamment.

Il n'existe aucun bouton permettant :

- de changer l'animal ;
- de relancer le tirage ;
- de choisir une couleur.

## 5.3 Renommage

Avant le lancement, le nom affiché peut être modifié.

Exemple :

```text
🐧 Pingouin
```

peut devenir :

```text
🐧 Bertrand
```

L'emoji et la couleur restent inchangés.

Contraintes recommandées :

- nom obligatoire après suppression des espaces de début et de fin ;
- 1 à 16 caractères visibles ;
- noms identiques autorisés, même si l'interface peut avertir ;
- pas de second sous-titre ;
- le nom personnalisé remplace visuellement le nom de l'animal.

Les noms sont verrouillés après le démarrage de la partie dans la V1.

## 5.4 Suppression avant lancement

Avant le démarrage, un joueur peut être supprimé définitivement.

Son animal et sa couleur retournent dans les réserves et peuvent être attribués à un futur joueur.

## 5.5 Ordre des joueurs

L'ordre de jeu correspond à l'ordre d'ajout, supposé suivre l'ordre autour de la table.

Le glisser-déposer n'est pas requis dans la V1.

## 5.6 Verrouillage au lancement

Après pression sur `Commencer` :

- aucun joueur ne peut être ajouté ;
- les animaux sont verrouillés ;
- les couleurs sont verrouillées ;
- les noms sont verrouillés ;
- l'ordre est verrouillé ;
- les règles de la partie sont figées ;
- une première sauvegarde est créée ;
- le premier joueur devient actif en mode guidé.

---

# 6. Catalogue des animaux et attribution aléatoire

## 6.1 Principe

Le catalogue ne doit pas être limité à douze animaux. Il doit contenir un large panel couvrant les emojis animaux Unicode, notamment :

```text
🦄 🐲 🐗 🫎 🐩 🦖
```

ainsi que les mammifères, oiseaux, reptiles, animaux marins, insectes, animaux fantastiques et variantes de visages animaux décrits dans l'annexe A.

Le catalogue V0.2 est basé sur les catégories animales d'Unicode Emoji 17.0.

## 6.2 Règles de sélection

- Un emoji exact ne peut apparaître qu'une seule fois dans une partie.
- Le tirage se fait sans remise.
- Il y a beaucoup plus d'animaux disponibles que de places de joueurs.
- Les douze joueurs maximum reçoivent donc douze animaux parmi le catalogue complet.
- Les animaux supprimés avant le lancement redeviennent disponibles.

## 6.3 Familles proches

Le catalogue SHOULD associer un `familyId` aux variantes proches :

```text
dog      -> 🐶 🐕 🦮 🐕‍🦺 🐩
cat      -> 🐱 🐈 🐈‍⬛ 😺 😸 😹 😻 😼 😽 🙀 😿 😾
monkey   -> 🐵 🐒 🙈 🙉 🙊
tiger    -> 🐯 🐅
horse    -> 🐴 🐎
cow      -> 🐮 🐄
pig      -> 🐷 🐖 🐽
mouse    -> 🐭 🐁
rabbit   -> 🐰 🐇
chick    -> 🐣 🐤 🐥
bird     -> 🐦 🐦‍⬛
dragon   -> 🐲 🐉
whale    -> 🐳 🐋
```

Pour une meilleure diversité visuelle, le tirage SHOULD éviter deux animaux de la même famille dans une partie tant qu'au moins douze familles différentes sont disponibles.

Cette règle n'empêche pas les variantes d'apparaître dans des parties différentes.

## 6.4 Emojis associés à la nature mais non utilisés comme totems par défaut

Le catalogue de référence peut conserver les symboles suivants, mais ils ne doivent pas être tirés comme identité de joueur par défaut :

```text
🐾 Empreintes
🪶 Plume
🪽 Aile
🐚 Coquillage
🕸️ Toile d'araignée
🦠 Microbe
```

Ils ne représentent pas clairement un animal individuel. Ils peuvent être activés plus tard par une option interne.

## 6.5 Compatibilité d'affichage

La V1 utilise les emojis fournis par la police système Android.

Conséquence connue : les emojis Unicode les plus récents peuvent ne pas être rendus sur d'anciens appareils.

La V1 SHOULD :

- conserver un identifiant stable par animal ;
- prévoir un emoji de secours pour les entrées très récentes ;
- ne jamais dépendre du réseau pour afficher un animal ;
- documenter les appareils de test utilisés.

Une future version MAY remplacer le rendu système par des illustrations embarquées sous licence adaptée.

---

# 7. Palette de douze couleurs

Les couleurs sont attribuées sans remise et indépendamment des animaux.

Palette initiale recommandée :

| ID | Nom | Couleur | Texte recommandé |
|---|---|---:|---|
| `cobalt` | Bleu cobalt | `#1565C0` | blanc |
| `orange` | Orange brûlé | `#EF6C00` | blanc |
| `forest` | Vert forêt | `#2E7D32` | blanc |
| `ruby` | Rouge rubis | `#C62828` | blanc |
| `purple` | Violet profond | `#6A1B9A` | blanc |
| `teal` | Turquoise foncé | `#00796B` | blanc |
| `raspberry` | Framboise | `#AD1457` | blanc |
| `amber` | Ambre | `#F9A825` | noir |
| `indigo` | Indigo | `#283593` | blanc |
| `cyan` | Cyan foncé | `#00838F` | blanc |
| `brown` | Brun | `#6D4C41` | blanc |
| `slate` | Ardoise | `#455A64` | blanc |

Les valeurs exactes peuvent être affinées après contrôle visuel, mais les contraintes suivantes sont obligatoires :

- douze couleurs réellement distinctes ;
- aucune duplication dans une partie ;
- contraste suffisant avec les textes ;
- l'identité d'un joueur ne repose jamais uniquement sur la couleur ;
- emoji et nom restent toujours visibles.

---

# 8. Écran principal de jeu

## 8.1 Contenu d'une tuile

Chaque tuile affiche uniquement :

1. l'emoji animal ;
2. le nom affiché ;
3. trois cœurs ;
4. le score total ;
5. le dernier gain actif.

Exemple :

```text
┌──────────────────────────────┐
│ 🐧 BERTRAND             ♥♥♡ │
│                              │
│            2 300             │
│                              │
│ Dernier gain : +500          │
└──────────────────────────────┘
```

La tuile ne doit pas afficher :

- un compteur textuel d'échecs ;
- une mention permanente de pénalité ;
- des statistiques secondaires ;
- un texte « À TOI » dans la carte.

Les cœurs représentent déjà les échecs.

## 8.2 Dernier gain affiché

`Dernier gain` correspond au sommet de la pile de gains actifs.

Exemple :

```text
Gains actifs : +1 000, +800, +500
Score : 2 300
Dernier gain affiché : +500
```

Après annulation du gain de 500 :

```text
Gains actifs : +1 000, +800
Score : 1 800
Dernier gain affiché : +800
```

S'il n'existe aucun gain actif :

```text
Dernier gain : —
```

## 8.3 Disposition responsive

Règle définitive :

| Nombre de joueurs actifs | Disposition |
|---:|---|
| 2 à 4 | une seule colonne |
| 5 à 12 | deux colonnes |

L'application ne doit **jamais** afficher trois colonnes ou davantage, quelle que soit la largeur de l'écran ou son orientation.

Si toutes les tuiles ne tiennent pas dans l'espace disponible :

- la zone des tuiles devient verticalement défilable ;
- l'en-tête et les actions principales restent accessibles ;
- l'application ne réduit pas les textes jusqu'à les rendre illisibles.

Jusqu'à quatre joueurs, l'interface SHOULD essayer d'afficher toutes les tuiles sans défilement, mais le défilement reste autorisé sur les petits écrans ou avec une grande taille de police.

À partir de cinq joueurs, le défilement est normal et attendu.

## 8.4 Joueur actif

En mode guidé, la tuile active possède :

- une bordure claire ou blanche ;
- un léger halo ;
- une animation douce du contour ;
- aucune augmentation notable de taille ;
- aucune pulsation de toute la carte.

L'animation ne doit pas être agressive, clignotante ou coûteuse en performances.

## 8.5 Phrase de tour

Le haut de l'écran affiche une phrase utilisant le nom affiché du joueur actif.

Exemples :

```text
Bertrand, à toi de jouer !
Bertrand, lance tes dés !
Fais-les rouler, Bertrand !
Que la chance soit avec toi, Bertrand !
Bertrand, fais trembler la table !
Make it roll, Bertrand!
```

L'application ne répète pas la même phrase deux tours de suite si plusieurs phrases sont disponibles.

---

# 9. Modes de tour

## 9.1 Mode guidé

Le mode guidé est le mode par défaut.

Règles :

- un seul joueur est actif ;
- seul son tour doit normalement être enregistré ;
- toucher sa tuile ouvre la saisie ;
- le bouton `Passer` concerne ce joueur ;
- après son action, le moteur choisit le prochain joueur autorisé ;
- une manche se termine lorsque chaque joueur actif a joué une fois ;
- le numéro de manche augmente ensuite.

### Sélection exceptionnelle d'un autre joueur

Si l'utilisateur touche une autre tuile :

```text
Ce n'est pas au tour de Panda.
Faire jouer Panda maintenant ?

[Annuler] [Choisir Panda]
```

Choisir Panda :

- ne retire aucune vie aux joueurs sautés ;
- ne crée aucun événement d'échec pour eux ;
- ne leur fait pas perdre leur droit de jouer dans la manche ;
- rend Panda actif.

Le moteur conserve une liste `pendingPlayersInRound`.

Un joueur ayant déjà joué dans la manche ne peut pas rejouer une deuxième fois en mode guidé ordinaire.

Quand la liste devient vide :

- la manche augmente de 1 ;
- la liste est recréée avec tous les joueurs encore actifs ;
- le prochain joueur est choisi selon l'ordre de table.

## 9.2 Mode libre

En mode libre :

- aucune tuile n'est active en permanence ;
- toutes les tuiles de joueurs actifs sont interactives ;
- aucun ordre de tour n'est imposé ;
- les manches ordinaires ne sont pas comptabilisées ;
- toucher une tuile ouvre ses actions ;
- l'historique conserve l'ordre réel des actions.

La phase de dernière chance conserve néanmoins une liste des joueurs qui ont ou non utilisé leur ultime tour.

---

# 10. Saisie d'un score

## 10.1 Ouverture

Toucher la tuile autorisée ouvre une modale ou une feuille remontant depuis le bas.

Disposition attendue :

```text
┌────────────────────────────────┐
│ 🐧 Bertrand — score du tour    │
│                                │
│             2 300              │
│                                │
│ ┌────────────┐  ┌────────────┐ │
│ │    -100    │  │    +100    │ │
│ ├────────────┤  ├────────────┤ │
│ │   -1000    │  │   +1000    │ │
│ └────────────┘  └────────────┘ │
│                                │
│ Effacer        Valider +2 300  │
└────────────────────────────────┘
```

Les boutons négatifs sont rouges à gauche. Les boutons positifs sont verts à droite.

## 10.2 Score provisoire

- La saisie commence à zéro.
- `+100` ajoute 100.
- `+1000` ajoute 1 000.
- `-100` retire 100 du provisoire.
- `-1000` retire 1 000 du provisoire.
- Le provisoire ne descend jamais sous zéro.
- Les boutons négatifs ne touchent jamais directement au score du joueur.
- `Effacer` remet le provisoire à zéro.
- Chaque pression rapide doit être comptée.
- Une double pression sur `Valider` ne doit produire qu'une seule action.

Exemple pour 2 300 :

```text
+1000
+1000
+100
+100
+100
```

## 10.3 Option des cinquante

Par défaut :

```text
scoreStep = 100
```

Les boutons `-50` et `+50` sont alors totalement masqués.

Si l'option `Multiples de 50` est activée :

```text
scoreStep = 50
```

La modale affiche deux actions secondaires :

```text
-50                    +50
```

L'objectif reste exactement 10 000 dans les deux modes.

## 10.4 Validation

Le bouton `Valider` est actif uniquement si :

- le provisoire est strictement positif ;
- il respecte le pas configuré ;
- il respecte la sortie minimale si le joueur n'est pas encore sorti.

La validation :

1. envoie une commande au moteur ;
2. attend le résultat ;
3. persiste l'action ;
4. ferme la modale ;
5. met à jour le plateau ;
6. passe au joueur suivant si nécessaire.

## 10.5 Fermeture avec saisie en cours

Si le provisoire est non nul :

```text
Abandonner la saisie de 2 300 points ?

[Continuer la saisie] [Abandonner]
```

Fermer l'application pendant une saisie provisoire ne doit jamais modifier le score réel. À la reprise, la partie revient au plateau ; la saisie non validée peut être abandonnée dans la V1.

---

# 11. Règle de sortie

## 11.1 Valeur par défaut

```text
minimumEntryScore = 300
```

La valeur est paramétrable avant le lancement.

Options proposées :

```text
Aucune
300
500
1 000
Personnalisée
```

La valeur personnalisée doit être compatible avec le pas de score choisi.

## 11.2 Joueur non sorti

Tant que `hasEnteredGame == false` :

- un score inférieur au minimum ne peut pas être validé ;
- un score égal ou supérieur peut être validé ;
- utiliser `Passer` ne retire aucune vie si aucun gain actif n'existe.

Exemple :

```text
Sortie minimale : 300
Score provisoire : 200
```

Le bouton de validation reste désactivé et le message suivant peut apparaître :

```text
Minimum de sortie : 300 points.
```

## 11.3 Sortie acquise définitivement

Après un premier score valide :

```text
hasEnteredGame = true
```

Cette valeur ne revient jamais à `false` pendant la partie.

Exemple :

```text
Bertrand sort avec +300.
Plus tard, tous ses gains sont annulés et son score revient à 0.
Il peut ensuite enregistrer +100.
```

---

# 12. Bouton Passer et vies

## 12.1 Interaction

Les cœurs ne sont pas des boutons dans la V1.

En mode guidé, un bouton fixe concerne le joueur actif :

```text
[ Passer — Bertrand ne marque aucun point ]
```

En mode libre, l'action est disponible dans la modale du joueur :

```text
[ Passer le tour de Bertrand ]
```

Si une saisie provisoire non nulle existe et que l'utilisateur choisit de passer :

```text
Abandonner 600 points et passer le tour ?

[Continuer] [Abandonner et passer]
```

## 12.2 Passage sans gain actif

Si la pile de gains actifs est vide :

- le passage est enregistré dans l'historique ;
- aucune vie n'est retirée ;
- les vies restent ou reviennent à trois ;
- le tour passe au suivant.

Cela couvre :

- un joueur jamais sorti ;
- un joueur sorti mais revenu à zéro après annulation de tous ses gains.

## 12.3 Passage avec gain actif

Si au moins un gain est actif :

- premier échec : 2 vies ;
- deuxième échec : 1 vie ;
- troisième échec : annulation du dernier gain actif puis retour à 3 vies.

Représentation :

```text
Départ      ♥ ♥ ♥
1er échec   ♥ ♥ ♡
2e échec    ♥ ♡ ♡
3e échec    ♡ ♡ ♡ -> annulation -> ♥ ♥ ♥
```

## 12.4 Score réussi après un ou deux échecs

Tout score positif accepté restaure trois vies avant la fin de résolution de l'action.

Exemple :

```text
Bertrand : ♥♡♡
Bertrand marque +400
Résultat : ♥♥♥
```

## 12.5 Confirmation du troisième échec

Activée par défaut :

```text
Troisième échec de Bertrand

Son dernier gain de 800 points sera annulé.
Il passera de 1 800 à 1 000 points.

[Annuler] [Confirmer l'échec]
```

Cette confirmation peut être désactivée dans les paramètres de partie.

---

# 13. Modèle central : pile de gains

Cette section est fondamentale et doit être implémentée exactement.

Chaque score positif validé crée un objet `Gain` distinct et l'ajoute en haut de la pile des gains actifs du joueur.

Exemple :

```text
Tour A : +1 000
Tour B : +800
Tour C : +500
```

État :

```text
Pile active, du plus ancien au plus récent : [1000, 800, 500]
Score total : 2 300
Dernier gain : 500
```

## 13.1 Annulation par rencontre

Pingouin arrive à 2 300 et rencontre Renard.

Renard perd le sommet de sa pile :

```text
Gain annulé : 500
Pile restante : [1000, 800]
Nouveau score : 1 800
Dernier gain : 800
```

## 13.2 Troisième échec ultérieur

Renard joue ensuite plusieurs tours sans point. Lorsqu'il perd son troisième cœur, il ne perd pas de nouveau les 500 déjà annulés.

Il perd le nouveau sommet de sa pile :

```text
Gain annulé : 800
Pile restante : [1000]
Nouveau score : 1 000
Dernier gain : 1000
Vies restaurées : 3
```

Une nouvelle série de trois échecs annulerait ensuite les 1 000 restants :

```text
Pile restante : []
Score : 0
Dernier gain : —
Vies : 3
```

## 13.3 Conséquence importante

Les tours sans point ne créent pas de nouveaux « paliers de score ».

Le retour au score précédent signifie toujours :

```text
score actuel - montant du dernier gain actif
```

et non :

```text
score affiché au tour immédiatement précédent
```

Un passage ne modifie pas la pile. Une rencontre ou un troisième échec retire une couche de la pile.

---

# 14. Règle de rencontre

## 14.1 Déclenchement

Après validation d'un score positif et avant la vérification finale de victoire, le moteur compare le nouveau total du joueur avec les scores des autres joueurs actifs.

Si un ou plusieurs adversaires possèdent exactement ce total, il y a rencontre.

## 14.2 Effet sur une victime

Pour chaque victime :

1. prendre son gain actif le plus récent ;
2. le marquer comme annulé par rencontre ;
3. soustraire son montant du total ;
4. conserver l'événement dans l'historique ;
5. mettre à jour son dernier gain affiché.

Le joueur qui vient de marquer conserve entièrement son nouveau score.

## 14.3 Exemple simple

```text
Renard possède : [1000, 800, 500] = 2 300
Pingouin arrive à 2 300
```

Résultat :

```text
Pingouin reste à 2 300
Renard perd 500
Renard revient à 1 800
```

## 14.4 Rencontre multiple

Si plusieurs joueurs sont au même score :

```text
Renard : 2 300
Panda : 2 300
Pingouin arrive à 2 300
```

Résultat :

- Pingouin reste à 2 300 ;
- Renard perd son dernier gain actif ;
- Panda perd son dernier gain actif.

Toutes les conséquences appartiennent à la même action atomique.

## 14.5 Pas de réaction en chaîne en V0.2

Supposons :

```text
Renard passe de 2 300 à 1 800 à cause de Pingouin.
Panda se trouve déjà à 1 800.
```

Panda ne subit rien.

La baisse de Renard est une conséquence indirecte et ne déclenche pas une nouvelle rencontre.

Cette décision est volontairement figée pour la V0.2, mais pourra être revalidée plus tard selon les règles du groupe.

## 14.6 Vies de la victime

Une rencontre ne constitue pas un échec de la victime.

Par défaut :

- ses vies actuelles sont conservées ;
- si elle possédait encore d'autres gains actifs, un futur troisième échec peut annuler le gain précédent ;
- si la rencontre vide complètement sa pile de gains, ses vies sont remises à trois.

Exemple important :

```text
Renard possède une seule vie et les gains [1000, 800, 500].
Pingouin rencontre Renard et annule les 500.
Renard reste à une vie avec les gains [1000, 800].
Au prochain échec, son dernier cœur tombe et les 800 sont annulés.
```

## 14.7 Joueurs ignorés

Ne participent pas aux rencontres :

- les joueurs ayant quitté la partie ;
- les joueurs supprimés avant le lancement ;
- le joueur qui vient de marquer lui-même.

---

# 15. Objectif exact et dépassement

## 15.1 Objectif

```text
targetScore = 10 000
winMode = exact
```

Un joueur ne gagne qu'en atteignant exactement 10 000.

## 15.2 Score valide

```text
Score actuel : 9 700
Gain : +300
Résultat : 10 000
```

Le score est accepté.

## 15.3 Dépassement

```text
Score actuel : 9 700
Gain tenté : +400
Résultat théorique : 10 100
```

Le gain n'est pas créé.

L'application affiche une confirmation :

```text
Ce score ferait monter Bertrand à 10 100 points.
Dépasser 10 000 compte comme un échec.
Le score ne sera pas enregistré.

[Corriger] [Confirmer l'échec]
```

Après confirmation :

- le total reste inchangé ;
- l'événement mémorise le montant tenté ;
- le tour devient un échec ;
- la règle des vies est appliquée ;
- un troisième échec peut annuler le dernier gain actif ;
- le tour se termine.

Si l'utilisateur choisit `Corriger`, la modale reste ouverte.

---

# 16. Phase de dernière chance

## 16.1 Déclenchement

Lorsqu'un joueur termine la résolution de son action à exactement 10 000, la partie passe en statut :

```text
FINAL_CHANCE
```

Ce joueur devient le candidat actuel à la victoire et n'obtient pas un nouveau tour.

Tous les autres joueurs actifs reçoivent exactement une dernière action.

Cette liste est construite indépendamment de la manche ordinaire : un joueur obtient sa dernière chance même s'il avait déjà joué plus tôt dans la manche au cours de laquelle les 10 000 ont été atteints. La manche ordinaire est alors interrompue au profit de la phase finale.

## 16.2 Ordre en mode guidé

L'ordre commence au joueur suivant autour de la table et continue avec retour au début.

Exemple :

```text
Ordre : Pingouin, Renard, Panda, Grenouille
Panda atteint 10 000
```

Ordre des dernières chances :

```text
Grenouille
Pingouin
Renard
```

Panda ne rejoue pas.

Le bandeau affiche par exemple :

```text
Dernière chance — au tour de Grenouille
3 joueurs doivent encore jouer
```

## 16.3 Mode libre

Tous les autres joueurs sont marqués comme ayant une dernière chance disponible.

Ils peuvent agir dans n'importe quel ordre. Une fois leur action validée, leur tuile devient inactive pour cette phase.

## 16.4 Rencontre à 10 000

La règle de rencontre continue de s'appliquer.

Exemple :

```text
Pingouin est à 10 000.
Renard utilise sa dernière chance et atteint 10 000.
```

Renard rencontre Pingouin :

- Renard reste à 10 000 ;
- Pingouin perd son dernier gain actif ;
- Pingouin redescend à son palier précédent ;
- Renard devient le nouveau candidat à la victoire.

La phase continue pour les joueurs qui n'ont pas encore utilisé leur dernière chance.

Le premier candidat délogé ne reçoit pas un nouveau tour.

## 16.5 Fin de la phase

Lorsque tous les joueurs autorisés ont joué leur dernière chance :

- le joueur encore présent à 10 000 gagne ;
- la partie passe à `FINISHED` ;
- les tuiles deviennent non interactives ;
- l'écran de résultat s'ouvre.

Grâce à la rencontre à 10 000, un seul joueur doit rester à 10 000.

---

# 17. Joueur quittant la partie

## 17.1 Avant le lancement

Action : suppression définitive.

## 17.2 Après le lancement

Action disponible dans un menu secondaire :

```text
Faire quitter la partie à Bertrand ?

Son historique et son score seront conservés.

[Annuler] [Confirmer]
```

Après confirmation :

- `hasLeftGame = true` ;
- le joueur disparaît du plateau actif ou passe dans une section inactive ;
- son historique reste disponible ;
- son score final reste consultable ;
- son animal et sa couleur ne sont pas réattribués ;
- il est retiré de la rotation ;
- il est retiré des joueurs restant dans la manche ;
- il est retiré des dernières chances en attente ;
- il ne peut plus être rencontré ;
- il ne peut plus gagner.

S'il était actif, le moteur choisit immédiatement le prochain joueur autorisé.

Pendant `FINAL_CHANCE`, un joueur encore en attente peut quitter et est retiré de la liste. En revanche, le candidat actuellement à 10 000 ne peut pas quitter individuellement dans la V1 : il faut annuler l'action ayant créé ou transféré sa candidature, ou abandonner la partie entière.

Si moins de deux joueurs actifs restent, l'application affiche une proposition de fin anticipée ou d'abandon de partie.

---

# 18. Historique

## 18.1 Objectif

L'historique sert à :

- expliquer chaque variation de score ;
- retrouver les gains encore actifs ;
- comprendre les rencontres ;
- permettre l'annulation ;
- restaurer la partie après fermeture ;
- produire le classement final.

## 18.2 Vue globale

Exemple :

```text
MANCHE 3

Bertrand marque +500
Total : 2 300
Vies restaurées : 3

Rencontre avec Renard
Gain de Renard annulé : -500
Renard revient à 1 800

Panda passe
2 vies restantes
```

## 18.3 Types d'entrées

L'historique doit distinguer :

- score validé ;
- passage protégé sans perte de vie ;
- passage avec perte d'une vie ;
- troisième échec ;
- gain annulé par troisième échec ;
- dépassement de 10 000 ;
- gain annulé par rencontre ;
- rencontre multiple ;
- début de dernière chance ;
- joueur ayant quitté ;
- fin de partie ;
- action annulée.

## 18.4 Gains annulés

Un gain annulé n'est jamais supprimé de l'historique.

Il reçoit :

```text
status = cancelled
cancelReason = thirdMiss | encounter
cancelledByActionId = ...
```

---

# 19. Annulation de la dernière action

## 19.1 Principe

Un bouton global `Annuler` annule uniquement la dernière action complète non annulée.

Une action peut contenir plusieurs effets.

Exemple : Bertrand marque 500, rencontre Renard et Panda, déclenche la dernière chance.

Une seule annulation doit :

- retirer le gain de Bertrand ;
- restaurer son ancien score ;
- restaurer ses anciennes vies ;
- réactiver le gain de Renard ;
- restaurer le score de Renard ;
- réactiver le gain de Panda ;
- restaurer le score de Panda ;
- annuler la phase de dernière chance ;
- restaurer le joueur actif ;
- restaurer la liste de manche ;
- restaurer toutes les métadonnées antérieures.

## 19.2 Cas du troisième échec

Avant :

```text
Score : 2 300
Vies : 1
Pile : [1000, 800, 500]
```

Après troisième échec :

```text
Score : 1 800
Vies : 3
Pile : [1000, 800]
```

Après annulation :

```text
Score : 2 300
Vies : 1
Pile : [1000, 800, 500]
Le joueur redevient actif
```

## 19.3 Limites de la V1

- Pas de modification d'une action ancienne arbitraire.
- Pas de redo obligatoire.
- L'annulation d'un départ de joueur SHOULD être possible si c'est la dernière action.
- Les actions déjà annulées restent auditables dans le journal technique.

---

# 20. Écrans et navigation

## 20.1 Accueil

Contenu :

- logo ou titre 10K ;
- `Nouvelle partie` ;
- `Reprendre la partie` si une partie active existe ;
- accès aux parties terminées ;
- accès aux informations de l'application.

Une seule partie active à la fois est suffisante pour la V1.

Créer une nouvelle partie alors qu'une partie est active nécessite une confirmation.

## 20.2 Préparation

Contenu :

- liste/grille des joueurs ;
- bouton `Ajouter un joueur` ;
- modification des noms ;
- suppression des joueurs ;
- résumé des règles ;
- accès aux paramètres ;
- bouton `Commencer`.

## 20.3 Paramètres de partie

Doit être accessible avant le lancement.

## 20.4 Plateau

Contenu :

- phrase de tour ou état de la partie ;
- numéro de manche en mode guidé ;
- grille défilable ;
- bouton `Passer` en mode guidé ;
- bouton `Annuler` ;
- accès à l'historique ;
- menu de partie.

## 20.5 Modale de score

Contenu décrit dans la section 10.

## 20.6 Historique

- vue globale chronologique ;
- filtre facultatif par joueur ;
- détail des rencontres et gains annulés.

## 20.7 Résultat

Exemple :

```text
VICTOIRE

🐧 BERTRAND
10 000 points

1. Bertrand       10 000
2. Panda           9 800
3. Renard          8 500
4. Grenouille      7 200

[Nouvelle partie]
[Rejouer avec les mêmes noms]
[Voir l'historique]
```

`Rejouer avec les mêmes noms` :

- recrée une partie ;
- conserve les noms et l'ordre ;
- réattribue de nouveaux animaux et de nouvelles couleurs aléatoires ;
- remet les scores et vies à zéro ;
- conserve les mêmes règles, sauf modification par l'utilisateur.

## 20.8 Parties terminées

Chaque partie terminée peut afficher :

- date ;
- gagnant ;
- joueurs ;
- score final ;
- historique ;
- durée facultative.

---

# 21. Paramètres de partie V1

## 21.1 Mode de tours

```text
● Guidé
○ Libre
```

Défaut : `Guidé`.

## 21.2 Sortie minimale

```text
○ Aucune
● 300
○ 500
○ 1 000
○ Personnalisée
```

Défaut : `300`.

## 21.3 Pas de score

```text
● Multiples de 100
○ Multiples de 50
```

Défaut : `100`.

## 21.4 Confirmation du troisième échec

```text
Confirmer avant l'annulation du dernier gain
[Activé]
```

Défaut : activé.

## 21.5 Règles fixes en V1

Les règles suivantes ne sont pas exposées comme options dans la première interface :

```text
Objectif : 10 000 exactement
Dépassement : échec
Nombre de vies : 3
Rencontres : activées
Rencontre multiple : toutes les victimes
Réaction en chaîne : désactivée
Dernière chance : un tour pour tous les autres joueurs
Ajout après lancement : interdit
```

Elles doivent néanmoins être représentées proprement dans `GameRules` afin de pouvoir devenir configurables plus tard.

---

# 22. Ordre exact de résolution d'une action de score

Le moteur MUST respecter cet ordre :

```text
1. Vérifier que la partie accepte encore une action.
2. Vérifier que le joueur est actif et autorisé à jouer.
3. Vérifier que le montant est strictement positif.
4. Vérifier qu'il respecte le pas de score.
5. Vérifier le minimum de sortie si nécessaire.
6. Calculer le futur total.
7. Si le futur total dépasse 10 000 :
   a. ne créer aucun gain ;
   b. enregistrer un dépassement ;
   c. appliquer la logique d'échec ;
   d. appliquer éventuellement le troisième échec ;
   e. terminer le tour ;
   f. sauvegarder ;
   g. choisir le prochain joueur.
8. Sinon :
   a. créer un nouveau gain actif ;
   b. ajouter son montant au total ;
   c. marquer la sortie comme acquise si nécessaire ;
   d. restaurer les trois vies du joueur.
9. Rechercher les joueurs rencontrés au nouveau total.
10. Pour chaque victime :
    a. annuler son dernier gain actif ;
    b. recalculer son total ;
    c. conserver ses vies, sauf pile devenue vide ;
    d. ne déclencher aucune rencontre secondaire.
11. Vérifier si le joueur qui a marqué est à 10 000.
12. Démarrer ou mettre à jour la phase de dernière chance.
13. Construire une action contenant tous les effets.
14. Persister l'action et le nouvel état dans une transaction.
15. Publier le nouvel état à l'interface.
16. Sélectionner le prochain joueur autorisé.
```

---

# 23. Ordre exact de résolution d'un passage

```text
1. Vérifier que le joueur est autorisé à agir.
2. Créer l'événement de passage.
3. Si le joueur ne possède aucun gain actif :
   a. ne retirer aucune vie ;
   b. normaliser les vies à 3 ;
   c. terminer le tour.
4. Sinon :
   a. retirer une vie ;
   b. si une ou deux vies restent, terminer le tour ;
   c. si la troisième vie vient d'être perdue :
      i. annuler le dernier gain actif ;
      ii. recalculer le score ;
      iii. restaurer 3 vies.
5. Persister l'action atomique.
6. Choisir le prochain joueur.
```

Le même algorithme est utilisé pour un dépassement, avec un type d'événement distinct.

---

# 24. Modèle de données recommandé

Le domaine doit être écrit en Dart pur et ne dépendre ni de Flutter, ni de la base de données, ni des widgets.

## 24.1 Énumérations

```text
GameStatus
- setup
- inProgress
- finalChance
- finished
- archived

TurnMode
- guided
- free

ScoreStep
- fifty
- hundred

GainStatus
- active
- cancelled

GainCancelReason
- thirdMiss
- encounter
- undone

GameActionType
- playerAdded
- playerRenamed
- playerRemovedBeforeStart
- gameStarted
- scoreRecorded
- passRecorded
- overshootRecorded
- playerLeft
- gameFinished
- actionUndone
```

## 24.2 AnimalAvatar

```text
AnimalAvatar
- id: String
- emoji: String
- defaultFrenchName: String
- familyId: String
- unicodeVersion: String?
- fallbackEmoji: String?
- eligibleForRandomDraw: bool
```

Contraintes :

- `id` est stable et indépendant du nom affiché ;
- `emoji` peut être une séquence Unicode composée de plusieurs points de code ;
- ne jamais découper un emoji selon sa longueur de chaîne ;
- le nom personnalisé du joueur n'altère jamais l'entrée du catalogue.

## 24.3 ColorToken

```text
ColorToken
- id: String
- backgroundArgb: int
- foregroundArgb: int
- optionalAccentArgb: int
```

## 24.4 GameRules

```text
GameRules
- targetScore: int                 // 10000
- exactTargetRequired: bool        // true
- scoreStep: int                   // 100 par défaut, 50 en option
- minimumEntryScore: int           // 300 par défaut
- maxLives: int                    // 3
- turnMode: TurnMode               // guided par défaut
- confirmThirdMiss: bool           // true par défaut
- encounterEnabled: bool           // true
- encounterAffectsAllMatches: bool // true
- encounterChainsEnabled: bool     // false en V0.2
- overshootCountsAsMiss: bool      // true
- finalChanceEnabled: bool         // true
```

Même les règles fixes de la V1 doivent être stockées explicitement.

## 24.5 Player

```text
Player
- id: String
- avatarId: String
- colorId: String
- displayName: String
- seatIndex: int
- lives: int
- hasEnteredGame: bool
- hasLeftGame: bool
- gainIds: List<String>
- createdAt: DateTime
```

Le score ne doit pas être une valeur modifiée de manière indépendante des gains.

Deux approches acceptables :

1. calculer le score à chaque lecture à partir des gains actifs ;
2. conserver un cache `score`, mais le vérifier systématiquement contre la somme des gains actifs.

La première approche est la référence métier.

Propriétés dérivées :

```text
activeGains
activeGainStack
score
lastActiveGain
hasActiveGain
isEligibleToPlay
```

## 24.6 Gain

```text
Gain
- id: String
- playerId: String
- amount: int
- status: GainStatus
- createdByActionId: String
- createdAt: DateTime
- cancelledByActionId: String?
- cancelReason: GainCancelReason?
- cancelledAt: DateTime?
```

Les gains sont triés par ordre de création. Le dernier gain actif est celui qui possède la date ou la séquence la plus récente parmi les gains actifs.

## 24.7 GameAction

Une action représente une intention utilisateur complète et tous ses effets dérivés.

```text
GameAction
- id: String
- gameId: String
- type: GameActionType
- primaryPlayerId: String?
- createdAt: DateTime
- roundNumber: int?
- attemptedScore: int?
- effects: List<GameEffect>
- isUndone: bool
- undoneAt: DateTime?
```

## 24.8 GameEffect

```text
GameEffect
- id: String
- type: GameEffectType
- targetPlayerId: String?
- gainId: String?
- delta: int?
- previousValue: JSON-compatible value?
- nextValue: JSON-compatible value?
- metadata: Map<String, JSON-compatible value>
```

Effets attendus :

```text
scoreGainCreated
lifeLost
livesRestored
playerEnteredGame
gainCancelledByThirdMiss
gainCancelledByEncounter
encounterTriggered
roundAdvanced
currentPlayerChanged
finalChanceStarted
finalChanceConsumed
winnerCandidateChanged
playerMarkedAsLeft
gameStatusChanged
```

## 24.9 RoundState

```text
RoundState
- roundNumber: int
- currentPlayerId: String?
- pendingPlayerIds: List<String>
- completedPlayerIds: List<String>
```

Utilisé uniquement en mode guidé ordinaire.

## 24.10 FinalChanceState

```text
FinalChanceState
- triggerActionId: String
- initialCandidatePlayerId: String
- currentCandidatePlayerId: String
- pendingPlayerIds: List<String>
- completedPlayerIds: List<String>
- currentPlayerId: String?
```

## 24.11 GameState

```text
GameState
- id: String
- status: GameStatus
- rules: GameRules
- players: List<Player>
- gains: List<Gain>
- actions: List<GameAction>
- roundState: RoundState?
- finalChanceState: FinalChanceState?
- createdAt: DateTime
- updatedAt: DateTime
- finishedAt: DateTime?
- winnerPlayerId: String?
- schemaVersion: int
```

---

# 25. API publique du moteur de jeu

Le moteur SHOULD exposer une API proche de :

```text
GameTransition apply(GameState state, GameCommand command)
```

avec :

```text
GameTransition
- previousState
- nextState
- action
- userMessages
```

Le moteur ne montre aucune modale et ne dépend d'aucun contexte Flutter. Il retourne des résultats structurés que l'interface transforme en confirmations ou animations.

## 25.1 Commandes de préparation

```text
CreateGame
AddPlayer
RenamePlayer
RemovePlayerBeforeStart
UpdateRules
StartGame
```

## 25.2 Commandes en partie

```text
SelectGuidedPlayer
RecordScore(playerId, amount)
PassTurn(playerId, reason)
LeaveGame(playerId)
UndoLastAction
```

`reason` peut valoir :

```text
manualPass
overshoot
```

## 25.3 Résultats et erreurs métier

Le moteur ne doit pas lever d'exception pour une erreur utilisateur normale.

Il retourne un résultat typé :

```text
Success(GameTransition)
Failure(GameRuleViolation)
```

Violations attendues :

```text
notEnoughPlayers
maximumPlayersReached
gameAlreadyStarted
gameNotStarted
gameAlreadyFinished
playerNotFound
playerHasLeft
playerNotAllowedToPlay
playerAlreadyPlayedThisRound
invalidScoreStep
scoreMustBePositive
entryMinimumNotReached
confirmationRequiredForOvershoot
confirmationRequiredForThirdMiss
noActionToUndo
```

Les confirmations sont gérées par l'application avant l'envoi de la commande finale ou via un champ `confirmed` explicite.

---

# 26. Machine à états de la partie

```text
SETUP
  -> IN_PROGRESS lors de StartGame

IN_PROGRESS
  -> FINAL_CHANCE lorsqu'un joueur atteint exactement 10 000
  -> FINISHED en cas de fin anticipée confirmée

FINAL_CHANCE
  -> FINISHED lorsque tous les derniers tours sont consommés
  -> IN_PROGRESS uniquement si l'action déclenchant la phase est annulée

FINISHED
  -> ARCHIVED lorsque l'utilisateur archive la partie
  -> IN_PROGRESS ou FINAL_CHANCE uniquement par annulation immédiate de l'action finale, si cette action est encore annulable
```

Les règles et la liste initiale des joueurs ne sont modifiables que dans `SETUP`.

---

# 27. Persistance locale et reprise

## 27.1 Contraintes

La V1 doit fonctionner sans compte et sans connexion Internet.

Elle ne doit pas demander de permission réseau pour son fonctionnement principal.

Les données sont stockées localement sur l'appareil.

## 27.2 Technologie recommandée

Utiliser SQLite via **Drift** ou une solution locale équivalente documentée.

Drift est recommandé pour :

- les transactions ;
- les migrations ;
- les requêtes d'historique ;
- la cohérence entre parties, joueurs, gains et actions.

## 27.3 Transaction atomique

Pour chaque action :

1. calculer le nouvel état dans le moteur pur ;
2. ouvrir une transaction de base de données ;
3. enregistrer l'action ;
4. enregistrer ses effets ;
5. mettre à jour les gains ;
6. mettre à jour le snapshot courant ;
7. valider la transaction ;
8. seulement ensuite publier le nouvel état à l'interface.

Si la persistance échoue :

- ne pas faire croire à l'utilisateur que l'action est enregistrée ;
- conserver l'ancien état affiché ;
- montrer un message réessayable.

## 27.4 Snapshot et journal

Conserver :

- un snapshot courant pour un chargement rapide ;
- le journal d'actions pour l'historique et l'annulation.

Le snapshot doit pouvoir être reconstruit à partir des actions non annulées pendant les tests.

## 27.5 Sauvegardes obligatoires

Sauvegarder après :

- ajout, renommage ou suppression d'un joueur en préparation ;
- modification des règles ;
- démarrage ;
- chaque score ;
- chaque passage ;
- chaque dépassement ;
- chaque rencontre dérivée ;
- chaque départ de joueur ;
- chaque annulation ;
- fin de partie.

## 27.6 Reprise après fermeture ou plantage

À la réouverture :

- retrouver la partie active ;
- restaurer le statut ;
- restaurer le joueur actif ;
- restaurer les manches ;
- restaurer les dernières chances ;
- restaurer les scores, gains et vies ;
- ne jamais réappliquer deux fois la dernière action.

Une saisie provisoire non validée n'est pas une action et peut être abandonnée.

## 27.7 Versionnement des données

Ajouter `schemaVersion` dès la première version.

Toute migration future doit :

- conserver les historiques existants ;
- être testée ;
- éviter de supprimer silencieusement une partie.

---

# 28. Architecture technique recommandée

## 28.1 Stack

- **Flutter** et Dart ;
- cible Android uniquement pour la V1 ;
- Material 3 personnalisable ;
- Riverpod pour l'état applicatif ;
- Drift/SQLite pour la persistance ;
- Freezed et `json_serializable` possibles pour les modèles immuables ;
- package UUID pour les identifiants ;
- tests Flutter standards et `integration_test`.

Ne pas verrouiller des versions obsolètes dans ce document. Le projet doit épingler la version stable réellement utilisée dans :

- `pubspec.yaml` ;
- `.metadata` ;
- `README.md` ;
- éventuellement un gestionnaire de versions Flutter.

## 28.2 Séparation des couches

```text
presentation
- écrans
- modales
- widgets
- animations
- formatage visuel

application
- contrôleurs
- providers
- orchestration des commandes
- navigation
- messages utilisateur

domain
- entités
- règles
- GameEngine
- commandes
- transitions
- erreurs métier

data
- base locale
- repositories
- sérialisation
- migrations
```

La couche `domain` ne doit importer aucun package Flutter.

## 28.3 Arborescence proposée

```text
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   ├── routes.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── color_tokens.dart
│       └── dimensions.dart
│
├── core/
│   ├── result/
│   ├── errors/
│   ├── formatting/
│   └── utilities/
│
├── domain/
│   ├── models/
│   │   ├── animal_avatar.dart
│   │   ├── game.dart
│   │   ├── game_action.dart
│   │   ├── game_effect.dart
│   │   ├── game_rules.dart
│   │   ├── game_state.dart
│   │   ├── gain.dart
│   │   └── player.dart
│   ├── commands/
│   ├── enums/
│   ├── errors/
│   └── services/
│       ├── game_engine.dart
│       ├── turn_resolver.dart
│       ├── encounter_resolver.dart
│       └── final_chance_resolver.dart
│
├── application/
│   ├── controllers/
│   ├── providers/
│   └── state/
│
├── data/
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   └── migrations/
│   ├── repositories/
│   └── catalogs/
│       ├── animal_catalog.dart
│       └── color_catalog.dart
│
├── features/
│   ├── home/
│   ├── game_setup/
│   ├── game_rules/
│   ├── game_board/
│   ├── score_entry/
│   ├── history/
│   └── game_result/
│
└── shared/
    ├── widgets/
    ├── animations/
    └── accessibility/

test/
├── domain/
├── application/
├── data/
└── widgets/

integration_test/
└── complete_game_flow_test.dart

docs/
├── SPECIFICATION.md
├── DECISIONS.md
├── RULES_EXAMPLES.md
└── RELEASE_CHECKLIST.md
```

## 28.4 Gestion d'état

Les widgets observent un état immuable.

Flux recommandé :

```text
Interaction utilisateur
-> Controller
-> GameCommand
-> GameEngine
-> GameTransition
-> Repository transactionnel
-> nouvel état publié
-> interface reconstruite
```

Aucun widget ne doit :

- soustraire directement un score ;
- gérer lui-même la pile de gains ;
- décider d'une rencontre ;
- avancer le tour ;
- restaurer les vies sans passer par le moteur.

---

# 29. Direction visuelle et interactions

## 29.1 Thème

Direction souhaitée :

- fond général sombre, bleu nuit ou anthracite ;
- tuiles fortement colorées ;
- coins arrondis ;
- score très grand ;
- textes courts ;
- emojis visibles ;
- ombres et halos modérés ;
- identité chaleureuse et ludique.

## 29.2 Priorité visuelle d'une tuile

Ordre d'importance :

1. score total ;
2. nom et emoji ;
3. vies ;
4. dernier gain.

## 29.3 Cœurs

Utiliser des icônes vectorielles :

- cœur rempli pour une vie disponible ;
- cœur vide ou contour pour une vie perdue ;
- petite animation de vidage ;
- animation de remplissage lors d'une réussite ou d'une remise à trois.

Les cœurs ne doivent pas être tactiles dans la V1.

Ajouter une sémantique d'accessibilité :

```text
« Bertrand, 2 vies sur 3 »
```

## 29.4 Animations

### Gain

- transition du score ancien vers le nouveau ;
- apparition temporaire de `+500` ;
- remplissage des cœurs si nécessaire.

### Échec

- vidage du cœur ;
- retour haptique léger facultatif.

### Troisième échec

- vidage du dernier cœur ;
- apparition de `-800` ;
- transition du score ;
- remplissage des trois cœurs.

### Rencontre

- courte indication sur la tuile du joueur qui marque ;
- surbrillance de la ou des victimes ;
- affichage de la perte correspondante ;
- aucune animation en cascade.

Toutes les animations :

- doivent être courtes ;
- ne doivent pas bloquer l'action suivante ;
- doivent respecter un éventuel réglage système de réduction des animations ;
- ne doivent pas provoquer de clignotement rapide.

## 29.5 Accessibilité

MUST :

- ne jamais identifier un joueur uniquement par sa couleur ;
- conserver emoji et nom ;
- fournir des libellés aux lecteurs d'écran ;
- utiliser de grandes cibles tactiles ;
- garder les actions critiques distinctes ;
- permettre le défilement avec de grandes polices ;
- éviter les textes trop petits à douze joueurs ;
- afficher des confirmations compréhensibles.

## 29.6 Orientation

L'application peut fonctionner en portrait et paysage, mais :

- 2 à 4 joueurs restent sur une colonne ;
- 5 à 12 restent sur deux colonnes ;
- aucune orientation ne doit produire trois colonnes.

Un verrouillage portrait MAY être choisi pour la première version si cela améliore nettement la fiabilité, mais cette décision doit être inscrite dans `docs/DECISIONS.md`.

---

# 30. Cas particuliers obligatoires

| Situation | Comportement attendu |
|---|---|
| Moins de 2 joueurs | Démarrage impossible |
| 12 joueurs présents | Bouton d'ajout désactivé |
| Suppression avant départ | Animal et couleur remis dans les réserves |
| Noms identiques | Autorisés, avertissement facultatif |
| Nom trop long | Limité ou tronqué visuellement |
| Appui sur `-100` à zéro | Reste à zéro |
| Validation à zéro | Impossible |
| Score sous la sortie | Validation impossible, pas d'échec automatique |
| Passage avant sortie | Aucune vie perdue |
| Joueur revenu à zéro mais déjà sorti | Peut marquer un petit score |
| Joueur sans gain actif | Passage sans perte de vie |
| Score après deux échecs | Trois vies restaurées |
| Troisième échec | Un seul gain actif annulé |
| Plusieurs séries de trois échecs | Gains plus anciens annulés successivement |
| Rencontre | Dernier gain actif de la victime annulé |
| Rencontre multiple | Un gain annulé pour chaque victime |
| Retour sur un score occupé | Pas de cascade en V0.2 |
| Victime sans autre gain après rencontre | Score 0 et vies 3 |
| Victime avec une vie et plusieurs gains | Vie conservée ; prochain échec peut annuler le gain suivant |
| Dépassement de 10 000 | Confirmation puis échec |
| Dépassement sans gain actif | Aucun cœur perdu |
| Dépassement comme troisième échec | Dernier gain annulé |
| Atteinte exacte de 10 000 | Début de dernière chance |
| Deuxième joueur atteint 10 000 | Rencontre du candidat précédent |
| Candidat délogé | Ne reçoit pas de nouveau dernier tour |
| Joueur quitte pendant une manche | Retiré des joueurs en attente |
| Joueur quitte pendant dernière chance | Retiré des dernières chances en attente |
| Dernier joueur actif seul | Proposer fin anticipée/abandon |
| Double validation rapide | Une seule action créée |
| Fermeture pendant modale | Saisie provisoire non appliquée |
| Fermeture juste après validation | Action retrouvée une seule fois |
| Annulation d'une rencontre multiple | Tous les états restaurés |
| Annulation du déclenchement de fin | Retour au statut précédent |
| Emoji non rendu | Utiliser le fallback prévu ou documenter la limite |
| Changement de taille de police | Défilement sans perte d'action |

---

# 31. Tests unitaires du moteur

Les tests du domaine sont prioritaires sur l'interface.

## 31.1 Préparation

1. Refuser le démarrage avec un joueur.
2. Autoriser le démarrage avec deux joueurs.
3. Autoriser douze joueurs.
4. Refuser le treizième joueur.
5. Garantir des emojis exacts uniques.
6. Garantir des couleurs uniques.
7. Rendre l'animal et la couleur disponibles après suppression avant démarrage.
8. Verrouiller les changements après démarrage.

## 31.2 Sortie

9. Refuser 200 avec une sortie à 300.
10. Accepter 300.
11. Accepter 1 000 comme première sortie.
12. Ne retirer aucune vie lors d'un passage avant sortie.
13. Conserver `hasEnteredGame` après retour à zéro.
14. Accepter 100 après une sortie antérieure et un retour à zéro.

## 31.3 Scores et vies

15. Ajouter un score simple.
16. Restaurer trois vies après un score.
17. Retirer une vie au premier passage avec gain actif.
18. Retirer une deuxième vie.
19. Annuler le dernier gain au troisième échec.
20. Restaurer trois vies après le troisième échec.
21. Ne pas retirer de vie sans gain actif.
22. Empêcher un score provisoire métier négatif.

## 31.4 Pile de gains

23. Ajouter `[1000, 800, 500]` et obtenir 2 300.
24. Annuler 500 et obtenir 1 800.
25. Annuler ensuite 800 et obtenir 1 000.
26. Annuler ensuite 1 000 et obtenir 0.
27. Ne jamais annuler deux gains lors d'un seul troisième échec.
28. Afficher le bon dernier gain après chaque annulation.

## 31.5 Rencontres

29. Faire reculer une victime simple.
30. Faire reculer plusieurs victimes.
31. Conserver le score du joueur déclencheur.
32. Ne pas déclencher de cascade.
33. Conserver les vies de la victime si des gains restent.
34. Remettre les vies à trois si la pile de la victime devient vide.
35. Ignorer un joueur ayant quitté.
36. Conserver les liens entre gain annulé et action de rencontre.

## 31.6 Objectif et dépassement

37. Accepter exactement 10 000.
38. Refuser 10 100.
39. Transformer un dépassement confirmé en échec.
40. Faire tomber une vie lors du dépassement.
41. Annuler un gain si le dépassement constitue le troisième échec.
42. Ne créer aucun gain pour le montant tenté.

## 31.7 Dernière chance

43. Créer la bonne liste de joueurs en mode guidé.
44. Respecter l'ordre circulaire.
45. Exclure le candidat initial.
46. Permettre n'importe quel ordre en mode libre.
47. Consommer une seule chance par joueur.
48. Gérer une rencontre à 10 000.
49. Changer le candidat à la victoire.
50. Ne pas redonner de tour au candidat délogé.
51. Terminer quand tous les joueurs autorisés ont joué.

## 31.8 Tours guidés

52. Avancer au joueur suivant.
53. Incrémenter la manche après le dernier joueur.
54. Permettre de choisir un joueur en attente hors ordre.
55. Ne pas compter les joueurs sautés comme des échecs.
56. Empêcher un joueur de jouer deux fois dans la même manche.
57. Gérer le départ du joueur actif.

## 31.9 Annulation

58. Annuler un score simple.
59. Annuler un passage.
60. Annuler un troisième échec.
61. Annuler une rencontre simple.
62. Annuler une rencontre multiple.
63. Annuler un dépassement.
64. Annuler le début de dernière chance.
65. Annuler la fin de partie.
66. Restaurer exactement les listes de joueurs en attente.
67. Refuser l'annulation sans action disponible.

---

# 32. Tests de widgets

MUST couvrir au minimum :

- une colonne pour 2, 3 et 4 joueurs ;
- deux colonnes pour 5 et 12 joueurs ;
- absence de troisième colonne sur écran large ;
- défilement jusqu'au douzième joueur ;
- rendu des noms longs ;
- bordure du joueur actif ;
- affichage des trois états de cœur ;
- boutons `±50` absents par défaut ;
- boutons `±50` présents lorsque l'option est activée ;
- score provisoire et corrections ;
- confirmation d'abandon de saisie ;
- confirmation du troisième échec ;
- confirmation du dépassement ;
- modale de sélection d'un autre joueur ;
- écran de dernière chance ;
- écran de résultat ;
- libellés d'accessibilité essentiels.

---

# 33. Tests d'intégration

Créer au moins les parcours suivants :

## 33.1 Partie complète simple

```text
Créer 2 joueurs
Renommer le premier
Démarrer
Faire sortir les joueurs
Enregistrer scores et passages
Atteindre exactement 10 000
Jouer la dernière chance
Afficher le gagnant
Fermer et rouvrir l'application
Consulter l'historique
```

## 33.2 Pile, rencontre et troisième échec

```text
Renard marque +1000, +800, +500
Pingouin atteint le même total
Vérifier que Renard revient à 1800
Faire perdre son dernier cœur à Renard
Vérifier qu'il revient à 1000
Annuler l'action
Vérifier le retour exact à 1800 et à l'état de vies précédent
```

## 33.3 Douze joueurs

```text
Ajouter 12 joueurs
Vérifier animaux et couleurs uniques
Démarrer
Faire défiler le plateau
Enregistrer une action pour chaque joueur
Vérifier la manche suivante
```

## 33.4 Reprise après interruption

```text
Valider une action complexe avec rencontre
Forcer une fermeture
Relancer
Vérifier scores, vies, gains, joueur actif et historique
```

---

# 34. Critères d'acceptation de la V1

La V1 n'est considérée terminée que si :

- `flutter analyze` ne signale aucune erreur ;
- tous les tests unitaires passent ;
- les tests de widgets critiques passent ;
- les parcours d'intégration principaux passent ;
- une APK release est produite ;
- l'APK s'installe sur au moins un appareil Android réel ;
- la partie fonctionne sans Internet ;
- une partie de douze joueurs reste utilisable avec défilement ;
- aucune vue ne passe à trois colonnes ;
- la pile de gains fonctionne sur plusieurs annulations successives ;
- la rencontre multiple fonctionne sans cascade ;
- le dépassement compte comme un échec ;
- la dernière chance fonctionne dans les deux modes ;
- l'annulation restaure une action complexe intégralement ;
- la partie survit à une fermeture complète de l'application ;
- aucun secret de signature n'est commité dans le dépôt ;
- le README explique comment lancer, tester et générer l'APK.

---

# 35. Plan d'implémentation recommandé

## Phase 0 — Fondation

Livrables :

- projet Flutter Android ;
- configuration de lint ;
- thème minimal ;
- structure des dossiers ;
- CI locale ou script de vérification ;
- copie de ce document dans `docs/SPECIFICATION.md`.

## Phase 1 — Domaine pur

Livrables :

- modèles ;
- règles ;
- catalogue de couleurs ;
- catalogue d'animaux ;
- `GameEngine` ;
- résolution des tours ;
- pile de gains ;
- rencontres ;
- dernière chance ;
- annulation ;
- tests unitaires complets.

Aucun écran final ne doit être développé avant que cette phase soit stable.

## Phase 2 — Persistance

Livrables :

- schéma Drift/SQLite ;
- repositories ;
- transactions ;
- migrations initiales ;
- chargement de partie ;
- tests de persistance et de reconstruction.

## Phase 3 — Préparation de partie

Livrables :

- accueil ;
- nouvelle partie ;
- ajout de 2 à 12 joueurs ;
- tirage animal/couleur ;
- renommage ;
- suppression ;
- paramètres ;
- démarrage.

## Phase 4 — Plateau et saisie

Livrables :

- grille une/deux colonnes ;
- scrolling ;
- tuiles ;
- bordure active ;
- phrases ;
- modale de score ;
- bouton Passer ;
- animations essentielles.

## Phase 5 — Règles avancées

Livrables :

- sortie ;
- vies ;
- troisième échec ;
- dépassement ;
- rencontres ;
- dernière chance ;
- départ d'un joueur.

## Phase 6 — Historique et annulation

Livrables :

- vue d'historique ;
- détails des actions ;
- annulation atomique ;
- reprise après redémarrage.

## Phase 7 — Finition et livraison

Livrables :

- écran de résultat ;
- archives ;
- accessibilité ;
- tests d'intégration ;
- icône d'application ;
- signature release ;
- APK ;
- checklist de recette.

Après chaque phase, Claude Code doit fournir :

- les fichiers créés/modifiés ;
- les tests ajoutés ;
- les commandes de validation exécutées ;
- les limites restantes ;
- les décisions consignées.

---

# 36. Construction et livraison Android

## 36.1 Développement

Commandes attendues, à ajuster au projet :

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 36.2 APK release

Commande de base :

```bash
flutter build apk --release
```

Pour produire des APK séparés par architecture si souhaité :

```bash
flutter build apk --split-per-abi
```

Les artefacts sont normalement générés sous :

```text
build/app/outputs/flutter-apk/
```

## 36.3 Signature

La configuration de signature doit :

- utiliser un keystore release dédié ;
- conserver les mots de passe hors du dépôt ;
- placer les fichiers locaux sensibles dans `.gitignore` ;
- documenter la procédure dans un fichier non secret ;
- conserver le keystore en lieu sûr, car il sera nécessaire pour les mises à jour.

## 36.4 Livrables

- APK release installable ;
- checksum facultatif ;
- numéro de version ;
- notes de version ;
- instructions d'installation ;
- liste des appareils testés.

La publication Play Store et le format AAB sont hors périmètre immédiat, mais le projet ne doit pas les rendre impossibles.

---

# 37. Sécurité, confidentialité et qualité

- Aucun compte obligatoire.
- Aucune donnée personnelle nécessaire.
- Aucun envoi réseau dans la V1.
- Aucune publicité.
- Aucun tracker.
- Aucune permission Android injustifiée.
- Aucun secret dans le dépôt.
- Les noms des joueurs restent sur l'appareil.
- La suppression d'une partie doit demander confirmation.
- Une option de suppression de toutes les données locales SHOULD être prévue dans les paramètres généraux.

---

# 38. Évolutions possibles après la V1

Ces idées ne doivent pas être implémentées avant stabilisation du MVP :

- calculateur de combinaisons de dés ;
- sélection visuelle des dés ;
- profils de règles maison ;
- réaction en chaîne des rencontres configurable ;
- choix ou exclusion de certains animaux ;
- illustrations animales personnalisées ;
- sons et packs de voix ;
- statistiques détaillées ;
- édition d'une ancienne action avec recalcul complet ;
- export JSON ou PDF d'une partie ;
- partage local ;
- mode tablette optimisé ;
- Android TV ou affichage secondaire ;
- version iOS ;
- synchronisation entre appareils.

---

# 39. Décisions fonctionnelles figées pour la V0.2

| Sujet | Décision |
|---|---|
| Joueurs | 2 à 12 |
| Mode solo | absent |
| Animaux | grand catalogue Unicode, tirage aléatoire sans remise |
| Couleurs | 12 couleurs, tirage sans remise indépendant |
| Changement animal/couleur | interdit |
| Renommage | autorisé avant lancement |
| Ordre | ordre d'ajout |
| Disposition | 1 colonne jusqu'à 4, 2 colonnes dès 5 |
| Troisième colonne | interdite |
| Défilement | autorisé et attendu |
| Informations de tuile | emoji, nom, vies, score, dernier gain |
| Cœurs tactiles | non |
| Échec | bouton Passer ou dépassement |
| Sortie par défaut | 300 |
| Passage sans gain | aucune vie perdue |
| Score positif | restaure 3 vies |
| Pénalité | annule le dernier gain actif |
| Pénalités répétées | remontent la pile des gains |
| Rencontre | annule le dernier gain actif de chaque victime |
| Cascade de rencontre | désactivée en V0.2 |
| Objectif | exactement 10 000 |
| Dépassement | échec |
| Fin | un dernier tour à tous les autres joueurs |
| Ajout après lancement | interdit |
| Départ d'un joueur | historique conservé |
| iOS | hors périmètre |

---

# Annexe A — Catalogue animal V0.2

## A.1 Règles du catalogue

- Toutes les entrées ci-dessous possèdent un identifiant technique unique.
- Les noms sont les noms français initiaux et peuvent être raffinés sans changer l'identifiant.
- Les variantes d'une même espèce doivent partager un `familyId`.
- Les emojis multi-codepoints doivent être stockés comme chaînes Unicode complètes.
- Le tirage utilise uniquement les entrées marquées comme éligibles.
- La liste inclut les animaux réels, animaux fantastiques et visages animaux.
- Les six symboles non individuels exclus par défaut sont listés séparément à la fin.

## A.2 Visages de chats

| Emoji | Nom par défaut | `familyId` |
|---|---|---|
| 😺 | Chat joyeux | `cat` |
| 😸 | Chat ravi | `cat` |
| 😹 | Chat hilare | `cat` |
| 😻 | Chat amoureux | `cat` |
| 😼 | Chat malicieux | `cat` |
| 😽 | Chat câlin | `cat` |
| 🙀 | Chat effrayé | `cat` |
| 😿 | Chat triste | `cat` |
| 😾 | Chat boudeur | `cat` |

## A.3 Singes symboliques

| Emoji | Nom par défaut | `familyId` |
|---|---|---|
| 🙈 | Singe caché | `monkey` |
| 🙉 | Singe aux oreilles cachées | `monkey` |
| 🙊 | Singe à la bouche cachée | `monkey` |

## A.4 Mammifères

| Emoji | Nom par défaut | `familyId` |
|---|---|---|
| 🐵 | Petit singe | `monkey` |
| 🐒 | Singe | `monkey` |
| 🦍 | Gorille | `gorilla` |
| 🦧 | Orang-outan | `orangutan` |
| 🐶 | Chiot | `dog` |
| 🐕 | Chien | `dog` |
| 🦮 | Chien-guide | `dog` |
| 🐕‍🦺 | Chien d'assistance | `dog` |
| 🐩 | Caniche | `dog` |
| 🐺 | Loup | `wolf` |
| 🦊 | Renard | `fox` |
| 🦝 | Raton laveur | `raccoon` |
| 🐱 | Chaton | `cat` |
| 🐈 | Chat | `cat` |
| 🐈‍⬛ | Chat noir | `cat` |
| 🦁 | Lion | `lion` |
| 🐯 | Tigre | `tiger` |
| 🐅 | Grand tigre | `tiger` |
| 🐆 | Léopard | `leopard` |
| 🐴 | Poney | `horse` |
| 🫎 | Élan | `moose` |
| 🫏 | Âne | `donkey` |
| 🐎 | Cheval | `horse` |
| 🦄 | Licorne | `unicorn` |
| 🦓 | Zèbre | `zebra` |
| 🦌 | Cerf | `deer` |
| 🦬 | Bison | `bison` |
| 🐮 | Vache | `cow` |
| 🐂 | Bœuf | `ox` |
| 🐃 | Buffle | `buffalo` |
| 🐄 | Grande vache | `cow` |
| 🐷 | Cochon | `pig` |
| 🐖 | Grand cochon | `pig` |
| 🐗 | Sanglier | `boar` |
| 🐽 | Groin | `pig` |
| 🐏 | Bélier | `ram` |
| 🐑 | Brebis | `sheep` |
| 🐐 | Chèvre | `goat` |
| 🐪 | Dromadaire | `camel` |
| 🐫 | Chameau | `camel` |
| 🦙 | Lama | `llama` |
| 🦒 | Girafe | `giraffe` |
| 🐘 | Éléphant | `elephant` |
| 🦣 | Mammouth | `mammoth` |
| 🦏 | Rhinocéros | `rhinoceros` |
| 🦛 | Hippopotame | `hippopotamus` |
| 🐭 | Petite souris | `mouse` |
| 🐁 | Souris | `mouse` |
| 🐀 | Rat | `rat` |
| 🐹 | Hamster | `hamster` |
| 🐰 | Petit lapin | `rabbit` |
| 🐇 | Lapin | `rabbit` |
| 🐿️ | Écureuil | `chipmunk` |
| 🦫 | Castor | `beaver` |
| 🦔 | Hérisson | `hedgehog` |
| 🦇 | Chauve-souris | `bat` |
| 🐻 | Ours | `bear` |
| 🐻‍❄️ | Ours polaire | `polar_bear` |
| 🐨 | Koala | `koala` |
| 🐼 | Panda | `panda` |
| 🦥 | Paresseux | `sloth` |
| 🦦 | Loutre | `otter` |
| 🦨 | Moufette | `skunk` |
| 🦘 | Kangourou | `kangaroo` |
| 🦡 | Blaireau | `badger` |

## A.5 Oiseaux

| Emoji | Nom par défaut | `familyId` |
|---|---|---|
| 🦃 | Dinde | `turkey` |
| 🐔 | Poule | `chicken` |
| 🐓 | Coq | `rooster` |
| 🐣 | Poussin qui éclot | `chick` |
| 🐤 | Poussin | `chick` |
| 🐥 | Poussin de face | `chick` |
| 🐦 | Oiseau | `bird` |
| 🐧 | Pingouin | `penguin` |
| 🕊️ | Colombe | `dove` |
| 🦅 | Aigle | `eagle` |
| 🦆 | Canard | `duck` |
| 🦢 | Cygne | `swan` |
| 🦉 | Hibou | `owl` |
| 🦤 | Dodo | `dodo` |
| 🦩 | Flamant rose | `flamingo` |
| 🦚 | Paon | `peacock` |
| 🦜 | Perroquet | `parrot` |
| 🐦‍⬛ | Corbeau | `bird` |
| 🪿 | Oie | `goose` |
| 🐦‍🔥 | Phénix | `phoenix` |

## A.6 Amphibiens et reptiles

| Emoji | Nom par défaut | `familyId` |
|---|---|---|
| 🐸 | Grenouille | `frog` |
| 🐊 | Crocodile | `crocodile` |
| 🐢 | Tortue | `turtle` |
| 🦎 | Lézard | `lizard` |
| 🐍 | Serpent | `snake` |
| 🐲 | Dragonnet | `dragon` |
| 🐉 | Dragon | `dragon` |
| 🦕 | Sauropode | `sauropod` |
| 🦖 | T-Rex | `trex` |

## A.7 Animaux marins

| Emoji | Nom par défaut | `familyId` |
|---|---|---|
| 🐳 | Baleine souffleuse | `whale` |
| 🐋 | Grande baleine | `whale` |
| 🐬 | Dauphin | `dolphin` |
| 🫍 | Orque | `orca` |
| 🦭 | Phoque | `seal` |
| 🐟 | Poisson | `fish` |
| 🐠 | Poisson tropical | `tropical_fish` |
| 🐡 | Poisson-globe | `blowfish` |
| 🦈 | Requin | `shark` |
| 🐙 | Pieuvre | `octopus` |
| 🪸 | Corail | `coral` |
| 🪼 | Méduse | `jellyfish` |
| 🦀 | Crabe | `crab` |
| 🦞 | Homard | `lobster` |
| 🦐 | Crevette | `shrimp` |
| 🦑 | Calmar | `squid` |
| 🦪 | Huître | `oyster` |

## A.8 Insectes et petits animaux

| Emoji | Nom par défaut | `familyId` |
|---|---|---|
| 🐌 | Escargot | `snail` |
| 🦋 | Papillon | `butterfly` |
| 🐛 | Chenille | `caterpillar` |
| 🐜 | Fourmi | `ant` |
| 🐝 | Abeille | `bee` |
| 🪲 | Scarabée | `beetle` |
| 🐞 | Coccinelle | `ladybug` |
| 🦗 | Criquet | `cricket` |
| 🪳 | Cafard | `cockroach` |
| 🕷️ | Araignée | `spider` |
| 🦂 | Scorpion | `scorpion` |
| 🦟 | Moustique | `mosquito` |
| 🪰 | Mouche | `fly` |
| 🪱 | Ver | `worm` |

## A.9 Entrées de nature conservées mais exclues du tirage par défaut

| Emoji | Nom | Raison |
|---|---|---|
| 🐾 | Empreintes | ne représente pas un animal individuel |
| 🪶 | Plume | partie d'un animal |
| 🪽 | Aile | partie d'un animal |
| 🐚 | Coquillage | objet ou reste plutôt qu'identité animale claire |
| 🕸️ | Toile d'araignée | construction d'un animal |
| 🦠 | Microbe | catégorie trop ambiguë pour un totem animal |

Le catalogue aléatoire par défaut contient donc **137 identités animales éligibles** dans cette version du document.

---

# Annexe B — Banque de phrases du joueur actif

La liste peut être enrichie sans modifier les règles du jeu.

Utiliser `{name}` comme variable.

```text
{name}, à toi de jouer !
{name}, lance tes dés !
Fais-les rouler, {name} !
Que la chance soit avec toi, {name} !
{name}, fais trembler la table !
Make it roll, {name}!
À toi de briller, {name} !
{name}, montre-nous ce que tu sais faire !
Les dés t'attendent, {name} !
{name}, c'est ton moment !
En piste, {name} !
{name}, que le meilleur lancer commence !
À toi de jouer le grand coup, {name} !
{name}, fais parler les dés !
La table est à toi, {name} !
{name}, tente ta chance !
C'est parti, {name} !
{name}, vise juste !
À ton tour, {name} !
{name}, fais monter le score !
```

Contraintes :

- ne pas répéter immédiatement la même phrase ;
- éviter les phrases trop longues sur petits écrans ;
- échapper correctement les noms personnalisés ;
- ne jamais injecter le nom comme code ou markup.

---

# Annexe C — Scénarios métier de référence

## C.1 Sortie puis retour à zéro

```text
Sortie minimale : 300
Bertrand marque +300
hasEnteredGame = true
Pile : [300]
Score : 300

Après trois échecs :
Pile : []
Score : 0
Vies : 3
hasEnteredGame = true

Bertrand marque +100
Le score est accepté
```

## C.2 Rencontre puis perte du gain précédent

```text
Renard marque +1000
Renard marque +800
Renard marque +500

Pile de Renard : [1000, 800, 500]
Score de Renard : 2300

Pingouin arrive à 2300
Rencontre

Pile de Renard : [1000, 800]
Score de Renard : 1800
Le gain de 500 est annulé par rencontre

Renard avait déjà une seule vie
Il passe à son prochain tour

Son dernier cœur tombe
Le gain de 800 est annulé
Pile : [1000]
Score : 1000
Vies : 3
```

Ce scénario est un test d'acceptation prioritaire.

## C.3 Absence de cascade

```text
Panda est à 1800
Renard est à 2300 avec un dernier gain de 500
Pingouin arrive à 2300

Renard revient à 1800
Panda reste à 1800
```

Deux joueurs peuvent donc se retrouver au même score à la suite d'une conséquence indirecte. Cela ne déclenche rien en V0.2.

## C.4 Dépassement comme troisième échec

```text
Bertrand est à 9800
Pile : [3000, 4000, 2800]
Vies : 1

Il tente +300
Total théorique : 10100
Il confirme le dépassement

Aucun gain de 300 n'est créé
Le dernier cœur tombe
Le gain de 2800 est annulé
Nouveau score : 7000
Pile : [3000, 4000]
Vies : 3
```

## C.5 Rencontre à 10 000

```text
Pingouin atteint 10000
La dernière chance commence

Renard atteint ensuite 10000
Renard reste à 10000
Pingouin perd son dernier gain actif
Renard devient candidat à la victoire

Les joueurs encore en attente jouent leur dernier tour
```

## C.6 Sélection hors ordre en mode guidé

```text
Manche 4
Ordre : A, B, C, D
A et B ont joué
C est actif

L'utilisateur choisit D
D joue
C reste en attente
C joue ensuite
La manche se termine
```

Aucun échec n'est créé pour C lors du changement d'ordre.

## C.7 Annulation atomique d'une rencontre multiple

```text
Bertrand marque +500 et atteint 2300
Renard et Panda sont à 2300
Le dernier gain de Renard est annulé
Le dernier gain de Panda est annulé

L'utilisateur appuie sur Annuler

Le gain de 500 de Bertrand disparaît
Renard récupère son gain
Panda récupère son gain
Les scores, vies, tours et listes sont exactement restaurés
```

---

# Annexe D — Première mission à donner à Claude Code

Après avoir placé ce fichier dans `docs/SPECIFICATION.md`, utiliser une instruction similaire :

```text
Lis intégralement docs/SPECIFICATION.md avant de modifier le dépôt.

Ta première mission n'est pas de construire les écrans finaux.
Commence par produire :

1. un résumé sans ambiguïté des règles comprises ;
2. l'arborescence proposée ;
3. les entités et enums du domaine ;
4. l'API publique du GameEngine ;
5. la représentation de la pile de gains ;
6. l'algorithme de rencontre sans cascade ;
7. la machine à états de dernière chance ;
8. la stratégie d'annulation atomique ;
9. la stratégie de persistance locale ;
10. la liste des tests unitaires à écrire en premier.

Ensuite, implémente le domaine en Dart pur avec les tests.
N'importe aucune classe Flutter dans domain/.
Ne place aucune règle métier dans les widgets.
Ne change aucune règle sans créer une entrée dans docs/DECISIONS.md.
Exécute le formatage, l'analyse statique et les tests après chaque étape cohérente.
```

---

# Annexe E — Checklist de recette manuelle

## Préparation

- [ ] Ajouter 2 joueurs.
- [ ] Ajouter 12 joueurs.
- [ ] Vérifier que le treizième est impossible.
- [ ] Vérifier que les animaux sont différents.
- [ ] Vérifier que les couleurs sont différentes.
- [ ] Renommer un joueur.
- [ ] Supprimer un joueur avant départ.
- [ ] Vérifier que l'animal et la couleur peuvent être réattribués.

## Affichage

- [ ] 2 à 4 joueurs : une colonne.
- [ ] 5 à 12 joueurs : deux colonnes.
- [ ] Jamais trois colonnes.
- [ ] Faire défiler jusqu'au dernier joueur.
- [ ] Vérifier un nom de 16 caractères.
- [ ] Vérifier la bordure active.
- [ ] Vérifier les grandes polices.

## Partie

- [ ] Tester la sortie à 300.
- [ ] Passer avant sortie sans perdre de vie.
- [ ] Marquer après deux échecs et restaurer les vies.
- [ ] Perdre trois vies et annuler le dernier gain.
- [ ] Annuler plusieurs gains successivement.
- [ ] Déclencher une rencontre simple.
- [ ] Déclencher une rencontre multiple.
- [ ] Vérifier l'absence de cascade.
- [ ] Dépasser 10 000.
- [ ] Atteindre exactement 10 000.
- [ ] Jouer toutes les dernières chances.
- [ ] Déloger un candidat à 10 000.

## Fiabilité

- [ ] Annuler un score.
- [ ] Annuler un troisième échec.
- [ ] Annuler une rencontre multiple.
- [ ] Fermer et rouvrir après une action.
- [ ] Fermer pendant une saisie provisoire.
- [ ] Vérifier l'historique.
- [ ] Faire quitter un joueur.
- [ ] Installer l'APK release sur un appareil réel.
- [ ] Tester sans connexion Internet.

---

# Fin du document

Toute évolution des règles doit incrémenter la version de ce fichier et ajouter une ligne dans `docs/DECISIONS.md`.
