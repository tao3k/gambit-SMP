import NodePool
import TransportComposition
namespace NodePoolComposition
abbrev P := NodePoolAst.State
abbrev W := WeakAdmissionAst.State
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
def project (q : P) : W := {phase:=(if q.phase=2 ∨ q.phase=3 ∨ q.phase=4 then 3 else 2),strongDebt:=0,active:=q.debt,kind:=q.kind,strongClosed:=true,da:=true,db:=true,rootsClosed:=q.rootsClosed}
theorem projectedSafe (q : P) (h : NodePoolAst.Safe q) : WeakAdmissionAst.Safe (project q) := by
 simp only [NodePoolAst.Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
 have nonneg : q.debt>=0 := by omega
 by_cases en : q.phase=2 ∨ q.phase=3 ∨ q.phase=4
 · have hh := h22 (by omega)
   rcases hh with ⟨hr,hd⟩
   simp [project,en,WeakAdmissionAst.Safe,hr,hd]
   omega
 · simp [project,en,WeakAdmissionAst.Safe]
   omega

theorem admitSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.admitGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.admitNext q)) := by
 have he : project (NodePoolAst.admitNext q)=project q := by
  rcases g with ⟨gp,gc⟩
  simp [project,NodePoolAst.admitNext,gp]
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))

theorem rejectSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.rejectGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.rejectNext q)) := by
 have he : project (NodePoolAst.rejectNext q)=project q := by
  rcases g with ⟨gp,gc⟩
  simp [project,NodePoolAst.rejectNext,gp]
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))

theorem reserveSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.reserveGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.reserveNext q)) := by
 have hg : WeakAdmissionAst.continuationProducerGuard (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.reserveGuard,WeakAdmissionAst.continuationProducerGuard] <;> omega
 have he : project (NodePoolAst.reserveNext q)=WeakAdmissionAst.continuationProducerNext (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.reserveGuard,NodePoolAst.reserveNext,WeakAdmissionAst.continuationProducerNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩)))))))))
theorem deriveSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.deriveGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.deriveNext q)) := by
 have hg : WeakAdmissionAst.deriveChildGuard (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.deriveGuard,WeakAdmissionAst.deriveChildGuard] <;> omega
 have he : project (NodePoolAst.deriveNext q)=WeakAdmissionAst.deriveChildNext (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.deriveGuard,NodePoolAst.deriveNext,WeakAdmissionAst.deriveChildNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩)))))))))))
theorem sealSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.sealGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.sealNext q)) := by
 have he : project (NodePoolAst.sealNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.sealGuard,NodePoolAst.sealNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem publishSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.publishGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.publishNext q)) := by
 have he : project (NodePoolAst.publishNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.publishGuard,NodePoolAst.publishNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem claimSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.claimGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.claimNext q)) := by
 have he : project (NodePoolAst.claimNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.claimGuard,NodePoolAst.claimNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem finishSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.finishGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.finishNext q)) := by
 have hg : WeakAdmissionAst.settleTaskGuard (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.finishGuard,WeakAdmissionAst.settleTaskGuard] <;> omega
 have he : project (NodePoolAst.finishNext q)=WeakAdmissionAst.settleTaskNext (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.finishGuard,NodePoolAst.finishNext,WeakAdmissionAst.settleTaskNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩))))))))))))
theorem observeSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.observeGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.observeNext q)) := by
 have he : project (NodePoolAst.observeNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.observeGuard,NodePoolAst.observeNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem borrowSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.borrowGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.borrowNext q)) := by
 have he : project (NodePoolAst.borrowNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.borrowGuard,NodePoolAst.borrowNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem returnBorrowSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.returnBorrowGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.returnBorrowNext q)) := by
 have he : project (NodePoolAst.returnBorrowNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.returnBorrowGuard,NodePoolAst.returnBorrowNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem closeRootsSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.closeRootsGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.closeRootsNext q)) := by
 have hg : WeakAdmissionAst.closeRootsGuard (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.closeRootsGuard,WeakAdmissionAst.closeRootsGuard] <;> omega
 have he : project (NodePoolAst.closeRootsNext q)=WeakAdmissionAst.closeRootsNext (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.closeRootsGuard,NodePoolAst.closeRootsNext,WeakAdmissionAst.closeRootsNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩)))))))))))))
theorem completeSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.completeGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.completeNext q)) := by
 have hg : WeakAdmissionAst.finishWeakGuard (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.completeGuard,WeakAdmissionAst.finishWeakGuard] <;> omega
 have he : project (NodePoolAst.completeNext q)=WeakAdmissionAst.finishWeakNext (project q) := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.completeGuard,NodePoolAst.completeNext,WeakAdmissionAst.finishWeakNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨hg,he⟩))))))))))))))
theorem closeUsersSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.closeUsersGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.closeUsersNext q)) := by
 have he : project (NodePoolAst.closeUsersNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.closeUsersGuard,NodePoolAst.closeUsersNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem detachHeadSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.detachHeadGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.detachHeadNext q)) := by
 have he : project (NodePoolAst.detachHeadNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.detachHeadGuard,NodePoolAst.detachHeadNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem certifySimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.certifyGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.certifyNext q)) := by
 have he : project (NodePoolAst.certifyNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.certifyGuard,NodePoolAst.certifyNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem reclaimSimulates (q : P) (h : NodePoolAst.Safe q) (g : NodePoolAst.reclaimGuard q) : WeakAdmissionAst.Step (project q) (project (NodePoolAst.reclaimNext q)) := by
 have he : project (NodePoolAst.reclaimNext q)=project q := by
  simp only [NodePoolAst.Safe] at h
  rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26,h27⟩
  simp_all [project,NodePoolAst.reclaimGuard,NodePoolAst.reclaimNext] <;> omega
 exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem stepSimulates (q r : P) (h : NodePoolAst.Safe q) (st : NodePoolAst.Step q r) : WeakAdmissionAst.Step (project q) (project r) := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17
 · rcases a0 with ⟨g,rfl⟩; exact admitSimulates q h g
 · rcases a1 with ⟨g,rfl⟩; exact rejectSimulates q h g
 · rcases a2 with ⟨g,rfl⟩; exact reserveSimulates q h g
 · rcases a3 with ⟨g,rfl⟩; exact deriveSimulates q h g
 · rcases a4 with ⟨g,rfl⟩; exact sealSimulates q h g
 · rcases a5 with ⟨g,rfl⟩; exact publishSimulates q h g
 · rcases a6 with ⟨g,rfl⟩; exact claimSimulates q h g
 · rcases a7 with ⟨g,rfl⟩; exact finishSimulates q h g
 · rcases a8 with ⟨g,rfl⟩; exact observeSimulates q h g
 · rcases a9 with ⟨g,rfl⟩; exact borrowSimulates q h g
 · rcases a10 with ⟨g,rfl⟩; exact returnBorrowSimulates q h g
 · rcases a11 with ⟨g,rfl⟩; exact closeRootsSimulates q h g
 · rcases a12 with ⟨g,rfl⟩; exact completeSimulates q h g
 · rcases a13 with ⟨g,rfl⟩; exact closeUsersSimulates q h g
 · rcases a14 with ⟨g,rfl⟩; exact detachHeadSimulates q h g
 · rcases a15 with ⟨g,rfl⟩; exact certifySimulates q h g
 · rcases a16 with ⟨g,rfl⟩; exact reclaimSimulates q h g
 · have he : project r=project q := congrArg project a17
   exact Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (Or.inr (he))))))))))))))))
theorem commonWeakLedger (p : P) (l : DelayedLedgerAst.State)
 (hp : NodePoolAst.Safe p) (hl : DelayedLedgerAst.Safe l)
 (pp : p.phase=1) (lp : l.phase=2)
 (debt : p.debt=l.debt) (kind : p.kind=l.kind) (roots : p.rootsClosed=l.rootsClosed) :
 project p=TransportComposition.project l := by
 simp only [DelayedLedgerAst.Safe] at hl
 rcases hl with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21,h22,h23,h24,h25,h26⟩
 have hc := h16 (by omega)
 have hd := h18 (by omega)
 simp_all [project,TransportComposition.project]

def weakCut : W := WeakAdmissionAst.openWeakNext (WeakAdmissionAst.classifyBNext (WeakAdmissionAst.classifyANext (WeakAdmissionAst.freezeStrongNext (WeakAdmissionAst.drainStrongNext WeakAdmissionAst.initial))))
theorem initialProjectIsWeakCut : project NodePoolAst.initial=weakCut := by rfl
theorem weakCutReachable : WeakAdmission.Reachable weakCut := by
 let q0 := WeakAdmissionAst.initial
 let q1 := WeakAdmissionAst.drainStrongNext q0
 let q2 := WeakAdmissionAst.freezeStrongNext q1
 let q3 := WeakAdmissionAst.classifyANext q2
 let q4 := WeakAdmissionAst.classifyBNext q3
 have r0 : WeakAdmission.Reachable q0 := WeakAdmission.Reachable.start
 have r1 : WeakAdmission.Reachable q1 := WeakAdmission.Reachable.next r0 (Or.inl ⟨by simp [WeakAdmissionAst.drainStrongGuard,q0,WeakAdmissionAst.initial],rfl⟩)
 have r2 : WeakAdmission.Reachable q2 := WeakAdmission.Reachable.next r1 (Or.inr (Or.inl ⟨by simp [WeakAdmissionAst.freezeStrongGuard,q1,q0,WeakAdmissionAst.drainStrongNext,WeakAdmissionAst.initial],rfl⟩))
 have r3 : WeakAdmission.Reachable q3 := WeakAdmission.Reachable.next r2 (Or.inr (Or.inr (Or.inl ⟨by simp [WeakAdmissionAst.classifyAGuard,q2,WeakAdmissionAst.freezeStrongNext],rfl⟩)))
 have r4 : WeakAdmission.Reachable q4 := WeakAdmission.Reachable.next r3 (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [WeakAdmissionAst.classifyBGuard,q3,q2,WeakAdmissionAst.classifyANext,WeakAdmissionAst.freezeStrongNext],rfl⟩))))
 exact WeakAdmission.Reachable.next r4 (Or.inr (Or.inr (Or.inr (Or.inr (Or.inl ⟨by simp [WeakAdmissionAst.openWeakGuard,q4,q3,q2,WeakAdmissionAst.classifyBNext,WeakAdmissionAst.classifyANext,WeakAdmissionAst.freezeStrongNext],rfl⟩)))))
theorem reachableProjects (q : P) (h : NodePool.Reachable q) : WeakAdmission.Reachable (project q) := by
 induction h with
 | start => rw [initialProjectIsWeakCut]; exact weakCutReachable
 | next reach st ih => exact WeakAdmission.Reachable.next ih (stepSimulates _ _ (NodePool.reachableSafe _ reach) st)
theorem weakEntryProjectIsWeakCut (capacity budget retained receiptCount borrowerCount : Int) :
 project (NodePool.weakEntry capacity budget retained receiptCount borrowerCount)=weakCut := by rfl
end NodePoolComposition

