<div align="center">

<img src="assets/logo.png" alt="Logo ivHelper : un i dont le point est une pokéball, suivi d'un v" width="120">

# ivHelper

**Le rang PvP de tes Pokémon GO, en ligue Mini, Super, Hyper et Master, en trois appuis, ou directement par-dessus le jeu.**

Flutter · Android · données PvPoke

</div>

---

## À quoi ça sert

Tu as un Pokémon avec ses IV (Attaque / Défense / PV). Tu veux savoir **où il se place** parmi toutes les combinaisons possibles pour la ligue Mini (500 PC), Super (1500 PC), Hyper (2500 PC) et Master (sans limite). ivHelper classe les 4096 combinaisons d'IV de l'espèce et te montre la tienne. Autour de ce calcul : une pastille qui lit l'écran du jeu, une collection, la méta PvPoke, un team builder, la table des types et un générateur de chaînes de recherche.

## Fonctionnalités

### Écran de rang (accueil)

- **Saisie par nom ou numéro** du Pokédex, avec suggestions (accents et casse ignorés) et croix pour effacer.
- **Saisie des IV** façon barre d'évaluation du jeu : toucher ou glisser sur les 15 segments, boutons − et +, ou saisie rapide « 15/14/13 » ou « 151413 ».
- **Dernières recherches** : sans Pokémon saisi, les 8 dernières (une par espèce, avec leurs IV).
- **Quatre volets : Mini · 500, Super · 1500, Hyper · 2500, Master · sans limite**, avec ton rang, ton pourcentage et le haut du classement : top 10, puis « Afficher 10 de plus ».
- **Niveau maximal** 50 par défaut, ou 51 (bonus meilleur ami). **Plancher d'IV** « Min 10/10/10 » (216 combinaisons).
- **Enregistrer** dans la collection, avec la ligue et le rang (recalculé à chaque ouverture avec les données actuelles), et en option : attaques (celles de la méta en gras), obscur ou purifié, taille (XXS à XXL), chanceux, shiny, costume. Doublons permis.

### Superposition (Android)

Une pastille flotte par-dessus Pokémon GO. Sur la fiche d'un Pokémon, touche « Évaluer » pour afficher les barres, puis la pastille :

- ivHelper **capture l'écran et lit** le nom, les PC, les PV et les trois barres d'IV, et reconnaît le stade d'évolution.
- **Tableau stades × ligues** avec rang et pourcentage ; une case choisit le stade et la ligue.
- Pour la case choisie : **rang dans la méta** de la ligue, et **coût pour monter** au niveau visé (poussières, bonbons, bonbons L), recalculé selon chanceux, obscur ou purifié (pré-cochés quand l'écran les montre).
- **Enregistrer** dans la collection, et **Copier PVP#<rang>** pour renommer le Pokémon dans le jeu.
- Tout se corrige à la main (espèce, barres, meilleur ami, décoché par défaut).

Il faut autoriser l'affichage par-dessus les autres applis et la capture d'écran (demandée à chaque lancement). Le bouton ⏻ ou la notification « Arrêter » ferme tout.

### Menu

- **Ma collection** : liste ou mosaïque (au moins 3 par ligne), case à la couleur du premier type, bordure dorée pour un rang 1, cœur pour les favoris, rang méta de la ligue.
  - Panneau **Filtres** (replié par défaut), combinables : favoris, ligue, rang d'IV et rang de ligue (Top 1, 10, 50), types du Pokémon, attaques **Immédiate** ET/OU **Chargée** (par nom ou par type).
  - Tris : rang, Pokédex, nom, type, favoris, rang méta.
  - Fiche : attaques avec barres d'énergie et effets, favori, modifier, voir le rang, voir la fiche méta de sa ligue, supprimer (avec confirmation).
- **Méta** : le top 300 PvPoke en Super, Hyper et Master (formes obscures comprises), mis à jour chaque jour.
  - Filtres : nom, types du Pokémon, types des attaques recommandées, « Possédés en <ligue> ».
  - Les Pokémon que tu as sont bordés de jaune avec ton meilleur rang.
  - Fiche : attaques recommandées, meilleurs matchs et pires adversaires (en jaune ceux que tu possèdes), « Voir le rang de mes IV », « Ajouter à mon équipe ».
- **Team builder** : 3 Pokémon, saisis ou importés de la collection, une immédiate et deux chargées chacun ; faiblesses, résistances, couverture offensive, et bilan d'équipe repliable. L'équipe est conservée. Le bouton **« Ma meilleure équipe »** propose, pour la ligue Super, Hyper ou Master, les trois espèces de ta collection (taguées dans cette ligue) qui contrent le plus d'adversaires du top 50 de la méta PvPoke, avec le pourcentage couvert et les menaces restantes ; « Utiliser cette équipe » les place dans les trois emplacements.
- **Table des types** : touche un type, ou deux pour un double type, pour voir sa défense et son attaque.
- **Chaînes de recherche** : le texte à coller dans la recherche du jeu.
  - Onglet **Rang PvP** : la chaîne qui retrouve les meilleurs IV d'une espèce pour une ligue (top 10, 50 ou 100), et des chaînes prêtes à l'emploi.
  - Onglet **Avancée** : générateur à cases (1 appui ajoute, 2 excluent avec « ! », 3 retirent) pour Pokémon ou famille, types, légendaire, chanceux, shiny, obscur, purifié, costume, taille, types et noms d'attaque, attaque élite, étoiles et IV, PC, date de capture. ET/OU dans chaque rubrique, chaîne optimisée à copier.
- **Superposition** : lance la pastille.
- **Compte** : exporter ou importer tout (collection, équipe, recherches, réglages) dans un fichier JSON.
- **Paramètres** : mode Auto / Jour / Nuit et taille de police de 85 à 140 %.

Les explications sont rangées dans de petits **ⓘ** : un appui affiche la phrase. Partout, une attaque d'événement (Élite) porte un astérisque (ex. Hydroblast*).

## Installer sur Android

L'app n'est pas sur le Play Store.

**Première installation** : onglet **Releases** du dépôt, dernière version, télécharger `ivhelper.apk` et l'ouvrir sur le téléphone (autoriser les sources inconnues).

**Mises à jour** : chaque fusion dans `main` publie une Release `v1.1.N` signée avec la clé fixe d'ivHelper. Au démarrage, l'app interroge GitHub ; si une version plus récente existe, une bannière propose « Mettre à jour ». L'APK se télécharge dans l'app, l'installeur d'Android s'ouvre et l'appli se ferme (pour ne pas laisser une seconde fiche dans les applis récentes) ; la nouvelle version garde ta collection, ton équipe et tes réglages. Le menu affiche la version installée et un bouton « Vérifier les mises à jour ». En cas d'échec, « Via le navigateur » ouvre l'APK directement.

**Clé de signature** : la CI signe avec la clé fournie par les secrets du dépôt `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` et `ANDROID_KEY_PASSWORD` (`tool/configure_signing.py`). Sans ces secrets, l'APK est signé avec une clé de débogage et aucune Release n'est publiée. Les APK de chaque exécution restent disponibles en artefact `ivhelper-apk` dans l'onglet Actions.

**Méta et données du jeu à jour sans réinstaller** : une tâche planifiée (`.github/workflows/meta.yml`, chaque jour à 4 h 17 UTC, ou à la main depuis l'onglet Actions) régénère depuis PvPoke la méta (`assets/meta.json`) ainsi que les espèces et attaques (`assets/species.json`, `assets/moves.json`, datées dans `assets/game_data_version.json`), et ne publie que ce qui a changé. L'app télécharge la méta à l'ouverture de l'onglet Méta ; les espèces et attaques au démarrage et au retour dans l'app, puis les met en service au retour suivant (stats rééquilibrées, nouveaux Pokémon et nouvelles attaques sans attendre une version). Tout est gardé en cache ; sans réseau, l'app retombe sur la copie incluse. La date des données du jeu est affichée dans le menu, sous la version.

**iPhone** : pas de version pour l'instant (phase 4).

## Comment le rang est calculé

Pour chacune des 4096 combinaisons d'IV (0 à 15 pour l'Attaque, la Défense et les PV) :

1. On prend le **plus haut niveau** (par demi-pas, jusqu'au niveau maximal choisi) dont le PC reste sous le plafond de la ligue. En Master, le plafond est fixé à 10 000 PC (comme PvPoke) : tout le monde monte au niveau maximal, et 15/15/15 est rang 1.
2. On calcule le **produit de stats** : `atk × cpm · def × cpm · ⌊pv × cpm⌋`.
3. On trie par produit décroissant, puis PC décroissant, puis IV décroissants. Le rang 1 vaut 100 %, les autres sont en pourcentage du meilleur produit.

Formules : `PC = ⌊atk · √def · √pv · cpm² / 10⌋` (minimum 10), `PV = ⌊pv · cpm⌋` (minimum 10), où `atk`, `def`, `pv` sont les stats de base de l'espèce plus l'IV.

Vérifié sur Flambusard : 15/15/15 est rang 2 246 en Super (niveau 23,5, 1 480 PC) et rang 21 en Hyper au niveau 51 (rang 1 au niveau 50) ; les rangs 1 et 2 Hyper sont 13/15/15 et 13/15/14. En Mini, 15/15/15 est rang 550 (niveau 8, 497 PC) et le rang 1 est 0/14/2 ; en Master, 15/15/15 est rang 1 (niveau 51, 2 522 PC).

Le coût de montée en niveau suit la table du jeu (poussières de 200 à 15 000 par amélioration, bonbons, puis bonbons L à partir du niveau 40) : obscur ×1,2, purifié ×0,9, chanceux ×0,5 sur les poussières, arrondi au supérieur à chaque amélioration ; le niveau 51 est gratuit.

## Développement

### Prérequis

Flutter stable (Dart 3.5 ou plus). Dépendances principales : `material_ui` (Material n'est plus dans le SDK depuis Flutter 3.47), `shared_preferences`, `http`, `open_filex`, `url_launcher`, `file_picker`, `flutter_overlay_window`, et le plugin local `packages/ivhelper_capture`.

```bash
flutter pub get
flutter analyze
flutter test
```

Les dossiers `android/` et `ios/` ne sont pas committés. La CI les génère avec `flutter create --platforms=android --project-name ivhelper --org fr.ivhelper .`, applique le nom « ivHelper », l'activité en `singleTask`, les permissions et les icônes de `tool/android_icons/`, puis compile l'APK. Pour lancer l'app en local, fais la même génération une fois, puis `flutter run`.

### Organisation

| Dossier | Contenu |
|---|---|
| `lib/core/` | Logique pure, sans Flutter, testée : stats, multiplicateurs de PC, rangs, espèces et familles, types, attaques, analyse d'équipe, méta, collection, coût de montée, lecture d'écran, chaînes de recherche |
| `lib/state/` | Contrôleurs : rang, dernières recherches, collection, équipe, méta, mises à jour |
| `lib/settings/` | Réglages, stockage (SharedPreferences), export et import du compte |
| `lib/ui/` | Écrans (rang, collection, méta, team builder, table des types, chaînes de recherche), thème, logo, pastilles de type, bulles ⓘ |
| `lib/overlay/` | Superposition : pastille, panneau, capture et lecture d'écran |
| `packages/ivhelper_capture/` | Plugin Android en Java : capture d'écran (MediaProjection), lecture du texte (ML Kit), copie, fermeture de tâche |
| `assets/species.json` | 1 180 espèces et formes (nom français, stats de base, types, attaques, familles) |
| `assets/moves.json` | 325 attaques (nom français, type, puissance, énergie, effets) |
| `assets/meta.json` | Top 300 PvPoke en Super, Hyper et Master, mis à jour chaque jour |
| `tool/` | `build_species.py`, `build_meta.py`, `build_icon.py`, `configure_signing.py` (signature), `check_mlkit_registrars.py` (contrôle de l'APK), `ci_wait.sh` |
| `docs/` | Sources des données, design et plan d'implémentation |

### Régénérer les données et les icônes

```bash
python3 tool/build_species.py GAMEMASTER NOMS MOVES NOMS_ATTAQUES assets/species.json assets/moves.json   # voir docs/data-sources.md
python3 tool/build_meta.py DOSSIER_SOURCES assets/meta.json        # méta (voir docs/data-sources.md)
python3 tool/build_icon.py                                          # icônes Android + assets/logo.png
```

### Tests

Chaque couche a ses tests : `test/core`, `test/state`, `test/settings`, `test/ui` (widgets) et `test/overlay`, avec des faux services dans `test/support` (aucun réseau en test). La CI (`.github/workflows/ci.yml`) lance analyse et tests, compile et vérifie l'APK, puis publie la Release depuis `main`.

## Feuille de route

- [x] **Phase 1** : saisie manuelle, rang Mini, Super, Hyper et Master, thème, réglages
- [x] **Phase 1 bis** : team builder, table des types, méta à jour, collection, mises à jour dans l'app
- [x] **Phases 2 et 3 (1.1)** : pastille flottante Android, lecture de l'écran, tableau stades × ligues, rang méta et coût de montée
- [x] **Outils** : chaînes de recherche (simple et avancée), export et import du compte
- [ ] **Phase 4** : parcours iPhone (analyse de la dernière capture d'écran)

Le détail est dans [le plan](docs/superpowers/plans/2026-11-24-ivhelper.md) et [le design](docs/superpowers/specs/2026-11-24-pvp-rank-overlay-design.md).

## Données et crédits

Stats de base, multiplicateurs de PC, formes, attaques et classements de la méta : [PvPoke](https://github.com/pvpoke/pvpoke) (licence MIT). Noms français : [PokéAPI](https://pokeapi.co). Syntaxe des recherches : aide Niantic et [Pokémon GO Hub](https://db.pokemongohub.net/fr/tools/search-strings). Détails dans [`docs/data-sources.md`](docs/data-sources.md).

ivHelper est un projet personnel, sans lien avec Niantic, Nintendo ou The Pokémon Company. Pokémon et Pokémon GO sont des marques de leurs propriétaires.
