# Agent instructions

Notes for AI coding agents working in this repository.
`AGENTS.md` is the cross-tool convention; Claude Code, Cursor, and others read it.
Humans should read [CONTRIBUTING.md](CONTRIBUTING.md) instead - this file only
adds what an agent cannot infer from the code.

## Before anything else

If `pyproject.toml` still contains `{{PROJECT_SLUG}}`, first determine which mode
you are in:

- **Creating a project from the template:** run
  `just init <slug> <owner> "<description>"` before project work.
- **Maintaining this template repository:** never initialize the working tree.
  Keep the placeholders and validate a disposable materialization with
  `just template-ci`.

## Commands

Read the [Justfile](Justfile) file as it lists all current available commands.
Add or update commands as needed for human contributors to leverage development.

Always run `just ci` before claiming generated-project work is done. When the
working tree is the template source, run `just template-ci` instead; it creates
a disposable initialized copy and runs `just ci` plus the hook checks there.

## Conventions

- **Ruff is the Python style authority.** shfmt owns shell formatting and
  Markdownlint owns Markdown structure. Do not hand-format, do not add `# noqa`
  without a reason on the same line, and do not argue with formatters. Run
  `just format` for Python and `just hooks` for all file types.
- **Types are a required gate.** `basedpyright` runs in `strict` mode. New
  public functions get annotations.
- **`src/` layout.** The package lives in `src/{{PACKAGE_NAME}}/`; tests import
  it as an installed package, never by relative path.
- **Tests marked `external`** (integration, network, model calls) are excluded
  from the required gate. Mark anything whose result something outside this
  repository can change. Slowness alone is not a reason to mark a test.
- **Warnings are errors** in pytest. If a dependency warns, fix the call or
  allowlist that one warning in `pyproject.toml` with a comment.
- **Never edit `uv.lock` by hand.** Change `pyproject.toml` and run `just lock`.
- **Use Conventional Commits.** Commitizen checks `<type>: <description>` (or
  `<type>(<scope>): <description>`) at `commit-msg`. The PR title uses the same
  shape because it becomes the squash commit on `main`.
- **Do not commit to `main`.** Branch, open a PR, squash-merge. A pre-commit
  hook enforces this locally.
- **Every PR references an existing issue.** Put `Closes #123` in the PR
  description, or `Refs #123` if it does not finish the issue. If none exists,
  open one before opening the PR. Only typo/formatting fixes are exempt, and
  they say `No issue: <reason>` instead. An advisory `issue-link` check reports
  when this is missing.
- **Issues are atomic; umbrella issues are the one exception.** An issue is an
  indivisible unit that either completes or does not happen at all. When a goal
  is too large for that, open an umbrella issue with the `umbrella` template:
  its **title must start with ☂️**, it carries the goal and the reasoning, and
  the work lives in atomic sub-issues linked from its checklist. Never close an
  umbrella with a single PR - land its children separately and let it close when
  the last one merges. The `umbrella-marker` job in
  `.github/workflows/issue-hygiene.yml` keeps the ☂️ prefix and the `umbrella`
  label in step, so setting either one is enough.
- **One problem per PR.** If an honest PR title needs an "and", split it into
  two PRs. Do not bundle a refactor, rename, or reformat with a behavior change:
  it hides the behavior change in diff noise, which is where a bug survives
  review. Split before you start, because untangling a branch later means rebase
  surgery. A large mechanical diff is fine when it is genuinely all-or-nothing,
  but say so in the description and say how to verify it.

## Where things are

| Path | What |
|---|---|
| `docs/decisions.md` | Lightweight decision log. Add ~10 lines for any non-obvious call. |
| `docs/adr/` | Architecture decision records, for decisions that reshape the system. |

## When you make a non-obvious call

Add an entry to [docs/decisions.md](docs/decisions.md) in the same PR. This is
the highest-value habit in the repo: it is what stops someone re-deriving your
reasoning.
