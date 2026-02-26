---
name: pull-request
description: Creates or updates GitHub pull requests with `gh`, including a thorough change description and explicit manual testing steps.
---

# Pull Request

Create or refresh GitHub pull requests with complete, reviewer-friendly context.

## When To Use

- User asks to create a PR.
- User asks to update an existing PR title/body.
- Branch content changed and PR description needs a refresh.

## Workflow

1. Inspect branch state and PR scope:
   - `git status`
   - `git diff` (staged + unstaged)
   - `git log --oneline <base>..HEAD`
   - `git diff <base>...HEAD`
2. Determine base branch and remote state:
   - `gh repo view --json defaultBranchRef`
   - Confirm current branch tracks/pushes to remote.
3. Build PR content from all included commits (not only the latest commit).
4. Create a PR if none exists, otherwise update the existing PR.
5. Return the PR URL and note what was created/updated.

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
4. <edge case checks>

## Risks / Follow-ups
- <known limitations, rollout notes, or "None">
```

Manual testing is mandatory. Include concrete commands, routes, or click paths and expected outcomes.

## `gh` Commands

- Check for existing PR on current branch:
  - `gh pr view --json number,url,title,body`
- Create PR:
  - `gh pr create --base <base> --title "<title>" --body "$(cat <<'EOF' ... EOF)"`
- Update existing PR:
  - `gh pr edit <number> --title "<title>" --body "$(cat <<'EOF' ... EOF)"`

Prefer HEREDOC bodies to preserve formatting.

## Quality Bar

- Be specific about user-visible behavior and internal changes.
- Mention all major commits/themes included in the PR.
- Do not claim tests/manual checks that were not actually run.
- If validation is blocked, state the blocker and exact command/step needed.
- Keep tone factual and reviewer-oriented.

## Output

Always report:

- Whether the PR was created or updated.
- PR number and URL.
- One-line recap of the main change area.
