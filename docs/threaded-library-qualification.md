# Threaded Library Qualification

This records selected Library candidate DSL061, not a portable release, a
multi-core inference benchmark or automatic qualification of later UF changes.
The raw local archive is `.data/ascent-threaded-library-061/phase-1.json`.

## Actual Changes

- No AnyIO dependency. Standard-library threads supervise independent child
  processes; each child initializes and uses its own C ABI runtime on its main
  OS thread. The runtime's thread guard is unchanged.
- `Module.evidence` constructs independent sessions from loaded definitions.
  It reuses native loading/expansion, not mutable inference state or count policy.
- All 50 Quint lifecycle trajectories remain. Construction failure, source
  replacement, independent limits, definition-owner close, retained explanation
  and released references are checked through the actual Library.
- Real contract-inventory DSL uses upstream operators, finite higher-order
  compilation and Actor closures. The complete answers are compared in Scheme,
  with actual edge withdrawal/restoration and explicit Actor close.

## Matching Results

The same 193 tests in 35 processes, identical complete source/fixture/artifact
inventory, scheduler and Library/API receipt passed in both controls:

| Scheduling | Wall time | Whole budget | Skips |
| --- | ---: | ---: | ---: |
| One worker | 78.194 s | 120 s | 0 |
| Four workers | 29.599 s | 120 s | 0 |

Every original per-fixture ceiling remains. Queue time consumes the shared
deadline; actual exit/timeout/stdout/stderr/process-group teardown remain in
the receipts. These are one matched local pair, not statistical speed estimates.
Concurrency reduced matrix wall time; it does not make a single query 2.64x faster.

The real scenario and source-bound general owner controls passed four tests
in 5.008 s under the unchanged 15 s ceiling. Actor worker capacities 1/2/4 agree
on the same complete contract graph; this establishes no Actor speed benefit.

The Library build/package/API completed in 43.854/0.643/1.256 s within their
original 120/15/45 s ceilings. This uses a prepared incremental cache, not a
cold build. Independent rehash matched 132 build inputs, 127 linked Scheme
sources, 1265 syntax resources in both copies, Library and CFFI extension
(2664 paths). API receipt:
`3db876fcbadaf4836e94d221d6eaae806ed2fc262e171053822118c7af2f41c7`.

## Single-Fixture Cost And Open Gates

Conformance replays 50 adversarial lifecycle trajectories; the added isolation
control makes three test methods, not three native requests. Instrumentation
observed 732 result/explanation boundary calls plus run/replacement/close calls.
Negative checks also render native rejection diagnostics. Whole-fixture time
must not be presented as single-query latency or attributed solely to expansion.
The first API timing favored reuse; the ABI order did not. Whole-conformance
speed improvement is not established from those variable samples.

The original DSL060 lifecycle-fixture error (replacement before initial run)
and DSL061 extra-parenthesis load error remain in raw receipts. Both were fixed
by exact source changes, not by loosening contracts or execution budgets.

Scheme Actors exist, but Actor Session admits pure positive canonical Set rules
and does not implement the ordinary Session's `.run-timeout` entry. The default
C ABI retained Session cannot be replaced wholesale without deadline/cancel/drain
and full rule-support contracts. Owning a value does not close arbitrary actor
resources automatically. No source-refinement theorem follows from these tests.

Fresh full-consumer/current-graph qualification remains a separate gate. The
historical scope058 graph and unrelated maintenance candidate results are not
current evidence for this candidate.

## Current Combined Candidate DSL063

DSL063 physically freezes the current reusable DSL interface and Evidence
prelude together with the final upstream relation-view and UF implementation.
It is not a combination of DSL061 and maintenance062 test receipts. Its actual
build/package/API completed in 97.705/0.937/1.424 s under the unchanged
120/15/45 s ceilings. Independent rehash matched 2664 paths, including all
132 build inputs, 127 linked sources and both copies of 1265 syntax resources.
The actual API receipt SHA is
`f91f4ba46ffa5f10b07f7f2ca8cf947dd1f3e250dd19114ecddb329722ce6728`.

The complete current inventory includes newly added upstream fixtures:
202 tests in 37 processes, with no skips. One-worker and four-worker controls
passed in 85.072 s and 27.298 s respectively under the original shared 120 s
deadline. Their full checked-input maps, fixture/mode inventory, scheduler and
API receipt match. These remain one local pair, not a single-query or Actor
performance claim. Raw current receipts are in
`/private/tmp/ascent-provider-dsl-063-001`; fresh consumer/performance/current
graph evidence must independently match this candidate before being admitted.

## Corrected Current Candidate DSL064

The upstream custom-export review exposed an uncovered ordering contract:
one-argument complete export may use exporter order, while an explicitly empty
three-argument query must preserve visitor order. The old source reproduces the
failure through actual native, API and ABI controls; the new source preserves
both contracts. Its test-only factory accepts caller-supplied rows rather than
adding a production success path.

ROOT independently rehashed the actual new DSL064 producer, all 132 build
inputs, 127 linked sources, both copies of all 1264 actual syntax resources,
Library/API binaries and current Python implementation/fixture bytes. The 2662
artifact paths match; API receipt SHA is
`4c40397e44584412d70a169307a07a3627c6cef3b604c4d15d669aa179163ad1`.
No DSL061/062/063 result is used as DSL064 qualification.

Its complete current matrix passed 203 tests in 37 processes, no skips:
four-worker scheduling 30.781 s versus identical one-worker inventory 84.005 s,
with the original shared 120 s ceiling and unchanged fixture caps. Consumer
ownership/source/cleanup controls passed 26 tests in 8.567 s; the real Evidence
operator/typed/Actor scenario and general-owner controls passed four tests in
4.366 s, each under the original 15 s ceiling.

The first DSL063 full graph is retained as DENY: 770 tests, two failures, no
errors/skips, parent exit 2 without timeout. The failing historical-source test
now explicitly rejects current producer drift, preserving the original receipt;
the audit test checks all current issue requirements, conditions and references
instead of assuming one issue. Twenty focused tests passed in 8.678 s. These
changes do not reclassify the old graph or waive runtime/model premises.

Fresh full graph and readback must use this corrected candidate and matching
consumer inputs. Local raw qualification archives are not a portable release,
committed provenance, unbounded fairness proof or arbitrary-resource sandbox.
