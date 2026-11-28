/* Model-owned writer-inventory declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpWriterInventory {
 private import GambitSharedHeapSmp::*;

 part taskMetadataReadersWriters:AccessFamily {
  attribute :>> id="taskMetadataReadersWriters";
  attribute :>> pattern="(?:task->|->task[.]|(?:->|[.])(?:vm_task|symkey_task|global_task|stack_task|bank_task)[.]|tasks[^;]*->)(?:origin|executor|epoch|state|scan_leases)";
  attribute :>> role="task metadata read/write candidates";
  attribute :>> guard="Every observed task validates and updates under its published source metadata owner; standalone confined tasks retain their existing worker-only scope. Root/shard completion requires global-before-source when both guards are used.";
  attribute :>> publication="Initialize private tasks before exposure; publish CLAIMED/SCANNING/SCANNED/DONE and lease changes with the same reader/writer discipline, plus epoch/incarnation validation on reuse";
  attribute :>> release="Do not extend a metadata lock across scanning or waits; a frozen topology lease must separately retain every RC node and source slot. A finished task does not retire its source.";
  attribute :>> knownCallers="root-tasks init/matches/fresh/publish_confined and every RC/VM/bank/stack/symkey/global wrapper; root_round begin/freeze/publish/scan/finish/end/refuse; rc-roots mark_rc; root-origins four scan adapters; continuation-roots scan_stack; rc-allocation setup/reopen/cleanup";
  attribute :>> gap="Lexical candidates include comments and unselected branches and may miss macro/alias/whole-struct writes. The reviewed function chain and actual backend/input closure remain required; a match count is not writer completeness.";
  attribute :>> acceptance="Audit all guards and last uses by function, then real-C delayed scan/query/finish/refusal and metadata publication controls under R3 W2; preserve all five joint gates";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=packetGlobalTaskGuard;
 }
 part rootControlLastUsers:AccessFamily {
  attribute :>> id="rootControlLastUsers";
  attribute :>> pattern="rc_unlink_if_dead|rc_can_close|idle_activation|activations|lifecycle_marker_(?:prepare|abort|kill)|lifecycle_(?:enter|leave|close_context)|return_rc_root|release_rc|cleanup_rc";
  attribute :>> role="root/control last-reader and reuse candidates";
  attribute :>> guard="Short route lookup hands lifetime to a VM/source-local observer grant before lookup ends. Activation/list/idle-slot readers and writers share source exclusion; distinct access, scan, query and retained installation owners cannot substitute for one another.";
  attribute :>> publication="Known installed result and ACK identity persist before source-root release; cleanup reserves exclusive retirement under the gate and performs root returns/free outside it before final reuse publication";
  attribute :>> release="No unlink/free during frozen chain, active query or unknown writer use. Close new admission and drain local readers; never hold a global registry reader across GC or pending ACK and never wait under the gate for an observer that needs it.";
  attribute :>> knownCallers="rc-allocation release/return/unlink/cleanup/reopen; vm-registry lifecycle enter/leave/marker prepare/abort/kill; vm-lifecycle terminal close/cleanup/dispose; generated END_SFUN and startup root ACK";
  attribute :>> gap="Current execution-entry admission requires PSTATE and is not observer-role lifetime. Owner-only activation lists and zero-refcount checks have no current query-pin/frozen-chain guard. External callbacks and conditional teardown branches remain explicit source obligations.";
  attribute :>> acceptance="Real query versus owner cleanup/idle reacquire, delayed/lost ACK replay, last RC release during scan, known refusal, next-epoch reuse and unknown stop; distinguish actual last-use evidence from elapsed time";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=packetActivationObserverRetirement;
 }

 part rootLibScope:InventoryScope {
  attribute :>> 'id'="rootLibScope";
  attribute :>> 'path'="vendor/gambit/lib";
  attribute :>> 'suffixes'=".c;.h;.scm;.inc";
  attribute :>> 'exclude'="_*.c";
  attribute :>> 'boundary'="Native C, Scheme producers and include fragments; underscore-prefixed C remains excluded until admitted producer/artifact proof; no binary branch activation is inferred";
  ref part :>> adapter=freezeAdapter;
 }
 part rootIncludeScope:InventoryScope {
  attribute :>> 'id'="rootIncludeScope";
  attribute :>> 'path'="vendor/gambit/include";
  attribute :>> 'suffixes'=".h;.h.in";
  attribute :>> 'exclude'="";
  attribute :>> 'boundary'="All public/generated-header templates and register/foreign/atomic variants; actual configure/preprocessor selection remains open";
  ref part :>> adapter=freezeAdapter;
 }
 part rootGeneratorScope:InventoryScope {
  attribute :>> 'id'="rootGeneratorScope";
  attribute :>> 'path'="vendor/gambit/gsc";
  attribute :>> 'suffixes'=".scm";
  attribute :>> 'exclude'="";
  attribute :>> 'boundary'="Compiler source producers only; generated C/object/cache outputs need independent exact producer and artifact acceptance";
  ref part :>> adapter=freezeAdapter;
 }
 part rootExampleScope:InventoryScope {
  attribute :>> 'id'="rootExampleScope";
  attribute :>> 'path'="vendor/gambit/examples";
  attribute :>> 'suffixes'=".c;.h;.scm";
  attribute :>> 'exclude'="";
  attribute :>> 'boundary'="Bundled embedding/callback examples only; external user/plugin/native JIT code is not a closed finite inventory";
  ref part :>> adapter=freezeAdapter;
 }
 part generatedRoots:AccessFamily {
  attribute :>> 'id'="generatedRoots";
  attribute :>> 'pattern'="SFUN_ROOT_ARG|SFUN_ARG|BEGIN_SFUN|END_SFUN|BEGIN_CFUN|END_CFUN|SET_STK|ST_ARG_REGS";
  attribute :>> 'role'="generator/entry";
  attribute :>> 'guard'="Raw Scheme inputs carry a preexisting parent/source root loan before registration; register before first local collecting conversion and publish complete live caller frame before ACK";
  attribute :>> 'publication'="Producer emits root declarations before conversion and canonical slot reload before final frame store";
  attribute :>> 'release'="Every normal/error/unwind path keeps result roots and releases once after last use";
  attribute :>> 'knownCallers'="gsc/_ptree2.scm c-make-function/root-arguments; _t-c-2.scm stack location emitters; include foreign_conversion and register macros";
  attribute :>> 'gap'="Concatenated names, arbitrary c-code and unqualified generated C are not resolved by text matches";
  attribute :>> 'acceptance'="Audit entire emitter/macro/consumer variants; reject stale producer products; existing full compilation and root-entry fixtures must match current source";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=foreignRootEmitter;
 }
 part bankAndStackRoots:AccessFamily {
  attribute :>> 'id'="bankAndStackRoots";
  attribute :>> 'pattern'="___(?:PSR[0-9]+|PSSELF|PSSTK|FP_SET_STK|SET_STK|VM_SCMOBJ|PROCESSOR_SCMOBJ|CONTINUATION_(?:FRAME|DENV)_FIELD)\\b|->temp[1-4]\\b";
  attribute :>> 'role'="mutator/root-bank";
  attribute :>> 'guard'="Current execution authority and complete frame; every actual Scheme-bearing scratch/error slot has an explicit live range";
  attribute :>> 'publication'="Final bank/stack/denv/processor stores precede frozen-view release; no concurrent semantic store during scan";
  attribute :>> 'release'="Do not release source/restore authority until each required canonical slot is rewritten and reloaded";
  attribute :>> 'knownCallers'="gvm_registers.h.in; stack_operations.h.in; setup.c ___call; _kernel.scm reflection; continuation-roots.inc";
  attribute :>> 'gap'="Physical address expressions or a struct layout do not classify root liveness; comments and reads are candidates too";
  attribute :>> 'acceptance'="Cross-check generator liveness, FrameSpec and scanner spans; test GC at native/error/restore boundaries without extra heap or waits";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=bankRootMacros;
 }
 part rcRootAccess:AccessFamily {
  attribute :>> 'id'="rcRootAccess";
  attribute :>> 'pattern'="___(?:alloc_rc|alloc_rc_no_register|register_rc|addref_rc|release_rc|set_data_rc|try_set_data_rc|data_rc|borrow_rc_root|return_rc_root|addref_scmobj|release_scmobj|still_obj_refcount_inc|still_obj_refcount_dec)\\b";
  attribute :>> 'role'="native/root-list/borrow";
  attribute :>> 'guard'="Registered node lifetime and refcount distinct from active data-access permission; current owner or declared native byte owner";
  attribute :>> 'publication'="RC source mutex serializes membership, payload and scan; park native data access before collector update";
  attribute :>> 'release'="Last payload use then return borrow; unknown native activity retains node/domain/gate even after logical exit";
  attribute :>> 'knownCallers'="rc-allocation.inc; still-refcount.inc native Scheme-object holds; setup.c resize/launch root slots; c_intf.c marker/conversion wrappers; Tcl ClientData";
  attribute :>> 'gap'="data_rc returns a snapshot and borrowed h->data remains mutable by GC; still-object count changes affect strong-root production outside the RC task; indirect pointers and raw aliases need explicit audit";
  attribute :>> 'acceptance'="Enumerate definitions/calls/exports/aliases and nested exceptions; nonzero processor RC and actual native borrow/GC PBT; no source pass from a counter";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=rcBorrow;
 }
 part globalAndSymkeyRoots:AccessFamily {
  attribute :>> 'id'="globalAndSymkeyRoots";
  attribute :>> 'pattern'="___(?:store_global|try_store_global|store_primitive|bind_primitive|primitive_ref|global_cell|GLO|PRMCELL|intern_symkey|new_symkey)\\b|root_writer_open|symkey_table_set";
  attribute :>> 'role'="global/template/symkey";
  attribute :>> 'guard'="Managed ordinary/primitive stores use actual VM authority; bootstrap and shared immutable templates have separate admission";
  attribute :>> 'publication'="Acquire/release payload publication plus global gate/count/page snapshot; close every mutable writer across affected VMs";
  attribute :>> 'release'="VM-local override slots and shared metadata remain pinned through scanners and old readers";
  attribute :>> 'knownCallers'="global-bindings.inc; symbols.inc; root_globals_begin; root-origins mark_global_cell and symkey tables";
  attribute :>> 'gap'="Atomic stores and immutable code templates do not prove all metadata or bootstrap mutations closed";
  attribute :>> 'acceptance'="Audit single/multi-VM and bootstrap/runtime variants, count/pages snapshot, symbol growth and last-use; native matching source-family acceptance stays separate";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=globalRootStores;
 }
 part nativeActivationRoots:AccessFamily {
  attribute :>> 'id'="nativeActivationRoots";
  attribute :>> 'pattern'="___(?:BEGIN_TRY|END_TRY|THROW|throw_error|propagate_error|make_sfun_stack_marker(?:_root)?|kill_sfun_stack_marker|call|run|lifecycle_[a-z_]+)\\b";
  attribute :>> 'role'="native-entry/reentry/exception";
  attribute :>> 'guard'="VM admission and pre-registration caller/source root protection precede payload access; installed roots, activation lineage and native data access remain independent authorities";
  attribute :>> 'publication'="Marker allocation consumes preprotected roots; reentry acquires rewritten source slots and current binding views";
  attribute :>> 'release'="TRY/catcher/continuation escapes discharge or transfer marker/result/entry/borrow debt exactly once";
  attribute :>> 'knownCallers'="foreign_conversion.h.in; c_intf.c; setup.c ___call and ___run callers; vm-registry.inc";
  attribute :>> 'gap'="A syntactic END_SFUN or catcher does not prove nonlocal continuation cleanup or physical native stop";
  attribute :>> 'acceptance'="Audit every result/void/conversion/error/nested callback variant; original native roots, multishot and lifecycle tests/PBT with exact source";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=foreignRootMacros;
 }
 part bulkReferenceAccess:AccessFamily {
  attribute :>> id="bulkReferenceAccess";
  attribute :>> pattern="\\bmemmove\\s*\\(|___(?:SUBVECTSMALL|VALUESSET|VECTORSET|VECTORELEM)\\b|prim-subvect-(?:move|fill)!";
  attribute :>> role="bulk-layout-and-publication";
  attribute :>> guard="Layout-qualified source/destination lifetime and no conflicting unqualified writers; reserve metadata before destructive writes";
  attribute :>> publication="Enrolled physical span plus incoming-edge commit before cut close/drain";
  attribute :>> release="Known data-write closure, complete chunk progress and canonical roots before resume/retire";
  attribute :>> knownCallers="_std#.scm macro producer; vector/vector.scm instances; gvm_operations.h.in; object-allocation.inc; stack growth; setup; Tcl vector writes";
  attribute :>> gap="All matches including numeric bytes, metadata and reads are candidates; actual macro/generated source and extension effects remain unqualified";
  attribute :>> acceptance="Classify complete eligible inventory by pointer layout and private/visible/update ownership; real overlap/movement/overflow/unknown-exit histories";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=boxedBulkMove;
 }
 part nativePointerAccess:AccessFamily {
  attribute :>> id="nativePointerAccess";
  attribute :>> pattern="___(?:SCMOBJ_to_(?:NONNULL)?POINTER|POINTER_to_SCMOBJ|FOREIGN_(?:PTR|TAGS|RELEASE_FN)_FIELD|BODY_AS|data_rc|borrow_rc_root|return_rc_root)\\b";
  attribute :>> role="native-address-and-root-validity";
  attribute :>> guard="Classify external pointer, copied bytes, canonical RC cell, Scheme value and derived heap address before access";
  attribute :>> publication="Native/root install ACK and access parking are separate from native reference-count lifetime";
  attribute :>> release="Every late callback/raw reader/writer and effect outcome settled or retained; no release from timeout";
  attribute :>> knownCallers="c_intf conversions; sfun-entry.inc; setup resize/start roots; Tcl call/create/delete and Scheme payload reload";
  attribute :>> gap="Patterns do not determine pointee layout, alias escape or arbitrary extension behavior; all branches and comments remain lexical candidates";
  attribute :>> acceptance="Bind selected extension set and compiled branches; qualify raw access/exception/last-use; refuse unsupported affected movement without changing valid sharing";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=nativePointerConversion;
 }
 part takeControlAccess:AccessFamily {
  attribute :>> 'id'="takeControlAccess";
  attribute :>> 'pattern'="\\b(?:take_heap_chunk|unlock_chunk_fifo|end_heap_chunk|require_chunk_transition|scan_complete_heap_chunk|chunk_gate_?|heap_chunks_to_scan(?:_(?:head|tail))?_?|active_scan_chunk_?|scan_origin_?|chunks_(?:claimed|completed)_?)\\b";
  attribute :>> 'role'="collector/queue-effect-delivery-and-diagnostic";
  attribute :>> 'guard'="Actual mem.c TU and selected provider; one enrolled operation retains candidate, queue and outer storage; source-closed writer exclusion before partial settlement";
  attribute :>> 'publication'="Intent precedes mutation; outcome precedes accepted private scan/ACK; busy is not empty; diagnostic counters confer no claim authority";
  attribute :>> 'release'="Every source effect, log, query and native postlude retains a named custodian until slot/round/provider grace; no free/reset from pointer return or IDLE alone";
  attribute :>> 'knownCallers'="heap-sections.inc take/end/reset; object-scanning.inc own-FIFO and scan_complete; collection-round.inc victim/phase; collector.h fields; mem.c inclusion order";
  attribute :>> 'gap'="The retained take-access-review classifies all 82 declared matches in 9 files at its exact source digest, including 6 legacy processor declarations; this is source-context review only. Dynamic/unqualified clients and alternate preprocessing paths are not proved covered";
  attribute :>> 'acceptance'="Bind exact per-TU provider evidence, review both take callers and every counter/queue access, then execute the complete existing native/PBT packet; lexical matches and model passes never close source refinement";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=chunkClaim;
 }
 part collectorRootWriters:AccessFamily {
  attribute :>> 'id'="collectorRootWriters";
  attribute :>> 'pattern'="___(?:root_round_[a-z_]+|root_task_[a-z_]+|ROOT_[A-Z_]+)\\b|\\bmark_(?:registers|saved|type_cache|processor_scmobj|vm_scmobj|rc|global_[a-z_]+|symkey_tables)\\b";
  attribute :>> 'role'="collector/relocate";
  attribute :>> 'guard'="Claimed epoch-bound scan lease and frozen source; census must not perform mutation";
  attribute :>> 'publication'="Acquire frozen roster; collector alone updates authoritative slots; release completion after required rewrites";
  attribute :>> 'release'="Task DONE is local scan completion; whole round includes copy/Tail/weak/restore/required cleanup before re-admission";
  attribute :>> 'knownCallers'="root-tasks.inc; root-origins.inc; rc-roots.inc; continuation-roots.inc; collection-round.inc";
  attribute :>> 'gap'="Local EMPTY/queue-empty/one DONE and collector frame gate cannot certify whole producer/physical-layout closure";
  attribute :>> 'acceptance'="Trace all six sources, W-to-R assignment, refusal and restore; existing source/algebra premises and native worker/root manifests remain mandatory";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=bankRootScanners;
 }
 part exitAndForeignOwners:AccessFamily {
  attribute :>> 'id'="exitAndForeignOwners";
  attribute :>> 'pattern'="___(?:thread_join|cleanup_pstate|cleanup_vmstate|rc_prepare_cleanup|rc_cancel_cleanup)\\b|\\b(?:cleanup_rc|pthread_join|scheme_call_cmd|scheme_delete_cmd|Tcl_DeleteCommand|Tcl_DeleteInterp)\\b";
  attribute :>> 'role'="lifecycle/native-client";
  attribute :>> 'guard'="Close new entries and callback admission before physical teardown; retain every queued/in-flight/unknown access";
  attribute :>> 'publication'="Known stop and last-reader ACK precede source/gate/PSTATE destruction; unknown outcome is retained";
  attribute :>> 'release'="Detach byte-only RC owners only after Scheme payload/root debt is settled; owner-affine effects execute outside the GC wait";
  attribute :>> 'knownCallers'="vm-lifecycle.inc; memory-lifecycle.inc; os_thread.c; setup.c partial launch/rollback; Tcl command callbacks";
  attribute :>> 'gap'="No complete general recovery proof for arbitrary interrupted native calls; user/plugin writers lie outside the source tree";
  attribute :>> 'acceptance'="Trace all setup failures, accepted/rejected launch, callback deletion and join outcomes; healthy independent VM GC and same-heap unknown-writer refusal must both hold";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=lifecycleRootExit;
 }
 part publicationAndStops:AccessFamily {
  attribute :>> 'id'="publicationAndStops";
  attribute :>> 'pattern'="___(?:RC_LOCK|RC_UNLOCK|MUTEX_LOCK|MUTEX_UNLOCK|WORD_(?:LOAD_ACQUIRE|STORE_RELEASE)|SHARED_MEMORY_BARRIER)\\b|\\b(?:BARRIER|barrier_sync_(?:noop|op))\\b";
  attribute :>> 'role'="memory-order/stop";
  attribute :>> 'guard'="Configured threaded backend and correct population incarnation; no-thread definitions qualify no SMP behavior";
  attribute :>> 'publication'="Final source writes -> release publish -> acquired claim -> relocation -> released completion -> acquired reentry";
  attribute :>> 'release'="Source mutex and edge/ACK buffers remain alive until all old readers/borrowers are known quiescent";
  attribute :>> 'knownCallers'="rc.h; activity_log.h.in; setup.h BARRIER; setup.c tree synchronization; root-round entry/end";
  attribute :>> 'gap'="A compiler fence, interrupt request or elapsed timeout is not stopped-data-access evidence";
  attribute :>> 'acceptance'="Review every supported backend and exact selected macros/collective edges; source proof plus native memory-order/entry regression under existing profiles";
  ref part :>> adapter=freezeAdapter;
  ref part :>> site=barrierRootPublication;
 }
}
