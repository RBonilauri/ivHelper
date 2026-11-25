#!/usr/bin/env python3
"""Génère assets/species.json et assets/moves.json à partir de sources communautaires.

Usage : build_species.py GAMEMASTER SPECIES_NAMES MOVES MOVE_NAMES SORTIE_ESPECES SORTIE_ATTAQUES

- GAMEMASTER : src/data/gamemaster.json du dépôt pvpoke (licence MIT) :
  stats de base, types, attaques immédiates et chargées.
- SPECIES_NAMES, MOVES, MOVE_NAMES : data/v2/csv/pokemon_species_names.csv,
  moves.csv et move_names.csv du dépôt PokéAPI (noms français, langue 5).
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
TYPES_FR = {
    "normal": "Normal", "fire": "Feu", "water": "Eau", "grass": "Plante",
    "electric": "Électrik", "ice": "Glace", "fighting": "Combat",
    "poison": "Poison", "ground": "Sol", "flying": "Vol", "psychic": "Psy",
    "bug": "Insecte", "rock": "Roche", "ghost": "Spectre", "dragon": "Dragon",
    "dark": "Ténèbres", "steel": "Acier", "fairy": "Fée",
}
# Identifiants Pokémon GO sans équivalent direct dans PokéAPI.
MOVE_ALIASES = {"SUPER_POWER": "superpower"}
# Suffixes de variantes : type en anglais (anciens noms des jeux) ou « PLUS ».
SUFFIX_TYPES = {
    "BURN": "fire", "CHILL": "ice", "DOUSE": "water", "SHOCK": "electric",
}


def move_effects(m):
    """Changements de stats d'une attaque : [{target, atk, def, chance}]."""
    if "buffs" not in m:
        return []
    chance = float(m.get("buffApplyChance", "1"))
    target = m.get("buffTarget", "self")
    if target == "both":
        parts = [("self", m.get("buffsSelf", [0, 0])),
                 ("opponent", m.get("buffsOpponent", [0, 0]))]
    else:
        parts = [(target, m["buffs"])]
    return [
        {"target": t, "atk": b[0], "def": b[1], "chance": chance}
        for t, b in parts
        if b[0] or b[1]
    ]


def french_species(path):
    names = {}
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["local_language_id"] == "5":
                names[int(row["pokemon_species_id"])] = row["name"]
    return names


def french_moves(moves_csv, names_csv):
    ids = {}
    with open(moves_csv, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            ids[row["id"]] = row["identifier"]
    names = {}
    with open(names_csv, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["local_language_id"] == "5" and row["move_id"] in ids:
                names[ids[row["move_id"]]] = row["name"]
    return names


def move_name(move_id, english, fr):
    """Nom français d'une attaque, avec repli sur le nom anglais de PvPoke."""
    if move_id in MOVE_ALIASES:
        return fr.get(MOVE_ALIASES[move_id], english)
    tokens = move_id.split("_")
    # Essaie la plus longue suite de jetons connue, en retirant des deux côtés.
    for length in range(len(tokens), 0, -1):
        for start in range(0, len(tokens) - length + 1):
            key = "-".join(tokens[start:start + length]).lower()
            if key in fr:
                rest = tokens[start + length:]
                name = fr[key]
                if rest == ["PLUS"]:
                    return name + " +"
                if len(rest) == 1:
                    t = SUFFIX_TYPES.get(rest[0], rest[0].lower())
                    if t in TYPES_FR:
                        return f"{name} ({TYPES_FR[t]})"
                return name
    return english


REGIONAL_FORMS = {
    "Alolan": "d'Alola", "Galarian": "de Galar",
    "Hisuian": "de Hisui", "Paldean": "de Paldea",
}


def form_label(name, p):
    """Libellé d'une forme : « Nom (Forme) », ou « Nom de Hisui » pour une forme
    régionale non marquée comme telle."""
    raw = p["speciesName"]
    if "(" in raw:
        form = raw.split("(")[-1].rstrip(")").strip()
    else:
        form = p["speciesId"].split("_", 1)[-1].replace("_", " ").title()
    if form in REGIONAL_FORMS:
        return f"{name} {REGIONAL_FORMS[form]}"
    return f"{name} ({form})"


def choose_species(pokemon, fr):
    """(libellé français, entrée PvPoke) des espèces retenues, par numéro."""
    by_dex = {}
    for p in pokemon:
        if set(p.get("tags", [])) & SKIPPED:
            continue
        by_dex.setdefault(p["dex"], []).append(p)
    chosen = []
    for dex in sorted(by_dex):
        name = fr.get(dex)
        if name is None:
            continue
        entries = by_dex[dex]
        regional = [p for p in entries if set(p.get("tags", [])) & set(REGIONAL)]
        plain = [p for p in entries if p not in regional]
        base = [p for p in plain if "_" not in p["speciesId"]]
        if base:
            b = base[0]
            chosen.append((name, b))
            # Formes aux stats ou types différents (Kyurem Noir, Motisma Lavage…) ;
            # les costumes, identiques à la forme de base, restent écartés.
            chosen.extend(
                (form_label(name, p), p)
                for p in plain
                if p is not b
                and (p["baseStats"] != b["baseStats"] or p["types"] != b["types"])
            )
        elif len(plain) == 1:
            chosen.append((name, plain[0]))
        else:
            chosen.extend((form_label(name, p), p) for p in plain)
        for p in regional:
            tag = next(t for t in p["tags"] if t in REGIONAL)
            chosen.append((f"{name} {REGIONAL[tag]}", p))
    return chosen


def main(gamemaster, species_csv, moves_csv, move_names_csv, out_species, out_moves):
    fr = french_species(species_csv)
    fr_moves = french_moves(moves_csv, move_names_csv)
    data = json.load(open(gamemaster, encoding="utf-8"))
    result = []
    used = set()
    used_fast = set()
    by_id = {p["speciesId"]: p for p in data["pokemon"]}

    def stage(p):
        depth, seen = 0, set()
        parent = (p.get("family") or {}).get("parent")
        while parent and parent in by_id and parent not in seen:
            seen.add(parent)
            depth += 1
            parent = (by_id[parent].get("family") or {}).get("parent")
        return depth

    for label, p in choose_species(data["pokemon"], fr):
        b = p["baseStats"]
        types = [t for t in p["types"] if t in TYPES_FR]
        fast = sorted(set(p.get("fastMoves", [])))
        charged = sorted(set(p.get("chargedMoves", [])))
        elite = sorted(set(p.get("eliteMoves", [])))
        used.update(fast)
        used_fast.update(fast)
        used.update(charged)
        result.append({
            "dex": p["dex"], "name": label,
            "atk": b["atk"], "def": b["def"], "sta": b["hp"],
            "types": types, "fast": fast, "charged": charged,
            "elite": elite,
            "family": (p.get("family") or {}).get("id") or p["speciesId"].upper(),
            "stage": stage(p),
        })
    moves = {}
    for m in data["moves"]:
        if m["moveId"] not in used or m["type"] not in TYPES_FR:
            continue
        fast = m.get("energyGain", 0) > 0 or (
            m.get("energy", 0) == 0 and m["moveId"] in used_fast
        )
        moves[m["moveId"]] = {
            "name": move_name(m["moveId"], m["name"], fr_moves),
            "type": m["type"],
            "power": m.get("power", 0),
            # Immédiate si elle rapporte de l'énergie ; Morphing (ni gain ni coût)
            # l'est aussi. Lutte coûte de l'énergie : elle est chargée.
            "fast": fast,
        }
        if not fast and m.get("energy", 0) > 0:
            moves[m["moveId"]]["energy"] = m["energy"]
        effects = move_effects(m)
        if effects:
            moves[m["moveId"]]["effects"] = effects
    for s in result:
        s["fast"] = [m for m in s["fast"] if m in moves and moves[m]["fast"]]
        s["charged"] = [m for m in s["charged"] if m in moves and not moves[m]["fast"]]
        s["elite"] = [m for m in s["elite"] if m in s["fast"] or m in s["charged"]]
    with open(out_species, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, separators=(",", ":"))
    with open(out_moves, "w", encoding="utf-8") as f:
        json.dump(moves, f, ensure_ascii=False, separators=(",", ":"), sort_keys=True)
    print(f"{len(result)} espèces et {len(moves)} attaques écrites")


if __name__ == "__main__":
    main(*sys.argv[1:7])
