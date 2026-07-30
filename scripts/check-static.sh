#!/usr/bin/env bash
# Run every non-mutating pre-commit check that required CI enforces server-side.
# Formatting hooks stay local because they rewrite files; Ruff checks formatting
# separately without changing the working tree.
set -euo pipefail

hooks=(
  check-merge-conflict
  check-added-large-files
  check-case-conflict
  check-illegal-windows-names
  check-symlinks
  destroyed-symlinks
  check-yaml
  check-toml
  check-json
  detect-private-key
  check-executables-have-shebangs
  check-shebang-scripts-are-executable
  check-ast
  actionlint
  check-github-workflows
  check-github-actions
  check-github-issue-config
  check-github-issue-forms
  check-dependabot
  shellcheck
  typos
  markdownlint-cli2
  zizmor
)
manual_hooks=(
  # The normal Gitleaks hook is deliberately staged-only. This alias negates
  # those flags and scans the Git tree checked out by required CI.
  gitleaks-full
)
omitted_hooks=(
  # Mutating hooks: local convenience, while CI uses read-only equivalents.
  ruff-check
  ruff-format
  uv-lock
  end-of-file-fixer
  trailing-whitespace
  mixed-line-ending
  shfmt
  # Context-specific hooks that do not describe files in a clean CI checkout.
  gitleaks
  no-commit-to-branch
  commitizen
  # External availability is advisory and runs in informational.yml.
  lychee
  # Enforced directly by `just lint` and ci.yml before this script.
  lockfile-public-index
)

# A new hook must be classified above. This turns the old silent local-only gap
# into a loud required-check failure.
uv run --locked python scripts/check-hook-coverage.py \
  --enforced "${hooks[@]}" "${manual_hooks[@]}" \
  --omitted "${omitted_hooks[@]}"

# `set -e` intentionally reports the first failing hook. Run `just hooks` for a
# complete local report across both mutating and non-mutating hooks.
for hook in "${manual_hooks[@]}"; do
  uv run --locked pre-commit run "$hook" --hook-stage manual --all-files
done
for hook in "${hooks[@]}"; do
  uv run --locked pre-commit run "$hook" --all-files
done
