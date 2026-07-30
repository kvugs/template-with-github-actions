"""{{PROJECT_NAME}}.

{{PROJECT_DESCRIPTION_ESCAPED}}

This module is a placeholder so the toolchain (Ruff, basedpyright, pytest) has
something real to run against on day one. Replace it as the project lands.
"""

from importlib.metadata import PackageNotFoundError, version

try:
    # Single source of truth: the version declared in pyproject.toml.
    __version__ = version("{{PROJECT_SLUG}}")
except PackageNotFoundError:  # pragma: no cover - running from a source tree
    __version__ = "0.0.0"

__all__ = ["__version__"]
