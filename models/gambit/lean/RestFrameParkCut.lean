/- Conditional construction ledger and exclusive park/resume/exit authority; not C simulation. -/
namespace GambitSMP.RestFrameParkCut
structure Progress where
  required : Nat
  remaining : Nat
  built : Nat
  actual : Nat
  pairs : Nat
  deriving DecidableEq
def Conserved (p : Progress) := p.required+p.remaining+p.built=p.actual ∧ p.pairs=p.built
def consOne (p : Progress) := {p with remaining:=p.remaining-1,built:=p.built+1,pairs:=p.pairs+1}
theorem consPreserves (p : Progress) (h : Conserved p) (r : p.remaining>0) : Conserved (consOne p) := by
  simp_all [Conserved,consOne]; omega
theorem completionHasExactRest (p : Progress) (h : Conserved p) (r : p.remaining=0) : p.required+p.built=p.actual := by simp_all [Conserved]
theorem completedPairCount (p : Progress) (h : Conserved p) (r : p.remaining=0) : p.pairs=p.actual-p.required := by
  simp_all [Conserved]; omega
theorem popAndPrependPreservesOrder (input pending pending' rest : List Nat) (a : Nat)
    (h : pending=pending'++[a]) (o : input=pending++rest) : input=pending'++(a::rest) := by
  rw [o,h]; simp [List.append_assoc]
theorem concreteRestOrder : ([0,1,2]++[3] : List Nat)=[0,1,2,3] := by decide
def RepairWords (remaining np pairWords vectorBody : Nat) := remaining*pairWords+np+vectorBody
theorem repairWordsExact (r n p v : Nat) : RepairWords r n p v=r*p+n+v := rfl
theorem actualRestFourNoHandles : RepairWords 3 1 3 1=11 := by decide
theorem actualRestFixedNoHandles : RepairWords 2 2 3 1=9 := by decide
structure Cut where
  remaining : Nat
  vectorComplete : Bool
  fullFrame : Bool
  mapped : Bool
  localLease : Bool
  entryClosed : Bool
  nativeBorrows : Nat
  writers : Nat
  unknown : Bool
  generation : Nat
  spillGeneration : Nat
  nativeLive : Bool
  capacityGranted : Bool
def Eligible (c : Cut) := c.remaining=0 ∧ c.vectorComplete=true ∧ c.fullFrame=true ∧ c.mapped=true ∧
  c.localLease=true ∧ c.entryClosed=true ∧ c.nativeBorrows=0 ∧ c.writers=0 ∧ c.unknown=false ∧
  c.generation=c.spillGeneration ∧ c.nativeLive=true ∧ c.capacityGranted=true
theorem partialRestRejects (c : Cut) (h : c.remaining>0) : ¬ Eligible c := by simp [Eligible]; omega
theorem partialVectorRejects (c : Cut) (h : c.vectorComplete=false) : ¬ Eligible c := by simp [Eligible,h]
theorem missingMapRejects (c : Cut) (h : c.mapped=false) : ¬ Eligible c := by simp [Eligible,h]
theorem rawBorrowRejects (c : Cut) (h : c.nativeBorrows>0) : ¬ Eligible c := by simp [Eligible]; omega
theorem lateWriterRejects (c : Cut) (h : c.writers>0) : ¬ Eligible c := by simp [Eligible]; omega
theorem unknownWriteRejects (c : Cut) (h : c.unknown=true) : ¬ Eligible c := by simp [Eligible,h]
theorem staleSpillRejects (c : Cut) (h : c.generation≠c.spillGeneration) : ¬ Eligible c := by simp [Eligible,h]
theorem deadNativeFrameRejects (c : Cut) (h : c.nativeLive=false) : ¬ Eligible c := by simp [Eligible,h]
theorem missingCapacityRejects (c : Cut) (h : c.capacityGranted=false) : ¬ Eligible c := by simp [Eligible,h]
structure Authority where
  offered : Bool
  accepted : Bool
  ack : Bool
  scanning : Bool
  permit : Bool
  roots : Bool
  nativeLive : Bool
  version : Nat
  reload : Nat
  starts : Nat
  pairs : Nat
  normal : Nat
  exits : Nat
  pendingExit : Bool
  deriving DecidableEq
def Safe (s : Authority) := s.starts=1 ∧ s.normal+s.exits≤1 ∧ s.roots=true ∧ s.nativeLive=true ∧
  (s.accepted=true → s.offered=true ∧ s.permit=false) ∧
  (s.scanning=true → s.accepted=true ∧ s.permit=false ∧ s.normal=0 ∧ s.exits=0) ∧
  (s.permit=true → s.reload=s.version ∧ s.scanning=false) ∧
  (s.normal>0 → s.pendingExit=false) ∧ (s.exits>0 → s.pendingExit=true)
def accept (s : Authority) := {s with accepted:=true,offered:=true,permit:=false}
def loseResponse (s : Authority) := {s with ack:=false}
def claimScan (s : Authority) := {s with scanning:=true}
def moveRoots (s : Authority) := {s with version:=s.version+1}
def finishScan (s : Authority) := {s with scanning:=false}
def reloadRoots (s : Authority) := {s with reload:=s.version}
def normalClaim (s : Authority) := {s with accepted:=false,offered:=false,permit:=true,normal:=s.normal+1}
def exitClaim (s : Authority) := {s with accepted:=false,offered:=false,permit:=true,exits:=s.exits+1}
def requestExit (s : Authority) := {s with pendingExit:=true}
theorem acceptPreserves (s : Authority) (h : Safe s) : Safe (accept s) := by simp_all [Safe,accept]
theorem loseResponsePreserves (s : Authority) (h : Safe s) : Safe (loseResponse s) := by simp_all [Safe,loseResponse]
theorem lostResponseKeepsAcceptance (s : Authority) : (loseResponse s).accepted=s.accepted := rfl
theorem scanPreserves (s : Authority) (h : Safe s) (a : s.accepted=true) (n : s.normal=0) (e : s.exits=0) : Safe (claimScan s) := by simp_all [Safe,claimScan]
theorem movePreserves (s : Authority) (h : Safe s) (a : s.scanning=true) : Safe (moveRoots s) := by simp_all [Safe,moveRoots]
theorem finishScanPreserves (s : Authority) (h : Safe s) : Safe (finishScan s) := by simp_all [Safe,finishScan]
theorem reloadPreserves (s : Authority) (h : Safe s) : Safe (reloadRoots s) := by simp_all [Safe,reloadRoots]
theorem normalPreserves (s : Authority) (h : Safe s) (n : s.normal=0) (e : s.exits=0)
    (scan : s.scanning=false) (r : s.reload=s.version) (p : s.pendingExit=false) : Safe (normalClaim s) := by simp_all [Safe,normalClaim]
theorem exitPreserves (s : Authority) (h : Safe s) (n : s.normal=0) (e : s.exits=0)
    (scan : s.scanning=false) (r : s.reload=s.version) (p : s.pendingExit=true) : Safe (exitClaim s) := by simp_all [Safe,exitClaim]
theorem requestPreserves (s : Authority) (h : Safe s) (n : s.normal=0) (e : s.exits=0) : Safe (requestExit s) := by simp_all [Safe,requestExit]
theorem pendingExitBlocksNormal (s : Authority) (h : Safe s) (p : s.pendingExit=true) : s.normal=0 := by simp_all [Safe]
theorem unrequestedExitRejected (s : Authority) (h : Safe s) (p : s.pendingExit=false) : s.exits=0 := by simp_all [Safe]
theorem resumeDoesNotReinvoke (s : Authority) : (normalClaim s).starts=s.starts := rfl
theorem resumeDoesNotRecons (s : Authority) : (normalClaim s).pairs=s.pairs := rfl
theorem normalExcludesExit (s : Authority) (h : Safe s) (n : s.normal=1) : s.exits=0 := by simp_all [Safe]; omega
theorem scanBlocksTerminalClaim (s : Authority) (h : Safe s) (a : s.scanning=true) : s.normal=0 ∧ s.exits=0 := by simp_all [Safe]
structure Ready where
  wholeRound : Bool
  context : Bool
  boundSameOwner : Bool
  epoch : Nat
  expected : Nat
def Authorized (r : Ready) := r.wholeRound=true ∧ r.context=true ∧ r.boundSameOwner=true ∧ r.epoch=r.expected
theorem missingWholeRoundRejects (r : Ready) (h : r.wholeRound=false) : ¬ Authorized r := by simp [Authorized,h]
inductive Step : Authority → Authority → Prop
  | accept (s : Authority) (c : Cut) (h : Eligible c) : Step s (RestFrameParkCut.accept s)
  | loseResponse (s : Authority) : Step s (RestFrameParkCut.loseResponse s)
  | claimScan (s : Authority) (a : s.accepted=true) (n : s.normal=0) (e : s.exits=0) : Step s (RestFrameParkCut.claimScan s)
  | move (s : Authority) (a : s.scanning=true) : Step s (RestFrameParkCut.moveRoots s)
  | finishScan (s : Authority) : Step s (RestFrameParkCut.finishScan s)
  | reload (s : Authority) : Step s (RestFrameParkCut.reloadRoots s)
  | normal (s : Authority) (r : Ready) (h : Authorized r) (n : s.normal=0) (e : s.exits=0) (scan : s.scanning=false) (v : s.reload=s.version) (p : s.pendingExit=false) : Step s (RestFrameParkCut.normalClaim s)
  | exit (s : Authority) (r : Ready) (h : Authorized r) (n : s.normal=0) (e : s.exits=0) (scan : s.scanning=false) (v : s.reload=s.version) (p : s.pendingExit=true) : Step s (RestFrameParkCut.exitClaim s)
  | request (s : Authority) (n : s.normal=0) (e : s.exits=0) : Step s (RestFrameParkCut.requestExit s)
  | query (s : Authority) : Step s s
theorem stepPreserves {a b : Authority} (h : Step a b) (s : Safe a) : Safe b := by
  cases h with
  | accept => exact acceptPreserves _ s
  | loseResponse => exact loseResponsePreserves _ s
  | claimScan a n e => exact scanPreserves _ s a n e
  | move a => exact movePreserves _ s a
  | finishScan => exact finishScanPreserves _ s
  | reload => exact reloadPreserves _ s
  | normal _ _ n e scan v p => exact normalPreserves _ s n e scan v p
  | exit _ _ n e scan v p => exact exitPreserves _ s n e scan v p
  | request n e => exact requestPreserves _ s n e
  | query => exact s
inductive Trace : Authority → Authority → Prop
  | nil (s : Authority) : Trace s s
  | cons {a b c : Authority} : Step a b → Trace b c → Trace a c
theorem tracePreserves {a b : Authority} (h : Trace a b) (s : Safe a) : Safe b := by
  induction h with
  | nil => exact s
  | cons h _ ih => exact ih (stepPreserves h s)
end GambitSMP.RestFrameParkCut
