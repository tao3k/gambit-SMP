namespace GambitSMP.ManagedMarkerLayout
-- An exact key is three bounded 64-bit values, never pointer identity.
structure Key where
  vm : Nat
  slot : Nat
  generation : Nat
  deriving DecidableEq
def radix : Nat := 2^64
def Bounded (k : Key) := k.vm < radix ∧ k.slot < radix ∧ k.generation < radix
def encode (k : Key) : Nat := (k.vm * radix + k.slot) * radix + k.generation
def decode (n : Nat) : Key := ⟨n / radix / radix, n / radix % radix, n % radix⟩
theorem radixPositive : 0 < radix := by decide
theorem decodeEncode (k : Key) (h : Bounded k) : decode (encode k) = k := by
  rcases k with ⟨v,s,g⟩
  simp only [Bounded,radix] at h
  simp only [decode,encode,radix]
  congr 1 <;> omega
theorem encodingInjective (a b : Key) (ha : Bounded a) (hb : Bounded b)
    (h : encode a=encode b) : a=b := by
  have e := congrArg decode h
  simpa [decodeEncode a ha,decodeEncode b hb] using e
-- Generated descriptor scans exactly two SCMOBJ cells, not 24 bytes of raw key.
def roots (i : Nat) : Prop := i=0 ∨ i=1
def rawSlots (wordBytes i : Nat) : Prop := 2 ≤ i ∧ i < 2+24/wordBytes
theorem rootZeroCovered : roots 0 := by simp [roots]
theorem rootOneCovered : roots 1 := by simp [roots]
theorem noRawKeyScanned (w i : Nat) (h : rawSlots w i) : ¬ roots i := by
  simp [rawSlots] at h
  simp [roots]; omega
structure Admission where
  initialized : Bool
  listVisible : Bool
  strongRoot : Bool
  unknown : Bool
  rawCount : Nat
def Safe (a : Admission) := (a.listVisible=true → a.initialized=true ∧ a.strongRoot=true) ∧
  (a.unknown=true → a.strongRoot=true) ∧ a.rawCount=0
def CanAdmit (a : Admission) := a.initialized=true ∧ a.listVisible=false ∧ a.rawCount=0
def admit (a : Admission) := {a with listVisible:=true,strongRoot:=true}
theorem admissionSafe (a : Admission) (h : CanAdmit a) : Safe (admit a) := by simp_all [Safe,CanAdmit,admit]
def unknown (a : Admission) := {a with unknown:=true}
theorem unknownRetainsCustody (a : Admission) (h : Safe a) (r : a.strongRoot=true) : Safe (unknown a) := by simp_all [Safe,unknown]
inductive Step : Admission → Admission → Prop
  | admission (a : Admission) (h : CanAdmit a) : Step a (admit a)
  | lostReply (a : Admission) (h : a.strongRoot=true) : Step a (unknown a)
  | query (a : Admission) : Step a a
theorem stepPreserves {a b : Admission} (h : Step a b) (s : Safe a) : Safe b := by
  cases h with
  | admission h => exact admissionSafe _ h
  | lostReply h => exact unknownRetainsCustody _ s h
  | query => exact s
inductive Trace : Admission → Admission → Prop
  | nil (a : Admission) : Trace a a
  | cons {a b c : Admission} : Step a b → Trace b c → Trace a c
theorem tracePreserves {a b : Admission} (h : Trace a b) (s : Safe a) : Safe b := by
  induction h with
  | nil => exact s
  | cons h _ ih => exact ih (stepPreserves h s)
structure Scan where
  setup : Bool
  marked : Bool
  procMarked : Bool
  done : Bool
def scanRoot (s : Scan) := {s with marked:=true}
def scanBody (s : Scan) := {s with procMarked:=true,done:=true}
def ScanSafe (s : Scan) := s.done=true → s.setup=true ∧ s.marked=true ∧ s.procMarked=true
theorem explicitRootNeedsNoCount (s : Scan) (h : s.setup=true) :
    ScanSafe (scanBody (scanRoot s)) := by simp [ScanSafe,scanBody,scanRoot,h]
theorem lateResetBreaksScan : ¬ ScanSafe ⟨true,false,true,true⟩ := by simp [ScanSafe]
def MayReturn (managed live isOpen sameKey owner : Bool) := managed=true ∧ live=true ∧ isOpen=true ∧ sameKey=true ∧ owner=true
theorem missingRecordRejectsReturn (m o k p : Bool) : ¬ MayReturn m false o k p := by simp [MayReturn]
theorem closedRecordRejectsReturn (m l k p : Bool) : ¬ MayReturn m l false k p := by simp [MayReturn]
theorem wrongOwnerRejectsReturn (m l o k : Bool) : ¬ MayReturn m l o k false := by simp [MayReturn]
def bodyBytes (w : Nat) := 2*w+24
def objectBytes (w : Nat) := 6*w+bodyBytes w
theorem bodyBytes64 : bodyBytes 8=40 := rfl
theorem bodyBytes32 : bodyBytes 4=32 := rfl
theorem payloadDelta (w : Nat) : objectBytes w - (6*w+2*w)=24 := by simp [objectBytes,bodyBytes]; omega
end GambitSMP.ManagedMarkerLayout
