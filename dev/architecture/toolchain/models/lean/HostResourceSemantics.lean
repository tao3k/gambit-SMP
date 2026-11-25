import Std

-- A semantic resource-boundary refinement, not extracted howto-verify GVM.
-- Store abstracts resource/root slots; concrete tagged values, stack/heap layout,
-- complete root enumeration and all opaque callback protocols remain obligations.
namespace Gambit.HostResourceSemantics
abbrev Store := Nat → Nat
abbrev Keep := Nat → Bool
structure Boundary where
 pc : Nat
 nargs : Nat
 fp : Nat
 frameId : Nat
 denv : Nat
 deriving DecidableEq
inductive Event where
 | poll (roots : List Nat)
 | resume (pc : Nat)
 | external (tag : Nat)
 | landing (pc : Nat)
 deriving DecidableEq
structure Machine where
 regs : Store
 boundary : Boundary
 trace : List Event
 world : Nat
structure Host where
 base : Machine
 localRegs : Store
structure Snapshot where
 regs : Store
 boundary : Boundary

def overlay (keep : Keep) (base localRegs : Store) : Store :=
 fun i => if keep i then localRegs i else base i

def observe (keep : Keep) (h : Host) : Machine :=
 {h.base with regs := overlay keep h.base.regs h.localRegs}

def load (keep : Keep) (m : Machine) : Host :=
 ⟨m, fun i => if keep i then m.regs i else 0⟩

theorem observeLoad (keep : Keep) (m : Machine) : observe keep (load keep m)=m := by
 have e : overlay keep m.regs (fun i => if keep i then m.regs i else 0)=m.regs := by
  funext i
  cases e : keep i <;> simp [overlay,e]
 change {m with regs := overlay keep m.regs (fun i => if keep i then m.regs i else 0)}=m
 rw [e]

def set (s : Store) (r value : Nat) : Store := fun i => if i=r then value else s i

def copy (m : Machine) (dst src : Nat) : Machine :=
 {m with regs := set m.regs dst (m.regs src)}

def copyLocal (h : Host) (dst src : Nat) : Host :=
 {h with localRegs := set h.localRegs dst (h.localRegs src)}

theorem copySimulation (keep : Keep) (h : Host) (dst src : Nat)
 (writesCovered : keep dst=true) (readsCovered : keep src=true) :
 observe keep (copyLocal h dst src)=copy (observe keep h) dst src := by
 have e : overlay keep h.base.regs (set h.localRegs dst (h.localRegs src))=
          set (overlay keep h.base.regs h.localRegs) dst
              ((overlay keep h.base.regs h.localRegs) src) := by
  funext i
  by_cases atDst : i=dst
  · subst i; simp [overlay,set,writesCovered,readsCovered]
  · simp [overlay,set,atDst,readsCovered]
 change {h.base with regs := overlay keep h.base.regs (set h.localRegs dst (h.localRegs src))}=
        {h.base with regs := (set (overlay keep h.base.regs h.localRegs) dst
          ((overlay keep h.base.regs h.localRegs) src))}
 rw [e]

-- A boundary first materializes the logical state, executes the SAME operation
-- once, then reloads locals. Proving real C does so is a source obligation.
def boundaryStep (keep : Keep) (f : Machine → Machine) (h : Host) : Host :=
 load keep (f (observe keep h))

def Related (keep : Keep) (m : Machine) (h : Host) : Prop := m=observe keep h

theorem boundarySimulation (keep : Keep) (f : Machine → Machine) (h : Host) :
 observe keep (boundaryStep keep f h)=f (observe keep h) := by
 simp [boundaryStep,observeLoad]

theorem copyRefines (keep : Keep) (m : Machine) (h : Host) (dst src : Nat)
 (related : Related keep m h) (writesCovered : keep dst=true) (readsCovered : keep src=true) :
 Related keep (copy m dst src) (copyLocal h dst src) := by
 change copy m dst src=observe keep (copyLocal h dst src)
 rw [related]
 exact (copySimulation keep h dst src writesCovered readsCovered).symm

theorem boundaryRefines (keep : Keep) (m : Machine) (h : Host) (f : Machine → Machine)
 (related : Related keep m h) : Related keep (f m) (boundaryStep keep f h) := by
 change f m=observe keep (boundaryStep keep f h)
 rw [related,boundarySimulation]

def moveRoots (roots : List Nat) (move : Nat → Nat) (s : Store) : Store :=
 fun i => if roots.contains i then move (s i) else s i

def poll (roots : List Nat) (move : Nat → Nat) (m : Machine) : Machine :=
 {m with regs := moveRoots roots move m.regs, trace := m.trace++[.poll roots]}

theorem pollSimulation (keep : Keep) (h : Host) (roots : List Nat) (move : Nat → Nat) :
 observe keep (boundaryStep keep (poll roots move) h)=poll roots move (observe keep h) :=
 boundarySimulation keep (poll roots move) h

theorem polledRootValue (keep : Keep) (h : Host) (roots : List Nat) (move : Nat → Nat)
 (r : Nat) (rootPresent : roots.contains r=true) :
 (observe keep (boundaryStep keep (poll roots move) h)).regs r=
 move ((observe keep h).regs r) := by
 rw [pollSimulation]
 have member : r ∈ roots := by simpa using rootPresent
 simp [poll,moveRoots,member]

theorem reloadAfterPoll (keep : Keep) (h : Host) (roots : List Nat) (move : Nat → Nat)
 (r : Nat) (resourcePresent : keep r=true) :
 (boundaryStep keep (poll roots move) h).localRegs r=
 (poll roots move (observe keep h)).regs r := by
 simp [boundaryStep,load,resourcePresent]

def capture (m : Machine) : Snapshot := ⟨m.regs,m.boundary⟩
def moveSnapshot (roots : List Nat) (move : Nat → Nat) (k : Snapshot) : Snapshot :=
 {k with regs := moveRoots roots move k.regs}

theorem captureCommutesWithRootUpdate (roots : List Nat) (move : Nat → Nat) (m : Machine) :
 capture (poll roots move m)=moveSnapshot roots move (capture m) := rfl

def resume (k : Snapshot) (current : Machine) : Machine :=
 ⟨k.regs,k.boundary,current.trace++[.resume k.boundary.pc],current.world⟩

theorem resumeSimulation (keep : Keep) (h : Host) (k : Snapshot) :
 observe keep (boundaryStep keep (resume k) h)=resume k (observe keep h) :=
 boundarySimulation keep (resume k) h

theorem resumePreservesWorld (k : Snapshot) (current : Machine) :
 (resume k current).world=current.world := rfl

theorem resumeKeepsNewEffectHistory (k : Snapshot) (current : Machine) :
 (resume k current).trace=current.trace++[.resume k.boundary.pc] := rfl

theorem multiShotResumeSimulation (keep : Keep) (h : Host) (k : Snapshot)
 (between : Machine → Machine) :
 observe keep (boundaryStep keep (resume k)
   (boundaryStep keep between (boundaryStep keep (resume k) h)))=
 resume k (between (resume k (observe keep h))) := by
 simp only [boundarySimulation]

def land (pc : Nat) (m : Machine) : Machine :=
 {m with boundary := {m.boundary with pc:=pc},trace:=m.trace++[.landing pc]}

theorem exceptionLandingSimulation (keep : Keep) (h : Host) (pc : Nat) :
 observe keep (boundaryStep keep (land pc) h)=land pc (observe keep h) :=
 boundarySimulation keep (land pc) h

-- All kept values and all base-only values are materialized. Narrowing does
-- not remove GC roots; root completeness is not proved by the mask theorem.
theorem baseOnlyValuePreserved (keep : Keep) (h : Host) (r : Nat)
 (notLocal : keep r=false) : (observe keep h).regs r=h.base.regs r := by
 simp [observe,overlay,notLocal]
-- Induction over arbitrary finite admitted programs, not just hand-written paths.
inductive Operation where
 | copy (dst src : Nat)
 | boundary (f : Machine → Machine)

def Covered (keep : Keep) : Operation → Prop
 | .copy dst src => keep dst=true ∧ keep src=true
 | .boundary _ => True

def stepSource : Operation → Machine → Machine
 | .copy dst src, m => copy m dst src
 | .boundary f, m => f m

def stepHost (keep : Keep) : Operation → Host → Host
 | .copy dst src, h => copyLocal h dst src
 | .boundary f, h => boundaryStep keep f h

theorem operationRefines (keep : Keep) (op : Operation) (m : Machine) (h : Host)
 (related : Related keep m h) (covered : Covered keep op) :
 Related keep (stepSource op m) (stepHost keep op h) := by
 cases op with
 | copy dst src => exact copyRefines keep m h dst src related covered.1 covered.2
 | boundary f => exact boundaryRefines keep m h f related

def runSource : List Operation → Machine → Machine
 | [], m => m
 | op::rest, m => runSource rest (stepSource op m)

def runHost (keep : Keep) : List Operation → Host → Host
 | [], h => h
 | op::rest, h => runHost keep rest (stepHost keep op h)

theorem finiteProgramSimulation (keep : Keep) (ops : List Operation) :
 ∀ (m : Machine) (h : Host), Related keep m h →
 (∀ op ∈ ops, Covered keep op) →
 Related keep (runSource ops m) (runHost keep ops h) := by
 induction ops with
 | nil => intro m h related _; exact related
 | cons op rest ih =>
  intro m h related covered
  change Related keep (runSource rest (stepSource op m))
    (runHost keep rest (stepHost keep op h))
  apply ih
  · exact operationRefines keep op m h related (covered op (by simp))
  · intro x member
    exact covered x (by simp [member])
end Gambit.HostResourceSemantics
