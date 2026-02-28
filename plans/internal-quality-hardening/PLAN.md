# Internal Quality Hardening Plan (API Stable)

**Status:** Planning
**Priority:** High
**Scope:** Internal improvements only (no public Ruby or TypeScript API changes)

## Table of Contents

- [Overview](#overview)
- [Goals and Non-Goals](#goals-and-non-goals)
- [Compatibility Guardrails](#compatibility-guardrails)
- [Current State Snapshot](#current-state-snapshot)
- [Workstream 1: Dead Code and Dependency Cleanup](#workstream-1-dead-code-and-dependency-cleanup)
- [Workstream 2: Security Hardening](#workstream-2-security-hardening)
- [Workstream 3: Error Handling and Observability](#workstream-3-error-handling-and-observability)
- [Workstream 4: Performance Improvements](#workstream-4-performance-improvements)
- [Workstream 5: Testability Improvements](#workstream-5-testability-improvements)
- [Benchmark and Validation Plan](#benchmark-and-validation-plan)
- [Execution Plan (PR Slices)](#execution-plan-pr-slices)
- [Risk Register](#risk-register)
- [Definition of Done](#definition-of-done)

---

## Overview

This plan targets background improvements to ReactiveView internals while preserving the developer-facing contract.

Focus areas:

1. Remove dead code and stale dependencies.
2. Improve security posture and isolation.
3. Improve runtime error handling and debugging signal.
4. Improve performance in hot paths with measurable evidence.
5. Increase testability of process/network-heavy components.

No user-facing API changes are permitted. Existing loader, mutation, shape, routing, and generated TypeScript APIs must remain source-compatible.

---

## Goals and Non-Goals

### Goals

- Reduce maintenance overhead by removing unused code paths and dependencies.
- Harden request handling against cross-request leakage and accidental method exposure.
- Make failure modes more deterministic and easier to diagnose.
- Improve latency/throughput in known hot paths with benchmark-backed verification.
- Increase confidence with targeted tests around concurrency and failure scenarios.

### Non-Goals

- No breaking API changes in Ruby or TypeScript.
- No behavioral redesign of file-based routing, shape DSL, or mutation semantics.
- No product feature additions.
- No redesign of public generated type signatures.

---

## Compatibility Guardrails

All work in this plan must satisfy:

1. No signature changes to documented public methods/classes in `reactive_view/lib`.
2. No export surface changes in `reactive_view/npm/src/index.ts` except internal refactors with same exports.
3. No changes to generated loader API shape (hook names, mutation helper names, form helper names).
4. Existing example app pages continue to run without code changes.
5. Full gem test suite passes (`bundle exec rspec` in `reactive_view/`).

---

## Current State Snapshot

Baseline findings from repository review:

- Test baseline is green: `322 examples, 0 failures` in `reactive_view/spec`.
- Dead or likely-dead internals exist:
  - Unused gem dependency candidate: `faye-websocket` in `reactive_view/reactive_view.gemspec`.
  - Unused generator helpers in `reactive_view/lib/generators/reactive_view/install_generator.rb`.
  - Unused method `write_silent` in `reactive_view/lib/reactive_view/file_sync/atomic_writer.rb`.
  - Unused constant `VALID_STATUSES` in `reactive_view/lib/reactive_view/daemon.rb`.
  - Unused Node imports in `reactive_view/npm/src/cli.ts`.
- Security concern: SSR request context values are stored on `globalThis` in `reactive_view/template/src/routes/api/render.ts`.
- Potential method-exposure hardening opportunity in mutation validation logic in `reactive_view/app/controllers/reactive_view/loader_data_controller.rb`.
- Performance opportunities:
  - Dev proxy builds HTTP connection per request in `reactive_view/lib/reactive_view/dev_proxy.rb`.
  - Stream message derivation in `reactive_view/npm/src/stream.ts` can be made more incremental.

---

## Workstream 1: Dead Code and Dependency Cleanup

### 1.1 Remove unused dependency declarations

**Targets**

- `reactive_view/reactive_view.gemspec`

**Plan**

- Remove dependencies that are not referenced by code paths or tests.
- Confirm no runtime load path depends on removed gems.

**Validation**

- `bundle exec rspec` in `reactive_view/`.
- Gem build/install smoke test.

### 1.2 Remove unused Ruby internals

**Targets**

- `reactive_view/lib/reactive_view/file_sync/atomic_writer.rb`
- `reactive_view/lib/reactive_view/daemon.rb`
- `reactive_view/lib/generators/reactive_view/install_generator.rb`

**Plan**

- Remove provably unused methods/constants.
- Keep behavior unchanged for callers.

**Validation**

- Existing specs.
- Generator smoke run in example app context.

### 1.3 Remove unused TypeScript imports/helpers

**Targets**

- `reactive_view/npm/src/cli.ts`

**Plan**

- Remove dead imports and dead locals.
- Keep CLI command behavior unchanged.

**Validation**

- TypeScript build in `reactive_view/npm`.
- CLI smoke checks (`dev`, `build`, `start` help/arg parsing).

---

## Workstream 2: Security Hardening

### 2.1 Request-scoped SSR context (replace process-global sharing)

**Targets**

- `reactive_view/template/src/routes/api/render.ts`
- `reactive_view/npm/src/loader.ts`
- `reactive_view/npm/src/mutation.ts`
- `reactive_view/npm/src/stream.ts`
- `reactive_view/template/src/entry-server.tsx`

**Plan**

- Replace mutable `globalThis` request context storage with request-scoped context propagation.
- Ensure concurrent SSR requests cannot leak cookies/CSRF/base URL to each other.

**Validation**

- Add concurrency-focused integration test (parallel render requests with different cookie/token context).
- Verify generated HTML/meta token correctness per request.

### 2.2 Tighten mutation callable allowlist

**Targets**

- `reactive_view/app/controllers/reactive_view/loader_data_controller.rb`

**Plan**

- Restrict invokable mutation methods to explicit loader-defined mutation methods.
- Preserve existing valid mutation behavior and status codes.

**Validation**

- Add tests for blocked methods (`load`, framework methods, helper methods).
- Add tests ensuring declared mutation methods still work.

### 2.3 Process spawn hardening

**Targets**

- `reactive_view/lib/reactive_view/file_sync/directory_setup.rb`
- `reactive_view/lib/reactive_view/daemon.rb`
- `reactive_view/lib/reactive_view/benchmark/server_manager.rb`

**Plan**

- Prefer argv-form process execution where feasible.
- Reduce shell interpretation risk while preserving current command behavior.

**Validation**

- Existing daemon and benchmark specs.
- Manual daemon start/stop smoke checks.

---

## Workstream 3: Error Handling and Observability

### 3.1 Normalize error payload and logging boundaries

**Targets**

- `reactive_view/lib/reactive_view/renderer.rb`
- `reactive_view/app/controllers/reactive_view/loader_data_controller.rb`
- `reactive_view/lib/reactive_view/loader.rb`

**Plan**

- Keep external JSON response shapes stable.
- Internally standardize parse errors, timeout errors, and stream errors.
- Ensure logs are useful but do not overexpose request-sensitive data.

**Validation**

- Add tests for malformed JSON and unexpected content-type responses.
- Confirm production-mode generic error behavior remains intact.

### 3.2 Remove duplicated error-formatting logic

**Targets**

- `reactive_view/lib/reactive_view/shape.rb`
- `reactive_view/lib/reactive_view/types/validator.rb`

**Plan**

- Introduce one internal error formatter utility used by both validation paths.
- Preserve returned error structure.

**Validation**

- Existing shape and validator specs.
- Add parity tests for nested error formatting.

---

## Workstream 4: Performance Improvements

All performance changes require benchmark evidence before merge.

### 4.1 Dev proxy connection reuse

**Targets**

- `reactive_view/lib/reactive_view/dev_proxy.rb`

**Plan**

- Reuse a memoized Faraday connection per middleware instance.
- Avoid per-request connection allocation overhead.

**Expected Impact**

- Reduced allocation churn and lower proxy latency under dev asset load.

**Validation**

- Microbenchmark: repeated proxy requests vs upstream mock.
- No regression in header forwarding behavior.

### 4.2 Stream message accumulation efficiency

**Targets**

- `reactive_view/npm/src/stream.ts`

**Plan**

- Replace full recomputation patterns with incremental append logic for parsed stream messages.
- Avoid unnecessary array remaps on each chunk.

**Expected Impact**

- Better client-side performance for long streams (large chunk counts).

**Validation**

- Browser/node microbenchmark using synthetic 1k/5k/10k chunk streams.
- Verify identical output semantics and stream completion behavior.

### 4.3 Optional: type generation runtime reductions (internal)

**Targets**

- `reactive_view/lib/reactive_view/types/typescript_generator.rb`

**Plan**

- Profile generator hotspots and reduce repeated schema conversions where possible.
- No generated output changes allowed.

**Expected Impact**

- Faster `reactive_view:types:generate` on larger loader sets.

**Validation**

- Benchmark generation time before/after with same fixture project.
- Snapshot test generated files to verify byte-equivalent output (or semantically equivalent where whitespace-only changes are intentional).

---

## Workstream 5: Testability Improvements

### 5.1 Isolate process and network boundaries

**Targets**

- `reactive_view/lib/reactive_view/daemon.rb`
- `reactive_view/lib/reactive_view/renderer.rb`
- `reactive_view/lib/reactive_view/dev_proxy.rb`

**Plan**

- Introduce small internal seam points (callables/adapters) for process spawn, kill, and HTTP calls.
- Keep public API unchanged.

**Validation**

- Add unit tests for retries, restart budget, and timeout behaviors without requiring live processes.

### 5.2 Deterministic watcher/monitor tests

**Targets**

- `reactive_view/lib/reactive_view/file_sync/file_watcher.rb`
- `reactive_view/lib/reactive_view/daemon.rb`
- corresponding specs in `reactive_view/spec/reactive_view`

**Plan**

- Make timer and thread-dependent logic more test-controllable (injectable clock/sleep where practical).
- Reduce flakiness from wall-clock sleeps.

**Validation**

- Run targeted specs repeatedly to verify stability.

---

## Benchmark and Validation Plan

This section is mandatory for all performance-related changes.

Execution details and copy-paste commands live in `plans/internal-quality-hardening/benchmark-playbook.md`.

### A. Baseline capture (before any perf change)

Run and save:

1. Existing benchmark suite (`reactive_view:benchmark:*`) with fixed iterations and concurrency.
2. New microbenchmarks for:
   - Dev proxy request path
   - Stream chunk processing path
   - Type generation runtime (if touched)

Store outputs under a timestamped benchmark artifact file in repo docs/plans (no generated temp artifacts committed outside docs).

### B. Success criteria

- No performance regression greater than 5% at p95 for touched paths.
- At least one targeted hotspot shows meaningful improvement (goal: 10%+ in mean or throughput).
- Memory/allocation behavior does not worsen materially in microbench scenarios.

### C. Required reporting per perf PR

Include a `Before vs After` table:

- mean ms
- p95 ms
- p99 ms
- req/s (where applicable)
- test command and environment summary

### D. Reproducibility controls

- Fixed iteration counts and warmups.
- Same machine/runtime mode for before/after.
- No concurrent unrelated load during benchmark run.

---

## Execution Plan (PR Slices)

### PR 1: Baseline + benchmark harness updates

- Add/standardize benchmark commands and result template.
- Capture baseline report.

### PR 2: Dead code/dependency cleanup

- Remove low-risk dead code and stale imports/dependencies.
- Verify full test pass.

### PR 3: Security hardening

- Implement request-scoped SSR context isolation.
- Tighten mutation method allowlist.
- Add negative/parallel tests.

### PR 4: Performance batch 1

- Dev proxy connection reuse.
- Stream accumulation improvements.
- Include benchmark deltas.

### PR 5: Error-handling + testability improvements

- Validation/error formatting consolidation.
- Internal seam refactors and deterministic tests.

### PR 6: Performance batch 2 (optional)

- Type generation optimization if measured bottleneck is confirmed.

---

## Risk Register

1. **Hidden coupling risk in SSR context changes**
   - Mitigation: add concurrency tests first, then refactor.

2. **Behavior drift in mutation method validation**
   - Mitigation: explicit allow/deny test matrix.

3. **Benchmark noise leading to false conclusions**
   - Mitigation: repeated runs and fixed setup controls.

4. **Refactor churn with little practical gain**
   - Mitigation: gate perf changes behind measurable deltas.

---

## Definition of Done

This plan is complete when:

- All planned internal refactors are merged without public API breakage.
- Dead code/dependency targets are removed or explicitly documented as retained.
- Security hardening tasks are implemented and covered by tests.
- Performance changes include benchmark evidence with before/after data.
- Full gem test suite passes after each PR slice.
- Documentation of benchmark methodology and results is committed.
