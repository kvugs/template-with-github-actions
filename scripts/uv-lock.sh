#!/usr/bin/env bash
# Keep uv.lock in step with pyproject.toml, always resolved against the index
# pinned in pyproject.toml.
#
# This exists instead of the upstream astral-sh/uv-pre-commit `uv-lock` hook
# because that hook inherits UV_INDEX_URL / UV_DEFAULT_INDEX from the developer's
# shell. On a machine that exports a corporate mirror, it rewrites every URL in
# the lockfile to a host GitHub-hosted runners cannot reach. Stripping those
# variables makes the lockfile a property of the project, not of whoever ran it.
#
# Same behaviour as `just lock`.
set -euo pipefail

exec env \
  -u UV_INDEX \
  -u UV_INDEX_URL \
  -u UV_DEFAULT_INDEX \
  -u UV_EXTRA_INDEX_URL \
  -u PIP_INDEX_URL \
  -u PIP_EXTRA_INDEX_URL \
  uv lock
