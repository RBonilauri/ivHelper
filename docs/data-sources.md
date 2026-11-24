# Sources des données

`assets/species.json` et `assets/moves.json` sont générés par `tool/build_species.py` (`python3 tool/build_species.py GAMEMASTER NOMS_ESPECES MOVES NOMS_ATTAQUES SORTIE_ESPECES SORTIE_ATTAQUES`) à partir de :

- **PvPoke** (`src/data/gamemaster.json`), licence MIT : stats de base, types, attaques immédiates et chargées des espèces et formes régionales, type de chaque attaque.
- **PokéAPI** (`data/v2/csv/pokemon_species_names.csv`, `moves.csv`, `move_names.csv`) : noms français des espèces et des attaques. Variantes de Pokémon GO : « Puissance Cachée (Feu) », « Ball’Météo (Eau) », etc. ; repli sur le nom anglais si aucune correspondance.

La table des multiplicateurs de PC (`lib/core/cp_multiplier.dart`) vient de `src/js/pokemon/Pokemon.js` de PvPoke (MIT).

Formes écartées : variantes obscures, méga-évolutions, costumes. Les formes alternatives (Cheniti, Giratina, etc.) portent un libellé anglais entre parenthèses.

La table des types (`lib/core/poke_type.dart`) suit Pokémon GO : super efficace ×1,6, peu efficace ×0,625, immunité des jeux principaux ×0,390625.
