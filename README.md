# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

[![CI](https://github.com/{{GITHUB_OWNER}}/{{PROJECT_SLUG}}/actions/workflows/ci.yml/badge.svg)](https://github.com/{{GITHUB_OWNER}}/{{PROJECT_SLUG}}/actions/workflows/ci.yml)
[![Python](https://img.shields.io/badge/python-3.14%2B-blue)](https://www.python.org/downloads/)
[![uv](https://img.shields.io/badge/deps-uv-261230)](https://docs.astral.sh/uv/)
[![Ruff](https://img.shields.io/badge/style-ruff-D7FF64)](https://docs.astral.sh/ruff/)

> **Status:** early scaffold. The `src/{{PACKAGE_NAME}}` package is a placeholder
> so the toolchain runs; the real work is being built issue-by-issue.

## Setting up (from the template)

Prerequisites are [Git](https://git-scm.com/),
[uv](https://docs.astral.sh/uv/getting-started/installation/), and
[Just](https://just.systems/man/en/packages.html). uv installs the requested
Python version automatically when needed.

If you just created this repository from the template, run this **first**:

```bash
just init                                        # fills in every placeholder value in interactive mode
just install                                     # deps + git hooks
just ci                                          # lint + types + tests + package smoke test
```

Nothing works before `just init`, on purpose: the placeholder project name is
not a legal Python distribution name, so `uv` refuses to parse
`pyproject.toml` rather than let a project ship named after its own template.

Then, once: choose a `LICENSE` and set `license` / `license-files` in
`pyproject.toml`, then run `./scripts/setup-repo.sh my-org/my-app` to apply the
small label set, merge settings, security features, and solo-compatible branch
protection. When reliable reviewers join, raise the required review count in
`.github/rulesets/main.json`.

## For contributors

New here? Read **[CONTRIBUTING.md](CONTRIBUTING.md)** - it's a one-pager. The
60-second version:

```bash
just install                # once: locked deps + git hooks
just ci                     # before pushing: lint + types + fast tests + built artifacts
```

Pick an issue, use a Conventional Commit message such as `feat: add export`,
open a focused PR with the same title shape, and squash-merge once required CI
is green. Ask for review when a friend is available; the default rules
intentionally keep solo projects operable without a second account.

Run `just` with no arguments to list every recipe. The
[`Justfile`](Justfile) documents when each one is meant to be run. Use
`just links` for the advisory external-link check.

When maintaining the template repository itself, keep placeholders intact and
run `just template-ci`; it materializes and verifies a disposable copy.

## Important reference files and folders

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - how to set up and open PRs.
- **[AGENTS.md](AGENTS.md)** - rules written by humans for AI coding agents.
- **[SECURITY.md](SECURITY.md)** - how to report a vulnerability privately.
- **[docs/decisions.md](docs/decisions.md)** - the lightweight decision log.
- **[docs/adr/](docs/adr/)** - architecture decision records (the heavier, numbered decisions).
