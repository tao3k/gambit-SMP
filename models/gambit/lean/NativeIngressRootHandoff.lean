/- Conditional custody laws for one ingress activation; not a complete C/QNT simulation. -/
namespace GambitSMP.NativeIngressRootHandoff
structure Custody where
  source : Bool
  child : Bool
  pin : Bool
  raw : Bool
  epoch : Nat
  readEpoch : Nat
  registeredCount : Nat
  nested : Nat
  unknown : Bool
  deriving DecidableEq
def Safe (s : Custody) := (s.source=true ∨ s.child=true) ∧ (s.pin=true → s.source=true) ∧
 (s.raw=true → s.pin=true ∧ s.source=true ∧ s.readEpoch=s.epoch) ∧ s.registeredCount≤1 ∧
 (0<s.nested → s.child=true) ∧ (s.unknown=true → s.child=true)
def publish (s : Custody) := {s with child:=true,raw:=false,registeredCount:=1}
def acknowledge (s : Custody) := {s with source:=false,pin:=false,raw:=false}
def collect (s : Custody) := {s with epoch:=s.epoch+1}
theorem publishPreserves (s : Custody) (h : Safe s) : Safe (publish s) := by simp_all [Safe,publish]
theorem ackPreserves (s : Custody) (h : Safe s) (c : s.child=true) : Safe (acknowledge s) := by simp_all [Safe,acknowledge]
theorem overlapBeforeAck (s : Custody) (h : s.source=true) : (publish s).source=true ∧ (publish s).child=true := by simp [publish,h]
theorem ackNeedsAcceptedChild (s : Custody) (h : Safe (acknowledge s)) : s.child=true := by simpa [Safe,acknowledge] using h.1
theorem unknownRetainsChild (s : Custody) (h : Safe s) (u : s.unknown=true) : s.child=true := h.2.2.2.2.2 u
theorem nestedRetainsChild (s : Custody) (h : Safe s) (n : 0<s.nested) : s.child=true := h.2.2.2.2.1 n
theorem collectPreserves (s : Custody) (h : Safe s) (r : s.raw=false) : Safe (collect s) := by simp_all [Safe,collect]
theorem rawCannotCrossEpoch (s : Custody) (h : Safe s) (r : s.raw=true) : ¬ Safe (collect s) := by simp_all [Safe,collect]
structure Handle where
  vm : Nat
  slot : Nat
  generation : Nat
  deriving DecidableEq
def SameHandle (a b : Handle) := a=b
theorem differentVmRejected (a b : Handle) (h : a.vm≠b.vm) : ¬ SameHandle a b := by intro p; exact h (congrArg Handle.vm p)
theorem differentGenerationRejected (a b : Handle) (h : a.generation≠b.generation) : ¬ SameHandle a b := by intro p; exact h (congrArg Handle.generation p)
def Reclaimable (s : Custody) (drained terminal : Bool) := drained=true ∧ terminal=true ∧ s.pin=false ∧ s.child=false ∧ s.raw=false ∧ s.nested=0 ∧ s.unknown=false
theorem noDrainNoReclaim (s : Custody) (t : Bool) : ¬ Reclaimable s false t := by simp [Reclaimable]
theorem unknownNoReclaim (s : Custody) (d t : Bool) (u : s.unknown=true) : ¬ Reclaimable s d t := by simp_all [Reclaimable]
def RootPayloadBytes (inputs converted depth wordBytes : Nat) := depth*(inputs+converted)*wordBytes
theorem fourInputTwoConverted64 : RootPayloadBytes 4 2 1 8=48 := by decide
theorem nestedSameShape64 : RootPayloadBytes 4 2 2 8=96 := by decide
inductive Step : Custody → Custody → Prop
 | publish (s : Custody) : Step s (NativeIngressRootHandoff.publish s)
 | ack (s : Custody) (c : s.child=true) : Step s (NativeIngressRootHandoff.acknowledge s)
 | collect (s : Custody) (r : s.raw=false) : Step s (NativeIngressRootHandoff.collect s)
theorem stepPreserves {a b : Custody} (h : Safe a) (t : Step a b) : Safe b := by
 cases t with
 | publish => exact publishPreserves a h
 | ack c => exact ackPreserves a h c
 | collect r => exact collectPreserves a h r
end GambitSMP.NativeIngressRootHandoff
