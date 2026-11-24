# Sources des données

`assets/species.json` est généré par `tool/build_species.py` (`python3 tool/build_species.py GAMEMASTER NOMS SORTIE`) à partir de :

- **PvPoke** (`src/data/gamemaster.json`), licence MIT : stats de base des espèces et formes régionales.
- **PokéAPI** (`data/v2/csv/pokemon_species_names.csv`) : noms français des espèces.

La table des multiplicateurs de PC (`lib/core/cp_multiplier.dart`) vient de `src/js/pokemon/Pokemon.js` de PvPoke (MIT).

Formes écartées : variantes obscures, méga-évolutions, costumes. Les formes alternatives (Cheniti, Giratina, etc.) portent un libellé anglais entre parenthèses.
