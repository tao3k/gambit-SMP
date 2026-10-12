# Caller-Owned ASCENT Capacity Qualification

ASCENT is a Library for Agentic AI. Downstream consumers import Python and
provide ordinary DSL definitions; no downstream Scheme imports, packages,
compiler or build workflow is required. The Library owns hygienic expansion,
composition and inference. This change adds a general native policy, not a
History-specific producer or Python inference branch.

## Public Policy

`Engine()` defaults to no request-byte ceiling. `FactLimits()` defaults to no
input, derived or output count ceiling. Native Scheme uses actual `+inf.0`, not
a larger finite replacement. Optional finite caller ceilings remain enforced:

```python
from ascent_engine import Engine, FactLimits

engine = Engine(max_request_bytes=2 * 1024 * 1024)
with engine.evidence(dsl_definitions, "make-history", trusted=True,
                     limits=FactLimits(input=10000, output=20000)) as session:
    pass
engine.shutdown()
```

Missing policy fields are unlimited. Native ceilings can tighten explicit finite
DSL declarations, never loosen them. `SourceSession.fact_limits` reports the
effective policy. Request bytes measure exact encoded UTF-8 JSON bytes. ABI
allocation overflow, NUL and UTF-8 validation remain enforced. Trusted execution
is not a sandbox. Unlimited counts do not promise unlimited RAM or termination.
DSL structure, symbol codecs, scopes, handles, projection and execution resources
remain distinct constraints; they are not claimed to be unlimited.

## Final Matched Build

Library `build.ss` / `defbuild-script` / upstream `std/make` built the actual
changed native modules and ABI with GNU GCC16/O0, using a prepared incremental
cache. The final build is 046-005, not transitional counts-only002 or API004.

| Gate | Actual Duration | Original Cap | Result |
| --- | ---: | ---: | --- |
| Native build005 | 33.861s | 120s | exit0, no timeout, quiescent |
| ABI package005 | 0.582s | 15s | exit0, no timeout, quiescent |
| CFFI API005 | 1.167s | 45s | exit0, no timeout, quiescent |
| Complete interface matrix003 | 43.198s | 120s whole | 167 tests / 28 fresh processes / 0 skip |
| History002 | 9.533s | 15s | 9 tests / 0 skip |
| Main paths and complete DSL scenario002 | 4.966s | 15s | 5 tests / 0 skip |
| Consumer/source audit002 | 8.085s | 15s | 27 tests / 0 skip |
| Catalog/review001 | 11.673s | 15s | 22 tests / 0 skip |
| Actual production evidence command003 | 3.630s | 15s | exit0, DATALOG-COVERAGE-OK |

The source audit requires `/usr/bin/git`; Gerbil SDK environment paths remain
hidden. Other consumer controls hide the SDK and compiler paths. Matrix PATH
permits the existing external Quint checker, not a downstream Scheme build.

API receipt SHA256:
`bc7426ab199354c235b0b912d4a2181e4d4ee01935c3c7ef69937ee10f58f0e5`.
Library SHA256:
`b2bbb682cd23a7de3e8808b04871bb3611c9fe01ec6e7e649b419584600d79c1`.
Extension SHA256:
`7a131d36fe2490d0a5dce940de26e4be967eacaf7d5d4282b4c1d187d9298c45`.
Independent rehash matched all132 build inputs,127 linked Scheme sources,
1265 loaded resources and both artifact identities. Production readback also
matched all1220 source bindings and1274 backend bindings, including individual
resource paths and the actual Python transport modules.

## Complete Production History

The real console command `gambit-smp evidence --validate --out ...` performed
native catalog queries and History comparison, then persisted the observation.
Read-only SQLite verification found8981 complete source occurrences:

| Snapshot | Query Rows | Source Bindings | Backend Bindings |
| --- | ---: | ---: | ---: |
| Previous | 2001 | 1057 | 1274 |
| Current | 2155 | 1220 | 1274 |

Native limits report input/derived/output `unlimited`. Native Scheme derived
154 added rows,0 removed,2001 retained,29 changed inputs and163 added inputs.
No source truncation, aggregated identity hash, hidden partition or Python delta
inference was used. The original observation
`cd094f42ae18b51d3936a8f304702c2464cbe77961dc7880dee9004894bd777f`
still exists. The observed head matches the successfully persisted observation
`12c33579d4287000951775fb2efb1d6ae96753efe85b15a2fcde4c242e567594`.
Production receipt SHA256 is
`139085737bd486d6c3e9ebd5577363c2a9bb8f08a846b076dbd9e40114f89c6a`.

Default large-history regression verifies repeated observation and growth.
Explicit4096 caller-policy rejection remains a negative control, preserving
the previous head and observations. Native source withdrawal, finite derived
and output limits, rejection atomicity, reference operators and positive
insertion plans are independently exercised. A request larger than1MiB runs
through actual Python/native calls; explicit byte ceilings reject oversized
requests. Positive insertion operators are not described as arbitrary withdrawal.

## Preserved Failures And Boundaries

All preceding build, harness, source-registration and finite-policy failures
remain archived. Mainpaths001 failed because two newly registered composition
models referenced unregistered parents. The asset owner registered both parents
from real manifests/receipts without deleting composition edges; mainpaths002
then passed. Audit001 failed with Git hidden; audit002 changed only the controlled
audit PATH. Neither retry increased the original time budget.

Raw local receipts, stdout/stderr and archive hashes are in
`.data/ascent-fact-policy-046`; `qualification-005.json` records exact identities
and matched inventories. These ignored local assets are not Git-persistent
admission. This is a prepared local build, not cold-build, portable-wheel,
locked-dependency, remote-CI or immutable research-engine qualification.

The default History cardinality problem is closed under the newly authorized
contract. This does not admit Gambit, causal reviews, retry permission or source
refinement. A fresh complete Agentic AI context graph is a separate gate, not
established by these receipts. Persistence remains coupled to successful native
comparison; separating recorded observations from analysis transactions is
still a design, not a feature implemented here. All-phase time/memory enforcement
and arbitrary Scheme callback isolation also remain separate resource work.
