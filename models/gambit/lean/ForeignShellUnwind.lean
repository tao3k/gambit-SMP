namespace GambitSMP.ForeignShellUnwind
structure Shell where
  privateBacking : Bool
  metadataValid : Bool
  defaultsValid : Bool
  initRegistered : Bool
  finalizerGuard : Bool
def CanPublish (s : Shell) := s.privateBacking=true ∧ s.metadataValid=true ∧
  s.defaultsValid=true ∧ s.initRegistered=true ∧ s.finalizerGuard=true
theorem missingDefaultsReject (s : Shell) (h : s.defaultsValid=false) : ¬ CanPublish s := by simp [CanPublish,h]
theorem unknownLayoutReject (s : Shell) (h : s.metadataValid=false) : ¬ CanPublish s := by simp [CanPublish,h]
theorem rawFinalizerReject (s : Shell) (h : s.finalizerGuard=false) : ¬ CanPublish s := by simp [CanPublish,h]
structure Record where
  phase : Nat
  root : Bool
  body : Bool
  generation : Nat
  duty : Nat
def CanCommit (s : Record) (g : Nat) := s.phase=0 ∧ s.root=true ∧ s.body=true ∧ s.generation=g ∧ s.duty=1
def commit (s : Record) := {s with phase:=1,duty:=0}
def Canonical (s : Record) := s.phase≠1 ∨ (s.root=true ∧ s.body=true)
theorem commitPreservesCanonical (s : Record) (g : Nat) (h : CanCommit s g) : Canonical (commit s) := by simp_all [CanCommit,Canonical,commit]
theorem secondCommitRejected (s : Record) (g : Nat) : ¬ CanCommit (commit s) g := by simp [CanCommit,commit]
theorem rootBeforeCommit (s : Record) (g : Nat) (h : CanCommit s g) : s.root=true := h.2.1
theorem bodyBeforeCommit (s : Record) (g : Nat) (h : CanCommit s g) : s.body=true := h.2.2.1
theorem wrongGenerationRejected (s : Record) (g : Nat) (h : s.generation≠g) : ¬ CanCommit s g := by simp [CanCommit,h]
def query (s : Record) := s
def escape (s : Record) := {s with duty:=if s.duty=1 then 2 else s.duty}
theorem queryPreservesCustody (s : Record) : (query s).phase=s.phase := rfl
theorem escapePreservesCustody (s : Record) : (escape s).phase=s.phase := rfl
theorem escapePreservesRoot (s : Record) : (escape s).root=s.root := rfl
theorem escapeTransfersDuty (s : Record) (h : s.duty=1) : (escape s).duty=2 := by simp [escape,h]
inductive Step : Record → Record → Prop
  | commit (s : Record) (g : Nat) (h : CanCommit s g) : Step s (ForeignShellUnwind.commit s)
  | query (s : Record) : Step s s
  | escape (s : Record) : Step s (ForeignShellUnwind.escape s)
theorem stepPreservesCanonical {a b : Record} (h : Step a b) (ha : Canonical a) : Canonical b := by
  cases h with
  | commit g h => exact commitPreservesCanonical _ g h
  | query => exact ha
  | escape => exact ha
inductive Trace : Record → Record → Prop
  | nil (s : Record) : Trace s s
  | cons {a b c : Record} : Step a b → Trace b c → Trace a c
theorem tracePreservesCanonical {a b : Record} (h : Trace a b) (ha : Canonical a) : Canonical b := by
  induction h with
  | nil => exact ha
  | cons h _ ih => exact ih (stepPreservesCanonical h ha)
structure ExitGate where
  writerStopped : Bool
  dutyTransferred : Bool
  markerInvalidated : Bool
  sameActivation : Bool
  children : Nat
def CanExit (s : ExitGate) := s.writerStopped=true ∧ s.dutyTransferred=true ∧
  s.markerInvalidated=true ∧ s.sameActivation=true ∧ s.children=0
theorem unknownStopRejects (s : ExitGate) (h : s.writerStopped=false) : ¬ CanExit s := by simp [CanExit,h]
theorem activeChildRejects (s : ExitGate) (h : 0<s.children) : ¬ CanExit s := by simp [CanExit]; omega
theorem wrongActivationRejects (s : ExitGate) (h : s.sameActivation=false) : ¬ CanExit s := by simp [CanExit,h]
def setSlot (slots : Nat→Record) (id : Nat) (r : Record) := fun k => if k=id then r else slots k
theorem childDoesNotOverwriteParent (slots : Nat→Record) (parent child : Nat) (r : Record) (h : parent≠child) : setSlot slots child r parent=slots parent := by simp [setSlot,h]
theorem knownResultDoesNotAuthorizeDelivery (s : Record) (_h : s.phase=1) (marker : Bool) (dead : marker=false) : ¬ marker=true := by simp [dead]
end GambitSMP.ForeignShellUnwind
