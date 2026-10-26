import ProducerEnvelope
import CopyCapacityComposition
namespace ProducerCapacity
set_option maxHeartbeats 6000000
set_option maxRecDepth 12000
def round4 (n : Int) : Int := ((n+3)/4)*4
def internalFs (stored regs : Int) : Int := round4 stored + round4 (regs+4)-3
def frameSpan (fs : Int) : Int := round4 (fs+3)
theorem normalCapturedFits (fs : Int) (nonneg : 0≤fs) : fs+2<frameSpan fs := by
 simp [frameSpan,round4]; omega
theorem internalSpanExact (stored regs : Int) :
 frameSpan (internalFs stored regs)=round4 stored+round4 (regs+4) := by
 simp [frameSpan,internalFs,round4]; omega
theorem internalCapturedFits (stored regs : Int) :
 internalFs stored regs+2<frameSpan (internalFs stored regs) := by
 rw [internalSpanExact]; simp [internalFs,round4]; omega
theorem normalStoredCap (fs : Int) (h : 0≤fs ∧ fs<16384) : fs+2≤16385 := by omega
theorem defaultInternalCap (fs : Int) (h : 0≤fs ∧ fs<16384) : internalFs fs 5+2≤16395 := by
 simp [internalFs,round4]; omega
theorem supportedRegisterCap (fs regs : Int) (h : 0≤fs ∧ fs<16384 ∧ 0≤regs ∧ regs≤25) :
 internalFs fs regs+2≤16415 := by
 simp [internalFs,round4]; omega
theorem abiMismatchIsReal : internalFs 28 3=33 ∧ internalFs 28 5=37 := by decide
theorem producerConsumerArithmetic (stored regs : Int) :
 round4 stored+(round4 ((regs+1)+3)-3)=internalFs stored regs := by
 simp [internalFs,round4]; omega
theorem descriptorStoredRoundTrip (stored link kind : Int)
 (h : 0≤stored ∧ stored<16384 ∧ 0≤link ∧ link<16384 ∧ 0≤kind ∧ kind<4) :
 ((link*65536+stored*4+kind)/4)%16384=stored ∧
 0≤link*65536+stored*4+kind ∧ link*65536+stored*4+kind<1073741824 := by omega
theorem smallConstructorCap64 (headerBody : Int) (h : 0≤headerBody ∧ headerBody≤255) : headerBody≤255 := h.2
theorem smallConstructorCap32 (headerBody padding : Int)
 (h : 0≤headerBody ∧ headerBody≤255 ∧ 0≤padding ∧ padding≤1) : headerBody+padding≤256 := by omega
theorem argumentVectorCap (np : Int) (h : 0≤np ∧ np<4096) : np+1≤4096 := by omega
theorem closureBound (n fixed trampoline : Int) (h : 0≤n ∧ n≤fixed ∧ 0≤trampoline) : n+trampoline+2≤fixed+trampoline+2 := by omega
theorem thresholdBudget (U T B : Int) (h : 0≤U ∧ 0≤T ∧ T≤U/255 ∧ U+U/255≤B) : U+T≤B := by omega
-- Actual extracted producer AST supplies G/B; source realization of its witness flags is separate.
theorem sourceBudgetHandoff (p : ProducerEnvelopeAst.State) (h : ProducerEnvelopeAst.Safe p)
 (issued : p.sealed=true) (actualU interiorT : Int) (realizes : actualU≤p.u ∧ interiorT≤p.threshold) :
 actualU+interiorT≤p.budget := by
 have bounds := ProducerEnvelope.certificateBounds p h issued
 omega
theorem packingHandoff (p : ProducerEnvelopeAst.State) (h : ProducerEnvelopeAst.Safe p)
 (issued : p.sealed=true) (C P K closed actualU interiorT : Int)
 (realizes : actualU≤p.u ∧ interiorT≤p.threshold)
 (positive : 0<C-p.cap+1)
 (spent : closed*(C-p.cap+1)≤actualU+interiorT)
 (reserved : p.budget<(K-P+1)*(C-p.cap+1)) : closed+P≤K := by
 have b := sourceBudgetHandoff p h issued actualU interiorT realizes
 apply CopyCapacityComposition.enoughHeapSections p.budget C p.cap P K closed positive
 · omega
 · exact reserved
theorem startedScope (p : ProducerEnvelopeAst.State) (h : ProducerEnvelopeAst.Safe p) (started : p.started=true) :
 p.oldPinned=true ∧ p.abi=true ∧ p.sourceWitness=true ∧ p.seenEpoch=p.epoch := by
 have issued : p.sealed=true := by simp_all [ProducerEnvelopeAst.Safe]
 exact ProducerEnvelope.certificateScope p h issued
-- Source 255 is a constructor-family bound, not a universal ordinary-object theorem.
theorem directObjectCounterexample : (300:Int)>255 ∧ (300:Int)<65533 := by decide
-- Ordered physical source pieces prevent charging the same bytes under two descriptor/type names.
structure SourcePiece where
 lo : Int
 hi : Int
 destination : Int
def SourceCover (lo hi : Int) : List SourcePiece → Prop
 | [] => lo≤hi
 | p::ps => lo≤p.lo ∧ p.lo<p.hi ∧ 0≤p.destination ∧ p.destination≤p.hi-p.lo ∧ SourceCover p.hi hi ps
def destinationSum : List SourcePiece → Int
 | [] => 0
 | p::ps => p.destination+destinationSum ps
theorem coverBounds (pieces : List SourcePiece) (lo hi : Int) (h : SourceCover lo hi pieces) : destinationSum pieces≤hi-lo := by
 induction pieces generalizing lo with
 | nil => simp [destinationSum,SourceCover] at *; omega
 | cons p ps ih =>
   simp only [SourceCover] at h
   have rest := ih p.hi h.2.2.2.2
   simp only [destinationSum]
   omega
theorem sourceCoverBudget (pieces : List SourcePiece) (lo hi Q A T B : Int)
 (cover : SourceCover lo hi pieces) (extent : hi-lo≤Q) (budget : Q+A+T≤B) :
 destinationSum pieces+A+T≤B := by
 have bound := coverBounds pieces lo hi cover
 omega
-- An invalid overlapping source list cannot be used as a coverage witness.
theorem overlapRejected : ¬SourceCover 0 10 [⟨0,8,8⟩,⟨4,10,6⟩] := by simp [SourceCover]
end ProducerCapacity
