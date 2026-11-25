import Std
namespace Gambit.LinkStageContract
structure Request where
 members : List Nat
 flags : List Nat
 code : Nat → Nat
 observation : Nat → Nat
 ccMeta : Nat → Nat
 pkg : Nat
 mode : Nat
 base : Nat
 name : Nat
 format : Nat
 abi : Nat
 compiler : Nat
 cc : Nat
 ld : List Nat
 output : Nat
 closed : Bool
structure LinkKey where
 members : List Nat
 flags : List Nat
 observations : List Nat
 mode : Nat
 base : Nat
 name : Nat
 format : Nat
 abi : Nat
 deriving DecidableEq
structure ObjKey where
 moduleId : Nat
 code : Nat
 ccMeta : Nat
 pkg : Nat
 abi : Nat
 compiler : Nat
 cc : Nat
 deriving DecidableEq
structure FinalKey where
 plan : LinkKey
 objects : List ObjKey
 compiler : Nat
 cc : Nat
 pkg : Nat
 ld : List Nat
 output : Nat
 deriving DecidableEq

def linkKey (x : Request) : LinkKey := ⟨x.members,x.flags,x.members.map x.observation,x.mode,x.base,x.name,x.format,x.abi⟩
def objKey (x : Request) (m : Nat) : ObjKey := ⟨m,x.code m,x.ccMeta m,x.pkg,x.abi,x.compiler,x.cc⟩
def finalKey (x : Request) : FinalKey := ⟨linkKey x,x.members.map (objKey x),x.compiler,x.cc,x.pkg,x.ld,x.output⟩

theorem compilerOnlyKeepsLink (x : Request) (c : Nat) : linkKey {x with compiler:=c}=linkKey x := rfl

theorem linkerOptionsKeepObject (x : Request) (ld : List Nat) (m : Nat) : objKey {x with ld:=ld} m=objKey x m := rfl

theorem codeOnlyKeepsLink (x : Request) (code : Nat → Nat) : linkKey {x with code:=code}=linkKey x := rfl

theorem linkMetadataOnlyKeepsObject (x : Request) (obs : Nat → Nat) (m : Nat) : objKey {x with observation:=obs} m=objKey x m := rfl

theorem memberOrderIsInput (x y : Request) (same : linkKey x=linkKey y) : x.members=y.members := congrArg LinkKey.members same

theorem baseIsInput (x y : Request) (same : linkKey x=linkKey y) : x.base=y.base := congrArg LinkKey.base same

theorem changedCodeInvalidates (x : Request) (code : Nat → Nat) (m : Nat) (different : code m≠x.code m) : objKey {x with code:=code} m≠objKey x m := by
 intro same
 exact different (congrArg ObjKey.code same)

def semanticReady (x : Request) (generated : Nat → Prop) : Prop :=
 x.closed=true ∧ (x.mode=0 ∨ x.mode=1) ∧ x.members.length=x.flags.length ∧ ∀ m ∈ x.members, generated m

def finalReady (x : Request) (generated objects : Nat → Prop) (linkObject : Prop) : Prop :=
 semanticReady x generated ∧ (∀ m ∈ x.members, objects m) ∧ linkObject

theorem finalRequiresLeafObjects (x : Request) (g o : Nat → Prop) (l : Prop) (h : finalReady x g o l) : ∀ m ∈ x.members, o m := h.2.1

theorem finalRequiresLinkObject (x : Request) (g o : Nat → Prop) (l : Prop) (h : finalReady x g o l) : l := h.2.2

theorem semanticReadinessIgnoresObjects (x : Request) (g : Nat → Prop) (h : semanticReady x g) : semanticReady x g := h

structure Attempt where
 product : Nat
 context : Nat
 workspace : Nat
 roots : Bool
 frozen : Bool

def parallelAllowed (a b : Attempt) : Prop :=
 a.product≠b.product ∧ a.context≠b.context ∧ a.workspace≠b.workspace ∧
 a.roots=true ∧ b.roots=true ∧ a.frozen=true ∧ b.frozen=true

theorem parallelRequiresPrivateContext (a b : Attempt) (h : parallelAllowed a b) : a.context≠b.context := h.2.1

theorem parallelRequiresPrivateOutput (a b : Attempt) (h : parallelAllowed a b) : a.workspace≠b.workspace := h.2.2.1

theorem sameProductCannotRunTwice (a b : Attempt) (same : a.product=b.product) : ¬parallelAllowed a b := fun h=>h.1 same

theorem parallelKeepsRoots (a b : Attempt) (h : parallelAllowed a b) : a.roots=true ∧ b.roots=true := ⟨h.2.2.2.1,h.2.2.2.2.1⟩

-- View projected from existing owned-session state. Extraction and the physical
-- workspace mapping remain source obligations, not consequences of this type.
structure SessionView where
 attempt : Attempt
 hasCpuLease : Bool
 ownerLive : Bool

def sessionPair (a b : SessionView) : Prop :=
 a.hasCpuLease=true ∧ b.hasCpuLease=true ∧ a.ownerLive=true ∧ b.ownerLive=true ∧ parallelAllowed a.attempt b.attempt

theorem sessionPairNeedsCpu (a b : SessionView) (h : sessionPair a b) : a.hasCpuLease=true ∧ b.hasCpuLease=true := ⟨h.1,h.2.1⟩

theorem pausedPairRefuses (a b : SessionView) (paused : a.hasCpuLease=false) : ¬sessionPair a b := by
 intro h
 have yes:=h.1
 rw [paused] at yes
 contradiction

theorem sessionPairNeedsPrivateContext (a b : SessionView) (h : sessionPair a b) : a.attempt.context≠b.attempt.context := parallelRequiresPrivateContext a.attempt b.attempt h.2.2.2.2

theorem sessionPairKeepsRoots (a b : SessionView) (h : sessionPair a b) : a.attempt.roots=true ∧ b.attempt.roots=true := parallelKeepsRoots a.attempt b.attempt h.2.2.2.2

-- Exact key/projection laws under complete input views. No hash theorem, native
-- data-race proof, scheduler fairness, or automatic QNT-to-Lean extraction.
end Gambit.LinkStageContract
