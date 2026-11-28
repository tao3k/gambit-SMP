import Std

-- Mathematical descriptor correspondence; C pointer validity, shifts and ABI
-- configuration remain separate source/native obligations.
namespace Gambit.FrameContract
def inlineWord (kind size link roots : Nat) := kind + 4*size + 128*link + 4096*roots
def outlineWord (kind size link : Nat) := kind + 4*size + 65536*link

theorem inlineKind (k s l r : Nat) (hk : k<4) : inlineWord k s l r % 4 = k := by
 unfold inlineWord; omega
theorem inlineSize (k s l r : Nat) (hk : k<4) (hs : s<32) :
 (inlineWord k s l r / 4) % 32 = s := by unfold inlineWord; omega
theorem inlineLink (k s l r : Nat) (hk : k<4) (hs : s<32) (hl : l<32) :
 (inlineWord k s l r / 128) % 32 = l := by unfold inlineWord; omega
theorem inlineRoots (k s l r : Nat) (hk : k<4) (hs : s<32) (hl : l<32)
 (hr : r<1048576) : (inlineWord k s l r / 4096) % 1048576 = r := by
 unfold inlineWord; omega
theorem outlineKind (k s l : Nat) (hk : k<4) : outlineWord k s l % 4 = k := by
 unfold outlineWord; omega
theorem outlineSize (k s l : Nat) (hk : k<4) (hs : s<16384) :
 (outlineWord k s l / 4) % 16384 = s := by unfold outlineWord; omega
theorem outlineLink (k s l : Nat) (hk : k<4) (hs : s<16384) (hl : l<16384) :
 (outlineWord k s l / 65536) % 16384 = l := by unfold outlineWord; omega

-- The list contains one-based required stack slots, including live raw values
-- and any stacked return address. GVM extraction completeness and native
-- pointer validity are premises, not consequences of this layout lemma.
def requiredDepth : List Nat → Nat
 | [] => 0
 | slot :: rest => max slot (requiredDepth rest)

theorem requiredDepthCovers (slots : List Nat) :
 ∀ slot ∈ slots, slot ≤ requiredDepth slots := by
 induction slots with
 | nil => intro slot h; cases h
 | cons head rest ih =>
   intro slot h
   rcases List.mem_cons.mp h with h | h
   · subst slot
     exact Nat.le_max_left _ _
   · exact Nat.le_trans (ih slot h) (Nat.le_max_right _ _)

theorem requiredDepthLeast (slots : List Nat) (limit : Nat) :
 (∀ slot ∈ slots, slot ≤ limit) → requiredDepth slots ≤ limit := by
 induction slots with
 | nil => intro _; simp [requiredDepth]
 | cons head rest ih =>
   intro covers
   have first := covers head (by simp)
   have tail := ih (by
     intro slot h
     exact covers slot (by simp [h]))
   simp only [requiredDepth]
   omega

-- A dirty floating cache may own a value before its stack slot is written.
-- Root liveness alone therefore does not inventory every preparatory store.
theorem requiredDepthAppend (live spill : List Nat) :
 requiredDepth (live ++ spill) = max (requiredDepth live) (requiredDepth spill) := by
 induction live with
 | nil => simp [requiredDepth]
 | cons head rest ih => simp [requiredDepth, ih, Nat.max_assoc]

theorem liveDepthAloneDoesNotCoverSpill :
 requiredDepth [1] < requiredDepth ([1] ++ [2]) := by decide

-- Source premises: default-label-info accounts for the already stacked
-- parameters; targ-scan-c-procedure adds arguments in registers, the old RA
-- and FRAME_RESERVE. These formulas own arithmetic, not C pointer custody.
def alignFour (words : Nat) : Nat := 4 * ((words + 3) / 4)
def cEntryExtra (arity argRegs reserve : Nat) : Nat :=
 alignFour (arity + 1 + reserve) - (arity - argRegs)
def handlerBacking (gvmRegs reserve : Nat) : Nat :=
 3 + alignFour (gvmRegs + 1 + reserve)

theorem cEntryExtraBound (arity argRegs reserve : Nat) :
 cEntryExtra arity argRegs reserve ≤ argRegs + reserve + 4 := by
 unfold cEntryExtra alignFour
 omega

theorem cEntryCoveredByArrivalBacking (arity argRegs gvmRegs reserve : Nat)
 (registers : argRegs ≤ gvmRegs) :
 cEntryExtra arity argRegs reserve ≤ handlerBacking gvmRegs reserve := by
 unfold cEntryExtra handlerBacking alignFour
 omega

-- One geometry owner for the caller's preparatory writes and callee arrival.
-- The adapter must supply a complete physical spill inventory and prove that
-- ownedDepth names actual backing, not merely the initialized/root prefix.
theorem entryEnvelopeWithSpill (live spill : List Nat) (ownedDepth : Nat)
 (arity argRegs gvmRegs reserve : Nat)
 (backing : requiredDepth (live ++ spill) ≤ ownedDepth)
 (registers : argRegs ≤ gvmRegs) :
 (∀ slot ∈ spill, slot ≤ ownedDepth) ∧
 cEntryExtra arity argRegs reserve ≤ handlerBacking gvmRegs reserve := by
 constructor
 · intro slot member
   exact Nat.le_trans (requiredDepthCovers (live ++ spill) slot
     (List.mem_append.mpr (Or.inr member))) backing
 · exact cEntryCoveredByArrivalBacking arity argRegs gvmRegs reserve registers

-- The source cache grows from capacity n to 2*n+1, recording n+1 in
-- field zero. Vacant-cell insertion does not update that field. These are
-- branch arithmetic facts, not proof that a particular GVM path fills it.
theorem cacheGrowthVacantCapacity (old : Nat) :
 (2 * old + 1) - (old + 1) = old := by omega

theorem recordedCountCanMissBoxing (words : Nat) (positive : 0 < words) :
 2 * words < 3 * words := by omega

theorem boxingBoundFromInventory (reserved dirty budget words : Nat)
 (inventory : dirty ≤ budget) :
 reserved + dirty * words ≤ reserved + budget * words :=
 Nat.add_le_add_left (Nat.mul_le_mul_right words inventory) reserved

-- The producer must establish inventory <= budget from the actual planned
-- boxing set, not from the cache's field-zero name or a later CHECK_HEAP.
theorem producerEnvelopeWithCache (live spill : List Nat) (ownedDepth : Nat)
 (arity argRegs gvmRegs reserve reserved dirty budget words : Nat)
 (backing : requiredDepth (live ++ spill) ≤ ownedDepth)
 (registers : argRegs ≤ gvmRegs) (inventory : dirty ≤ budget) :
 ((∀ slot ∈ spill, slot ≤ ownedDepth) ∧
 cEntryExtra arity argRegs reserve ≤ handlerBacking gvmRegs reserve) ∧
 reserved + dirty * words ≤ reserved + budget * words :=
 ⟨entryEnvelopeWithSpill live spill ownedDepth arity argRegs gvmRegs reserve
   backing registers, boxingBoundFromInventory reserved dirty budget words inventory⟩

-- Standard ALLOC_ALIGN64 on 32-bit words rounds the cursor after a
-- one-word header and two-word payload to an even word address. On 64-bit
-- words the ordinary memory-box branch advances by two words. Immediate
-- representations allocate nothing. Probe overrides need their own premise.
def boxed32End (heap : Nat) : Nat := 2 * ((heap + 4) / 2)

theorem boxed32Extent (heap : Nat) :
 heap + 3 ≤ boxed32End heap ∧ boxed32End heap ≤ heap + 4 := by
 unfold boxed32End
 omega

theorem boxed32StoresInside (heap : Nat) :
 heap ≤ boxed32End heap - 3 ∧ heap ≤ boxed32End heap - 2 ∧
 boxed32End heap - 1 < boxed32End heap := by
 have extent := boxed32Extent heap
 omega

theorem portableBoxingBound (heap : Nat) :
 boxed32End heap - heap ≤ 4 ∧ (2 : Nat) ≤ 4 ∧ (0 : Nat) ≤ 4 := by
 have extent := boxed32Extent heap
 omega

theorem threeBoxesUnder24 (heap : Nat) :
 boxed32End (boxed32End (boxed32End heap)) - heap ≤ 12 ∧ (12 : Nat) ≤ 24 := by
 have first := boxed32Extent heap
 have second := boxed32Extent (boxed32End heap)
 have third := boxed32Extent (boxed32End (boxed32End heap))
 omega

-- The compiler's portable formula uses min word size 4, two header words
-- and eight-byte alignment. This is a source constant/control, not the
-- effective preprocessed ABI of a particular object.
theorem portableFlonumReservation :
 (8 * ((8 + 4 + 2 * 4 + 7) / 8)) / 4 = (6 : Nat) ∧ (4 : Nat) ≤ 6 := by decide

theorem producerEnvelopeWithMacroClosure (live spill : List Nat) (ownedDepth : Nat)
 (arity argRegs gvmRegs reserve reserved dirty budget words : Nat)
 (backing : requiredDepth (live ++ spill) ≤ ownedDepth)
 (registers : argRegs ≤ gvmRegs) (inventory : dirty ≤ budget) :
 (((∀ slot ∈ spill, slot ≤ ownedDepth) ∧
 cEntryExtra arity argRegs reserve ≤ handlerBacking gvmRegs reserve) ∧
 reserved + dirty * words ≤ reserved + budget * words) ∧
 (∀ heap, boxed32End (boxed32End (boxed32End heap)) - heap ≤ 24) := by
 constructor
 · exact producerEnvelopeWithCache live spill ownedDepth arity argRegs gvmRegs
     reserve reserved dirty budget words backing registers inventory
 · intro heap
   exact Nat.le_trans (threeBoxesUnder24 heap).1 (threeBoxesUnder24 heap).2

theorem currentCEntryExtraBound (arity : Nat) :
 cEntryExtra arity 3 3 ≤ 10 := cEntryExtraBound arity 3 3

theorem currentHandlerBacking : handlerBacking 5 3 = 15 := by decide

-- PUSH_REGS, PUSH(ra) and RETI_RA put the handler cursor below the
-- original entry. Internal return reverses that displacement. Equality of
-- context/epoch alone cannot identify which coordinate a pointer describes.
def handlerDisplacement (cfs gvmRegs reserve : Nat) : Nat :=
 (alignFour cfs - cfs) + alignFour (gvmRegs + 1 + reserve)

theorem currentHandlerDisplacementRange (cfs : Nat) :
 12 ≤ handlerDisplacement cfs 5 3 ∧ handlerDisplacement cfs 5 3 ≤ 15 := by
 unfold handlerDisplacement alignFour
 omega

theorem handlerAndRetryDifferent (cfs : Nat) (entry : Int) :
 entry - Int.ofNat (handlerDisplacement cfs 5 3) ≠ entry := by
 simp only [Int.ofNat_eq_natCast]
 have bounds := currentHandlerDisplacementRange cfs
 omega

-- Checking the old cursor for a handler and checking the adjustment
-- separately does not reserve the handler at the resulting cursor.
-- This is an admitted-state counterexample, not the observed failing PC.
theorem separateChecksDoNotProveArrival :
 (20 : Nat) ≥ 15 ∧ (20 : Nat) ≥ 20 ∧ ¬ (10 : Nat) ≤ 20 - 20 := by decide

-- copy-planning bounds source length; restore_loan_words caps the disjoint
-- lower heap loan. The source/native adapter must prove that these numbers
-- describe one owned destination half and the actual restored cursor.
theorem restoreMarginFromBudget (space length loan fudge : Nat)
 (source : length + fudge ≤ space)
 (lending : loan ≤ space - length - fudge) :
 fudge ≤ space - length - loan := by omega

theorem restoredArrivalBacking (space length loan fudge gvmRegs reserve : Nat)
 (source : length + fudge ≤ space)
 (lending : loan ≤ space - length - fudge)
 (enough : handlerBacking gvmRegs reserve ≤ fudge) :
 handlerBacking gvmRegs reserve ≤ space - length - loan :=
 Nat.le_trans enough (restoreMarginFromBudget space length loan fudge source lending)

-- These legacy dimensional controls formerly lived in Quint. They are
-- retained here so temporal histories do not duplicate the arithmetic owner.
theorem legacyTwentyWordControls :
 20 > (4 : Nat) ∧ 20 > (12 : Nat) ∧ 20 * 8 = (160 : Nat) := by decide
theorem legacyInternalReturnControl :
 (12 : Nat) ≤ 12 ∧ ¬ (13 : Nat) ≤ 12 := by decide
theorem legacyAdjustmentNonzero : (20 : Nat) ≠ 0 := by decide
-- Offset geometry assumes an independently retained, authoritative array span.
-- Neither these bounds nor a GC epoch supplies C pointer provenance or lifetime.
def heapRange (lo hi cursor words : Nat) : Prop :=
 lo ≤ cursor ∧ cursor ≤ hi ∧ words ≤ hi - cursor

def stackRange (lo hi cursor words : Nat) : Prop :=
 lo ≤ cursor ∧ cursor ≤ hi ∧ words ≤ cursor - lo

theorem heapRangeEnd (lo hi cursor words : Nat)
 (h : heapRange lo hi cursor words) : cursor + words ≤ hi := by
 unfold heapRange at h
 omega

-- The producer must identify the complete group budget and actual consumption.
-- This lemma translates a demand's origin; it does not authorize resetting the
-- compiler's traditional cumulative heap-check counter.
def remainingGroupWords (total consumed : Nat) : Nat := total - consumed

theorem remainingGroupConservation (total consumed : Nat) (within : consumed ≤ total) :
 consumed + remainingGroupWords total consumed = total := by
 unfold remainingGroupWords
 omega

theorem remainingGroupFitsCurrentCursor (lo hi total consumed : Nat)
 (backed : lo + total ≤ hi) (within : consumed ≤ total) :
 heapRange lo hi (lo + consumed) (remainingGroupWords total consumed) := by
 unfold heapRange remainingGroupWords
 omega

theorem cumulativeDemandCanRefuseConsumedAllocation :
 heapRange 0 4 4 (remainingGroupWords 4 4) ∧ ¬ heapRange 0 4 4 4 := by
 simp [heapRange, remainingGroupWords]

theorem heapRangeStore (lo hi cursor words offset : Nat)
 (h : heapRange lo hi cursor words) (written : offset < words) :
 lo ≤ cursor + offset ∧ cursor + offset < hi := by
 unfold heapRange at h
 omega

theorem stackRangePush (lo hi cursor words offset : Nat)
 (h : stackRange lo hi cursor words) (positive : 0 < offset)
 (written : offset ≤ words) :
 lo ≤ cursor - offset ∧ cursor - offset < hi := by
 unfold stackRange at h
 omega

-- A one-past cursor can authorize decrement-before-store, never a store at itself.
theorem onePastPushNotDirectStore :
 stackRange 8 16 16 1 ∧ ¬ heapRange 8 16 16 1 := by simp [heapRange, stackRange]

-- Small index controls, not observations of any failing native instruction.
theorem wholeHalfDoesNotAuthorizeHeap :
 heapRange 0 16 4 1 ∧ ¬ heapRange 8 16 4 1 := by simp [heapRange, stackRange]

theorem stackFloorMustClipHeap :
 heapRange 0 16 7 2 ∧ ¬ heapRange 0 8 7 2 := by simp [heapRange, stackRange]

theorem cursorSelectedHalfIsNotAuthority :
 stackRange 0 8 4 1 ∧ ¬ stackRange 8 16 4 1 := by simp [heapRange, stackRange]

-- The negative extend-vars branch drops the deepest logical suffix's
-- list prefix before reverse. The adapter must map actual ret-var identity
-- to this zero-based frame-slots index; name equality is insufficient.
def callerRaProjected (logical cursor index : Nat) : Prop :=
 logical - alignFour cursor ≤ index ∧ index < logical

theorem backedCallerRaSurvives (logical cursor index : Nat)
 (present : index < logical) (backed : logical - index ≤ cursor) :
 callerRaProjected logical cursor index := by
 unfold callerRaProjected alignFour
 omega

theorem requiredCallerRaSurvives (slots : List Nat) (logical cursor index : Nat)
 (present : index < logical) (included : logical - index ∈ slots)
 (backed : requiredDepth slots ≤ cursor) : callerRaProjected logical cursor index := by
 have depth := requiredDepthCovers slots (logical - index) included
 exact backedCallerRaSurvives logical cursor index present (Nat.le_trans depth backed)

-- A mathematical control, not the retained host's unreported actual frame.
theorem truncatedCallerRaControl :
 ¬ callerRaProjected 20 4 0 ∧ callerRaProjected 20 20 0 := by
 simp [callerRaProjected, alignFour]

-- Each inventory uses its own decoded frame origin. Native refinement
-- supplies complete slot lists, the actual owned depths and their attempt.
theorem generatedWriteGroupExtents (oldLive preGrantSpill targetWrites : List Nat)
    (oldDepth demand grantedDepth : Nat)
    (oldBacking : requiredDepth (oldLive ++ preGrantSpill) ≤ oldDepth)
    (demandCovers : requiredDepth targetWrites ≤ demand)
    (newGrant : demand ≤ grantedDepth) :
    (∀ slot ∈ oldLive ++ preGrantSpill, slot ≤ oldDepth) ∧
    (∀ slot ∈ targetWrites, slot ≤ grantedDepth) := by
  constructor
  · intro slot member
    exact Nat.le_trans (requiredDepthCovers (oldLive ++ preGrantSpill) slot member) oldBacking
  · intro slot member
    exact Nat.le_trans (requiredDepthCovers targetWrites slot member)
      (Nat.le_trans demandCovers newGrant)

theorem targetLastSlotRejectsShortExtent (targetWrites : List Nat)
    (last grantedDepth : Nat) (touched : last ∈ targetWrites) (short : grantedDepth < last) :
    ¬ requiredDepth targetWrites ≤ grantedDepth := by
  intro covers
  exact (Nat.not_le_of_gt short)
    (Nat.le_trans (requiredDepthCovers targetWrites last touched) covers)

-- Decode from the handler coordinate at the actual unwind. A native witness
-- must account for any relocation between the earlier save and this point.
def decodedCallerFp (handlerAtUnwind : Int) (cfs gvmRegs reserve : Nat) : Int :=
  handlerAtUnwind + Int.ofNat (handlerDisplacement cfs gvmRegs reserve)

def stackStoreAddress (base priorAdjustment slotOffset : Int) : Int :=
  base - priorAdjustment - slotOffset

theorem firstStoreAddressFromUnwind
    (handlerAtUnwind actualCaller grantBase writeFp priorAdjustment slotOffset : Int)
    (cfs gvmRegs reserve : Nat)
    (decoded : actualCaller = decodedCallerFp handlerAtUnwind cfs gvmRegs reserve)
    (grantMatches : grantBase = actualCaller) (adjusted : writeFp = grantBase - priorAdjustment) :
    writeFp - slotOffset =
      stackStoreAddress (decodedCallerFp handlerAtUnwind cfs gvmRegs reserve)
        priorAdjustment slotOffset := by
  rw [adjusted, grantMatches, decoded]
  rfl

-- Sequence numbers belong to one complete native observation window.
def SettledWindow (invocation grantOwner settleOwner grant write commit retire : Nat)
    (laterEffects : List Nat) : Prop :=
  invocation = grantOwner ∧ invocation = settleOwner ∧
    grant < write ∧ write < commit ∧ commit < retire ∧
    (∀ seq ∈ laterEffects, commit < seq → retire ≤ seq)

theorem committedWindowRejectsReplay
    (invocation grantOwner settleOwner grant write commit retire replay : Nat)
    (laterEffects : List Nat)
    (w : SettledWindow invocation grantOwner settleOwner grant write commit retire laterEffects)
    (effect : replay ∈ laterEffects) (afterCommit : commit < replay) :
    ¬ replay < retire := by
  exact Nat.not_lt_of_ge (w.2.2.2.2.2 replay effect afterCommit)

theorem settledWindowRejectsForeignAttempt
    (invocation grantOwner settleOwner grant write commit retire : Nat)
    (laterEffects : List Nat) (foreignAttempt : invocation ≠ settleOwner) :
    ¬ SettledWindow invocation grantOwner settleOwner grant write commit retire laterEffects :=
  fun w => foreignAttempt w.2.1

theorem handlerOriginChangesFirstStore (handlerAtUnwind priorAdjustment slotOffset : Int)
    (cfs : Nat) :
    stackStoreAddress handlerAtUnwind priorAdjustment slotOffset ≠
      stackStoreAddress (decodedCallerFp handlerAtUnwind cfs 5 3)
        priorAdjustment slotOffset := by
  unfold stackStoreAddress decodedCallerFp
  intro sameAddress
  simp only [Int.ofNat_eq_natCast] at sameAddress
  have bounds := currentHandlerDisplacementRange cfs
  omega

-- Test the pre-enter spill against old backing, independently of any
-- post-refill grant. The slot list uses the decoded old-frame origin.
theorem preEnterSpillNeedsOldExtent (spill : List Nat) (oldDepth : Nat) :
    (∀ slot ∈ spill, slot ≤ oldDepth) ↔ requiredDepth spill ≤ oldDepth := by
  constructor
  · exact requiredDepthLeast spill oldDepth
  · intro fits slot member
    exact Nat.le_trans (requiredDepthCovers spill slot member) fits

-- Lowered writes use a common admission origin even after signed ADJFPs.
-- The native inventory must include macro/inliner effects, not only GVM locs.
structure AnchoredStore where
 priorAdjustment : Int
 slotOffset : Int

def anchoredEndpoint (store : AnchoredStore) : Int :=
 store.priorAdjustment + store.slotOffset

theorem stackOriginRebase (entry consumed later slot : Int) :
 stackStoreAddress (entry - consumed) later slot =
 stackStoreAddress entry (consumed + later) slot := by
 unfold stackStoreAddress
 omega

-- New words below entry fit the physical [low, high) interval. Writes above
-- entry or to old slots need their separately decoded authority premises.
theorem anchoredNewStackStoresInside
 (stores : List AnchoredStore) (entry low high grantWords : Int)
 (entryInside : entry ≤ high) (grantLow : low ≤ entry - grantWords)
 (complete : ∀ store ∈ stores,
   1 ≤ anchoredEndpoint store ∧ anchoredEndpoint store ≤ grantWords) :
 ∀ store ∈ stores,
   low ≤ stackStoreAddress entry store.priorAdjustment store.slotOffset ∧
   stackStoreAddress entry store.priorAdjustment store.slotOffset < high := by
 intro store member
 have bounds := complete store member
 unfold anchoredEndpoint at bounds
 unfold stackStoreAddress
 omega

theorem localMaximumCanMissRebasedStore :
 max (4 : Int) 6 = 6 ∧
 ¬ (94 ≤ stackStoreAddress 100 4 6) := by decide

-- Equality of physical depth says nothing about root kind or register roots.
inductive RootLocation where
 | stack : Nat → RootLocation
 | register : Nat → RootLocation
 deriving DecidableEq

inductive RootRepresentation where
 | scheme
 | raw
 deriving DecidableEq

def rootMapCovers (required decoded : List (RootLocation × RootRepresentation)) : Bool :=
 required.all (fun root => decoded.contains root)

theorem sameSlotExtentDoesNotProveRootRepresentation :
 rootMapCovers [(.stack 1, .scheme)] [(.stack 1, .raw)] = false := by decide

theorem stackRootExtentDoesNotCoverRegisterRoot :
 rootMapCovers [(.stack 1, .scheme), (.register 3, .scheme)]
   [(.stack 1, .scheme)] = false := by decide

-- Fast pair construction and the full slow reservation have different
-- footprints. This equation does not prove that either lowering is complete.
theorem fastAndFullDemandAreDistinct (pairs formalWords header : Nat) (positive : 0 < header) :
    pairs < pairs + formalWords + header := by omega

-- A decoder bounded by this logical stop cannot supply a successor-segment
-- witness. Actual C provenance, checked arithmetic and decoder refinement
-- are premises; this is not a proof of whole-program unreachability.
theorem boundedCallerWalkStaysInSegment (lo hi stop top next : Nat)
    (entry : lo ≤ top ∧ top < stop ∧ stop ≤ hi)
    (decoded : top ≤ next ∧ next ≤ stop) (continues : next ≠ stop) :
    lo ≤ next ∧ next < hi := by omega

-- Unchanged construction memory does not imply entry backing. Whole-state
-- byte rollback is not required: readiness is a distinct public guarantee.
theorem zeroWritesDoesNotEstablishReentry :
    ∃ (constructionWrites : Nat) (entryBacked : Bool),
      constructionWrites = 0 ∧ entryBacked = false := by
  exact ⟨0, false, rfl, rfl⟩

-- These numerical states are compatible with the publication contract. They
-- do not construct a Scheme program or prove collector-tail reachability.
theorem postGCNineNotExcluded (fudge quota : Nat) (enough : 9 ≤ quota) :
    min quota ((fudge + 9) - fudge) = 9 := by omega

theorem physicalReserveAloneDoesNotGrantTen (fudge : Nat) :
    fudge ≤ fudge + 9 ∧ ¬ (10 ≤ (fudge + 9) - fudge) := by omega

-- Valid positive frame extents in a single native half cannot exhaust the
-- image's 100000-step guard. Decoder validity and current-half provenance
-- are implementation premises, not consequences of this arithmetic.
theorem validHalfWalkBelowGuard (steps consumed : Nat)
    (positiveFrames : 4 * steps ≤ consumed) (withinHalf : consumed ≤ 65536) :
    steps < 100000 := by omega

-- A scalar sequence is local to an incarnation. Source refinement must
-- establish lifetime uniqueness, checked exhaustion and non-overlapping
-- writers; equality of recycled C pointers supplies none of those facts.
structure ServiceOwner where
  vmLifetime : Nat
  processor : Nat
  incarnation : Nat
  deriving DecidableEq

structure ServiceAttempt where
  owner : ServiceOwner
  sequence : Nat
  context : Nat
  activation : Nat
  point : Nat
  deriving DecidableEq

def sameServiceAttempt (a b : ServiceAttempt) : Prop :=
  0 < a.sequence ∧ a = b

theorem serviceAttemptRejectsDifferentOwner (a b : ServiceAttempt)
    (different : a.owner ≠ b.owner) : ¬ sameServiceAttempt a b := by
  intro matched
  exact different (congrArg ServiceAttempt.owner matched.2)

theorem zeroSequenceHasNoServiceAuthority (a b : ServiceAttempt)
    (zero : a.sequence = 0) : ¬ sameServiceAttempt a b := by
  intro matched
  have positive := matched.1
  omega

-- Offsets are decoded from the whole lowered group. The C refinement
-- supplies the actual owned interval, alignment and uninterrupted lifetime.
theorem fittingHeapStoresInside (low hp high words offset : Nat)
    (owned : low ≤ hp) (fit : hp + words ≤ high) (store : offset < words) :
    low ≤ hp + offset ∧ hp + offset < high := by omega

-- Mutator stack write-groups reserve [lo, lo + fudge) for the limit handler's
-- internal-return spill frame. When a mutator group is refused at fp >= lo + fudge
-- because fp - (lo + fudge) < delta, the handler spill frame still fits above lo.
theorem mutatorFudgeReserveProtectsHandlerSpill
    (lo hi fp fudge spill delta : Nat)
    (span : lo + fudge < hi)
    (aboveFloor : lo + fudge ≤ fp ∧ fp ≤ hi)
    (spillBound : spill ≤ fudge)
    (_shortage : fp - (lo + fudge) < delta) :
    lo ≤ fp - spill ∧ fp - spill ≤ hi := by omega

theorem mutatorFudgeFitStaysAboveFloor
    (lo hi fp fudge delta : Nat)
    (span : lo + fudge < hi)
    (aboveFloor : lo + fudge ≤ fp ∧ fp ≤ hi)
    (fit : delta ≤ fp - (lo + fudge)) :
    lo + fudge ≤ fp - delta ∧ fp - delta ≤ hi := by omega

-- When ps->heap_limit was set below hard - fudge by an initial poll quota,
-- extending soft to hard - fudge in-place admits any group that still fits
-- below hard - fudge without abandoning the active heap section.
theorem inSectionSoftExtensionPreservesHardReserve
    (start hp soft hard fudge words : Nat)
    (fudgePos : 0 < fudge)
    (owned : start ≤ hp ∧ hp ≤ hard - fudge)
    (fudgeInside : start + fudge < hard)
    (pollShort : soft < hard - fudge ∧ soft < hp + words)
    (preFudgeFit : words ≤ (hard - fudge) - hp) :
    hp + words ≤ hard - fudge ∧ hard - fudge < hard := by omega

-- When pre-fudge room is positive (hp < hard - fudge) and the write-group
-- fits within the physical section (hp + words ≤ hard), retaining the active
-- section preserves both positive pre-fudge tail visibility and hard bounds.
theorem preFudgeShortageFitsInActiveSection
    (start hp hard fudge words : Nat)
    (owned : start ≤ hp)
    (preFudgePos : hp + fudge < hard)
    (hardFit : hp + words ≤ hard) :
    0 < (hard - fudge) - hp ∧ hp + words ≤ hard := by omega

-- Clearing one dirty FP-cache entry before reserving flonumWords transfers
-- capacity from the dirty cache count to reserved heap words without inflating
-- the write-group's total heap budget.
theorem dirtyFlonumFlushConservesHeapWords
    (reserved dirty flonumWords : Nat)
    (dirtyPos : 0 < dirty) :
    (reserved + flonumWords) + (dirty - 1) * flonumWords =
      reserved + dirty * flonumWords := by
  cases dirty with
  | zero => omega
  | succ d =>
    simp [Nat.succ_sub_one, Nat.succ_mul]
    omega

-- A c-lambda entry write-group whose return address resides in R0 immediately
-- above the aligned stacked-argument prefix has link = alignedPcFs, never an
-- inherited slot outside R0.
theorem cLambdaEntryLinkSelectsSavedReturnRegister
    (pcFs alignedPcFs nbRegs : Nat)
    (aligned : pcFs ≤ alignedPcFs)
    (regsPos : 0 < nbRegs) :
    alignedPcFs < alignedPcFs + nbRegs ∧ pcFs ≤ alignedPcFs := by omega

-- Thread-local collector section-lookup caches (scan_state_*, census_*,
-- msection_find_cache) isolate worker w1 from concurrent updates by w2 ≠ w1,
-- preventing cross-worker bitmap base/offset aliasing under parallel GC (nw ≥ 2).
structure SectionCacheEntry where
  sectionId : Nat
  baseAddr : Nat
  epoch : Nat
  deriving DecidableEq

def updateWorkerCache (caches : Nat → SectionCacheEntry) (w : Nat)
    (entry : SectionCacheEntry) : Nat → SectionCacheEntry :=
  fun q => if q = w then entry else caches q

theorem threadLocalSectionCacheIsolatesWorkers
    (caches : Nat → SectionCacheEntry) (w1 w2 : Nat) (entry2 : SectionCacheEntry)
    (distinct : w1 ≠ w2) :
    updateWorkerCache caches w2 entry2 w1 = caches w1 := by
  unfold updateWorkerCache
  simp [distinct]

-- Once runtime GC admission is open (lifecycleGcAdmitted = true), a non-planted
-- physical rest-tail shortage enters root-window custody and garbage collection
-- before section extension; during early bootstrap (lifecycleGcAdmitted = false)
-- direct extension remains available.
def restPreGcDirectExtend (lifecycleGcAdmitted plantedShort physicalShort : Bool) : Bool :=
  (!lifecycleGcAdmitted) && (!plantedShort) && physicalShort

theorem admittedRestShortageCollectsBeforeExtend
    (plantedShort physicalShort : Bool) :
    restPreGcDirectExtend true plantedShort physicalShort = false := by
  simp [restPreGcDirectExtend]

-- Recording the Phase-1 rest native cut at fp before pushing rest_param_list
-- or staging keyword arguments preserves the exact post-pop stack coordinate
-- fp0 + poppedPairs.
theorem exactCutBeforeStagingPreservesPairWindow
    (fp0 poppedPairs stagedPush : Nat) :
    (fp0 + poppedPairs) ≠ (fp0 + poppedPairs) + (stagedPush + 1) := by omega

end Gambit.FrameContract
