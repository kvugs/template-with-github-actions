#!/usr/bin/env bash
# Give actionlint a stable ShellCheck executable. Its Go pre-commit environment
# cannot see the separate ShellCheck hook environment, while Ubuntu runners have
# a system copy; without this wrapper local and CI checks silently differ.
set -euo pipefail

exec uv run --locked shellcheck "$@"
