#!/usr/bin/env bash
# Fill in this template's placeholders. Run this ONCE, first thing after
# cloning or clicking "Use this template". Idempotent: a second run is a no-op.
#
#   ./scripts/init-project.sh                       # interactive prompts
#   ./scripts/init-project.sh my-app my-org         # non-interactive
#   ./scripts/init-project.sh my-app my-org "Does the thing"
#   ./scripts/init-project.sh --ci                  # throwaway values, for CI
#   ./scripts/init-project.sh --check               # exit 1 if not yet initialized
#
# Until this runs, nothing works: `{{PROJECT_SLUG}}` is not a legal Python
# distribution name, so uv refuses to parse pyproject.toml. That is deliberate -
# an un-initialized template should fail loudly, not silently ship a project
# named after its own placeholder.
#
# CI calls this with --ci on a disposable checkout, which is how the template
# repo proves it still produces a green project.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SELF="scripts/init-project.sh" # never rewrite ourselves: it breaks re-runs
SENTINEL='{{PROJECT_SLUG}}'    # its presence in pyproject.toml == uninitialized

# --- --check: used by the Justfile to fail early with a useful message -------
if [ "${1:-}" = "--check" ]; then
  if grep -qF "$SENTINEL" pyproject.toml 2>/dev/null; then
    echo "This is an uninitialized template." >&2
    echo 'Run:  just init <slug> <owner> "<description>"' >&2
    exit 1
  fi
  exit 0
fi

# --- Already initialized? Nothing to do. -------------------------------------
if ! grep -qF "$SENTINEL" pyproject.toml 2>/dev/null; then
  echo "init-project: placeholders already filled in - nothing to do."
  exit 0
fi

# --- Collect values ----------------------------------------------------------
CI_MODE=false
if [ "${1:-}" = "--ci" ]; then
  CI_MODE=true
  shift
fi

SLUG="${1:-}"
OWNER="${2:-}"
DESCRIPTION="${3:-}"

if [ "$CI_MODE" = true ]; then
  SLUG="${SLUG:-template-check}"
  OWNER="${OWNER:-example-org}"
  DESCRIPTION="${DESCRIPTION:-Throwaway project materialized by CI to verify the template.}"
fi

[ -n "$SLUG" ] || read -r -p "Project slug (lowercase, dashes; e.g. my-app): " SLUG
[ -n "$OWNER" ] || read -r -p "GitHub owner (user or org): " OWNER
[ -n "$DESCRIPTION" ] || read -r -p "One-line description: " DESCRIPTION

# --- Validate ----------------------------------------------------------------
# Distribution names are more permissive than Python import names. Restrict the
# slug so replacing `.` / `-` with `_` always creates a valid identifier and so
# normalized names cannot collide through repeated separators.
if ! printf '%s' "$SLUG" | grep -Eq '^[a-z][a-z0-9]*([._-][a-z0-9]+)*$'; then
  echo "error: slug must start with a lowercase letter and use single - . _ separators (got: '$SLUG')" >&2
  exit 1
fi
if ! printf '%s' "$OWNER" | grep -Eq '^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$'; then
  echo "error: owner must look like a GitHub username or org (got: '$OWNER')" >&2
  exit 1
fi
if [ -z "$DESCRIPTION" ]; then
  echo "error: description must not be empty" >&2
  exit 1
fi
if [[ $DESCRIPTION == *"'"* && $DESCRIPTION == *'"'* ]]; then
  echo "error: description must not mix single and double quotes" >&2
  echo "Choose one quote style, then run init again." >&2
  exit 1
fi
if printf '%s' "$DESCRIPTION" | grep -q '[[:cntrl:]]'; then
  echo "error: description must be one line and contain no control characters" >&2
  exit 1
fi
if printf '%s' "$DESCRIPTION" | grep -Eq '\{\{[A-Z_]+\}\}'; then
  echo "error: description must not contain template-style placeholder tokens" >&2
  exit 1
fi

# Refuse an unknown template token before changing any file. pyproject.toml is
# rewritten last below, so the sentinel remains available for a safe rerun if an
# earlier file operation is interrupted.
unknown_placeholders="$(
  grep -rhoIE --exclude-dir=.git --exclude-dir=.venv \
    --exclude-dir=.pytest_cache --exclude-dir=.ruff_cache \
    '\{\{[A-Z_]+\}\}' . 2>/dev/null |
    sort -u |
    grep -vE '^\{\{(PROJECT_NAME|PROJECT_SLUG|PACKAGE_NAME|GITHUB_OWNER|PROJECT_DESCRIPTION|PROJECT_DESCRIPTION_ESCAPED)\}\}$' || true
)"
if [ -n "$unknown_placeholders" ]; then
  echo "error: unknown template placeholder(s):" >&2
  printf '%s\n' "$unknown_placeholders" | sed 's/^/  /' >&2
  exit 1
fi

# The same human text lands in TOML and a Python triple-quoted docstring. Escape
# the two characters meaningful in both contexts; Markdown receives the raw text.
DESCRIPTION_ESCAPED="${DESCRIPTION//\\/\\\\}"
DESCRIPTION_ESCAPED="${DESCRIPTION_ESCAPED//\"/\\\"}"

# Derived: import name (underscores) and human title (Title Case).
PACKAGE="${SLUG//[.-]/_}"
case "$PACKAGE" in
and | as | assert | async | await | break | class | continue | def | del | elif | else | except | finally | for | from | global | if | import | in | is | lambda | nonlocal | not | or | pass | raise | return | try | while | with | yield)
  echo "error: slug produces Python keyword import name '$PACKAGE'" >&2
  exit 1
  ;;
esac
TITLE="$(printf '%s' "$SLUG" | tr '._-' '   ' |
  awk '{for (i = 1; i <= NF; i++) $i = toupper(substr($i, 1, 1)) substr($i, 2)} 1')"

echo "Initializing:"
echo "  title        : $TITLE"
echo "  slug         : $SLUG"
echo "  import name  : $PACKAGE"
echo "  owner        : $OWNER"
echo "  description  : $DESCRIPTION"

# --- Rename placeholder paths before rewriting contents ----------------------
PLACEHOLDER_PKG="src/{{PACKAGE_NAME}}"
if [ -d "$PLACEHOLDER_PKG" ]; then
  mv "$PLACEHOLDER_PKG" "src/$PACKAGE"
  echo "  renamed      : $PLACEHOLDER_PKG -> src/$PACKAGE"
fi

# --- Rewrite contents --------------------------------------------------------
# Text files only, skipping VCS internals, virtualenvs, and tool caches.
changed=0
rewrite_file() {
  local file="$1"
  # grep -I skips binary files; `-q .` means "has at least one line".
  grep -Iq . "$file" 2>/dev/null || return 0
  grep -qF '{{' "$file" 2>/dev/null || return 0
  TITLE="$TITLE" SLUG="$SLUG" PACKAGE="$PACKAGE" OWNER="$OWNER" \
    DESCRIPTION="$DESCRIPTION" DESCRIPTION_ESCAPED="$DESCRIPTION_ESCAPED" \
    perl -pi -e '
      s/\{\{PROJECT_NAME\}\}/$ENV{TITLE}/g;
      s/\{\{PROJECT_SLUG\}\}/$ENV{SLUG}/g;
      s/\{\{PACKAGE_NAME\}\}/$ENV{PACKAGE}/g;
      s/\{\{GITHUB_OWNER\}\}/$ENV{OWNER}/g;
      s/\{\{PROJECT_DESCRIPTION_ESCAPED\}\}/$ENV{DESCRIPTION_ESCAPED}/g;
      s/\{\{PROJECT_DESCRIPTION\}\}/$ENV{DESCRIPTION}/g;
    ' "$file"
  changed=$((changed + 1))
}

while IFS= read -r -d '' f; do
  rel="${f#./}"
  [ "$rel" != "$SELF" ] || continue
  [ "$rel" != "pyproject.toml" ] || continue
  rewrite_file "$f"
done < <(
  find . \
    \( -path './.git' -o -path './.venv' -o -name '__pycache__' \
    -o -name '.pytest_cache' -o -name '.ruff_cache' -o -name '.mypy_cache' \) -prune \
    -o -type f -print0
)
# Keep the sentinel intact until every other rewrite succeeds. If the process is
# interrupted before this point, rerunning with the same values safely resumes.
rewrite_file ./pyproject.toml
echo "  rewrote      : $changed file(s)"

# --- Verify nothing was missed ----------------------------------------------
missed="$(grep -rIlE --exclude-dir=.git --exclude-dir=.venv \
  --exclude="$(basename "$SELF")" '\{\{[A-Z_]+\}\}' . 2>/dev/null || true)"
if [ -n "$missed" ]; then
  echo "error: unfilled placeholders remain in:" >&2
  printf '%s\n' "$missed" | sed 's/^/  /' >&2
  exit 1
fi

cat <<EOF

Done. Next steps:
  1. just install                             # deps + git hooks
  2. just ci                                  # lint + types + tests + package artifacts
  3. Add a LICENSE, then set license/license-files in pyproject.toml
  4. ./scripts/setup-repo.sh $OWNER/$SLUG      # labels, security, protection
  5. Replace the placeholder module in src/$PACKAGE/ and the smoke tests

Keep this script: CI re-runs it on a throwaway checkout to prove the template
still produces a green project. It no-ops once initialized.
EOF
