# Contributing

How to contribute to this project.

## Setup

Install [Git](https://git-scm.com/),
[uv](https://docs.astral.sh/uv/getting-started/installation/), and
[Just](https://just.systems/man/en/packages.html). uv installs the project's
requested Python version automatically.

```bash
just install                                     # locked deps + git hooks
just ci                                          # the complete required gate
```

Create a branch before changing files. Direct pushes to `main` are blocked
locally and by the repository ruleset.

## Daily workflow

| Moment | Command |
| --- | --- |
| While coding | `just test`, `just types`, `just format` |
| Before pushing or opening a PR | `just ci` |
| Adding or bumping a dependency | `just add <pkg>`, `just add-dev <tool>`, or `just update`; then `just ci` and `just audit` |
| Before a release | `just test-all`, `just package`, `just audit` |

`just` with no arguments lists every recipe.

## Quality gates

`just ci` runs non-mutating checks for Ruff, workflow/config/security hygiene,
basedpyright, fast tests, and installable wheel/sdist artifacts. CI runs the same
checks. `just hooks` additionally runs the mutating hygiene hooks over every file;
run it after changing `.pre-commit-config.yaml` or bypassing a hook. It is not part
of `just ci` because a check that rewrites what it checks cannot gate a merge.

Tests marked `external`, coverage, dependency auditing, external-link checking, Trivy, CodeQL, and the `issue-link` PR check are advisory.
A red advisory check should still be understood; it is non-blocking so a flaky service does not lock the repository, not because failures are unimportant.

Most of those checks also run nightly against `main`, because they depend on things no commit here controls: an upstream API changes shape, or a new advisory lands against a dependency that was already locked.
Pull requests cannot catch that, since they only run when someone pushes.
A failed nightly run opens or comments on one tracking issue, and the next green run closes it again.
While that issue is open, treat it as real work: it is the only thing keeping an advisory check from being ignored indefinitely.

Warnings are pytest errors.
Mark a test `external` when something outside this repository can change its result - a network call, a live service, a model.
That is the line the required gate draws, so a slow but self-contained test stays in the gate rather than being marked.
Use `just links` to run the advisory Markdown link check locally. Use
`git commit --no-verify` only for an emergency and explain why in the PR.

## Issues

Pick the form that fits - bug, feature, documentation, or umbrella - and two things are asked for every time:

- **Numbered steps.** Write the path to the problem as `1.`, `2.`, `3.`, starting from a clean state, so a reader can follow it and land where you did.
  Required on bug reports.
  If it is not reproducible on demand, say so and describe what you were doing when it appeared; that is useful information, not a gap.
- **Something visual.** Drag a screenshot, screen recording, mockup, or diagram straight into the form.
  A picture of the broken state, or a sketch of the flow you have in mind, routinely saves a round of back-and-forth.

Blank issues stay enabled for reports that fit no form.
The same two expectations apply there - the form is a reminder, not the reason.

### Keep an issue atomic

Aim for one atomic issue per piece of work: an indivisible unit that either completes or does not happen at all, with no half-applied state in between.
The test is to try splitting it: If both halves stand on their own and each one solves something a person would care about, it was two issues. If one half is a fragment nobody could close or verify by itself, it is genuinely one.

The single exception is an umbrella issue, and it is a deliberate one.

### Umbrella issues

An umbrella carries a goal too large for one issue: the finished state, the reasoning behind it, and a checklist.
It is the one issue in the repository that is **not** atomic, and the trade is that every sub-issue under it has to be.
A child that cannot be closed and verified on its own is a fragment; merge it into a sibling rather than list it.

**The title always starts with ☂️.** That is the marker, and it makes umbrellas legible in a list where everything else is a unit of work.
The [umbrella form](.github/ISSUE_TEMPLATE/umbrella.yml) pre-fills it, and the `umbrella` label is applied with it.

The two markers are kept in step by the `umbrella-marker` job in [`.github/workflows/issue-hygiene.yml`](.github/workflows/issue-hygiene.yml), so neither is a rule anyone has to remember.
Whichever side you edited last wins: put ☂️ in the title of an existing issue and the label appears, remove the label and the ☂️ goes with it.
Searching `☂️` in the title and filtering on `label:umbrella` therefore return the same set.

- **Link the children both ways.** Use GitHub sub-issues, or a task list in the umbrella body, so the tree is navigable from either end.
- **Put the reasoning in the umbrella, not the children.** The "why now" is the part a reader cannot reconstruct from a checklist, and it is most of what the umbrella is for.
- **Name what is out of scope.** One line about the neighboring work you are not doing is what stops the checklist growing without end.
- **The umbrella closes when the last child does.** It is never closed by a PR of its own - see the atomicity rules below.

## Pull requests

Commit messages use [Conventional Commits](https://www.conventionalcommits.org/):
`<type>: <description>` or `<type>(<scope>): <description>`. Commitizen checks
this before Git creates the commit. Use the same form for the PR title because
GitHub uses that title for the squash commit on `main`.

**Every PR references an issue that already exists**, and that reference belongs in the description, not only in the branch name.
Write `Closes #123` and the merge closes the issue for you.
Use `Refs #123` when the PR moves an issue forward without finishing it.

If no issue exists yet, open one before opening the PR.
It costs a minute and forces the change to have a stated problem before it has a diff, which is the entire point of the rule.
The "when applicable" escape covers a deliberately small set: typo and formatting fixes, and the dependency bumps Dependabot opens by itself.
Anything that changes behavior, structure, or the public surface gets an issue first.
When the escape genuinely applies, write `No issue: <reason>` in the description instead of a link.

The advisory `issue-link` check reads the description and looks for one of those three forms, ignoring anything inside HTML comments so the template's own examples do not count.
It is advisory on purpose: it reports, it does not block, because a required check here would stop a legitimate typo fix and turn the habit into an obstacle.
Dependabot's own PRs and drafts are skipped, and the check re-runs when you edit the description.

### Keep a PR atomic

For issues, atomicity is a guideline. For pull requests it is close to a hard rule, because the cost falls on the reviewer instead of the author.
An oversized PR results in slow reviews, less careful reviews, and the defect it hides is the one nobody thought to look for.

- **One problem per PR.** The description should name a single problem and the change that solves it. Two problems, however small, are two PRs.
- **The title test.** The title becomes the squash commit on `main`, so write it as a useful commit message. If an honest title needs an "and", you have two PRs.
- **Refactors travel alone.** A rename, move, or reformat mixed into a behavior change buries the behavior change in diff noise, which is exactly where a bug survives review.
- **One sub-issue, one PR.** A PR that closes an ☂️ umbrella issue is too big by construction. Land its children separately, groundwork first, and let the umbrella close itself when the last one merges.
- **One sitting.** If a reviewer cannot hold the whole diff in their head at once, split it. That, not a line count, is the real limit.

### Review and merge

- Review is encouraged whenever another maintainer is available.
  The template requires zero approvals by default so a solo author cannot be locked out; teams with reliable reviewers should raise the count in [`.github/rulesets/main.json`](.github/rulesets/main.json).
- Resolve review threads and update the branch before merging.

## Dependencies

Use `just add <pkg>` for a library-compatible runtime lower bound and
`just add-dev <tool>` for an exact development-tool pin. Never edit `uv.lock`
by hand. `uv.lock` remains normally diffable because dependency changes are
security-relevant even when the file is generated.

All read-only commands use `uv --locked`: it checks that `uv.lock` still matches
`pyproject.toml` and refuses to rewrite it. Deliberate lock commands strip
ambient public/private index overrides, and `scripts/check-lock-index.sh` rejects
accidental private registry sources while still permitting explicit Git and URL
dependencies.

`just update` temporarily relaxes exact direct pins, resolves the newest
versions allowed by project policy, and writes the resolved direct versions
back to `pyproject.toml`; it restores both files if resolution fails. Remote
pre-commit revisions update through Dependabot rather than `autoupdate`, which
can select mutable aliases such as `v1` or `nightly`.
Dependabot groups and auto-merges only development-tool minor/patch updates
after required CI passes. Runtime dependencies, Actions, pre-commit hooks, and
major updates remain human-reviewed because SemVer does not make behavior
changes risk-free.

## Decisions and releases

Record non-obvious tradeoffs in [`docs/decisions.md`](docs/decisions.md). Decisions
that reshape module boundaries, data models, or system structure get an ADR in
[`docs/adr/`](docs/adr/).

There is no hand-maintained changelog. GitHub generates release notes from
squash-merged PRs and [`.github/release.yml`](.github/release.yml).
