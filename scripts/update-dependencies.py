#!/usr/bin/env python3
"""Upgrade the lock and rewrite exact direct requirements to resolved versions."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import tomllib
from pathlib import Path
from typing import Any, cast

PYPROJECT = Path("pyproject.toml")
LOCKFILE = Path("uv.lock")
EXACT_REQUIREMENT = re.compile(
    r"^(?P<prefix>(?P<name>[A-Za-z0-9][A-Za-z0-9._-]*)"
    r"(?:\[[^]]+\])?)\s*==\s*(?P<version>[^;\s]+)(?P<suffix>\s*(?:;.*)?)$"
)
INDEX_ENVIRONMENT = (
    "UV_INDEX",
    "UV_INDEX_URL",
    "UV_DEFAULT_INDEX",
    "UV_EXTRA_INDEX_URL",
    "PIP_INDEX_URL",
    "PIP_EXTRA_INDEX_URL",
)


def normalize_name(name: str) -> str:
    return re.sub(r"[-_.]+", "-", name).lower()


def direct_requirements(document: dict[str, Any]) -> list[str]:
    """Collect requirements declared directly by project metadata and groups."""
    requirements: list[str] = []
    project = cast(dict[str, Any], document.get("project", {}))
    requirements.extend(cast(list[str], project.get("dependencies", [])))
    optional = cast(dict[str, list[str]], project.get("optional-dependencies", {}))
    for group in optional.values():
        requirements.extend(group)

    dependency_groups = cast(dict[str, list[Any]], document.get("dependency-groups", {}))
    for group in dependency_groups.values():
        requirements.extend(item for item in group if isinstance(item, str))

    build_system = cast(dict[str, Any], document.get("build-system", {}))
    requirements.extend(cast(list[str], build_system.get("requires", [])))
    return requirements


def replace_toml_requirement(text: str, old: str, new: str) -> str:
    """Replace a TOML string without reformatting the surrounding document."""
    old_literal = f'"{old}"'
    if old_literal not in text:
        raise ValueError(f"cannot safely locate exact requirement in pyproject.toml: {old}")
    return text.replace(old_literal, f'"{new}"')


def clean_environment() -> dict[str, str]:
    environment = os.environ.copy()
    for name in INDEX_ENVIRONMENT:
        environment.pop(name, None)
    return environment


def run_uv_lock(*arguments: str) -> None:
    executable = shutil.which("uv")
    if executable is None:
        raise RuntimeError("uv is not installed or is not on PATH")
    # Arguments are fixed by this repository, not supplied by an untrusted caller.
    subprocess.run(  # noqa: S603 - execute the resolved uv binary without a shell
        [executable, "lock", *arguments], check=True, env=clean_environment()
    )


def locked_versions() -> dict[str, set[str]]:
    document = tomllib.loads(LOCKFILE.read_text(encoding="utf-8"))
    versions: dict[str, set[str]] = {}
    for package in cast(list[dict[str, Any]], document["package"]):
        version = package.get("version")
        if isinstance(version, str):
            versions.setdefault(normalize_name(str(package["name"])), set()).add(version)
    return versions


def main() -> int:
    original_pyproject = PYPROJECT.read_text(encoding="utf-8")
    original_lock = LOCKFILE.read_bytes()
    document = tomllib.loads(original_pyproject)

    exact: dict[str, re.Match[str]] = {}
    for requirement in direct_requirements(document):
        match = EXACT_REQUIREMENT.fullmatch(requirement)
        if match:
            exact[requirement] = match
        elif "==" in requirement:
            raise ValueError(
                f"unsupported exact requirement; update it with `just add` instead: {requirement}"
            )

    try:
        unlocked = original_pyproject
        for requirement, match in exact.items():
            bare = f"{match['prefix']}{match['suffix']}"
            unlocked = replace_toml_requirement(unlocked, requirement, bare)
        PYPROJECT.write_text(unlocked, encoding="utf-8")

        run_uv_lock("--upgrade")
        resolved = locked_versions()

        updated = original_pyproject
        changes: list[tuple[str, str, str]] = []
        for requirement, match in exact.items():
            name = normalize_name(match["name"])
            candidates = resolved.get(name, set())
            if len(candidates) != 1:
                versions = ", ".join(sorted(candidates)) or "none"
                raise RuntimeError(
                    f"cannot choose one resolved version for {match['name']}: {versions}"
                )
            version = next(iter(candidates))
            replacement = f"{match['prefix']}=={version}{match['suffix']}"
            updated = replace_toml_requirement(updated, requirement, replacement)
            if match["version"] != version:
                changes.append((match["name"], match["version"], version))

        PYPROJECT.write_text(updated, encoding="utf-8")
        run_uv_lock()
    except BaseException:
        PYPROJECT.write_text(original_pyproject, encoding="utf-8")
        LOCKFILE.write_bytes(original_lock)
        raise

    if changes:
        print("Updated exact direct requirements:")
        for name, before, after in changes:
            print(f"  {name}: {before} -> {after}")
    else:
        print("Exact direct requirements are already current within project policy.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
