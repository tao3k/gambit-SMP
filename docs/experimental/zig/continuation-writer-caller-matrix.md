# Captured Graph: Selected Writer and FFI Caller Matrix

The [JSON inventory](continuation-writer-callers.json) records actual selected
caller chains, source groups and bounded lexical observations. Read the
[design](continuation-writer-closure-design.md), [source ledger](continuation-writer-evidence.md)
and [proof conditions](continuation-minor-scan-proof.md). No source expansion,
compiler/native/model or whole-program analysis ran. All replacements remain
unimplemented and unqualified.

| Family | Actual selected producer/caller path | Necessary replacement / source coverage boundary |
| --- | --- | --- |
| W01 Heap frame setter | ##frame-set! implementation; actual ##implode-frame caller [WE01] | typed saved-frame slot or validated control transition. selected constructor/caller chain reviewed; privileged/external callers unresolved |
| W02 Heap and stack continuation setter | ##continuation-set! has two real representation branches [WE01] | managed frame store or owned stack-root/control store. implementation reviewed; complete dynamic callers unresolved |
| W03 Shell frame and denv setters | kernel macros and C-target primitive emission [WE01] | typed region/managed shell store. definition/emission surfaces reviewed; not all are proven active native calls |
| W04 Shared shell copy and cursor advance | ##continuation-copy; ##continuation-next invokes next! on copied shell [WE01] | preserve shallow frame/denv aliases and typed cursor update. selected local caller chain reviewed |
| W05 Frame reader reconstruction | #frame dispatch -> deserialize -> implode-frame -> make-frame -> frame-set! loop [WE02, WE03] | rooted trace-safe initialization and ordinary mature-store fallback. selected actual producer/fill/consumer chain reviewed; complete serializer domain unresolved |
| W06 Continuation reader reconstruction | #continuation dispatch -> implode-continuation -> make-continuation [WE01, WE02] | root frame/denv before shell allocation/publication. selected chain reviewed; code/layout/domain qualification unresolved |
| W07 Deferred reconstruction writers | closure-set! and list/vector fixup callbacks; deserialize-vector exception [WE02] | retain callback roots/owner and apply actual managed stores. distinct actual families reviewed; no inferred delayed frame fixup |
| W08 SMP dynamic parameter lookup | dynamic-ref updates cache2/cache3/lookup paths, not cache1 hit [WE04, WE05] | thread-cache managed stores even on logical reads. selected active SMP paths reviewed |
| W09 SMP dynamic parameter assignment | dynamic-set! -> binding pair cdr/default descriptor/special parameter pair and caches [WE04, WE05] | generic pair/vector managed writer with alias coverage. selected active SMP paths reviewed |
| W10 Persistent environment insertion | dynamic-let -> env-insert -> newly constructed denv/env nodes [WE04, WE05] | private initialization/publication, thread/denv adoption. selected active SMP path reviewed |
| W11 SMP destructive environment insertion text | env-insert! following #; reader comment [WE05] | no active SMP writer credited. reader-commented source; do not count as executed writer |
| W12 Non-SMP environment/parameter paths | active env-insert! plus dynamic-ref/set!/let in non-SMP branch [WE06] | profile-specific old-node/pair/cache stores. source branch reviewed; configured selection not executed |
| W13 Dynamic environment binding | dynamic-env-bind installs/restores thread denv and caches around thunk [WE07] | rooted before/after state, cache managed stores and reentry. selected implementation reviewed; arbitrary thunk effects remain conservative |
| W14 Scheduler save and restore | THREAD_SAVE writes scheduler shell frame; THREAD_RESTORE clears it and changes current thread [WE07] | source-to-active-root handoff plus typed shell/root writes. source protocol reviewed; not general one-shot user continuation semantics |
| W15 Graft and continuation return | graft/return macros write frame frontier, thread denv and caches [WE07] | root handoff + heap-field barriers + winding stages. source protocol reviewed; complete mixed/native control acceptance unresolved |
| W16 Thread creation/end and REPL binding | thread-init!, thread-end-locked!, thread-repl-context-get! [WE04, WE08] | initialized objects and admitted clears/adoptions; current parameter pair write. selected concrete callers reviewed; other feature/extension consumers open |
| W17 RC carrier lifecycle | register_rc / set_data_rc / mark_rc / release_rc / cleanup_rc [WE09] | known owner/epoch root write, scan and last-reader withdrawal. actual native producers/readers reviewed; selected patch not loaded qualification |
| W18 Procedure-to-native function conversion | SCMOBJ_to_FUNCTION/NONNULLFUNCTION -> static entry or make_c_closure -> RC data [WE10] | protect proc and preserve actual target/owner/carrier support. conditional path reviewed; new target/ABI not qualified |
| W19 Native SFUN callback | BEGIN_SFUN -> marker -> call/error loop -> kill/propagate [WE09, WE11, WE12] | preallocation root, nested callback root stack and every exit custody. macro template reviewed; not expanded/native verified |
| W20 Scheme CFUN and conversion cleanup | CFUN writeback/conversion/native code/error path -> release_function where selected [WE10, WE11] | rooted converted inputs/results, borrow/write/callback footprint. templates reviewed; arbitrary C target bodies unresolved |
| W21 Independent native run entry | ___run -> make_sfun_stack_marker -> ___call -> kill marker [WE09, WE12] | incoming thunk root before allocation and matching control exit. concrete caller reviewed; marker preallocation gap remains |
| W22 Actual roots and collector frame rewriting | register/saved/global/current VM/processor roots, capture forwarding and normal/internal scan [WE09, WE13] | admitted typed root/region readers and collector-exclusive relocation. actual source readers reviewed; new generation profile not implemented |
| W23 Generic stores and direct C surfaces | macro-vector-slot -> vector-set!, set-cdr!, raw global/frame/native field stores [WE04, WE14] | one managed store policy plus classified control/root writes. source realization required; generic/raw caller completeness unresolved |
| W24 External or indirect managed writers/borrows | public native APIs, aliases, generated/embedded C, extension/callback code [WE01, WE09, WE10, WE11, WE14] | bounded admitted footprint/fallback or reject profile. explicit unknown domain; lexical inventory is not full call graph |

The library Scheme query matched 97 lines across 7 files. This is a
literal navigation count only: feature/comment/declaration distinctions need
manual review and unknown indirect/embedded/native users remain open. In
particular, the SMP env-insert! form is reader-commented while the non-SMP
implementation is active in its own branch. The other-target _univlib primitive
declarations are not native caller evidence.

Selected source producer-to-reader chains are concrete; global caller closure
is not established. A qualified generational domain needs every relevant
generic store, raw root carrier, structural edit, serializer callback and native
borrow/write effect accounted. Do not derive a coverage percentage from the
24 rows or the lexical match count.
