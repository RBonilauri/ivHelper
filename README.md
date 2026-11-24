<div align="center">

<img src="assets/logo.png" alt="Logo ivHelper : un i dont le point est une pokéball, suivi d'un v" width="120">

# ivHelper

**Le rang PvP de tes Pokémon GO, en ligue Super et Hyper, en trois appuis.**

Flutter · Android · données PvPoke

</div>

---

## À quoi ça sert

Tu as un Pokémon avec ses IV (Attaque / Défense / PV). Tu veux savoir **où il se place** parmi toutes les combinaisons possibles pour la ligue Super (1500 PC) et la ligue Hyper (2500 PC). ivHelper classe les 4096 combinaisons d'IV de l'espèce et te montre la tienne.

## Fonctionnalités

- **Saisie par nom ou numéro** du Pokédex, avec suggestions si le nom est incomplet ou mal orthographié (accents et casse ignorés).
- **Deux volets : Super · 1500 et Hyper · 2500**, chacun avec ton rang, ton pourcentage du meilleur produit de stats, et le haut du classement.
- **Tableau dépliable** : rang, niveau, PC, IV (Atk/Déf/PV) et Parfait (%). Un appui sur une ligne affiche ses stats réelles (Atk, Déf, PV, stat globale) ; l'interrupteur **Détails** déplie tout.
- **Niveau maximal** : 50, ou 51 (niveau 50 plus bonus meilleur ami).
- **Plancher d'IV** : « Min 10/10/10 » restreint le classement aux 216 combinaisons dont chaque IV vaut au moins 10.
- **Paramètres** (bouton aux trois traits, en haut à droite) : mode Auto / Jour / Nuit et taille de police de 85 à 140 %. Les réglages sont conservés.

> Pas encore de lecture d'écran ni de bulle flottante : voir la [feuille de route](#feuille-de-route).

## Installer sur Android

L'app n'est pas sur le Play Store. Chaque envoi sur GitHub compile un APK :

1. Onglet **Actions** du dépôt, dernière exécution de la CI sur `main` (connexion GitHub nécessaire).
2. Télécharger l'artefact **`ivhelper-apk`** et le décompresser.
3. Ouvrir `app-release.apk` sur le téléphone et autoriser les sources inconnues.

**Mise à jour** : il faut retélécharger l'APK, rien ne se met à jour tout seul. Si Android refuse d'installer par-dessus (« conflit avec un paquet existant »), désinstalle l'ancienne version d'abord : la CI signe avec une clé de débogage différente à chaque compilation.

**iPhone** : pas de version pour l'instant. Une installation personnelle passera soit par un Mac, soit par TestFlight avec un compte développeur Apple.

## Comment le rang est calculé

Pour chacune des 4096 combinaisons d'IV (0 à 15 pour l'Attaque, la Défense et les PV) :

1. On prend le **plus haut niveau** (par demi-pas, jusqu'au niveau maximal choisi) dont le PC reste sous le plafond de la ligue.
2. On calcule le **produit de stats** : `atk × cpm · def × cpm · ⌊pv × cpm⌋`.
3. On trie par produit décroissant, puis PC décroissant, puis IV décroissants, de façon déterministe. Le rang 1 vaut 100 %, les autres sont en pourcentage du meilleur produit.

Formules : `PC = ⌊atk · √def · √pv · cpm² / 10⌋` (minimum 10), `PV = ⌊pv · cpm⌋` (minimum 10), où `atk`, `def`, `pv` sont les stats de base de l'espèce plus l'IV.

Vérifié sur Flambusard : 15/15/15 est rang 2 246 en Super (niveau 23,5, 1 480 PC) et rang 21 en Hyper au niveau 51 ; les rangs 1 et 2 Hyper sont 13/15/15 et 13/15/14.

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
| `lib/core/` | Logique pure, sans Flutter : stats, multiplicateurs de PC, table de rangs, espèces |
| `lib/state/` | `LookupController` : espèce, IV, niveau max, plancher d'IV, résultats |
| `lib/settings/` | Réglages (mode, police) et leur stockage |
| `lib/ui/` | Écrans, thème jaune, logo dessiné en code, barre latérale |
| `assets/species.json` | 1 117 espèces et formes régionales (nom français, stats de base) |
| `tool/` | `build_species.py` (données), `build_icon.py` (icônes), `ci_wait.sh` (attente de la CI) |
| `docs/` | Sources des données, design et plan d'implémentation |

### Régénérer les données et les icônes

```bash
python3 tool/build_species.py GAMEMASTER NOMS assets/species.json   # voir docs/data-sources.md
python3 tool/build_icon.py                                          # icônes Android + assets/logo.png
```

### Tests

Chaque couche a ses tests : `test/core` (formules, table, espèces), `test/state`, `test/settings`, `test/ui` (widgets). La CI (`.github/workflows/ci.yml`) lance analyse et tests, puis compile l'APK.

## Feuille de route

- [x] **Phase 1** : saisie manuelle, rang Super et Hyper, tableau dépliable, thème, réglages
- [ ] **Phase 2** : lecture des IV depuis une capture d'écran (nom, PC, PV, barres d'évaluation)
- [ ] **Phase 3** : pastille flottante Android qui ouvre le tableau par-dessus Pokémon GO
- [ ] **Phase 4** : parcours iPhone (analyse de la dernière capture d'écran)

Le détail est dans [le plan](docs/superpowers/plans/2026-11-24-ivhelper.md) et [le design](docs/superpowers/specs/2026-11-24-pvp-rank-overlay-design.md).

## Données et crédits

Stats de base, multiplicateurs de PC et formes : [PvPoke](https://github.com/pvpoke/pvpoke) (licence MIT). Noms français : [PokéAPI](https://pokeapi.co). Détails dans [`docs/data-sources.md`](docs/data-sources.md).

ivHelper est un projet personnel, sans lien avec Niantic, Nintendo ou The Pokémon Company. Pokémon et Pokémon GO sont des marques de leurs propriétaires.
