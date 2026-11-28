import Std

namespace Gambit.BootstrapCohort

-- Coverage-class membership is not a witness for every native filename.
-- These laws require a complete required-name predicate and universal coverage
-- within each class. They do not establish compiler semantics or C lifetimes.
def Complete (required emitted : Nat → Prop) : Prop :=
  ∀ n, required n → emitted n

def ClassComplete (required emitted : Nat → Prop) (kind : Nat → Nat)
    (k : Nat) : Prop :=
  ∀ n, required n → kind n = k → emitted n

theorem completeProjects (required emitted : Nat → Prop) (kind : Nat → Nat)
    (h : Complete required emitted) : ∀ k, ClassComplete required emitted kind k := by
  intro k n hr _
  exact h n hr

theorem universalClassesReflect (required emitted : Nat → Prop) (kind : Nat → Nat)
    (h : ∀ k, ClassComplete required emitted kind k) : Complete required emitted := by
  intro n hr
  exact h (kind n) n hr rfl

theorem twoClassesReflect (required emitted : Nat → Prop) (kind : Nat → Nat)
    (domain : ∀ n, required n → kind n = 0 ∨ kind n = 1)
    (scheme : ClassComplete required emitted kind 0)
    (linker : ClassComplete required emitted kind 1) : Complete required emitted := by
  intro n hr
  rcases domain n hr with hk | hk
  · exact scheme n hr hk
  · exact linker n hr hk

theorem emissionPreserves (required before after : Nat → Prop)
    (complete : Complete required before)
    (monotone : ∀ n, before n → after n) : Complete required after := by
  intro n hr
  exact monotone n (complete n hr)

-- One observed representative in each class cannot close native coverage.
theorem representativesInsufficient :
    (∃ n, n ≤ 2 ∧ n = 0) ∧ (∃ n, n ≤ 2 ∧ n = 1) ∧
    ¬ Complete (fun n => n ≤ 2) (fun n => n = 0 ∨ n = 1) := by
  refine ⟨⟨0, by decide, rfl⟩, ⟨1, by decide, rfl⟩, ?_⟩
  intro complete
  have missing := complete 2 (by decide)
  simp at missing

-- A target-source pass is a distinct event. Equality of a host output alone
-- supplies neither this event nor a semantic result.
theorem semanticRequiresSelf (target self semantic : Prop)
    (selfNeedsTarget : self → target) (semanticNeedsSelf : semantic → self)
    (h : semantic) : target ∧ self := by
  exact ⟨selfNeedsTarget (semanticNeedsSelf h), semanticNeedsSelf h⟩

-- Byte identities enter through native input and receipt verification.
-- The fixed key excludes only the selected host and private output coordinates.
structure HostControlKey where
  source : Nat
  moduleInput : Nat
  prelude : Nat
  command : Nat
  profile : Nat
  diagnosticBudget : Nat

structure HostLeg where
  key : HostControlKey
  runId : Nat
  declaredHost : Nat
  executedHost : Nat
  evidenceBound : Prop
  inputsStable : Prop
  formalPreludeApplied : Prop
  parseReturned : Prop
  naturalExit : Prop
  freshC : Prop
  c23 : Prop
  quiescent : Prop

def HostLegBound (current : HostControlKey) (selected : Nat) (leg : HostLeg) : Prop :=
  leg.key = current ∧ leg.declaredHost = selected ∧ leg.executedHost = selected ∧
    leg.evidenceBound ∧ leg.inputsStable ∧ leg.formalPreludeApplied ∧ leg.quiescent

def HostLegComplete (leg : HostLeg) : Prop :=
  leg.parseReturned ∧ leg.naturalExit ∧ leg.freshC ∧ leg.c23

def HostPair (current : HostControlKey) (selected independent : Nat)
    (candidate reference : HostLeg) : Prop :=
  selected ≠ independent ∧ candidate.runId ≠ reference.runId ∧
    HostLegBound current selected candidate ∧ HostLegBound current independent reference

def Family6BuildPrerequisite (current : HostControlKey) (selected independent : Nat)
    (candidate reference : HostLeg) : Prop :=
  HostPair current selected independent candidate reference ∧ HostLegComplete candidate

theorem hostPairFixedInputs (current : HostControlKey) (selected independent : Nat)
    (candidate reference : HostLeg) (pair : HostPair current selected independent candidate reference) :
    candidate.key = reference.key := by
  rcases pair with ⟨_, _, candidateBound, referenceBound⟩
  exact candidateBound.1.trans referenceBound.1.symm

theorem changedPreludeCannotMatch (current : HostControlKey) (selected independent : Nat)
    (candidate reference : HostLeg) (changed : candidate.key.prelude ≠ reference.key.prelude) :
    ¬ HostPair current selected independent candidate reference := by
  intro pair
  exact changed (congrArg HostControlKey.prelude
    (hostPairFixedInputs current selected independent candidate reference pair))

theorem buildNeedsSelectedOutput (current : HostControlKey) (selected independent : Nat)
    (candidate reference : HostLeg)
    (ready : Family6BuildPrerequisite current selected independent candidate reference) :
    candidate.freshC :=
  ready.2.2.2.1

theorem missingCandidateOutputBlocksBuild (current : HostControlKey) (selected independent : Nat)
    (candidate reference : HostLeg) (missing : ¬ candidate.freshC) :
    ¬ Family6BuildPrerequisite current selected independent candidate reference := by
  intro ready
  exact missing (buildNeedsSelectedOutput current selected independent candidate reference ready)

structure Gate2Emission where
  selectedEmitter : Nat
  actualEmitter : Nat
  makeInputs : Nat
  observedInputs : Nat
  cRun : Nat
  gvmRun : Nat
  retainedC : Nat
  emittedC : Nat
  completed : Prop
  reviewed : Prop
  linked : Prop
  historicalLineage : Prop

def Gate2Pair (e : Gate2Emission) : Prop :=
  e.completed ∧ e.selectedEmitter = e.actualEmitter ∧ e.makeInputs = e.observedInputs ∧
    e.cRun = e.gvmRun ∧ e.retainedC = e.emittedC

def Gate2SiteBound (e : Gate2Emission) : Prop :=
  Gate2Pair e ∧ e.reviewed ∧ e.linked ∧ e.historicalLineage

theorem gate2CannotSplice (e : Gate2Emission) (split : e.cRun ≠ e.gvmRun) :
    ¬ Gate2Pair e := fun h => split h.2.2.2.1

theorem gate2PairRejectsChangedC (e : Gate2Emission) (changed : e.retainedC ≠ e.emittedC) :
    ¬ Gate2Pair e := fun h => changed h.2.2.2.2

theorem gate2CannotTransferLineage (e : Gate2Emission) (missing : ¬ e.historicalLineage) :
    ¬ Gate2SiteBound e := fun h => missing h.2.2.2

theorem gate2RequiresSemanticReview (e : Gate2Emission) (bound : Gate2SiteBound e) :
    e.reviewed := bound.2.1

-- Representation safety for Gate 2 procedure-name capture under (declare (not safe)).
-- Applying unchecked ___SYMBOLNAME (body[0]) to an already-tagged string stores raw
-- UTF-32 code units (such as "##" = 0x0000002300000023, tag 3) into a global root.
inductive Gate2ValueKind where
  | falseVal
  | stringVal
  | symbolVal
  | rawUtf32Word
  deriving DecidableEq

def GcSafeGlobalRoot : Gate2ValueKind → Prop
  | .falseVal => True
  | .stringVal => True
  | .symbolVal => True
  | .rawUtf32Word => False

def uncheckedSymbolNameProjection : Gate2ValueKind → Gate2ValueKind
  | .symbolVal => .stringVal
  | _ => .rawUtf32Word

def checkedGate2ProcName : Gate2ValueKind → Gate2ValueKind
  | .stringVal => .stringVal
  | .symbolVal => .stringVal
  | _ => .falseVal

theorem uncheckedStringCorruptsGlobalRoot :
    ¬ GcSafeGlobalRoot (uncheckedSymbolNameProjection .stringVal) := by
  simp [uncheckedSymbolNameProjection, GcSafeGlobalRoot]

theorem checkedGate2ProcNameAlwaysGcSafe (k : Gate2ValueKind) :
    GcSafeGlobalRoot (checkedGate2ProcName k) := by
  cases k <;> simp [checkedGate2ProcName, GcSafeGlobalRoot]

theorem checkedGate2ProcNameStringOnStringOrSymbol (k : Gate2ValueKind)
    (h : k = .stringVal ∨ k = .symbolVal) :
    checkedGate2ProcName k = .stringVal := by
  rcases h with rfl | rfl <;> rfl

end Gambit.BootstrapCohort
