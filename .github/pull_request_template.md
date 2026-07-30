<!-- Keep this short. The reviewer's attention is the scarce resource. -->

## Issue

Closes #

<!-- Required. One keyword per issue, each on its own line: `Closes #12` then
     `Closes #13`. A comma-separated list only links the first one.
     Use `Refs #123` when this advances an issue without finishing it.
     Closing a ☂️ umbrella issue here means the PR is too big: reference the
     sub-issue instead and let the umbrella close with its last child.
     No issue yet? Open one first. Only typo/formatting fixes and Dependabot
     bumps are exempt - replace the line above with `No issue: <reason>`.
     The advisory `issue-link` check looks for exactly these forms. -->

## What & why

<!-- One or two sentences. -->

## Architecture impact

- [ ] No architectural change
- [ ] Architectural change; the ADR is linked below

<!-- ADR link (only if architectural): -->

## Checklist

- [ ] An issue is referenced above, or the exemption is stated
- [ ] PR is atomic
- [ ] `just ci` passes
- [ ] Tests and docs changed with behavior, where appropriate
- [ ] Non-obvious reasoning is recorded in `docs/decisions.md` or an ADR

<!-- The PR title becomes the squash commit on `main`. Use Conventional Commits:
     `feat: add task export`, `fix(api): reject empty names`, `docs: clarify setup`. -->
