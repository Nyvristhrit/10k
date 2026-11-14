# Backlog

Ce qui reste à faire. Ce qui est livré est dans `CHANGELOG.md`.

## Fonctionnalités

- [ ] Liste des parties terminées (date, joueurs, gagnant), spec §20.8.
- [ ] « Rejouer avec les mêmes noms » depuis cette liste, spec §20.7.
- [ ] Supprimer toutes les données locales depuis les réglages, spec §37
      (les parties terminées ne sont jamais effacées, voir DECISIONS A-010).

## Play Store

- [ ] Compte Play Console au nom de la société (nécessite un numéro D-U-N-S).
- [ ] Signature release avec une clé dédiée, sauvegardée hors du dépôt
      (aujourd'hui l'APK est signé avec la clé debug).
- [ ] Build `.aab` : `flutter build appbundle`.
- [ ] Mentions légales et politique de confidentialité au nom de la société.
- [ ] Questionnaire IARC : déclarer le mode trash. Sécurité des données :
      aucune donnée collectée. URL de confidentialité :
      `https://nyvristhrit.github.io/10k/confidentialite.html`.
- [ ] Fiche : captures d'écran, description, bannière (FR et EN).

## Technique

- [ ] Compléter le catalogue animal (environ 85 identités sur 137).
- [ ] Retirer l'override `path_provider_android` quand `jni` sera corrigé
      (DECISIONS A-007).
- [ ] Réévaluer `kotlin.incremental=false` (DECISIONS A-008).
- [ ] Sortir les résolveurs du moteur si utile (DECISIONS A-004).
- [ ] Plus de tests de widgets et d'intégration : saisie, confirmations,
      dernière chance, reprise après fermeture.
- [ ] Valider avec le groupe les choix par défaut F-001, F-002 et F-004.

## Idées

- Calculateur de combinaisons de dés à partir du plateau virtuel.
- Profils de règles maison.
- Export des parties.
- iOS.
