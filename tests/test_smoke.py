"""Smoke tests: proof the package imports and the toolchain is wired up.

Delete these once the real code has its own tests.
"""

import {{PACKAGE_NAME}}


def test_package_imports() -> None:
    assert {{PACKAGE_NAME}}.__doc__ is not None


def test_version_is_a_string() -> None:
    assert isinstance({{PACKAGE_NAME}}.__version__, str)
    assert {{PACKAGE_NAME}}.__version__
