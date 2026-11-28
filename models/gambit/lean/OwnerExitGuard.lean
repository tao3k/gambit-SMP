namespace GambitSMP.OwnerExitGuard
-- markerLive is logical activation validity; physical heap clearing is not modeled.
structure Frame where
  ownerRoots : Nat
  serviceRoots : Nat
  ownerInit : Nat
  serviceInit : Nat
  committed : Bool
  resultRoot : Bool
  markerLive : Bool
  settled : Bool
def rootTotal (f : Frame) := f.ownerRoots+f.serviceRoots
def initTotal (f : Frame) := f.ownerInit+f.serviceInit
def WellFormed (f : Frame) := (f.committed=true → f.resultRoot=true) ∧
  (f.settled=true → f.ownerInit=0 ∧ f.markerLive=false)
-- Supported callers additionally establish stopped writers and durable cell locations.
def settle (f : Frame) := { f with
  ownerRoots := 0
  serviceRoots := f.ownerRoots + f.serviceRoots
  ownerInit := 0
  serviceInit := f.ownerInit + f.serviceInit
  markerLive := false
  settled := true }
theorem settlePreservesRootTotal (f : Frame) : rootTotal (settle f)=rootTotal f := by simp [rootTotal,settle]
theorem settlePreservesInitTotal (f : Frame) : initTotal (settle f)=initTotal f := by simp [initTotal,settle]
theorem settlePreservesCommit (f : Frame) : (settle f).committed=f.committed := rfl
theorem settlePreservesResultRoot (f : Frame) : (settle f).resultRoot=f.resultRoot := rfl
theorem settleRetainsInitDuty (f : Frame) : (settle f).serviceInit=initTotal f := rfl
theorem settledMarkerDead (f : Frame) : (settle f).markerLive=false := rfl
theorem settlePreservesWellFormed (f : Frame) (h : WellFormed f) : WellFormed (settle f) := by
  simpa [WellFormed,settle] using h.1
structure Chain where
  frames : Nat→Frame
  target : Nat
  fp : Nat
  transportFp : Nat
def settleAt (s : Chain) (i : Nat) := {s with frames:=fun k => if k=i then settle (s.frames k) else s.frames k}
theorem otherFrameUnchanged (s : Chain) (i k : Nat) (h : k≠i) : (settleAt s i).frames k=s.frames k := by simp [settleAt,h]
theorem liveTargetPreserved (s : Chain) (i : Nat) (h : s.target<i) : (settleAt s i).frames s.target=s.frames s.target := by
  apply otherFrameUnchanged; omega
theorem transportFpPreserved (s : Chain) (i : Nat) : (settleAt s i).fp=s.fp := rfl
theorem destinationPreserved (s : Chain) (i : Nat) : (settleAt s i).target=s.target := rfl
inductive Step : Chain → Chain → Prop
  | settle (s : Chain) (i : Nat) (h : s.target<i) : Step s (settleAt s i)
  | query (s : Chain) : Step s s
theorem stepPreservesDestination {a b : Chain} (h : Step a b) : b.target=a.target := by cases h <;> rfl
theorem stepPreservesFp {a b : Chain} (h : Step a b) : b.fp=a.fp := by cases h <;> rfl
theorem stepPreservesTargetFrame {a b : Chain} (h : Step a b) : b.frames b.target=a.frames a.target := by
  cases h with
  | settle i h => exact liveTargetPreserved _ i h
  | query => rfl
inductive Trace : Chain → Chain → Prop
  | nil (s : Chain) : Trace s s
  | cons {a b c : Chain} : Step a b → Trace b c → Trace a c
theorem tracePreservesTargetFrame {a b : Chain} (h : Trace a b) : b.frames b.target=a.frames a.target := by
  induction h with
  | nil => rfl
  | cons h _ ih => exact ih.trans (stepPreservesTargetFrame h)
theorem tracePreservesFp {a b : Chain} (h : Trace a b) : b.fp=a.fp := by
  induction h with
  | nil => rfl
  | cons h _ ih => exact ih.trans (stepPreservesFp h)
structure PopGate where
  durableRoots : Bool
  stoppedWriters : Bool
  markerDead : Bool
  catcherRestored : Bool
  originalOwner : Bool
  pendingBridges : Nat
def CanPop (g : PopGate) := g.durableRoots=true ∧ g.stoppedWriters=true ∧ g.markerDead=true ∧
  g.catcherRestored=true ∧ g.originalOwner=true ∧ g.pendingBridges=0
theorem missingCatcherRejects (g : PopGate) (h : g.catcherRestored=false) : ¬ CanPop g := by simp [CanPop,h]
theorem stackOnlyRootsReject (g : PopGate) (h : g.durableRoots=false) : ¬ CanPop g := by simp [CanPop,h]
theorem unknownStopRejects (g : PopGate) (h : g.stoppedWriters=false) : ¬ CanPop g := by simp [CanPop,h]
theorem wrongOwnerRejects (g : PopGate) (h : g.originalOwner=false) : ¬ CanPop g := by simp [CanPop,h]
theorem bridgeDebtRejects (g : PopGate) (h : 0<g.pendingBridges) : ¬ CanPop g := by simp [CanPop]; omega
end GambitSMP.OwnerExitGuard
