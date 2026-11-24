# ivHelper

App Flutter personnelle : rang PvP (ligues Mini 500 PC, Super 1500, Hyper 2500, Master sans limite, plafond technique 10 000 comme PvPoke) d'un Pokémon GO à partir de son nom ou numéro et de ses IV. Phase 1 faite (saisie manuelle). Voir `README.md` et `docs/superpowers/plans/2026-11-24-ivhelper.md` pour la suite.

## Langue

Tout est en français : interface, commentaires `///`, messages de commit, réponses. Identifiants de code en anglais.

## Commandes

- `flutter pub get`, `flutter analyze`, `flutter test`
- Le bac à sable de Claude **n'a pas Flutter** : la CI GitHub Actions fait foi. Pousser, puis `./tool/ci_wait.sh` (attend la CI du commit courant via `gh`). Les erreurs réseau Gradle du job `apk` sont passagères : `gh run rerun <id> --failed`.
- `python3 tool/build_icon.py` regénère les icônes ; `tool/build_species.py` regénère `assets/species.json` et `assets/moves.json` (voir `docs/data-sources.md`).

## Architecture

- `lib/core/` : logique pure sans Flutter (stats, `cpm`, `buildRankTable`, `rankIv`, `SpeciesRepository`, `PokeType` et table des types, `MoveBook`, `DefenseProfile`/`OffenseProfile`/`TeamSummary`). Toute règle de calcul va ici, avec ses tests.
- `lib/state/lookup_controller.dart` : `ChangeNotifier` (espèce, IV, `maxLevel` 50 ou 51, `minIv` 0 ou 10). Pas de Riverpod ni autre gestionnaire d'état : `ListenableBuilder`.
- `lib/state/team_controller.dart` : 3 emplacements (espèce, attaque immédiate, deux chargées distinctes, `collectionId` si importé de la collection), enregistrés en JSON via `SettingsStore.writeTeam`. `importFromCollection` refuse une entrée déjà présente dans un autre emplacement.
- `lib/state/meta_controller.dart` : méta PvPoke la plus récente entre la copie incluse (`assets/meta.json`), le cache et la version en ligne (`HttpMetaSource`, raw.githubusercontent.com du dépôt). `MetaSource` est remplacé par `FakeMetaSource` (`test/support/fake_meta.dart`) dans les tests : aucun réseau en test.
- `lib/core/collection.dart` + `lib/state/collection_controller.dart` : collection d'entrées (espèce, IV, niveau max, ligue `League` de `lib/core/league.dart`, rang/pourcentage/PC/niveau **figés à l'enregistrement**, attaques facultatives, `ShadowState`, `PokeSize`, chanceux, shiny, costume ; doublons permis ; deux chargées toujours distinctes). `update` refige le rang seulement si la ligue change. `CollectionFilter` (ligue du tag, Top 10/50, types, attaques enregistrées sinon apprenables ; combinés en ET), `filterAndSort`, vue liste ou mosaïque. Menu d'enregistrement : `save_pokemon_sheet.dart` ; fiche : `collection_detail_screen.dart` ; suppression toujours confirmée (`confirmDelete`). La liste méta est teintée par le premier type ; bordure jaune et badge « Dans ta collection · rang N » si la collection a la même espèce, même état obscur, tagguée dans cette ligue (meilleur rang). La fiche méta surligne en jaune les matchs dont l'espèce est possédée (« (Obscur) » ignoré, toutes ligues).
- `lib/settings/` : `SettingsController` et `SettingsStore` (mémoire en test, `PrefsSettingsStore` en vrai) ; stocke aussi l'équipe, la méta en cache et la collection.
- `lib/ui/` : écrans et widgets ; thème dans `app_theme.dart` (jour jaune vif, nuit or adouci), logo dans `iv_logo.dart`, pastilles de type (couleurs et icônes Material, pas les icônes officielles) dans `type_badge.dart`. Le menu (`settings_drawer.dart`) ouvre le team builder et la table des types.
- Importer `package:material_ui/material_ui.dart`, jamais `package:flutter/material.dart` (déprécié, `flutter analyze` échoue).
- `android/` et `ios/` ne sont **pas** committés : le job `apk` de `.github/workflows/ci.yml` les génère, applique le nom « ivHelper », ajoute la permission INTERNET (méta) et copie `tool/android_icons/`.
- Mises à jour de l'app : le job `apk` signe avec la clé fixe (secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, patch de `build.gradle.kts` par `tool/configure_signing.py`), numérote le build avec `github.run_number` (`--build-number`, `--dart-define=BUILD_NUMBER`, version `1.0.N`), puis le job `release` publie la Release `v1.0.N` avec `ivhelper.apk` (push sur `main` seulement, et seulement si signé). L'app (`UpdateController`, `GitHubUpdateSource`) compare `releases/latest` à `currentBuildNumber` et ouvre l'installeur via `open_filex` (permission REQUEST_INSTALL_PACKAGES ajoutée par la CI). Build 0 (local) : pas de vérification au démarrage. La clé ne doit jamais être committée.
- `.github/workflows/meta.yml` : tâche quotidienne qui régénère `assets/meta.json` avec `tool/build_meta.py` et committe sur `main` seulement s'il change. Ses commits (github-actions[bot]) ne relancent pas la CI. Penser à `git pull` avant de travailler.

## Règles métier à ne pas casser

- Niveau maximal 51 par défaut (50 plus bonus meilleur ami) ; 50 aussi sélectionnable.
- Pour chaque combinaison d'IV : plus haut niveau (demi-pas) dont le PC ≤ plafond ; tri par produit de stats décroissant, puis PC décroissant, puis IV décroissants ; pourcentage = produit / meilleur × 100.
- `PC = ⌊atk·√def·√pv·cpm²/10⌋` (min 10), `PV = ⌊pv·cpm⌋` (min 10).
- Valeurs de référence testées (Flambusard 176/155/186) : 15/15/15 est rang 2246 en Super, 21 en Hyper ; rangs 1 et 2 Hyper : 13/15/15 et 13/15/14 ; niveau max 50 : rang 1 Hyper. Mini : 15/15/15 rang 550 (niveau 8, 497 PC), rang 1 = 0/14/2. Master : 15/15/15 rang 1 (niveau 51, 2522 PC).
- `minIv` 10 : le classement ne porte que sur 6³ = 216 combinaisons, et les IV saisis sont relevés au plancher.
- Table des types Pokémon GO : ×1,6 super efficace, ×0,625 peu efficace, ×0,390625 immunité ; multiplicateurs cumulés sur double type. Offensive : meilleur multiplicateur parmi les attaques, sur types simples.
- Attaques d'événement : `Species.eliteMoves` (champ `elite` de `species.json`, `eliteMoves` PvPoke) et `MetaMove.elite`, affichées avec un astérisque (`moveLabel`). Puissance PvP : `Move.power` / `MetaMove.power`.
- Les bandeaux avec action (« Voir ») disparaissent après 5 s (`duration` + `persist: false`).
- Format : décimales avec virgule, espaces insécables (U+00A0) pour les milliers, stats tronquées à 1 décimale, pourcentage à 2 décimales, « 100 % ».

## Pièges connus

- Les valeurs attendues des tests se vérifient par un calcul indépendant (port Python), pas à l'œil : deux fois c'était le test qui était faux (cpm, puis 6³ = 216 et non 1331), pas le code.
- Noms d'espèces : formes régionales « Raichu d'Alola » ; autres formes avec libellé anglais entre parenthèses ; costumes, méga et formes obscures exclus.
- Les tests de `meta_asset_test.dart` lisent le vrai `meta.json`, qui change chaque jour : n'y tester que la structure, jamais un nom ou un rang précis.
- Un APK signé avec la clé de débogage (artefact d'une branche, ou CI sans secrets) ne s'installe pas par-dessus une version de Release : désinstaller d'abord.
- Dans le bac à sable, un hook peut refuser une commande Bash très longue avec « Very Good CLI is required » : écrire les fichiers avec l'outil Write.

## Hors périmètre actuel

Lecture d'écran (OCR), pastille flottante Android, import de capture iPhone : prévus aux phases 2 à 4 du plan, à ne pas commencer sans accord de Pickles. Pas de publication sur les stores. Merge dans `main` seulement sur accord.
