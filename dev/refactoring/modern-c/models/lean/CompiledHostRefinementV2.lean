/-
  CompiledHostRefinementV2.lean
  Family 7 (7/12: stress-gsc) Strengthened Formal Refinement Suite (v2):
    1. Basic-block write-group dominance + inline <6000 fast-span enter refinement
       (proving the value-passed fast-span check refines out-of-line ___group_demand_enter
       and enables dead-code elimination of ___group_demand_commit when obsActive = false).
    2. True Gambit 0-based ___IFD / ___OFD bitfield model (matching
       vendor/gambit/include/_gambit/module_generation.h.in:1065-1116 and
       src/gambit_smp/compiled_host_validator.py:75-155):
       0 <= link < expandedFs, bit `link` set in `gcmap`, bit-pack/unpack roundtrip,
       and concrete witness for real _thread.c ___IFD(___RETN, 1, 0, 0x1L).
    3. Non-tautological two-stage composition equivalence for the <6000-label
       RSS guard: outer inline pre-guard composed with runtime callee equals
       direct runtime callee across all 6 hooks (object_access.h.in & runtime_protocols.h.in).
    4. Genuine dynamic ___EXT(___GSTATE->fn) dispatch refinement and single-hop
       scalar obsActive equivalence to two-hop pointer indirection.
-/

namespace CompiledHostRefinementV2

/-! ## Part 1: Write-Group Dominance & Inline Fast-Span Enter Refinement -/

structure FastSpan where
  stackFloor  : Nat
  stackLimit  : Nat  -- byte span + 1 (0 when unowned or demand active)
  heapLo      : Nat
  heapBytes   : Nat  -- byte span up to soft heap_limit (0 when invalid)
  deriving DecidableEq, Repr

structure HostCursor where
  epoch        : Nat
  cursorEpoch  : Nat
  fpBytes      : Nat
  hpBytes      : Nat
  heapRoom     : Nat  -- words
  stackRoom    : Nat  -- words
  demandActive : Bool
  demandHeap   : Nat
  demandStack  : Nat
  fastSpan     : FastSpan
  deriving DecidableEq, Repr

def wordBytes : Nat := 8

/-- Geometric soundness linking the processor-local fast-span cache to the true
    owned stack/heap word rooms when no slow write-group demand is active. -/
def FastSpanValid (st : HostCursor) : Prop :=
  st.fastSpan.stackLimit > 0 →
    st.demandActive = false ∧
    st.cursorEpoch = st.epoch ∧
    st.fastSpan.stackFloor ≤ st.fpBytes ∧
    (st.fpBytes - st.fastSpan.stackFloor) < st.fastSpan.stackLimit ∧
    (st.fpBytes - st.fastSpan.stackFloor) / wordBytes ≤ st.stackRoom ∧
    (st.fastSpan.heapBytes > 0 →
      st.fastSpan.heapLo ≤ st.hpBytes ∧
      (st.hpBytes - st.fastSpan.heapLo) < st.fastSpan.heapBytes ∧
      (st.fastSpan.heapBytes - (st.hpBytes - st.fastSpan.heapLo)) / wordBytes ≤ st.heapRoom)

/-- Boolean leaf fast-span predicate mirroring allocation-limits.inc:1183-1190
    and the proposed <6000 inline fast-span enter wrapper. -/
def fastSpanFits (st : HostCursor) (needStack needHeap : Nat) : Bool :=
  let fs := st.fastSpan
  let stackOk :=
    decide (fs.stackFloor ≤ st.fpBytes) &&
    decide ((st.fpBytes - fs.stackFloor) < fs.stackLimit) &&
    decide (needStack ≤ (st.fpBytes - fs.stackFloor) / wordBytes)
  let heapOk :=
    decide (needHeap = 0) ||
    (decide (fs.heapLo ≤ st.hpBytes) &&
     decide ((st.hpBytes - fs.heapLo) < fs.heapBytes) &&
     decide (needHeap ≤ (fs.heapBytes - (st.hpBytes - fs.heapLo)) / wordBytes))
  stackOk && heapOk

structure EnterOutcome where
  granted : Bool
  attempt : Nat
  next    : HostCursor
  deriving DecidableEq, Repr

/-- Out-of-line slow fallback when fast-span fails or is invalidated. -/
def slowDemandEnter (st : HostCursor) (needStack needHeap : Nat) (nextAttempt : Nat) : EnterOutcome :=
  if st.cursorEpoch = st.epoch ∧ needStack ≤ st.stackRoom ∧ needHeap ≤ st.heapRoom then
    { granted := true
      attempt := nextAttempt
      next := { st with demandActive := true, demandStack := needStack, demandHeap := needHeap } }
  else
    { granted := false, attempt := nextAttempt, next := st }

/-- Out-of-line ___group_demand_enter (allocation-limits.inc:1171-1200):
    checks leaf fast-span first (attempt = 0), otherwise runs slowDemandEnter. -/
def outOfLineDemandEnter (st : HostCursor) (needStack needHeap nextAttempt : Nat) : EnterOutcome :=
  if fastSpanFits st needStack needHeap then
    { granted := true
      attempt := 0
      next := { st with demandActive := true, demandStack := needStack, demandHeap := needHeap } }
  else
    slowDemandEnter st needStack needHeap nextAttempt

/-- Proposed <6000 inline fast-span wrapper: checks the exact same value-based
    predicate inline before falling back to the out-of-line entry. -/
def inlineFastDemandEnter (st : HostCursor) (needStack needHeap nextAttempt : Nat) : EnterOutcome :=
  if fastSpanFits st needStack needHeap then
    { granted := true
      attempt := 0
      next := { st with demandActive := true, demandStack := needStack, demandHeap := needHeap } }
  else
    outOfLineDemandEnter st needStack needHeap nextAttempt

/-- Theorem 1a: Inline fast-span enter is observationally identical to out-of-line
    ___group_demand_enter on every possible input state. -/
theorem inline_fast_enter_refines_out_of_line
    (st : HostCursor) (ns nh att : Nat) :
    inlineFastDemandEnter st ns nh att = outOfLineDemandEnter st ns nh att := by
  unfold inlineFastDemandEnter outOfLineDemandEnter
  cases fastSpanFits st ns nh <;> simp

/-- Theorem 1b: Whenever fastSpanFits succeeds under FastSpanValid, the admitted
    demand satisfies current epoch, stack room, heap room, and attempt = 0. -/
theorem fast_span_hit_implies_sound_and_zero_attempt
    (st : HostCursor) (ns nh att : Nat)
    (hValid : FastSpanValid st)
    (hFit : fastSpanFits st ns nh = true) :
    let out := inlineFastDemandEnter st ns nh att
    out.granted = true ∧
    out.attempt = 0 ∧
    out.next.cursorEpoch = out.next.epoch ∧
    ns ≤ out.next.stackRoom ∧
    nh ≤ out.next.heapRoom := by
  have hFitUnf :
      (decide (st.fastSpan.stackFloor ≤ st.fpBytes) &&
       decide (st.fpBytes - st.fastSpan.stackFloor < st.fastSpan.stackLimit) &&
       decide (ns ≤ (st.fpBytes - st.fastSpan.stackFloor) / wordBytes)) = true ∧
      (decide (nh = 0) ||
       (decide (st.fastSpan.heapLo ≤ st.hpBytes) &&
        decide (st.hpBytes - st.fastSpan.heapLo < st.fastSpan.heapBytes) &&
        decide (nh ≤ (st.fastSpan.heapBytes - (st.hpBytes - st.fastSpan.heapLo)) / wordBytes))) = true := by
    simpa [fastSpanFits, Bool.and_eq_true] using hFit
  have hStackParts := hFitUnf.1
  simp only [Bool.and_eq_true, decide_eq_true_eq] at hStackParts
  have hLimPos : st.fastSpan.stackLimit > 0 := by omega
  have hSpan := hValid hLimPos
  have hStackRoom : ns ≤ st.stackRoom := Nat.le_trans hStackParts.2 hSpan.2.2.2.2.1
  have hHeapRoom : nh ≤ st.heapRoom := by
    have hH := hFitUnf.2
    simp only [Bool.or_eq_true, Bool.and_eq_true, decide_eq_true_eq] at hH
    cases hH with
    | inl hZero => omega
    | inr hPos =>
        have hHbPos : st.fastSpan.heapBytes > 0 := by omega
        have hHeapValid := hSpan.2.2.2.2.2 hHbPos
        exact Nat.le_trans hPos.2 hHeapValid.2.2
  simp [inlineFastDemandEnter, hFit, hSpan.2.1, hStackRoom, hHeapRoom]

/-! ## Part 2: True Gambit 0-Based ___IFD / ___OFD Bitfield Soundness -/

inductive FrameKind where
  | retn
  | reti
  deriving DecidableEq, Repr

def frameKindCode : FrameKind → Nat
  | .retn => 1
  | .reti => 2

def roundUp (v align : Nat) : Nat :=
  if align ≤ 1 then v
  else
    let r := v % align
    if r = 0 then v else v + (align - r)

/-- Exact Gambit LP64 expanded frame size (matching compiled_host_validator.py:132). -/
def expandedFs (kind : FrameKind) (fs : Nat) : Nat :=
  match kind with
  | .retn => fs
  | .reti => roundUp fs 4 + 5 + 1

/-- Gambit's true 0-based ___IFD descriptor invariant:
    - 5-bit fs (< 32)
    - 0 <= link < expandedFs
    - gcmap fits inside expandedFs bits
    - link slot IS marked live in gcmap (matching real _thread.c ___IFD(___RETN,1,0,0x1L)). -/
def ValidGambitIfd (kind : FrameKind) (fs link gcmap : Nat) : Prop :=
  fs < 32 ∧
  link < expandedFs kind fs ∧
  gcmap < 2 ^ (expandedFs kind fs) ∧
  Nat.testBit gcmap link = true

/-- Exact ___IFD bitfield packing from vendor/gambit/include/_gambit/module_generation.h.in:1109:
    (gcmap << (2*5 + 2)) + (link << (5 + 2)) + (fs << 2) + kind. -/
def packIfd (kindCode fs link gcmap : Nat) : Nat :=
  gcmap * 4096 + link * 128 + fs * 4 + kindCode

def unpackIfdKind (w : Nat) : Nat := w % 4
def unpackIfdFs (w : Nat) : Nat := (w / 4) % 32
def unpackIfdLink (w : Nat) : Nat := (w / 128) % 32
def unpackIfdGcmap (w : Nat) : Nat := w / 4096

theorem ifd_pack_unpack_roundtrip
    (k fs link gcmap : Nat)
    (hk : k < 4) (hfs : fs < 32) (hlink : link < 32) :
    let w := packIfd k fs link gcmap
    unpackIfdKind w = k ∧
    unpackIfdFs w = fs ∧
    unpackIfdLink w = link ∧
    unpackIfdGcmap w = gcmap := by
  dsimp only [packIfd, unpackIfdKind, unpackIfdFs, unpackIfdLink, unpackIfdGcmap]
  refine ⟨?_, ?_, ?_, ?_⟩ <;> omega

private theorem testBit_lt_of_lt_pow2 :
    ∀ (n x i : Nat), x < 2 ^ n → Nat.testBit x i = true → i < n := by
  intro n
  induction n with
  | zero =>
      intro x i hx hbit
      have hx0 : x = 0 := by omega
      subst hx0
      simp [Nat.testBit] at hbit
  | succ k ih =>
      intro x i hx hbit
      cases i with
      | zero => exact Nat.zero_lt_succ k
      | succ j =>
          have hdiv : x / 2 < 2 ^ k := by
            have : 2 ^ (k + 1) = 2 ^ k * 2 := by rw [Nat.pow_succ]
            omega
          have hbit' : Nat.testBit (x / 2) j = true := by
            simpa [Nat.testBit_succ] using hbit
          exact Nat.succ_lt_succ (ih (x / 2) j hdiv hbit')

/-- Every bit set in a valid Gambit gcmap decodes to an in-bounds 0-based slot,
    and the return-link slot itself is guaranteed to be GC-scanned. -/
theorem valid_gambit_ifd_roots_in_bounds_and_scans_link
    (kind : FrameKind) (fs link gcmap : Nat)
    (hValid : ValidGambitIfd kind fs link gcmap) :
    Nat.testBit gcmap link = true ∧
    (∀ slot, Nat.testBit gcmap slot = true → slot < expandedFs kind fs) := by
  rcases hValid with ⟨_, _, hMapBound, hLinkBit⟩
  refine ⟨hLinkBit, fun slot hBit => testBit_lt_of_lt_pow2 (expandedFs kind fs) gcmap slot hMapBound hBit⟩

/-- Concrete witness: real vendor/gambit/lib/_thread.c ___IFD(___RETN, 1, 0, 0x1L). -/
theorem real_thread_c_ifd_valid : ValidGambitIfd .retn 1 0 1 := by
  unfold ValidGambitIfd expandedFs
  decide

/-- Concrete witness: real ___IFD(___RETI, 1, 4, 0x3f1L) (expandedFs = 4 + 5 + 1 = 10). -/
theorem real_reti_ifd_valid : ValidGambitIfd .reti 1 4 0x3f1 := by
  unfold ValidGambitIfd expandedFs roundUp
  decide

/-! ## Part 3: Non-Tautological Two-Stage <6000 vs >=6000 Macro Equivalence -/

structure ObsRuntimeState where
  obsActive     : Bool
  storeEvents   : Nat
  adjustEvents  : Nat
  popEvents     : Nat
  commitEvents  : Nat
  gate2Open     : Nat
  gate2Enter    : Nat
  deriving DecidableEq, Repr

/-- Stage 2 (Runtime callees inside lib/_mem/{rest-observation,allocation-limits}.inc):
    each callee independently checks `obsActive` (or `attempt != 0 || obsActive`). -/
def rtStoreFast (st : ObsRuntimeState) : ObsRuntimeState :=
  if st.obsActive then { st with storeEvents := st.storeEvents + 1 } else st

def rtAdjustFast (st : ObsRuntimeState) : ObsRuntimeState :=
  if st.obsActive then { st with adjustEvents := st.adjustEvents + 1 } else st

def rtPopFast (st : ObsRuntimeState) : ObsRuntimeState :=
  if st.obsActive then { st with popEvents := st.popEvents + 1 } else st

def rtGroupDemandCommit (attempt : Nat) (st : ObsRuntimeState) : ObsRuntimeState :=
  if attempt ≠ 0 ∨ st.obsActive = true then
    { st with commitEvents := st.commitEvents + 1 }
  else
    st

def rtGate2Site (opening : Bool) (st : ObsRuntimeState) : ObsRuntimeState :=
  if st.obsActive then
    if opening then { st with gate2Open := st.gate2Open + 1 }
    else { st with gate2Enter := st.gate2Enter + 1 }
  else
    st

/-- Stage 1 (<6000 inline outer pre-guard wrappers from object_access.h.in:37-39
    and runtime_protocols.h.in:1240-1270): invoke the Stage 2 callee only when
    the outer guard fires. Structurally distinct from direct >=6000 calls! -/
def guardObs (callee : ObsRuntimeState → ObsRuntimeState) (st : ObsRuntimeState) : ObsRuntimeState :=
  if st.obsActive then callee st else st

def guardCommit (obsCompiledIn : Bool) (attempt : Nat)
    (callee : Nat → ObsRuntimeState → ObsRuntimeState) (st : ObsRuntimeState) : ObsRuntimeState :=
  if attempt ≠ 0 ∨ (obsCompiledIn = true ∧ st.obsActive = true) then
    callee attempt st
  else
    st

/-- Non-tautological idempotence theorem: composing the <6000 outer pre-guard
    with every runtime callee yields exact observational equivalence to direct
    >=6000 runtime calls across all states and attempt tokens. -/
theorem two_stage_label_guard_equiv
    (st : ObsRuntimeState) (attempt : Nat) :
    guardObs rtStoreFast st = rtStoreFast st ∧
    guardObs rtAdjustFast st = rtAdjustFast st ∧
    guardObs rtPopFast st = rtPopFast st ∧
    guardCommit true attempt rtGroupDemandCommit st = rtGroupDemandCommit attempt st ∧
    guardObs (rtGate2Site true) st = rtGate2Site true st ∧
    guardObs (rtGate2Site false) st = rtGate2Site false st := by
  cases hObs : st.obsActive <;> cases attempt <;>
    simp [guardObs, guardCommit, rtStoreFast, rtAdjustFast, rtPopFast,
          rtGroupDemandCommit, rtGate2Site, hObs]

/-- Dead-commit elimination theorem under -___GAMBIT_REST_OBSERVATION (obsActive = false):
    when inline fast-span enter succeeds (attempt = 0), ___group_demand_commit
    is provably the identity function and may be statically eliminated. -/
theorem fast_path_commit_dead_when_obs_inactive
    (st : ObsRuntimeState) (hNoObs : st.obsActive = false) :
    guardCommit false 0 rtGroupDemandCommit st = st ∧
    rtGroupDemandCommit 0 st = st := by
  simp [guardCommit, rtGroupDemandCommit, hNoObs]

/-! ## Part 4: Dynamic ___GSTATE/___EXT Table Dispatch & Single-Hop obsActive -/

structure DynamicGstate (Addr : Type) where
  obsSlotAddr   : Addr
  readMem       : Addr → Bool
  obsScalar     : Bool
  fnStoreFast   : ObsRuntimeState → ObsRuntimeState
  fnAdjustFast  : ObsRuntimeState → ObsRuntimeState
  fnPopFast     : ObsRuntimeState → ObsRuntimeState
  fnCommit      : Nat → ObsRuntimeState → ObsRuntimeState
  fnGate2       : Bool → ObsRuntimeState → ObsRuntimeState

def GstateBound {Addr : Type} (gs : DynamicGstate Addr) (st : ObsRuntimeState) : Prop :=
  gs.readMem gs.obsSlotAddr = st.obsActive ∧
  gs.obsScalar = st.obsActive ∧
  gs.fnStoreFast = rtStoreFast ∧
  gs.fnAdjustFast = rtAdjustFast ∧
  gs.fnPopFast = rtPopFast ∧
  gs.fnCommit = rtGroupDemandCommit ∧
  gs.fnGate2 = rtGate2Site

/-- Two-hop dynamic guard (*___GSTATE->___rest_observation_active_ptr) vs
    proposed single-hop scalar guard (___GSTATE->___rest_observation_active) vs
    static direct dispatch. -/
def dynamicTwoHopStore {Addr : Type} (gs : DynamicGstate Addr) (st : ObsRuntimeState) : ObsRuntimeState :=
  if gs.readMem gs.obsSlotAddr then gs.fnStoreFast st else st

def dynamicSingleHopStore {Addr : Type} (gs : DynamicGstate Addr) (st : ObsRuntimeState) : ObsRuntimeState :=
  if gs.obsScalar then gs.fnStoreFast st else st

def dynamicTwoHopCommit {Addr : Type} (gs : DynamicGstate Addr) (att : Nat) (st : ObsRuntimeState) : ObsRuntimeState :=
  if att ≠ 0 ∨ gs.readMem gs.obsSlotAddr = true then gs.fnCommit att st else st

def dynamicSingleHopCommit {Addr : Type} (gs : DynamicGstate Addr) (att : Nat) (st : ObsRuntimeState) : ObsRuntimeState :=
  if att ≠ 0 ∨ gs.obsScalar = true then gs.fnCommit att st else st

theorem dynamic_ext_and_single_hop_refine_static
    {Addr : Type} (gs : DynamicGstate Addr) (st : ObsRuntimeState) (att : Nat)
    (hBound : GstateBound gs st) :
    dynamicTwoHopStore gs st = rtStoreFast st ∧
    dynamicSingleHopStore gs st = dynamicTwoHopStore gs st ∧
    dynamicTwoHopCommit gs att st = rtGroupDemandCommit att st ∧
    dynamicSingleHopCommit gs att st = dynamicTwoHopCommit gs att st := by
  rcases hBound with ⟨hPtr, hScalar, hStore, _, _, hCommit, _⟩
  cases hObs : st.obsActive <;> cases att <;>
    simp [dynamicTwoHopStore, dynamicSingleHopStore,
          dynamicTwoHopCommit, dynamicSingleHopCommit,
          rtStoreFast, rtGroupDemandCommit, hPtr, hScalar, hStore, hCommit, hObs]

end CompiledHostRefinementV2
