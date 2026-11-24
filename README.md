<div align="center">

<img src="assets/logo.png" alt="Logo ivHelper : un i dont le point est une pokéball, suivi d'un v" width="120">

# ivHelper

**Le rang PvP de tes Pokémon GO, en ligue Mini, Super, Hyper et Master, en trois appuis.**

Flutter · Android · données PvPoke

</div>

---

## À quoi ça sert

Tu as un Pokémon avec ses IV (Attaque / Défense / PV). Tu veux savoir **où il se place** parmi toutes les combinaisons possibles pour la ligue Mini (500 PC), Super (1500 PC), Hyper (2500 PC) et Master (sans limite). ivHelper classe les 4096 combinaisons d'IV de l'espèce et te montre la tienne.

## Fonctionnalités

- **Saisie par nom ou numéro** du Pokédex, avec suggestions si le nom est incomplet ou mal orthographié (accents et casse ignorés).
- **Quatre volets : Mini · 500, Super · 1500, Hyper · 2500 et Master · sans limite**, chacun avec ton rang, ton pourcentage du meilleur produit de stats, et le haut du classement.
- **Tableau dépliable** : rang, niveau, PC, IV (Atk/Déf/PV) et Parfait (%). Un appui sur une ligne affiche ses stats réelles (Atk, Déf, PV, stat globale) ; l'interrupteur **Détails** déplie tout.
- **Niveau maximal** : 50, ou 51 (niveau 50 plus bonus meilleur ami).
- **Plancher d'IV** : « Min 10/10/10 » restreint le classement aux 216 combinaisons dont chaque IV vaut au moins 10.
- **Enregistrer** : sur l'écran de rang, ouvre un menu pour garder le Pokémon dans ta collection avec une ligue (par défaut le volet ouvert) et le rang de ses IV figé à ce moment, et en option ses attaques (immédiate, chargée, seconde chargée), obscur ou purifié, taille (XXS, XS, XL, XXL), chanceux et shiny. Les doublons sont permis.
- **Menu** (bouton aux trois traits, en haut à droite) :
  - **Ma collection** : en liste ou en mosaïque, chaque case à la couleur du premier type, avec bordure dorée et badge « ★ Rang 1 » pour un rang 1 de sa ligue. Filtres combinables : ligue (Toutes, Mini, Super, Hyper, Master), rang d'IV (Tous, Top 10, Top 50), types du Pokémon, attaques (enregistrées, à défaut apprenables, par type ou par nom). Tri par rang, Pokédex, nom ou type. Un appui ouvre la fiche : modifier, voir le rang, supprimer (avec confirmation).
  - **Méta** : le top 100 PvPoke en Super, Hyper et Master (formes obscures comprises), avec la note, les types et le jeu d'attaques recommandé. La fiche d'un Pokémon montre ses meilleurs matchs et ses pires adversaires (en jaune, ceux que tu as dans ta collection), et propose « Voir le rang de mes IV » et « Ajouter à mon équipe ». La méta se met à jour toute seule (voir plus bas), avec un filtre par nom et un bouton pour vérifier.
  - **Team builder** : 3 Pokémon, une attaque immédiate et deux chargées chacun. Pour chacun : faiblesses et résistances selon ses types (×2,56, ×1,6, ×0,63, ×0,39…), types touchés en super efficace et types sur lesquels il est en difficulté selon ses attaques. Bilan d'équipe : faiblesses partagées, types que personne ne résiste, types qu'aucune attaque ne couvre. L'équipe est conservée.
  - **Table des types** : forces, faiblesses et résistances des 18 types, avec une pastille colorée par type.
  - **Paramètres** : mode Auto / Jour / Nuit (or adouci la nuit) et taille de police de 85 à 140 %. Les réglages sont conservés.

> Pas encore de lecture d'écran ni de bulle flottante : voir la [feuille de route](#feuille-de-route).

## Installer sur Android

L'app n'est pas sur le Play Store.

**Première installation** : onglet **Releases** du dépôt, dernière version, télécharger `ivhelper.apk` et l'ouvrir sur le téléphone (autoriser les sources inconnues).

**Mises à jour** : chaque fusion dans `main` publie une Release `v1.0.N` signée avec la clé fixe d'ivHelper. Au démarrage, l'app interroge GitHub ; si une version plus récente existe, une bannière propose « Mettre à jour ». L'APK se télécharge dans l'app puis l'installeur d'Android s'ouvre : un appui sur « Installer », et la nouvelle version remplace l'ancienne en gardant ta collection, ton équipe et tes réglages. Le menu affiche la version installée et un bouton « Vérifier les mises à jour ». En cas d'échec du téléchargement, « Via le navigateur » ouvre l'APK directement.

**Clé de signature** : la CI signe avec la clé fournie par les secrets du dépôt `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` et `ANDROID_KEY_PASSWORD` (`tool/configure_signing.py`). Sans ces secrets, l'APK est signé avec une clé de débogage et aucune Release n'est publiée. Les APK de chaque exécution restent aussi disponibles en artefact `ivhelper-apk` dans l'onglet Actions.

**Méta à jour sans réinstaller** : une tâche planifiée du dépôt (`.github/workflows/meta.yml`, chaque jour à 4 h 17 UTC, ou à la main depuis l'onglet Actions) régénère `assets/meta.json` depuis PvPoke et ne le publie que s'il a changé. L'app télécharge ce fichier à l'ouverture de l'onglet Méta, le garde en cache, et retombe sur la copie incluse sans réseau.

**iPhone** : pas de version pour l'instant. Une installation personnelle passera soit par un Mac, soit par TestFlight avec un compte développeur Apple.

## Comment le rang est calculé

Pour chacune des 4096 combinaisons d'IV (0 à 15 pour l'Attaque, la Défense et les PV) :

1. On prend le **plus haut niveau** (par demi-pas, jusqu'au niveau maximal choisi) dont le PC reste sous le plafond de la ligue. En Master, le plafond est fixé à 10 000 PC (comme PvPoke) : tout le monde monte au niveau maximal, et 15/15/15 est rang 1.
2. On calcule le **produit de stats** : `atk × cpm · def × cpm · ⌊pv × cpm⌋`.
3. On trie par produit décroissant, puis PC décroissant, puis IV décroissants, de façon déterministe. Le rang 1 vaut 100 %, les autres sont en pourcentage du meilleur produit.

Formules : `PC = ⌊atk · √def · √pv · cpm² / 10⌋` (minimum 10), `PV = ⌊pv · cpm⌋` (minimum 10), où `atk`, `def`, `pv` sont les stats de base de l'espèce plus l'IV.

Vérifié sur Flambusard : 15/15/15 est rang 2 246 en Super (niveau 23,5, 1 480 PC) et rang 21 en Hyper au niveau 51 ; les rangs 1 et 2 Hyper sont 13/15/15 et 13/15/14. En Mini, 15/15/15 est rang 550 (niveau 8, 497 PC) et le rang 1 est 0/14/2 ; en Master, 15/15/15 est rang 1 (niveau 51, 2 522 PC).

## Développement

### Prérequis

Flutter stable (Dart 3.5 ou plus). Le projet utilise `material_ui` (Material n'est plus dans le SDK depuis Flutter 3.47) et `shared_preferences`.

```bash
flutter pub get
flutter analyze
flutter test
```

Les dossiers `android/` et `ios/` ne sont pas committés. La CI les génère avec `flutter create --platforms=android --project-name ivhelper --org fr.ivhelper .`, applique le nom « ivHelper » et les icônes de `tool/android_icons/`, puis compile l'APK. Pour lancer l'app en local, fais la même génération une fois, puis `flutter run`.

### Organisation

| Dossier | Contenu |
|---|---|
| `lib/core/` | Logique pure, sans Flutter : stats, multiplicateurs de PC, table de rangs, espèces, types, attaques, analyse d'équipe |
| `lib/state/` | `LookupController` (rang), `TeamController` (team builder), `MetaController` (méta), `CollectionController` (collection) |
| `lib/settings/` | Réglages (mode, police) et stockage de l'équipe, de la méta en cache et de la collection |
| `lib/ui/` | Écrans (rang, team builder, table des types), thème, logo et pastilles de type dessinés en code |
| `assets/species.json` | 1 180 espèces et formes (nom français, stats de base, types, attaques) |
| `assets/moves.json` | 325 attaques (nom français, type, immédiate ou chargée) |
| `assets/meta.json` | Top 100 PvPoke en Super, Hyper et Master, mis à jour chaque jour |
| `tool/` | `build_species.py` (espèces, attaques), `build_meta.py` (méta), `build_icon.py` (icônes), `ci_wait.sh` (attente de la CI) |
| `docs/` | Sources des données, design et plan d'implémentation |

### Régénérer les données et les icônes

```bash
python3 tool/build_species.py GAMEMASTER NOMS MOVES NOMS_ATTAQUES assets/species.json assets/moves.json   # voir docs/data-sources.md
python3 tool/build_meta.py DOSSIER_SOURCES assets/meta.json        # méta (voir docs/data-sources.md)
python3 tool/build_icon.py                                          # icônes Android + assets/logo.png
```

### Tests

Chaque couche a ses tests : `test/core` (formules, table, espèces), `test/state`, `test/settings`, `test/ui` (widgets). La CI (`.github/workflows/ci.yml`) lance analyse et tests, puis compile l'APK.

## Feuille de route

- [x] **Phase 1** : saisie manuelle, rang Mini, Super, Hyper et Master, tableau dépliable, thème, réglages
- [x] **Phase 1 bis** : team builder, table des types, ligues Mini et Master, méta à jour
- [ ] **Phase 2** : lecture des IV depuis une capture d'écran (nom, PC, PV, barres d'évaluation)
- [ ] **Phase 3** : pastille flottante Android qui ouvre le tableau par-dessus Pokémon GO
- [ ] **Phase 4** : parcours iPhone (analyse de la dernière capture d'écran)

Le détail est dans [le plan](docs/superpowers/plans/2026-11-24-ivhelper.md) et [le design](docs/superpowers/specs/2026-11-24-pvp-rank-overlay-design.md).

## Données et crédits

Stats de base, multiplicateurs de PC, formes et classements de la méta : [PvPoke](https://github.com/pvpoke/pvpoke) (licence MIT). Noms français : [PokéAPI](https://pokeapi.co). Détails dans [`docs/data-sources.md`](docs/data-sources.md).

ivHelper est un projet personnel, sans lien avec Niantic, Nintendo ou The Pokémon Company. Pokémon et Pokémon GO sont des marques de leurs propriétaires.
