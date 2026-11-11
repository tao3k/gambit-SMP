import Std

namespace GambitSMP.RetirementRepairCampaign

-- Identity is an observed test/run key, not a native owner capability.
structure Key where
  source : Nat
  configuration : Nat
  vm : Nat
  generation : Nat
  caseId : Nat
  deriving DecidableEq

structure Receipt where
  key : Key
  joins : Nat

structure State where
  key : Key
  phase : Nat := 0
  joins : Nat := 0
  failed : Bool := false
  receipts : List Receipt := []

inductive Event where
  | joined (key : Key)
  | transferred (key : Key)
  | releaseReturned (key : Key)
  | cleared (key : Key)
  | collect (key : Key)
  | failedJoin (key : Key)
  | busy (key : Key)
  | next (key : Key)

def step (s : State) : Event → State
  | .joined k => if k = s.key ∧ s.failed = false ∧ s.phase = 0 then
      { s with phase := 1, joins := s.joins + 1 } else s
  | .transferred k => if k = s.key ∧ s.failed = false ∧ s.phase = 1 then
      { s with phase := 2 } else s
  | .releaseReturned k => if k = s.key ∧ s.failed = false ∧ s.phase = 2 then
      { s with phase := 3 } else s
  | .cleared k => if k = s.key ∧ s.failed = false ∧ s.phase = 3 then
      { s with phase := 4 } else s
  | .collect k => if k = s.key ∧ s.failed = false ∧ s.phase = 4 then
      { s with phase := 5, receipts := ⟨s.key, s.joins⟩ :: s.receipts } else s
  | .failedJoin k => if k = s.key ∧ s.failed = false ∧ s.phase = 0 then
      { s with failed := true } else s
  | .busy _ => s
  | .next k => if s.failed = false ∧ s.phase = 5 ∧ k.generation > s.key.generation then
      { key := k, receipts := s.receipts } else s

def Inv (s : State) : Prop :=
  s.joins ≤ 1 ∧ (s.phase = 0 → s.joins = 0) ∧
  (s.phase > 0 → s.joins = 1) ∧ ∀ r ∈ s.receipts, r.joins = 1

theorem initial_inv (k : Key) : Inv { key := k } := by
  simp [Inv]

theorem step_preserves (s : State) (e : Event) (h : Inv s) : Inv (step s e) := by
  rcases h with ⟨hc, hz, hp, hr⟩
  cases e <;> simp only [step]
  all_goals first
    | exact ⟨hc, hz, hp, hr⟩
    | split <;> simp_all [Inv]

-- Any finite sequence, any source/configuration/VM/case and generation count.
def run (s : State) : List Event → State
  | [] => s
  | e :: es => run (step s e) es

theorem trace_preserves (s : State) (es : List Event) (h : Inv s) : Inv (run s es) := by
  induction es generalizing s with
  | nil => exact h
  | cons e es ih => exact ih _ (step_preserves s e h)

theorem all_receipts_join_once (k : Key) (es : List Event) :
    ∀ r ∈ (run { key := k } es).receipts, r.joins = 1 :=
  (trace_preserves _ _ (initial_inv k)).2.2.2

theorem busy_preserves_joined_state (s : State) (k : Key) : step s (.busy k) = s := rfl

theorem joined_retry_does_not_join_twice (s : State) (k : Key) (h : s.phase = 1) :
    step s (.joined k) = s := by
  simp [step, h]

theorem stale_join_is_ignored (s : State) (k : Key) (h : k ≠ s.key) :
    step s (.joined k) = s := by simp [step, h]

theorem failure_cannot_be_reset (s : State) (k : Key) (h : s.failed = true) :
    step s (.next k) = s := by simp [step, h]

theorem unfinished_cannot_start_next (s : State) (k : Key) (h : s.phase ≠ 5) :
    step s (.next k) = s := by simp [step, h]

theorem failed_step_retains (s : State) (e : Event) (h : s.failed = true) :
    step s e = s := by
  cases e <;> simp [step, h]

theorem failed_trace_retains (s : State) (es : List Event) (h : s.failed = true) :
    run s es = s := by
  induction es with
  | nil => rfl
  | cons e es ih => simpa [run, failed_step_retains s e h] using ih

def first : Key := ⟨1, 1, 0, 0, 0⟩
def second : Key := ⟨1, 1, 0, 1, 0⟩
def closeEvents (k : Key) : List Event :=
  [.joined k, .busy k, .joined k, .transferred k,
   .releaseReturned k, .cleared k, .collect k]

theorem repeated_completion_is_reachable :
    (run { key := first } (closeEvents first ++ [Event.next second] ++ closeEvents second)).receipts.map Receipt.key = [second, first] := by decide

-- Archive retention and applicability are distinct. An old receipt is kept
-- as historical evidence but cannot satisfy a different current run key.
def Applicable (current : Key) (r : Receipt) : Prop := r.key = current

theorem old_generation_is_not_current (current : Key) (r : Receipt)
    (h : r.key.generation ≠ current.generation) : ¬ Applicable current r := by
  intro same
  exact h (congrArg Key.generation same)

theorem other_vm_is_not_current (current : Key) (r : Receipt)
    (h : r.key.vm ≠ current.vm) : ¬ Applicable current r := by
  intro same
  exact h (congrArg Key.vm same)

theorem changed_source_is_not_current (current : Key) (r : Receipt)
    (h : r.key.source ≠ current.source) : ¬ Applicable current r := by
  intro same
  exact h (congrArg Key.source same)

theorem changed_configuration_is_not_current (current : Key) (r : Receipt)
    (h : r.key.configuration ≠ current.configuration) : ¬ Applicable current r := by
  intro same
  exact h (congrArg Key.configuration same)

-- Recipient ownership is independent of the donor's next cohort. This is
-- logical resource conservation; a lastRead event still needs a native witness.
structure Ledger where
  received : List Key := []
  owned : List Key := []
  completed : List Key := []

inductive LedgerEvent where
  | receive (key : Key)
  | lastRead (key : Key)
  | nextCohort

def ledgerStep (l : Ledger) : LedgerEvent → Ledger
  | .receive k => if k ∈ l.received then l else
      { l with received := k :: l.received, owned := k :: l.owned }
  | .lastRead k => if k ∈ l.owned then
      { l with owned := l.owned.filter (fun x => decide (x ≠ k)), completed := k :: l.completed } else l
  | .nextCohort => l

def LedgerInv (l : Ledger) : Prop := ∀ k,
  (k ∈ l.received ↔ k ∈ l.owned ∨ k ∈ l.completed) ∧
  ¬ (k ∈ l.owned ∧ k ∈ l.completed)

theorem empty_ledger_inv : LedgerInv {} := by simp [LedgerInv]

theorem ledger_step_preserves (l : Ledger) (e : LedgerEvent) (h : LedgerInv l) :
    LedgerInv (ledgerStep l e) := by
  cases e with
  | nextCohort => exact h
  | receive k =>
    by_cases present : k ∈ l.received
    · simpa [ledgerStep, present] using h
    · intro x
      have hx := h x
      have hk := h k
      by_cases same : x = k
      · subst x; simp_all [ledgerStep]
      · simpa [ledgerStep, present, same] using hx
  | lastRead k =>
    by_cases owned : k ∈ l.owned
    · intro x
      have hx := h x
      by_cases same : x = k
      · subst x; simp_all [ledgerStep]
      · simpa [ledgerStep, owned, same] using hx
    · simpa [ledgerStep, owned] using h

def ledgerRun (l : Ledger) : List LedgerEvent → Ledger
  | [] => l
  | e :: es => ledgerRun (ledgerStep l e) es

theorem ledger_trace_preserves (l : Ledger) (es : List LedgerEvent) (h : LedgerInv l) :
    LedgerInv (ledgerRun l es) := by
  induction es generalizing l with
  | nil => exact h
  | cons e es ih => exact ih _ (ledger_step_preserves l e h)

theorem next_cohort_keeps_recipient (l : Ledger) :
    ledgerStep l .nextCohort = l := rfl

theorem recipient_completion_is_reachable :
    (ledgerRun {} [.receive first, .nextCohort, .lastRead first]).owned = [] ∧
    (ledgerRun {} [.receive first, .nextCohort, .lastRead first]).completed = [first] := by
  decide

theorem forgetting_recipient_is_rejected : ¬ LedgerInv ⟨[first], [], []⟩ := by
  intro h
  have bad := (h first).1
  simp at bad

#print axioms trace_preserves
#print axioms all_receipts_join_once
#print axioms busy_preserves_joined_state
#print axioms joined_retry_does_not_join_twice
#print axioms stale_join_is_ignored
#print axioms failure_cannot_be_reset
#print axioms unfinished_cannot_start_next
#print axioms failed_trace_retains
#print axioms repeated_completion_is_reachable
#print axioms old_generation_is_not_current
#print axioms other_vm_is_not_current
#print axioms changed_source_is_not_current
#print axioms changed_configuration_is_not_current

#print axioms ledger_trace_preserves
#print axioms next_cohort_keeps_recipient
#print axioms recipient_completion_is_reachable
#print axioms forgetting_recipient_is_rejected


-- Per-worker recovery refinement. A model event is conditional source input,
-- never an assertion that a host join error occurred in a native execution.
structure RecoveryKey where
  source : Nat
  configuration : Nat
  vm : Nat
  worker : Nat
  generation : Nat
  owner : Nat
  deriving DecidableEq, BEq

inductive RecoveryOp where
  | close | bodyEnd | handlerReturn | lastRead | joinError | joinOk
  | quiet | transfer | clearPending | reclaim | terminalError
  deriving DecidableEq

structure RecoveryEvent where
  key : RecoveryKey
  op : RecoveryOp
  errno : Nat := 0

structure RecoveryState where
  key : RecoveryKey
  phase : Nat := 0
  errorKey : Option RecoveryKey := none
  joinKey : Option RecoveryKey := none
  errno : Nat := 0
  consumers : List Nat := [1, 2]
  bodyDone : Bool := false
  returned : Bool := false
  privateDone : Bool := false
  quietObserved : Bool := false
  transferred : Bool := false
  pending : Bool := true
  reclaimed : Bool := false

def RecoveryReady (s : RecoveryState) : Prop :=
  s.phase = 5 ∧ s.errorKey = some s.key ∧ s.joinKey = some s.key ∧
  0 < s.errno ∧ s.errno ≠ 22 ∧ s.consumers = [] ∧ s.returned = true ∧
  s.privateDone = true ∧ s.quietObserved = true ∧ s.transferred = true ∧ s.pending = false
instance (s : RecoveryState) : Decidable (RecoveryReady s) := inferInstanceAs (Decidable (_ ∧ _))

def recoveryStep (s : RecoveryState) (e : RecoveryEvent) : RecoveryState :=
  if e.key ≠ s.key ∨ s.reclaimed = true ∨ s.phase = 7 then s else
  match e.op with
  | .close => if s.phase = 0 then { s with phase := 1 } else s
  | .bodyEnd => { s with bodyDone := true }
  | .handlerReturn => if s.bodyDone = true then
      { s with consumers := s.consumers.filter (· != 1), returned := true } else s
  | .lastRead => { s with consumers := s.consumers.filter (· != 2), privateDone := true }
  | .joinError => if s.phase = 1 ∧ 0 < e.errno ∧ e.errno ≠ 22 then
      { s with errorKey := some e.key, errno := e.errno } else s
  | .joinOk => if s.phase = 1 ∧ s.errorKey = some e.key ∧ 0 < s.errno then
      { s with joinKey := some e.key, phase := 2 } else s
  | .quiet => if s.phase = 2 ∧ s.consumers = [] then
      { s with quietObserved := true, phase := 3 } else s
  | .transfer => if s.phase = 3 then { s with transferred := true, phase := 4 } else s
  | .clearPending => if s.phase = 4 then { s with pending := false, phase := 5 } else s
  | .reclaim => if RecoveryReady s then { s with reclaimed := true, phase := 6 } else s
  | .terminalError => if s.phase = 1 then { s with phase := 7 } else s

def RecoveryInv (s : RecoveryState) : Prop := s.reclaimed = true →
  s.errorKey = some s.key ∧ s.joinKey = some s.key ∧ 0 < s.errno ∧ s.errno ≠ 22 ∧
  s.consumers = [] ∧ s.returned = true ∧ s.privateDone = true ∧
  s.quietObserved = true ∧ s.transferred = true ∧ s.pending = false ∧ s.phase = 6

theorem recovery_initial (k : RecoveryKey) : RecoveryInv { key := k } := by
  simp [RecoveryInv]

theorem recovery_step_preserves (s : RecoveryState) (e : RecoveryEvent) (h : RecoveryInv s) :
    RecoveryInv (recoveryStep s e) := by
  unfold recoveryStep
  split
  · exact h
  · rename_i permitted
    have hr : s.reclaimed = false := by
      cases flag : s.reclaimed with
      | false => rfl
      | true => exact False.elim (permitted (Or.inr (Or.inl flag)))
    cases e.op <;> dsimp only
    case reclaim =>
      split
      · rename_i ready
        intro _
        rcases ready with ⟨_, he, hj, hp, hn, hc, hrtn, hprivate, hquiet, htransfer, hpending⟩
        exact ⟨he, hj, hp, hn, hc, hrtn, hprivate, hquiet, htransfer, hpending, rfl⟩
      · exact h
    all_goals first
      | (split <;> exact fun hx => Bool.noConfusion (hr.symm.trans hx))
      | exact fun hx => Bool.noConfusion (hr.symm.trans hx)


def recoveryRun (s : RecoveryState) : List RecoveryEvent → RecoveryState
  | [] => s
  | e :: es => recoveryRun (recoveryStep s e) es

theorem recovery_trace_preserves (s : RecoveryState) (es : List RecoveryEvent) (h : RecoveryInv s) :
    RecoveryInv (recoveryRun s es) := by
  induction es generalizing s with
  | nil => exact h
  | cons e es ih => exact ih _ (recovery_step_preserves s e h)

theorem recovery_foreign_key_ignored (s : RecoveryState) (e : RecoveryEvent) (h : e.key ≠ s.key) :
    recoveryStep s e = s := by simp [recoveryStep, h]

theorem recovery_other_worker_ignored (s : RecoveryState) (e : RecoveryEvent)
    (h : e.key.worker ≠ s.key.worker) : recoveryStep s e = s :=
  recovery_foreign_key_ignored s e (fun same => h (congrArg RecoveryKey.worker same))
theorem recovery_old_generation_ignored (s : RecoveryState) (e : RecoveryEvent)
    (h : e.key.generation ≠ s.key.generation) : recoveryStep s e = s :=
  recovery_foreign_key_ignored s e (fun same => h (congrArg RecoveryKey.generation same))
theorem recovery_other_owner_ignored (s : RecoveryState) (e : RecoveryEvent)
    (h : e.key.owner ≠ s.key.owner) : recoveryStep s e = s :=
  recovery_foreign_key_ignored s e (fun same => h (congrArg RecoveryKey.owner same))

theorem body_end_keeps_consumers (s : RecoveryState) (k : RecoveryKey) :
    (recoveryStep s ⟨k, .bodyEnd, 0⟩).consumers = s.consumers := by
  simp [recoveryStep]; split <;> rfl

theorem unfinished_consumer_blocks_reclaim (s : RecoveryState) (k : RecoveryKey)
    (pending : s.consumers ≠ []) : recoveryStep s ⟨k, .reclaim, 0⟩ = s := by
  simp [recoveryStep, RecoveryReady, pending]

theorem clear_before_transfer_ignored (s : RecoveryState) (k : RecoveryKey)
    (phase : s.phase ≠ 4) : recoveryStep s ⟨k, .clearPending, 0⟩ = s := by
  simp [recoveryStep, phase]

theorem terminal_error_retains (s : RecoveryState) (es : List RecoveryEvent)
    (terminal : s.phase = 7) : recoveryRun s es = s := by
  induction es with
  | nil => rfl
  | cons e es ih => simpa [recoveryRun, recoveryStep, terminal] using ih

def recoveryFirst : RecoveryKey := ⟨1, 1, 1, 1, 1, 1⟩
def recoveryComplete : List RecoveryEvent :=
  [⟨recoveryFirst, .close, 0⟩, ⟨recoveryFirst, .joinError, 11⟩,
   ⟨recoveryFirst, .joinOk, 0⟩, ⟨recoveryFirst, .bodyEnd, 0⟩,
   ⟨recoveryFirst, .handlerReturn, 0⟩, ⟨recoveryFirst, .lastRead, 0⟩,
   ⟨recoveryFirst, .quiet, 0⟩, ⟨recoveryFirst, .transfer, 0⟩,
   ⟨recoveryFirst, .clearPending, 0⟩, ⟨recoveryFirst, .reclaim, 0⟩]
theorem same_identity_recovery_reachable :
    (recoveryRun { key := recoveryFirst } recoveryComplete).reclaimed = true := by decide

theorem body_only_cannot_reclaim :
    (recoveryRun { key := recoveryFirst }
      [⟨recoveryFirst, .close, 0⟩, ⟨recoveryFirst, .joinError, 11⟩,
       ⟨recoveryFirst, .joinOk, 0⟩, ⟨recoveryFirst, .bodyEnd, 0⟩,
       ⟨recoveryFirst, .quiet, 0⟩, ⟨recoveryFirst, .transfer, 0⟩,
       ⟨recoveryFirst, .clearPending, 0⟩, ⟨recoveryFirst, .reclaim, 0⟩]).reclaimed = false := by decide

-- Diagnostic and hypothesis units are orthogonal to native admission.
structure Capture where
  expectedImage : Nat
  loadedImage : Nat
  recordOwner : Nat
  copyOwner : Nat
  copyEpoch : Nat
  stopEpoch : Nat
  apiQualified : Bool
  readSucceeded : Bool
  stopped : Bool
  rawWord : Nat

def CaptureAccepted (c : Capture) : Prop := c.expectedImage = c.loadedImage ∧
  c.recordOwner = c.copyOwner ∧ c.copyEpoch = c.stopEpoch ∧
  c.apiQualified = true ∧ c.readSucceeded = true ∧ c.stopped = true

def BadDescriptorWitness (c : Capture) : Prop := CaptureAccepted c ∧ (c.rawWord = 0 ∨ c.rawWord = 8262)
theorem capture_does_not_prove_valid_descriptor :
    ∃ c, CaptureAccepted c ∧ BadDescriptorWitness c := by
  exact ⟨⟨1,1,1,1,1,1,true,true,true,0⟩, by simp [CaptureAccepted, BadDescriptorWitness]⟩
theorem gc_between_copy_and_stop_revokes (c : Capture) (h : c.copyEpoch ≠ c.stopEpoch) :
    ¬ CaptureAccepted c := fun accepted => h accepted.2.2.1
theorem failed_read_is_not_zero_witness (c : Capture) (h : c.readSucceeded = false) :
    ¬ BadDescriptorWitness c := by
  intro witness
  have success := witness.1.2.2.2.2.1
  simp_all

-- A header alone supplies no unique cause; arbitrary compatible sets are kept.
theorem header_can_leave_multiple_causes : ∃ causes : List Nat,
    causes = [1,2,3,4] ∧ causes.length > 1 := by exact ⟨[1,2,3,4], rfl, by decide⟩

structure PassObservation where
  compiler : Nat
  dumpCompiler : Nat
  source : Nat
  dumpSource : Nat
  exit : Nat
  optionWarnings : Bool
  functionCount : Nat
  requested : String
  artifacts : List String
  timeout : Bool

def PassExercised (p : PassObservation) : Prop := p.exit = 0 ∧ p.optionWarnings = false ∧
  0 < p.functionCount ∧ p.requested ∈ p.artifacts ∧ p.source = p.dumpSource ∧
  p.compiler = p.dumpCompiler ∧ p.timeout = false

theorem compile_zero_without_dump_is_not_phase (p : PassObservation)
    (missing : p.requested ∉ p.artifacts) : ¬ PassExercised p := by
  intro h; exact missing h.2.2.2.1
theorem no_function_is_not_alias_phase (p : PassObservation)
    (none : p.functionCount = 0) : ¬ PassExercised p := by
  intro h; have positive := h.2.2.1; omega

inductive CostUnit where | universeElement | mergedClass | projectedSlot | measuredWork
  deriving DecidableEq
structure Quantity where
  unit : CostUnit
  value : Nat
  deriving DecidableEq

theorem equal_numbers_do_not_identify_units :
    (Quantity.mk .mergedClass 2) ≠ (Quantity.mk .projectedSlot 2) := by decide

#print axioms recovery_step_preserves
#print axioms recovery_trace_preserves
#print axioms recovery_other_worker_ignored
#print axioms recovery_old_generation_ignored
#print axioms recovery_other_owner_ignored
#print axioms body_end_keeps_consumers
#print axioms unfinished_consumer_blocks_reclaim
#print axioms clear_before_transfer_ignored
#print axioms terminal_error_retains
#print axioms same_identity_recovery_reachable
#print axioms body_only_cannot_reclaim
#print axioms capture_does_not_prove_valid_descriptor
#print axioms gc_between_copy_and_stop_revokes
#print axioms failed_read_is_not_zero_witness
#print axioms header_can_leave_multiple_causes
#print axioms compile_zero_without_dump_is_not_phase
#print axioms no_function_is_not_alias_phase
#print axioms equal_numbers_do_not_identify_units

end GambitSMP.RetirementRepairCampaign
