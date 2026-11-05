/- Conditional interval and ticket lifecycle laws. No C allocator, caller FrameSpec or ABI simulation. -/
namespace GambitSMP.RestCapacityPreflight
structure Interval where
  lo : Nat
  hi : Nat
def Fits (r : Interval) (need limit : Nat) := r.lo≤r.hi ∧ need≤r.hi-r.lo ∧ r.hi≤limit
def DisjointOrdered (heap stack : Interval) := heap.hi≤stack.lo
def Physical (h s : Interval) (heapNeed stackNeed limit : Nat) := Fits h heapNeed limit ∧ Fits s stackNeed limit ∧ DisjointOrdered h s
theorem heapEnough (h s : Interval) (hn sn l : Nat) (p : Physical h s hn sn l) : hn≤h.hi-h.lo := p.1.2.1
theorem stackEnough (h s : Interval) (hn sn l : Nat) (p : Physical h s hn sn l) : sn≤s.hi-s.lo := p.2.1.2.1
theorem overlapRejected (h s : Interval) (hn sn l : Nat) (p : s.lo<h.hi) : ¬ Physical h s hn sn l := by simp [Physical,DisjointOrdered]; omega
theorem shortHeapRejected (h s : Interval) (hn sn l : Nat) (p : h.hi-h.lo<hn) : ¬ Physical h s hn sn l := by simp [Physical,Fits]; omega
def CallerWords (na np body : Nat) := (na-np+1)*(2+body)+np+body
theorem fourRestNoHandles : CallerWords 4 1 1=14 := by decide
theorem oneRequiredNoHandles : CallerWords 4 2 1=12 := by decide
theorem fourRestHandles : CallerWords 4 1 2=19 := by decide
theorem oneRequiredHandles : CallerWords 4 2 2=16 := by decide
structure Stamp where
  epoch : Nat
  arena : Nat
  ticket : Nat
  input : Nat
  deriving DecidableEq
def Matches (a b : Stamp) := a=b
theorem staleEpochRejected (a b : Stamp) (h : a.epoch≠b.epoch) : ¬ Matches a b := by intro p; exact h (congrArg Stamp.epoch p)
theorem staleArenaRejected (a b : Stamp) (h : a.arena≠b.arena) : ¬ Matches a b := by intro p; exact h (congrArg Stamp.arena p)
theorem staleSerialRejected (a b : Stamp) (h : a.ticket≠b.ticket) : ¬ Matches a b := by intro p; exact h (congrArg Stamp.ticket p)
theorem changedInputRejected (a b : Stamp) (h : a.input≠b.input) : ¬ Matches a b := by intro p; exact h (congrArg Stamp.input p)
structure S where
  epoch : Nat
  arena : Nat
  te : Nat
  ta : Nat
  serial : Nat
  clientSerial : Nat
  live : Bool
  active : Bool
  full : Bool
  roots : Bool
  metadataPinned : Bool
  hp : Nat
  base : Nat
  used : Nat
  initialized : Nat
  budget : Nat
  evals : Nat
  deriving DecidableEq
def Safe (s : S) := s.roots=true ∧ s.metadataPinned=true ∧ s.evals=1 ∧ s.used≤s.budget ∧ s.initialized=s.used ∧
  (s.live=true → s.te=s.epoch ∧ s.ta=s.arena ∧ s.hp=s.base+s.used) ∧
  (s.active=true → s.live=true ∧ s.clientSerial=s.serial) ∧ (s.full=false → s.active=true)
def grant (s : S) := {s with live:=true,te:=s.epoch,ta:=s.arena,serial:=s.serial+1,base:=s.hp,used:=0,initialized:=0}
def observe (s : S) := {s with clientSerial:=s.serial}
def begin (s : S) := {s with active:=true,full:=false}
def write (s : S) (n : Nat) := {s with used:=s.used+n,initialized:=s.initialized+n,hp:=s.hp+n}
def finish (s : S) := {s with active:=false,live:=false,full:=true}
def cancel (s : S) := {s with live:=false}
def collect (s : S) := {s with epoch:=s.epoch+1,arena:=s.arena+1,hp:=8,base:=8,used:=0,initialized:=0}
theorem grantPreserves (s : S) (h : Safe s) (f : s.full=true) (a : s.active=false) (l : s.live=false) : Safe (grant s) := by simp_all [Safe,grant]
theorem grantDoesNotAdvanceCursor (s : S) : (grant s).hp=s.hp := rfl
theorem beginPreserves (s : S) (h : Safe s) (l : s.live=true) (c : s.clientSerial=s.serial) : Safe (begin s) := by simp_all [Safe,begin]
theorem writePreserves (s : S) (h : Safe s) (a : s.active=true) (n : Nat) (b : s.used+n≤s.budget) : Safe (write s n) := by
  simp_all [Safe,write,Nat.add_assoc]
theorem finishPreserves (s : S) (h : Safe s) : Safe (finish s) := by simp_all [Safe,finish]
theorem cancelPreserves (s : S) (h : Safe s) (a : s.active=false) : Safe (cancel s) := by simp_all [Safe,cancel]
theorem collectPreserves (s : S) (h : Safe s) (f : s.full=true) (l : s.live=false) (a : s.active=false) : Safe (collect s) := by simp_all [Safe,collect]
theorem liveTicketCannotCrossGc (s : S) (h : Safe s) (l : s.live=true) : ¬ Safe (collect s) := by
  simp_all [Safe,collect]
theorem partialFrameCannotCollect (s : S) (h : Safe s) (f : s.full=false) : s.active=true := h.2.2.2.2.2.2.2 f
theorem cancelDoesNotRewindHp (s : S) : (cancel s).hp=s.hp := rfl
theorem collectDoesNotReevaluate (s : S) : (collect s).evals=s.evals := rfl
theorem regrantUsesNewEpoch (s : S) : (grant (collect s)).te=s.epoch+1 := rfl
theorem regrantUsesNewArena (s : S) : (grant (collect s)).ta=s.arena+1 := rfl
theorem budgetPartition (used budget : Nat) (h : used≤budget) : used+(budget-used)=budget := by omega
theorem completedBudgetHasNoUnused (used budget : Nat) (h : used=budget) : budget-used=0 := by omega
theorem knownDenyPreservesFullView (s : S) (h : s.full=true ∧ s.roots=true) : (cancel s).full=true ∧ (cancel s).roots=true := h
inductive Step : S → S → Prop
  | grant (s : S) (h : s.full=true) (a : s.active=false) (l : s.live=false) : Step s (RestCapacityPreflight.grant s)
  | begin (s : S) (l : s.live=true) (c : s.clientSerial=s.serial) : Step s (RestCapacityPreflight.begin s)
  | write (s : S) (a : s.active=true) (n : Nat) (b : s.used+n≤s.budget) : Step s (RestCapacityPreflight.write s n)
  | finish (s : S) (w : s.used=s.budget) : Step s (RestCapacityPreflight.finish s)
  | cancel (s : S) (a : s.active=false) (u : s.used=0) : Step s (RestCapacityPreflight.cancel s)
  | collect (s : S) (f : s.full=true) (l : s.live=false) (a : s.active=false) : Step s (RestCapacityPreflight.collect s)
  | query (s : S) : Step s s
theorem stepPreserves {a b : S} (h : Step a b) (s : Safe a) : Safe b := by
  cases h with
  | grant f a l => exact grantPreserves _ s f a l
  | begin l c => exact beginPreserves _ s l c
  | write a n b => exact writePreserves _ s a n b
  | finish => exact finishPreserves _ s
  | cancel a _ => exact cancelPreserves _ s a
  | collect f l a => exact collectPreserves _ s f l a
  | query => exact s
inductive Trace : S → S → Prop
  | nil (s : S) : Trace s s
  | cons {a b c : S} : Step a b → Trace b c → Trace a c
theorem tracePreserves {a b : S} (h : Trace a b) (s : Safe a) : Safe b := by
  induction h with
  | nil => exact s
  | cons h _ ih => exact ih (stepPreserves h s)
end GambitSMP.RestCapacityPreflight
