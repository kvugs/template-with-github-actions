# Decision log

Append-only. When we make a non-obvious call, add ~10 lines to the **top** of the list below.
No template, no ceremony.
The goal is simple: months from now, nobody has to reconstruct "why did we do this?"

**When to log here vs. an ADR:** anything lighter than an architecture decision goes here (tools, conventions, small tradeoffs).
Architecture-level decisions - ones that change module boundaries, data models, or how the system is shaped - get a numbered record in [adr/](adr/) instead.
When in doubt, a 10-line entry here, explaining the when, the what, the why, and the result, is always fine.

The entries below record decisions made in the template itself. Keep them as
provenance; add project-specific decisions above them.

---

## 2026-07-29 - Separate library compatibility from the tested environment

**What:** Runtime additions now receive lower bounds, development tools remain exact, and `uv.lock` records the complete tested resolution. `just update` temporarily relaxes exact direct requirements, resolves under the project's index and age policy, then writes the chosen versions back.

**Why:** Exact runtime metadata makes a reusable library unnecessarily difficult to install alongside other packages, while a lockfile already gives contributors and CI an exact environment. Tool versions are different: their command-line behavior is part of the repository's development contract. A plain `uv lock --upgrade` could not move those exact declarations, so it gave a misleading impression of updating them.

**Result:** Built libraries advertise compatibility instead of an application lock policy, development behavior remains explicit, and `just update` now updates both direct and transitive dependencies without hand-editing the lockfile.

## 2026-07-29 - Enforce Conventional Commits at commit time

**What:** Added the locked Commitizen client as a `commit-msg` hook and documented the same Conventional Commit shape for PR titles.

**Why:** GitHub uses the PR title for this repository's squash commit, and a single-commit PR commonly starts with that commit's subject. A local check catches vague or malformed subjects at the cheapest point. Gitlint was reconsidered, but its last release and repository activity were in 2023; Commitizen is active, supports Python 3.14, and provides the convention without adding a Node toolchain. The branch-wide pre-push hook remains excluded because intermediate commits are squashed.

**Result:** Local commits and final squash titles share a readable `<type>(<scope>): <description>` convention without requiring every intermediate branch commit to survive in main's history.

## 2026-07-29 - Make hook enforcement explicit and deterministic

**What:** Required CI now runs a full-tree Gitleaks scan, read-only Typos and Markdownlint checks, schema validation for composite actions and issue forms, and cross-platform filesystem checks. Actionlint calls the locked ShellCheck binary through a repository wrapper. Every configured hook is classified as required or intentionally local/advisory.

**Why:** The upstream Gitleaks hook remains staged-only under `--all-files`, Typos writes by default, and actionlint only invokes ShellCheck when it happens to be on `PATH`. Those defaults made local and CI behavior diverge or made a required check scan nothing. Link availability is external, so Lychee belongs in the advisory nightly workflow instead of the merge gate.

**Result:** Required checks report without rewriting files, new hooks cannot silently become local-only, and external failures stay visible through the existing nightly watchdog without blocking merges.

## 2026-07-29 - Umbrella issues get a form, a ☂️ title prefix, and a sync job

**What:** Added `.github/ISSUE_TEMPLATE/umbrella.yml`, the `umbrella` label in `scripts/setup-repo.sh`, and `.github/workflows/issue-hygiene.yml`.
The form pre-fills the `☂️` marker plus a trailing space and applies the label; the workflow keeps the two in step in both directions on `opened`, `edited`, `labeled`, and `unlabeled`.

**Why:** Every other issue in the repository is atomic, and the umbrella is the one deliberate exception, so it has to be identifiable at a glance rather than by opening it.
A label alone is invisible in a list of titles and in a commit message; an emoji alone is a convention people forget.
Requiring both by hand means they drift - typically the label gets added to an existing issue and the title never changes - and a marker that is only usually right is not a marker anyone can filter on.
The job removes the rule instead of enforcing it: set either side, get both.
Edits made with `GITHUB_TOKEN` do not trigger workflow runs, so the sync cannot loop.

**Result:** `☂️` in the title and `label:umbrella` return the same set, and the PR rule "never close an umbrella with one PR" has something concrete to point at.
