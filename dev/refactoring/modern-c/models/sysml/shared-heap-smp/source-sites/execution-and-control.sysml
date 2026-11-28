/* Model-owned source-sites/execution-and-control declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpExecutionControlSources {
 private import GambitSharedHeapSmp::*;

 part copyAlias:SourceSite {
  attribute :>> id="copyAlias";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="(define-prim (##continuation-copy cont)";
  attribute :>> role="constructor";
  attribute :>> observed="Copies continuation wrapper fields frame and denv; it does not deep-copy captured graph";
  attribute :>> required="Preserve shared frame/denv identity and logical mutation revision across wrappers; refresh physical address per restored shot";
  attribute :>> gap="No alias-wide revision law follows from allocating another continuation wrapper";
  ref part :>> question=aliasSource;
 }
 part reflectFrame:SourceSite {
  attribute :>> id="reflectFrame";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="(define-prim (##frame-set! frame i val)";
  attribute :>> role="writer";
  attribute :>> observed="Uses decoded return frame size to write physical fs-i+1 slot directly";
  attribute :>> required="One FrameSpec coordinates stack/heap/reflection/serialization; semantic writes participate in freeze and future remembered-set coverage";
  attribute :>> gap="Interrupt masking alone is not cross-context mutation exclusion, a generational barrier or an alias revision protocol";
  ref part :>> question=aliasSource;
 }
 part denvWriter:SourceSite {
  attribute :>> id="denvWriter";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="(define-prim (##continuation-denv-set! cont denv)";
  attribute :>> role="writer";
  attribute :>> observed="Denv setter delegates to continuation macro; continuation-next! also rewrites frame/denv directly";
  attribute :>> required="Enumerate macro, bulk decode, direct field and continuation-next! writers; separate semantic writes from collector relocation";
  attribute :>> gap="Writer inventory is incomplete without generated/native/serialization expansion; source anchor is not coverage proof";
  ref part :>> question=aliasSource;
 }
 part frameProducer:SourceSite {
  attribute :>> id="frameProducer";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-3.scm";
  attribute :>> anchor="(define (targ-make-frame-spec kind fs link gc-map)";
  attribute :>> role="generator";
  attribute :>> observed="Validates frame kind, physical size, link and GC-map before C emission";
  attribute :>> required="Producer and every capture/scan/restore consumer use same decoded slots and heap/stack coordinates";
  attribute :>> gap="Matching size bounds is not complete liveness, reflection or foreign-root correspondence";
  ref part :>> question=aliasSource;
 }
 part mailboxShare:SourceSite {
  attribute :>> id="mailboxShare";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-send thread obj)";
  attribute :>> role="message";
  attribute :>> observed="SMP branch roots detached cons cell, links it under mailbox mutex, then signals; fallback definition also exists";
  attribute :>> required="Same-VM object reference sharing stays intact; publish/claim/lifetime authority differs from cross-VM transfer policy";
  attribute :>> gap="Both conditional definitions must be qualified; mailbox API alone proves no heap isolation or cross-VM closure mobility";
  ref part :>> question=boundarySource;
 }
 part restoreWinding:SourceSite {
  attribute :>> id="restoreWinding";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##continuation-return-aux cont val1 val2 val3 others)";
  attribute :>> role="restorer";
  attribute :>> observed="Chooses unwind/wind path from source and captured denv then no-winding return; conditional variants exist";
  attribute :>> required="Each shot checks execution domain/resource affinity and reloads current physical slots before hooks/reentry; preserve shared heap effects";
  attribute :>> gap="No one-shot conversion or unproved cross-VM continuation relocation; hooks can reenter and allocate";
  ref part :>> question=boundarySource;
 }
 part minorWriters:SourceSite {
  attribute :>> id="minorWriters";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_operations.h.in";
  attribute :>> anchor="#define ___CONTINUATIONDENVSET";
  attribute :>> role="minor-admission";
  attribute :>> observed="Generated continuation setters store directly; reflective and capture/restore paths reach shared frame and denv slots. DEV p1 detects stale-live omissions, overflow and no-store residual edges.";
  attribute :>> required="Bind generator and native writer families to canonical slots/ranges; reserve log or publish sticky fallback before a store; collector repair rearms residual edges.";
  attribute :>> gap="Generated, reflective, reconstruction and boxed bulk coverage, actual overlap and native aliases must be qualified.";
  ref part :>> question=aliasSource;
 }

 part minorGenerated:SourceSite {
  attribute :>> id="minorGenerated";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="(targ-jump-inline \"##thread-park!\"";
  attribute :>> role="minor-admission";
  attribute :>> observed="The inline jump accepts 2..5 arguments and emits THREAD_PARK; continuation setters have independent primitive emission.";
  attribute :>> required="Bind actual expansions to canonical stack and scheduler frame stores; inspect denv fallback separately.";
  attribute :>> gap="Replay generated inline and fallback, reconstruction across GC and both directions of boxed overlap.";
  ref part :>> question=aliasSource;
 }
 part minorTableReplacement:SourceSite {
  attribute :>> id="minorTableReplacement";
  attribute :>> artifact="vendor/gambit/lib/_system.scm";
  attribute :>> anchor="(define-prim (##table-resize! table)";
  attribute :>> role="minor-admission";
  attribute :>> observed="Scheme-index resize publishes the new gcht before reinsertion and permits interrupts; native-key rehash populates before wrapper replacement.";
  attribute :>> required="Keep old aliases and the partial destination under separate rooted identity; retain on exception or UNKNOWN.";
  attribute :>> gap="Exercise nested Scheme and safepoint during reinsertion, wrapper publication and old alias survival.";
  ref part :>> question=boundarySource;
 }
 part minorTablePartialCoverage:SourceSite {
  attribute :>> id="minorTablePartialCoverage";
  attribute :>> artifact="vendor/gambit/lib/_system.scm";
  attribute :>> anchor="(macro-table-gcht-set! table new-gcht)";
  attribute :>> role="minor-admission";
  attribute :>> observed="Scheme resize can publish a partial backing; native keyed resize also replaces backing under a different path.";
  attribute :>> required="Retain source and destination rooted coverage before early publication; live old aliases retain independent responsibility.";
  attribute :>> gap="Inject safepoint and exception during reinsertion and keep an independent old alias.";
  ref part :>> question=boundarySource;
 }

 part minorGcReturnTarget:SourceSite {
  attribute :>> id="minorGcReturnTarget";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="___COVER_INTERNAL_RETURN_HANDLER_END;";
  attribute :>> role="minor-admission";
  attribute :>> observed="DEV internal return records the restored ira; the first observed workload label reports its indexed address. Matching handoffs establish execution at the saved target; Mach-O host identity isolated the missing thread module, and the thread overlay observed 14963 same-address entries and identified nonstd as the remaining destination. The nonstd overlay matched all 11889 observed handoffs in its run, with 31 pre-handoff supersessions. The separate handoff clock observed 13153 matching entries with a 1 us p95 for each carrier; a separate first-operation probe bracketed completion of 6432 straight-line GVM operations. A timing-disabled census classified 13952 matched targets, including 5359 JUMP/GOTO sites and no conditional sites in that run. The indexed transfer probe observed 1521 exact destination arrivals. The direct TFIB GOTO replay verified 5376 of 5383 transfer-class returns, including 3637 static-edge arrivals. The DEV floating-update and POLL overlay records POLL fallthrough separately from exact slow-dispatch arrival. A watchdog-ended trace retains 131 matched slow-dispatch arrivals and 40 fallthrough completions. A separate natural-exit replay with a larger DEV-only trace buffer observed completion for 13456 of 13466 matched labels, including 118 POLL fallthroughs and 147 handler arrivals. The ten unobserved completions map to four generated sites in execute-jobs, kernel initialization and go. A co-located label accounts for the definition class. An exact-handoff DEV trace from a watchdog-ended run witnesses both execute-jobs paths and kernel POLL; the go safe jump was not sampled in that run. Exact-object substitutions and the prior natural-exit executable all hit the fixed watchdog in a later block. The same four-site binary later exited naturally and witnessed one go safe call with 13035 of 13036 categorized operations completed. Two later exact raw-clock replays witness go L4 POLL(5) entering the same slow handler with a 125 ns bracket in each run. A single natural-exit DEV run combines scheduler, condition and first-operation markers: 34 sampled calls join the exact first-operation completion of their own single-GC return. Their condition-return to GC-resume span sums to 20.963 ms; GC-resume to GVM completion sums to 44.582 us. The local collector exit marker partitions that former span across all 34 calls into 18.799 ms before local collector exit and 2.164 ms from exit to GC resume. Both parts remain inclusive. A separate natural-exit phase overlay clips stage intervals to 349 sampled local tails. It covers 241.998 of 243.737 ms by interval union, with 110.331 ms of barrier, 65.809 ms of copy and root scan, and 44.229 ms of steal search. Allocator gate and selected calls were unobserved in these tails. The same phase executable later exited naturally under Instruments and joined 26 sampled tails to kernel wake and GVM completion. Stage union covers 20.576 of 20.791 ms. The selected per-VM tail union is 20.776 ms after removing 15.500 us of overlap. Whole-round reduction admits 4207 R3 rounds and maps the 26 joined local exits to 23 complete rounds. Request-to-last-resume p95 is 1.929 ms across all rounds and 1.567 ms in the selected subset. None of the 43 slowest rounds intersects the raw scheduler export, which fully contains 523 other rounds. User-space phase markers cover seven carrier tails in five of the 43 slowest rounds. Barrier condition calls account for 110.001 of 118.205 ms of their summed wall. A separate paired-anchor capture intersects four of its 48 slowest rounds and matches one same-TID condition wake with 1.385 ms of runnable-to-switch time in a 73.928 ms whole round. A three-second recording with the same phase binary later intersects six of 41 slowest rounds, but none qualifies for the full scheduler-to-operation chain. None of the six slow intersections contains or crosses a paired user condition sample under the one-in-64 DEV wait selection. A carrier-bracketed scheduler-only reduction finds a 5.815 ms runnable-to-switch pair wholly inside the collector envelope of a 10.106 ms round. No exact wait or operation identity attaches to that pair. Exact per-carrier resume timestamps join all 18 first-operation completions across the six slow rounds. In the 10.106 ms round carrier 1 resumes 202.125 us before the last carrier, and their first operations complete 1.500 and 1.625 us after their respective resumes. A reconstructed DEV pair preserves the a9b896c4 setup source and cached link inputs while varying wait stride. Under Instruments stride eight overflows the existing buffer; stride sixteen records 1105 wait starts and 4415 whole rounds with a valid terminal receipt. Eleven of 45 slowest rounds contain a wait start. This is diagnostic-only. The kernel export joins 71 tails across 57 whole rounds and intersects three slow rounds without an exact wait join. Separating wait boundaries from clock anchoring and tail arming records 11191 eligible waits, 3972 whole rounds and 9647 first-operation completions under the same trace capacity at a one millisecond tail threshold. A 100 microsecond trial exhausts the buffer. Outer collector sampling still limits wait coverage. Exact scheduler joins span 71 whole rounds; the kernel export intersects none of the slowest 40. Later capture of the same binary joins 70 rounds and intersects four slow rounds without wait matches. Independently 20 sampled local tails from 12 slow rounds include 228.837 ms of barrier condition intervals out of 275.843 ms summed local wall. The per-VM tail union is 165.207 ms. Cross-round long-wait capture joins 24 exact calls in five slow rounds. The longest same-call runnable delay is 1.609 ms on the last-resuming carrier of a 10.218 ms pause; its first operation completes 2.584 us after resume. Detailed phase intervals cover only one matched slow local tail. Barrier-site capture joins 17 exact waits across four slow rounds. The longest matched dispatch interval is 1.927 ms at cleanup and still sweep completion in a 15.229 ms pause. Across the 40 slowest rounds the planning decision barrier has 43 observed waits and 74.413 ms of inclusive carrier time. These measurements do not establish global critical-path savings. A DEV publication probe brackets 33992 release stores at copy-plan and cleanup barriers. Among 47 exact waits at these sites, 43 have a unique release whose ordering relative to runnable is unresolved within the 2.417 us calibration spread; four lack a unique candidate. No causal pause savings are admitted. A same-kernel-clock marker after release and before signal orders 22 of 23 exact waits at the selected sites. Four ordered calls occur in three slow rounds. For those calls marker to runnable takes 0.667 to 0.875 us and runnable to dispatch takes 198.250 to 324.666 us. Signal causality and counterfactual pause savings remain open. Of four ordered waits in three slow rounds, three receivers resume last, and two of those also exit the collector last. Advancing only the matched receiver with all peer resumes fixed clips the observed dispatch intervals to 0, 18.750, 35.209 and 86.708 us at the whole-round endpoint. This sensitivity does not account for dependency propagation. All four ordered slow waits return 1.900 to 5.298 ms before local collector exit. Two cleanup receivers then wait 2.894 ms each at the collector-detach barrier. The capacity-decision receiver later waits 1.213 ms at weak-mark completion. The slow path crosses additional synchronization, so peer dependencies remain material. At collector detach 21 sampled slow waits with a unique candidate span 17.485 ms before release and 26.851 ms after release. At resize 25 such waits span 25.497 ms before and 17.255 ms after. These are inclusive carrier sums. Two ordinary resize waits join to kernel dispatch at 2.541 and 7.250 us. No slow wait at these two sites has a same-clock publication join. Site-specific replay finds five retained detach or resize waits in slow rounds intersecting the two kernel exports. Two are outside carrier anchor brackets, two lack an exact scheduler event chain, and one straddles the calibrated clock boundary. All five fail before publication matching. Per-wait target anchoring exhausts the existing buffer. Every-second target anchoring with long-wait phase arming yields 157 exact round joins and 139 ordered publication calls without overflow. The kernel window intersects none of the 41 slowest rounds. Ten waits lack a unique publication and one is rejected because runnable precedes the candidate release. The unchanged denser binary produces 149 ordered calls in a later window, including no slow-round target joins. Resize dispatch p95 varies from 182.208 us in the earlier capture to 7.958 us in the later capture. Detach p95 changes from 17.333 to 7.875 us. Selected windows must stay separate for inference. Six of 63 early resize calls have at least 100 us of dispatch delay, compared with zero of 78 later calls. The four longest account for 63.05 percent of the early sum. The longest is 846.500 us in a 10.240 ms round, but its receiver resumes 21.542 us before the last carrier. The median changes only from 6.750 to 5.480 us. Six early resize dispatch intervals of at least 100 us occur in four rounds. Their summed time is 1.912 ms and their per-round wall unions total 1.588 ms. Three rounds have matching intervals on the final resuming carrier, totaling 0.551 ms. A fixed-suffix calculation for the six long resize calls advances the last resume by 17.875, 175.125, 0 and 175.458 us in the four recorded R3 rounds, totaling 368.458 us. It subtracts observed dispatch intervals only from the receivers and preserves all other resume times and downstream durations. It is an endpoint sensitivity, with no causal or throughput credit. The receiver with the 846.500 us resize dispatch interval subsequently waits 1.057 ms at the root-round retirement barrier. All six long resize waits return 0.558 to 1.887 ms before local collector exit, followed by 0.312 to 0.839 ms to resume. The other five have no retained later wait record. Fixed-suffix sensitivity is therefore conditional. Root-reopen and retirement capture joins 75 ordered publication calls. In a 22.145 ms pause, the last-resuming carrier has 912.417 us of dispatch delay at RC reopen and 564.000 us at root retirement. At retirement it exits the collector 0.792 us after condition return, resumes 1.001 ms after collector exit and completes its first GVM operation 1.042 us later. The 564.000 us retirement interval is a fixed-peer sensitivity, not measured savings. Three slow retirement receivers each have a second distinct runnable-to-switch pair between collector exit and resume. These delays are 741.209, 349.541 and 80.333 us. In the 22.145 ms round the final carrier becomes runnable 241.416 to 256.333 us after collector exit and resumes 3.041 to 17.958 us after dispatch. The second wake cause remains unobserved. The scoped DEV replay locates all 74 distinct admitted post-collector dispatch pairs in subsequent sync-tree exchanges, with none inside lifecycle drain. There are 3976 complete rounds, 131 joined rounds and 118 ordered publications. No slow ordered publication has a scoped dispatch witness in this run, so earlier slow wake causes remain open. Of 74 matched sync-tree suffixes, 73 have greater runnable-to-switch time than resume-to-first-GVM-completion time. Their respective p95 values are 163.833 and 2.834 us, and maxima are 361.541 and 5.833 us. These are separate distributions of matched diagnostics and grant no whole-pause or throughput credit. The 74 scoped sync-tree dispatch pairs map to 64 complete rounds, ten with multiple observed carriers. Their sum and per-round unions both total 1.599 ms, showing no overlap among these matched intervals. In 22 rounds the last-resuming carrier is matched, totaling 1.259 ms. Unobserved peers and wake causality remain open. A later capture of the same scoped binary links nine dispatch pairs in five slow rounds to sync-tree exchanges after collector exit. Across the capture 87 pairs have that scope and two remain unresolved. The 87 pairs cover 67 rounds, with 1.783 ms summed dispatch and 1.485 ms of per-round unions. The 9.629 ms round includes 98.000 and 296.291 us on two receivers. The specific wake sender remains unobserved. Raw event thread headers agree with all 996 explicit carrier anchors. All 87 scoped runnable records have a peer carrier as emitter, with 53 from carrier 0, five from carrier 1 and 29 from carrier 2. All nine slow records are emitted by carrier 0. This identifies the kernel event context, while the precise signal call is still unresolved. All nine slow runnable events fall within carrier 0 post-collector sync-tree calls bounded by its own collector exit and resume in the same round. Across all 87 recipient sync-tree pairs, 52 have a matching emitter sync-tree scope and 35 are unresolved. The exact signal invocation is still unobserved. The final-retirement-only overlay resolves 25 of 33 post-collector sync-tree runnable records inside unique root signal brackets with matching emitter and recipient. The largest signal bracket is 4.541 us and the largest matched dispatch delay is 517.625 us. None is in an admitted slow-round chain. Two broader captures exhausted the unchanged trace buffers. The same signal binary with later attach exits normally and yields 3973 complete user rounds, but the kernel export has no explicit anchors, publication markers or signal markers. The reducer rejects shared-clock matching despite 1210204 exported rows. In the valid earlier 25 calls, median signal-bracket time is 2.708 us and median runnable-to-switch is 8.666 us. The middle attach window joins 54 signal calls across the capture and matches two root signals to the same 15.289 ms slow round. Their receiver dispatch intervals are 211.584 and 229.791 us, with a 234.500 us union. Carrier 2 resumes last and completes its first GVM operation 0.750 us later. The late failed export has an empty signpost table despite 6760 successful user probe returns. In the 15.289 ms round, eliminating only the matched dispatch intervals with fixed downstream durations advances the endpoint by zero for carrier 1 alone, 22.333 us for carrier 2 alone, and 227.833 us for both. Carrier 0 then determines the endpoint. The joint sensitivity is 1.49 percent of the observed pause and is not an observed saving. The same 15.289 ms round has a 13.655 ms whole collector envelope. The one carrier with phase intervals after its first matched wait has a 4.956 ms local tail, of which 4.952 ms is covered by barrier probes and 4.867 ms by nested condition wait. Other carriers and earlier phases are not covered by that local decomposition. The consolidated diagnostic matrix separates sampled local stages, bounded allocator calls, exact signal-to-GVM evidence, the R3 W2 full-GC control and official uninstrumented net costs. Whole-round stage partition and allocator-internal wait remain unresolved. Official two-block body time changes are +4.41 percent for tfib and -7.25 percent for gcbench, with gcbench reversing sign across blocks. These intervals are observations and do not establish critical-path savings. The 10.218 ms round contains 7.336 ms summed exact runnable intervals, 5.304 ms after cross-carrier union, and 3.494 ms on the last-resuming carrier. Across five rounds, 24 calls match ten distinct operation completions. The longest resume-to-operation interval is 6.750 us. These are coverage bounds for observed intervals, with no causal or speedup credit. Disjoint carrier accounting separates 6.077 ms of barrier with a condition call and 1.056 ms without it. The 26 exact joins also split GC resume through handoff and operation start, with respective sums of 20.747 us, 8.250 us, and 2.377 us for the operation bracket. The matched dynamic operations comprise 15 transfers, 10 straight-line operations and one poll fallthrough. GCBench full-overlay controls independently exercised the allocator gate; A full collector-invocation census later finds zero calls at the three section allocator gates in both TFIB roles. GCBench controls exercise 765 and 644 acquisitions, with 192 and 144 us of inclusive wall respectively. A separate all-invocation census observes 26 checked native allocator calls in each TFIB role, with 21 and 23 us inclusive wall. Internal allocator wait is bounded by the call span at those sites. The exact ARM64 image places the go safe-call argument-count store at offset 0x1e18 and its indirect host branch at 0x220c. Two dynamic witnesses resolve the same make-thread entry label. Their 1000 ns-grid probe timestamps tie. Three raw-uptime replays verify 34491 completion brackets with class medians of 42 to 83 ns, but no go return was sampled in that initial block. Later exact raw-clock runs measure two go safe-call brackets of 125 and 292 ns to make-thread. Exact native instruction timing remains open.";
  attribute :>> required="Keep address mismatch, unobserved return and multiple handoff cases separate; never infer a native thread wake from user-space instruction entry.";
  attribute :>> gap="Explicit Points of Interest co-records carrier clock markers with raw scheduler events. Brackets reject constant CLOCK_MONOTONIC offset but establish a common CLOCK_UPTIME_RAW offset in one DEV run. The raw uptime run joins 7782 runnable-to-recorded-switch pairs to bounded GC windows. Public XNU source confirms field meanings; exact local-tag and first native instruction timing remain open.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibJoinPathMix:SourceSite {
  attribute :>> id="tfibJoinPathMix";
  attribute :>> artifact="vendor/gambit/lib/_thread.scm";
  attribute :>> anchor="(define-prim (##thread-join-wait! thread timeout)";
  attribute :>> role="minor-admission";
  attribute :>> observed="Official TFIB starts and joins a new Scheme thread at each recursive split. Both historical revisions share the same join source. A completed target returns directly; an outstanding target may capture a wait continuation and enter the register and park path. In the GCC wake contrast the TFIB timing report shows 515816184 to 951217664 bytes and 3629 to 5145 collections. The bytes field comes from the current processor allocation statistic at each endpoint, plus its still component, and is not a sum over all carriers. GCBench reports the same bytes value in every arm and 36 to 54 collections.";
  attribute :>> required="Keep successful TFIB result and iteration count fixed. Observe fast join, captured wait, successful registration and completion by stable event identity before attributing allocation or GC frequency to the wake intervention.";
  attribute :>> gap="The DEV generated-code counters retain 16 qualified runs. Each accepted TFIB cell accounts for exactly 1220000 joins and every capture enters its receiver label. In role and block order, argument overlay capture changes are -1.14, +3.74, -0.55, +0.85 percent and successful BTQ insertion changes are -1.10, +3.53, -0.53, +0.81 percent. GCBench process-wide join entries range from 0 to 0. Carrier totals provide no per-request or GC-epoch linkage. A counting build can change scheduling; the counts do not establish why the uninstrumented historical timing differs.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibHistoricalCampaignSensitivity:SourceSite {
  attribute :>> id="tfibHistoricalCampaignSensitivity";
  attribute :>> artifact="vendor/gambit/bench/src/tfib.scm";
  attribute :>> anchor="(define (tfib n)";
  attribute :>> role="minor-admission";
  attribute :>> observed="The exact historical no-probe products yield 12 slower TFIB pairs out of 18, in four slower campaigns out of six. The median paired body-time change is plus 2.72 percent. Removing any two complete campaigns leaves plus 0.84 to plus 5.02 percent. The analogous GCBench range is minus 9.03 to plus 0.81 percent. Recomputing all eighteen retained TFIB log-accounting rows gives 30.4664 percent count, 32.8420 percent reported per-round duration and 36.6916 percent outside-report shares of the observed log contrast; the three terms sum exactly, but are not causal mediated fractions.";
  attribute :>> required="Keep whole campaigns together to preserve within-session run order. Exhaustive campaign resampling gives a weighted percentile sensitivity range of plus 0.13 to plus 6.11 percent for TFIB and minus 11.71 to plus 2.74 percent for GCBench. Treat this as an exchangeability sensitivity and retain the distinct randomized assignment evidence. Keep historical p3-only worker evidence separate from explicit R3/W2 cohorts. The direct final-barrier path is after report time, but next-round trigger/headroom feedback is not excluded by that boundary. Exact historical image recovery or matched mediation remains required for common-cause identification.";
  attribute :>> gap="Only six balanced assignments exist in the retained randomized block. Its two-sided sharp-null p value is 1.0 for TFIB and one third for GCBench. The wider historical record supports a directional TFIB tendency under its observed campaign weights, without an independent-session confidence claim or a causal link to barrier wait.";
  ref part :>> question=nativeAcceptance;
 }

 part tfibHistoricalPhaseAlignment:SourceSite {
  attribute :>> id="tfibHistoricalPhaseAlignment";
  attribute :>> artifact="vendor/gambit/bench/src/tfib.scm";
  attribute :>> anchor="(define (tfib n)";
  attribute :>> role="minor-admission";
  attribute :>> observed="Work-progress bins use cumulative join entries at the root cut. Two previous captures of the same candidate binary fully cover eligible receipts in the 30 to 40 and 40 to 50 percent bins also covered by the archived baseline. At 30 to 40 percent, post-release Runnable p95 is 7.667 us for the baseline and 220.959 and 242.166 us for the candidate captures. At 40 to 50 percent it is 184.875 versus 252.917 and 143.041 us.";
  attribute :>> required="Keep separate executions and their exact image and trace identities. Match benchmark work progress and require at least 100 receipts and 80 percent coverage in each run. For population percentile bounds, assign missing receipt values zero or the measured post-publication last-wait span. Keep full user reply percentiles separate.";
  attribute :>> gap="The same-pair role capture has no qualifying common bin. Two earlier candidate captures share one baseline and are not independent role repetitions. The mid-run tail difference is phase-specific and may include host-condition variation. It does not identify historical no-probe mediation.";
  ref part :>> question=nativeAcceptance;
 }
 part minorParticipantHandoff:SourceSite {
  attribute :>> id="minorParticipantHandoff";
  attribute :>> artifact="vendor/gambit/lib/setup.h";
  attribute :>> anchor="#define BARRIER() barrier_sync_noop";
  attribute :>> role="minor-admission";
  attribute :>> observed="SMP uses a carrier rendezvous, separate from the W termination counter. DEV read-only GC cut observer checks source 2 READY to DONE with executor 0 at R=3/W=2; same-cache diagnostic executed real R=3/W=2 and two weak cleanup-list observations with no target-table store; GSC/archive/link metadata match one historical producer; full configured input and in-round fault qualification remain open.";
  attribute :>> required="Transfer W debt without satisfying R. DEV negative joins actual non-worker carrier 2 after frozen custody; surviving workers complete source task, with no rendezvous return observed before explicit monitor exit. Product handoff remains open.";
  attribute :>> gap="At W<R compare parked-carrier success, carrier-exit refusal, next round without stores and budget exhaustion. DEV p1 control reran successfully; retained seed lacked companion linker metadata and the new topology control did not link.";
  ref part :>> question=nativeAcceptance;
 }

 part orderedRootWords:SourceSite {
  attribute :>> id="orderedRootWords";
  attribute :>> artifact="vendor/gambit/include/_gambit/activity_log.h.in";
  attribute :>> anchor="#define ___WORD_LOAD_ACQUIRE(p)";
  attribute :>> role="memory-order";
  attribute :>> observed="Native atomic, legacy RMW and sequential definitions coexist under platform selection";
  attribute :>> required="Bind configured backend; prove collective and source mutex publication, not just ordered primitive spelling";
  attribute :>> gap="All conditional matches are retained; selected binary backend and barrier implementation remain source/native work";
  ref part :>> question=cutSource;
 }
 part rebuildFrame:SourceSite {
  attribute :>> id="rebuildFrame";
  attribute :>> artifact="vendor/gambit/lib/_io.scm";
  attribute :>> anchor="(define-prim (##implode-frame re fields)";
  attribute :>> role="reconstruction";
  attribute :>> observed="Deserializer allocates a frame then populates it with frame-set!; continuation rebuild calls make-continuation";
  attribute :>> required="Root frame and source fields across allocation; cover every live slot, partial initialization, alias fixups and publication";
  attribute :>> gap="Interrupt masking is not complete initialization, generational BulkWrite or concurrent alias exclusion";
  ref part :>> question=aliasSource;
 }
 part continuationWriter:SourceSite {
  attribute :>> id="continuationWriter";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="(define-prim (##continuation-set! cont i val)";
  attribute :>> role="writer";
  attribute :>> observed="Heap and stack branches write different fs-based physical coordinates, including an unresolved link-position comment";
  attribute :>> required="One FrameSpec adapter validates ordinary and structural slots; semantic revision and remembered coverage apply to direct stores";
  attribute :>> gap="Source has no single demonstrated revision/barrier path covering all direct reflection and serializer writes";
  ref part :>> question=aliasSource;
 }
 part stackEmitter:SourceSite {
  attribute :>> id="stackEmitter";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="(list \"SET_STK\"";
  attribute :>> role="generator";
  attribute :>> observed="The C target emits stack stores through SET_STK at multiple location-assignment paths";
  attribute :>> required="Every live local must reach the canonical stack/bank view before the freeze ACK; use existing FrameSpec/liveness owner";
  attribute :>> gap="Generated strings and direct c-code can bypass normal GVM emitters; complete liveness/reflection coverage remains open";
  ref part :>> question=cutSource;
 }
 part bankRootMacros:SourceSite {
  attribute :>> id="bankRootMacros";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_registers.h.in";
  attribute :>> anchor="#define ___W_R1";
  attribute :>> role="root-writer";
  attribute :>> observed="Logical register macro writes the execution-context bank; stack operations use separate coordinates";
  attribute :>> required="Spill all actual live GVM roots before root-round publication; metadata pc/fp/hp are not automatically Scheme roots";
  attribute :>> gap="All register-count/backend variants and scratch temp/error carriers need liveness-to-root correspondence";
  ref part :>> question=cutSource;
 }
 part claimFatalHook:SourceSite {
  attribute :>> id="claimFatalHook";
  attribute :>> artifact="vendor/gambit/lib/os_base.c";
  attribute :>> anchor="void ___fatal_error";
  attribute :>> role="gate-held-contract-failure-effect";
  attribute :>> observed="take's require_chunk_transition can call fatal_error before queue unlock; fatal_error invokes setup_params.fatal_error callback before exit_process";
  attribute :>> required="Normal claim span permits no Scheme/native reentry. A fatal hook escape cannot imply rollback or gate closure; retain the affected VM/slot and reject resume unless actual writer/fragment closure is proved";
  attribute :>> gap="Current failure hook is not covered by a durable take outcome/exit guard. Exact callback effects and last users need source/native qualification; default process exit is not a recovered-VM pass";
  ref part :>> question=cutSource;
 }
 part takeAtomicService:SourceSite {
  attribute :>> id="takeAtomicService";
  attribute :>> artifact="vendor/gambit/include/_gambit/activity_log.h.in";
  attribute :>> anchor="#define ___WORD_LOAD_ACQUIRE(p) __atomic_load_n(p,__ATOMIC_ACQUIRE)";
  attribute :>> role="slot-control-access-class";
  attribute :>> observed="Ordered-word service has native acquire/release operations and full-RMW legacy alternatives; plain accesses are confined to sequential or exclusive initialization cases";
  attribute :>> required="All concurrent slot control operations use one selected service with sufficient ordering; plain immutable payload access needs acquired publication and pin-protected no-overwrite lifetime";
  attribute :>> gap="No actual take slot layout or release/acquire compiler qualification exists; do not cast a new _Atomic object through incompatible legacy aliases";
  ref part :>> question=cutSource;
 }
 part bulkTargetSelection:SourceSite {
  attribute :>> id="bulkTargetSelection";
  attribute :>> artifact="vendor/gambit/lib/_gambit#.scm";
  attribute :>> anchor="(macro-define-syntax macro-case-target";
  attribute :>> role="actual-target-selection";
  attribute :>> observed="Reads compilation-options target and defaults to C; c/C branch of vector macro emits c-code";
  attribute :>> required="Bind actual compilation target and macro instance to emitted consumer; distinguish fallback from native path";
  attribute :>> gap="No current regenerated producer/build equivalence follows from default selection";
  ref part :>> question=cutSource;
 }
 part generatedBulkCaller:SourceSite {
  attribute :>> id="generatedBulkCaller";
  attribute :>> artifact="vendor/gambit/lib/_std.c";
  attribute :>> anchor="___DEF_GLBL(___L4__23__23_vector_2d_copy_21_)";
  attribute :>> role="observed-generated-caller";
  attribute :>> observed="Observed generated primitive saves/reorders stack/register roots, POLLs then jumps to subvector-move; primitive derives raw bodies and memmoves";
  attribute :>> required="Retain complete caller root view across new reservation and reload before physical span";
  attribute :>> gap="Generated file corroborates source path only; source/producer/toolchain equality and execution remain unqualified";
  ref part :>> question=cutSource;
 }
 part generatedFillCaller:SourceSite {
  attribute :>> id="generatedFillCaller";
  attribute :>> artifact="vendor/gambit/lib/_std.c";
  attribute :>> anchor="___DEF_GLBL(___L3__23__23_subvector_2d_fill_21_)";
  attribute :>> role="observed-generated-loop";
  attribute :>> observed="Generated fill performs VECTORSET then POLL before next iteration";
  attribute :>> required="Preserve semantic store commit before each admitted safe point and keep vector/fill live";
  attribute :>> gap="A whole-operation cached pointer or a gate held over POLL would invalidate existing loop behavior";
  ref part :>> question=cutSource;
 }
 part bulkNativeAllocationResult:SourceSite {
  attribute :>> id="bulkNativeAllocationResult";
  attribute :>> artifact="vendor/gambit/lib/os_base.c";
  attribute :>> anchor="ptr = malloc (bytes);";
  attribute :>> role="native-allocation-result-boundary";
  attribute :>> observed="Ordinary allocator branch returns native malloc result; optional debug accounting/logging is not a target-intent ownership journal";
  attribute :>> required="Classify native result capture separately from RC header initialization, typed payload, registration and intent adoption; qualify actual selected backend";
  attribute :>> gap="No allocator-key query or arbitrary-death result recovery is established";
  ref part :>> question=cutSource;
 }
 part bulkRcMutexProvider:SourceSite {
  attribute :>> id="bulkRcMutexProvider";
  attribute :>> artifact="vendor/gambit/include/_gambit/activity_log.h.in";
  attribute :>> anchor="#define ___MUTEX_INIT(mut) (pthread_mutex_init (&mut, NULL) == 0)";
  attribute :>> role="actual-posix-source-gate-provider";
  attribute :>> observed="POSIX macro requests default attributes and lock macro compares return to zero; RC gate aliases these operations";
  attribute :>> required="Require genuine exclusion/known gate release before inspecting or settling a registration; retain provider lifetime and actual backend qualification";
  attribute :>> gap="Source shows no requested robust-owner-death protocol or partial-list repair service; observed owner death alone grants no mutex recovery";
  ref part :>> question=cutSource;
 }
 part bulkPollDispatch:SourceSite {
  attribute :>> id="bulkPollDispatch";
  attribute :>> artifact="vendor/gambit/include/_gambit/module_generation.h.in";
  attribute :>> anchor="#define ___POLL(n)";
  attribute :>> role="poll-is-general-control-transfer";
  attribute :>> observed="POLL records continuation label in temp1 and jumps to handler_stack_limit on heartbeat/stack trip";
  attribute :>> required="Bulk GC-only park needs complete rooted return state and explicit permitted effects, not an ordinary POLL inserted into raw C";
  attribute :>> gap="Current macro is not a restricted no-user-code service";
  ref part :>> question=cutSource;
 }
 part bulkInterruptEffects:SourceSite {
  attribute :>> id="bulkInterruptEffects";
  attribute :>> artifact="vendor/gambit/lib/_kernel.scm";
  attribute :>> anchor="(define-prim (##interrupt-handler)";
  attribute :>> role="scheme-interrupt-caller";
  attribute :>> observed="Stack-limit handler saves registers/return state then dispatches Scheme interrupt handlers; sync handler wraps service_sync_op with W_ALL/R_ALL";
  attribute :>> required="Preserve original Scheme fill/multi-shot semantics; native bulk boundary may not introduce hook/capture points accidentally";
  attribute :>> gap="GC-only restricted entry/exit and exact error/callback deferral are unimplemented";
  ref part :>> question=cutSource;
 }
 part bulkPurposeDispatch:SourceSite {
  attribute :>> id="bulkPurposeDispatch";
  attribute :>> artifact="vendor/gambit/lib/lifecycle.h";
  attribute :>> anchor="enum ___activation_kind";
  attribute :>> role="real-lifecycle-purpose-discriminator";
  attribute :>> observed="Current kinds include legacy/startup/SFUN plus clean retired IDLE, with owner/marker/roots/kind fields and RC-domain idle reuse";
  attribute :>> required="Add real bulk purpose and pending effect/root-custody state to existing lifecycle owner plus all kind consumers";
  attribute :>> gap="No current bulk kind or universal-purpose abort exists; cannot reuse SFUN/STARTUP tags to bypass checks";
  ref part :>> question=cutSource;
 }
 part bulkStageLayout:SourceSite {
  attribute :>> id="bulkStageLayout";
  attribute :>> artifact="vendor/gambit/include/_gambit/memory_state.h.in";
  attribute :>> anchor="typedef struct ___rc_header_struct";
  attribute :>> role="fixed-stage-root-layout";
  attribute :>> observed="Header separates refcount, primary root, source domain, root borrows and immutable root_count";
  attribute :>> required="Fixed typed stage slots remain valid SCMOBJ values through freeze/scan; native progress is separate nonroot metadata";
  attribute :>> gap="No bulk-purpose writer or partial-effect fields are provided by this layout";
  ref part :>> question=cutSource;
 }
 part nativeClosureCustody:SourceSite {
  attribute :>> id="nativeClosureCustody";
  attribute :>> artifact="vendor/gambit/lib/os_dyn.c";
  attribute :>> anchor="void *___make_c_closure";
  attribute :>> role="platform-conditional-trampoline-producer";
  attribute :>> observed="Conditional implementation allocates RC code storage, records Scheme proc with set_data_rc and publishes function address; self accessor feeds SFUN entry";
  attribute :>> required="Qualify selected CPU/code publication, self identity under reentry/concurrency and pin-before-release";
  attribute :>> gap="Unsupported code-size branch returns zero; opaque native bytes are not a typed Scheme root span";
  ref part :>> question=cutSource;
 }
 part boxedBulkMove:SourceSite {
  attribute :>> id="boxedBulkMove";
  attribute :>> artifact="vendor/gambit/lib/_std#.scm";
  attribute :>> anchor="memmove (dst, src, len);";
  attribute :>> role="boxed-bulk-physical-write";
  attribute :>> observed="C macro branch selects SCMOBJ word spans for vector and values; public copy!/subvector paths converge here";
  attribute :>> required="Root source and destination, reserve range metadata, preserve overlap semantics and enclose move plus edge commit in admitted write span";
  attribute :>> gap="No scalar VECTORSET barrier is executed here; arbitrary interrupted memmove lacks per-word completion evidence";
  ref part :>> question=cutSource;
 }
 part boxedBulkFill:SourceSite {
  attribute :>> id="boxedBulkFill";
  attribute :>> artifact="vendor/gambit/lib/_std#.scm";
  attribute :>> anchor="(define-prim (,prim-subvect-fill! vect start end fill)";
  attribute :>> role="boxed-fill-and-fallback";
  attribute :>> observed="Fill uses vect-set! loop; non-C move fallback chooses directional setter loop";
  attribute :>> required="Use same edge policy and bounded complete-root safe points without changing serial copy/fill effects";
  attribute :>> gap="Loop syntax alone proves neither stop latency nor actual generated-store coverage";
  ref part :>> question=cutSource;
 }
 part bulkTypeInstances:SourceSite {
  attribute :>> id="bulkTypeInstances";
  attribute :>> artifact="vendor/gambit/lib/gambit/vector/vector.scm";
  attribute :>> anchor="(define-prim-vector-procedures";
  attribute :>> role="macro-instance-layout-owner";
  attribute :>> observed="Macro is instantiated for boxed vector and values as well as unboxed numeric vectors";
  attribute :>> required="Bind emitted branch to actual element layout; do not treat all copied bytes as Scheme references";
  attribute :>> gap="Branch and macro use need actual generated producer/consumer evidence, not a textual name match";
  ref part :>> question=cutSource;
 }
 part smallBulkConstructor:SourceSite {
  attribute :>> id="smallBulkConstructor";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_operations.h.in";
  attribute :>> anchor="#define ___SUBVECTSMALL(body,start,end,";
  attribute :>> role="private-bulk-initialization";
  attribute :>> observed="Small copy snapshots a body pointer and loops ADD_VECT_ELEM into allocation macros";
  attribute :>> required="Preprotect operands, preserve no-GC physical span or reload after any new collecting reservation; initialize before first publication";
  attribute :>> gap="Adding an allocating barrier inside the raw-pointer loop invalidates source coordinates";
  ref part :>> question=cutSource;
 }
 part verbatimNativeEmission:SourceSite {
  attribute :>> id="verbatimNativeEmission";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="(obj-val code)";
  attribute :>> role="native-extension-admission-boundary";
  attribute :>> observed="c-code emitter inserts constant native source into generated output and binds ARG macros";
  attribute :>> required="Require explicit effects/layout/roots/access and last-use qualification or conservative affected-domain policy";
  attribute :>> gap="Arbitrary native code cannot be certified from generator syntax or repository grep";
  ref part :>> question=cutSource;
 }
 part mapControlOrder:SourceSite {
  attribute :>> id="mapControlOrder";
  attribute :>> artifact="vendor/gambit/lib/gambit/list/list.scm";
  attribute :>> anchor="(define-primitive (map (proc  procedure)";
  attribute :>> role="map-callback-capture-and-retained-graph";
  attribute :>> observed="let* orders callback, non-tail recursion and cons; callback capture retains pending control and shared inputs";
  attribute :>> required="Retain actual frame/denv and shared aliases across request return and every restore";
  attribute :>> gap="Actual generated frame/root and winding consumers still require whole-case native validation";
  ref part :>> question=cutSource;
 }
 part generatedReferenceStore:SourceSite {
  attribute :>> id="generatedReferenceStore";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="(targ-op \"##set-car!\"";
  attribute :>> role="semantic-store-emitter";
  attribute :>> observed="Pair setters emit SETCAR/SETCDR; vector and closure stores have analogous emission";
  attribute :>> required="Generate a common admitted edge policy for published pointer fields and distinguish unpublished initialization";
  attribute :>> gap="Current emitters and disabled SSB hook do not supply an active generational remembered-set protocol";
  ref part :>> question=cutSource;
 }
 part inactiveStoreBuffer:SourceSite {
  attribute :>> id="inactiveStoreBuffer";
  attribute :>> artifact="vendor/gambit/gsc/_t-c-2.scm";
  attribute :>> anchor="if #f ;;;;ssb-space";
  attribute :>> role="inactive-store-buffer-hook";
  attribute :>> observed="targ-apply-simp-generator disables ssb-space reservation";
  attribute :>> required="A new barrier must reserve metadata before mutation and never silently collect inside the write span";
  attribute :>> gap="Historical SSB parameters are not evidence of functioning barrier overflow/failure coverage";
  ref part :>> question=cutSource;
 }
 part pairReferenceStore:SourceSite {
  attribute :>> id="pairReferenceStore";
  attribute :>> artifact="vendor/gambit/include/_gambit/gvm_operations.h.in";
  attribute :>> anchor="#define ___SETCAR(obj,car)";
  attribute :>> role="physical-published-pair-store";
  attribute :>> observed="SETCAR is a direct CAR_FIELD assignment; continuation field setters likewise directly assign";
  attribute :>> required="Enroll semantic writers through store and incoming-edge commit; scanner requires writer closure or a proved concurrent rescan";
  attribute :>> gap="Release on an unrelated root does not make these plain fields safe during racing relocation";
  ref part :>> question=cutSource;
 }
 part closureReferenceStore:SourceSite {
  attribute :>> id="closureReferenceStore";
  attribute :>> artifact="vendor/gambit/include/_gambit/module_generation.h.in";
  attribute :>> anchor="#define ___SET_CLO(x,y,z)";
  attribute :>> role="closure-free-variable-store";
  attribute :>> observed="SET_CLO writes a free-variable slot directly";
  attribute :>> required="Cover visible closure mutation as well as safe unpublished construction; preserve shared alias semantics";
  attribute :>> gap="A macro name or region-local allocation does not prove complete edge coverage";
  ref part :>> question=cutSource;
 }
 part frameReconstructionStore:SourceSite {
  attribute :>> id="frameReconstructionStore";
  attribute :>> artifact="vendor/gambit/lib/_io.scm";
  attribute :>> anchor="(define-prim (##implode-frame re fields)";
  attribute :>> role="reconstructed-control-fields";
  attribute :>> observed="Builds frame and fills fields through frame-set! with interrupts disabled";
  attribute :>> required="Separate unpublished initialization from published reflective updates and retain full descriptor/root semantics";
  attribute :>> gap="Disabled interrupts are not complete cross-thread publication or native-access exclusion";
  ref part :>> question=cutSource;
 }
 part collectorDestinationRegion:SourceSite {
  attribute :>> id="collectorDestinationRegion";
  attribute :>> artifact="vendor/gambit/lib/collector.h";
  attribute :>> anchor="___gc_worker_arena arena;";
  attribute :>> role="collector-destination-not-young-mutator-region";
  attribute :>> observed="Worker arena is explicitly a private destination distinct from scanned origin, with copy/restore loans and private debts";
  attribute :>> required="Preserve disjoint physical intervals and ownership across any placement/domain change; no relabeling this arena as a ready-made nursery";
  attribute :>> gap="Physical destination ownership and root-worker separation do not prove independent regional GC";
  ref part :>> question=cutSource;
 }
 part takeCollectorTranslationUnit:SourceSite {
  attribute :>> id="takeCollectorTranslationUnit";
  attribute :>> artifact="vendor/gambit/lib/mem.c";
  attribute :>> anchor="#include \"_mem/heap-sections.inc\"";
  attribute :>> role="actual-collector-translation-unit";
  attribute :>> observed="mem.c includes gambit.h, collector-related headers and ordered _mem fragments including queue operations, scanning and collection round; fragments are not independent compilation units";
  attribute :>> required="Selection evidence belongs to this actual TU and include closure; independently bind os_thread.c provider TU and linked artifact, with matching field layout/provider availability";
  attribute :>> gap="Make-derived preprocessing of the existing configured cache now exists for both TUs. Twelve union include/input differences from checkout remain; no current-checkout object, ABI or linked runtime qualification follows";
  ref part :>> question=cutSource;
 }
 part takeBackendSelection:SourceSite {
  attribute :>> id="takeBackendSelection";
  attribute :>> artifact="vendor/gambit/include/_gambit/activity_log.h.in";
  attribute :>> anchor="#ifdef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4";
  attribute :>> role="exact-translation-unit-provider-selection";
  attribute :>> observed="Full RMW uses WS4/WS8 sync feature macros first, then Win32, POSIX emulation or sequential; ordered-word independently uses ATOMIC feature macros unless existing legacy override is defined";
  attribute :>> required="One source-period binding covers compiler/target/predefined macros, generated include bytes, all command-line definitions and effective macro expansions of every slot access; qualify their same-field interoperability";
  attribute :>> gap="Retained cache preprocessing selects WS8, native ordered-word plus sync CAS for both TUs under GCC16.2/aarch64/C23/RTS-O3. Its full input closure differs from checkout; it cannot qualify current-source objects/link/runtime or forced-legacy/Win32/emulated paths";
  ref part :>> question=cutSource;
 }
 part orderedCasFailureContract:SourceSite {
  attribute :>> id="orderedCasFailureContract";
  attribute :>> artifact="vendor/gambit/include/_gambit/activity_log.h.in";
  attribute :>> anchor="__atomic_compare_exchange_n(p,&(expected),v,0,__ATOMIC_ACQUIRE,__ATOMIC_RELAXED)";
  attribute :>> role="provider-order-and-expected-contract";
  attribute :>> observed="Native acquire CAS passes expected by address and can update it on failure; legacy compare expression returns boolean without the same expected-variable contract";
  attribute :>> required="Use explicit observed-value full-RMW/reload semantics for mapped gate loops and sufficient order for publication/seal; do not infer release from the acquire helper";
  attribute :>> gap="Compiler lowering/provider qualification and exact CAS failure tests remain native duties; retained macro expansion now binds the configured cache only, not actual CAS execution or current-checkout qualification";
  ref part :>> question=cutSource;
 }
 part sequentialCasScratch:SourceSite {
  attribute :>> id="sequentialCasScratch";
  attribute :>> artifact="vendor/gambit/include/_gambit/activity_log.h.in";
  attribute :>> anchor="((___ps->temp1 = *(p)) == (oldval) && (*(p) = (newval)), ___ps->temp1)";
  attribute :>> role="sequential-provider-context-premise";
  attribute :>> observed="Sequential full CAS uses ___ps->temp1 scratch; the generic observed-value mapping therefore still has a context precondition on that provider";
  attribute :>> required="Do not fabricate a PSTATE for carrier-independent control queries. Qualify valid confinement or refine the existing sequential service to local scratch; processor count1 alone does not select this compile-time backend";
  attribute :>> gap="No carrier-free sequential query provider is admitted by this design; unsupported context combinations remain OPEN rather than hidden behind a new wrapper";
  ref part :>> question=cutSource;
 }
 part lifecycleBorrowPattern:SourceSite {
  attribute :>> id="lifecycleBorrowPattern";
  attribute :>> artifact="vendor/gambit/lib/lifecycle.h";
  attribute :>> anchor="___VOLATILE ___WORD entries[___MAX_PROCESSORS];";
  attribute :>> role="existing-closed-bit-borrow-pattern";
  attribute :>> observed="VM entries encode bit0 closed and +2 per borrow; vm-registry operations admit and release using CAS";
  attribute :>> required="Learn this word-encoding pattern while keeping take-query and writer authority distinct from VM/PSTATE entry; storage admission precedes raw slot access";
  attribute :>> gap="Existing VM entry closure is not a substitute for take-slot writer/reader closure or helper-generation validation";
  ref part :>> question=cutSource;
 }
 part collectorAtomicBackend:SourceSite {
  attribute :>> id="collectorAtomicBackend";
  attribute :>> artifact="vendor/gambit/include/_gambit/activity_log.h.in";
  attribute :>> anchor="__sync_val_compare_and_swap(p,oldval,newval)";
  attribute :>> role="configured-publication-backend";
  attribute :>> observed="Builtin gate uses sync CAS and fetch-and-and clear; POSIX maps mutex/condvar operations to pthread, while Win32, emulated and sequential alternatives remain distinct";
  attribute :>> required="Bind selected preprocessing branch, alignment, atomic-only gate access and successful release/acquire chain; sequential backend is not SMP evidence";
  attribute :>> gap="Exact configured-cache preprocessing now observes native ordered-word and sync CAS. Current-source binding, compiler code generation, layout/link and weak-memory runtime acceptance remain unqualified";
  ref part :>> question=cutSource;
 }
}
