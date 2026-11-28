import DelayedLedger
import MarkerTransport
import WeakAdmission
namespace TransportComposition
abbrev L := DelayedLedgerAst.State
abbrev M := MarkerTransportAst.State
abbrev W := WeakAdmissionAst.State
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
def project (q : L) : W := {phase:=(if q.phase=4 then 3 else q.phase), strongDebt:=q.strongDebt,active:=q.debt,kind:=q.kind,strongClosed:=q.strongClosed, da:=q.da,db:=q.db,rootsClosed:=q.rootsClosed}
theorem initialProject : project DelayedLedgerAst.initial=WeakAdmissionAst.initial := by rfl

theorem drainStrongSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.drainStrongGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.drainStrongNext q)) := by
 have hg : WeakAdmissionAst.drainStrongGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.drainStrongGuard,WeakAdmissionAst.drainStrongGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.drainStrongNext q)=WeakAdmissionAst.drainStrongNext (project q) := by
  simp_all [project,DelayedLedgerAst.drainStrongGuard,DelayedLedgerAst.drainStrongNext,WeakAdmissionAst.drainStrongNext] <;> rfl
 exact Or.inl ⟨hg,he⟩
theorem freezeStrongSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.freezeStrongGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.freezeStrongNext q)) := by
 have hg : WeakAdmissionAst.freezeStrongGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.freezeStrongGuard,WeakAdmissionAst.freezeStrongGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.freezeStrongNext q)=WeakAdmissionAst.freezeStrongNext (project q) := by
  simp_all [project,DelayedLedgerAst.freezeStrongGuard,DelayedLedgerAst.freezeStrongNext,WeakAdmissionAst.freezeStrongNext] <;> rfl
 exact Or.inr (Or.inl ⟨hg,he⟩)
theorem classifyASimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.classifyAGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.classifyANext q)) := by
 have hg : WeakAdmissionAst.classifyAGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.classifyAGuard,WeakAdmissionAst.classifyAGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.classifyANext q)=WeakAdmissionAst.classifyANext (project q) := by
  simp_all [project,DelayedLedgerAst.classifyAGuard,DelayedLedgerAst.classifyANext,WeakAdmissionAst.classifyANext] <;> rfl
 exact Or.inr (Or.inr (Or.inl ⟨hg,he⟩))
theorem classifyBSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.classifyBGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.classifyBNext q)) := by
 have hg : WeakAdmissionAst.classifyBGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.classifyBGuard,WeakAdmissionAst.classifyBGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.classifyBNext q)=WeakAdmissionAst.classifyBNext (project q) := by
  simp_all [project,DelayedLedgerAst.classifyBGuard,DelayedLedgerAst.classifyBNext,WeakAdmissionAst.classifyBNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩)))
theorem enterWeakSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.enterWeakGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.enterWeakNext q)) := by
 have hg : WeakAdmissionAst.openWeakGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.enterWeakGuard,WeakAdmissionAst.openWeakGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.enterWeakNext q)=WeakAdmissionAst.openWeakNext (project q) := by
  simp_all [project,DelayedLedgerAst.enterWeakGuard,DelayedLedgerAst.enterWeakNext,WeakAdmissionAst.openWeakNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩))))
theorem acceptDelayedSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.acceptDelayedGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.acceptDelayedNext q)) := by
 have hg : WeakAdmissionAst.continuationProducerGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.acceptDelayedGuard,WeakAdmissionAst.continuationProducerGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.acceptDelayedNext q)=WeakAdmissionAst.continuationProducerNext (project q) := by
  simp_all [project,DelayedLedgerAst.acceptDelayedGuard,DelayedLedgerAst.acceptDelayedNext,WeakAdmissionAst.continuationProducerNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩)))))))))
theorem sealDelayedSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.sealDelayedGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.sealDelayedNext q)) := by
 have he : project (DelayedLedgerAst.sealDelayedNext q)=project q := by
  simp_all [project,DelayedLedgerAst.sealDelayedGuard,DelayedLedgerAst.sealDelayedNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem publishAcceptedSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.publishAcceptedGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.publishAcceptedNext q)) := by
 have he : project (DelayedLedgerAst.publishAcceptedNext q)=project q := by
  simp_all [project,DelayedLedgerAst.publishAcceptedGuard,DelayedLedgerAst.publishAcceptedNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem observeReceiptSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.observeReceiptGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.observeReceiptNext q)) := by
 have he : project (DelayedLedgerAst.observeReceiptNext q)=project q := by
  simp_all [project,DelayedLedgerAst.observeReceiptGuard,DelayedLedgerAst.observeReceiptNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem claimSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.claimGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.claimNext q)) := by
 have he : project (DelayedLedgerAst.claimNext q)=project q := by
  simp_all [project,DelayedLedgerAst.claimGuard,DelayedLedgerAst.claimNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem deriveChildSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.deriveChildGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.deriveChildNext q)) := by
 have hg : WeakAdmissionAst.deriveChildGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.deriveChildGuard,WeakAdmissionAst.deriveChildGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.deriveChildNext q)=WeakAdmissionAst.deriveChildNext (project q) := by
  simp_all [project,DelayedLedgerAst.deriveChildGuard,DelayedLedgerAst.deriveChildNext,WeakAdmissionAst.deriveChildNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩)))))))))))
theorem settleParentSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.settleParentGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.settleParentNext q)) := by
 have hg : WeakAdmissionAst.settleTaskGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.settleParentGuard,WeakAdmissionAst.settleTaskGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.settleParentNext q)=WeakAdmissionAst.settleTaskNext (project q) := by
  simp_all [project,DelayedLedgerAst.settleParentGuard,DelayedLedgerAst.settleParentNext,WeakAdmissionAst.settleTaskNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩))))))))))))
theorem settleChildSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.settleChildGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.settleChildNext q)) := by
 have hg : WeakAdmissionAst.settleTaskGuard (project q) := by
  have hd := DelayedLedger.childrenCoveredByDebt q h
  have hg := g
  simp only [DelayedLedgerAst.settleChildGuard] at hg
  have hp : q.phase=2 := hg.1
  have ha : 0<q.debt := by omega
  simp [WeakAdmissionAst.settleTaskGuard,project,hp,ha]
 have he : project (DelayedLedgerAst.settleChildNext q)=WeakAdmissionAst.settleTaskNext (project q) := by
  simp_all [project,DelayedLedgerAst.settleChildGuard,DelayedLedgerAst.settleChildNext,WeakAdmissionAst.settleTaskNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩))))))))))))
theorem closeRootsSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.closeRootsGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.closeRootsNext q)) := by
 have hg : WeakAdmissionAst.closeRootsGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.closeRootsGuard,WeakAdmissionAst.closeRootsGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.closeRootsNext q)=WeakAdmissionAst.closeRootsNext (project q) := by
  simp_all [project,DelayedLedgerAst.closeRootsGuard,DelayedLedgerAst.closeRootsNext,WeakAdmissionAst.closeRootsNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩)))))))))))))
theorem finishWeakSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.finishWeakGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.finishWeakNext q)) := by
 have hg : WeakAdmissionAst.finishWeakGuard (project q) := by
  have hs := h
  simp only [DelayedLedgerAst.Safe] at hs
  rcases hs with ⟨hh0,hh1,hh2,hh3,hh4,hh5,hh6,hh7,hh8,hh9,hh10,hh11,hh12,hh13,hh14,hh15,hh16,hh17,hh18,hh19,hh20,hh21,hh22,hh23,hh24,hh25,hh26⟩
  simp_all [project,DelayedLedgerAst.Safe,DelayedLedgerAst.finishWeakGuard,WeakAdmissionAst.finishWeakGuard] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
 have he : project (DelayedLedgerAst.finishWeakNext q)=WeakAdmissionAst.finishWeakNext (project q) := by
  simp_all [project,DelayedLedgerAst.finishWeakGuard,DelayedLedgerAst.finishWeakNext,WeakAdmissionAst.finishWeakNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩))))))))))))))
theorem closeFutureUsersSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.closeFutureUsersGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.closeFutureUsersNext q)) := by
 have he : project (DelayedLedgerAst.closeFutureUsersNext q)=project q := by
  simp_all [project,DelayedLedgerAst.closeFutureUsersGuard,DelayedLedgerAst.closeFutureUsersNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem releaseHeadSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.releaseHeadGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.releaseHeadNext q)) := by
 have he : project (DelayedLedgerAst.releaseHeadNext q)=project q := by
  simp_all [project,DelayedLedgerAst.releaseHeadGuard,DelayedLedgerAst.releaseHeadNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem retireEpochSimulates (q : L) (h : DelayedLedgerAst.Safe q) (g : DelayedLedgerAst.retireEpochGuard q) : WeakAdmissionAst.Step (project q) (project (DelayedLedgerAst.retireEpochNext q)) := by
 have he : project (DelayedLedgerAst.retireEpochNext q)=project q := by
  simp_all [project,DelayedLedgerAst.retireEpochGuard,DelayedLedgerAst.retireEpochNext] <;> rfl
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem stepSimulates (q r : L) (h : DelayedLedgerAst.Safe q) (st : DelayedLedgerAst.Step q r) : WeakAdmissionAst.Step (project q) (project r) := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18
 · rcases a0 with ⟨g,rfl⟩; exact drainStrongSimulates q h g
 · rcases a1 with ⟨g,rfl⟩; exact freezeStrongSimulates q h g
 · rcases a2 with ⟨g,rfl⟩; exact classifyASimulates q h g
 · rcases a3 with ⟨g,rfl⟩; exact classifyBSimulates q h g
 · rcases a4 with ⟨g,rfl⟩; exact enterWeakSimulates q h g
 · rcases a5 with ⟨g,rfl⟩; exact acceptDelayedSimulates q h g
 · rcases a6 with ⟨g,rfl⟩; exact sealDelayedSimulates q h g
 · rcases a7 with ⟨g,rfl⟩; exact publishAcceptedSimulates q h g
 · rcases a8 with ⟨g,rfl⟩; exact observeReceiptSimulates q h g
 · rcases a9 with ⟨g,rfl⟩; exact claimSimulates q h g
 · rcases a10 with ⟨g,rfl⟩; exact deriveChildSimulates q h g
 · rcases a11 with ⟨g,rfl⟩; exact settleParentSimulates q h g
 · rcases a12 with ⟨g,rfl⟩; exact settleChildSimulates q h g
 · rcases a13 with ⟨g,rfl⟩; exact closeRootsSimulates q h g
 · rcases a14 with ⟨g,rfl⟩; exact finishWeakSimulates q h g
 · rcases a15 with ⟨g,rfl⟩; exact closeFutureUsersSimulates q h g
 · rcases a16 with ⟨g,rfl⟩; exact releaseHeadSimulates q h g
 · rcases a17 with ⟨g,rfl⟩; exact retireEpochSimulates q h g
 · exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (by simp [a18]))))))))))))))))
theorem reachableProjects (q : L) (h : DelayedLedger.Reachable q) : WeakAdmission.Reachable (project q) := by
 induction h with
 | start => rw [initialProject]; exact WeakAdmission.Reachable.start
 | next h st ih => exact WeakAdmission.Reachable.next ih (stepSimulates _ _ (DelayedLedger.reachableSafe _ h) st)
theorem projectedSafety (q : L) (h : DelayedLedger.Reachable q) : WeakAdmissionAst.Safe (project q) := by
 exact WeakAdmission.reachableSafe _ (reachableProjects q h)
theorem phaseMonotone (q r : L)  (st : DelayedLedgerAst.Step q r) : q.phase≤r.phase := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18
 · rcases a0 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.drainStrongGuard,DelayedLedgerAst.drainStrongNext] <;> omega
 · rcases a1 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.freezeStrongGuard,DelayedLedgerAst.freezeStrongNext] <;> omega
 · rcases a2 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.classifyAGuard,DelayedLedgerAst.classifyANext] <;> omega
 · rcases a3 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.classifyBGuard,DelayedLedgerAst.classifyBNext] <;> omega
 · rcases a4 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.enterWeakGuard,DelayedLedgerAst.enterWeakNext] <;> omega
 · rcases a5 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.acceptDelayedGuard,DelayedLedgerAst.acceptDelayedNext] <;> omega
 · rcases a6 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.sealDelayedGuard,DelayedLedgerAst.sealDelayedNext] <;> omega
 · rcases a7 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.publishAcceptedGuard,DelayedLedgerAst.publishAcceptedNext] <;> omega
 · rcases a8 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.observeReceiptGuard,DelayedLedgerAst.observeReceiptNext] <;> omega
 · rcases a9 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.claimGuard,DelayedLedgerAst.claimNext] <;> omega
 · rcases a10 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.deriveChildGuard,DelayedLedgerAst.deriveChildNext] <;> omega
 · rcases a11 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.settleParentGuard,DelayedLedgerAst.settleParentNext] <;> omega
 · rcases a12 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.settleChildGuard,DelayedLedgerAst.settleChildNext] <;> omega
 · rcases a13 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.closeRootsGuard,DelayedLedgerAst.closeRootsNext] <;> omega
 · rcases a14 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.finishWeakGuard,DelayedLedgerAst.finishWeakNext] <;> omega
 · rcases a15 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.closeFutureUsersGuard,DelayedLedgerAst.closeFutureUsersNext] <;> omega
 · rcases a16 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.releaseHeadGuard,DelayedLedgerAst.releaseHeadNext] <;> omega
 · rcases a17 with ⟨g,rfl⟩; simp_all [DelayedLedgerAst.retireEpochGuard,DelayedLedgerAst.retireEpochNext] <;> omega
 · rw [a18]; omega
theorem exposedProtocolStable (q r : M) (hx : q.exposed=true) (st : MarkerTransportAst.Step q r) : r.mode=q.mode ∧ r.exposed=true := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12
 · rcases a0 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.chooseAtomicGuard,MarkerTransportAst.chooseAtomicNext] <;> omega
 · rcases a1 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.chooseSplitGuard,MarkerTransportAst.chooseSplitNext] <;> omega
 · rcases a2 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.exposeGuard,MarkerTransportAst.exposeNext] <;> omega
 · rcases a3 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.plainReadGuard,MarkerTransportAst.plainReadNext] <;> omega
 · rcases a4 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.atomicReadGuard,MarkerTransportAst.atomicReadNext] <;> omega
 · rcases a5 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.acquireGateGuard,MarkerTransportAst.acquireGateNext] <;> omega
 · rcases a6 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.plainWriteGuard,MarkerTransportAst.plainWriteNext] <;> omega
 · rcases a7 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.atomicWriteGuard,MarkerTransportAst.atomicWriteNext] <;> omega
 · rcases a8 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.finishReadGuard,MarkerTransportAst.finishReadNext] <;> omega
 · rcases a9 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.finishWriteGuard,MarkerTransportAst.finishWriteNext] <;> omega
 · rcases a10 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.releaseGateGuard,MarkerTransportAst.releaseGateNext] <;> omega
 · rcases a11 with ⟨g,rfl⟩; simp_all [MarkerTransportAst.retireStorageGuard,MarkerTransportAst.retireStorageNext] <;> omega
 · rw [a12]; exact ⟨rfl,hx⟩
def TransportPermit (m : M) : Prop := 1≤m.mode ∧ m.exposed=true ∧ m.alive=true
def CombinedSafe (m : M) (l : L) : Prop := MarkerTransportAst.Safe m ∧ DelayedLedgerAst.Safe l ∧ (l.phase<4 → m.alive=true) ∧ (3≤l.chunk → 1≤m.mode ∧ m.exposed=true)
def CombinedStep (m : M) (l : L) (m' : M) (l' : L) : Prop :=
 (MarkerTransportAst.Step m m' ∧ l'=l ∧ (m'.alive=false → l.phase=4)) ∨
 (DelayedLedgerAst.Step l l' ∧ m'=m ∧ ((l.chunk<3 ∧ 3≤l'.chunk) → TransportPermit m))

theorem combinedStepPreserves (m m' : M) (l l' : L)
 (h : CombinedSafe m l) (st : CombinedStep m l m' l') : CombinedSafe m' l' := by
 rcases h with ⟨hm,hl,hlife,htransport⟩
 rcases st with ⟨ms,he,hr⟩ | ⟨ls,he,hp⟩
 · subst l'
   refine ⟨MarkerTransport.stepPreserves _ _ hm ms,hl,?_,?_⟩
   · intro hlp
     cases ha:m'.alive with
     | false => have hc := hr ha; omega
     | true => rfl
   · intro hchunk
     have ht := htransport hchunk
     have hs := exposedProtocolStable _ _ ht.2 ms
     exact ⟨by omega,hs.2⟩
 · subst m'
   refine ⟨hm,DelayedLedger.stepPreserves _ _ hl ls,?_,?_⟩
   · intro hlp
     have hmono := phaseMonotone _ _ ls
     exact hlife (by omega)
   · intro hchunk
     by_cases hold:3≤l.chunk
     · exact htransport hold
     · have ht := hp ⟨by omega,hchunk⟩; exact ⟨ht.1,ht.2.1⟩

theorem combinedInitialSafe : CombinedSafe MarkerTransportAst.initial DelayedLedgerAst.initial := by
 refine ⟨MarkerTransport.initialSafe,DelayedLedger.initialSafe,?_,?_⟩
 · simp [MarkerTransportAst.initial]
 · simp [DelayedLedgerAst.initial]

inductive CombinedReachable : M → L → Prop where
 | start : CombinedReachable MarkerTransportAst.initial DelayedLedgerAst.initial
 | next {m m' l l'} : CombinedReachable m l → CombinedStep m l m' l' → CombinedReachable m' l'
theorem combinedReachableSafe (m : M) (l : L) (h : CombinedReachable m l) : CombinedSafe m l := by
 induction h with
 | start => exact combinedInitialSafe
 | next _ st ih => exact combinedStepPreserves _ _ _ _ ih st

theorem publicationUsesManagedTransport (m m' : M) (l l' : L)
 (st : CombinedStep m l m' l') (hn : l.chunk<3) (hp : 3≤l'.chunk) : TransportPermit m := by
 rcases st with ⟨_,he,_⟩ | ⟨_,_,hpermit⟩
 · subst l'; omega
 · exact hpermit ⟨hn,hp⟩

theorem lifetimeGuardNecessary : MarkerTransportAst.retireStorageGuard MarkerTransportAst.initial ∧ ¬CombinedSafe (MarkerTransportAst.retireStorageNext MarkerTransportAst.initial) DelayedLedgerAst.initial := by
 simp [MarkerTransportAst.retireStorageGuard,MarkerTransportAst.retireStorageNext,MarkerTransportAst.initial,DelayedLedgerAst.initial,CombinedSafe]

def sealedExample : L := {DelayedLedgerAst.initial with phase:=2,chunk:=2,debt:=1,accepted:=1,kind:=4,strongDebt:=0,strongClosed:=true,da:=true,db:=true,sealed:=true,receiptPin:=true}
def legacyExposed : M := {MarkerTransportAst.initial with exposed:=true}
theorem transportGuardNecessary : CombinedSafe legacyExposed sealedExample ∧ DelayedLedgerAst.publishAcceptedGuard sealedExample ∧ DelayedLedgerAst.Safe (DelayedLedgerAst.publishAcceptedNext sealedExample) ∧ ¬CombinedSafe legacyExposed (DelayedLedgerAst.publishAcceptedNext sealedExample) := by
 simp [CombinedSafe,legacyExposed,sealedExample,MarkerTransportAst.Safe,MarkerTransportAst.initial,DelayedLedgerAst.Safe,DelayedLedgerAst.initial,DelayedLedgerAst.publishAcceptedGuard,DelayedLedgerAst.publishAcceptedNext]
end TransportComposition
