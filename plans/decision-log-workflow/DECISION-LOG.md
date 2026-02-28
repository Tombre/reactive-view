# Decision Log - decision-log-workflow

## DEC-20260228-01 - Establish decision log workflow

- Status: Active
- Date: 2026-02-28
- Deprecated By: N/A
- Supersedes: None

### Context
Planning and implementation choices were not being recorded in one durable place, which made later decisions slower and less consistent.

### Decision
Adopt a per-feature decision log workflow under `plans/{{ feature name }}/DECISION-LOG.md` and capture non-trivial planning and implementation choices with stable IDs.

### Consequences
Future planning can reference prior rationale quickly; when choices change, old decisions stay visible and are marked deprecated instead of deleted.
