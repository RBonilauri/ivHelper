# ivHelper

App Flutter qui donne le rang PvP d'un Pokémon de Pokémon GO en ligue super (1500 PC) et hyper (2500 PC) : on saisit le Pokémon (nom ou numéro) et ses trois IV, l'app classe la combinaison parmi les 4096 possibles.

## Utilisation

- Saisir le nom français ou le numéro du Pokédex (des suggestions apparaissent si le nom est incomplet).
- Régler les IV d'attaque, de défense et de PV avec les boutons moins et plus.
- Choisir le niveau maximal : 50, ou 51 (niveau 50 plus bonus meilleur ami).
- Deux volets, Super et Hyper : rang en gros, puis un tableau avec la ligne du Pokémon saisi en vert et le haut du classement. Un appui sur une ligne affiche ses stats réelles (Atk, Déf, PV, stat globale) ; l'interrupteur Détails déplie toutes les lignes.

Pas de superposition ni de lecture d'écran pour l'instant : ils viendront dans une phase suivante (voir `docs/superpowers/plans/2026-11-24-ivhelper.md`).

## Installer sur Android

Chaque envoi sur GitHub lance la CI (`.github/workflows/ci.yml`) : analyse, tests, puis compilation d'un APK. Ouvrir l'exécution la plus récente dans l'onglet Actions du dépôt, télécharger l'artefact `ivhelper-apk`, le décompresser et installer `app-release.apk` sur le téléphone (autoriser les sources inconnues).

## Développement

Les tests tournent avec `flutter test`. Le bac à sable de développement ne contient pas Flutter : la CI fait foi. `tool/ci_wait.sh` attend le résultat de la CI pour le commit courant (nécessite `gh`).

Les données des espèces sont générées par `tool/build_species.py` ; sources et licences dans `docs/data-sources.md`.

## Documents

- Design : `docs/superpowers/specs/2026-11-24-pvp-rank-overlay-design.md`
- Plan : `docs/superpowers/plans/2026-11-24-ivhelper.md`
