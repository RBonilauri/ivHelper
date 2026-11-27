#!/usr/bin/env python3
"""Génère assets/meta.json : la méta PvPoke en Super, Hyper et Master.

Usage : build_meta.py DOSSIER_SOURCES SORTIE [TOP]

DOSSIER_SOURCES contient :
- gamemaster.json et rankings-1500.json, rankings-2500.json, rankings-10000.json
  (src/data/gamemaster.json et src/data/rankings/all/overall/ du dépôt pvpoke,
  licence MIT) ;
- pokemon_species_names.csv, moves.csv, move_names.csv (PokéAPI).

TOP vaut 300 par défaut. Le champ « species » ne renvoie qu'à une espèce de
species.json (dans le même dossier que SORTIE), sinon il vaut null. La date « updated » ne change que si le classement
change, pour que la tâche planifiée ne committe que les vraies mises à jour.
"""
import datetime
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_species import (  # noqa: E402
    REGIONAL,
    TYPES_FR,
    choose_species,
    form_label,
    french_moves,
    french_species,
    move_name,
)

LEAGUES = {"great": 1500, "ultra": 2500, "master": 10000}


def labels(pokemon, fr):
    """speciesId → (libellé affiché, nom de l'espèce dans species.json ou None)."""
    chosen = choose_species(pokemon, fr)
    known = {p["speciesId"]: label for label, p in chosen}
    # Formes absentes de species.json mais identiques à une forme retenue
    # (costumes, Genesect et ses modules) : même rang d'IV que cette forme.
    same_stats = {
        (p["dex"], json.dumps(p["baseStats"], sort_keys=True)): label
        for label, p in chosen
    }
    out = {}
    pokemon_by_id = {p["speciesId"]: p for p in pokemon}
    for p in pokemon:
        sid = p["speciesId"]
        shadow = "shadow" in p.get("tags", []) or sid.endswith("_shadow")
        base_id = sid[: -len("_shadow")] if sid.endswith("_shadow") else sid
        base = pokemon_by_id.get(base_id, p)
        lookup = known.get(base_id)
        if lookup is not None:
            label = lookup
        else:
            name = fr.get(p["dex"], p["speciesName"])
            tag = next((t for t in p.get("tags", []) if t in REGIONAL), None)
            if tag:
                label = f"{name} {REGIONAL[tag]}"
            elif "_" in base_id:
                label = form_label(name, base)
            else:
                label = name
            lookup = same_stats.get(
                (p["dex"], json.dumps(base["baseStats"], sort_keys=True))
            )
        if shadow:
            label += " (Obscur)"
        out[sid] = (label, lookup)
    return out


def build(src, top, known_species):
    fr = french_species(os.path.join(src, "pokemon_species_names.csv"))
    fr_moves = french_moves(
        os.path.join(src, "moves.csv"), os.path.join(src, "move_names.csv")
    )
    gm = json.load(open(os.path.join(src, "gamemaster.json"), encoding="utf-8"))
    names = labels(gm["pokemon"], fr)
    pokemon = {p["speciesId"]: p for p in gm["pokemon"]}
    moves = {m["moveId"]: m for m in gm["moves"]}

    def move(mid, elite):
        m = moves.get(mid)
        if m is None or m["type"] not in TYPES_FR:
            return None
        return {
            "id": mid,
            "name": move_name(mid, m["name"], fr_moves),
            "type": m["type"],
            "power": m.get("power", 0),
            "elite": mid in elite,
        }

    leagues = {}
    for key, cap in LEAGUES.items():
        path = os.path.join(src, f"rankings-{cap}.json")
        ranking = json.load(open(path, encoding="utf-8"))
        entries = []
        for e in ranking:
            sid = e["speciesId"]
            p = pokemon.get(sid)
            if p is None or sid not in names:
                continue
            label, lookup = names[sid]
            if lookup not in known_species:
                lookup = None
            elite = set(p.get("eliteMoves", []))
            moveset = [move(m, elite) for m in e.get("moveset", [])]
            moveset = [m for m in moveset if m is not None]
            if not moveset:
                continue
            entries.append({
                "rank": len(entries) + 1,
                "name": label,
                "species": lookup,
                "shadow": label.endswith("(Obscur)"),
                "types": [t for t in p["types"] if t in TYPES_FR],
                "score": e.get("score"),
                "fast": moveset[0],
                "charged": moveset[1:],
                "bestMatchups": [names[m["opponent"]][0] for m in e.get("matchups", []) if m["opponent"] in names],
                "worstMatchups": [names[m["opponent"]][0] for m in e.get("counters", []) if m["opponent"] in names],
            })
            if len(entries) >= top:
                break
        leagues[key] = entries
    return leagues


def main(src, out, top="300"):
    species_path = os.path.join(os.path.dirname(out), "species.json")
    known_species = {s["name"] for s in json.load(open(species_path, encoding="utf-8"))}
    leagues = build(src, int(top), known_species)
    updated = datetime.date.today().isoformat()
    if os.path.exists(out):
        try:
            old = json.load(open(out, encoding="utf-8"))
            if old.get("leagues") == leagues:
                updated = old.get("updated", updated)
        except (ValueError, OSError):
            pass
    data = {"updated": updated, "source": "PvPoke", "leagues": leagues}
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    print(f"méta du {updated} : " + ", ".join(f"{k} {len(v)}" for k, v in leagues.items()))


if __name__ == "__main__":
    main(*sys.argv[1:4])
