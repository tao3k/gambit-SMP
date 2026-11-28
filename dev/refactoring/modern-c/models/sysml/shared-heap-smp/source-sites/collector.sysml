/* Model-owned source-sites/collector declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpCollectorSources {
 private import GambitSharedHeapSmp::*;

 part rootCollective:SourceSite {
  attribute :>> id="rootCollective";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="___root_round_begin(___ps)";
  attribute :>> role="publication";
  attribute :>> observed="All-R BARRIER surrounds begin/freeze/publish and one capacity decision before copying";
  attribute :>> required="Prove platform barrier acquire/release and every participant root spill; known refusal before forwarding; unknown retains source and buffers";
  attribute :>> gap="All-R participation is not arbitrary native preemption or proof of complete external writers";
  ref part :>> question=cutSource;
 }
 part rootScan:SourceSite {
  attribute :>> id="rootScan";
  attribute :>> artifact="vendor/gambit/lib/_mem/rc-roots.inc";
  attribute :>> anchor="mark_array (work, &h->data, 1);";
  attribute :>> role="scanner";
  attribute :>> observed="Current mark_rc binds work from the admitted executor PSTATE collector, then scans h->data plus the root_count SCMOBJ span at h+1 under the frozen claimed source gate";
  attribute :>> required="Every authoritative slot remains live and writable; the initialized span/count and argument-cell writers obey the same scan/exit lifetime before relocation and required scans complete";
  attribute :>> gap="Tracing one registered RC list does not establish all native sources registered";
  ref part :>> question=cutSource;
 }
 part frameConsumer:SourceSite {
  attribute :>> id="frameConsumer";
  attribute :>> artifact="vendor/gambit/lib/_mem/continuation-roots.inc";
  attribute :>> anchor="___HIDDEN void mark_frame";
  attribute :>> role="scanner";
  attribute :>> observed="Ordinary root runs use frame descriptor; captured-chain traversal uses frame access exclusion";
  attribute :>> required="Injective forwarding on admitted live identities and complete slot rewrite including denv/return links precede restore";
  attribute :>> gap="Collector frame gate does not prove mutator alias protocol; multi-shot repeated restoration remains a native obligation";
  ref part :>> question=aliasSource;
 }

 part minorRegion:SourceSite {
  attribute :>> id="minorRegion";
  attribute :>> artifact="vendor/gambit/lib/_mem/heap-sections.inc";
  attribute :>> anchor="All source and restoration admission precedes the first space flip";
  attribute :>> role="minor-admission";
  attribute :>> observed="Existing pre-flip admission requires physical grants; still/movable and parity are not generation identity.";
  attribute :>> required="Freeze one VM writer/borrower roster and bind young region map, RootTask sources and disjoint grants to the same epoch. Retain census.";
  attribute :>> gap="W<R unclaimed source, worker skew, largest frame, no-flip refusal and lost grant receipt need exact-source native evidence.";
  ref part :>> question=cutSource;
 }
 part minorPublication:SourceSite {
  attribute :>> id="minorPublication";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="publishes the one RootTask/worker assignment";
  attribute :>> role="minor-admission";
  attribute :>> observed="Root assignment precedes planning; strong and weak joins precede restoration. DEV overlay is p1.";
  attribute :>> required="Acquire sealed producer views before claim; acquire worker completion before publishing repaired roots and next bank. Separate minor weak policy and major finalization.";
  attribute :>> gap="Require same-profile p1 and pN native/PBT through two rounds and a major interval; check delayed publish, overflow, skew and unknown exit.";
  ref part :>> question=nativeAcceptance;
 }
 part minorCost:SourceSite {
  attribute :>> id="minorCost";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-scanning.inc";
  attribute :>> anchor="if (movable && work->census==0)";
  attribute :>> role="minor-admission";
  attribute :>> observed="DEV target marking is 2 versus 4 visits per two rounds and two fixture banks occupy 80 bytes; census is unchanged.";
  attribute :>> required="Measure matched full, minor with census and separately certified census-free minor over equal completed work. Account writer checks, dirty publishes, fallback, promotion, pause and peak committed bytes.";
  attribute :>> gap="CPU, pause, peak and production break-even remain unmeasured.";
  ref part :>> question=netBenefit;
 }

 part minorWeakEntry:SourceSite {
  attribute :>> id="minorWeakEntry";
  attribute :>> artifact="vendor/gambit/lib/_mem/wills.inc";
  attribute :>> anchor="___HIDDEN void process_wills";
  attribute :>> role="minor-admission";
  attribute :>> observed="Weak uses strided will lists and forwarding/mark state; no direct DRAINING or globals snapshot read in the located path.";
  attribute :>> required="Prove source disjointness after globals lease release; publish any required coordinator decision before weak entry, or hold a lease through the last weak use.";
  attribute :>> gap="Delay processor 0 after strong barrier and observe worker 1 weak entry without waiting for collective completion; vary shared testator classification order.";
  ref part :>> question=nativeAcceptance;
 }

 part minorWeakTableRepair:SourceSite {
  attribute :>> id="minorWeakTableRepair";
  attribute :>> artifact="vendor/gambit/lib/_mem/weak-tables.inc";
  attribute :>> anchor="___HIDDEN void process_gc_hash_tables";
  attribute :>> role="minor-admission";
  attribute :>> observed="Cleanup rewrites forwarded weak key/value fields, deletes pairs with count/flags changes, and never permutes slots.";
  attribute :>> required="Use final typed entry observations after cleanup. Preserve weak roles and distinguish deletion and index-placement debt.";
  attribute :>> gap="Exercise all weak flag branches and held cleanup at W<R; compare final pair, count and flags independently of lookup.";
  ref part :>> question=nativeAcceptance;
 }
 part minorWeakTableReopen:SourceSite {
  attribute :>> id="minorWeakTableReopen";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="if(active_worker) garbage_collect_cleanup_phase(work);";
  attribute :>> role="minor-admission";
  attribute :>> observed="Hash cleanup occurs after internal restoration and before RC reopen, with an all-member barrier after cleanup.";
  attribute :>> required="Acquire final repair completion, commit next bank once by epoch/revision, and gate reentry. Keep both banks on unknown outcome.";
  attribute :>> gap="Drop commit reply on both sides of publication; next GC with no store must preserve sole strong edges and allow weak deletions.";
  ref part :>> question=nativeAcceptance;
 }

 part minorTablePermutation:SourceSite {
  attribute :>> id="minorTablePermutation";
  attribute :>> artifact="vendor/gambit/lib/_mem/hash-table-api.inc";
  attribute :>> anchor="gc_hash_table_rehash_in_situ (ht);";
  attribute :>> role="minor-admission";
  attribute :>> observed="Native set and union/find can permute a table; pure native lookup falls back to read-only scanning.";
  attribute :>> required="Close layout leases and publish full typed coverage before permutation; invalidate all prior slot coordinates.";
  attribute :>> gap="Delay a real layout pin and a metadata-only bank pin independently at W<R.";
  ref part :>> question=aliasSource;
 }

 part minorTableFreezeJoin:SourceSite {
  attribute :>> id="minorTableFreezeJoin";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="if (!___root_round_freeze(___ps,&rc_epoch))";
  attribute :>> role="minor-admission";
  attribute :>> observed="Per-member root freeze precedes roster publication and copy planning.";
  attribute :>> required="Join current layout and dirty transition coverage to the same frozen roster before selective admission.";
  attribute :>> gap="Race freeze and permutation at both sides of invalidation; missing coverage must refuse before forwarding.";
  ref part :>> question=cutSource;
 }
 part minorTableRetentionBudget:SourceSite {
  attribute :>> id="minorTableRetentionBudget";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="if(___COLLECTION(___vms).decision!=1) {";
  attribute :>> role="minor-admission";
  attribute :>> observed="Current planning distinguishes pre-copy refusal from unknown retention. DEV fills its fixed retention credit after census; real pre-copy refusal retains the pin and leaves section count and parity unchanged, then full GC succeeds. Managed DEV replay passes the positive and carrier-exit negative within the original budget. Product table-bank accounting remains open.";
  attribute :>> required="Reserve retained storage before invalidation, query exact ACK, and refuse over budget while keeping prior coverage.";
  attribute :>> gap="At W<R exercise pinned metadata, raw access, exhausted capacity and no-new-store successor repair.";
  ref part :>> question=nativeAcceptance;
 }

 part workerGuardedPark:SourceSite {
  attribute :>> id="workerGuardedPark";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="if (--(*workers_count) == 0)";
  attribute :>> role="minor-admission";
  attribute :>> observed="DEV guarded park retries actual FIFO claim under the termination mutex before decrementing active count. Two probe-on TFIB pairs reduce body time by 11.77 and 46.09 percent and p99 by 32.65 and 61.95 percent. GCBench reverses direction across order. All eight workloads complete with valid traces. The reversed historical four-cell crossover completes all 16 no-probe runs. Its rebuilt untreated TFIB controls do not reproduce the historical positive role gap. The guarded treatment multiplies the TFIB between-role time ratio by 2.194 and 1.816, while GCBench interaction reverses. The independent counter runs show only 82 and 87 productive TFIB rechecks against 33921 and 31138 empty rechecks and 400917 and 340449 publication notifications. Counts separate the successful handoff from the cost of inspecting empty queues and notifying on every publication. They do not identify the historical regression or final tree wake. The matching historical map fixture relinks against the configured core archive; both control and guarded DEV builds reproduce identical R3 W2 and eleven complete GC markers. Two no-probe crossover pairs give TFIB body-time changes of -3.78 and +11.70 percent, and GCBench +0.87 and +15.88 percent. These are isolated park and publication treatment ratios in the same cache cohort.";
  attribute :>> required="An acquired chunk retains scan custody and the active count before releasing the termination mutex. Confirmed empty requires a completed FIFO observation. Trace the productive recheck and final closure separately from tree wake.";
  attribute :>> gap="The blocking recheck depends on a live FIFO gate owner. It does not settle interrupted claims or qualify unknown exit. The initial fixture layout mismatch is resolved by using the configured core archive and matching headers. No attribution to the historical uninstrumented 2.93 percent. Historical archives differ in 18 of 26 object members. The crossed guarded treatment has not reproduced the historical untreated gap or established a common cause.";
  ref part :>> question=nativeAcceptance;
 }

 part workerGuardedPublication:SourceSite {
  attribute :>> id="workerGuardedPublication";
  attribute :>> artifact="vendor/gambit/lib/_mem/heap-sections.inc";
  attribute :>> anchor="___CONDVAR_SIGNAL(scan_termination_condvar);";
  attribute :>> role="minor-admission";
  attribute :>> observed="DEV publication preserves initialized chunk transfer and releases the FIFO gate before taking the termination mutex for notification. Idle recheck takes the termination mutex before acquiring FIFO gates, so the publisher must not nest in the opposite order.";
  attribute :>> required="Separate work notification from barrier_sync_op tree messages. Test park before publication, publication before park, final worker idle, and nonworker carrier restoration with the same census.";
  attribute :>> gap="Recheck and notification costs need their own counters and separate treatment from final tree wake. Probe-on throughput is not a production net estimate.";
  ref part :>> question=nativeAcceptance;
 }

 part workerWaiterGatedPark:SourceSite {
  attribute :>> id="workerWaiterGatedPark";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="___VOLATILE ___WORD *workers_count = &scan_workers_count[traverse_weak_refs];";
  attribute :>> role="minor-admission";
  attribute :>> observed="The DEV variant publishes the phase-count decrement under the termination mutex before rechecking every FIFO. A hit restores the active count before unlock. Publishers check the count only after FIFO publication. ARM64 object evidence shows stlr, ldapr and casal. The exact map fixture passes at R3 W2 with eleven complete collections.";
  attribute :>> required="If publication precedes the acquired recheck, queued work must be found or already claimed. If publication follows the recheck on that FIFO, gate release/acquire orders waiter registration before the publisher count load. Full count may skip notification only with complete phase producer coverage. Closure remains under the termination mutex.";
  attribute :>> gap="The gated TFIB probe-on run counts 4336 notifications, 46 productive and 23846 empty rechecks. Its no-probe time changes by plus 2.46 and plus 157.02 percent versus unconditional guarded park; GCBench changes by minus 8.09 and minus 21.69 percent. Neither the blocked FIFO gate case nor independent final sync-tree wake is settled. No same-cause claim for the historical gap.";
  ref part :>> question=nativeAcceptance;
 }

 part workerWakeProofAdmission:SourceSite {
  attribute :>> id="workerWakeProofAdmission";
  attribute :>> artifact="vendor/gambit/lib/_mem/heap-sections.inc";
  attribute :>> anchor="if (___COMPARE_AND_SWAP_WORD(&owner->chunk_gate_,0,1) != 0)";
  attribute :>> role="minor-admission";
  attribute :>> observed="Current take returns zero for busy and observed-empty alike. Native wait probes establish notification exposure but cannot supply the localDrained or producerCoverage premise. Six existing gc_work_closure histories pass with seed 317: foreign queued work with local idle, spurious wake recount, busy own queue fault, busy custody, empty versus private drain, and publication invalidation. The fault deliberately omits localDrained; it is not a demonstrated reachable C failure. Existing map controls exercise selected histories. A new GCC C23 DEV counter overlay preserves take and idle behavior, and completes two tfib and two gcbench runs with the original 30-second cap at R3 W2. Idle decrements with the last own-queue observation busy occur 532 and 498 times for tfib, 90 and 119 for gcbench. The counters never inspect a busy queue payload. A peer could drain it, and repeated idle can reuse a previous observation. Native reachability of the observation gap is established, but live work at that cut and unsafe termination remain unproved. Gate holders occur in take or publication and unlock before scan, signal or idle. If the gate holder remains counted, busy implies some active worker at that instant; busy-before-idle does not prove a zero-count violation. The remaining source obligation is continuous queued/private coverage after gate release, including phase changes and unknown exit. A single-VM gate-updated DEV shadow depth ledger completes two tfib and two gcbench runs with no negative depth, cross-VM identity mismatch or residual queue debt. Busy-own idle observations coincide with positive shadow queued depth 134 and 148 times for tfib, 105 and 137 for gcbench. All 4994 final idle votes observe zero shadow queued debt. This resolves these samples as queued work surviving an earlier idle candidate but drained by final voting. A separate DEV extension checks five own-worker private fields immediately before idle. All 9768 observed idle candidates have drained scan frontier, still chain, active complete chunk and Tail count, with local chunk matching allocation. Four native runs pass within the original cap. Reapplying the adapter reproduces the compiled source bytes. Snapshot concurrency, helper interruption, full writer coverage and unknown-exit schedules remain separate obligations.";
  attribute :>> required="QNT gc_work_closure owns preservation across idle, publication, spurious wake and phase changes. Lean WorkAccounting owns conditional coverage algebra and queue-result implications. The C adapter must establish authoritative empty, frontier/Tail custody, claim settlement and phase freshness on its actual atomic backend. One joined phase-close acceptance covers counted publication, exact take outcome, private drain before idle, zero-count custody, strong-to-weak authority change, repaired-slot publication before R-member restoration and retained work on unknown exit. Keep original entrypoints and the fixed-steal reference. No single timing or counter pass retires this combined responsibility.";
  attribute :>> gap="A faster notification cannot qualify idle or termination while busy is collapsed with empty. Bind actual publication-to-claim and last-idle custody histories to the existing QNT actions before crediting source refinement. Reuse existing Lean premises.";
  ref part :>> question=nativeAcceptance;
 }

 part workerWakeDecision:SourceSite {
  attribute :>> id="workerWakeDecision";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="gc_real_time += real_time;";
  attribute :>> role="minor-admission";
  attribute :>> observed="R3 W2 map/PBT and native notification overlays establish scoped behavior. Removing fixed prespin helps tfib but hurts gcbench. Historical exact-image accounting places 63.3 percent of the log body contrast before final notification. Per-recipient wait and exact-epoch controls distinguish delivery from round completion.";
  attribute :>> required="Preserve one VM/epoch/member identity from allocation miss through combined request, root freeze, claim/scan completion, restored binding authorization and first Scheme reentry. Qualify with the existing full collector and map/PBT. Measure uninstrumented cost separately.";
  attribute :>> gap="Historical 2.93 percent causal identity, current-REV net benefit, OS-only wake attribution and the source of changed collection counts remain open. No current PR or independent SMP progress credit follows from historical overlays.";
  ref part :>> question=nativeAcceptance;
 }

 part workerHandoffParkResumeRefactor:SourceSite {
  attribute :>> id="workerHandoffParkResumeRefactor";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="if (--(*workers_count) == 0)";
  attribute :>> role="minor-admission";
  attribute :>> observed="Guarded recheck transfers scan custody before idle but waits on a FIFO gate. Waiter-gated publication reduces notifications without stable no-probe benefit. One exact role replay retains 683.680 ms of slowdown even with the direct reply prefix removed under fixed-other assumptions. The retained atomic-stop-native-preflight.json gcCollectorOverlay.goalEvidenceMatrix binds the diagnostic to R3 W2, eleven forced full collections, PBT seed 317 and a 30 second execution budget. Its minimal lost-child-reply history does not exercise the combined FIFO claim and park replacement. Carry it as diagnostic control evidence only. The joint native receipt must bind the intervention sources, both resolved executable identities, and each correctness and cost observation to that exact candidate; a diagnostic executable identity cannot discharge SH-EXEC-N for a different intervention.";
  attribute :>> required="One delivery replaces take, park and phase-close authority together. Sample phase availability before the trusted FIFO sweep. Claimed work transfers custody into the worker record; busy retains debt and cannot count as empty. After local drain and confirmed empty, compare the sampled sequence under the wait mutex before parking. Publishers commit FIFO custody, release the FIFO gate, then advance availability under the wait mutex; producer credit spans that entire gap, including uncertain completion. The closer never acquires FIFO gates while holding the wait mutex. Close only after all producers, private frontier and claims settle. Publish the separate R-participant resume seal via the qualified tree edge and retain notification resources through the last signal return.";
  attribute :>> gap="Native acceptance must jointly cover publication between sweep and park, publication committed with lost receipt, busy FIFO during the final idle vote, late signal during resize, and unknown worker exit. Keep the R3 W2 map and PBT replay, full GC, census and budget as correctness controls. The new path adds availability updates and predicate checks; only eliminated futile steals and waits on the critical path can pay for them. For the historical geometric ratio 1.02930, parity requires an overlay-to-current ratio at most 1/1.02930, or at least 2.847 percent reduction relative to current candidate body time, under a matching paired cohort. Exclusive critical-path work removed minus added sequence, accounting and handoff work must meet that margin. Sum overlapping carrier waits only as resource exposure, never as removable elapsed time. A lower pause percentile without paired body improvement leaves the throughput gate open. Existing notification and direct reply controls do not establish positive net benefit or mediation of the 2.93 percent historical estimate. The workspace-managed overlay source receipt binds the generator and four candidate leaves; source materialization does not qualify native execution. The source receipt also binds mem.c and its explicit private root.h include route. A direct include audit finds three checkout/cache differences: collection-round.inc has the paired frozen and repaired cuts, mem.h has different resize and global-binding declarations, and object-allocation.inc has a GC participant phase check before invoking GC. The latter two are distinct semantic source inputs. For native build reuse, derive both arms from one coherent cache source baseline and validate the effective include closure and all reused objects; a checkout overlay with cache fallbacks would otherwise describe a mixed source period. Both cuts are compile-time conditional, including the repaired barrier. The admitted optimization and benchmark pair uses the existing Darwin GCC C23 profile in both arms. Bind the resolved GCC binary, effective optimization and C23 arguments, SDK and link driver identity. Historical Clang-built diagnostics retain their original scope and cannot serve as GCC performance controls. A no-probe pair must start from the same baseline bytes and show both cuts disabled in both effective commands; the map control must explicitly bind its intended cut configuration. Never join a current overlay to a cached baseline merely from an object filename or the apparent inactivity of guarded code. The GCC C23 body crossover in gcc-worker-park-crossover.json completes eight natural exits in retained order with 30 second per-run bounds. The four links require both the existing executable mode defines and GCC selection of Apple ld instead of the PATH ld64. The raw stdout contains a standalone body elapsed line and a later reported GC subtotal. Correcting the earlier last-match extraction gives TFIB body changes plus 9.52 and 55.20 percent, geometric center plus 30.38 percent. Reported GC increases 1.217357 and 2.485381 seconds against body increases 1.297326 and 2.957278 seconds. The arithmetic differences are 0.079969 and 0.471897 seconds, without phase or causal attribution. The plus 31.48 percent center belongs to reported GC elapsed. GCBench body changes minus 11.85 and plus 7.47 percent, geometric center minus 2.67 percent; its reported GC center is minus 6.92 percent. The initial official arms use historical p3 options without proof of W2. A separate GCC body crossover explicitly pins R3 W2 in both arms through the existing worker request, aborts on disagreement, and retains census and full GC. All eight runs reach the policy marker and exit naturally within 30 seconds. TFIB body changes plus 41.20 and plus 111.20 percent, center plus 72.68 percent; GCBench changes plus 28.56 and minus 1.18 percent, center plus 12.71 percent. This contrast uses the sealed archive from the original validation receipt after detecting live-cache archive drift. The no-probe R3 W2 TFIB body increases 1.343 and 2.926 s, with 80 and 77 more reported collections. Using the control mean duration, the count components are 0.136 and 0.104 s, the mean-duration components are 0.745 and 2.186 s, and the body-minus-GC residual components are 0.462 and 0.637 s. The reported subtotal ends before final resume, so its increases cannot be direct within-round charges from site 17. This accounting leaves upstream collector cost, cross-round effects and run conditions to distinguish. Its separate one-in-sixteen phase probe completes the original eight runs with R3 W2 markers and valid traces. TFIB aggregate barrier means per carrier sample fall from 1477.34 to 1187.30 us in AB and 1813.93 to 1568.44 us in BA. Final close site 17 rises from 42.80 to 57.07 us and 25.42 to 66.84 us. Scan and idle condition buckets reverse directions across order, while take rises in both. Instrumented TFIB body times are 3.959 to 4.130 s and 3.540 to 3.601 s; these do not reproduce the magnitude of the separate no-probe result. This evidence denies a stable aggregate barrier increase in the pinned topology probe and cannot establish historical mediation. A separate no-phase-probe ablation compares the exact W2 joint candidate against removing only its inherited fixed remote steal loop before the sequence-checked sweep. All eight R3 W2 executions exit within 30 seconds. TFIB changes minus 23.37 and minus 30.02 percent, center minus 26.77 percent; GCBench changes plus 24.79 and plus 38.36 percent, center plus 31.40 percent. This exposes a workload-dependent work-distribution tradeoff, and does not measure against the original baseline. Separate matched GCC C23 map/PBT overlay builds with the same prespin deletion pass both normal and carrier-exit cases at R3 W2. Each normal case checks continuation roots and completes 11 forced full collections. Both carrier-exit cases retain custody through source-task completion without reopening the exited carrier. These four runs qualify the fixture behavior only. Symmetric GC accounting separates count from mean duration in the independent no-probe prespin ablation. For tfib the per-round duration term saves 953.11 and 962.25 ms, while count contributes plus 82.47 and minus 19.39 ms. For gcbench count adds 1181.70 and 528.10 ms despite unchanged reported allocation bytes, and mean duration contributes minus 509.92 and plus 522.10 ms. These are elapsed-time accounting terms, not causal assignments. The residual includes post-report resume. A uniform prespin deletion fails the two-workload acceptance boundary; compare any future change with both collection count and per-round work exposed. The gcbench count changes 37 to 58 and 49 to 58 at equal total reported allocation. Source qualification must join heap or stack section refusal, still request and collective dispatch to the actual VM epoch, then join resize and post-resume headroom to the next allocation interval. The capacity estimate uses assigned sections, occupied still words and overflow reserve. Equal allocation totals do not establish equal headroom or equal request combination. Trigger attribution remains open in these timing images. Source-bound request attribution observes each offered operation, selected operation and local match in execute_sync_op_loop before result overwrites arg0. COMBINING_ADD sums still words and loses contributor identity, especially for zero-word offers. Resize may invoke GC internally without a selected GC op. Lifecycle rejection and copy-plan refusal precede nb_gcs accounting. Reconcile completed rounds to the coordinator increment, keeping selected dispatch, frozen epoch and completion distinct. The two historical revisions and the inspected 568e0276 head carry byte-identical allocation-limits, capacity-resize, memory-lifecycle and collection-round source blobs. Their setup request-combine and dispatch cuts have the same source rules. The historical role delta adds binding close at root freeze inside the reported interval and binding readmission at root-round end outside it. Compare these named boundaries separately from final notification. Freeze clears each member view under that member RC lock inside the GC interval. Successful root-round end is a coordinator-serialized restored-member validation, detach and readmission loop before final release but after GC reporting. Record admission outcome because the historical caller discards it. Qualification separates last freeze arrival, coordinator prefix, final release and acquire, and actual Scheme reentry. Never remove an authority check to create the timing treatment. Shared source locations qualify instrumentation placement only; historical headers, archive members and workload identities differ. It is a topology-controlled counterexample to a demonstrated throughput benefit, not attribution of the historical p3 estimate; The GCC C23 map/PBT pair passes R3 W2 and eleven complete collections with multi-shot frame roots. Both carrier-exit controls retain custody and reject reopen. The exact fixture runs seed 317 with eight length-seven histories and the shrunk lost-child-reply control. Initial parallel GSC links collided on same-source temporary objects; the candidate link succeeded when isolated in time without rebuilding its collector object. The same GCC candidate and baseline linked with a common DEV setup pause probe complete eight natural exits in the original order. A strict reducer accepts complete ordered post-collector brackets and excludes one unmatched round per arm. TFIB accepted rounds are 3781/3989 in AB and 3628/4177 in BA for baseline/candidate. Request-to-last-resume p99 rises from 8.487 to 14.879 ms and from 4.189 to 21.963 ms. Collector-envelope p99 rises from 7.639 to 13.413 ms and from 3.737 to 19.835 ms; resume p99 rises from 0.396 to 0.721 ms and from 0.220 to 0.888 ms. These are marginal percentiles and cannot be added or treated as paired round contributions. Matched internal DEV counters complete the TFIB AB pair and both GCBench pairs; both reverse-order TFIB arms time out at the unchanged 30 second cap without terminal traces. In the complete TFIB pair, summed carrier seconds increase by 4.207 for barriers, 1.193 for copy/scan, 0.543 for take, 1.107 for idle condition and 0.004 for notify calls. Inclusive buckets overlap and the instrumentation issues tens of millions of take clock reads. A separate paired run with one in sixteen carrier-local GC entries sampled completes all eight original-order executions within the same budget. TFIB per-carrier-sample barrier means grow from 679.90 to 877.77 us in AB and from 507.92 to 1211.53 us in BA. Copy scan, take, idle condition and notification also rise in both TFIB orders. All four sampled TFIB arms record exactly sixteen barrier calls per carrier sample. Mean time per barrier increases from 42.49 to 54.86 us in AB and from 31.74 to 75.72 us in BA, while take attempts per carrier sample also increase. The historical binding-activation-exact versus sfun-entry-sdk executable identities are disjoint from the new single-mem.o GCC overlay pair. The equal barrier count excludes more recorded barriers per sample as an explanation of the measured barrier bucket increase, but does not identify the delay mechanism. A separate GCC site-counter crossover at the same sampling rate completes all eight runs and exactly reconciles site counts and nanoseconds to the aggregate. TFIB aggregate barrier time per carrier sample decreases by 107.17 us in AB and 75.36 us in BA, reversing the previous sample result. Strong scan rendezvous decreases by 47.35 and 66.50 us, and weak scan rendezvous decreases by 40.13 and 30.10 us. The final round close/resume publication increases by 4.77 and 69.73 us, respectively. In the BA pair the coordinator mean at site 17 moves from 34.70 to 35.19 us, while the two receiver means grow from 67.66 to 180.22 and from 58.65 to 154.80 us. This is receiver-local waiting, with the causal contributor unresolved. A subsequent GCC exact-epoch crossover completes all eight runs within the original limit. The TFIB AB pair joins 248 epochs per arm; BA joins 286 baseline and 250 candidate epochs. Receiver arrival skew means change from 5.05 to 13.70 us in AB and 4.20 to 2.81 us in BA. The lower bound of mean release-to-acquire changes from 12.52 to 13.14 us and from 9.99 to 13.02 us, respectively. Last-arrival-to-release means decrease in both pairs. Per-epoch rather than pooled-edge reduction gives TFIB first-arrival-to-last-exit p99 601 to 337 us in AB and 776 to 377 us in BA, while its means increase 42.39 to 49.51 us and 36.79 to 38.37 us. After the last arrival, the p99 changes 450 to 255 us in AB but 297 to 320 us in BA. Per-epoch maximum receiver release-to-acquire p99 bounds coincide at 297 to 167 us in AB and 188 to 131 us in BA. This separates aggregate tails, last-arrival tails and reply tails without adding percentiles. The exact epoch join separates these intervals; it does not identify OS wake, mutex reacquisition or historical causal mediation. Site 17 follows root_round_end inside collection-round.inc. The historical direct-reply intervention uses previous_gc in setup.c to target the following synchronous service exchange. Both use the tree transport, but the measured intervals cover distinct invocations. The existing historical setup-only GCC archive intervention gives TFIB role interactions plus 60.84, plus 6.70 and minus 50.32 percent across the three non-overlap blocks. The argument-scoped intervention gives plus 95.98 and minus 7.20 percent. These sign reversals deny stable evidence for a direct post-return reply treatment. The historical early reverse fixed-other bound still leaves 683.680 ms after eliminating the entire 280.476 ms observed candidate reply prefix. A causal bridge must alter the same named edge on both historical roles, distinguish final collector close from post-return exchange, and retain a no-probe matched contrast separately from epoch traces. The DEV final-wake treatment now maps the same checked root_round_end successor and SYNC_SEND_MSG anchors on historical b39f6944 and a9b896c4. Both arms use an identical final-barrier wrapper. The treatment moves only processor zero downward signal under the recipient mutex at R3, leaving release, acquire and the post-return exchange unchanged. Reconstructing unmodified mem.o and setup.o gives byte-identical members for both historical GCC C23 archives. The final-wake matched control and treatment then link under GCC with their retained role-specific benchmark objects. All eight no-probe TFIB executions exit naturally within 30 seconds. Role gap interaction is minus 47.51 percent in the forward block and plus 76.14 percent in reverse. The direction reversal denies a stable effect on the historical role gap for this intervention. A separate probe build of the same treatment completes all eight runs and joins exact final epochs. For sfun-entry the p99 upper bound of the per-epoch maximum receiver release-to-acquire falls from 870 to 260 us forward and 455 to 144 us reverse. Binding-activation moves from 76 to 455 us forward and 392 to 163 us reverse. The sfun-entry no-probe body time nevertheless increases from 16.718 to 19.654 s and from 18.129 to 29.563 s in the separately timed runs. A shorter final reply tail is insufficient evidence of a body-time win. In the separate no-probe sfun-entry treatment runs the reported GC count changes by only 3 and 13. Decomposing the reported GC increase against the control mean gives count components of 0.008 and 0.038 s and mean-duration components of 2.070 and 9.542 s. Body time minus the reported GC subtotal increases by another 0.858 and 1.853 s. This arithmetic locates the increase in average reported collection cost rather than count and cannot assign it to individual phases or isolate mutator CPU. The source reporting cut is earlier than the treatment: both historical collectors and current checkout accumulate gc_real_time on processor zero before prepare_mem_pstate, reopen_rc_roots, and root_round_end. The final notification cannot directly add to its own round reported subtotal. Larger subtotals can reflect changes upstream in later rounds or run conditions; the residual includes final resume and cannot be called mutator time. A separate GCC same-treatment adjacent-epoch crossover completes all eight runs and joins 236 to 258 consecutive pairs per arm; each excludes one incomplete roster. For sfun-entry the mean following-minus-current reported GC time changes from minus 163.67 to plus 82.15 us forward, but from plus 59.81 to minus 69.17 us reverse. The mean maximum release-to-acquire upper bound increases in both blocks. Within-arm correlations with following-minus-current reverse sign across the four sfun-entry arms. No consistent adjacent-round carryover is identified by this probe. The probe and timing images are separate, and these relinked wrapper contrasts do not replicate exact historical executable bytes or establish historical causal identity. This isolates a site-level direction for this block but neither establishes a stable aggregate increase nor qualifies a shared historical mediator. The historical no-probe estimate reconstructs from 18 exact-image pairs across six retained campaigns: 12 slower and six faster, with median plus 2.72 percent and pair range minus 12.26 to plus 16.70 percent. Six of nine pairs are slower in each order. Exact-image accounting verifies all 18 pairs against their retained per-order ratios. Symmetric count and mean-duration terms and the residual contribute plus 0.880, plus 0.949 and plus 1.060 log points respectively to the aggregate 2.888 log points. The first two terms account for 63.3 percent of this log contrast and lie in the reported GC subtotal ending before final notification. Omitting one campaign at a time leaves the reported subtotal at 51.1 to 68.7 percent of the paired log contrast. Count contributes positively in all six campaigns while mean duration contributes positively in three. The historical count contribution is more directionally consistent than per-round duration, so prioritize source-bound trigger and capacity receipts as well as phase timing. This is descriptive sensitivity of the retained campaigns. Further exact-image accounting splits the count term by reported allocation volume and collections per reported byte. Overall the terms are minus 2.792 and plus 3.672 log points; AB gives minus 8.561 and plus 9.399, whereas BA gives plus 2.977 and minus 2.056. Both orders still have a positive net count term. Neither more allocated bytes nor more collections per byte is directionally stable across orders as a standalone explanation. Preserve the per-epoch trigger, headroom and combining receipts rather than interpreting reported bytes as a controlled workload input. The residual includes resume but does not isolate it. This bounds a direct same-round final-notification-only account with earlier costs fixed. It does not establish the cause of the earlier cost or exclude indirect feedback. This describes the retained population and does not establish an independently reproduced effect. A hash check of tfib-named executable files in the current Modern C task cache found neither exact historical image. A wider scan hashes 15475 distinct Mach-O files in the same task cache and finds neither original image. An exact rerun needs both byte-verified original images; the historically relinked notification experiment has its own identity. Historical p3 specifies processor topology only. In both historical source revisions root_round_publish selects requested_workers when valid and otherwise uses all participants. The historical probe receipts carry no W2 evidence. Current W2 overlays explicitly set the policy. Treat topology as an independent experimental factor. The additional GCC C23 no-probe tfib companion reuses the historical notification objects and sets two workers at root_round_publish when the roster is three. All eight runs exit naturally within the unchanged 30-second cap. The sfun-entry notification treatment changes body time by -2.80 and +150.99 percent in reversed four-cell blocks; the role-gap interaction is -4.73 and +186.16 percent. This reversal survives the explicit worker policy. The attempted historical gcbench crossover has zero admitted runs. The binding-activation link receipt shows both tfib objects survived the filename substitution. The four successful executions are tfib. The four sfun-entry links contain one gcbench module descriptor with GSTATE 85864 and VMSTATE 79032. Its compiled setup guard requires 86336 and 79544. Source maps this mismatch to module incompatibility if reached. The exact dynamic setup status remains unobserved. Require workload identity, per-role module layout and benchmark completion before admitting a future crossover. The corrected GCC C23 companion recompiles both gcbench translation units per historical header, verifies all 11 linked descriptors per image and completes all eight runs within 30 seconds each. Holding notification under the mutex changes body time by -5.43 and -18.68 percent for binding-activation and by -25.01 and -17.72 percent for sfun-entry. This relinked W2 control does not recover the historical original tfib images. The corrected gcbench workload also completes all eight wait-probe runs using the same GCC C23 W2 epoch objects. One-in-16 sampling captures 23 complete rounds and 46 signal-within-wait recipients, only two or three rounds per arm/block. The evidence preserves individual windows and does not admit a gcbench tail estimate or a notification mediation claim. The separate every-round GCC C23 diagnostic completes eight runs and joins 402 rounds, matching each run reported collection count after excluding two incomplete rosters per run. For sfun-entry, locked notification increases signal-end to wait-return p95 in both orders (143 to 211 and 157 to 321 us), while the final-barrier p95 falls in one order and rises in the other (668 to 252 and 308 to 773 us). The two binding-activation recipient contrasts reverse direction. This diagnostic instrumentation does not qualify no-probe throughput or causal mediation. A separate dense adjacent-epoch gcbench diagnostic completes all eight runs and joins 40 to 55 exact successor pairs per run. In sfun-entry, final delivery delay correlates with next reported GC time at 0.23 to 0.53, but also with the current pre-notification GC time at 0.26 to 0.56 and previous GC at 0.17 to 0.31. The positive next association is not temporally specific. Residualizing both variables on current and previous reported GC and a linear epoch trend reduces the sfun-entry next association to minus 0.045 through plus 0.318 with mixed signs. The binding-activation forward locked arm retains 0.620 while its reverse locked arm has 0.106. This descriptive within-run sensitivity does not control nonlinear workload phase or scheduler state and cannot establish a mediated effect. The mean next-minus-current over contiguous epochs telescopes to the endpoints, so it is not evidence of carryover. Keep temporal controls and workload-phase confounding explicit. A dense gcbench overlay assigns final signal mode by epoch hash, with complementary images and verified receiver-side policy markers. All eight runs complete at the original budget. Matched ordinal sfun-entry barrier contrasts are minus 21.8 and 16.7 us while next reported GC contrasts are plus 1384.7 and minus 178.2 us. The current pre-signal GC control also differs by minus 783.1 and 79.7 us. Complementary ordinal pairing does not equalize workload phase or prior treatment histories. This does not establish a consistent carryover mechanism. The same complementary policy objects in tfib complete all eight runs with 1233 to 1288 joined process-scope epochs per run. One trace contains an extra epoch relative to the benchmark report. Matched ordinal sfun-entry final-barrier means change plus 4.46 and 2.28 us, next reported GC minus 215.49 and plus 168.62 us, and current pre-signal GC minus 173.58 and 267.83 us. This directly tests the target workload but still lacks stable carryover or a qualified historical whole-body bridge. Within each tfib run the hash schedule switches signal policy on about 62 percent of adjacent epochs, so policy history is not independent. Matching on the previous policy and 64-epoch windows gives sfun-entry next-GC contrasts from minus 465.75 to plus 265.73 us across the four runs. Window widths of 32 and 128 preserve the mixed direction. This sensitivity does not equalize heap state or longer history. The single-epoch tfib intervention admits a locked signal only at 4k+2, with two unlocked predecessors and an unlocked successor. All eight GCC C23 runs complete; matched blocks contain 285 to 312 slots with complementary verified exposure. In sfun-entry, final barrier means move plus 4.92 and minus 35.03 us, while next reported GC moves plus 59.52 and 89.88 us. Current pre-signal GC differs by plus 98.59 and minus 54.48 us. The next-GC sign is consistent in these two blocks but does not track the current barrier sign. Subtracting each matched slot pre-signal contrast from its next-GC contrast gives sfun-entry means minus 39.07 and plus 144.36 us and medians minus 15.74 and minus 18.72 us. Positive slots are 141 of 285 and 146 of 294. This is a descriptive sensitivity check; equal counterfactual trends are not established. The raw positive means do not support a stable shift after this control. Earlier history, heap state and exact historical image mediation remain open. All eight corrected gcbench runs report exactly 1247715344 allocated bytes. Collection counts fall 56 to 54, 52 to 35, 53 to 38, and 54 to 48. Symmetric accounting gives count contributions of minus 100, 821, 733 and 306 ms respectively, larger in magnitude than the average-duration terms in each pair. Most of the observed benefit is in the reported interval before final notification. The direct same-round notification path cannot account for that subtotal; request and post-resume capacity evidence would be needed to link the count change to the treatment. This is a relinked intervention with no separate dynamic roster probe and does not reproduce the historical original-image contrast. A separate W2 policy probe companion reproduces the historical reducer on all eight original traces, then completes eight new runs with 70 to 76 joined epochs each and no incomplete rosters. On reverse sfun-entry, release-to-acquire p99 upper bound increases from 129 to 892 us and last-arrival-to-last-exit p99 from 250 to 1103 us. The latter increases from 480 to 576 us even in the forward block where body time decreases. Reverse body delta in the probe is 405.648 ms, of which 339.612 ms is in reported GC before the final notification; no-probe reverse body delta is 2768.891 ms with 2059.017 ms reported before that cut. These are separate run populations. W2 epoch images are verified against their mode-specific setup object and compile define. The release trace brackets the payload store before either signal site. SYNC_GET_MSG can observe the payload in its spin path or during a locked recheck without ever parking. The current trace confirms delivery but cannot attest notification exposure on a blocked recipient. A follow-up must classify wait admission, actual signal site, condition return and payload observation per recipient, retaining non-parked recipients as a control. The existing DEV final-epoch adapter now offers opt-in downward-reply wait-call and return markers plus recipient-tagged signal-site brackets for this treatment. Its edit anchors were exercised on prepared snapshots of both historical sources. The DEV reducer joins the wait-call intervals and signal bracket by VM, exact epoch and recipient. Synthetic positive, non-waiting, missing-return and legacy controls pass. New campaigns must require exposure so an old trace cannot be accepted as a non-wait sample. Native GCC C23 compilation and eight tfib executions pass within the original 30-second cap. The reducer joins 1228 recipient edges, 1157 with a wait call and 1155 with the full signal bracket inside that call. Signal lock mode matches each linked treatment. These intervals establish user-space exposure only. Seven wait and epoch-policy campaigns now retain all 56 original UTF8 trace streams in repository gzip archives, keyed by role, block and mode. Each archive and each uncompressed trace has a SHA256 receipt. The existing reader exposes archive replay with required wait exposure, digest, identity and exclusion checks. All 56 replay; 40 additionally match a separately declared epoch count. Sixteen have only slot or pair counts and report epochCountDeclared=false. Missing wait return, overflow and mismatched receiver epoch mutation controls prevent affected observations from qualifying. Among recipients whose wait call contains the full signal bracket, signal-end to wait-return p95 in sfun-entry changes from 50 to 89 us forward and from 48 to 24 us reverse. Binding-activation changes from 112 to 138 and from 34 to 111 us. Exposure group membership changes between arms, and the interval includes mutex reacquisition. These strata do not establish a directionally stable sfun-entry tail treatment or OS-only latency. Exact-epoch exit attribution finds one unique last receiver in 566 of 614 rounds, and that receiver has the largest release-to-acquire upper bound in 532 rounds. Holding other exits fixed, a one-receiver signal-in-wait elision can save at most the smaller of its release-to-acquire bound and the gap to the second-last exit. In sfun-entry the p95 of this sampled opportunity changes 11 to 29 us forward and 53 to 16 us reverse. This is an opportunity bound for the stated counterfactual, not observed savings or a joint two-receiver bound. A separate two-receiver bound holds sender and noneligible exits fixed, advances eligible exits by at most their wait interval, and recomputes the maximum exit. It never adds parallel receiver delays. The sampled sfun-entry p95 opportunity for signal-start to wait-return elision changes 50 to 102 us forward and 75 to 36 us reverse. Direction remains order sensitive even when both recipients can improve. No sample-to-population or body-time extrapolation is admitted. Wait-call entry is not proof of OS descheduling. Extra probe work inside the mutex must remain outside no-probe performance claims. Existing Darwin scheduler windows cover the distinct post-return tree exchange only. They match 4536 of 7864 and 1315 of 7479 eligible windows, and 47 of 79 and 19 of 75 eligible tail windows for binding-activation and sfun-entry respectively. The unequal coverage and different call site forbid a final-barrier OS wake estimate or a population-level between-role tail estimate from these matched windows. The current-round direct final-notification interval cannot account for the majority of either reverse body delta. Earlier cost variation or inter-round effects remain possible. The W2 adjacent-epoch companion completes eight GCC C23 tfib runs in the original 30-second budget. The reducer reproduces all eight prior adjacent-epoch summaries and joins 69 to 76 exact successor pairs per new run, excluding one incomplete startup roster in each. In sfun-entry the treatment increases the mean release-to-acquire upper bound from 30.66 to 99.34 us forward and from 7.01 to 9.97 us reverse. Meanwhile the mean next-minus-current reported GC time decreases by 28.02 and 255.47 us. This does not support the simple positive carryover prediction under this notification intervention. The separate probe arms, scheduling variation and within-arm correlation sensitivity prevent a causal exclusion of other inter-round effects. The separate exact-epoch audit compares sampled per-round means without expanding the 1-in-16 samples. Current TFIB B minus A release-to-acquire upper-bound means increase by 1.17 and 4.39 us, while last-arrival-to-last-exit changes by minus 2.79 and plus 3.31 us. Historical sfun-entry final-notification treatment reduces both means in both orders: release-to-acquire by 31.70 and 8.79 us and last-arrival-to-last-exit by 41.34 and 15.69 us. The binding-activation role reverses direction. A consistently shorter sampled final synchronization path on one historical role coexists with its separately measured body regression. The treatment and current worker crossover are distinct, and the data do not establish a shared mechanism. Critical-path qualification keys all R barrier observations and W collector observations by VM lifetime, frozen epoch and phase. For a complete ordered roster, split first arrival to last arrival, last arrival to last exit, and last exit to latest first Scheme resumption. Keep each participant exit-to-first-Scheme interval separately for overlap. Join queue publications and claims to the corresponding phase by work identity, with busy distinct from observed empty. Do not sum inclusive carrier waits or queue spans as elapsed wall time. A direct final-notification treatment cannot add to the earlier same-round GC report; test proposed carryover on an exact successor epoch and both run orders. A paired sign audit separates the final barrier from earlier barriers. In the W2 tfib phase cohort, final site 17 adds 14.27 and 41.43 us per carrier sample, while the other barriers together fall by 304.31 and 286.92 us. The independent source-site census shows the same sign split and locates reductions at strong completion (47.35 and 66.50 us) and weak completion (40.13 and 30.10 us). Neither census establishes same-epoch covariance or a critical-path saving. This rejects uniform barrier movement as a description of these samples and prioritizes separate arrival and release observations. The normalized intervals are inclusive and not joined across carriers by round. The evidence distinguishes observed interval locations but does not partition the uninstrumented 30.38 percent body gap, attribute OS wake latency, or establish the cause of the historical 2.93 percent. These body results deny a demonstrated TFIB net gain and do not identify mediation of the historical 2.93 percent estimate.";
  ref part :>> question=nativeAcceptance;
 }

 part workerClaimEffectExit:SourceSite {
  attribute :>> id="workerClaimEffectExit";
  attribute :>> artifact="vendor/gambit/lib/_mem/heap-sections.inc";
  attribute :>> anchor="require_chunk_transition(work,node+1,1,2);";
  attribute :>> role="minor-admission";
  attribute :>> observed="Take calls require_chunk_transition under the FIFO gate. Its mismatch calls fatal_error. The nested change_object_scan_state calls fatal_error for a header outside destination before returning minus one. os_base dispatches the configured fatal hook before process exit. The claimed counter is incremented after head advancement and read by no current native control predicate.";
  attribute :>> required="The managed take core must return closed typed failures from both mismatch and destination validation without dispatching effects inside the gate. Record a known no-mutation rejection only when this operation has not changed the chunk or head. Invariant failure retains phase debt even after gate release. After the one-to-two transition, keep the claim in the VM slot through unlink, result loss and scan. Derive diagnostic counts from committed decisions instead of replaying an increment.";
  attribute :>> gap="The proposed effect-free split has no native implementation. A mismatched preexisting chunk owner is not cleared by a failed take. Unknown writer or gate use requires retained custody before any diagnostic callback and prevents phase closure. Existing QNT owns ordering and Lean owns receipt identity without duplicate proofs.";
  ref part :>> question=nativeAcceptance;
 }

 part workerRoundResumePermission:SourceSite {
  attribute :>> id="workerRoundResumePermission";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="if(___COLLECTION(___vms).decision!=1) {";
  attribute :>> role="minor-admission";
  attribute :>> observed="The pre-copy path synchronizes the planning decision and its observation by every participant before coordinator refusal. root_round_refuse checks census refusal, untouched root tasks and all participants' observations. Unknown planning instead reaches rc_contract_error. The success epilogue restores arenas and continuations, reopens RC roots and synchronizes around root_round_end. Both end paths attempt binding-context refresh; the refresh cannot create lifecycle entry and its Boolean is ignored.";
  attribute :>> required="Separate PrecopyRefused, Restored and Retained. Only the first two may authorize participant resume via a common round disposition after coordinator completion and each participant's acquire. Refusal requires no copy, repair or claimed work. Restored requires actual arena and continuation restoration, completed root work and root reopening. Neither the overflow Boolean nor an attempted binding refresh is a resume credential. Retained preserves roots, outstanding claims and provider storage until settlement and last-use closure.";
  attribute :>> gap="The existing pre-copy refusal is a no-effect exit, with no post-claim rollback. Prove the publication/acquire relation for the actual barrier backend and route both GC and resize through the same disposition before admitting a recoverable post-claim exit. Unknown failure remains held or fatal under current source. No tfib timing attribution follows from these source cuts.";
  ref part :>> question=nativeAcceptance;
 }

 part workerScanParkPredicate:SourceSite {
  attribute :>> id="workerScanParkPredicate";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="if (--(*workers_count) == 0)";
  attribute :>> role="minor-admission";
  attribute :>> observed="The scan loop finishes local work, retries steals, then decrements the phase worker count under scan_termination_mutex. A nonfinal worker waits and checks the count on return. heap-sections.inc publishes chunk links under the FIFO gate and signals after releasing that gate, without the termination mutex. This site is distinct from the setup.c tree barrier, whose wait rechecks its acquire predicate under its receiver mutex.";
  attribute :>> required="Couple producer publication and worker sleep with one phase-scoped availability sequence and a check-to-park protocol. Publish custody before advancing availability, then use the wait mutex or an atomic compare-and-park primitive to make the final check and wait indivisible to the notifier. A sequence increment prompts retry; it grants neither work ownership nor termination. Only trusted empty observations plus producer closure and settled claims authorize phase close. The nonworker root participant observes the round disposition separately.";
  attribute :>> gap="Test the schedule where W0 finishes its last steal before W1 publishes and signals, W0 then decrements and parks, and W1 starts its own idle transition. A notification alone cannot preserve the earlier publish across the check-to-park window. Whether a queued chunk is still owed at final decrement also depends on publisher local drainage and the busy-versus-empty distinction. This is a source-derived schedule to qualify, with no observed lost work or attribution to the measured tfib regression.";
  ref part :>> question=nativeAcceptance;
 }

 part workerPhaseCloseDebt:SourceSite {
  attribute :>> id="workerPhaseCloseDebt";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-scanning.inc";
  attribute :>> anchor="while ((ptr=take_heap_chunk(work,work)) != 0)";
  attribute :>> role="minor-admission";
  attribute :>> observed="Both the local FIFO drain and the remote steal treat a busy gate like an empty queue. The current idle count does not record a worker's observed availability generation. The published, claimed and completed counters are diagnostic, without a closure consumer.";
  attribute :>> required="Preserve one live debt from before a chunk can become discoverable through queued, claimed and fully scanned states. Child debt must exist before parent settlement, including work introduced by the weak phase. A sequence change invalidates an older empty observation even when its worker has not resumed. Do not use a sum of idle votes as a substitute for zero live debt. Certify closure under the phase authority only after admission and producer credits are closed, phase debt is zero and local frontier obligations are settled. With live debt and a busy gate, preserve a runnable progress path or identify the notifier that owns the next availability change. If that notifier is unknown, retain the phase rather than allowing all workers to park indefinitely.";
  attribute :>> gap="Native negative control must force local take to see a busy gate, delay the earlier sleeper after publication, and attempt the last idle vote with live debt. A second cut must release a busy gate without a fresh enqueue and verify a progress path. Accounting may be batched only if reservation precedes visibility and refund follows settlement. These source-derived requirements add no measured performance gain.";
  ref part :>> question=nativeAcceptance;
 }

 part minorGcCollectorCosts:SourceSite {
  attribute :>> id="minorGcCollectorCosts";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="___CONDVAR_WAIT(scan_termination_condvar,scan_termination_mutex);";
  attribute :>> role="minor-admission";
  attribute :>> observed="An exact-artifact DEV map and PBT replay reproduces R=3 W=2, eleven forced full collections, and the frame root markers under the original budget. Carrier two records barriers and no copy-scan bucket. DEV-only probes time per-carrier root and copy scan, work search, idle condition waits, collective barriers, capacity planning, and selected allocator gates and calls. In the uninstrumented reverse block, candidate TFIB body elapsed rises 894 ms and reported GC rises 721 ms; candidate GCBench body elapsed falls 182 ms while reported GC rises 190 ms. The arithmetic residual does not identify mutator time or a collector phase. A third exact-artifact uninstrumented block completed all eight runs with TFIB throughput up 0.30 percent and GCBench down 9.06 percent. Opposite-order adjacent comparisons reverse within each workload, so neither direction qualifies as stable. A later 16-run same-session ABBA and BAAB crossover also reverses direction for each workload. Equal-order geometric throughput estimates are plus 1.33 percent for TFIB and plus 3.07 percent for GCBench, with no stable direction admitted. A descriptive five-block sensitivity analysis estimates plus 0.25 percent for TFIB and minus 2.28 percent for GCBench. Both leave-one-block-out ranges cross zero. A later balanced randomized adjacent-pair block gives minus 3.37 percent for TFIB and plus 20.83 percent for GCBench, with both pair ranges crossing zero and only six assignments per workload. A re-reduction of eight exact instrumented pause traces finds TFIB request-to-last-resume p99 up 46.67 and 38.62 percent in adjacent pairs and GCBench down 9.93 and 44.32 percent. GCBench p99 is the observed maximum at these run sizes. In the slowest one percent of TFIB rounds per run, candidate mean pause grows 23.800 and 5.063 ms, with collector-envelope increments of 21.093 and 4.961 ms. The all-invocation allocator census observes zero calls at three section gates in each TFIB role and 26 calls across six allocation and free sites per role. Inclusive durations of 21 and 23 us correspond to 5.07 and 5.89 ppm of reported GC time within the instrumented runs. GCBench exercises the gate probes. Wait inside native calls and outside the selected sites remains unresolved. In the full-run TFIB recorder control, five per-entry native allocator totals reconcile exactly to the independent 26-call census at 9.415 us inclusive, with no section gate hits. Two totals have no admitted R3 envelope; three map to pauses ranked 603, 1148 and 1826 of 4240. None of the 43 slowest rounds enters the instrumented sites. These call envelopes bound internal wait at the covered sites without identifying allocator lock ownership. The exact TFIB recorder Mach-O branches all four Gambit allocation wrappers to the malloc or free stubs, including the heap-named pair. The selected call envelopes do not qualify libc-internal lock or syscall attribution, nor other wrapper callers outside the six probes. The paired DEV allocator clock control records 26 TFIB calls with 19.209 us outer wall and 15.208 us nested thread CPU, and 147 GCBench calls with 254.499 and 222.164 us respectively. TFIB has zero section gate hits; GCBench has 933 with 31.731 us inclusive. Wall minus nested CPU includes measurement overhead and cannot identify libc lock time. The DEV GCBench OS control brackets 11 of 151 native calls with valid same-carrier anchors. Ten contain no selected scheduler events. A 199.667 us call contains three dispatch-class records but no unique runnable-to-dispatch chain. The remaining 140 calls are outside anchor coverage. The TFIB repeat with the previously used full trace capacity reconciles 26 allocator intervals to its census. All 26 precede or fall outside admitted same-carrier OS anchor coverage despite successful recorder export. The TFIB per-table export does not recover startup coverage. Carrier syscall rows start at 2.983 s in the recorder clock. The thread-state table shows one leading Blocked row spanning startup through 2.983 s, while user trace records real allocator calls in that span. The 650 ms recorder attempt exits 54 without a terminal workload trace. Neither source qualifies a startup allocator wait. A recorder-first TFIB control admits two of 26 native calls, at 1.125 and 0.667 us. The same TID stays Running across both entire outer clock windows. Off-CPU wait is absent in those observed intervals; on-CPU spinning remains within the inclusive envelope. The other 24 calls lack anchor coverage. The delayed recorder-first TFIB repeat separates 20 calls outside accepted R3 envelopes from six calls inside three of 4565 R3 rounds. Two R3 calls remain Running throughout their calibrated windows, totaling 10.416 us. The four other R3 calls have a combined inclusive envelope of 14.250 us, with no qualified scheduler state. A 2.9 s launch-offset control completes the TFIB workload and census, but the recorder stalls after its three-second limit and is terminated before saving. User evidence places six of 26 calls inside accepted R3 rounds with a 43.958 us inclusive total. No OS state is credited to this run. In the constructor-stop DEV control with 2.5 s release after recorder readiness, all 26 TFIB allocator windows and all six inside admitted R3 collector rounds are bracketed by same-carrier kernel anchors. Each entire conservative window is Running. The inclusive totals are 12.665 us across all calls and 7.374 us across R3 calls; on-CPU allocator wait remains bounded by these totals. The earlier 2.2 s release misses all calls. These diagnostic controls make no production or throughput claim. This neither establishes an internal lock wait nor excludes blocking. The same GCBench call is classified by the System Trace thread-state table as three fully contained preemptions totaling 178.916 us. Syscall stacks show XZM allocation through mach_vm_map in adjust_msections. One trap is wholly enclosed; one overlaps a clock-uncertain entry boundary. The export does not establish libc lock wait. The steady DEV entry windows retain 30 of 4203 TFIB and two of 56 GCBench R3 rounds with all three carrier traces. The slowest sampled TFIB pause is 1.978 ms; its last collector carrier records 643.209 us copy and scan, 385.167 us steal search, 250.502 us barrier, and 28.873 us outside the interval union. These windows lack same-round OS joins. A joint TFIB run ties 30 three-carrier rounds to a trace containing exact GVM completions, with 1.167 us from last resume to operation completion in its slowest covered round. Two three-second OS recordings each export scheduler rows but reject all 24 and 23 candidate waits respectively outside same-carrier anchor brackets. No joint OS attribution is admitted. The 2.8 s attach control observes 30 full carrier cohorts and 29 exact last-resume operation witnesses. The latest sampled condition returns precede the first admitted same-carrier clock anchors by about 4.06 s. Its 47.797 ms maximum is recorder-on diagnostic evidence; the last collector carrier records 32.816 ms of barrier wall time. Full-run inclusive collector totals cover all 4240 accepted TFIB R3 rounds. In the recorder-on TFIB comparison, carrier 2 exits last in 42 of the 43 slowest rounds and 33 of the 43 middle rounds. Holding that carrier identity fixed, median barrier condition time rises from 0.489 to 9.061 ms while median copy scan drops from 0.424 to 0.051 ms and steal search drops from 0.228 to 0.063 ms. This locates where time is observed on that carrier; it does not identify the peer or scheduler event causing the wait. Same-trace thread states fully cover seven of the 43 slowest TFIB collector intervals after conservative clock clipping. In rank eight, 12.054 ms of the 13.292 ms collector interval has no carrier Running, and 12.051 ms of that interval has at least one carrier Runnable or Preempted. Across the seven, no-carrier-running spans range from 6.009 to 12.054 ms. This recorder-on evidence distinguishes scheduler delay from peers executing collector work for these intervals, without extrapolating to the unobserved tail or recorder-off throughput. The same DEV executable with the recorder off reproduces the barrier-heavy tail. Pause p99 is 11.617 and 6.909 ms in two recorder-off runs, versus 8.642 ms in the recorder-on run. Median barrier condition time on last-exiting carrier 2 among the slowest percentile is 13.698 and 8.098 ms off, versus 9.061 ms on. This is a nonconsecutive descriptive control; the off runs have no OS-state attribution. Of these, 4205 have exact last-resume GVM completion and 73 have a collector condition wake-to-GVM join. In one 1.971 ms round the last collector and last resume carrier records 518.874 us copy scan, 185.501 us steal search and 1097.540 us barrier including 1001.169 us condition wait. Its exact condition runnable-to-switch is 4.958 us and final resume to operation completion is 25.209 us. The OS match is an in-collector wait, and operation completion is a GVM witness. Final-resume attribution uses exact collector exit and resume identities without requiring an earlier sampled condition publication. The full-run capture yields 398 R3 rounds with a matched signal call, OS dispatch and GVM completion on the final carrier. In the longest such round, 14.215 ms, the final carrier spends 228.416 us runnable before switch and 0.709 us from resume to verified GVM completion. Instruction retirement and allocator-internal blocking remain unresolved. In the 14.215 ms matched round, the exact Mach-O host offset 0x3fdec and tagged Scheme label offset 0x43e181 lead to the instrumented F64UNBOX at make-thread label 1. The successful operation bracket implies execution of the required ldur at image offset 0x3ffb4 between 584 and 709 ns after resume. This is a control-flow bound; retirement time is not directly observed. A DEV LLDB attempt against the exact TFIB executable stops producing output at launch and times out without reaching the F64UNBOX breakpoint. A separately compiled ARM64 main control also times out at launch. The control-flow bound of 584 to 709 ns remains the available machine-path evidence. Of 4240 recorded TFIB rounds, the final-resume signal join covers 398 and five of the 43 highest pauses. Runnable-to-switch has median 7.292 us and p95 157.625 us in the matched subset. Holding peer resume endpoints and all other durations fixed, removing that final-carrier delay could reduce the round by a median 6.500 us, p95 71.292 us and maximum 304.667 us. This diagnostic subset and counterfactual do not establish a throughput benefit. Matching wall and thread CPU counts at sampled barriers yield CPU shares of 2.492 and 2.039 percent in the two watchdog-ended TFIB traces. Both GCBench controls exit naturally with shares below 0.3 percent. A later four-run natural-exit DEV block directly times the sync condition call within sampled barriers: 93.04 to 95.07 percent of TFIB carrier barrier wall and over 99 percent for GCBench. The call includes scheduler delay and mutex reacquisition; those portions remain unresolved. The same-call scheduler overlay emitted 286 valid user-space intervals without the recorder; the System Trace attempt returned 139 and export returned a missing-template error, so no same-call kernel join is admitted from that run. A later 8-second attach saved the System Trace under an independent 30-second workload watchdog and retained 367 condition intervals. Raw export succeeded and matched 11 unique same-TID runnable-to-switch chains, totaling 301.914 us. This sparse bounded prefix does not isolate sleep or mutex reacquisition. A per-call anchored capture later exited naturally and matched 20 of 424 condition intervals, totaling 1533.999 us of recorded runnable-to-switch time. Exported anchor spans cover only 0.74 to 0.80 s per carrier. Re-export establishes that 1441998 raw rows cover just 879.322 ms of the 9.056742 s saved run; the isolated marker table has 45 rows. The missing earlier history is already absent before join filtering. Official uninstrumented pairs give geometric candidate body-time changes of +3.48 percent for tfib and -17.24 percent for gcbench. A sequential mix breaks even at 16.81 percent gcbench baseline body time using point estimates. Both worst observed ratios exceed one. Separate pause p99 pairs retain opposite workload directions. The reversed-order official replay changes tfib body time by +5.35 percent and gcbench by +3.94 percent. Across the two blocks the changes are +4.41 and -7.25 percent respectively. Gcbench reverses sign between blocks. The exact map control again completes 11 full collections at R3 W2. The final uninstrumented AB and BA crossover retains eight natural exits. TFIB candidate body time changes by plus 11.76 and minus 7.66 percent across the two orders, with a geometric center of plus 1.59 percent. GCBench changes by plus 1.63 and minus 15.10 percent, centered at minus 7.11 percent. Both signs reverse. The exact map replay again matches its retained markers with R3 W2 and 11 full collections. An exact-artifact synthesis over six retained campaigns uses 18 adjacent candidate/baseline body-time ratios per workload with equal AB and BA counts. TFIB body time rises 2.930 percent and GCBench falls 4.390 percent on the paired geometric estimate. Equal campaign weighting gives plus 3.162 and minus 3.652 percent. Each leave-one-campaign-out estimate preserves its workload direction, while individual campaign ranges still cross zero. This descriptive synthesis uses different weights and source blocks from the earlier five-block role-mean sensitivity; it does not establish causal or production gain.";
  attribute :>> required="Keep nested carrier wall times separate from whole-round critical path and measure throughput on the uninstrumented paired artifacts.";
  attribute :>> gap="Internal wait reasons require kernel scheduling correlation. The first observed benchmark label does not establish the first instruction executed in runtime Scheme code.";
  ref part :>> question=nativeAcceptance;
 }

 part minorTakeoverFrontier:SourceSite {
  attribute :>> id="minorTakeoverFrontier";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-scanning.inc";
  attribute :>> anchor="work->active_scan_chunk_ = start;";
  attribute :>> role="minor-admission";
  attribute :>> observed="Complete-chunk scan advances a C-local cursor; the active chunk records identity without exact progress.";
  attribute :>> required="Bind canonical frontier to settled writes, forwarding/copy and child debt before changing executor.";
  attribute :>> gap="Stop after first repaired slot and before checkpoint at W<R; verify remaining sole edge without duplicate repair.";
  ref part :>> question=nativeAcceptance;
 }
 part minorTakeoverWeak:SourceSite {
  attribute :>> id="minorTakeoverWeak";
  attribute :>> artifact="vendor/gambit/lib/_mem/weak-tables.inc";
  attribute :>> anchor="body[___GCHASHTABLE_NEXT] = ___FIX(0);";
  attribute :>> role="minor-admission";
  attribute :>> observed="Cleanup consumes intrusive NEXT before finishing pair, count and flags writes.";
  attribute :>> required="Keep durable typed weak custody and settle a partial pair before advancing.";
  attribute :>> gap="Lose publication or finish reply and reject duplicate deletion or early bank retirement.";
  ref part :>> question=nativeAcceptance;
 }

 part minorAtomicStop:SourceSite {
  attribute :>> id="minorAtomicStop";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-scanning.inc";
  attribute :>> anchor="scan_and_advance(ptr, head); /* note: this advances ptr */";
  attribute :>> role="minor-admission";
  attribute :>> observed="Native chunk cursor advances locally, with no atomic frontier/owner handoff. A DEV pthread carries its fixture permit across actual R=3/W=2 frozen and repaired cuts; collector-owned writes and exit remain open.";
  attribute :>> required="Drain admitted helper permits then atomically publish STOPPED and successor authorization with the settled frontier.";
  attribute :>> gap="Delay a helper across close, reject old tokens, and query lost transfer reply.";
  ref part :>> question=nativeAcceptance;
 }
 part minorWeakCommit:SourceSite {
  attribute :>> id="minorWeakCommit";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-scanning.inc";
  attribute :>> anchor="body[0] = reached_gc_hash_tables;";
  attribute :>> role="minor-admission";
  attribute :>> observed="Weak work uses an intrusive worker list with no durable result receipt. DEV staged scanner observes the real list insertion; suppressed fixture delivery is settled once per epoch, and the full GC sole-edge control repairs both rounds.";
  attribute :>> required="Reserve exact child intent and atomically publish child custody and committed result.";
  attribute :>> gap="Lose reply after publication; verify exact query with one weak child and no duplicate list effect.";
  ref part :>> question=nativeAcceptance;
 }
 part frameAccessDomain:SourceSite {
  attribute :>> id="frameAccessDomain";
  attribute :>> artifact="vendor/gambit/lib/_mem/copy-reservations.inc";
  attribute :>> anchor="___HIDDEN void acquire_frame_access";
  attribute :>> role="synchronization";
  attribute :>> observed="Collector frame access uses the VM collection frame gate and releases it after source/link repair";
  attribute :>> required="Prove CAS acquire and clear release on each supported C platform; keep queue locks out of frame acquisition and all semantic mutators parked";
  attribute :>> gap="Collector serialization alone neither versions shared aliases nor enforces generational write barriers";
  ref part :>> question=aliasSource;
 }
 part packetWholePauseCost:SourceSite {
  attribute :>> id="packetWholePauseCost";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="prepare_mem_pstate (___ps);";
  attribute :>> role="implementation-handoff";
  attribute :>> observed="Reported GC time precedes prepare_mem_pstate, reopen_rc_roots, root_round_end and the final member barrier. The report therefore omits part of the complete root-to-resume interval.";
  attribute :>> required="Pair uninstrumented equal-work controls; use separate probes to attribute request/park/collector/restore/wake and first Scheme reentry. Count simultaneous physical intervals and metadata, keeping census and heap unchanged. Gate correctness separately from a measured net-benefit claim.";
  attribute :>> gap="Historical rebuilt cohorts and collector-only reports do not establish current-source pause, throughput or peak benefit, and outside-report time is not exclusively an OS-wakeup cost.";
  ref part :>> question=netBenefit;
 }
 part globalRootStores:SourceSite {
  attribute :>> id="globalRootStores";
  attribute :>> artifact="vendor/gambit/lib/_mem/global-bindings.inc";
  attribute :>> anchor="___BOOL ___try_store_global";
  attribute :>> role="root-writer";
  attribute :>> observed="Ordinary global store uses cooperative owner gate and release word store; primitive stores also use global gate";
  attribute :>> required="No poll/callback between admission and last store; publish one shared count/pages view and cover all VM writers";
  attribute :>> gap="Atomic payload publication does not itself freeze a source or close cross-VM template/bootstrap writers";
  ref part :>> question=cutSource;
 }
 part bankRootScanners:SourceSite {
  attribute :>> id="bankRootScanners";
  attribute :>> artifact="vendor/gambit/lib/_mem/root-origins.inc";
  attribute :>> anchor="___BOOL ___root_task_scan_bank";
  attribute :>> role="scanner";
  attribute :>> observed="Bank scanner covers register/saved/cache/processor Scheme-object spans";
  attribute :>> required="Every generator and native-entry root maps to exactly the canonical admitted span; every relocation updates that span";
  attribute :>> gap="A larger processor struct is not an all-word root map; temp/error state and metadata require explicit classification";
  ref part :>> question=cutSource;
 }
 part symbolRootStores:SourceSite {
  attribute :>> id="symbolRootStores";
  attribute :>> artifact="vendor/gambit/lib/_mem/symbols.inc";
  attribute :>> anchor="___HIDDEN void symkey_table_set";
  attribute :>> role="root-writer";
  attribute :>> observed="Symbol/keyword table pointer assignment, intern growth and permanent table checks form a separate source family";
  attribute :>> required="Bootstrap/permanent publication and runtime interning must be frozen or proven immutable under their actual source locks";
  attribute :>> gap="Permanent allocation class alone is not proof against mutation or concurrent table/header publication";
  ref part :>> question=cutSource;
 }
 part stillRootProducer:SourceSite {
  attribute :>> id="stillRootProducer";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-scanning.inc";
  attribute :>> anchor="setup_still_objs_to_scan";
  attribute :>> role="supplemental-root-producer";
  attribute :>> observed="GC setup and scan transport include still-object strong-root production outside the six direct root tasks";
  attribute :>> required="Publish a consistent still list/count view with required copy/scan/weak/restore debt; payload and refcount writers obey the same cut";
  attribute :>> gap="Direct-root completion does not prove every still/foreign/will producer closed; existing GW-S source obligation retains ownership";
  ref part :>> question=cutSource;
 }
 part canonicalCellRepair:SourceSite {
  attribute :>> id="canonicalCellRepair";
  attribute :>> artifact="vendor/gambit/lib/_mem/copy-reservations.inc";
  attribute :>> anchor="*cell = ___TAG(alloc - ___REFERENCE_TO_BODY, ___TYP(obj));";
  attribute :>> role="canonical-slot-store";
  attribute :>> observed="Winning copy path repairs the incoming canonical cell after forwarding publication and before payload copy, scan publication and commit_copy";
  attribute :>> required="The store denotes forward(before logical slot); later payload initialization and Tail debts remain owned until whole observation is permitted";
  attribute :>> gap="Per-store algebra does not establish all canonical slots covered, all destinations initialized or all live forwarding targets distinct";
  ref part :>> question=aliasSource;
 }
 part chunkPublish:SourceSite {
  attribute :>> id="chunkPublish";
  attribute :>> artifact="vendor/gambit/lib/_mem/heap-sections.inc";
  attribute :>> anchor="___HIDDEN void end_heap_chunk";
  attribute :>> role="chunk-publisher";
  attribute :>> observed="Closes chunk marker, transitions private0 to queued1 and publishes FIFO link/tail with barriers under chunk gate, then signals waiters";
  attribute :>> required="Publisher remains accounted until final publication/local scan use; selected backend orders initialized payload and link before acquired dequeue";
  attribute :>> gap="Two barrier calls are not by themselves a C memory-order proof; last-idle and failed/unknown transfer need complete producer coverage";
  ref part :>> question=cutSource;
 }
 part chunkClaim:SourceSite {
  attribute :>> id="chunkClaim";
  attribute :>> artifact="vendor/gambit/lib/_mem/heap-sections.inc";
  attribute :>> anchor="___HIDDEN ___WORD *take_heap_chunk";
  attribute :>> role="queue-to-private-transfer";
  attribute :>> observed="Failed chunk-gate CAS returns no observation; success changes queued1 to claimed2 and moves the head before returning the private chunk";
  attribute :>> required="Claimant owns active/dequeued work until chunk completion or accepted transfer, even after the FIFO no longer names it";
  attribute :>> gap="No-work return is not an empty-queue proof; a stopped or unknown claimant needs retained physical/work custody";
  ref part :>> question=cutSource;
 }
 part claimDiagnosticIncrement:SourceSite {
  attribute :>> id="claimDiagnosticIncrement";
  attribute :>> artifact="vendor/gambit/lib/_mem/heap-sections.inc";
  attribute :>> anchor="work->chunks_claimed_++;";
  attribute :>> role="non-idempotent-claim-diagnostic-write";
  attribute :>> observed="Diagnostic increment follows head update and precedes gate clear/return; no durable per-operation outcome is recorded";
  attribute :>> required="A lagging progress log cannot authorize repeating an increment. Reconcile from immutable before/after data under writer exclusion, or derive diagnostics from committed records; never use the counter as claim authority";
  attribute :>> gap="Native exact-write and source-closed readback are unproved; current QNT scans counts logical unique claim transitions, not this C counter's crash atomicity";
  ref part :>> question=cutSource;
 }
 part latePrivateClaimRegistration:SourceSite {
  attribute :>> id="latePrivateClaimRegistration";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-scanning.inc";
  attribute :>> anchor="work->active_scan_chunk_ = start;";
  attribute :>> role="post-return-private-custody-registration";
  attribute :>> observed="scan_complete_heap_chunk assigns active chunk and origin after take_heap_chunk returned the removed node";
  attribute :>> required="VM-owned pending claim identity must cover the preceding return/exception window; pointer presence is not full immutable commit or last-user evidence";
  attribute :>> gap="Current fields do not provide exact-key query, delivery acknowledgment or interruption settlement; no native query endpoint exists yet";
  ref part :>> question=cutSource;
 }
 part bulkGcNotification:SourceSite {
  attribute :>> id="bulkGcNotification";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="___raise_interrupt_pstate (___ps, ___INTR_GC);";
  attribute :>> role="post-gc-notification-not-effect-discharge";
  attribute :>> observed="Collection raises GC interrupt; kernel GC interrupt handler finalizes and executes queued jobs";
  attribute :>> required="Retain pending notification and permit handler execution only at compatible effect boundary; memory completion differs from notification completion";
  attribute :>> gap="GC completion does not establish that hooks have run or can safely run during bulk operation";
  ref part :>> question=cutSource;
 }
 part bulkStackRelocation:SourceSite {
  attribute :>> id="bulkStackRelocation";
  attribute :>> artifact="vendor/gambit/lib/_mem/allocation-limits.inc";
  attribute :>> anchor="memmove (alloc_stack_ptr - words,";
  attribute :>> role="runtime-control-stack-bulk-move";
  attribute :>> observed="Stack growth copies raw frame words after break-frame setup";
  attribute :>> required="Bind frame coordinates and roots to existing stack/continuation consumer; keep private pointer scope distinct from semantic boxed mutation";
  attribute :>> gap="A vector card barrier alone cannot qualify frame relocation or hidden stack roots";
  ref part :>> question=cutSource;
 }
 part runtimeVectorInitialization:SourceSite {
  attribute :>> id="runtimeVectorInitialization";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-allocation.inc";
  attribute :>> anchor="___VECTORELEM(obj, i) = init;";
  attribute :>> role="native-vector-initialization";
  attribute :>> observed="make_vector allocates then fills reference slots before returning";
  attribute :>> required="Keep init rooted, valid scan shape and initialization/publication ordering; separate published updates";
  attribute :>> gap="Constructor exemption requires actual no-escape and collecting-boundary evidence";
  ref part :>> question=cutSource;
 }
 part mutatorRegionPlacement:SourceSite {
  attribute :>> id="mutatorRegionPlacement";
  attribute :>> artifact="vendor/gambit/lib/_mem/configuration.inc";
  attribute :>> anchor="#define alloc_heap_ptr          ___PSTATE_MEM(alloc_heap_ptr_)";
  attribute :>> role="current-mutator-placement-coupling";
  attribute :>> observed="Mutator allocation aliases PSTATE memory fields while chunk/frontier macros use collector work; existing movable/still/permanent classes are not age-selective generations";
  attribute :>> required="Assign future allocation region and capacity to explicit execution/VM lifetime; do not infer object privacy or independent collection from a local pointer";
  attribute :>> gap="Context-local nursery/remembered-set and finer-domain implementation are candidates, not established by these aliases";
  ref part :>> question=cutSource;
 }
 part lastWorkerIdle:SourceSite {
  attribute :>> id="lastWorkerIdle";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="if (--(*workers_count) == 0)";
  attribute :>> role="phase-active-count-close";
  attribute :>> observed="After local work and stealing, decrement occurs under termination mutex; zero broadcasts, nonzero waits and increments on reawakening";
  attribute :>> required="Project count to counted active owners; idle requires local owned private/queued/dequeued/Tail drain, not globally empty FIFOs. Every remaining queued item retains an active publisher or claimant; nonterminal wake increments count even without visible work";
  attribute :>> gap="Existing QNT now admits foreign-queued local idle, but actual own-FIFO drain also treats failed CAS as empty; no authoritative localDrained certificate follows. Correct that queue-result responsibility and prove layout/producer/backend/wait/phase/last-user coverage before admitting the decrement";
  ref part :>> question=cutSource;
 }
 part localQueueDrain:SourceSite {
  attribute :>> id="localQueueDrain";
  attribute :>> artifact="vendor/gambit/lib/_mem/object-scanning.inc";
  attribute :>> anchor="while ((ptr=take_heap_chunk(work,work)) != 0)";
  attribute :>> role="owner-local-drain-admission";
  attribute :>> observed="Own-FIFO loop exits on zero, but take_heap_chunk returns zero for both failed gate CAS and acquired empty queue; code then switches to incomplete local chunk";
  attribute :>> required="Separate acquired chunk, authoritative empty and no observation at the existing queue interface; local idle needs real FIFO/frontier/Tail drain while an opportunistic thief may skip busy";
  attribute :>> gap="Source obstruction to localDrained is established; a full native premature-zero schedule is not. Retain queued custody and gate/arena lifetime on busy or unknown results; no runtime edit in this research session";
  ref part :>> question=cutSource;
 }
 part stealQueueCaller:SourceSite {
  attribute :>> id="stealQueueCaller";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="___WORD *ptr = take_heap_chunk(work,victim);";
  attribute :>> role="opportunistic-foreign-queue-caller";
  attribute :>> observed="Victim loop scans a returned chunk then restarts local work; zero currently skips a victim for either busy or empty";
  attribute :>> required="Acquired consumes registered claim; busy and empty may both skip victim but never certify caller local drain; preserve configured steal budget and return to local closure after useful work or wake";
  attribute :>> gap="Actual status/out-pointer switch and return-gap claim registration are unimplemented; no source/native pass inferred from loop shape";
  ref part :>> question=cutSource;
 }
 part queueRestoreConsumer:SourceSite {
  attribute :>> id="queueRestoreConsumer";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="if(!___gc_arena_handoff";
  attribute :>> role="post-weak-queue-and-arena-consumer";
  attribute :>> observed="After weak phase barrier, raw head/tail and cursor checks precede retiring local chunk and arena handoff";
  attribute :>> required="These are quiescent postconditions after all publishers/claims/users close, not unlocked concurrent empty queries; a gate or unknown user must not survive arena transfer";
  attribute :>> gap="Whole-phase last-user and return-fragment coverage must justify the raw observations; wrapping only a check cannot establish lifetime closure";
  ref part :>> question=cutSource;
 }
 part workerQueueInit:SourceSite {
  attribute :>> id="workerQueueInit";
  attribute :>> artifact="vendor/gambit/lib/_mem/heap-sections.inc";
  attribute :>> anchor="heap_chunks_to_scan_head = &heap_chunks_to_scan;";
  attribute :>> role="worker-queue-round-initialization";
  attribute :>> observed="setup_stack_heap_vmstate resets sentinel/head/tail and private scan fields and initializes phase counts to W";
  attribute :>> required="Previous collection's gate/queue/claim users are closed before reuse; initialization is not an atomic recovery of unknown old work";
  attribute :>> gap="Existing preceding-round comment and partial preflight debt checks do not establish complete queue last-user exclusion";
  ref part :>> question=cutSource;
 }
 part capturedFramePublisher:SourceSite {
  attribute :>> id="capturedFramePublisher";
  attribute :>> artifact="vendor/gambit/lib/_mem/continuation-roots.inc";
  attribute :>> anchor="___HIDDEN void mark_captured_continuation_locked";
  attribute :>> role="frame-copy-producer";
  attribute :>> observed="Frame-body/link repair precedes publish_object_scan and commit_copy; full destination chunks call end_heap_chunk while frame-chain traversal continues";
  attribute :>> required="Frame producer remains counted through forwarding, destination initialization, next-frame cursor and publication; frame exclusion and copy debt are independent of object scan DONE";
  attribute :>> gap="Ordinary object producer coverage alone omits this real publisher; frame access, last use and exceptional stop still require complete C refinement";
  ref part :>> question=cutSource;
 }
 part weakWorkProducer:SourceSite {
  attribute :>> id="weakWorkProducer";
  attribute :>> artifact="vendor/gambit/lib/_mem/collection-round.inc";
  attribute :>> anchor="___HIDDEN void garbage_collect_mark_weak_phase";
  attribute :>> role="next-phase-production-and-close";
  attribute :>> observed="process_wills visits R sources assigned over W workers before a second mark_reachable_from_marked; later physical restore and cleanup have all-R barriers";
  attribute :>> required="Strong terminal cut cannot retire weak producer authority; no old-phase publisher crosses phase reuse; restore, still cleanup and owner-affine debt have separate closure";
  attribute :>> gap="Need complete producer/caller census, phase barriers and refusal/unknown custody mapping, not one zero counter or DRAINING enum";
  ref part :>> question=cutSource;
 }
}
