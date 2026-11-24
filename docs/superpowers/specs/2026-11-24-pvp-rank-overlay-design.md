# App de rang PvP (ligue super et hyper) — design

Date : 2026-11-24. Statut : en attente d'approbation. Aucun code écrit.

## Intention

Pendant qu'il évalue un Pokémon dans Pokémon GO, Pickles veut voir en un geste son rang parmi les 4096 combinaisons d'IV, en ligue super (1500 PC) et en ligue hyper (2500 PC), avec un tableau comme celui d'un calculateur web de rang PvP : ligne verte pour son Pokémon, puis le haut du classement.

Usage : lui, et son frère (iPhone). Pas de publication sur les stores. Le « pourquoi plutôt qu'une app existante » n'a pas été précisé ; on suppose le plaisir de construire et un parcours sur mesure, et non un produit concurrent.

## Objectifs

- Un geste depuis l'écran d'évaluation du jeu pour obtenir le rang, en super et en hyper.
- Résultat correct ou honnêtement incertain : si plusieurs combinaisons d'IV restent possibles, afficher une fourchette de rangs, jamais un faux chiffre précis.
- Fonctionne hors ligne, calculs sur le téléphone.
- Même cœur sur Android et iPhone.

## Hors périmètre (v1)

- Pas de connexion au compte du jeu, pas de saisie automatique dans le jeu.
- Pas de pastille flottante sur iPhone (impossible sur iOS), pas d'enregistrement d'écran en direct.
- Pas de simulation de combats, de capacités, de raids ni de chaînes d'évolution.
- Pas de Pokémon obscurs ou purifiés traités à part, pas de publication sur les stores.

## À éviter absolument

- Tout ce qui expose le compte à un ban : identifiants demandés, automatisation, usurpation de position.
- Afficher un rang comme certain alors que la lecture est ambiguë.
- Une analyse lente qui casse le rythme d'une partie.

## Contraintes

- Android : permission d'affichage par-dessus les autres apps, et capture d'écran avec accord de l'utilisateur à chaque session (Android 14 et plus), via un service au premier plan.
- iPhone : aucune superposition possible. Distribution au frère via TestFlight, ce qui suppose un compte développeur Apple payant.
- Les IV exacts ne sont pas affichés par le jeu : seulement le nom, le PC, les PV, le coût en poussière d'étoiles et les barres d'évaluation.

## Approches envisagées

1. **Cœur commun, deux déclencheurs (retenue).** Lecture, calcul et panneau écrits une fois. Android : pastille flottante. iPhone : capture d'écran, puis l'app analyse la dernière capture (un raccourci iOS peut enchaîner capture et ouverture). Compromis : parcours un peu plus long sur iPhone.
2. Capture d'écran partout, sans pastille. Plus simple, mais perd l'idée de la pastille.
3. Saisie manuelle seule. Fonctionne partout mais lente. Conservée uniquement comme correction quand la lecture se trompe.

Pourquoi la 1 : elle garde l'expérience voulue sur Android sans doubler le travail.

## Design

Parcours Android : la pastille reste au bord de l'écran. Un appui prend une capture, lit le texte et les barres, calcule, puis ouvre un panneau en bas avec deux volets, Super et Hyper.

Parcours iPhone : capture d'écran, ouverture de l'app (via raccourci ou à la main), analyse automatique de la dernière capture, même panneau.

Panneau (maquette validée par Pickles) : volets Super 1500 et Hyper 2500 ; en haut le rang en gros, « sur 4096 » et le pourcentage de perfection ; tableau avec colonnes rang, niveau, PC, A/D/PV, perfection ; première ligne verte pour son Pokémon ; en dessous le haut du classement. Une correction manuelle (espèce, PC, PV) est possible quand la lecture échoue.

Cœur commun :
1. Lecture : espèce, PC, PV, coût en poussière, et barres d'évaluation par analyse d'image.
2. Inférence d'IV : pour chaque niveau compatible avec la poussière et chaque combinaison d'IV (0 à 15 pour chaque stat), garder celles qui redonnent exactement le PC et les PV lus. Les barres réduisent l'ensemble.
3. Rang : pour chaque combinaison, prendre le plus haut niveau dont le PC reste sous le plafond de la ligue, puis trier par produit des stats (attaque × défense × PV, avec le multiplicateur de niveau). Pourcentage = produit / meilleur produit.

## Mes choix (pas encore validés par toi)

- Flutter, comme ses autres apps ; lecture de texte sur le téléphone (ML Kit), sans serveur.
- Données des espèces : source communautaire (gamemaster de PvPoke ou PokeMiners), embarquées dans l'app ; licence à vérifier. Noms français via une table embarquée.
- Plafond de niveau réglable 50 ou 51 (Best Buddy), par défaut 51 pour retrouver le même classement que son calculateur de référence, où le rang 21 correspond à ce Pokémon en 15/15/15 niveau 50.
- Fourchette de rangs en cas d'ambiguïté sur les IV ; distribution au frère par TestFlight, à moins qu'un autre moyen existe.

## Laissé au développeur

- Lecture exacte des barres d'évaluation à valider sur de vraies captures avant tout le reste (premier essai jetable).
- Détails du raccourci iOS et du service de capture Android.
- Mise en page fine du panneau selon les tailles d'écran.

## Questions ouvertes

- Compte développeur Apple pour le frère : existant ou à créer ?
- Plafond de niveau par défaut : tranché par Pickles, 51 (niveau 50 plus bonus meilleur ami).

## Environnement de build

Le bac à sable de cette session ne contient pas Flutter et ne peut pas le télécharger (stockage Google et pub.dev refusés). Les tests et les compilations tournent donc dans GitHub Actions, depuis les branches poussées sur le dépôt.
