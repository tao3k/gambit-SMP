# ASCENT History Repeat Input Bound

## Observed Cause

The failed full Agent context export reached native history-delta inference.
Its original program supplied 2,254 source facts. The first query completed;
the second query converted completed components into source relations while
also keeping all original source facts. That new open request supplied 4,210
facts and was correctly rejected by the unchanged 4,096 total-input limit.
The request was 480,069 bytes, below the independent 1 MiB wire limit.

The failed route is `.data/agent-context-feasibility-015`. Its validation child
passed 390 framework tests, but the export itself failed; this is not a valid
Agent context receipt. The diagnostic rerun inspected request sizes and shapes,
not a new performance or Gambit native acceptance result.

## Repair

In the ASCENT dependency, `EvidenceChain` remembers the admitted lowered path
and relation mapping for an exact request within one source generation.
Repeated requests use that same native session through `EvidenceStore` and
still execute the native completed-session `run(0)` check. They do not copy
completed outputs back into a fresh input program. Changed requests still use
component composition. Source replacement and close clear remembered paths.

Authority checks execute before lookup. The repair does not relax input bounds,
skip history, delete observations, implement inference in Python, or admit
runtime execution. Loaded dependency hashes remain part of every receipt.

## Regression Coverage

- The ASCENT Datalog suite checks 2,100 source facts with a 2,100-row derived
  result: exact repetition performs one open and two native runs, including
  the completed zero-budget run, with the same path and answer.
- A true 4,100-fact input across two individually valid relations still fails
  native admission.
- An exact repeat of a composed aggregate path retains its native session.
- The research history regression records 1,100 input identities and 100
  conclusions twice, preserving native deltas and observation identity.
- Existing source-replacement, negation and authority regressions remain
  mandatory; no old-history result becomes execution authority.

The ASCENT change is currently a local dependency edit, not a published pin.
Fresh export and recheck receipts must bind its current implementation hash.
None of these checks establishes Gambit SMP, bootstrap, or Gerbil acceptance.

## Independent Stale Source-Schedule Receipt

After the native history repair, export `agent-context-history-repair-016`
produced the graph but correctly denied full validation: 395 tests, zero
failures, one error, no skipped tests or changed inputs during the run.
The source-schedule receipt bound an older `framework.py`. Commit `86e9145`
added its restricted relative-path helper. All seven other schedule inputs,
including the original Gambit source, fixture, model and extractor, were
unchanged. The failure was stale evidence, not a repaired Gambit runtime.

The unchanged eight control schedules were rerun using GNU GCC 16.2.0 and
the current helper module. All expected outcomes matched; the extracted
function digest remained `93726a9a3160092cb8f0510c0e3fa88635586c2e8d802d4209fd551ec33b809d`.
The original `sync-retirement-source-schedule-uv-001.json` stays intact.
The correspondence now binds new receipt `sync-retirement-source-schedule-uv-002.json`,
SHA-256 `313fa471e58d4e90326e4a106429798c1d8e211dbe7f1ded840b42d834acfe01`.
This is still a mocked source-schedule observation, not native SMP acceptance.
