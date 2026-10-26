from pathlib import Path
import json,hashlib,re,ast
from gambit_smp import workspace,work_process
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
ENTRY_ROLES={4249:'captured-continuation-ref',4294:'frame-run-inclusive',4316:'frame-run',4420:'rc-data',4489:'will-action-testator',4492:'will-action',4513:'hash-key',4519:'hash-value',4529:'symbol-name',4534:'continuation-fields',4583:'heap-frame-return-label',4604:'closure-free-vars',4611:'heap-fields-skip-first',4613:'heap-fields',4638:'pair-fast-cdr',5734:'will-list-1',5740:'executable-will-testator-1',5750:'will-list-2',5760:'executable-will-testator-2',5770:'nonexec-will-testator',7231:'registers',7246:'saved',7261:'type-cache',7276:'processor-object',7294:'VM-object',7335:'global',7364:'VM-register-segment',7384:'symbol-table',7385:'keyword-table'}
HOOKS=[
 dict(surface='sender',file='lib/_thread.scm',lines=[1439,1451,1454,1455,1459,1460,1461],events=['ISSUE','PROPAGATE_RETURN','WAIT2_ENTER','WAIT2_RETURN','CONSUME_OR_ERROR']),
 dict(surface='route',file='lib/_thread.scm',lines=[1467,1484,1487,1488,1495,1507,1510,1517,1519,1520,1521,1530,1534,1536,1538],events=['ROUTE_ENTER','ROUTE_DECISION','QUEUE_COMMIT','ROUTE_UNLOCKED','OTHER_NOTIFY']),
 dict(surface='processor-queue',file='lib/setup.c',lines=[425,436,438,440,442,444,448,450,453,457,469,471,473,475,479,481,484,487],events=['H_APPEND_BEGIN','H_APPEND_COMMIT','H_POP_BEGIN','H_POP_TO_DISPATCHER']),
 dict(surface='dispatch',file='lib/_thread.scm',lines=[1542,1550,1568,1569,1570,1571,1572,1573,2877,2894,2895,2898,2905,2906,2907],events=['DISPATCH','REROUTE','ACTION_START','ACTION_RETURN','ACTION_ERROR_OR_ESCAPE']),
 dict(surface='result-and-wake',file='lib/_thread#.scm',lines=[1681,1785,1790,1792,1795,1797,1798,4303,4314,4315,4316,4318],events=['RESULT_STORED','UNLOCK_ENTER','UNLOCK_RETURN','T_POP_TO_DISPATCHER']),
 dict(surface='terminal-and-restore',file='lib/_thread.scm',lines=[1744,1779,1780,1781,1812,1815,2877,2890,3324],events=['TARGET_END','ABANDON','RESTORE','MIGRATION_OWNER'])]
REPORT='''# Current-lock minimum diagnostics: first scan load and one pending request

2026-10-24, Asia/Shanghai. Implementation-ready diagnostic instructions only. No runtime/generator/qualifier/history edits, native execution, other-thread operation, commit or push in this turn. The authority is main `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` plus cohort-ack-rc lock SHA `c5b2e0bd4db5b8b99dee274d3d5cfbdec8df387eb7ca9d4df4b6d971a3b8686d` / patch `3597ad3f5dd3223ad54f567bc9b542741812c2623bf0abda3e0b9b4b2359c7c7`. Companion JSON binds the current33-file candidate and exact source statements. All coordinates below are this candidate, not historical c86/vendor/TFIB coordinates. Existing classification QNT is reused; unchanged models are not rerun.

## Minimum scope and two outputs

Use the existing bounded diagnostic-carrier idea, not a new scheduler, queue, coordinator or lifecycle mechanism. Produce (1) a committed pre-load scan record associated with the faulting native instruction and (2) a stable-ID trail for the actual sender still waiting at result-mutex lock2. Record observations only: no route changes, replay, extra yield, select timeout, queue repair, bad-word skip, stronger root retention or new Scheme error suppression.

There is no current diagnostic CLI to invoke for either complete record. Grok must add the hooks below, regenerate the correct SMP C, and validate their emitted ordering/coverage. Giving a command that pretends these hooks already exist would be misleading.

## What exists and what does not

| Current source/probe | Established coverage | Missing for this diagnosis |
| --- | --- | --- |
| `mem.c:3838..3881 check_gc_write_target / CHECK_GC_WRITE_TARGET / GC_CELL_WRITE` | Darwin+GCC and not Clang only; checks selected GC write targets against msection header region, prints GC-HEADER-WRITE-DENY and aborts on that condition. Selected callers include forwarding/header/frame writes. | It returns for targets outside the known arena and does not validate all writes/reads, allocation generation or compiler maps. It runs after the original header read on that path, so cannot record `mark_array:3945` fault context. Its logging/abort is not a crash-surviving pre-cell/header record. Do not enable Clang and assume this probe remains active. |
| `gambit.h.in:11529..11536`, `mem.c:331..333,3920..3922,4452..4455` | Conditional debug fields reference_location_, container_body_, mark_array_call_line_; some callers set origin/body. | No selected cell/raw presence, dynamic tail parent, complete frame map, run identity or crash carrier. Pair fast path can bypass scan's context. Debug printing dereferences object headers/fields and must not be used to pretty-print a corrupt pointer. |
| Current mem.c | Original read at3930 and header read3945; tail target4023..4026/4045;29 direct mark_array call expressions enumerated in JSON. | No gc_origin or gc_diag implementation in this file. Historical build7's partial carrier is a different mem.c and not inherited by the current lock. |
| Current Scheme result-mutex path | Vector `[next,result-mutex]`, mutex.name=thunk, mutex.specific=target then result. Correct exclusive target-current branch; both H and T dequeue clear slot0. | No stable request serial, request-specific last owner or complete six-surface record. Existing aggregate counters do not identify R. |
| Source-package `_kernel.c:12380..12386` | Actual RA-store/W_ALL/service/R_ALL/RA-load for the old wrapper. | Does not cover new helper locals/maps or issue a request/scan diagnostic record. |
| Source-package `_thread.c:14320..14352,19061..19085` | Resume calls vector slot1 as a procedure with one argument; other-interrupt accepts procedure payloads only. These bodies match non-SMP Scheme6564..6575 and7720..7735, not the SMP mutex/thunk paths2877..2911/1542..1574. New participation helpers/migration are absent. | This source-package C cannot certify the current SMP diagnostics or mutex root map. This is not evidence any completed native producer compiled these stale/non-SMP bodies. Regenerate under the real SMP configuration and bind the result before interpreting labels. |

## A. First faulting scan: exact hooks and fields

### Place hooks around original operations, not around a guessed bad pointer

| Placement | Capture using already available locals | Required rule |
| --- | --- | --- |
| `___garbage_collect_pstate:7692` after actual entry/admission; setup/cleanup at5042/5177/5589/5607 | Run/session, explicit VM incarnation, pstate/native owner, local diagnostic GC sequence, actual strong/weak phase, configured word/tag ABI and code identity. | Initialize bounded storage outside hot scanning. Do not derive a bootstrap P0 ID from an uninitialized ps->vmstate; unavailable identity disables attribution. Local GC sequence is not a cross-worker clock, scheduler epoch or nb_gcs statistic. |
| Every direct mark_array entry (JSON29-call table) | Stable call-site role; original entry start/count; caller-supplied root/parent/frame context version. | Set origin at caller, before entry. Do not infer it from the latest generic debug variable or current return address alone. |
| `mark_array:3924..3930` after selecting `cell`, before `obj=*cell`; also every `again:3928` | `attempt_seq`, `CELL_PENDING`, cell, original span, current span/index/role and context version; `raw_present=false`, `target_header_present=false`. | Commit before the original cell load; recording must not read `*cell` itself. Preserve the first selected attempt if that load faults. |
| `mark_array:3930..3945` after original cell read/tag acceptance and body computation, immediately before original `head=body[-1]` | Same attempt ID; `HEADER_PENDING`, original tagged obj bits, compiled tag rule, computed header address, `raw_present=true`; retain target-header absence. | Commit before header read; never inspect that target header for the record. If the original code validates earlier under ENABLE_CONSISTENCY_CHECKS3940..3941, bracket that earlier hazardous access too or record it as a different uncovered PC. |
| After successful header read3945 | Existing local head/type/subtype/words, with presence flag if needed. | Optional success completion, not proof of a prior invalid read. Never move the original dereference or skip invalid input. |
| Tail conversion `mark_array:4023..4032,4045` | When cell becomes alloc, preserve destination body base, the original `head`/word count before words decrements to0, copy completion and field0 index; preserve outer root origin separately. | Update current parent/span/role before goto again. The next field is inside the copied object; outer start/n and original frame map are not its current container. Do not read the destination header again merely for diagnostics. |
| Pair fast path `scan_and_advance:4634..4643` | Macro's already-known ptr/head; body=ptr+1, selected cdr cell=ptr+2, pair extent. | Set a pair-fast context here because scan() is bypassed. Keep the pair body index distinct from a whole-body scan. |

### Root/frame/heap context table

* `scan:4437..4617`: preserve already-read head, body, words/subtype and selected branch/run. Intact scalar cases4470..4473 must still skip payload. For `sFRAME:4538..4583`, selected GC-map payload and separate return-label `&body[0]` are different roles.
* `mark_frame:4253..4330`: preserve input fp/fs, raw/actual RA from caller, link, current gcmap plus the map-word source/index, j/i and run start/count. Inclusive4294 scans `FP_STK(fp,i)` for `i-j+1`; exclusive4316 scans `FP_STK(fp,i-1)` for `i-j`. `FP_STK(fp,k)=fp[-k]` (gambit.h.in6763). A pointer-range check does not prove this is a current frame/map.
* `mark_continuation:4334..4401`: record ps->fp/stack_break, ra1 at4360, actual_ra if RETI4368, fs/link/gcmap/nextgcmap after the original decode4369/4374, adjusted fp and ra2. Preserve presence/absence if a descriptor load itself faults; do not add a speculative nextgcmap dereference. Log map-word changes only after the original reads4298/4322.
* `mark_captured_continuation:4090..4249`: keep orig_ptr, ptr, cf, fp, ra1/actual_ra, fs/link, source/destination and copied frame extent when those original reads/copies finish. The alternate4249 entry has its own continuation-reference role. This does not imply the copy path decoded a GC map; heap-frame scanning decodes that separately.
* RC4420 records the actual `&h->data` cell, not a cached Scheme value. Registers7231, saved7246, type cache7261, processor7276, VM7294, globals7335, VM segment7364 and symbol/keyword7384..7385 get their actual cell interval and role. Will/hash/closure/generic fields in the29-entry table receive their own role. Do not scan native diagnostic words as Scheme roots.

### Bounded carrier and strict acceptance

Proposed record field names (not existing runtime fields): common `{schema,run_nonce,vm_id,pstate_id,native_owner,owner_generation,local_gc_seq,attempt_seq,ctx_seq,stage,commit_seq,coverage_flags}`; context `{origin_kind,entry_site,entry_start,entry_words,current_kind,parent_body,parent_head_present,parent_head,parent_words,selected_start,selected_words,cell_index}`; frame `{fp_raw,fp_adjusted,stack_break,ra1,actual_ra_present,actual_ra,fs,link,map_word,map_word_source,map_word_index,j,i,frame_generation_present}`; operation `{cell,raw_present,raw_word,header_address,target_header_present,target_header}`. Set frame/allocation-generation presence false when no existing trustworthy source supplies it. In particular parent_head is an already-read containing object's header, not permission to read the failing target_header. Native address fields are copied bits, never dereferenced by the postmortem reader.

Use preallocated shared bytes with separate native-owner/pstate slots, complete context records and pre-load records. Capture only raw integers/pointers already available; those addresses are forensic observations, **not new GC roots**. Include version, presence bits, process/run/binary/VM identity, native-owner mapping, local sequence, context version and commit footer. At least retain a previous complete record while publishing the next; context storage referenced by a record must remain matched and complete. Capacity, reentry, overflow or unknown allocation generation must be explicit UNAVAILABLE states, not silently reused identities. Initialize/close once at the existing owned diagnostic lifecycle; no syscall/alloc/lock/printf/pretty printer per scanned cell and no new signal handler.

Release-storing a footer alone is **not** proof that a following faulting load cannot execute before the record is visible. Require compiler and target CPU store-before-load ordering for the actual fault site (a reviewed full fence/compiler barrier if needed), inspect the final object disassembly, and prove carrier survival with an isolated deliberate-fault control under the same producer configuration. Historical CAS codegen controls prove neither this ordering nor Darwin mapping persistence. Record-to-IPS native-thread correlation must be established using a proven mapping captured outside the scan; do not equate pthread_t with an IPS thread ID.

Accept a fault association only when binary/UUID/native PC, faulting owner, record phase, sequence/context and commit agree. A new diagnostic binary changes instruction offsets/register allocation: match its actual cell/header load, not old `mark_array+104` or x25 by fiat. On CELL_PENDING at the cell load, raw is unavailable. On HEADER_PENDING at the header load, raw exists but target header does not. A timeout's latest record is merely a last attempt, not a proved faulting operation. Freeze/classify after the owned process group is quiescent; another worker's later record is not this fault.

Output is the first **captured faulting scan operation on that worker**, not the earliest globally corrupting write. Classify ROOT/FRAME/HEAP/PAIR/EXTENT/UNKNOWN only from valid current context. F64-looking bits alone do not select a class. First writer remains unknown until allocation generation, overlap and causal-before evidence exist; do not add broad write tracing in this first stage.

## B. Stable request R: keep existing routing and mutex semantics

### Minimum identity choice

For this diagnostic only, add an immediate nonwrapping request serial as a **third metadata element of the private result-mutex request vector** in `##thread-intr!:1451..1453`. Preserve slot0 next, slot1 result-mutex, mutex.name thunk and mutex.specific target/result exactly. Session/VM incarnation prefix lives in the diagnostic session header. This is not the previously failed attempt to use slot2 as another queue link; slot2 must never be used by queue mutation or admission.

Issue the serial before publication, outside queue locks. Keep it live in the sender until WAIT2_RETURN/RETURN_OR_ERROR and in dispatcher Scheme locals until callback/result/unlock exit, so post-GC/migration records keep the same logical ID. Generic procedure interrupts retain their original representation; C hooks may read metadata only for a validated private mutex request with the expected vector length and valid registered serial. No unconditional slot2 read on ordinary two-element requests. Audit all vector construction/size consumers before selecting this diagnostic layout; reject the diagnostic interpretation on mismatch without changing the original request's behavior.

This avoids the existing plan's private mutex.name wrapper and its extra thunk/name/error-display projections. Do not implement both representations. Adding one metadata word can still change GC timing: regenerate maps and validate overhead under the existing budget. If serial/capacity is exhausted, mark coverage incomplete and continue the original semantics; do not reject, replay or block the request to save the recorder. Physical node/mutex addresses are samples only; ID is not an address.

Nested callbacks get separate request IDs. START/RETURN for the outer ID remain tied to its live Scheme activation even when it yields/migrates. Do not keep the current request in unrooted TLS or infer a parent from whichever native processor last ran it. Parent identity may be absent in this minimum cut; mark parent_present=false rather than invent ancestry. Opaque nonlocal exits leave an unfinished record. Supported error/abandon is recorded from the actual existing exit, not a diagnostic finally that changes behavior.

The minimum recorder adds no exception catcher. If the original throw/abandon site cannot carry a trustworthy serial, retain the R record as unfinished and mark that terminal correlation unavailable; do not recover identity from an old mutex address after GC or fabricate CONSUME_OR_ERROR. An error self-test may correctly yield this explicit incomplete trail while preserving the original exception. This limitation does not prevent identifying a genuinely blocked WAIT2 sender in a complete successful/queued path.

### Six existing surfaces rebased to this lock

| Surface / exact source | Minimum events and existing fields | Placement / last use |
| --- | --- | --- |
| Sender `_thread.scm:1439..1461` | ISSUE id/target/current sender/result-mutex; PROPAGATE_RETURN1455; WAIT2_ENTER before1459; WAIT2_RETURN after1459; sender release1460 and final read1461/error. | Distinguish initial lock1454 from sender lock2. Keep ID until actual return/error. Propagate return is not delivery. |
| Route `_thread.scm:1467..1540` | Entry current node/id; target/thread-last-P; after1484/1487 restored object value; live-member/running1495; H/T choice; head/tail/next before and after mutation. | Record QUEUE_COMMIT while the existing owner lock still protects final fields, before1519/1520 or1538 unlock. Record notify separately at1521, not as a reply/ownership transfer. Never replay or change route. |
| P queue `setup.c:425..490` | Enqueue intr/tail/head/slot0 before/after438..448; dequeue current head/next at471..479, clearing slot0 and tail. | A pop transfers the exact ID into dispatcher ownership before queue unlock/return. Capture copied raw fields inside the existing P lock; emit completed nonblocking record without new locking or root retention. C enqueue is not the only path: Scheme running branch1507..1517 bypasses this function. |
| T queue / dispatch `_thread#.scm:4303..4319`; `_thread.scm:1542..1574,2877..2911` | T_POP after detach to Scheme local; source route H/T; DISPATCH target/current; REROUTE; ACTION_START immediately before thunk; ACTION_RETURN immediately after actual return. | Both consumers must retain ID/node/mutex live across thunk, GC and migration. Do not change exclusive branch or manufacture a return event for a thrown/nonreturning thunk. |
| Reply/unlock `_thread.scm:1571..1572,2906..2907`; `_thread#.scm:1785..1798`; `_thread.scm:1000,4020..4119` | RESULT_STORED with id/mutex/result-presence; UNLOCK_ENTER/RETURN; actual BTQ transfer/wake/owner fields. | Result store precedes potential heap check/lock participation. Record return after real unlock helper returns, never at entry. Detailed wake mutation is needed only for a missing R whose store/unlock already occurred; do not turn this into all-mutex logging. |
| Terminal/restore `_thread.scm:1744..1817,1819ff,2877..2890,3315ff` | Real target termination/abandon, actual restore/migration owner and any sender-supported error. | Do not label target termination alone a successful reply; correlate real mutex/BTQ abandonment. Preserve unknown if the continuation escapes without the existing error path. No diagnostic handler may swallow the exception. |

The existing pending request needs a bounded active-record slot indexed by its stable ID/generation, not just a rolling last-event counter overwritten by other completed requests. Store accepted H/T/dispatcher/action/result phase, last committed transfer/hop, native actor and diagnostic completeness. A slot cannot be reused while that R or its dispatcher/result consumer is unfinished. This record is observational; it does not own/keep alive the Scheme request or enforce runtime ownership. Capacity overflow marks UNKNOWN and must not acquire a queue lock or change scheduling. Completed history can be bounded; late stale IDs remain distinguishable from newly issued IDs.

Proposed request event fields: `{request_serial,hop_seq,event,src_owner,dst_owner,native_actor,node_bits,mutex_bits,target_bits,current_thread_bits,head_bits,tail_bits,next_bits,parent_present,coverage_flags,commit_seq}` plus the common session/VM identity. Supporting wait fields are `{wait_seq,intr_enabled,sync_flag,other_flag,deadline_present,deadline_bits,return_present,return_code,errno_present,errno}`. Claim/commit diagnostic record writers nonblockingly; if an observational slot is busy/torn or the platform primitive would block, mark dropped coverage and perform the original runtime operation. Do not put a new mutex/spinning wait on the hot path. H/T transfer records are captured before the real owner unlock; consumer records follow the real acquire. Per-actor counters and timestamps alone are not a causal transfer ACK, and post-unlock logging must not overwrite a newer owner as the authoritative current phase. Validate full event/transfer identity offline, otherwise UNKNOWN.

For the park branch, add only supporting actor snapshots: `setup.c:491..499` intr_enabled and relevant intr_flag; `##wait!:2682..2698` entry/return with P/device/timeout; scheduler3150..3154 unlock/wait/service; `os_io.c:11703..11723` actual converted deadline/devices; original native wait entry/return in device_select936ff and existing abort write1553 with its **actual return/errno**. Save errno before recording can clobber it; do not retry or repair this write in the diagnostic change. Add an actual-WAIT_RETURN event; SYNC service does not imply select returned. These snapshots correlate to the actor/hop, not to every request through a global current-R pointer.

No signal/sample/debugger is necessary for this minimum cut. On the owned run's existing watchdog termination, read the shared carrier after that group is quiescent and locate R from a committed WAIT2_ENTER without its matching return/error. The last complete record then determines the edge below. If ID records or coverage were lost, say UNKNOWN; aggregate counters cannot reconstruct R.

## C. Generated C gate before any original workload

Regenerate the changed `_thread.scm`/`_thread#.scm` and any altered `_kernel.scm` with the actual lock-bound compiler/header/SMP configuration; bind generated files, compiler flags, objects/lib/gsi SHA/UUID and diagnostic schema in producer B. Static source-package `_thread.c` is not the output to patch by hand. Stop if the real SMP `thread-intr!`, propagate, mutex dispatch and participation bodies are not emitted (or if inlining prevents proving equivalent edges).

For each call edge, inspect the **new** return label, frame size/space, saved STK/register values, selected map bits and reloads:

* Sender: mutex/request/target through creation and propagate; serial/mutex through lock2 and result read.
* Route: node/mutex/thread/last-P across sync participation at1484; values actually used by splice after collection must be current, not a cached C address.
* Both dispatchers: request/mutex/serial plus resume-thunk where live across thunk; result remains rooted through mutex.specific and all emitted heap-check/participation edges before unlock.
* Probe helpers: no Scheme allocation, safepoint, callback, lock or native pointer dereference introduced by decoding raw diagnostic metadata; Scheme metadata creation/argument evaluation remains subject to normal root maps. W_ALL/R_ALL is an executed save/restore requirement where native GC is possible, not a declaration-only proof.
* Error paths: ID/carrier writes cannot overwrite the actual Scheme result/error or force a normal return. A nonlocal escape does not execute the ordinary after-call event.

Translate generated STK offsets through the actual ADJFP/frame-space convention before mapping them to `FP_STK` ordinals. The old five-label map study is a historical control only; never copy its offsets/maps into B's evidence. Inspect final assembly for scan commit-before-cell/header access and Scheme event order. Extra source-level c-code calls alone prove neither ordering nor liveness.

## D. Direct Grok sequence and judgment table

1. Freeze the current lock/candidate plus diagnostic-only delta and preserve the last known binary. Choose **one** producer B with both minimal recorders and correct generated SMP C. Keep routing, scanner, heap limits/topology and error semantics unchanged. Verify all old third-vector-element/length assumptions, generated roots and native record ordering before launch.
2. Validate record completeness with isolated existing fault-injection/self-test facilities: distinguish controlled cell-load fault from header-load fault; verify shared bytes remain after the owned child exits and match its PC/native owner. Test stale/torn/overflow/reentry records yield UNKNOWN. Test one synchronous request, early reply, nested request, migration+GC, supported exception/abandon and ordinary procedure interrupt so the metadata slot is not read on the wrong node shape. There is no claim these tests are currently wired or passed.
3. Rehash the same B and run original TFIB `(go 15 5000)` through the existing harness/settings/budget (driver p1, recorded test child11); small workloads remain smoke. Then run unchanged interrupt2/interrupt stress and exact retained flood fixture under its own original caps. Do not relink B or mix lastq/5620/9eca outputs between rows. On watchdog read only the owned run's records after quiescence. Retain all failures and instrumentation-budget overruns.
4. Stop diagnosis as soon as the following accepted cut exists; change only its implicated mechanism in the next producer. Do not first implement a wider handoff protocol or add all-allocation writer tracing. No full inventory launch, qualifier edit or9/12 declaration follows from this research.

| Accepted evidence | Judgment / immediate next inspection |
| --- | --- |
| HEADER_PENDING + exact new header-load PC/owner + valid root/RC/register cell context | Actual root path; inspect owner/GC update and post-GC value used. Still not first-writer proof. |
| Same fault + valid FRAME context and selected ordinal/descriptor | Frame route; compare exact B generated return label/map and live frame generation. Do not equate this with a compiler-map bug automatically. |
| Same fault + heap/pair current parent/span | Actual field route; F64 only if valid observed header/branch supports that classification. Investigate upstream header/bounds/write after identifying this allocation. |
| CELL_PENDING + exact cell-load PC | The cell dereference failed; raw/header are unavailable. Do not use previous HEADER_PENDING. |
| Stable R waiting, complete owner census proves no queue/transfer/dispatcher/action/result owner | Ownership/link loss. Inspect committed predecessor/slot0 mutation and duplicate-live-node precondition. Head-empty alone does not satisfy this row. |
| Stable R reachable in H, actor parked with OTHER masked/no real wait-return | Wake/park obligation; not link loss. Inspect publish/notify/backend-return. |
| Stable R reachable in T but target never claims/starts | Run queue/resume/routing issue; inspect actual member migration and current-thread transitions. |
| Stable R popped/dispatcher-owned but no START | Dispatch/reroute gap. Empty queues here are normal ownership. |
| START but no actual RETURN/ERROR | Callback/escape branch; incompatible with calling the same R 'never executed'. |
| RESULT_STORED, no real UNLOCK_RETURN; or unlock returned but sender not runnable/reacquired | Narrow to result root/unlock/BTQ/sender wake. Match actual generated label and GC occurrence. |
| Only raw float-looking bits, stale record, another owner, timeout/latest attempt, missing ID or overflow | UNKNOWN. No causal repair selected. |

Native diagnostics remain unimplemented/unverified in this evidence turn. This document specifies the exact minimum missing observations and their acceptance rules; it does not count metadata assertions or earlier QNT controls as a successful native fault capture. Recorded status remains8/12.
'''
def run():
 idx=json.loads((E/'drain-sync-closure-contract.json').read_text());s=json.loads((R/idx['sourceReceipt']).read_text());c=R/s['candidate']
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/current-lock-diagnostics');out.mkdir(parents=True)
  assert sha(R/idx['lock'])==idx['lockSha256'] and sha(R/idx['patch'])==idx['patchSha256']
  for f,h in s['files'].items():assert sha(c/f)==h,f
  for f,h in idx['protectedInputs'].items():assert sha(R/f)==h,f
  mem=(c/'lib/mem.c').read_text();lines=mem.splitlines()
  actual={i+1 for i,z in enumerate(lines) if re.search(r'\bmark_array\s*\(',z) and not z.lstrip().startswith('#define')}
  assert actual==set(ENTRY_ROLES),(actual^set(ENTRY_ROLES))
  assert '___WORD obj = *cell;' in lines[3929] and 'head = body[-1];' in lines[3944]
  assert 'gc_origin' not in mem and 'gc_diag' not in mem
  assert '#if defined(__APPLE__) && defined(__MACH__) && defined(__GNUC__) && !defined(__clang__)' in lines[3837]
  assert 'abort ();' in lines[3871] and 'write' not in lines[3944]
  generated=(c/'lib/_thread.c').read_text();kernel=(c/'lib/_kernel.c').read_text()
  assert 'sync_2d_participation' not in generated and 'migrate' not in generated
  other='\n'.join(generated.splitlines()[19060:19085]);resume='\n'.join(generated.splitlines()[14319:14352])
  assert '___PROCEDUREP' in other and '___FIX(11L)' not in other and '___FIX(11L)' not in resume
  assert '___JUMPGENNOTSAFE(___SET_NARGS(1),___R3)' in resume
  assert '___W_ALL\n\n   service_sync_op (___PSPNC);\n\n   ___R_ALL' in kernel
  for hook in HOOKS:
   a=(c/hook['file']).read_text().splitlines();hook['statements']={str(i):a[i-1] for i in hook['lines']}
  entries=[dict(file='lib/mem.c',line=i,role=role,statement=lines[i-1]) for i,role in ENTRY_ROLES.items()]
  audit=dict(schema='current-lock-minimum-diagnostics.v1',lock=idx['lock'],lockSha256=idx['lockSha256'],patch=idx['patch'],patchSha256=idx['patchSha256'],sourceReceipt=idx['sourceReceipt'],sourceReceiptSha256=sha(R/idx['sourceReceipt']),candidate=s['candidate'],sourceHashes=s['files'],scanEntryCount=len(entries),scanEntries=entries,requestHooks=HOOKS,existingProbe=dict(function='check_gc_write_target',range=[3838,3881],compileGuard='Darwin GCC non-Clang only',coverage='selected writes into known msection header regions; not first-invalid scan read'),generatedShape=dict(threadC=sha(c/'lib/_thread.c'),kernelC=sha(c/'lib/_kernel.c'),archivedOtherRange=[19061,19085],archivedResumeRange=[14320,14352],shape='procedure-only, corresponding to non-SMP Scheme bodies; not proof of a produced native image'),newDiagnosticFieldsImplemented=False,nativeExecutions=0,runtimeChanged=False,qualifierChanged=False,historyChanged=False,commitOrPush=False,protectedInputs=idx['protectedInputs'])
  doc=E/'current-lock-minimal-diagnostics.md';doc.write_text(REPORT)
  index=E/'current-lock-minimal-diagnostics.json';index.write_text(json.dumps(audit,indent=2)+'\n')
  verifier=E/'verify-current-lock-diagnostics.py';verifier.write_text(Path(__file__).read_text());ast.parse(verifier.read_text())
  additions=[(E/'README.md','\n- [Current-lock minimum diagnostics](current-lock-minimal-diagnostics.md):29 current scan-entry roles, six rebased request surfaces, actual probe coverage, non-SMP source-package C gap, and one-producer diagnostic acceptance.\n'),(E/'repair9-failure-causal-alignment.md','\nImplementation detail: [current-lock minimum diagnostics](current-lock-minimal-diagnostics.md) rebases both missing evidence cuts to the current source and generated-C boundary. Existing write-target guards are not pre-load scan recorders; old procedure-only C does not certify new SMP mutex paths.\n'),(R/'docs/current-repair-research.md','\n### 2026-10-24 Current-lock minimum scan/request diagnostic cut\n\nThe [diagnostic handoff](../evidence/research/smp-retirement-study/current-lock-minimal-diagnostics.md) binds all33 current candidate files, enumerates all29 mark_array entry roles and rebases the six request evidence surfaces to exact statements. Existing Darwin/GCC-only check_gc_write_target guards selected writes into msection headers; it does not capture original cell3930/header3945 reads. Current mem.c has no gc_origin/gc_diag recorder. Source-package thread C14320..14352/19061..19085 has procedure-only resume/other bodies corresponding to non-SMP Scheme, not the current SMP result-mutex implementation; no produced-gsi regression is inferred. Grok must generate/bind actual SMP C, then verify root maps and native record-before-fault ordering. Minimal observational request ID is an immediate third metadata element of private result-mutex vectors; next/payload/mutex name/specific/routing remain unchanged, and generic procedure nodes require safe discrimination. No extra queue link or mutex-name wrapper is prescribed. Report defines pre-cell/pre-header/current-tail/frame presence fields, exact event/last-consumer placement, partial-carrier UNKNOWN rules, one-producer original workload order and accepted diagnosis table. No native execution, model rerun, runtime/qualifier/history/Recipe/peer/commit/push action. Recorded8/12 remains.\n')]
  for f,text in additions:
   if text not in f.read_text():
    with f.open('a') as stream:stream.write(text)
  for f,h in s['files'].items():assert sha(c/f)==h,f
  for f,h in idx['protectedInputs'].items():assert sha(R/f)==h,f
  files=[doc,index,verifier,E/'README.md',E/'repair9-failure-causal-alignment.md',R/'docs/current-repair-research.md']
  (out/'receipt.json').write_text(json.dumps(dict(schema='current-lock-diagnostic-publication.v1',files={str(f.relative_to(R)):sha(f) for f in files},candidateFilesVerified=len(s['files']),scanEntriesVerified=len(entries),requestSurfaces=len(HOOKS),protectedInputsUnchanged=True,nativeExecutions=0,modelReruns=0),indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':run()
