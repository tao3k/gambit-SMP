package GambitRootTaskCRefinement {
  private import ScalarValues::*;
  attribute upstreamCommit:String="9e6f6742c4d9e9915ee8af0dcb7d97cf1f836116";
  attribute header:String="vendor/gambit/include/_gambit/vm_state.h.in";
  attribute consumer:String="vendor/gambit/lib/_mem/collection-round.inc";
  attribute setup:String="vendor/gambit/lib/setup.c";
  attribute test:String="vendor/gambit/tests/gc-root-task.c";
  attribute scope:String="Frozen-origin four-phase root tasks and worker-private destination cursors in the existing collective; physical phase drain still uses that collective. WorkerArena and W scan/R owner-domain service are current C adapter obligations; arbitrary worker migration, whole physical packing, writer admission and general exit recovery remain open";
  part def Operation {
    ref part parent:GambitRootWorkerExit::Replacement;
    attribute id:String; attribute symbol:String; attribute guard:String;
    attribute linearization:String; attribute custody:String; attribute gap:String;
  }
  part freeze:Operation {
    ref part :>> parent=GambitRootWorkerExit::r1; attribute :>> id="freeze";
    attribute :>> symbol="___gc_origin_freeze";
    attribute :>> guard="Existing collective has physically stopped the complete context root writers; descriptor RUNNING; round monotonically advances without wrap";
    attribute :>> linearization="Acquire origin publication gate, initialize round/context under exclusion, release FROZEN; no FROZEN view before its metadata";
    attribute :>> custody="Failed or unknown publication retains origin/root storage; no thaw while a root task remains held";
    attribute :>> gap="The C helper does not prove all foreign writers stopped; replacing the old collective requires the full NativeActivation/borrow inventory";
  }
  part publish:Operation {
    ref part :>> parent=GambitRootWorkerExit::r2; attribute :>> id="publish";
    attribute :>> symbol="___gc_root_task_publish";
    attribute :>> guard="Frozen origin and matching immutable round/incarnation; exclusive task-slot reuse after old readers have drained";
    attribute :>> linearization="Initialize task identity then release READY; descriptor lifetime excludes concurrent reuse";
    attribute :>> custody="Unpublished task stays coordinator-owned; published task stays round-owned even without a carrier";
    attribute :>> gap="New independent registry needs bounded slot/reader grace and stable VM route; current collective supplies slot quiescence only";
  }
  part claim:Operation {
    ref part :>> parent=GambitRootWorkerExit::r2; attribute :>> id="claim";
    attribute :>> symbol="___gc_root_task_claim";
    attribute :>> guard="Published epoch/incarnation/phase and bounded nonzero worker claim key; pinned task slot; cleanup additionally requires explicit original-host eligibility";
    attribute :>> linearization="One CAS replaces READY with an owner-bearing claim word; no second multi-store claimant publication window";
    attribute :>> custody="CAS loser has no root-write authority; unknown winner remains named by the atomic claim, not recreated by another scan";
    attribute :>> gap="Worker-key reuse and lost-carrier recovery require physical-stop and generation receipts, not an idle count";
  }
  part finish:Operation {
    ref part :>> parent=GambitRootWorkerExit::r2; attribute :>> id="finish";
    attribute :>> symbol="___gc_root_task_finish";
    attribute :>> guard="Exact claim holder and phase, matching frozen origin completed that phase's root work and accounted children; root completion is not descendant or round completion";
    attribute :>> linearization="Release CAS from exact owner claim to phase DONE; coordinator acquires after all old-phase users and required descendants drain";
    attribute :>> custody="Wrong/late holder cannot finish another claim; unknown result is queried through task state";
    attribute :>> gap="Private/Tail and weak descendants still need complete source refinement and round termination; no new formal theorem supplied here";
  }
  part advance:Operation {
    ref part :>> parent=GambitRootWorkerExit::r2; attribute :>> id="advance";
    attribute :>> symbol="___gc_root_task_advance";
    attribute :>> guard="Sole coordinator, matching frozen epoch/incarnation, exact immediate predecessor phase DONE; physical phase barrier excludes late readers and strong/weak descendant work";
    attribute :>> linearization="Write next phase under exclusion, release CAS DONE to READY, then next collective barrier admits claimers";
    attribute :>> custody="Held/unknown task refuses advance; old-phase return cannot complete a new claim. Cleanup cannot reopen as prepare within the same epoch";
    attribute :>> gap="C source refinement depends on the actual collective publication/drain contract; no extra QNT or Lean proof is inferred from the native kernel";
  }
  part arena:Operation {
    ref part :>> parent=GambitRootWorkerExit::r3; attribute :>> id="arena";
    attribute :>> symbol="___gc_arena_reserve";
    attribute :>> guard="Worker exclusively owns one actual bounded destination span; requested offset matches private cursor; arithmetic checked before pointer construction";
    attribute :>> linearization="Advance private cursor and record one pending reservation before forwarding; only the same unpublished grant can refund";
    attribute :>> custody="CAS loss cancels only that grant; forwarding visibility retains initialization responsibility; unknown writes deny handoff";
    attribute :>> gap="VM refill and exclusive resume handoff replace the legacy collector cursor adapter; ownerCleanup/domainResume supply selected W<R scheduling, while full physical packing and independent carrier migration remain open";
  }
  part refill:Operation {
    ref part :>> parent=GambitRootWorkerExit::r3; attribute :>> id="refill";
    attribute :>> symbol="refill_worker_arena";
    attribute :>> guard="Exclusive arena writer, no pending grant or handoff; closing old chunk preserves its queue/frontier custody; round has issued the bounded optional stack loan";
    attribute :>> linearization="VM allocator lock removes one physical section from free suffix; if none, consume one private epoch-matched loan without acquiring any context heap cursor";
    attribute :>> custody="Retired copied prefixes remain arena-accounted until handoff. Exhausted or unknown loan cannot be recreated. Reserve failure grants no forwarding or destination-write permission";
    attribute :>> gap="Native workload must actually force refill. Complete pre-flip packing and rejection recovery are separate open obligations; aggregate words are insufficient";
  }
  part handoff:Operation {
    ref part :>> parent=GambitRootWorkerExit::r6; attribute :>> id="handoff";
    attribute :>> symbol="___gc_arena_handoff; move_continuation";
    attribute :>> guard="Weak descendants and physical old writers drained; scan cursor equals allocation tip; no active chunk, pending copy or Tail; same epoch, exclusive unaccepted resume plan";
    attribute :>> linearization="Exclusive non-collecting transfer publishes final section/cursor/limit and retired words to context, then marks arena handed-off and resume accepted before capacity consumers";
    attribute :>> custody="Wrong epoch, pending reservation or duplicate handoff changes no ledger. Source retains unknown transfer; actual physical exclusion, not epoch checking alone, justifies plain stores";
    attribute :>> gap="W tails transfer to W distinct recipients and domainResume covers R-W others. Physical stack-copy receipts do not authorize execution; prepare_mem_pstate, all cleanup results and root thaw still gate final resume. W>R remains unqualified";
  }

  part selectWorkers:Operation {
    ref part :>> parent=GambitRootWorkerExit::r3; attribute :>> id="select-workers";
    attribute :>> symbol="setup_stack_heap_vmstate; restore_loan_words";
    attribute :>> guard="All R allocators and live stack footprints physically frozen; atomic request validated and clamped to current R; every requested nonworker has empty-heap fudge in its bounded stack partition";
    attribute :>> linearization="Coordinator selects actual W before flip and publishes R grants plus W arenas through the setup barrier; deep-stack insufficient-fudge cases use the existing W=R plan";
    attribute :>> custody="No worker acts on the requested value before actual census publication. Insufficient initial physical sections fail before a partial flip; no extra heap is allocated to qualify W<R";
    attribute :>> gap="Restore admission is not a complete copy-object packing proof. Selected native W<R cases do not discharge arbitrary deep-stack or large-object capacity obligations";
  }
  part domainResume:Operation {
    ref part :>> parent=GambitRootWorkerExit::r6; attribute :>> id="domain-resume";
    attribute :>> symbol="___gc_resume_without_arena; move_continuation";
    attribute :>> guard="Root domain has source_worker=-1, same frozen epoch, unused bounded loan, no prior acceptance; all W descendants and writers drained";
    attribute :>> linearization="Initialize empty heap span in the already reserved stack bottom; move active stack on its native owner; publish restored before the all-R restore barrier";
    attribute :>> custody="No arena tail is invented or credited. A duplicate, loaned or wrong-epoch plan refuses acceptance. Resume remains blocked until every R root cleanup task completes";
    attribute :>> gap="Initial restore/fudge capacity must be admitted before flip; arbitrary copy packing and unknown native writers remain external obligations";
  }
  part ownerCleanup:Operation {
    ref part :>> parent=GambitRootWorkerExit::r2; attribute :>> id="owner-cleanup";
    attribute :>> symbol="cleanup_root_domain; free_unmarked_still_objs";
    attribute :>> guard="Actual native owner and context match frozen root task; all R active stacks restored; exact CLEANUP task claim with host token 4+MAX_PROCESSORS+id";
    attribute :>> linearization="Owner claim precedes release callbacks/list sweep; matching completion precedes capacity result and thaw; worker idle count supplies no cleanup authority";
    attribute :>> custody="Inactive collector carriers still service their root domain. Unknown native release completion cannot authorize a second destructor or root thaw. Reentrant native cleanup effects are not newly admitted";
    attribute :>> gap="Native pthread identity and exactly-once releases observed for selected foreign objects; unclassified callback/native-writer effect closure remains open";
  }
  part sweepGeneration:Operation {
    ref part :>> parent=GambitRootWorkerExit::r2; attribute :>> id="sweep-generation";
    attribute :>> symbol="free_unmarked_still_objs; gc_cleanup_escrow";
    attribute :>> guard="Actual native owner, claimed CLEANUP task, OWNER_CLEANUP phase, physically drained W writers and empty prior escrow";
    attribute :>> linearization="Move old head to VM pending before callback; publish native payload/function/inflight before invocation; old survivors stay VM-owned; merge/recount fresh chain on known return before completion";
    attribute :>> custody="Nonreturn leaves pending/survivor/inflight records visible to VM; no slot reuse or callback replay follows from that retention. Normal C error returns do not prove resource disposition";
    attribute :>> gap="Stop evidence, native error escrow/recovery, cross-VM teardown and arbitrary raw writers remain unqualified; there is no new QNT/Lean state machine";
  }
  part nativeRefusal:Operation {
    ref part :>> parent=GambitRootWorkerExit::r0; attribute :>> id="native-refusal";
    attribute :>> symbol="garbage_collect; call; run; alloc_scmobj_still; cleanup";
    attribute :>> guard="Participant is non-RUNNING at entry; actual owner service is not an executable GVM activation; no incomplete view may begin a nested collective or managed frame";
    attribute :>> linearization="GC/call/run return failure before own collective/register/marker/catcher effects; collecting allocation returns error before publication; same-carrier cleanup returns before setup/interrupt/resize effects";
    attribute :>> custody="Existing source/fresh chains and registered roots remain in owner/VM custody. The endpoint gate cannot undo earlier generated SFUN_ARG or raw native payload stores";
    attribute :>> gap="Baseline run public declaration omitted PSD while definition and function table included it. Current ABI must match all three and the real caller, with preserved pre-entry observations";
  }
  part cleanupSlot:Operation {
    ref part :>> parent=GambitRootWorkerExit::r8; attribute :>> id="cleanup-slot";
    attribute :>> symbol="setup_pstate; gc_cleanup_empty; setup_vmstate";
    attribute :>> guard="A reused participant has no pending/survivor/inflight/native identity; fresh VM initialization is exclusive and follows the existing setup lifetime contract";
    attribute :>> linearization="Reject nonempty cleanup escrow before sync, incarnation or context binding mutations; initialize all fresh fixed descriptors before any thread can borrow them";
    attribute :>> custody="Unknown or interrupted release cannot be erased by PSTATE setup. This does not permit arbitrary reinitialization of an active VM or prove a global shutdown grace period";
    attribute :>> gap="Direct/cross-VM teardown and native user closure remain source obligations; fixed record capacity does not bound retained native/object memory";
  }
  part nativeRunAbi:Operation {
    ref part :>> parent=GambitRootWorkerExit::r0; attribute :>> id="native-run-abi";
    attribute :>> symbol="runtime_forwards.h.in::run_function; runtime_protocols.h.in::run; global_state.h.in::run; setup.c::typed forward,run";
    attribute :>> guard="Same configured PSTATE propagation mode, public declaration/definition/function table share PSD; independent actual-header C consumer must compile the expected function-pointer type";
    attribute :>> linearization="Caller passes exactly the configured native parameters before endpoint phase checks; correct ABI is a prerequisite, not a receipt produced by a later guard";
    attribute :>> custody="A mismatched ABI can interpret thunk as PSTATE and crash before any custody gate; reject at compile-time and retain the real native failure, rather than treating it as a GC proof or typed result";
    attribute :>> gap="Darwin explicit-PSTATE mode is actually qualified here; unrelated target modes require their own native ABI validation. QNT/Lean control proofs cannot discharge compiler-level parameter fidelity";
  }
  part copyAuthority:Operation {
    attribute :>> id="copy-before-reserve";
    attribute :>> symbol="memory_state.h.in::msection.copy_gate; vm_state.h.in::gc_copy_acquire,gc_copy_release; copy-reservations.inc::require_fromspace_copy_source,mark_array";
    attribute :>> guard="Complete stopped-root collective; source header remains in admitted fromspace. Gate and revalidation precede arena reserve/refill. Captured stack-frame forwarding remains under frame access";
    attribute :>> linearization="Gate acquisition serializes the reservation/header-publication fragment; successful forwarding CAS publishes identity, not initialized payload. Release precedes payload copy and all child/Tail execution; READY follows full initialization";
    attribute :>> custody="Copy winner owns pending interval and initialization/Tail even after forwarding is visible. Duplicate contender retries through the forwarded branch without requesting destination space. Unknown copier exit retains the round, never clears a gate on timeout";
    attribute :>> gap="This source strengthening removes managed losing-attempt section waste only. Existing QNT copy_custody histories and Lean RoundCapacity packing obligations are reused. Successful packing tails, source census, native bypass and stop recovery remain independent premises; selected GCC acquire loads do not establish every legacy backend";
  }
  part writerAuthority:Operation {
    ref part :>> parent=GambitRootWorkerExit::r0; attribute :>> id="write-authority";
    attribute :>> symbol="write_authority.c/.h; vm_state.h.in::write_authorities; setup.c::write_authority_init_vmstate; tests/write-authority.c; tests/gc-root-task.c";
    attribute :>> guard="Live VM/storage borrow; fixed registered actor and exclusive delegated role; generation is checked without wrap; current source has exactly one write_authority family and no old-name aliases";
    attribute :>> linearization="One full-word CAS couples generation, closed, spent and live permits. Handoff requires closed and drained and installs both owner permits atomically; release follows the actual last store/borrow and preserves the spent bit";
    attribute :>> custody="Unknown writer retains its live permit. Duplicate release is idempotent; stale generations cannot clear later permits; exhausted identity or capacity rejects. A failed join cannot manufacture a last-use receipt";
    attribute :>> gap="This record carries no Scheme payload, GC-root registration or physical-stop proof. Existing QNT native_scope_gate history and Lean NativeScopeGate encoding duties are reused without new models; connecting every generated/foreign writer remains open";
  }
  part sourceRequest:Operation {
    ref part :>> parent=GambitRootWorkerExit::r3; attribute :>> id="source-request";
    attribute :>> symbol="prepare_copy_request; reserve_copy; commit_copy; cancel_copy";
    attribute :>> guard="Heap section claim or captured-frame access already held; source interval wholly inside frozen old half; no earlier pending request; exact round epoch and destination length";
    attribute :>> linearization="Full-barrier CAS publishes immutable source coordinates before any arena refill. Arena grant changes prepared to reserved. Known commit/cancel settles arena before clearing request";
    attribute :>> custody="Unknown stop retains request plus any grant; both worker drain checks reject it. Source interval is not sufficient to replay forwarding, payload copy or Tail. Duplicate forwarded contenders create no request";
    attribute :>> gap="Lean interval/source-size refinement requires actual heap and effective frame coordinates; global injective census, packed placement, physical source retention and common refusal remain open. QNT owns request/unknown histories only";
  }
  part closeRc:Operation {
    ref part :>> parent=GambitRootWorkerExit::r1; attribute :>> id="close-rc-root-domain";
    attribute :>> symbol="close_rc_roots; mark_rc; reopen_rc_roots";
    attribute :>> guard="Same context gate covers membership, payload, refcount and scan; close occurs before ROOTS_FROZEN; native releases own a live incoming reference";
    attribute :>> linearization="Closed flag publishes under gate before collective freeze; mark_rc requires closed under that gate; reopen follows final all-R drain and RUNNING";
    attribute :>> custody="Borrowed cells remain registered during GC and are updated by scanner. Closing does not wait for borrow count. Live borrow prevents context cleanup; raw aliases and VM lifetime must be excluded independently";
    attribute :>> gap="Existing host-root QNT covers closure scheduling; Lean stable-cell mapping owns root coverage. No new proof that unknown native exits stopped writing or that global shutdown is safe";
  }
  part sfunBorrow:Operation {
    ref part :>> parent=GambitRootWorkerExit::r0; attribute :>> id="sfun-root-borrow";
    attribute :>> symbol="make_sfun_stack_marker; borrow_rc_root; make_sfun_stack_marker_from_root; return_rc_root";
    attribute :>> guard="RUNNING same-owner context; valid incoming Scheme object or owned C closure; stable cell registered before allocating marker; current SDK consumer for BOOL payload-store status";
    attribute :>> linearization="Borrow increments cell refcount and domain debt under gate; gate releases before allocation; marker reloads updated root. Known normal return pays borrow after last root use";
    attribute :>> custody="Failed registration/store leaves source owned or frees only its fresh native block. Unknown nonlocal exit retains cell/debt. Marker root fix is not activation-wide conversion/stack-store or concurrent trampoline admission";
    attribute :>> gap="Process-global c_closure_self and foreign ClientData first-read/delete arbitration remain open. Native tests cover selected actual callers, not all public-ABI consumers. Existing QNT/Lean retain disjoint duties";
  }
  part sfunInputBank:Operation {
    ref part :>> parent=GambitRootWorkerExit::r0; attribute :>> id="sfun-input-bank";
    attribute :>> symbol="begin_sfun; alloc_rc_roots; BEGIN_SFUN_ARG_SCMOBJ; check_sfun; sfun_arg; call_sfun; sfun_error; end_sfun";
    attribute :>> guard="RUNNING same-owner context; noncollecting bank initialization publishes root_count only after all cells are false. Generator emits every raw SCMOBJ parameter declaration before collecting converters. Max argument count and actual stack interval are checked";
    attribute :>> linearization="Raw argument store acquires context gate. Converters execute with registered inputs and no held root-store lock. After marker allocation, the complete parameter batch reloads current bank values and writes under that same gate, then unlocks before Scheme entry";
    attribute :>> custody="All three wrapper forms keep procedure, raw inputs, converted arguments and error data/handler live. Known end invalidates marker and pays RC borrow/owner debt after converter cleanup; unknown physical escape retains the chain/debt and cannot authorize replay or teardown";
    attribute :>> gap="Existing host_roots_contract QNT is updated for pre-marker conversion, close/drain and reload schedules. HostRootsRefinement owns span/data mapping; no new Lean proof. PSTATE migration, process-global closure selection, arbitrary C aliases and compiler traversal corruption remain open";
  }
  part thaw:Operation {
    ref part :>> parent=GambitRootWorkerExit::r6; attribute :>> id="thaw";
    attribute :>> symbol="___gc_origin_thaw";
    attribute :>> guard="Matching epoch/incarnation, CLEANUP root task DONE and external whole-round resume authority; all scanner reads ended";
    attribute :>> linearization="Release FROZEN to RUNNING only after acquiring the completed task and physical restore plan";
    attribute :>> custody="Held/unknown task prevents root mutation/recycle; host join supplies no substitute receipt";
    attribute :>> gap="Existing collective still supplies whole-round/resize result and native-user closure; unknown exit is retained rather than recovered by this kernel";
  }
  part def NativeCase { attribute id:String; attribute purpose:String; }
  part c0:NativeCase { attribute :>> id="publication"; attribute :>> purpose="Frozen metadata, epoch mismatch, premature thaw and no-wrap admission"; }
  part c1:NativeCase { attribute :>> id="claim-race"; attribute :>> purpose="Real concurrent C claimers obtain one owner; mismatched completion cannot retire it"; }
  part c2:NativeCase { attribute :>> id="arena"; attribute :>> purpose="Actual intervals, exhaustion, private rollback and reservation identity; bounds under sanitizer"; }
  part c3:NativeCase { attribute :>> id="bootstrap"; attribute :>> purpose="Full two-pass Gambit bootstrap under the existing source/profile, no repair patches imported"; }
  part c4:NativeCase { attribute :>> id="scheme-control"; attribute :>> purpose="Real map/wide-root multi-shot continuation, GC and natural shutdown under the unchanged watchdog/heap"; }
}
