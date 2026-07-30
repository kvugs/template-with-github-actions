#!/usr/bin/env bash
# Build both distribution formats and import each from a clean environment.
# Editable installs can hide omitted package data and broken build configuration;
# this checks the artifacts users would actually install.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/package-check.XXXXXX")"
DIST_DIR="$TMP_ROOT/dist"
trap 'rm -rf "$TMP_ROOT"' EXIT
cd "$REPO_ROOT"

clean_uv() {
  env \
    -u UV_INDEX \
    -u UV_INDEX_URL \
    -u UV_DEFAULT_INDEX \
    -u UV_EXTRA_INDEX_URL \
    -u PIP_INDEX_URL \
    -u PIP_EXTRA_INDEX_URL \
    uv "$@"
}

clean_uv build --out-dir "$DIST_DIR"

shopt -s nullglob
wheels=("$DIST_DIR"/*.whl)
sdists=("$DIST_DIR"/*.tar.gz)
if [ "${#wheels[@]}" -ne 1 ] || [ "${#sdists[@]}" -ne 1 ]; then
  echo "error: expected exactly one wheel and one source distribution" >&2
  exit 1
fi

for artifact in "${wheels[0]}" "${sdists[0]}"; do
  echo "Smoke testing $(basename "$artifact")"
  clean_uv run --isolated --no-project --with "$artifact" python "$REPO_ROOT/tests/package_smoke.py"
done
