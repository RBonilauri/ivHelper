#!/usr/bin/env bash
# Attend le résultat de la CI GitHub pour le commit courant.
# Sortie 0 si vert, 1 si rouge (avec la fin du journal), 2 si délai dépassé.
set -uo pipefail
repo="RBonilauri/ivhelper"
sha="$(git rev-parse HEAD)"
for _ in $(seq 1 90); do
  line="$(gh api "repos/$repo/actions/runs?head_sha=$sha&per_page=1" \
    --jq '.workflow_runs[0] | "\(.id) \(.status) \(.conclusion)"' 2>/dev/null || true)"
  id="${line%% *}"
  rest="${line#* }"
  case "$rest" in
    "completed success")
      echo "CI verte pour $sha (run $id)"
      exit 0
      ;;
    completed*)
      echo "CI rouge pour $sha (run $id) : $rest"
      gh run view "$id" -R "$repo" --log-failed 2>&1 | tail -60
      exit 1
      ;;
  esac
  sleep 10
done
echo "Délai dépassé pour $sha"
exit 2
