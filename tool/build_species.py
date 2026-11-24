#!/usr/bin/env python3
"""Génère assets/species.json à partir de deux sources communautaires.

Usage : build_species.py GAMEMASTER_JSON SPECIES_NAMES_CSV SORTIE_JSON

- GAMEMASTER_JSON : src/data/gamemaster.json du dépôt pvpoke (licence MIT).
- SPECIES_NAMES_CSV : data/v2/csv/pokemon_species_names.csv du dépôt PokéAPI
  (noms français, langue 5).
Écarte les variantes obscures, les méga-évolutions et les costumes.
"""
import csv
import json
import sys

REGIONAL = {
    "alolan": "d'Alola",
    "galarian": "de Galar",
    "hisuian": "de Hisui",
    "paldean": "de Paldea",
}
SKIPPED = {"shadow", "mega", "supermega"}


def french_names(path):
    names = {}
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["local_language_id"] == "5":
                names[int(row["pokemon_species_id"])] = row["name"]
    return names


def main(gamemaster, names_csv, out):
    fr = french_names(names_csv)
    pokemon = json.load(open(gamemaster, encoding="utf-8"))["pokemon"]
    by_dex = {}
    for p in pokemon:
        if set(p.get("tags", [])) & SKIPPED:
            continue
        by_dex.setdefault(p["dex"], []).append(p)
    result = []
    for dex in sorted(by_dex):
        name = fr.get(dex)
        if name is None:
            continue
        entries = by_dex[dex]
        regional = [p for p in entries if set(p.get("tags", [])) & set(REGIONAL)]
        plain = [p for p in entries if p not in regional]
        base = [p for p in plain if "_" not in p["speciesId"]]
        if base:
            chosen = [(name, base[0])]
        elif len(plain) == 1:
            chosen = [(name, plain[0])]
        else:
            chosen = [
                (f"{name} ({p['speciesName'].split('(')[-1].rstrip(')').strip()})", p)
                for p in plain
            ]
        for p in regional:
            tag = next(t for t in p["tags"] if t in REGIONAL)
            chosen.append((f"{name} {REGIONAL[tag]}", p))
        for label, p in chosen:
            b = p["baseStats"]
            result.append(
                {"dex": dex, "name": label, "atk": b["atk"], "def": b["def"], "sta": b["hp"]}
            )
    with open(out, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(result)} espèces écrites dans {out}")


if __name__ == "__main__":
    main(*sys.argv[1:4])
