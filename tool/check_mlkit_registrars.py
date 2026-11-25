#!/usr/bin/env python3
"""Vérifie qu'un APK garde le constructeur des « registrars » de ML Kit.

ML Kit crée ses composants en instanciant par réflexion les classes listées
dans le manifeste (MlKitComponentDiscoveryService). Si R8 retire leur
constructeur sans argument, ML Kit démarre sans composants et la lecture du
texte plante (NullPointerException dans TextRecognition.getClient).

Usage : dexdump -l plain classes*.dex | check_mlkit_registrars.py
"""
import re
import sys

REGISTRARS = [
    "Lcom/google/mlkit/common/internal/CommonComponentRegistrar;",
    "Lcom/google/mlkit/vision/common/internal/VisionCommonRegistrar;",
    "Lcom/google/mlkit/vision/text/internal/TextRegistrar;",
]


def constructors(dump):
    """Classe → vrai si elle a un constructeur sans argument."""
    found = {}
    current = None
    method = None
    for line in dump.splitlines():
        m = re.search(r"Class descriptor\s*:\s*'([^']+)'", line)
        if m:
            current = m.group(1)
            found.setdefault(current, False)
            continue
        m = re.search(r"name\s*:\s*'([^']+)'", line)
        if m:
            method = m.group(1)
            continue
        m = re.search(r"type\s*:\s*'([^']+)'", line)
        if m and current and method == "<init>" and m.group(1) == "()V":
            found[current] = True
            method = None
    return found


def main():
    found = constructors(sys.stdin.read())
    missing = [r for r in REGISTRARS if not found.get(r)]
    for r in REGISTRARS:
        state = "absente" if r not in found else ("ok" if found[r] else "SANS constructeur")
        print(f"{r} : {state}")
    if missing:
        print("ML Kit ne pourra pas créer ses composants : règles R8 à corriger.")
        sys.exit(1)


if __name__ == "__main__":
    main()
