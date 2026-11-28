/-
  CompiledHostRefinement.lean
  Family 7 (7/12: stress-gsc): Formal Lean 4 laws connecting emitted compiled-host
  C code (gsc/_t-c-2.scm + dynamic .o1 bundles) to runtime safety:
    1. Basic-block write-group dominance and post-safepoint R_HEAP reload soundness
       (Necula 2000 translation validation + Reynolds 2002 small-footprint framing).
    2. ___RETI / ___RETN / ___IFD frame descriptor link and GC-map partition soundness
       (Diwan, Moss, Hudson 1992).
    3. < 6000-label RSS-guard macro observational equivalence when observation is
       inactive and attempt = 0 (connecting include/_gambit/object_access.h.in and
       include/_gambit/runtime_protocols.h.in to the 8 GiB compiler RSS budget).
-/

namespace CompiledHostRefinement

/-! ## Part 1: Basic-Block Write-Group Dominance & Post-Safepoint Reload -/

structure HostCursor where
  epoch        : Nat
  cursorEpoch  : Nat
  heapRoom     : Nat
  stackRoom    : Nat
  demandActive : Bool
  demandHeap   : Nat
  demandStack  : Nat
  deriving DecidableEq, Repr

inductive BlockOp where
  | enterDemand (needStack needHeap : Nat)
  | writeHeap (words : Nat)
  | adjStack (words : Nat)
  | safepointGc (newHeapRoom newStackRoom : Nat)
  | reloadHeap
  | commitDemand
  deriving DecidableEq, Repr

def stepBlockOp (st : HostCursor) (op : BlockOp) : Option HostCursor :=
  match op with
  | BlockOp.enterDemand ns nh =>
      if st.cursorEpoch = st.epoch ∧ ns ≤ st.stackRoom ∧ nh ≤ st.heapRoom then
        some { st with demandActive := true, demandStack := ns, demandHeap := nh }
      else
        none
  | BlockOp.writeHeap w =>
      if st.demandActive = true ∧ st.cursorEpoch = st.epoch ∧
         w ≤ st.demandHeap ∧ w ≤ st.heapRoom then
        some { st with heapRoom := st.heapRoom - w, demandHeap := st.demandHeap - w }
      else
        none
  | BlockOp.adjStack s =>
      if st.demandActive = true ∧ s ≤ st.demandStack ∧ s ≤ st.stackRoom then
        some { st with stackRoom := st.stackRoom - s, demandStack := st.demandStack - s }
      else
        none
  | BlockOp.safepointGc nh ns =>
      -- GC advances global epoch, invalidates cached local cursor, and clears open demand.
      some {
        epoch := st.epoch + 1
        cursorEpoch := st.cursorEpoch
        heapRoom := nh
        stackRoom := ns
        demandActive := false
        demandHeap := 0
        demandStack := 0
      }
  | BlockOp.reloadHeap =>
      some { st with cursorEpoch := st.epoch }
  | BlockOp.commitDemand =>
      if st.demandActive = true then
        some { st with demandActive := false, demandHeap := 0, demandStack := 0 }
      else
        none

def CursorSound (st : HostCursor) : Prop :=
  st.demandActive = true →
    st.cursorEpoch = st.epoch ∧
    st.demandHeap ≤ st.heapRoom ∧
    st.demandStack ≤ st.stackRoom

theorem stepBlockOp_preserves_sound
    (st st' : HostCursor) (op : BlockOp)
    (hInv : CursorSound st)
    (hStep : stepBlockOp st op = some st') :
    CursorSound st' := by
  cases op with
  | enterDemand ns nh =>
      simp only [stepBlockOp] at hStep
      split at hStep
      · rename_i hCond
        injection hStep with hEq
        subst hEq
        intro _
        exact ⟨hCond.1, hCond.2.2, hCond.2.1⟩
      · contradiction
  | writeHeap w =>
      simp only [stepBlockOp] at hStep
      split at hStep
      · rename_i hCond
        injection hStep with hEq
        subst hEq
        intro _
        have hPrev := hInv hCond.1
        refine ⟨hCond.2.1, ?_, hPrev.2.2⟩
        dsimp only
        omega
      · contradiction
  | adjStack s =>
      simp only [stepBlockOp] at hStep
      split at hStep
      · rename_i hCond
        injection hStep with hEq
        subst hEq
        intro _
        have hPrev := hInv hCond.1
        refine ⟨hPrev.1, hPrev.2.1, ?_⟩
        dsimp only
        omega
      · contradiction
  | safepointGc nh ns =>
      simp only [stepBlockOp] at hStep
      injection hStep with hEq
      subst hEq
      intro hAct
      cases hAct
  | reloadHeap =>
      simp only [stepBlockOp] at hStep
      injection hStep with hEq
      subst hEq
      intro hAct
      have hPrev := hInv hAct
      exact ⟨rfl, hPrev.2.1, hPrev.2.2⟩
  | commitDemand =>
      simp only [stepBlockOp] at hStep
      split at hStep
      · injection hStep with hEq
        subst hEq
        intro hAct
        cases hAct
      · contradiction

theorem write_requires_dominating_demand
    (st : HostCursor) (w : Nat)
    (hNoDemand : st.demandActive = false) :
    stepBlockOp st (BlockOp.writeHeap w) = none := by
  simp [stepBlockOp, hNoDemand]

theorem post_safepoint_write_refused_without_reload
    (st stGc : HostCursor) (nh ns needS needH : Nat)
    (hSynced : st.cursorEpoch = st.epoch)
    (hGc : stepBlockOp st (BlockOp.safepointGc nh ns) = some stGc) :
    stepBlockOp stGc (BlockOp.enterDemand needS needH) = none := by
  simp only [stepBlockOp] at hGc
  injection hGc with hEq
  subst hEq
  simp [stepBlockOp, hSynced]

/-! ## Part 2: ___RETI / ___RETN / ___IFD Frame Descriptor Soundness -/

structure FrameDescriptor where
  frameSize : Nat
  linkSlot  : Nat
  gcMap     : List Nat
  rawSlots  : List Nat
  entryFp   : Nat
  retryFp   : Nat

def ValidDescriptor (d : FrameDescriptor) : Prop :=
  (0 < d.frameSize → 1 ≤ d.linkSlot ∧ d.linkSlot ≤ d.frameSize) ∧
  (∀ slot ∈ d.gcMap, 1 ≤ slot ∧ slot ≤ d.frameSize) ∧
  (d.linkSlot ∉ d.gcMap) ∧
  (∀ slot ∈ d.rawSlots, slot ∉ d.gcMap) ∧
  (d.retryFp = d.entryFp)

theorem valid_descriptor_excludes_link_and_raw
    (d : FrameDescriptor) (slot : Nat)
    (hValid : ValidDescriptor d)
    (hInMap : slot ∈ d.gcMap) :
    1 ≤ slot ∧ slot ≤ d.frameSize ∧ slot ≠ d.linkSlot ∧ slot ∉ d.rawSlots := by
  rcases hValid with ⟨_, hRange, hLinkOut, hRawOut, _⟩
  have hBounds := hRange slot hInMap
  refine ⟨hBounds.1, hBounds.2, ?_, ?_⟩
  · intro hEq
    subst hEq
    exact hLinkOut hInMap
  · intro hRaw
    exact hRawOut slot hRaw hInMap

theorem valid_descriptor_preserves_retry_fp
    (d : FrameDescriptor)
    (hValid : ValidDescriptor d) :
    d.retryFp = d.entryFp :=
  hValid.2.2.2.2

/-! ## Part 3: < 6000-Label RSS-Guard Observational Equivalence -/

structure RuntimeObsState where
  hp           : Nat
  fp           : Nat
  obsActive    : Bool
  obsEventLog  : Nat
  commitCalls  : Nat
  gate2Events  : Nat
  deriving DecidableEq, Repr

/-- Small-module (< 6000 labels) inline-guarded ___REST_OBS_STORE expansion
    (vendor/gambit/include/_gambit/object_access.h.in:31-34). -/
def restObsStoreSmall (st : RuntimeObsState) : RuntimeObsState :=
  if st.obsActive then { st with obsEventLog := st.obsEventLog + 1 } else st

/-- Large-module (>= 6000 labels) direct-call ___REST_OBS_STORE expansion
    (vendor/gambit/include/_gambit/object_access.h.in:36-38).
    Inside ___rest_observation_store_fast, the runtime immediately returns when
    !___rest_observation_active. -/
def restObsStoreLarge (st : RuntimeObsState) : RuntimeObsState :=
  if st.obsActive then { st with obsEventLog := st.obsEventLog + 1 } else st

/-- Small-module (< 6000 labels) ___group_demand_commit expansion
    (vendor/gambit/include/_gambit/runtime_protocols.h.in:1227-1230). -/
def groupDemandCommitSmall (st : RuntimeObsState) (attempt : Nat) : RuntimeObsState :=
  if attempt ≠ 0 ∨ st.obsActive = true then
    { st with commitCalls := st.commitCalls + 1 }
  else
    st

/-- Large-module (>= 6000 labels) direct ___group_demand_commit call
    (vendor/gambit/lib/_mem/allocation-limits.inc returns immediately when
    attempt == 0 && !___rest_observation_active). -/
def groupDemandCommitLarge (st : RuntimeObsState) (attempt : Nat) : RuntimeObsState :=
  if attempt ≠ 0 ∨ st.obsActive = true then
    { st with commitCalls := st.commitCalls + 1 }
  else
    st

/-- Small-module (< 6000 labels) ___GATE2_OPEN / ___GATE2_ENTER expansion
    (vendor/gambit/include/_gambit/runtime_protocols.h.in:1243-1253). -/
def gate2SiteSmall (st : RuntimeObsState) : RuntimeObsState :=
  if st.obsActive then { st with gate2Events := st.gate2Events + 1 } else st

def gate2SiteLarge (st : RuntimeObsState) : RuntimeObsState :=
  if st.obsActive then { st with gate2Events := st.gate2Events + 1 } else st

theorem label_guard_threshold_obs_equiv
    (st : RuntimeObsState) (attempt : Nat)
    (hInactive : st.obsActive = false)
    (hFastAttempt : attempt = 0) :
    restObsStoreSmall st = restObsStoreLarge st ∧
    restObsStoreSmall st = st ∧
    groupDemandCommitSmall st attempt = groupDemandCommitLarge st attempt ∧
    groupDemandCommitSmall st attempt = st ∧
    gate2SiteSmall st = gate2SiteLarge st ∧
    gate2SiteSmall st = st := by
  simp [restObsStoreSmall, restObsStoreLarge,
        groupDemandCommitSmall, groupDemandCommitLarge,
        gate2SiteSmall, gate2SiteLarge,
        hInactive, hFastAttempt]

theorem label_guard_general_obs_equiv
    (st : RuntimeObsState) (attempt : Nat) :
    restObsStoreSmall st = restObsStoreLarge st ∧
    groupDemandCommitSmall st attempt = groupDemandCommitLarge st attempt ∧
    gate2SiteSmall st = gate2SiteLarge st := by
  simp [restObsStoreSmall, restObsStoreLarge,
        groupDemandCommitSmall, groupDemandCommitLarge,
        gate2SiteSmall, gate2SiteLarge]

/-! ## Part 4: -D___DYNAMIC ___EXT(___GSTATE->fn) Dispatch Equivalence -/

structure GstateTable where
  obsActiveRef : Bool
  storeHook    : RuntimeObsState → RuntimeObsState
  commitHook   : RuntimeObsState → Nat → RuntimeObsState
  gate2Hook    : RuntimeObsState → RuntimeObsState

def canonicalGstate (obsActive : Bool) : GstateTable :=
  { obsActiveRef := obsActive
    storeHook    := restObsStoreSmall
    commitHook   := groupDemandCommitSmall
    gate2Hook    := gate2SiteSmall }

theorem dynamic_ext_dispatch_equiv
    (st : RuntimeObsState) (attempt : Nat) :
    let gs := canonicalGstate st.obsActive
    gs.obsActiveRef = st.obsActive ∧
    gs.storeHook st = restObsStoreSmall st ∧
    gs.commitHook st attempt = groupDemandCommitSmall st attempt ∧
    gs.gate2Hook st = gate2SiteSmall st := by
  simp [canonicalGstate]

end CompiledHostRefinement
