#!/usr/bin/env bash
# One-shot GitHub configuration for this repo. Idempotent: safe to re-run.
# Requires the `gh` CLI, authenticated (`gh auth login`) with admin on the repo.
#
#   ./scripts/setup-repo.sh              # uses the repo of the current dir
#   ./scripts/setup-repo.sh owner/name   # or target an explicit repo
#
# Applies: a small label set, squash-only merge settings, security features, and
# the solo-compatible protect-main ruleset from .github/rulesets/main.json.
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "error: the GitHub CLI (gh) is not installed. See https://cli.github.com" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "error: gh is not authenticated. Run: gh auth login" >&2
  exit 1
fi

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Configuring: $REPO"

# --- Labels ------------------------------------------------------------------
# Objective work types, contributor effort estimates, and dependency/release-note
# buckets.
label() { # name color description
  gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null
  echo "  label: $1"
}
echo "Labels:"
label "bug" "d73a4a" "Something is broken"
label "feature" "a2eeef" "A new feature, extension, or improvement"
label "documentation" "0075ca" "Docs are missing, wrong, or hard to follow"
label "architecture" "5319e7" "Changes system structure and needs an ADR"
# Pick at most one effort label per issue. These estimate focused work rather
# than elapsed time or a delivery deadline.
label "time:hours" "0e8a16" "Expected to take a few focused hours"
label "time:days" "fbca04" "Expected to take one to several focused days"
# The one non-atomic issue type: a goal tracked as a checklist of atomic
# sub-issues. .github/workflows/issue-hygiene.yml keeps this label and the ☂️
# title prefix in step, so either one finds every umbrella.
label "umbrella" "c2e0c6" "Goal tracked as a checklist of atomic sub-issues"
# Dependabot + release-notes buckets.
label "dependencies" "0366d6" "Dependency bump"
label "ci" "ededed" "CI / tooling"

# Remove default labels and process labels from earlier template versions (no-op
# if absent). `task` retired because every unit of work is already a bug, a
# feature, or a docs change, and a third catch-all bucket only invited debate
# about which one applied. `duplicate`, `invalid`, and `wontfix` stay because
# release notes exclude them.
for stale in \
  "good first issue" \
  "help wanted" \
  "automerge" \
  "duplicate" \
  "enhancement" \
  "question" \
  "wontfix" \
  "invalid"; do
  if gh label delete "$stale" --repo "$REPO" --yes >/dev/null 2>&1; then
    echo "  removed: $stale"
  fi
done

# --- Repo merge settings -----------------------------------------------------
echo "Merge settings: squash-only, auto-merge on, delete head branches"
gh api -X PATCH "repos/$REPO" \
  -F allow_squash_merge=true \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F allow_auto_merge=true \
  -F delete_branch_on_merge=true \
  -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=PR_BODY >/dev/null

# --- Security features -------------------------------------------------------
# Free on public repos. Each one is a whole class of mistake we stop making by
# hand: leaked credentials, known-vulnerable dependencies, and unreported
# vulnerabilities that would otherwise arrive as a public issue.
echo "Security: vulnerability alerts, Dependabot security updates, secret scanning"
sec() { # method path label
  if gh api -X "$1" "repos/$REPO/$2" >/dev/null 2>&1; then
    echo "  enabled: $3"
  else
    echo "  skipped: $3 (needs a public repo or GitHub Advanced Security)"
  fi
}
sec PUT vulnerability-alerts "vulnerability alerts"
sec PUT automated-security-fixes "Dependabot security updates"
sec PUT private-vulnerability-reporting "private vulnerability reporting"

if gh api -X PATCH "repos/$REPO" \
  -F 'security_and_analysis[secret_scanning][status]=enabled' \
  -F 'security_and_analysis[secret_scanning_push_protection][status]=enabled' \
  >/dev/null 2>&1; then
  echo "  enabled: secret scanning + push protection"
else
  echo "  skipped: secret scanning (needs a public repo or GitHub Advanced Security)"
fi

# --- Branch protection ruleset ----------------------------------------------
# Create protect-main, or update it if it already exists. It requires PRs and
# up-to-date CI but zero approvals by default, so a solo author is never locked
# out. Teams can raise the review count in main.json when a reviewer is reliable.
echo "Ruleset: protect-main"
RULESET_JSON="$SCRIPT_DIR/../.github/rulesets/main.json"
EXISTING_ID="$(gh api "repos/$REPO/rulesets" -q '.[] | select(.name=="protect-main") | .id' 2>/dev/null || true)"
if [ -n "$EXISTING_ID" ]; then
  gh api -X PUT "repos/$REPO/rulesets/$EXISTING_ID" --input "$RULESET_JSON" >/dev/null
  echo "  updated (id $EXISTING_ID)"
else
  gh api -X POST "repos/$REPO/rulesets" --input "$RULESET_JSON" >/dev/null
  echo "  created"
fi

echo "Done. Review at: https://github.com/$REPO/settings/rules"
