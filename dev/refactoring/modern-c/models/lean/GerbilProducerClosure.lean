/-
  GerbilProducerClosure.lean
  Family 11 (11/12: gerbil) standalone Lean 4 proofs (0 sorry, 0 external imports):
    1. Transitive producer and ABI-seal closure across all 8 downstream Gerbil stages
       (boot-gxi -> stage0 -> stage1 -> stdlib -> libgerbil -> lang -> tools -> correctness).
    2. Mixed-ABI / mixed-producer refusal: if any single stage binds a distinct producer
       or ABI seal, the whole downstream consumer cohort cannot be admitted.
    3. Strict partial-stage non-promotion: omitting any of the 8 stages prevents closure.
-/

namespace GerbilProducerClosure

structure ProducerSeal where
  gsiHash          : Nat
  gscHash          : Nat
  libGambitHash    : Nat
  headerHash       : Nat
  smpEnabled       : Bool
  dynamicAbiClosed : Bool   -- 4-way ___IMP_FUNC <-> ___GSTATE <-> setup.c <-> ___EXT closure (incl. ___publish_raw_stack_span)
  deriving DecidableEq, Repr

structure StageReceipt where
  stageOrdinal : Nat
  producer     : ProducerSeal
  passed       : Bool
  deriving DecidableEq, Repr

def StageChainClosed (target : ProducerSeal) (receipts : List StageReceipt) : Prop :=
  ∀ ord, ord < 8 →
    ∃ r ∈ receipts, r.stageOrdinal = ord ∧ r.producer = target ∧ r.passed = true

def AllReceiptsMatchTarget (target : ProducerSeal) (receipts : List StageReceipt) : Prop :=
  ∀ r ∈ receipts, r.producer = target ∧ r.passed = true

def GerbilFamilyAdmitted (target : ProducerSeal) (receipts : List StageReceipt) : Prop :=
  target.smpEnabled = true ∧
  target.dynamicAbiClosed = true ∧
  StageChainClosed target receipts ∧
  AllReceiptsMatchTarget target receipts

theorem unexported_dynamic_abi_blocks_admission
    (target : ProducerSeal) (receipts : List StageReceipt)
    (hLeak : target.dynamicAbiClosed = false) :
    ¬ GerbilFamilyAdmitted target receipts := by
  intro hAdm
  have hClosed := hAdm.2.1
  rw [hLeak] at hClosed
  cases hClosed

theorem mixed_producer_stage_blocks_admission
    (target : ProducerSeal) (receipts : List StageReceipt) (bad : StageReceipt)
    (hMem : bad ∈ receipts) (hDiff : bad.producer ≠ target) :
    ¬ GerbilFamilyAdmitted target receipts := by
  intro hAdm
  have hMatch := hAdm.2.2.2 bad hMem
  exact hDiff hMatch.1

theorem failed_stage_blocks_admission
    (target : ProducerSeal) (receipts : List StageReceipt) (bad : StageReceipt)
    (hMem : bad ∈ receipts) (hFail : bad.passed = false) :
    ¬ GerbilFamilyAdmitted target receipts := by
  intro hAdm
  have hMatch := hAdm.2.2.2 bad hMem
  rw [hFail] at hMatch
  cases hMatch.2

theorem missing_stage_blocks_admission
    (target : ProducerSeal) (receipts : List StageReceipt) (ord : Nat)
    (hOrd : ord < 8)
    (hAbsent : ∀ r ∈ receipts, r.stageOrdinal ≠ ord) :
    ¬ GerbilFamilyAdmitted target receipts := by
  intro hAdm
  rcases hAdm.2.2.1 ord hOrd with ⟨r, hMem, hEq, _, _⟩
  exact hAbsent r hMem hEq

def canonicalFullChain (target : ProducerSeal) : List StageReceipt :=
  (List.range 8).map (fun ord => { stageOrdinal := ord, producer := target, passed := true })

theorem canonical_full_chain_admitted
    (target : ProducerSeal)
    (hSmp : target.smpEnabled = true)
    (hAbi : target.dynamicAbiClosed = true) :
    GerbilFamilyAdmitted target (canonicalFullChain target) := by
  refine ⟨hSmp, hAbi, ?_, ?_⟩
  · intro ord hOrd
    refine ⟨{ stageOrdinal := ord, producer := target, passed := true }, ?_, rfl, rfl, rfl⟩
    unfold canonicalFullChain
    exact List.mem_map.mpr ⟨ord, List.mem_range.mpr hOrd, rfl⟩
  · intro r hMem
    unfold canonicalFullChain at hMem
    rcases List.mem_map.mp hMem with ⟨ord, _, hEq⟩
    subst hEq
    exact ⟨rfl, rfl⟩

end GerbilProducerClosure
