---
name: feature-plan
description: Writes feature plans and keeps per-feature architecture decision logs.
---

## What I do

Create and maintain planning artifacts for features under `plans/`:

- Plan file: `plans/{{ feature name }}/PLAN.md`
- Decision log file: `plans/{{ feature name }}/DECISION-LOG.md`

Use a short kebab-case feature name for directory paths (for example `streaming-support`).

## When To Use

Use this skill when the user asks to:

- create or update a feature plan
- record planning outcomes for future work
- capture architecture decisions tied to a plan

Trigger this skill by default for:

- big architecture changes
- major implementation plans
- new feature planning

## Required Workflow

1. Ensure the feature has a plan at `plans/{{ feature name }}/PLAN.md`.
2. Every time the plan introduces or changes an architecture decision, write it to `plans/{{ feature name }}/DECISION-LOG.md`.
3. Never skip decision logging for architecture-level choices.

## Decision Format

Each decision entry should include:

- Decision ID (for example `DEC-20260228-01`)
- Status
- Date
- Context
- Decision
- Consequences

Use status values consistently:

- `Active`: the decision is currently in effect.
- `Deprecated`: the decision has been replaced.

If a decision replaces an earlier one, include `Supersedes` and set the older entry to `Deprecated` in the same file.

Use `plans/_templates/DECISION-LOG.md` as the default template when creating a new decision log.

## Decision Entry Example

```md
## DEC-20260228-01 - Choose root-owned runtime

- Status: Active
- Date: 2026-02-28
- Deprecated By: N/A
- Supersedes: None

### Context
We need one canonical JS dependency graph to reduce setup drift.

### Decision
Keep Node runtime ownership at repository root and keep generated artifacts under `.reactive_view`.

### Consequences
DX is simpler and dependency management is centralized.
```
