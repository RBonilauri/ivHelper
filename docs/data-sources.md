# Sources des données

`assets/species.json` et `assets/moves.json` sont générés par `tool/build_species.py` (`python3 tool/build_species.py GAMEMASTER NOMS_ESPECES MOVES NOMS_ATTAQUES SORTIE_ESPECES SORTIE_ATTAQUES`) à partir de :

- **PvPoke** (`src/data/gamemaster.json`), licence MIT : stats de base, types, attaques immédiates et chargées des espèces et formes régionales, type de chaque attaque, coût d'énergie des attaques chargées (`energy`) et changements de stats (`effects` : cible `self`/`opponent`, crans d'attaque et de défense, probabilité ; `buffs`/`buffTarget`/`buffApplyChance` de PvPoke).
- **PokéAPI** (`data/v2/csv/pokemon_species_names.csv`, `moves.csv`, `move_names.csv`) : noms français des espèces et des attaques. Variantes de Pokémon GO : « Puissance Cachée (Feu) », « Ball’Météo (Eau) », etc. ; repli sur le nom anglais si aucune correspondance.

La table des multiplicateurs de PC (`lib/core/cp_multiplier.dart`) vient de `src/js/pokemon/Pokemon.js` de PvPoke (MIT).

Formes écartées : variantes obscures, méga-évolutions, costumes. Les formes alternatives (Cheniti, Giratina, etc.) portent un libellé anglais entre parenthèses.

La table des types (`lib/core/poke_type.dart`) suit Pokémon GO : super efficace ×1,6, peu efficace ×0,625, immunité des jeux principaux ×0,390625.

## Méta

`assets/meta.json` est généré par `tool/build_meta.py DOSSIER SORTIE [TOP]`. DOSSIER contient `gamemaster.json`, `rankings-1500.json`, `rankings-2500.json` et `rankings-10000.json` (PvPoke, `src/data/rankings/all/overall/`), plus les trois CSV PokéAPI. Le script garde les TOP premiers (300 par défaut), avec la note, le jeu d'attaques recommandé (`moveset`), les meilleurs matchs (`matchups`) et les pires adversaires (`counters`). Les commentaires éditoriaux de PvPoke ne sont pas repris.

La tâche planifiée `.github/workflows/meta.yml` le régénère chaque jour et ne committe que si le classement a changé (la date `updated` reste celle du dernier changement).

Les formes alternatives aux stats ou types différents (Kyurem Noir/Blanc, Motisma, Deoxys, Dialga et Palkia Originels…) sont incluses dans `species.json` avec un libellé anglais entre parenthèses ; les costumes, de mêmes stats que la forme de base, restent écartés.
