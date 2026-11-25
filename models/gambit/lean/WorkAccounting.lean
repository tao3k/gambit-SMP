import LeanPoo.Functional.TransformationResources

namespace GambitSMP.WorkAccounting

-- A projection obligation, not a model of the C runtime or all GC phases.
structure Worker where
  counted : Bool
  privateWork : Bool
  queued : Bool
  deriving DecidableEq

def activeCount : List Worker → Nat
  | [] => 0
  | w :: ws => (if w.counted then 1 else 0) + activeCount ws

def ProducerLifetimeSafe (ws : List Worker) : Prop :=
  ∀ w ∈ ws, w.privateWork = true → w.counted = true

-- The C adapter must aggregate initialization, Tail, dequeued scan, local
-- frontier and any still/weak/helper production into privateWork. Queued work
-- must be covered by QueuesEmpty separately. Counted ownership extends through
-- the last publication/use; an unknown stop cannot clear it. This algebra does
-- not establish release/acquire visibility, condvar progress, physical thread
-- exit, or the completeness of that source projection. Those stay source/QNT
-- adapter duties, not a second temporal proof in Lean.

def QueuesEmpty (ws : List Worker) : Prop :=
  ∀ w ∈ ws, w.queued = false

theorem zeroCountExcludesActive (ws : List Worker) (h : activeCount ws = 0) :
    ∀ w ∈ ws, w.counted = false := by
  induction ws with
  | nil => simp
  | cons head tail ih =>
    cases hc : head.counted with
    | false =>
      simp [activeCount, hc] at h
      intro w hw
      simp only [List.mem_cons] at hw
      rcases hw with rfl | ht
      · exact hc
      · exact ih h w ht
    | true => simp [activeCount, hc] at h

theorem zeroCountAndEmptyQueuesExcludeHiddenWork (ws : List Worker)
    (countZero : activeCount ws = 0)
    (lifetime : ProducerLifetimeSafe ws)
    (queues : QueuesEmpty ws) :
    ∀ w ∈ ws, w.counted = false ∧ w.privateWork = false ∧ w.queued = false := by
  intro w hw
  have inactive := zeroCountExcludesActive ws countZero w hw
  have noPrivate : w.privateWork = false := by
    cases hp : w.privateWork with
    | false => rfl
    | true =>
      have active := lifetime w hw hp
      rw [inactive] at active
      contradiction
  exact ⟨inactive, noPrivate, queues w hw⟩

-- Without producer lifetime accounting, zero count and empty queues are unsafe.
def uncountedProducer : Worker := ⟨false, true, false⟩

theorem missingLifetimeCounterexample :
    activeCount [uncountedProducer] = 0 ∧
    QueuesEmpty [uncountedProducer] ∧
    uncountedProducer.privateWork = true ∧
    ¬ ProducerLifetimeSafe [uncountedProducer] := by
  simp [activeCount, QueuesEmpty, ProducerLifetimeSafe, uncountedProducer]

-- Queue custody is an additional data premise: local idle may coexist with
-- another counted owner's published work. Quint owns preservation by steps;
-- source refinement supplies the complete projection and C synchronization.
def PublishedLifetimeSafe (ws : List Worker) : Prop :=
  ∀ w ∈ ws, w.queued = true → w.counted = true

theorem zeroCountAndProducerCoverageExcludeHiddenWork (ws : List Worker)
    (countZero : activeCount ws = 0)
    (privateLifetime : ProducerLifetimeSafe ws)
    (publishedLifetime : PublishedLifetimeSafe ws) :
    ∀ w ∈ ws, w.counted = false ∧ w.privateWork = false ∧ w.queued = false := by
  have queues : QueuesEmpty ws := by
    intro w hw
    have inactive := zeroCountExcludesActive ws countZero w hw
    cases queued : w.queued with
    | false => rfl
    | true =>
      have active := publishedLifetime w hw queued
      rw [inactive] at active
      contradiction
  exact zeroCountAndEmptyQueuesExcludeHiddenWork ws countZero privateLifetime queues

def uncountedQueuedProducer : Worker := ⟨false, false, true⟩

theorem missingPublishedLifetimeCounterexample :
    activeCount [uncountedQueuedProducer] = 0 ∧
    ProducerLifetimeSafe [uncountedQueuedProducer] ∧
    ¬ PublishedLifetimeSafe [uncountedQueuedProducer] := by
  simp [activeCount, ProducerLifetimeSafe, PublishedLifetimeSafe, uncountedQueuedProducer]

-- Data interpretation only. Quint owns observation freshness, idle/phase
-- admission and unknown-result settlement. Source must establish QueuePost.
-- For the proposed C status/out-pointer adapter, construct acquired only from
-- a committed claim with that exact output; non-acquired outputs must not be
-- interpreted as stale chunks. Caller retry/drain policy is not this data law.
inductive QueueObservation (α : Type) where
  | acquired (item : α)
  | confirmedEmpty
  | unobserved

def QueuePost {α : Type} (result : QueueObservation α)
    (queued claimed nextQueued nextClaimed : List α) : Prop :=
  match result with
  | .acquired item => ∃ rest, queued = item :: rest ∧
      nextQueued = rest ∧ nextClaimed = item :: claimed
  | .confirmedEmpty => queued = [] ∧ nextQueued = queued ∧ nextClaimed = claimed
  | .unobserved => nextQueued = queued ∧ nextClaimed = claimed

theorem unobservedPreservesQueueCustody {α : Type} (q p q' p' : List α)
    (post : QueuePost .unobserved q p q' p') : q' = q ∧ p' = p := post

theorem confirmedEmptyRequiresEmptyQueue {α : Type} (q p q' p' : List α)
    (post : QueuePost .confirmedEmpty q p q' p') : q = [] := post.1

theorem acquiredObservationConservesWorkCount {α : Type}
    (item : α) (q p q' p' : List α)
    (post : QueuePost (.acquired item) q p q' p') :
    q'.length + p'.length = q.length + p.length := by
  obtain ⟨rest, before, afterQueue, afterClaim⟩ := post
  simp only [before, afterQueue, afterClaim, List.length_cons]
  omega

theorem busyMayRetainNonemptyQueue {α : Type} (item : α) (q p : List α) :
    QueuePost .unobserved (item :: q) p (item :: q) p ∧ item :: q ≠ [] := by
  simp [QueuePost]

-- Immutable receipt interpretation; QNT owns slot pins, progress and reuse.
-- Native code must publish all key/payload fields before the acquired decision
-- word and retain their storage for the query. This does not prove that ABI.
structure ClaimKey where
  vm : Nat
  collection : Nat
  phase : Nat
  worker : Nat
  generation : Nat
  deriving DecidableEq

structure ClaimReceipt (α : Type) where
  key : ClaimKey
  item : α

def lookupClaimReceipt {α : Type} (requested : ClaimKey) (receipt : ClaimReceipt α) : Option α :=
  if requested = receipt.key then some receipt.item else none

theorem mismatchedClaimKeyHasNoPayload {α : Type}
    (requested : ClaimKey) (receipt : ClaimReceipt α) (different : requested ≠ receipt.key) :
    lookupClaimReceipt requested receipt = none := by
  simp [lookupClaimReceipt, different]

theorem claimQueryReturnsOnlyRecordedItem {α : Type}
    (requested : ClaimKey) (receipt : ClaimReceipt α) (returned : α)
    (hit : lookupClaimReceipt requested receipt = some returned) : returned = receipt.item := by
  unfold lookupClaimReceipt at hit
  split at hit <;> simp_all

-- Encoding algebra only; Quint owns seal/pin races and writer generations.
-- Source must additionally exclude machine-word overflow and mixed accesses.
def gateEncoding (closed : Bool) (borrowers : Nat) : Nat :=
  (if closed then 1 else 0) + 2 * borrowers

theorem gateEncodingInjective (a b : Bool) (n m : Nat)
    (same : gateEncoding a n = gateEncoding b m) : a = b ∧ n = m := by
  cases a <;> cases b <;> simp [gateEncoding] at * <;> omega

theorem sealedGateZeroHasNoBorrowers (n : Nat) :
    gateEncoding true n = 1 ↔ n = 0 := by
  simp [gateEncoding] <;> omega

theorem checkedBorrowStepFits (n limit : Nat) (room : 2 ≤ limit)
    (guard : gateEncoding false n ≤ limit - 2) : gateEncoding false (n + 1) ≤ limit := by
  simp [gateEncoding] at *
  omega

theorem checkedGenerationSuccessor (generation limit : Nat) (guard : generation < limit) :
    generation + 1 ≤ limit ∧ generation + 1 ≠ generation := by omega

-- Bounds must be established for actual stage work before composing them.
theorem stageCostsStayWithinComposedBudget
    (first second : LeanPoo.Functional.Transformation.ResourceContract)
    (size firstCost secondCost : Nat)
    (firstBound : firstCost ≤ first.cost.apply size)
    (secondBound : secondCost ≤ second.cost.apply (first.size.apply size)) :
    firstCost + secondCost ≤ (first.compose second).cost.apply size := by
  rw [LeanPoo.Functional.Transformation.resource_compose_cost]
  exact Nat.add_le_add firstBound secondBound

-- Transfer-interface obligations, not implementation or weak-memory proofs.
def ServiceReady (announced acknowledged : Bool) : Prop :=
  announced = true ∧ acknowledged = true

theorem announcementWithoutAcknowledgementIsNotReady :
    ¬ ServiceReady true false := by simp [ServiceReady]

def InactiveRootsReady (published mutating : Bool) : Prop :=
  published = true ∧ mutating = false

theorem rootsDoNotPermitConcurrentMutation (published : Bool) :
    ¬ InactiveRootsReady published true := by simp [InactiveRootsReady]

-- Reopening work invalidates zero-count readiness under the existing lifetime
-- contract. This reuses the parameterized theorem instead of a second GC model.
theorem reopenedWorkRevokesZeroCount (ws : List Worker) (w : Worker)
    (member : w ∈ ws) (hasPrivateWork : w.privateWork = true)
    (lifetime : ProducerLifetimeSafe ws) : activeCount ws ≠ 0 := by
  intro zero
  have inactive := zeroCountExcludesActive ws zero w member
  have counted := lifetime w member hasPrivateWork
  rw [inactive] at counted
  contradiction

def SameGeneration (captured current : Nat) : Prop := captured = current

theorem reuseRevokesOldIdentity (captured current : Nat)
    (currentIdentity : SameGeneration captured current) :
    ¬ SameGeneration captured (current + 1) := by
  simp only [SameGeneration] at *
  omega

def EntryBalanced (acquired released : Nat) (original delivered : Int) : Prop :=
  acquired = released ∧ original = delivered

theorem balancedNestedExitsCompose
    (a1 a2 r1 r2 : Nat) (error1 error2 delivered1 delivered2 : Int)
    (first : EntryBalanced a1 r1 error1 delivered1)
    (second : EntryBalanced a2 r2 error2 delivered2) :
    a1 + a2 = r1 + r2 ∧ error1 = delivered1 ∧ error2 = delivered2 := by
  rcases first with ⟨h1, e1⟩
  rcases second with ⟨h2, e2⟩
  exact ⟨by omega, e1, e2⟩

#print axioms zeroCountExcludesActive
#print axioms zeroCountAndEmptyQueuesExcludeHiddenWork
#print axioms missingLifetimeCounterexample
#print axioms zeroCountAndProducerCoverageExcludeHiddenWork
#print axioms missingPublishedLifetimeCounterexample
#print axioms unobservedPreservesQueueCustody
#print axioms confirmedEmptyRequiresEmptyQueue
#print axioms acquiredObservationConservesWorkCount
#print axioms busyMayRetainNonemptyQueue
#print axioms mismatchedClaimKeyHasNoPayload
#print axioms claimQueryReturnsOnlyRecordedItem
#print axioms gateEncodingInjective
#print axioms sealedGateZeroHasNoBorrowers
#print axioms checkedBorrowStepFits
#print axioms checkedGenerationSuccessor
#print axioms stageCostsStayWithinComposedBudget
#print axioms announcementWithoutAcknowledgementIsNotReady
#print axioms rootsDoNotPermitConcurrentMutation
#print axioms reopenedWorkRevokesZeroCount
#print axioms reuseRevokesOldIdentity
#print axioms balancedNestedExitsCompose

end GambitSMP.WorkAccounting
