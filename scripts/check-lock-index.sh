#!/usr/bin/env bash
# Fail if uv.lock resolves registry packages from a non-public Python index.
#
# Why this exists: uv honors ambient index variables ahead of the index pinned
# in pyproject.toml. A contributor with a corporate mirror can otherwise re-lock
# the project to a host that GitHub-hosted runners cannot reach.
#
# Inspect only `registry =` sources. Direct URL and Git dependencies are explicit
# project choices and must remain usable; the old all-URL scan rejected both.
set -euo pipefail

LOCKFILE="${1:-uv.lock}"
ALLOWED_HOSTS='pypi\.org|files\.pythonhosted\.org'

[ -f "$LOCKFILE" ] || exit 0

bad="$(grep -oE 'registry = "https://[a-zA-Z0-9.-]+' "$LOCKFILE" |
  sed -E 's|registry = "https://||' | sort -u |
  grep -vE "^($ALLOWED_HOSTS)$" || true)"

if [ -n "$bad" ]; then
  echo "error: $LOCKFILE references non-public package registry host(s):" >&2
  printf '%s\n' "$bad" >&2
  cat >&2 <<'EOF'

CI cannot reach these. Re-lock against the public index:

  just lock

Then remove the ambient index override from your shell profile. If this project
intentionally uses a private registry, update this script's allowlist and CI.
EOF
  exit 1
fi
