from pathlib import Path
p=Path('models/build/IncrementalBuild.lean');s=p.read_text();assert s.endswith('end GambitBuild\n')
extra='''-- Stable-view lifecycle ledger: a contract model, not a runtime implementation.
inductive ViewPhase where
  | acquiring | borrowed | releasing | suspended | owned
  deriving DecidableEq

structure ViewLedger where
  generation : Nat
  entry : Nat
  acquisition : Nat
  writerEpoch : Nat
  contentEpoch : Nat
  phase : ViewPhase
  pins : Nat
  writers : Nat
  allWriters : Bool
  roots : Bool
  gateClosed : Bool
  cleanupPending : Bool
  resultComplete : Bool
  deriving DecidableEq

structure ViewToken where
  generation : Nat
  entry : Nat
  acquisition : Nat
  writerEpoch : Nat
  contentEpoch : Nat
  deriving DecidableEq

def viewToken (s : ViewLedger) : ViewToken :=
  ⟨s.generation,s.entry,s.acquisition,s.writerEpoch,s.contentEpoch⟩

def TokenMatches (s : ViewLedger) (t : ViewToken) : Prop :=
  t.generation = s.generation ∧ t.entry = s.entry ∧
  t.acquisition = s.acquisition ∧ t.writerEpoch = s.writerEpoch ∧ t.contentEpoch = s.contentEpoch

def IssuableView (s : ViewLedger) : Prop :=
  s.phase = .acquiring ∧ s.allWriters = true ∧ s.roots = true ∧
  s.gateClosed = true ∧ s.writers = 0 ∧ s.cleanupPending = false

def ReadableView (s : ViewLedger) (t : ViewToken) : Prop :=
  TokenMatches s t ∧ s.phase = .borrowed ∧ s.pins > 0 ∧
  s.allWriters = true ∧ s.roots = true ∧ s.gateClosed = true ∧
  s.writers = 0 ∧ s.cleanupPending = false

def activateView (s : ViewLedger) : ViewLedger := { s with phase := .borrowed, pins := 1 }
def revokeView (s : ViewLedger) : ViewLedger :=
  { s with generation := s.generation + 1, phase := .releasing, cleanupPending := true }
def returnViewPin (s : ViewLedger) : ViewLedger := { s with pins := s.pins - 1 }
-- Entry is an issuer-owned mutable ledger identity, never restored from continuation payload.
-- This candidate transition requires an independently settled old acquisition.
def enterViewAgain (s : ViewLedger) : ViewLedger :=
  { s with generation := s.generation + 1, entry := s.entry + 1,
    acquisition := s.acquisition + 1, phase := .acquiring, pins := 0, roots := false }
def unknownViewWriter (s : ViewLedger) : ViewLedger :=
  { (revokeView s) with writerEpoch := s.writerEpoch + 1, allWriters := false }
def WriterCanCommit (s : ViewLedger) : Prop := s.pins = 0 ∧ s.phase ≠ .borrowed
-- ack represents independently established physical completion, not a call to close/free.
def ackViewCleanup (s : ViewLedger) (owner : Nat) (ack : Bool) : ViewLedger :=
  if owner = s.acquisition ∧ ack = true then { s with cleanupPending := false } else s

def ViewDeliverable (s : ViewLedger) : Prop :=
  s.phase = .owned ∧ s.resultComplete = true ∧ s.cleanupPending = false ∧ s.pins = 0

theorem issuedReceiptReadable {s : ViewLedger} (ok : IssuableView s) :
    ReadableView (activateView s) (viewToken s) := by
  rcases ok with ⟨phase,allW,roots,gate,writers,debt⟩
  simp [ReadableView,TokenMatches,activateView,viewToken,allW,roots,gate,writers,debt]

theorem revokeRejectsOldReceipt {s : ViewLedger} {t : ViewToken}
    (old : TokenMatches s t) : ¬ TokenMatches (revokeView s) t := by
  intro changed
  have a := old.1
  have b := changed.1
  simp [revokeView] at b
  omega

theorem revokePreservesCustody (s : ViewLedger) :
    (revokeView s).pins = s.pins ∧ (revokeView s).roots = s.roots ∧
    (revokeView s).acquisition = s.acquisition := by simp [revokeView]

theorem livePinBlocksWriter {s : ViewLedger} (live : s.pins > 0) : ¬ WriterCanCommit s := by
  intro commit
  have zero := commit.1
  omega

theorem returnPinKeepsCleanupDebt (s : ViewLedger) :
    (returnViewPin s).cleanupPending = s.cleanupPending := rfl

theorem freshEntryRejectsOldReceipt {s : ViewLedger} {t : ViewToken}
    (old : TokenMatches s t) : ¬ TokenMatches (enterViewAgain s) t := by
  intro changed
  have a := old.1
  have b := changed.1
  simp [enterViewAgain] at b
  omega

theorem unknownWriterRejectsRead (s : ViewLedger) (t : ViewToken) :
    ¬ ReadableView (unknownViewWriter s) t := by
  simp [ReadableView,unknownViewWriter,revokeView]

theorem cleanupDebtBlocksDelivery {s : ViewLedger} (debt : s.cleanupPending = true) :
    ¬ ViewDeliverable s := by simp [ViewDeliverable,debt]

theorem staleCleanupCannotClear (s : ViewLedger) {owner : Nat}
    (stale : owner ≠ s.acquisition) (ack : Bool) : ackViewCleanup s owner ack = s := by
  simp [ackViewCleanup,stale]

theorem cleanupAckIdempotent (s : ViewLedger) (owner : Nat) (ack : Bool) :
    ackViewCleanup (ackViewCleanup s owner ack) owner ack = ackViewCleanup s owner ack := by
  by_cases accepted : owner = s.acquisition ∧ ack = true
  · simp [ackViewCleanup,accepted,accepted.1,accepted.2]
  · simp [ackViewCleanup,accepted]

theorem sameExtentMutationRejects {s : ViewLedger} {t : ViewToken}
    (old : TokenMatches s t) :
    ¬ TokenMatches { s with contentEpoch := s.contentEpoch + 1 } t := by
  intro changed
  have a := old.2.2.2.2
  have b := changed.2.2.2.2
  simp at b
  omega

theorem freshEntryHasDistinctToken (s : ViewLedger) : viewToken (enterViewAgain s) ≠ viewToken s := by
  intro equal
  have same := congrArg ViewToken.generation equal
  simp [viewToken,enterViewAgain] at same

theorem positiveDevelopmentWork {required duplicated validation added : Nat}
    (net : validation + added < duplicated) :
    required + validation + added < required + duplicated := by omega

theorem coordinatorWithoutRemovedWork {required added : Nat} (positive : added > 0) :
    required < required + added := by omega

'''
p.write_text(s[:-len('end GambitBuild\n')]+extra+'end GambitBuild\n')
p=Path('models/build/incremental_build.qnt');s=p.read_text();s+='''
// Protocol projection only. Actual writer/GC/winding/I/O refinement is not established.
module script_view_lifecycle {
  type State = { phase: int, generation: int, entry: int, acquisition: int,
    writerEpoch: int, contentEpoch: int, tokenGeneration: int, tokenEntry: int,
    tokenWriter: int, tokenContent: int, pins: int, debt: bool,
    roots: bool, allWriters: bool, gateClosed: bool }
  var s: State
  pure def readable(v: State): bool = all { v.phase == 1, v.pins > 0,
    v.generation == v.tokenGeneration, v.entry == v.tokenEntry,
    v.writerEpoch == v.tokenWriter, v.contentEpoch == v.tokenContent,
    v.roots, v.allWriters, v.gateClosed, not(v.debt) }
  action init = s' = { phase: 0, generation: 0, entry: 0, acquisition: 0,
    writerEpoch: 0, contentEpoch: 0, tokenGeneration: -1, tokenEntry: -1,
    tokenWriter: -1, tokenContent: -1, pins: 0, debt: false,
    roots: true, allWriters: true, gateClosed: true }
  action issue = all { s.phase == 0, s.roots, s.allWriters, s.gateClosed, not(s.debt), s.pins == 0,
    s' = { ...s, phase: 1, pins: 1, tokenGeneration: s.generation, tokenEntry: s.entry,
      tokenWriter: s.writerEpoch, tokenContent: s.contentEpoch } }
  action revoke = all { s.phase == 1,
    s' = { ...s, generation: s.generation + 1, phase: 2, debt: true } }
  action returnPin = all { s.phase == 2, s.pins > 0, s' = { ...s, pins: s.pins - 1 } }
  action cleanupAck = all { s.phase == 2, s.pins == 0, s.debt,
    s' = { ...s, debt: false, roots: false, phase: 3 } }
  action resume = all { s.phase == 3, s.pins == 0, not(s.debt),
    s' = { ...s, phase: 0, generation: s.generation + 1, entry: s.entry + 1,
      acquisition: s.acquisition + 1 } }
  action rootGrant = all { s.phase == 0, not(s.roots), s' = { ...s, roots: true } }
  action unknownWriter = all { s.phase != 2,
    s' = { ...s, generation: s.generation + 1, writerEpoch: s.writerEpoch + 1,
      phase: 2, debt: true, allWriters: false } }
  action payloadWrite = all { s.phase != 1, s.pins == 0,
    s' = { ...s, contentEpoch: s.contentEpoch + 1 } }
  action stutter = s' = s
  action step = any { issue, revoke, returnPin, cleanupAck, resume, rootGrant, unknownWriter, payloadWrite, stutter }
  val liveBorrowSafe = (s.phase == 1) implies readable(s)
  val noReleasedRootWithPins = (s.pins > 0) implies s.roots
}

module darwin_development_work {
  type Budget = { required: int, duplicated: int, validation: int, added: int, serialPrefix: int }
  pure def wellFormed(b: Budget): bool = all { b.required >= 0, b.duplicated >= 0,
    b.validation >= 0, b.added >= 0, b.serialPrefix >= 0 }
  pure def oldWork(b: Budget): int = b.required + b.duplicated
  pure def newWork(b: Budget): int = b.required + b.validation + b.added
  pure def positiveWork(b: Budget): bool = wellFormed(b) and b.validation + b.added < b.duplicated
  pure def parallelLatencyLowerBound(b: Budget): int = b.serialPrefix
}
''';p.write_text(s);print('Added 14 Lean statements and two QNT modules')
