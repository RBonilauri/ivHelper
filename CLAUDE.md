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
- Mises à jour de l'app : le job `apk` signe avec la clé fixe (secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, patch de `build.gradle.kts` par `tool/configure_signing.py`), numérote le build avec `github.run_number` (`--build-number`, `--dart-define=BUILD_NUMBER`, `--dart-define=VERSION_NAME`, version `1.1.N`), puis le job `release` publie la Release `v1.1.N` avec `ivhelper.apk` (push sur `main` seulement, et seulement si signé). L'app (`UpdateController`, `GitHubUpdateSource`) compare `releases/latest` à `currentBuildNumber` et ouvre l'installeur via `open_filex` (permission REQUEST_INSTALL_PACKAGES ajoutée par la CI). Build 0 (local) : pas de vérification au démarrage. La clé ne doit jamais être committée.
- `.github/workflows/meta.yml` : tâche quotidienne qui régénère `assets/meta.json` avec `tool/build_meta.py` et committe sur `main` seulement s'il change. Ses commits (github-actions[bot]) ne relancent pas la CI. Penser à `git pull` avant de travailler.

## Règles métier à ne pas casser

- Accueil : niveau maximal 50 et tous les IV par défaut (demandé par Pickles) ; 51 (50 plus bonus meilleur ami) sélectionnable. Liste des IV : top 10, puis bouton « Afficher 10 de plus » (remis à 10 au changement de ligue).
- Pour chaque combinaison d'IV : plus haut niveau (demi-pas) dont le PC ≤ plafond ; tri par produit de stats décroissant, puis PC décroissant, puis IV décroissants ; pourcentage = produit / meilleur × 100.
- `PC = ⌊atk·√def·√pv·cpm²/10⌋` (min 10), `PV = ⌊pv·cpm⌋` (min 10).
- Valeurs de référence testées (Flambusard 176/155/186) : 15/15/15 est rang 2246 en Super, 21 en Hyper ; rangs 1 et 2 Hyper : 13/15/15 et 13/15/14 ; niveau max 50 : rang 1 Hyper. Mini : 15/15/15 rang 550 (niveau 8, 497 PC), rang 1 = 0/14/2. Master : 15/15/15 rang 1 (niveau 51, 2522 PC).
- `minIv` 10 : le classement ne porte que sur 6³ = 216 combinaisons, et les IV saisis sont relevés au plancher.
- Table des types Pokémon GO : ×1,6 super efficace, ×0,625 peu efficace, ×0,390625 immunité ; multiplicateurs cumulés sur double type. Offensive : meilleur multiplicateur parmi les attaques, sur types simples.
- Attaques d'événement : `Species.eliteMoves` (champ `elite` de `species.json`, `eliteMoves` PvPoke) et `MetaMove.elite`, affichées avec un astérisque (`moveLabel`). Puissance PvP : `Move.power` / `MetaMove.power`. Énergie `Move.energy` → `chargeBars` (3 si ≤ 33, 2 jusqu'à 50, 1 au-delà, comme le jeu) et changements de stats `Move.effects` (`StatChange`, libellés `effectLabels` : « Ton attaque −2 », « Défense adverse −1 (30 % de chance) »). Fiches (collection et méta) : `MoveLine` (`lib/ui/move_line.dart`), barres de la couleur du type ; la fiche méta reprend énergie et effets du `MoveBook` passé dans `MetaActions.moves`.
- Menu d'enregistrement et de modification : attaques de la méta en gras, sans ★ (retirée à la demande de Pickles), dans les menus (`MetaSnapshot.movesetForAnyLeague` : ligue choisie, sinon Super, Hyper, Master ; forme obscure si cochée). Pas d'encadré au-dessus des attaques (refusé par Pickles). La méta est chargée au démarrage pour ça.
- Saisie des IV : `IvBar` (`lib/ui/iv_bar.dart`, segments à toucher ou glisser, − et + gardés avec les infobulles « Diminuer/Augmenter Atk|Déf|PV ») et saisie rapide (`parseIvText`). Dernières recherches : `HistoryController` (8 max, une par espèce, `SettingsStore.readHistory`), affichées quand aucune espèce n'est saisie. Dans les tests, le champ d'espèce est `find.byType(TextField).first`.
- Collection : filtre de type en ligne (`_TypeFilterRow`, types présents seulement, avec compte). Bilan d'équipe : rubriques repliables (`_ChipLine(collapsible: true)`), ouvertes par défaut. Fiche de collection : « Attaques », puis « Immédiate » et « Chargée(s) » en petit, nom en gras si méta, puissance seule (sans le mot « puissance »).
- Barres de recherche : `SearchField` (`lib/ui/search_field.dart`, croix « Effacer » visible avec du texte, qui appelle `onChanged('')`). Indication des champs vides grise et italique via `inputDecorationTheme` (`labelStyle`/`hintStyle`, `floatingLabelStyle` normal). Menu : Superposition en dernier des entrées.
- Superposition (version 1.1) : `lib/overlay/` (`overlayMain` dans `main.dart`, point d'entrée du plugin `flutter_overlay_window`). `PluginOverlayLauncher` (autorisations + pastille), `PluginOverlayWindow` (pastille 64 dp ↔ panneau), `DeviceScreenScanner` (capture par le plugin local `packages/ivhelper_capture` en Java : MediaProjection + service de premier plan + notification « Arrêter », ML Kit `text-recognition` appelé en Java sur le Bitmap capturé (`TextReader`, lignes renvoyées avec la capture : `CapturedScreen.lines`, jamais de décodage de fichier par ML Kit, qui renvoyait un bitmap nul sur le téléphone de Pickles), puis `lib/core/screen_reading.dart`). `screen_reading.dart` est pur et testé : `parseScreenText` (PC, PV max, phrase « Ce X a été attrapé », bonbons, mots en capitales, types, étiquettes Attaque/Défense/PV), `readBar` (barre la plus longue sous l'étiquette, part colorée × 15 ; calibré sur de vraies captures : 0/13/10, Kapoera 1/13/13), `identify` (famille par le nom, stade par PC+PV+IV via `matchingLevel`). Familles : champs `family`/`stage` de `species.json`, `SpeciesRepository.familyOf`. Tableau : `FamilyRankTable`. La pastille écrit la collection dans les mêmes SharedPreferences ; l'app relit au retour au premier plan (`SettingsStore.refresh`). Le service `OverlayService` du plugin est déclaré dans le manifeste du plugin local. Fakes de test : `test/support/fake_overlay.dart`. Ne jamais committer de capture d'écran de Pickles (lieu de capture visible).
- Les bandeaux avec action (« Voir ») disparaissent après 5 s (`duration` + `persist: false`).
- Format : décimales avec virgule, espaces insécables (U+00A0) pour les milliers, stats tronquées à 1 décimale, pourcentage à 2 décimales, « 100 % ».

## Pièges connus

- Les valeurs attendues des tests se vérifient par un calcul indépendant (port Python), pas à l'œil : deux fois c'était le test qui était faux (cpm, puis 6³ = 216 et non 1331), pas le code.
- Noms d'espèces : formes régionales « Raichu d'Alola » ; autres formes avec libellé anglais entre parenthèses ; costumes, méga et formes obscures exclus.
- Les tests de `meta_asset_test.dart` lisent le vrai `meta.json`, qui change chaque jour : n'y tester que la structure, jamais un nom ou un rang précis.
- Un APK signé avec la clé de débogage (artefact d'une branche, ou CI sans secrets) ne s'installe pas par-dessus une version de Release : désinstaller d'abord.
- Dans le bac à sable, un hook peut refuser une commande Bash très longue avec « Very Good CLI is required » : écrire les fichiers avec l'outil Write.

## Hors périmètre actuel

Import de capture iPhone : phase 4, à ne pas commencer sans accord de Pickles. Pas de publication sur les stores.

## Livraison

Pickles a demandé de **toujours modifier puis fusionner dans `main`** sans redemander : branche, CI verte, merge `--no-ff`, push, attendre la Release `v1.1.N`, puis lui annoncer la version à installer depuis l'app.
