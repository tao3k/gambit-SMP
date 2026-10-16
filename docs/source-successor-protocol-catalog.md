# Source Successor Protocol Catalog

## Existing Framework Integration

The six source-successor models are registered through the existing
gambit-protocol-extensions manifest and protocol-bundles registry. No new Python
execution lane, receipt format adapter or Datalog reasoner was introduced.
The contract is `evidence/fixtures/fdset-abort-owned-rollback/protocol-contract.json`.
Its source context binds the latest 23-file candidate lock and overlay, model
sources and five typed safety Recipes by SHA-256.

Registered models:

- sfun_marker_context_use
- sfun_allocation_unwind
- foreign_origin_retirement_admission
- sfun_gate_publication_order
- pipe_descriptor_rollback
- fdset_abort_setup_ownership

Three required dependency edges connect context to allocation unwind, origin
lifecycle to split publication, and descriptor rollback to fd-set setup. Only
the split-publication model imports its dependency. Other edges name contract
obligations, not proved products or a whole-GC refinement theorem. Global
dependency validation found no unknown parent, duplicate ID or cycle.

## Deliberate Acceptance Boundary

Registration uses the framework's existing registrationOnly contract. The
separate typed safety checks remain valid observations at their recorded source
scope; they are not converted into a legacy complete protocol receipt requiring
temporal proof. No synthetic accepted receipt is written to the registered
qualification path. A missing complete receipt keeps its requirement open.

There are 21 explicit open obligations across current-source refinement, lookup
lifetime/generation correspondence, nested callbacks, CPU memory ordering,
public fault paths, platform configurations, temporal progress and native
retirement/bootstrap. Sixteen registry control labels are declared; the typed
pipe Recipe additionally retains unpublished-output and omitted-temp controls.
That limitation of the registry labels is documented, not silently omitted from
the safety experiment inventory.

## Actual ASCENT Query

The existing `gambit-smp evidence --validate` command completed with
DATALOG-COVERAGE-OK through the official receipt-bound ASCENT C ABI. The framework
executor reports exit 0, no timeout, 4.116902917 seconds under the 15-second
focused ceiling, parent reaped and process group quiescent.

The complete catalog query reports 122 protocol models, 112 complete checked
protocols and 10 lacking complete checks. All six newly registered models occur
in protocol_extensions_without_checks; none occurs in recorded_protocol_checks.
All 21 new obligations occur in protocol_open_obligations. The source change
has therefore become visible to the existing native Scheme DSL review path
without promoting local safety checks to full acceptance.

Fact export SHA-256:
`2bba584f6ec5e7fb265b7f7c69497bef4393f8dcf853f298a095d6398d0b273b`.
Query receipt SHA-256:
`4588c8b820d4e6a08355de48272ecb95077ade1af312d819ae74d7647e021bde`.
Provider library SHA-256:
`e7d1636dd195461b4218b6c8e17f45f379157936603a232379db069cbe4ee2dc`.
Provider build receipt SHA-256:
`4fc9e9a42490b2a9f2bd3151ec825cf52dc0e9a3dcff947886d8eb1891ae54de`.

The existing protocol-evidence regression module passes 27/27 tests in
0.040 seconds. These focused checks are not a new complete consumer-framework
qualification or native SMP test pass. Temporary provider locations are not
repository dependencies, and no personal absolute path is included here.

## Milestone

Cumulative native progress remains 3/12. The latest source candidate still
requires bootstrap/requalification; the nine open native gates are unchanged.
Original qualification consumption remains 468.695876834 / 600 seconds.
No new bootstrap budget or unchanged failed native route was run in this work.
