---
name: pull-request
description: Creates GitHub pull requests with `gh` and a reviewer-ready body with summary, testing, and risk notes.
---

# Pull Request

Create GitHub pull requests with `gh` using a complete, reviewer-friendly description.

## When To Use

- User asks to open/create a GitHub pull request.
- User asks to "make a PR with gh".
- A branch is ready to merge and needs a reviewer-ready PR description.

## Workflow

1. Determine the base branch:
   - `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
2. Inspect what the PR will include (all commits since divergence):
   - `git status`
   - `git diff`
   - `git log --oneline <base>..HEAD`
   - `git diff <base>...HEAD`
3. Ensure branch is on remote:
   - If needed: `git push -u origin <branch>`
4. Draft PR title/body from all included commits (not only `HEAD`).
5. Create the PR with `gh pr create`.
6. Return PR number + URL and one-line intent recap.

## Preflight Checks

- Do not create a PR from a dirty branch unless user explicitly wants WIP changes included.
- Do not claim tests/manual checks unless they were actually run.
- If there is already an open PR for the branch, update it instead of creating a duplicate:
  - `gh pr view --json number,url,title,body`
- If the PR includes `reactive_view/npm/src/*` changes, run `npm run build --prefix reactive_view/npm` and include the resulting `reactive_view/npm/dist/*` updates in the PR.

## Required PR Body Structure

Use this structure for both create and update operations:

```md
## Summary
- <2-4 bullets explaining intent and impact>

## What Changed
- <file/behavior-level changes grouped by area>
- <include migration/config/runtime behavior changes>

## Manual Testing
1. <setup step>
2. <run command or UI flow>
3. <expected result>
4. <edge case or regression checks>

## Risks / Follow-ups
- <known limitations, rollout notes, or "None">
```

Manual testing is mandatory. Include concrete commands, routes, or click paths and expected outcomes.

## `gh` Commands

- Create PR:
  - `gh pr create --base <base> --title "<title>" --body "$(cat <<'EOF' ... EOF)"`
- Update existing PR when one already exists:
  - `gh pr edit <number> --title "<title>" --body "$(cat <<'EOF' ... EOF)"`

Prefer HEREDOC bodies to preserve formatting.

## Quality Bar

- Be specific about user-visible behavior and internal changes.
- Mention all major commits/themes included in the PR scope.
- Do not claim tests/manual checks that were not actually run.
- If validation is blocked, state the blocker and exact command/step needed.
- Keep tone factual and reviewer-oriented.

## Output

Always report:

- Whether the PR was created or updated.
- PR number and URL.
- One-line recap of why this change exists.
