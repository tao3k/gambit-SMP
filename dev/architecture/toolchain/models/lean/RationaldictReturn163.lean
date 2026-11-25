import RationaldictWitness

-- Word coordinates derived from the regs5/align4/reserve3 RETI source branch.
-- Pointer provenance, object tags, concurrency and original producer ABI stay open.
namespace Gambit.RationaldictReturn163
open HostResourceSemantics HostFrameBridge RationaldictWitness
abbrev Memory := Nat → Nat

def put (m : Memory) (slot value : Nat) : Memory := fun i => if i=slot then value else m i

def spill (m regs : Memory) (ira : Nat) : Memory :=
 put (put (put (put (put (put m 1 (regs 0)) 2 (regs 1)) 3 (regs 2)) 4 (regs 3)) 5 (regs 4)) 6 ira

def restore (slots : Memory) (r : Nat) := slots (r+1)
def ordinary (slots : Memory) (move : Nat → Nat) : Memory :=
 fun slot => if slot ∈ ordinarySlots selected then move (slots slot) else slots slot

theorem pushedRegister (m regs : Memory) (ira r : Nat) (bound : r<5) :
 restore (spill m regs ira) r=regs r := by
 have cases : r=0 ∨ r=1 ∨ r=2 ∨ r=3 ∨ r=4 := by omega
 rcases cases with e|e|e|e|e <;> subst r <;> simp [restore,spill,put]
theorem actualReturnSlot (m regs : Memory) (ira : Nat) : (spill m regs ira) 6=ira := by simp [spill,put]
theorem paddingPreserved (m regs : Memory) (ira slot : Nat) (padding : 7≤slot) :
 (spill m regs ira) slot=m slot := by
 have h1 : slot≠1 := by omega
 have h2 : slot≠2 := by omega
 have h3 : slot≠3 := by omega
 have h4 : slot≠4 := by omega
 have h5 : slot≠5 := by omega
 have h6 : slot≠6 := by omega
 simp [spill,put,h1,h2,h3,h4,h5,h6]
theorem ordinaryRestoresArguments (m regs : Memory) (ira r : Nat) (move : Nat → Nat)
 (positive : 1≤r) (bound : r<5) :
 restore (ordinary (spill m regs ira) move) r=move (regs r) := by
 have cases : r=1 ∨ r=2 ∨ r=3 ∨ r=4 := by omega
 rcases cases with e|e|e|e <;> subst r <;> simp [restore,ordinary,selectedRoots,spill,put]
theorem r0ExcludedFromOrdinary (m regs : Memory) (ira : Nat) (move : Nat → Nat) :
 restore (ordinary (spill m regs ira) move) 0=regs 0 := by
 simp [restore,ordinary,selectedRoots,spill,put]
theorem actualReturnUpdated (m regs : Memory) (ira : Nat) (move : Nat → Nat) :
 (ordinary (spill m regs ira) move) 6=move ira := by
 simp [ordinary,selectedRoots,spill,put]

-- F is the pre-POLL stack origin; H=F-12 is the suspended internal-return FP.
def suspended (f : Int) := f-12
def stackAddress (f : Int) (slot : Nat) : Int := f-Int.ofNat slot
def heapAddress (body : Int) (slot : Nat) : Int := body+10-Int.ofNat slot
theorem gcRebasesStack (f : Int) : suspended f+12=f := by simp [suspended]
theorem handlerFindsActualReturn (f : Int) : suspended f-(-6)=stackAddress f 6 := by
 simp [suspended,stackAddress]; omega
theorem addressInjective (f : Int) : Function.Injective (stackAddress f) := by
 intro a b h
 exact Int.ofNat_inj.mp ((Int.sub_right_inj f).mp h)
theorem sentinelOutsidePayload (f : Int) (slot : Nat) (payload : slot≤9) :
 stackAddress f slot≠suspended f := by
 intro same
 have castEq : Int.ofNat slot=12 := (Int.sub_right_inj f).mp same
 have natEq : slot=12 := Int.ofNat_inj.mp castEq
 omega
theorem copiedCoordinate (body : Int) : heapAddress body 6=body+4 := by simp [heapAddress]; omega
theorem heapStructuralLink (body : Int) : heapAddress body 1=body+9 := by simp [heapAddress]; omega
theorem markArrayEndpoints (f : Int) : stackAddress f 6+5=stackAddress f 1 := by
 simp [stackAddress]; omega
theorem markArrayAddresses (f : Int) :
 (List.range 5).map (fun i => stackAddress f 6 + Int.ofNat i)=
 [stackAddress f 6,stackAddress f 5,stackAddress f 4,stackAddress f 3,stackAddress f 2] := by
 have h1 : f-6+1=f-5 := by omega
 have h2 : f-6+2=f-4 := by omega
 have h3 : f-6+3=f-3 := by omega
 have h4 : f-6+4=f-2 := by omega
 simp [stackAddress,List.range_succ,h1,h2,h3,h4]

-- Heap restoration copies payload, then substitutes the structural link.
-- This is intentional: R0's old bit pattern is not an invariant of capture.
def heapRestore (slots : Memory) (breakLink : Nat) := put slots 1 breakLink
theorem heapRestoreOrdinary (slots : Memory) (link r : Nat) (positive : 1≤r) :
 restore (heapRestore slots link) r=restore slots r := by
 have nonzero : r≠0 := by omega
 simp [restore,heapRestore,put,nonzero]
theorem heapRestoreR0 (slots : Memory) (link : Nat) : restore (heapRestore slots link) 0=link := by
 simp [restore,heapRestore,put]

inductive HostMode where | single | multiple deriving DecidableEq
structure TailState where
 nargs : Nat
 next : Nat
 checkedEntry : Bool
 fp : Int
 regs : Memory

def tailTransfer (mode : HostMode) (s : TailState) : TailState :=
 match mode with
 | .single => {s with next:=150,checkedEntry:=false}
 | .multiple => {s with next:=150,nargs:=2,checkedEntry:=true}
theorem singleKeepsNargs (s : TailState) : (tailTransfer .single s).nargs=s.nargs := rfl
theorem multipleSetsNargs (s : TailState) : (tailTransfer .multiple s).nargs=2 := rfl
theorem checkedEntryMode (mode : HostMode) (s : TailState) :
 (tailTransfer mode s).checkedEntry=(match mode with | .single => false | .multiple => true) := by cases mode <;> rfl
theorem tailNoNewFrame (mode : HostMode) (s : TailState) : (tailTransfer mode s).fp=s.fp := by cases mode <;> rfl
theorem tailKeepsArguments (mode : HostMode) (s : TailState) : (tailTransfer mode s).regs=s.regs := by cases mode <;> rfl
-- Point150 denotes the common target body; the native single-host path skips
-- its entry arity guard, multiple-host path enters with nargs2. Not a raw C PC.
end Gambit.RationaldictReturn163
