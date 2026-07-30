#!/usr/bin/env python3
"""Ensure every configured pre-commit hook has an explicit CI policy."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
from typing import Any, cast

import yaml


def configured_hook_names(config_path: Path) -> list[str]:
    """Return hook aliases, falling back to IDs when no alias is configured."""
    document = cast(dict[str, Any], yaml.safe_load(config_path.read_text(encoding="utf-8")))
    repositories = cast(list[dict[str, Any]], document["repos"])
    names: list[str] = []
    for repository in repositories:
        hooks = cast(list[dict[str, Any]], repository["hooks"])
        names.extend(str(hook.get("alias", hook["id"])) for hook in hooks)
    return names


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--enforced", nargs="+", required=True)
    parser.add_argument("--omitted", nargs="+", required=True)
    args = parser.parse_args()

    configured = configured_hook_names(Path(".pre-commit-config.yaml"))
    duplicates = sorted(name for name, count in Counter(configured).items() if count > 1)
    enforced = set(cast(list[str], args.enforced))
    omitted = set(cast(list[str], args.omitted))
    classified = enforced | omitted

    errors: list[str] = []
    if duplicates:
        errors.append(f"configured hook names are not unique: {', '.join(duplicates)}")
    overlap = sorted(enforced & omitted)
    if overlap:
        errors.append(f"hooks are both enforced and omitted: {', '.join(overlap)}")
    missing = sorted(set(configured) - classified)
    if missing:
        errors.append(f"hooks have no CI policy: {', '.join(missing)}")
    stale = sorted(classified - set(configured))
    if stale:
        errors.append(f"policy lists hooks not in config: {', '.join(stale)}")

    if errors:
        for error in errors:
            print(f"error: {error}")
        return 1

    print(f"All {len(configured)} pre-commit hooks have an explicit CI policy.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
