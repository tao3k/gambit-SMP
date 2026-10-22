import Std.Tactic
namespace GambitSMP.RestGcResumeEnvelope
-- Conditional arithmetic over object extents. Not C provenance or a full GC proof.
theorem suffixBound (m k r : Nat) (partition : k+m=r) :
    3*m+3 ≤ 3*r+3 := by omega
theorem noDoubleCount (k m r : Nat) (partition : k+m=r) :
    3*k+(3*m+3)=3*r+3 := by omega
theorem crossingAndCompletion (m a : Nat) (remaining : m+2≤a) :
    3+(3*m+3)≤3*a := by omega
theorem structureCarrier (a r : Nat) (args : a=r+1) :
    3*r+3=3*a := by omega
theorem boundedStructureCarrier (a : Nat) (limit : a≤8192) :
    3*a≤24576 := by omega
theorem genericJointBound (a p r : Nat) (legal : 1≤p) (shape : r+p=a+1)
    (limit : a≤8192) : 3*r+p+1≤24578 := by omega
theorem completionFits (h m last : Nat) (grant : h+3*m+3≤last) :
    h+3*m≤last ∧ h+3*m+3≤last := by omega
theorem zeroFirstHeapSpan (h last : Nat) (entry : h≤last) : h+0≤last := by omega
theorem stackPrefix (r : Nat) : 8*r≤8*8191 ↔ r≤8191 := by omega
theorem countedOnce (fresh q demand : Nat) (partition : fresh+q=demand) :
    fresh=demand-q := by omega
theorem phaseCredit (baseline q added : Nat) (credit : q≤baseline)
    (positive : added<q) : baseline-q+added<baseline := by omega
theorem unchangedPeak (baseline rest : Nat) : ¬max baseline rest<baseline := by omega
theorem retainedPeak (past current refund : Nat) : past≤max past (current-refund) := Nat.le_max_left _ _
end GambitSMP.RestGcResumeEnvelope
#check GambitSMP.RestGcResumeEnvelope.suffixBound
#print axioms GambitSMP.RestGcResumeEnvelope.suffixBound
#check GambitSMP.RestGcResumeEnvelope.noDoubleCount
#print axioms GambitSMP.RestGcResumeEnvelope.noDoubleCount
#check GambitSMP.RestGcResumeEnvelope.crossingAndCompletion
#print axioms GambitSMP.RestGcResumeEnvelope.crossingAndCompletion
#check GambitSMP.RestGcResumeEnvelope.structureCarrier
#print axioms GambitSMP.RestGcResumeEnvelope.structureCarrier
#check GambitSMP.RestGcResumeEnvelope.boundedStructureCarrier
#print axioms GambitSMP.RestGcResumeEnvelope.boundedStructureCarrier
#check GambitSMP.RestGcResumeEnvelope.genericJointBound
#print axioms GambitSMP.RestGcResumeEnvelope.genericJointBound
#check GambitSMP.RestGcResumeEnvelope.completionFits
#print axioms GambitSMP.RestGcResumeEnvelope.completionFits
#check GambitSMP.RestGcResumeEnvelope.zeroFirstHeapSpan
#print axioms GambitSMP.RestGcResumeEnvelope.zeroFirstHeapSpan
#check GambitSMP.RestGcResumeEnvelope.stackPrefix
#print axioms GambitSMP.RestGcResumeEnvelope.stackPrefix
#check GambitSMP.RestGcResumeEnvelope.countedOnce
#print axioms GambitSMP.RestGcResumeEnvelope.countedOnce
#check GambitSMP.RestGcResumeEnvelope.phaseCredit
#print axioms GambitSMP.RestGcResumeEnvelope.phaseCredit
#check GambitSMP.RestGcResumeEnvelope.unchangedPeak
#print axioms GambitSMP.RestGcResumeEnvelope.unchangedPeak
#check GambitSMP.RestGcResumeEnvelope.retainedPeak
#print axioms GambitSMP.RestGcResumeEnvelope.retainedPeak
