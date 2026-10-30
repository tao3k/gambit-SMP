/- Conditional contracts; no C/Tcl source simulation. -/
namespace GambitSMP.NativeEntryCloseCleanup
structure Entry where
  token : Bool
  payload : Bool
  pins : Nat
  closed : Bool
  queued : Nat
  drained : Bool
  deriving DecidableEq
def EntrySafe (s : Entry) := (0<s.pins → s.token=true ∧ s.payload=true) ∧
 (s.token=false → s.closed=true ∧ s.payload=false ∧ s.pins=0 ∧ s.queued=0 ∧ s.drained=true)
def closeEntry (s : Entry) := {s with closed:=true}
theorem closePreservesPin (s : Entry) (h : EntrySafe s) : EntrySafe (closeEntry s) := by simp_all [EntrySafe,closeEntry]
theorem pinnedPayloadRetained (s : Entry) (h : EntrySafe s) (p : 0<s.pins) : s.payload=true := (h.1 p).2
theorem zeroPinsNotDrain : ∃ s : Entry, EntrySafe s ∧ s.pins=0 ∧ s.drained=false := by
 exact ⟨⟨true,false,0,true,1,false⟩, by simp [EntrySafe]⟩
structure Park where
  raw : Bool
  borrow : Bool
  mapped : Bool
  frozen : Bool
  epoch : Nat
  loaded : Nat
  contextReady : Bool
  deriving DecidableEq
def ParkSafe (s : Park) := (s.raw=true → s.loaded=s.epoch ∧ s.frozen=false) ∧
 (s.frozen=true → s.raw=false ∧ s.borrow=false ∧ s.mapped=true)
def park (s : Park) := {s with raw:=false,borrow:=false,frozen:=true}
def collect (s : Park) := {s with epoch:=s.epoch+1,contextReady:=false}
theorem parkPreserves (s : Park) (h : ParkSafe s) (m : s.mapped=true) : ParkSafe (park s) := by simp_all [ParkSafe,park]
theorem parkedCollectionPreserves (s : Park) (h : ParkSafe s) (f : s.frozen=true) : ParkSafe (collect s) := by simp_all [ParkSafe,collect]
theorem rawOldEpochRejected (s : Park) (h : ParkSafe s) (r : s.raw=true) : ¬ ParkSafe (collect s) := by simp_all [ParkSafe,collect]
structure Run where
  root : Bool
  marker : Nat
  claimed : Bool
  unknown : Bool
  clearCount : Nat
  dropCount : Nat
  rootDrops : Nat
  catcherRestored : Bool
  returned : Bool
  deriving DecidableEq
def RunSafe (s : Run) := s.clearCount≤1 ∧ s.dropCount≤s.clearCount ∧ s.rootDrops≤1 ∧
 (s.unknown=true → s.root=true) ∧
 (s.returned=true → s.root=false ∧ s.rootDrops=1 ∧ s.claimed=true ∧ s.unknown=false ∧ s.catcherRestored=true ∧ (s.marker=0 ∨ s.marker=3))
def claim (s : Run) := {s with claimed:=true}
theorem claimPreserves (s : Run) (h : RunSafe s) : RunSafe (claim s) := by simp_all [RunSafe,claim]
theorem returnedMarkerSettled (s : Run) (h : RunSafe s) (r : s.returned=true) : s.marker=0 ∨ s.marker=3 := (h.2.2.2.2 r).2.2.2.2.2
theorem unknownRetainsRunRoot (s : Run) (h : RunSafe s) (u : s.unknown=true) : s.root=true := h.2.2.2.1 u
theorem markerDropAtMostOnce (s : Run) (h : RunSafe s) : s.dropCount≤1 := by have a:=h.1;have b:=h.2.1;omega
theorem errorReturnRestoresCatcher (s : Run) (h : RunSafe s) (r : s.returned=true) : s.catcherRestored=true := (h.2.2.2.2 r).2.2.2.2.1
theorem positiveDropRequiresClear (s : Run) (h : RunSafe s) (d : 0<s.dropCount) : s.clearCount=1 := by have a:=h.1;have b:=h.2.1;omega
def SlotBytes (slots depth word : Nat) := slots*depth*word
theorem runTwoSlots64 : SlotBytes 2 1 8=16 := by decide
theorem twoActivations64 : SlotBytes 2 2 8=32 := by decide
end GambitSMP.NativeEntryCloseCleanup
