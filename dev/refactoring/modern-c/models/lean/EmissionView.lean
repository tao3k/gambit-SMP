import EmissionViewAst
namespace EmissionView
open EmissionViewAst
set_option maxHeartbeats 12000000
set_option maxRecDepth 14000
theorem initialSafe : Safe initial := by simp [Safe,initial]
theorem captureFrontPreserves (q : State) (h : Safe q) (g : captureFrontGuard q) : Safe (captureFrontNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,captureFrontGuard,captureFrontNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem captureLatePreserves (q : State) (h : Safe q) (g : captureLateGuard q) : Safe (captureLateNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,captureLateGuard,captureLateNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem discoverChildPreserves (q : State) (h : Safe q) (g : discoverChildGuard q) : Safe (discoverChildNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,discoverChildGuard,discoverChildNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem drainOnePreserves (q : State) (h : Safe q) (g : drainOneGuard q) : Safe (drainOneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,drainOneGuard,drainOneNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem reserveWriterPreserves (q : State) (h : Safe q) (g : reserveWriterGuard q) : Safe (reserveWriterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,reserveWriterGuard,reserveWriterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem writerPublishPreserves (q : State) (h : Safe q) (g : writerPublishGuard q) : Safe (writerPublishNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,writerPublishGuard,writerPublishNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem writerDonePreserves (q : State) (h : Safe q) (g : writerDoneGuard q) : Safe (writerDoneNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,writerDoneGuard,writerDoneNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownWriterPreserves (q : State) (h : Safe q) (g : unknownWriterGuard q) : Safe (unknownWriterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,unknownWriterGuard,unknownWriterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem escapeAliasPreserves (q : State) (h : Safe q) (g : escapeAliasGuard q) : Safe (escapeAliasNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,escapeAliasGuard,escapeAliasNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem beginClosePreserves (q : State) (h : Safe q) (g : beginCloseGuard q) : Safe (beginCloseNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,beginCloseGuard,beginCloseNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeAliasesPreserves (q : State) (h : Safe q) (g : closeAliasesGuard q) : Safe (closeAliasesNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,closeAliasesGuard,closeAliasesNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezeInputsPreserves (q : State) (h : Safe q) (g : freezeInputsGuard q) : Safe (freezeInputsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,freezeInputsGuard,freezeInputsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem declareOpaquePreserves (q : State) (h : Safe q) (g : declareOpaqueGuard q) : Safe (declareOpaqueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,declareOpaqueGuard,declareOpaqueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem copyFragmentsPreserves (q : State) (h : Safe q) (g : copyFragmentsGuard q) : Safe (copyFragmentsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,copyFragmentsGuard,copyFragmentsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem qualifyNativePreserves (q : State) (h : Safe q) (g : qualifyNativeGuard q) : Safe (qualifyNativeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,qualifyNativeGuard,qualifyNativeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem qualifyVerifierPreserves (q : State) (h : Safe q) (g : qualifyVerifierGuard q) : Safe (qualifyVerifierNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,qualifyVerifierGuard,qualifyVerifierNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem resolveLayoutPreserves (q : State) (h : Safe q) (g : resolveLayoutGuard q) : Safe (resolveLayoutNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,resolveLayoutGuard,resolveLayoutNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem lateLayoutWritePreserves (q : State) (h : Safe q) (g : lateLayoutWriteGuard q) : Safe (lateLayoutWriteNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,lateLayoutWriteGuard,lateLayoutWriteNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem freezePreserves (q : State) (h : Safe q) (g : freezeGuard q) : Safe (freezeNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,freezeGuard,freezeNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem emitCPreserves (q : State) (h : Safe q) (g : emitCGuard q) : Safe (emitCNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,emitCGuard,emitCNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem emitSpecPreserves (q : State) (h : Safe q) (g : emitSpecGuard q) : Safe (emitSpecNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,emitSpecGuard,emitSpecNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem verifyCoveragePreserves (q : State) (h : Safe q) (g : verifyCoverageGuard q) : Safe (verifyCoverageNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,verifyCoverageGuard,verifyCoverageNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem closeOutputsPreserves (q : State) (h : Safe q) (g : closeOutputsGuard q) : Safe (closeOutputsNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,closeOutputsGuard,closeOutputsNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem issuePreserves (q : State) (h : Safe q) (g : issueGuard q) : Safe (issueNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,issueGuard,issueNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem nativePermitPreserves (q : State) (h : Safe q) (g : nativePermitGuard q) : Safe (nativePermitNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,nativePermitGuard,nativePermitNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectSnapshotPreserves (q : State) (h : Safe q) (g : rejectSnapshotGuard q) : Safe (rejectSnapshotNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,rejectSnapshotGuard,rejectSnapshotNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem unknownOutputPreserves (q : State) (h : Safe q) (g : unknownOutputGuard q) : Safe (unknownOutputNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,unknownOutputGuard,unknownOutputNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem rejectLateWriterPreserves (q : State) (h : Safe q) (g : rejectLateWriterGuard q) : Safe (rejectLateWriterNext q) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases ld : q.layoutDone <;> cases rc : q.receipt <;> simp_all [Safe,rejectLateWriterGuard,rejectLateWriterNext] <;> (repeat' apply And.intro) <;> intros <;> (try simp_all) <;> omega
theorem stepPreserves (q r : State) (h : Safe q) (st : Step q r) : Safe r := by
 rcases st with a0 | a1 | a2 | a3 | a4 | a5 | a6 | a7 | a8 | a9 | a10 | a11 | a12 | a13 | a14 | a15 | a16 | a17 | a18 | a19 | a20 | a21 | a22 | a23 | a24 | a25 | a26 | a27 | a28
 · rcases a0 with ⟨g,eqn⟩; rw [eqn]; exact captureFrontPreserves q h g
 · rcases a1 with ⟨g,eqn⟩; rw [eqn]; exact captureLatePreserves q h g
 · rcases a2 with ⟨g,eqn⟩; rw [eqn]; exact discoverChildPreserves q h g
 · rcases a3 with ⟨g,eqn⟩; rw [eqn]; exact drainOnePreserves q h g
 · rcases a4 with ⟨g,eqn⟩; rw [eqn]; exact reserveWriterPreserves q h g
 · rcases a5 with ⟨g,eqn⟩; rw [eqn]; exact writerPublishPreserves q h g
 · rcases a6 with ⟨g,eqn⟩; rw [eqn]; exact writerDonePreserves q h g
 · rcases a7 with ⟨g,eqn⟩; rw [eqn]; exact unknownWriterPreserves q h g
 · rcases a8 with ⟨g,eqn⟩; rw [eqn]; exact escapeAliasPreserves q h g
 · rcases a9 with ⟨g,eqn⟩; rw [eqn]; exact beginClosePreserves q h g
 · rcases a10 with ⟨g,eqn⟩; rw [eqn]; exact closeAliasesPreserves q h g
 · rcases a11 with ⟨g,eqn⟩; rw [eqn]; exact freezeInputsPreserves q h g
 · rcases a12 with ⟨g,eqn⟩; rw [eqn]; exact declareOpaquePreserves q h g
 · rcases a13 with ⟨g,eqn⟩; rw [eqn]; exact copyFragmentsPreserves q h g
 · rcases a14 with ⟨g,eqn⟩; rw [eqn]; exact qualifyNativePreserves q h g
 · rcases a15 with ⟨g,eqn⟩; rw [eqn]; exact qualifyVerifierPreserves q h g
 · rcases a16 with ⟨g,eqn⟩; rw [eqn]; exact resolveLayoutPreserves q h g
 · rcases a17 with ⟨g,eqn⟩; rw [eqn]; exact lateLayoutWritePreserves q h g
 · rcases a18 with ⟨g,eqn⟩; rw [eqn]; exact freezePreserves q h g
 · rcases a19 with ⟨g,eqn⟩; rw [eqn]; exact emitCPreserves q h g
 · rcases a20 with ⟨g,eqn⟩; rw [eqn]; exact emitSpecPreserves q h g
 · rcases a21 with ⟨g,eqn⟩; rw [eqn]; exact verifyCoveragePreserves q h g
 · rcases a22 with ⟨g,eqn⟩; rw [eqn]; exact closeOutputsPreserves q h g
 · rcases a23 with ⟨g,eqn⟩; rw [eqn]; exact issuePreserves q h g
 · rcases a24 with ⟨g,eqn⟩; rw [eqn]; exact nativePermitPreserves q h g
 · rcases a25 with ⟨g,eqn⟩; rw [eqn]; exact rejectSnapshotPreserves q h g
 · rcases a26 with ⟨g,eqn⟩; rw [eqn]; exact unknownOutputPreserves q h g
 · rcases a27 with ⟨g,eqn⟩; rw [eqn]; exact rejectLateWriterPreserves q h g
 · rw [a28]; exact h
inductive Reachable : State → Prop where
 | start : Reachable initial
 | next {q r} : Reachable q → Step q r → Reachable r
theorem reachableSafe (q : State) (h : Reachable q) : Safe q := by
 induction h with
 | start => exact initialSafe
 | next _ st ih => exact stepPreserves _ _ ih st
theorem receiptSameView (q : State) (h : Safe q) (p : q.receipt=true) : q.snapshot=q.generation ∧ q.cGen=q.generation ∧ q.mGen=q.generation ∧ q.lateCaptured=true ∧ q.pending=0 ∧ q.writers=0 := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases op : q.opaqueSeen <;> simp_all <;> omega
theorem receiptCoverageAndClose (q : State) (h : Safe q) (p : q.receipt=true) : q.coverage=true ∧ q.ioComplete=true ∧ q.verifierQualified=true := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases op : q.opaqueSeen <;> simp_all <;> omega
theorem nativeNeedsQualification (q : State) (h : Safe q) (p : q.nativeReady=true) : q.receipt=true ∧ (q.opaqueSeen=true → q.nativeQualified=true) := by
 simp only [Safe] at h
 rcases h with ⟨h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13,h14,h15,h16,h17,h18,h19,h20,h21⟩
 cases op : q.opaqueSeen <;> simp_all <;> omega
theorem unknownWriterKeepsCustody (q : State) : (unknownWriterNext q).writers=q.writers := by simp [unknownWriterNext]
end EmissionView
