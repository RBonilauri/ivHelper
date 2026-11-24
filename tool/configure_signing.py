#!/usr/bin/env python3
"""Fait signer l'APK de release avec la clé fixe d'ivHelper.

Usage (CI, après `flutter create`) : python3 tool/configure_signing.py

Lit dans l'environnement KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD,
ANDROID_KEY_ALIAS et ANDROID_KEY_PASSWORD (secrets GitHub). Sans KEYSTORE_PATH,
ne change rien : l'APK reste signé avec la clé de débogage.

Modifie android/app/build.gradle.kts généré par Flutter : ajoute une
configuration de signature « release » lue dans l'environnement et la donne au
type de build release. Échoue bruyamment si le fichier n'a pas la forme
attendue, plutôt que de produire un APK mal signé.
"""
import os
import sys

GRADLE = "android/app/build.gradle.kts"
DEBUG_SIGNING = 'signingConfig = signingConfigs.getByName("debug")'
RELEASE_SIGNING = 'signingConfig = signingConfigs.getByName("release")'
SIGNING_BLOCK = """    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH"))
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        }
    }

    buildTypes {"""


def main():
    if not os.environ.get("KEYSTORE_PATH"):
        print("Pas de clé fournie : signature de débogage conservée.")
        return
    for name in ("ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD"):
        if not os.environ.get(name):
            sys.exit(f"{name} manquant alors que KEYSTORE_PATH est fourni")
    if not os.path.exists(GRADLE):
        sys.exit(f"{GRADLE} introuvable")
    text = open(GRADLE, encoding="utf-8").read()
    if text.count(DEBUG_SIGNING) != 1 or text.count("    buildTypes {") != 1:
        sys.exit(f"{GRADLE} n'a pas la forme attendue :\n{text}")
    text = text.replace("    buildTypes {", SIGNING_BLOCK, 1)
    text = text.replace(DEBUG_SIGNING, RELEASE_SIGNING, 1)
    open(GRADLE, "w", encoding="utf-8").write(text)
    print("Signature release configurée.")


if __name__ == "__main__":
    main()
