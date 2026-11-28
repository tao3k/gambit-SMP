/* Model-owned handoff/contracts declarations; imported by shared-heap-smp.sysml. */
package GambitSharedHeapSmpHandoffContracts {
 private import GambitSharedHeapSmp::*;

 part rootHandoff:HandoffProtocol {
  attribute :>> id="root-freeze-handoff";
  attribute :>> key="VM incarnation + pinned source origin + admission/enrollment scope established before fallible work; target slot identity and payload revision when known; round/task epoch and assignment incarnation are distinct observations";
  attribute :>> joinRule="Parent ACK requires known installed payload and durable target protection in every overlapping collection prefix. Under the parent source gate, commit the matching ACK decision and counter-only loan discharge once; no recursive public RC release is called while that gate is held. Across sources, target protection is sealed first and target settlement follows after releasing the parent gate, with no two-source nesting. Physical free and source clearing retain access/last-user guards. GC resume still requires root/copy/Tail/weak/physical restore closure; observation never waits for it.";
  attribute :>> scope="One whole generator/native borrower/root scanner/restore/exit responsibility. Supports same-VM sharing and multi-shot control; ordinary successful cooperative windows need no per-instruction transaction log";
  attribute :>> valuePolicy="Never encode installation or stop state using Scheme payload FAL; do not equate data equality, node membership, scan DONE, VM entry or join status with another role";
  attribute :>> unknownRule="Distinguish committed, known refused/absent and unknown. Retain original source loan, possible target root, query/record pins and physical debt until exact identity observation settles it; no destructive replay, double ACK or timeout-based release";
  attribute :>> retirement="No origin/control reuse or counter wrap while permitted old observers or unacknowledged loans remain. Use bounded existing VM/source/activation records; retain byte-only descriptors separately when heap access is proven closed. ACKED result stays queryable until its accepted consumer right is closed by known consumption or qualified abandonment; target settlement alone cannot authorize SETTLED/IDLE";
  attribute :>> acceptance="All real point gaps and existing root-freeze clauses close together; selected producer/platform source refinement plus complete affected native/PBT manifests and independent cost evidence; no local Python/SDK/ASCENT result creates runtime permission";
  attribute :>> nonGoals="These receipt roles are necessary facts, not seven allocated objects, new C namespaces, an executor or another QNT/Lean state machine. Broader scheduler/FFI/Actor policy remains separately owned";
  ref part :>> adapter=freezeAdapter;
 }
 part installedRoot:HandoffReceipt {
  attribute :>> id="installedRoot";
  attribute :>> kind="install";
  attribute :>> identity="Origin/enrollment scope, target canonical slot, payload installation revision and target lifetime/protection owner";
  attribute :>> condition="Source and target identities match; payload installation and durable target root protection known for overlapping/current and future collection prefixes; parent loan held until ACK and physical removal obeys its own guards";
  attribute :>> outcomes="committed / known-refused / unknown";
  attribute :>> permits="Matching parent/source loan may be acknowledged only for committed protection; synchronous known control flow can supply the fact";
  attribute :>> forbids="Membership, FAL value, unrelated success or scan completion is insufficient; ACK alone cannot free source/control storage or bypass parked-access and old-reader guards";
  attribute :>> unknown="Keep source and possible target protection and metadata debt until exact settlement; known refusal does not erase partial resource cleanup";
  ref part :>> protocol=rootHandoff;
 }
 part parkedBorrow:HandoffReceipt {
  attribute :>> id="parkedBorrow";
  attribute :>> kind="park";
  attribute :>> identity="Source origin, lifetime loan, activation/read scope, collection epoch and complete caller/root view";
  attribute :>> condition="All raw payload reads/writes closed; pending initialization/result roots published; lifetime pin remains valid";
  attribute :>> outcomes="parked / known-refused / unknown";
  attribute :>> permits="Source can join the frozen cut; collector uses its separate claimed scan authority";
  attribute :>> forbids="Lifetime count, const pointer, OS wait or logical close cannot sign physical data quiescence";
  attribute :>> unknown="Retain source and native access debt; do not enter the moving cut until closure is known";
  ref part :>> protocol=rootHandoff;
 }
 part sealedProducers:HandoffReceipt {
  attribute :>> id="sealedProducers";
  attribute :>> kind="producer";
  attribute :>> identity="VM/round epoch, supplemental still/list/count/payload/weak producer population and work-accounting owner";
  attribute :>> condition="All prior admitted root-status writes are before selection; late roots retain an already admitted source and a proved accounting path";
  attribute :>> outcomes="sealed / admitted-late-work / retained-unknown";
  attribute :>> permits="Still prefix and subsequent work can be consumed consistently under existing collector ownership";
  attribute :>> forbids="Six direct RootTask kinds or an atomic count alone cannot establish producer closure";
  attribute :>> unknown="Keep writer/source/root and work debt; no unrooted resurrection or premature finish/reopen";
  ref part :>> protocol=rootHandoff;
 }
 part scanProgress:HandoffReceipt {
  attribute :>> id="scanProgress";
  attribute :>> kind="scan";
  attribute :>> identity="Pinned origin, round/task epoch, current assignment incarnation, worker/task lease and scan state";
  attribute :>> condition="Known assigned worker owns claim; source remains frozen; all progress observations correspond to that same task";
  attribute :>> outcomes="ready / claimed / scanning / rewritten / done / unknown";
  attribute :>> permits="Describe local scan state; only existing worker authority may execute/complete scan";
  attribute :>> forbids="No parent ACK, payload access, source release or whole-round resume follows from DONE";
  attribute :>> unknown="Retain source, unique copy/scan/frontier and physical debt; do not reset or requeue partial destructive work";
  ref part :>> protocol=rootHandoff;
 }
 part originObservation:HandoffReceipt {
  attribute :>> id="originObservation";
  attribute :>> kind="observe";
  attribute :>> identity="VM/source lifetime pin acquired before lookup, source kind/member or shard, prebound admission identity, payload installation revision and round epoch; assignment incarnation is a separate field and grants no observer authority";
  attribute :>> condition="Validate prebound VM/source lifetime before task lookup; read scalar installation/task facts under the published metadata owner shared by all matching readers/writers. Release metadata guards before any scan or wait. Round facts carry their own matching epoch/publication evidence, not an invented atomic multi-record snapshot. End short query read access after scalar output capture; retain admission/target settlement separately. A known absent result needs complete closed admission scope; stale, superseded or unobserved detail is not absence and never grants reentry.";
  attribute :>> outcomes="lookup match/stale/unobserved; installation private/enrolled-empty/committed/known-refused/unknown; independent task state and round state with a separate restored permission. These are a product observation, not one DONE/false flag.";
  attribute :>> permits="Settle the matching observation only; caller applies the distinct installation/resume/retirement guards";
  attribute :>> forbids="Cannot claim/execute a scan, treat false as absence, revive a retired identity or read payload while parked";
  attribute :>> unknown="Keep query/source/target pins and parent debt; record reuse remains blocked until observers settle";
  ref part :>> protocol=rootHandoff;
 }
 part roundResume:HandoffReceipt {
  attribute :>> id="roundResume";
  attribute :>> kind="resume";
  attribute :>> identity="VM/round epoch, complete source set, physical restore grant, rewritten root/view revisions and reentry scope";
  attribute :>> condition="All required root/copy/Tail/strong/weak/memory work settled; context has accepted restored storage; acquire reentry refreshes canonical roots/bindings";
  attribute :>> outcomes="restored-and-admitted / known-refused / unknown";
  attribute :>> permits="Read canonical slot under renewed data authority, reload after any GC, then resume semantic writes";
  attribute :>> forbids="Local scan DONE, owner-affine effect completion or old copied payload is not this permission";
  attribute :>> unknown="Keep frozen/restore responsibility; no callback/GC wait cycle and no old-address continuation restart";
  ref part :>> protocol=rootHandoff;
 }
 part sourceRetired:HandoffReceipt {
  attribute :>> id="sourceRetired";
  attribute :>> kind="retire";
  attribute :>> identity="Source/control incarnation and every borrower/observer/initializer/native resource last-use owner";
  attribute :>> condition="First close new logical admission while allowing matching accepted-key settlement; close that settlement admission only after every accepted install/ACK obligation is settled or safely abandoned. Then all short readers, frozen-view/scan borrowers, cleanup claims and actual native last users end before IDLE/rebind/free. Counter and epoch wrap is refused. Source loan release, task completion and byte-resource retirement remain distinct; uncertain records cannot enter the idle cache. ACKED must remain queryable until known result consumption or qualified abandonment closes its accepted consumer right; target settlement alone is insufficient. SETTLED and final pin drain precede IDLE/free.";
  attribute :>> outcomes="retired / retained / unknown";
  attribute :>> permits="Release exactly the authorized source/record/gate/PSTATE storage, respecting affinity";
  attribute :>> forbids="No timeout, failed join, local task DONE or logical phase alone permits reclamation";
  attribute :>> unknown="Retain needed source/gate/control storage; isolate unrelated VM work only with safe shared-global dependencies";
  ref part :>> protocol=rootHandoff;
 }
}
