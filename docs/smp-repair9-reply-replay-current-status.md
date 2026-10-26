# Repair 9: two reply-replay branches, current repair and native correspondence

2026-10-23. Research only; native acceptance **8/12**. No source repair, native execution, signal/debugger/peer operation or push was performed by this audit.

## Current answer: the two branches have been corrected

A stable read cut `f4af8764be9042eba08349dfbfddae59` now contains the proper three-argument `if` in **both** mutex arms of `##other-interrupt!`: target=current executes/replies; target≠current propagates. The current generated C success paths return to their loops and do not propagate. This chat did not make that runtime change. The file contents establish that a correction landed in the shared workspace; they do not identify the actor through chat inspection.

The earlier defective snapshot `863e886c…` remains historical evidence. Its Scheme SHA was `481c2a0f…`, C `ae2f27f6…`; each target conditional lacked an else, with propagation as the next enclosing expression. Its generated C success paths fell into propagation. The current Scheme diff against those exact saved bytes has **only two hunks**, each moving one close parenthesis from the end of `mutex-unlock!` to the end of the propagation branch. No action, expected result, lock API, timeout, GC/header layout or fixture change is needed for this local correction.

Do not apply the already-landed correction a second time. This conclusion is scoped to the saved stable cut; later edits require their own identity.

## Scheme, generated C, object and actual executable files

| Layer at the stable read | SHA-256 / identity | What was checked |
|---|---|---|
| Current `_thread.scm` | `f987f557cb0678f8a9d7183cf6e0a8260014e3c7c8eb46e10df8cdadf8daa48c` | Both target-current conditionals have one exclusive else; no unconditional following propagation. |
| Current `_thread.c` | `52bd0c33e15e0484ba35442da3f25e3677ff0de931cfb64dbb31ffc3be64ed7f` | Both stored-result/unlock paths rejoin their drain loops; propagation remains on target-mismatch paths. |
| Current `_thread.o` | `98889408a6330f678b507bcceafb4850b1c0ba7822fbd4a46a907826cb72a658` | Static thread-host function extent and internal transfer signature captured. |
| Main `gsi/gsi` | `9eca674b79248987e67d458c9acce7941149f428616caf0aff5defdc93e49d78`; UUID `1bcb0a1c-fa73-33e6-8647-f744ca756d24` | Still the exported origin generation, not the current changed Scheme/C. Its original processor handler never had this newly introduced candidate replay edge. |
| Scratch `gsi/gsi.lastq` | `48fe88b579279fbc93319964c03cce3570e3bde6c84f53051c0cd2da47faa761` | Distinct executable, copied and hashed without running. Its thread-host internal transfer signature matches current object. |

All nine selected inputs had stable inode/size/mtime during each read and matching reread digests across the capture interval. This is an observed stable byte cut, not a completed producer receipt. No new successful build-8 or current full-inventory receipt was found in the narrowly inspected fixtures listing; no broader claim about all scratch runs is made.

The binary comparison uses Mach-O sections/symbols and arm64 instruction words, not execution. In `_thread.o` and scratch gsi, `____H___thread` is 128,460 bytes and has 5,122 same-position internal branch/indirect-transfer entries. Their signature is `a1d3d6ad5324fdd089772f2bd1ae09d38a46b40811a0848a4c9c99426a115e0c`. Main origin gsi has 127,216 bytes, 5,074 entries and a different signature. External relocations/data-address instructions are excluded by the signature definition.

This is concrete machine-code correspondence between object and scratch for that function's inspected transfer signature. It is **not** full binary equivalence, cryptographic C-to-object provenance, an execution test, or a proof that the corrected scratch matches the first-eight/full native inventory. We did not execute `gsi`, attach to it or inspect another thread's conversation.

## The two corrected branch paths

The `other-interrupt!` C procedure has local label numbering within this current source cut; numbers from the bad snapshot must not be reused.

| Site | Successful action/result/unlock | Target mismatch |
|---|---|---|
| Newly added current-thread queue drain | Callback L2 stores mutex field 11; fast/contended unlock rejoins L12, then drain loop. Slow unlock return L3 also goes to L12. | A distinct branch calls `thread-intr-propagate!`; it is not fall-through after success. |
| Existing processor high-level queue loop | Callback L9 stores field 11; unlock rejoins L23; slow unlock return L10 also goes to L23. | Separate mismatch branch L27 invokes propagation. |

Current callback return descriptors retain the mutex at `STK(-6)`: frame size 5, space 8, scanner ordinal 2 selected by map `0x3` in both callback cases. This is source-map coverage at these points; it is not proof of every native live range or earlier memory integrity. The leading Scheme macro heap check is still not an emitted check directly between result storage and primitive lock. The earlier generated-C correction remains in force.

The local minimal repair is only the exclusive branch structure. A shared action-dispatch helper, new request metadata or global once flag would expand the change unnecessarily. A global "already executed" flag would in particular conflate distinct requests and valid nested actions.

## Once means different things on normal and exceptional paths

- Normal queued request: action runs once, result is stored once, terminal reply is published once, caller consumes once. A receiver mismatch may reroute **before** action execution.
- Early reply: caller may acquire a reply already unlocked; no wake is needed. Zero wakes does not mean zero replies.
- Target terminates before dispatch: zero action executions and zero normal result stores can be correct; one supported abandoned-mutex error completes the wait.
- Target terminates after action entry: normal result storage is not required; abandonment is distinct from callback success.
- A callback catches its own error and returns a value: one ordinary result/reply. This does not imply the dispatcher installs a universal catcher.
- Unresolved Scheme continuation escape or raw C unwind: no successful reply may be invented. The model retains an unfinished outcome and forbids restarting the old action merely to obtain a reply.
- Migration: an old execution owner cannot run the same action after transfer; destination restore retains the request identity. Migration does not create a second reply entitlement.

The maintained QNT now tracks action executions, normal result writes and reply publications separately. Safety enforces at-most-one counts; explicit normal/exceptional trajectories show the required exact counts for completed modeled paths. The finite model does not prove delivery under arbitrary native scheduling or C memory behavior.

New decoded mutations specifically require witnesses for a second execution, second reply, reporting target abandonment as normal success, execution by the old owner during transfer, and opaque-exit replay. These supplement the existing post-reply propagation mutation, early reply, root, ID, nested-context and final-consumer controls. The original trace where a reply is repropagated remains retained; the new source audit marks the later correction rather than erasing it.

## Impact on the first eight gates

The first eight are cumulative contracts, not a reusable certificate for every modified scratch binary. For the **two-branch correction alone**, the intended effect is to restore the original execute-or-reroute semantics; the surrounding last-processor placement, running scan, queue drain and yield edits are a separate, larger footprint and cannot inherit that narrow argument.

| Gate | Expected local impact / material risk | Required same-producer evidence, not run by this audit |
|---|---|---|
| 1 bootstrap | No header/layout change, but Scheme-generated labels, maps and linker tables must stay coherent. | Regenerate affected Scheme C/link artifacts through existing producer flow; preserve exact input identities. A scratch link alone is not complete bootstrap. |
| 2 complete-gsi | Fix removes invalid post-result propagation. Procedure-targeted interrupts, direct same-thread action and ordinary evaluation should keep prior behavior; surrounding candidate changes may still affect scheduling. | Original complete interpreted inventory, errors and natural exit. |
| 3 pr-regressions-gsi | Interrupt, mutex/abandon, nested callback, migration and join behavior are directly relevant. | Exact original PR inventory, including failure history, original expectations/topology/limits. |
| 4 complete-gsc | A branch-only Scheme repair still changes generated code and return-label tables. Static coverage does not establish compiler/native equivalence. | Complete compiled inventory with matching runtime/compiler and generated artifacts. |
| 5 pr-regressions-gsc | Same semantic risk as gate 3 through compiled continuations/FFI. | Complete declared compiled PR inventory. |
| 6 stress-gsi | Avoids one concrete duplicate dispatch; it does not prove the intermittent interrupt flood or TFIB fault resolved. | Original sustained stress and resource reuse, zero skips, original processors/deadlines. |
| 7 stress-gsc | Concurrent generated execution can expose stale owner/root/queue bugs independent of this branch. | Original compiled stress, same candidate, no SIGSEGV/stalls. |
| 8 registry-lifetime | Local diff does not edit registry/admission fields; callbacks and pending async/cleanup consumers still exercise its boundaries. | Existing declared registry/reuse/lifetime controls and native campaign; no broader scope or automatic PASS. |

The old TFIB crash binary was separately bound to the earlier producer. This newer candidate defect and its correction do not explain or close that earlier failure. Likewise, these source/native-read controls do not turn the unchanged failed full-inventory route into a justified rerun. A causal completed producer plus the existing admission/budget rules remains necessary for native qualification; this audit does not initiate it.

## Decision

The two exclusive branches are already corrected in the current saved Scheme/C; scratch machine-code correspondence is materially stronger than a filename or timestamp. No duplicate repair is needed from this chat. Remaining work is to bind any claimed successful native outcomes to that corrected producer and to identify the actual still-blocked request/other memory fault under the existing contracts. Model/static results are not 12/12.
