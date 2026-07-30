"""Smoke test executed against built wheel and source distributions."""

from importlib import import_module, metadata
from pathlib import Path

DISTRIBUTION = "{{PROJECT_SLUG}}"
PACKAGE = "{{PACKAGE_NAME}}"


def main() -> None:
    module = import_module(PACKAGE)
    module_path = Path(str(module.__file__)).resolve()
    source_root = (Path(__file__).parents[1] / "src").resolve()

    if module_path.is_relative_to(source_root):
        raise RuntimeError(f"import resolved to source checkout: {module_path}")
    if not module_path.with_name("py.typed").is_file():
        raise RuntimeError("built package is missing its py.typed marker")
    if module.__version__ != metadata.version(DISTRIBUTION):
        raise RuntimeError("module and distribution versions differ")


if __name__ == "__main__":
    main()
