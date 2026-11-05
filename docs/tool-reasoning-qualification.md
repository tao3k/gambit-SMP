# Tool reasoning qualification and remaining gates

The current implementation is caller-owned declarative Evidence DSL, not Python
tool-selection inference. GCC/Clang compiler classification is an explicit
source-bound mapping of the receipt's exact compiler name, not a default or
inference from the inspection tool's brand. The actual GCC16.2 fixture is
historical and not renamed into the latest Working repair candidate.

The registered view and Working action-context expose compiler context, known
options, rationale, missing premises, existing observations, conflicts and
provenance gaps. Open-world choice_scope and exploration_window outputs make
non-exhaustiveness explicit even for no matching tool, an empty catalog, a new
caller question or unknown compiler. No ranking, compulsory tool, fixed sequence
or requirement to register an idea before investigation is introduced.

## Fixed Library

Repository publication lock: revision c8c3c8b4dc3bd5fa4c290dc258646915fdc1b69b;
wheel SHA ea64372276c89ac5e76cb8baf5c4a598a5bc33f9a5c22dfc34524b685afb9da6;
extension SHA 1e88c4000dabb94c63d953535e265633b6b2734c093381f3e25d2d71648011a5.
The real installed Rust build has186 complete source inputs and matches the
publication lock. Shared .venv was rejected for a mismatching wheel; it was not
modified or bypassed. Qualification uses an isolated temporary environment.

## Actual observations

* Initial tool061-001:6 tests,2 errors from incorrect test-owner construction
  and missing host authorization. Neither production gate was weakened.
* Tool061-002:6 tests passed2.111s/15. Tool061-003:6 passed3.177s/15 after adding
  exact compiler-name classification, rationale and conflict/unknown outputs.
* Final open-world001:8 tests/0skip passed1.313s/15, actual exit0, no timeout,
  quiescent group. Tests use the real locked Library. Empty catalogs, novel
  questions, caller-defined tools, source withdrawal/restoration, retained-owner
  updates/close, provenance and build conflicts are distinct controls.
* Final open-action001: actual production-history discover/select/observe,
  1.244s/15, exit0/no timeout/quiescent, inspection CURRENT and outcome RECORDED.
  Its real snapshot exposes the four open-world scope statements, seven
  exploration windows and ten known examples. It is not graph qualification.
* Tool061-004:14 tests including actual installed CLI passed3.517s/15. This
  precedes the final open-world addition and is not relabeled final coverage.
* Real Working Action discover/select/observe:2.760s/15,16 actions,10 known
  tool options/10 rationale rows/28 missing premises/no declared-ready tools;
  CURRENT inspection, exact source hashes, RECORDED only. This also predates
  the explicit open-world outputs; retain its original snapshot.
* Consumer001 timed out at15s. Parallel consumer002 retained the correctly
  rejected shared Action history race. Final tool tests isolate only SQLite
  storage, not inference, results, permission or identity checks. A separate
  actual production-history Action invocation remains part of qualification.

All local launch receipts, available stdout/stderr and snapshots remain under
the tool-reasoning-061 .data/.cache directories. These local logs are not claimed
as Git-archived admission. No tool execution capability or herd7 run is claimed.

## Complete graph remains unqualified

Full001 was refused by the current output-location contract. Full002 used the
required .cache output but hit the original300s whole deadline; its child
inventory1581/0skip reported2 failing identities and18 errors, while ordinary
unittest counted3 failures including two subtests. Original logs are retained.
Sealed105 passed41.204s/60; it does not cover the full failure.

The18 errors exposed old temporary test roots without Git initialization after
the cache contract became repository-root based. Tests now initialize real
temporary Git repositories; production has no non-Git fallback. Focused source
materialization11 and stage journal12 passed; combined consumer003 still timed
out its retry-gate lane under the unchanged15s total deadline. It is not PASS.

Full003 produced a graph with framework ERROR: old seal no longer matched
concurrent ascent_program/framework changes. Full004 used new engine
a2ae6900ddf8c56b95957cee965783d839c6be75e7439e8715e1202b65e6cb81,
but again timed out at300s; its partial logs include action/input and loaded
implementation drift and the remaining dated-fixture naming failures. No old
Library, old framework pass or local component result substitutes for a final
CURRENT/PASS graph. The final open-world change is newer than those runs.

The old Working thread is archived; a concrete coordination message was refused
and no thread was unarchived. No SubAgent, timeout increase, source deletion,
authority bypass or automatic commit/push was used. Full current-graph closure
and latest-candidate source correspondence remain open.
