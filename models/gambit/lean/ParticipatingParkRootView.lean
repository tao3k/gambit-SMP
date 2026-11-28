/- Conditional laws for one live native invocation; no source/ABI or full QNT simulation. -/
namespace GambitSMP.ParticipatingParkRootView
structure Boundary where
  atSafePoint : Bool
  initSafe : Bool
  materialized : Bool
  entryClosed : Bool
  effects : Nat
  writers : Nat
  borrows : Nat
  nested : Nat
  unknown : Bool
  nativeFrame : Bool
  rootBacking : Bool
  resources : Bool
def Eligible (b : Boundary) := b.atSafePoint=true ∧ b.initSafe=true ∧ b.materialized=true ∧
  b.entryClosed=true ∧ b.effects=0 ∧ b.writers=0 ∧ b.borrows=0 ∧ b.nested=0 ∧ b.unknown=false ∧
  b.nativeFrame=true ∧ b.rootBacking=true ∧ b.resources=true
theorem safePointRequired (b : Boundary) (h : Eligible b) : b.atSafePoint=true := h.1
theorem constructionRequired (b : Boundary) (h : Eligible b) : b.initSafe=true := h.2.1
theorem materializationRequired (b : Boundary) (h : Eligible b) : b.materialized=true := h.2.2.1
theorem inFlightRejects (b : Boundary) (h : b.effects>0) : ¬ Eligible b := by simp [Eligible]; omega
theorem writerRejects (b : Boundary) (h : b.writers>0) : ¬ Eligible b := by simp [Eligible]; omega
theorem borrowRejects (b : Boundary) (h : b.borrows>0) : ¬ Eligible b := by simp [Eligible]; omega
theorem nestedRejects (b : Boundary) (h : b.nested>0) : ¬ Eligible b := by simp [Eligible]; omega
theorem unknownRejects (b : Boundary) (h : b.unknown=true) : ¬ Eligible b := by simp [Eligible,h]
theorem deadFrameRejects (b : Boundary) (h : b.nativeFrame=false) : ¬ Eligible b := by simp [Eligible,h]
structure View where
  accepted : Bool
  response : Bool
  mutator : Bool
  scanner : Bool
  roots : Bool
  backing : Bool
  frame : Bool
  version : Nat
  cache : Nat
  starts : Nat
  resumes : Nat
  epoch : Nat
  deriving DecidableEq
def Safe (s : View) := s.starts=1 ∧ s.resumes≤1 ∧ s.roots=true ∧ s.backing=true ∧ s.frame=true ∧
  (s.accepted=true → s.mutator=false) ∧ (s.scanner=true → s.accepted=true ∧ s.mutator=false) ∧
  (s.mutator=true → s.cache=s.version ∧ s.scanner=false)
def loseResponse (s : View) := {s with response:=false}
def offer (s : View) := {s with mutator:=false}
def accept (s : View) := {s with accepted:=true,mutator:=false}
def claim (s : View) := {s with scanner:=true}
def move (s : View) := {s with version:=s.version+1}
def release (s : View) := {s with scanner:=false}
def reload (s : View) := {s with cache:=s.version}
def resume (s : View) := {s with accepted:=false,mutator:=true,epoch:=s.epoch+1,resumes:=s.resumes+1}
theorem offerPreserves (s : View) (h : Safe s) : Safe (offer s) := by simp_all [Safe,offer]
theorem acceptPreserves (s : View) (h : Safe s) : Safe (accept s) := by simp_all [Safe,accept]
theorem claimPreserves (s : View) (h : Safe s) (a : s.accepted=true) : Safe (claim s) := by simp_all [Safe,claim]
theorem movePreserves (s : View) (h : Safe s) (a : s.scanner=true) : Safe (move s) := by simp_all [Safe,move]
theorem releasePreserves (s : View) (h : Safe s) : Safe (release s) := by simp_all [Safe,release]
theorem reloadPreserves (s : View) (h : Safe s) : Safe (reload s) := by simp_all [Safe,reload]
theorem resumePreserves (s : View) (h : Safe s) (a : s.accepted=true) (n : s.scanner=false)
    (r : s.cache=s.version) (z : s.resumes=0) : Safe (resume s) := by simp_all [Safe,resume]
theorem resumeDoesNotReinvoke (s : View) : (resume s).starts=s.starts := rfl
theorem freezePermitsCollectorMutation (s : View) : (move s).mutator=s.mutator := rfl
theorem relocatedCacheNeedsReload (s : View) (h : s.cache=s.version) : (move s).cache≠(move s).version := by simp [move]; omega
theorem lostResponseKeepsAcceptance (s : View) : (loseResponse s).accepted=s.accepted := rfl
theorem lostResponseKeepsBacking (s : View) : (loseResponse s).roots=s.roots ∧ (loseResponse s).frame=s.frame := by constructor <;> rfl
theorem lostResponsePreserves (s : View) (h : Safe s) : Safe (loseResponse s) := by simp_all [Safe,loseResponse]
structure Ready where
  roundComplete : Bool
  contextPrepared : Bool
  ownerBound : Bool
  scanners : Nat
  epoch : Nat
  expected : Nat
def Authorized (r : Ready) := r.roundComplete=true ∧ r.contextPrepared=true ∧ r.ownerBound=true ∧ r.scanners=0 ∧ r.epoch=r.expected
theorem roundRequired (r : Ready) (h : Authorized r) : r.roundComplete=true := h.1
theorem scannerBlocksResume (r : Ready) (h : r.scanners>0) : ¬ Authorized r := by simp [Authorized]; omega
theorem staleEpochRejects (r : Ready) (h : r.epoch≠r.expected) : ¬ Authorized r := by simp [Authorized,h]
inductive Step : View → View → Prop
  | offer (s : View) : Step s (ParticipatingParkRootView.offer s)
  | accept (s : View) (b : Boundary) (h : Eligible b) : Step s (ParticipatingParkRootView.accept s)
  | claim (s : View) (h : s.accepted=true) : Step s (ParticipatingParkRootView.claim s)
  | move (s : View) (h : s.scanner=true) : Step s (ParticipatingParkRootView.move s)
  | release (s : View) : Step s (ParticipatingParkRootView.release s)
  | reload (s : View) : Step s (ParticipatingParkRootView.reload s)
  | resume (s : View) (r : Ready) (h : Authorized r) (a : s.accepted=true) (n : s.scanner=false)
      (v : s.cache=s.version) (z : s.resumes=0) : Step s (ParticipatingParkRootView.resume s)
  | loseResponse (s : View) : Step s (ParticipatingParkRootView.loseResponse s)
  | query (s : View) : Step s s
theorem stepPreserves {a b : View} (h : Step a b) (s : Safe a) : Safe b := by
  cases h with
  | offer => exact offerPreserves _ s
  | accept => exact acceptPreserves _ s
  | claim a => exact claimPreserves _ s a
  | move a => exact movePreserves _ s a
  | release => exact releasePreserves _ s
  | reload => exact reloadPreserves _ s
  | resume _ _ a n v z => exact resumePreserves _ s a n v z
  | loseResponse => exact lostResponsePreserves _ s
  | query => exact s
inductive Trace : View → View → Prop
  | nil (s : View) : Trace s s
  | cons {a b c : View} : Step a b → Trace b c → Trace a c
theorem tracePreserves {a b : View} (h : Trace a b) (s : Safe a) : Safe b := by
  induction h with
  | nil => exact s
  | cons h _ ih => exact ih (stepPreserves h s)
end GambitSMP.ParticipatingParkRootView
