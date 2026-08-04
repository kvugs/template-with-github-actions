#!/usr/bin/env bash
# Verify this template without ever replacing placeholders in the source tree.
# Generated repositories no-op here; only the template source has the sentinel.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if "$REPO_ROOT/scripts/init-project.sh" --check >/dev/null 2>&1; then
  echo "template-ci: initialized project - template-only checks do not apply."
  exit 0
fi

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/template-check.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

# tar is available anywhere this Bash-based template runs; unlike git archive,
# it also works before the template repository has its first commit.
(
  cd "$REPO_ROOT"
  COPYFILE_DISABLE=1 tar \
    --exclude='./.git' \
    --exclude='./.venv' \
    --exclude='./.DS_Store' \
    --exclude='./.pytest_cache' \
    --exclude='./.ruff_cache' \
    --exclude='./__pycache__' \
    -cf - .
) | tar -xf - -C "$TMP_ROOT"

cd "$TMP_ROOT"
git init -q --initial-branch=audit
git add -A
git -c user.name=Template -c user.email=template@example.invalid \
  commit -qm 'chore: capture template source'

# Ambiguous quote delimiters fail before the script mutates anything.
if ./scripts/init-project.sh quote-test example-org \
  'A "double" and a '\''single'\'' quoted description' >init-error.txt 2>&1; then
  echo "error: init accepted a description mixing quote styles" >&2
  exit 1
fi
grep -qF 'description must not mix single and double quotes' init-error.txt
rm init-error.txt

if ./scripts/init-project.sh quote-test 'invalid--owner-' 'Valid description' \
  >init-error.txt 2>&1; then
  echo "error: init accepted an invalid GitHub owner" >&2
  exit 1
fi
grep -qF 'owner must look like a GitHub username or org' init-error.txt
rm init-error.txt

printf '{{%s}}\n' UNKNOWN_TEMPLATE_TOKEN >unknown-placeholder.txt
if ./scripts/init-project.sh quote-test example-org 'Valid description' \
  >init-error.txt 2>&1; then
  echo "error: init accepted an unknown template placeholder" >&2
  exit 1
fi
grep -qF 'unknown template placeholder' init-error.txt
grep -qF '{{PROJECT_SLUG}}' pyproject.toml
[ -d 'src/{{PACKAGE_NAME}}' ]
rm init-error.txt unknown-placeholder.txt

# A single quote style is escaped for TOML and Python while remaining natural
# prose in Markdown.
./scripts/init-project.sh quote-test example-org 'A "quoted" tool'
git add -A
git -c user.name=Template -c user.email=template@example.invalid \
  commit -qm 'chore: initialize disposable project'

just install
[ -x .git/hooks/pre-commit ]
[ -x .git/hooks/commit-msg ]
just ci
just hooks

message_file="$(mktemp "${TMPDIR:-/tmp}/commit-message.XXXXXX")"
trap 'rm -rf "$TMP_ROOT" "$message_file"' EXIT
printf '%s\n' 'chore: verify commit message hook' >"$message_file"
uv run --locked pre-commit run commitizen --hook-stage commit-msg \
  --commit-msg-filename "$message_file"
printf '%s\n' 'not a conventional commit' >"$message_file"
if uv run --locked pre-commit run commitizen --hook-stage commit-msg \
  --commit-msg-filename "$message_file" >commitizen-error.txt 2>&1; then
  echo "error: commitizen accepted a non-Conventional Commit message" >&2
  exit 1
fi
rm commitizen-error.txt

echo "template-ci: disposable initialized project is green."
