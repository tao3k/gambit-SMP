import Std

namespace GambitBuild

/- Pure contract theory. There is no filesystem, compiler, cryptographic hash,
   native scheduler or QNT refinement theorem in this file. -/

inductive Affected {Node : Type} (dep : Node → Node → Prop)
    (changed : Node → Prop) : Node → Prop where
  | source {n} : changed n → Affected dep changed n
  | consumer {d n} : Affected dep changed d → dep d n → Affected dep changed n

theorem unaffectedDependency {Node : Type} {dep : Node → Node → Prop}
    {changed : Node → Prop} {d n : Node}
    (outside : ¬ Affected dep changed n) (edge : dep d n) :
    ¬ Affected dep changed d := by
  intro hd
  exact outside (.consumer hd edge)

theorem emptyChangeHasNoAffected {Node : Type} {dep : Node → Node → Prop}
    {n : Node} : ¬ Affected dep (fun _ => False) n := by
  intro h
  induction h with
  | source h => exact h
  | consumer _ _ ih => exact ih

-- A producer consumes a declared input cut. Extensionality of that cut is a
-- source obligation; collision-free hashing is deliberately not assumed.
def CutAgreement {Input Value : Type} (cut : Input → Prop)
    (a b : Input → Value) : Prop := ∀ i, cut i → a i = b i

def CutComplete {Input Value Output : Type} (cut : Input → Prop)
    (produce : (Input → Value) → Output) : Prop :=
  ∀ a b, CutAgreement cut a b → produce a = produce b

theorem reuseMatchesClean {Input Value Output : Type}
    {cut : Input → Prop} {produce : (Input → Value) → Output}
    {previous current : Input → Value} {cached : Output}
    (complete : CutComplete cut produce)
    (origin : cached = produce previous)
    (agreement : CutAgreement cut previous current) : cached = produce current := by
  exact origin.trans (complete previous current agreement)

-- Cutoff must preserve every projection consumed by a particular successor.
theorem projectionCutoff {Output View Result : Type}
    (observe : Output → View) (consume : View → Result)
    {old fresh : Output} (same : observe old = observe fresh) :
    consume (observe old) = consume (observe fresh) := by
  exact congrArg consume same

def runWork (keyMatches : Bool) : Nat := if keyMatches then 0 else 1

theorem validNoOpWork (keys : List Bool) (allMatch : ∀ b ∈ keys, b = true) :
    (keys.map runWork).sum = 0 := by
  induction keys with
  | nil => rfl
  | cons b bs ih =>
    have hb : b = true := allMatch b (by simp)
    have hs : ∀ x ∈ bs, x = true := by
      intro x hx
      exact allMatch x (by simp [hx])
    simp [hb, runWork, ih hs]

structure Budget where
  used : Nat
  limit : Nat

inductive BudgetStep : Budget → Budget → Prop where
  | start (used limit weight : Nat) (admitted : used + weight ≤ limit) :
      BudgetStep ⟨used, limit⟩ ⟨used + weight, limit⟩
  | finish (used limit weight : Nat) (owned : weight ≤ used) :
      BudgetStep ⟨used, limit⟩ ⟨used - weight, limit⟩

theorem budgetStepPreserves {a b : Budget} (safe : a.used ≤ a.limit)
    (step : BudgetStep a b) : b.used ≤ b.limit := by
  cases step with
  | start _ _ _ admitted => exact admitted
  | finish _ _ _ _ => exact Nat.le_trans (Nat.sub_le _ _) safe

inductive BudgetTrace : Budget → Budget → Prop where
  | refl (a) : BudgetTrace a a
  | step {a b c} : BudgetTrace a b → BudgetStep b c → BudgetTrace a c

theorem budgetTracePreserves {a b : Budget} (safe : a.used ≤ a.limit)
    (trace : BudgetTrace a b) : b.used ≤ b.limit := by
  induction trace with
  | refl => exact safe
  | step _ step ih => exact budgetStepPreserves ih step

-- Credits are held by running jobs, not by finished staged or published jobs.
-- This algebra does not prove parent/child progress or actual RSS bounds.
theorem returnedCreditCannotIncrease (used credit : Nat) : used - credit ≤ used :=
  Nat.sub_le _ _

-- Increasing a conservative cut preserves extensional completeness. Finding
-- a finite fixed point is separate from proving this semantic premise.
theorem agreementOnSmallerCut {Input Value : Type} {small large : Input → Prop}
    {a b : Input → Value} (included : ∀ i, small i → large i)
    (agreement : CutAgreement large a b) : CutAgreement small a b := by
  intro i hi
  exact agreement i (included i hi)

theorem completeCutCanGrow {Input Value Output : Type}
    {small large : Input → Prop} {produce : (Input → Value) → Output}
    (included : ∀ i, small i → large i) (complete : CutComplete small produce) :
    CutComplete large produce := by
  intro a b agreement
  exact complete a b (agreementOnSmallerCut included agreement)

-- An extension cannot remove an already required downstream invalidation.
theorem affectedEdgeExtension {Node : Type} {before after : Node → Node → Prop}
    {changed : Node → Prop} {n : Node}
    (included : ∀ a b, before a b → after a b)
    (affected : Affected before changed n) : Affected after changed n := by
  induction affected with
  | source h => exact .source h
  | consumer _ edge ih => exact .consumer ih (included _ _ edge)

def ObservationAgreement {Input Value : Type} (image : Input → Value)
    (trace : List (Input × Value)) : Prop := ∀ p ∈ trace, p.2 = image p.1

theorem immutableReadExtendsTrace {Input Value : Type} {image : Input → Value}
    {trace : List (Input × Value)} (sound : ObservationAgreement image trace)
    (i : Input) : ObservationAgreement image ((i, image i) :: trace) := by
  intro p hp
  rcases List.mem_cons.mp hp with hp | hp
  · subst p; rfl
  · exact sound p hp

-- A linearized epoch check is useful only if its issuer proves the following
-- agreement. End-of-run equal hashes do not construct this premise.
theorem receiptReuseMatchesClean {Input Value Output : Type}
    {cut : Input → Prop} {produce : (Input → Value) → Output}
    {previous image current : Input → Value} {cached : Output}
    (complete : CutComplete cut produce) (origin : cached = produce previous)
    (traceValid : CutAgreement cut previous image)
    (receipt : CutAgreement cut image current) : cached = produce current := by
  apply reuseMatchesClean complete origin
  intro i hi
  exact (traceValid i hi).trans (receipt i hi)

-- A family of observations, not one arbitrarily chosen metadata projection.
theorem allConsumerCutoff {Consumer Output View : Type}
    (observe : Consumer → Output → View) {old fresh : Output}
    (same : ∀ c, observe c old = observe c fresh)
    (c : Consumer) (consume : View → View) :
    consume (observe c old) = consume (observe c fresh) := by
  exact congrArg consume (same c)

-- Conditional forward simulation preserves a safety invariant. This reusable
-- lemma supplies NO relation between actual GSC processes and either QNT model.
theorem projectedStepPreserves {Concrete Abstract : Type}
    (project : Concrete → Abstract) (step : Concrete → Concrete → Prop)
    (abstractStep : Abstract → Abstract → Prop) (safe : Abstract → Prop)
    (simulate : ∀ a b, step a b →
      abstractStep (project a) (project b) ∨ project a = project b)
    (preserve : ∀ a b, safe a → abstractStep a b → safe b)
    {a b : Concrete} (ha : safe (project a)) (hab : step a b) :
    safe (project b) := by
  rcases simulate a b hab with move | idle
  · exact preserve _ _ ha move
  · rw [← idle]; exact ha

-- A closed, deterministic adaptive reader. Real Scheme macro evaluation has
-- NOT been translated into this datatype. Ask includes every mediated effect
-- that can influence the result, not just successful file reads.
inductive ReadProgram (Input Value Output : Type) where
  | done : Output → ReadProgram Input Value Output
  | ask : Input → (Value → ReadProgram Input Value Output) →
      ReadProgram Input Value Output

inductive ReadRun {Input Value Output : Type} (image : Input → Value) :
    ReadProgram Input Value Output → List Input → Output → Prop where
  | done (o) : ReadRun image (.done o) [] o
  | ask (i next rest o) : ReadRun image (next (image i)) rest o →
      ReadRun image (.ask i next) (i :: rest) o

-- Agreement on the OLD successful trace preserves the adaptive requests too.
-- This avoids assuming a static set of future reads is known in advance.
theorem adaptiveTraceReplay {Input Value Output : Type}
    {old fresh : Input → Value} {program : ReadProgram Input Value Output}
    {trace : List Input} {o : Output} (run : ReadRun old program trace o)
    (agreement : ∀ i ∈ trace, old i = fresh i) :
    ReadRun fresh program trace o := by
  induction run with
  | done o => exact .done o
  | ask i next rest o tail ih =>
    have first : old i = fresh i := agreement i (by simp)
    apply ReadRun.ask
    rw [← first]
    apply ih
    intro j hj
    exact agreement j (by simp [hj])

theorem adaptiveOutputUnique {Input Value Output : Type} {image : Input → Value}
    {program : ReadProgram Input Value Output} {trace other : List Input}
    {a b : Output} (left : ReadRun image program trace a)
    (right : ReadRun image program other b) : a = b := by
  induction left generalizing other b with
  | done o => cases right; rfl
  | ask i next rest o tail ih =>
    cases right with
    | ask _ _ _ _ run => exact ih run

theorem receiptBackedAdaptiveReuse {Input Value Output : Type}
    {old image current : Input → Value}
    {program : ReadProgram Input Value Output} {trace : List Input}
    {cached : Output} (origin : ReadRun old program trace cached)
    (traceValidated : ∀ i ∈ trace, old i = image i)
    (atCommit : ∀ i ∈ trace, image i = current i) :
    ReadRun current program trace cached := by
  apply adaptiveTraceReplay origin
  intro i hi
  exact (traceValidated i hi).trans (atCommit i hi)

-- Structural slice correspondence. Lists preserve the native template order;
-- this supplies graph facts only, not the integer calculate oracle's adequacy.
def selectedIndex (k : Nat) : Nat :=
  match k with
  | 0 => 31 | 1 => 1 | 2 => 65 | 3 => 35 | 4 => 68
  | 5 => 69 | 6 => 70 | 7 => 71 | 8 => 72 | _ => 73

def smallPredecessors (k : Nat) : List Nat :=
  match k with
  | 0 => [] | 1 => [] | 2 => [0] | 3 => [1] | 4 => [0,1]
  | 5 => [4] | 6 => [2,3,5] | 7 => [4] | 8 => [7] | _ => [6,8]

def fullPredecessors (n : Nat) : List Nat :=
  if n < 34 then [] else if n < 68 then [n-34]
  else if n = 68 then List.range 33 else if n = 69 then [68]
  else if n = 70 then (List.range 33).map (· + 34) ++ [69]
  else if n = 71 then [33,68] else if n = 72 then [71] else [67,70,72]

theorem selectedIndexInjective : ∀ a b : Fin 10,
    selectedIndex a.val = selectedIndex b.val → a = b := by decide

theorem selectedEdgesExact : ∀ a b : Fin 10,
    selectedIndex a.val ∈ fullPredecessors (selectedIndex b.val) ↔
    a.val ∈ smallPredecessors b.val := by decide

def PhaseRelated (full : Nat → Nat) (small : Fin 10 → Nat) : Prop :=
  ∀ k, small k = full (selectedIndex k.val)
def FullReady (full : Nat → Nat) (k : Fin 10) : Prop :=
  ∀ d ∈ fullPredecessors (selectedIndex k.val), full d = 2
def SmallReady (small : Fin 10 → Nat) (k : Fin 10) : Prop :=
  ∀ d : Fin 10, d.val ∈ smallPredecessors k.val → small d = 2
def BoundaryReady (full : Nat → Nat) (k : Fin 10) : Prop :=
  ∀ d ∈ fullPredecessors (selectedIndex k.val),
    (¬ ∃ j : Fin 10, selectedIndex j.val = d) → full d = 2

theorem fullReadyProjects {full : Nat → Nat} {small : Fin 10 → Nat}
    {k : Fin 10} (related : PhaseRelated full small) (ready : FullReady full k) :
    SmallReady small k := by
  intro d edge
  rw [related d]
  exact ready _ ((selectedEdgesExact d k).mpr edge)

theorem selectedAndBoundaryReady {full : Nat → Nat} {small : Fin 10 → Nat}
    {k : Fin 10} (related : PhaseRelated full small) (localReady : SmallReady small k)
    (boundary : BoundaryReady full k) : FullReady full k := by
  classical
  intro d edge
  by_cases h : ∃ j : Fin 10, selectedIndex j.val = d
  · obtain ⟨j,hj⟩ := h
    subst d
    rw [← related j]
    exact localReady j ((selectedEdgesExact j k).mp edge)
  · exact boundary d edge h

theorem fullBudgetBoundsSelected {full selected omitted limit : Nat}
    (decomposition : full = selected + omitted) (admitted : full ≤ limit) :
    selected ≤ limit := by omega

def FrozenBoundary {View : Type} (old fresh : Fin 10 → Nat → View) : Prop :=
  ∀ k d, d ∈ fullPredecessors (selectedIndex k.val) →
    (¬ ∃ j : Fin 10, selectedIndex j.val = d) → old k d = fresh k d

theorem changedBoundaryRejectsFrozen {View : Type}
    {old fresh : Fin 10 → Nat → View} {k : Fin 10} {d : Nat}
    (edge : d ∈ fullPredecessors (selectedIndex k.val))
    (outside : ¬ ∃ j : Fin 10, selectedIndex j.val = d)
    (changed : old k d ≠ fresh k d) : ¬ FrozenBoundary old fresh := by
  intro frozen
  exact changed (frozen k d edge outside)

-- A relational step-or-stutter premise, instead of assuming real output groups
-- have an already-known functional quotient into the ten-node integer oracle.
inductive FiniteSteps {State : Type} (step : State → State → Prop) :
    State → State → Prop where
  | refl (s) : FiniteSteps step s s
  | next {a b c} : FiniteSteps step a b → step b c → FiniteSteps step a c

theorem relationalTraceSafety {Concrete Abstract : Type}
    (concreteStep : Concrete → Concrete → Prop)
    (abstractStep : Abstract → Abstract → Prop)
    (related : Concrete → Abstract → Prop) (safe : Abstract → Prop)
    (simulation : ∀ c a c', related c a → concreteStep c c' →
      ∃ a', related c' a' ∧ (abstractStep a a' ∨ a = a'))
    (preserve : ∀ a a', safe a → abstractStep a a' → safe a')
    {c c' : Concrete} {a : Abstract} (initial : related c a) (initialSafe : safe a)
    (trace : FiniteSteps concreteStep c c') :
    ∃ a', related c' a' ∧ safe a' := by
  induction trace with
  | refl => exact ⟨a,initial,initialSafe⟩
  | next priorTrace hop ih =>
    obtain ⟨b,rb,sb⟩ := ih
    obtain ⟨b',rb',choice⟩ := simulation _ _ _ rb hop
    refine ⟨b',rb',?_⟩
    rcases choice with h | h
    · exact preserve _ _ sb h
    · rw [← h]; exact sb

-- Abstract safety transfers back to a concrete property only through a
-- separately proved reflection premise. Phase equality alone cannot supply it.
theorem concreteSafetyFromRefinement {Concrete Abstract : Type}
    (concreteStep : Concrete → Concrete → Prop)
    (abstractStep : Abstract → Abstract → Prop)
    (related : Concrete → Abstract → Prop) (safe : Abstract → Prop)
    (concreteSafe : Concrete → Prop)
    (simulation : ∀ c a c', related c a → concreteStep c c' →
      ∃ a', related c' a' ∧ (abstractStep a a' ∨ a = a'))
    (preserve : ∀ a a', safe a → abstractStep a a' → safe a')
    (reflection : ∀ c a, related c a → safe a → concreteSafe c)
    {c c' : Concrete} {a : Abstract} (initial : related c a) (initialSafe : safe a)
    (trace : FiniteSteps concreteStep c c') : concreteSafe c' := by
  obtain ⟨final,rf,sf⟩ := relationalTraceSafety concreteStep abstractStep related safe
    simulation preserve initial initialSafe trace
  exact reflection c' final rf sf

-- Coverage is required across caller and callback traces, under one admitted
-- capability interpretation. This does not discover the real executed trace.
def CapabilityCovered {Cap : Type} (allowed : Cap → Prop) (trace : List Cap) : Prop :=
  ∀ c ∈ trace, allowed c

theorem capabilityCoverageAppend {Cap : Type} {allowed : Cap → Prop}
    {caller callback : List Cap} :
    CapabilityCovered allowed (caller ++ callback) ↔
      CapabilityCovered allowed caller ∧ CapabilityCovered allowed callback := by
  simp [CapabilityCovered, List.mem_append, or_imp, forall_and]

theorem uncoveredCapabilityRejects {Cap : Type} {allowed : Cap → Prop}
    {trace : List Cap} {c : Cap} {issued : Prop}
    (mustCover : issued → CapabilityCovered allowed trace)
    (called : c ∈ trace) (unmanaged : ¬ allowed c) : ¬ issued := by
  intro receipt
  exact unmanaged (mustCover receipt c called)

-- Related concrete and abstract observations need a proved fidelity bridge.
-- Equality of scalar scenario flags alone does not construct this bridge.
theorem observationEqualityReflection {Concrete Abstract Observation : Type}
    (observe : Concrete → Observation) (token : Abstract → Observation)
    {actual clean : Concrete} {a b : Abstract}
    (actualRelated : observe actual = token a)
    (cleanRelated : observe clean = token b) (abstractSafe : token a = token b) :
    observe actual = observe clean := by
  exact actualRelated.trans (abstractSafe.trans cleanRelated.symm)

theorem factorizationSufficient {Output Observation Result : Type}
    (observe : Output → Observation) (consume : Output → Result)
    (kernel : Observation → Result)
    (factors : ∀ o, consume o = kernel (observe o))
    {old fresh : Output} (same : observe old = observe fresh) :
    consume old = consume fresh := by
  rw [factors old, factors fresh, same]

-- Concrete counterexample to length/sum-based equality. These are exact finite
-- list facts, not a native counterexample and not a claim about every int code.
theorem scalarSummariesLoseOrder :
    ([1,2] : List Nat).length = ([2,1] : List Nat).length ∧
    ([1,2] : List Nat).sum = ([2,1] : List Nat).sum ∧
    ([1,2] : List Nat) ≠ ([2,1] : List Nat) := by decide

-- Exact byte widening is injective; acquisition of the real file is external.
def byteEncoding (xs : List (Fin 256)) : List Int := xs.map (fun b => (b.val : Int))

theorem byteEncodingInjective {xs ys : List (Fin 256)}
    (same : byteEncoding xs = byteEncoding ys) : xs = ys := by
  have point : Function.Injective (fun b : Fin 256 => (b.val : Int)) := by
    intro a b h
    apply Fin.ext
    exact Int.ofNat.inj h
  exact (List.map_inj_right point).mp same

-- A proposed framed atom code: tag, payload length, exact payload units.
-- Text-to-unit fidelity and the recursive Scheme datum codec remain external.
def framedAtom (tag : Int) (payload : List Int) : List Int :=
  tag :: (payload.length : Int) :: payload

theorem framedAtomInjective {tag : Int} {a b : List Int}
    (same : framedAtom tag a = framedAtom tag b) : a = b := by
  exact (List.cons.inj (List.cons.inj same).2).2

theorem atomTagsSeparate {a b : List Int} {t u : Int} (different : t ≠ u) :
    framedAtom t a ≠ framedAtom u b := by
  intro same
  exact different (List.cons.inj same).1

-- A left inverse must be proved on an admitted domain, not all Scheme objects.
theorem admittedCodecInjective {Datum : Type} (admitted : Datum → Prop)
    (encode : Datum → List Int) (decode : List Int → Option Datum)
    (roundtrip : ∀ d, admitted d → decode (encode d) = some d)
    {a b : Datum} (ha : admitted a) (hb : admitted b)
    (same : encode a = encode b) : a = b := by
  have eqSome : some a = some b := by
    rw [← roundtrip a ha, ← roundtrip b hb, same]
  exact Option.some.inj eqSome

-- Clean execution, actual parser fidelity, consumer factoring, context identity
-- and effect equivalence must be supplied independently by concrete witnesses.
theorem cleanConsumerCutoff {Group Datum Observation Result : Type}
    (read : Group → Datum) (encode : Datum → Observation)
    (consumer : Group → Result) (kernel : Datum → Result)
    (admitted : Datum → Prop)
    (injectiveOn : ∀ a b, admitted a → admitted b → encode a = encode b → a = b)
    (factors : ∀ g, consumer g = kernel (read g))
    {old clean : Group} (oldOk : admitted (read old)) (cleanOk : admitted (read clean))
    (same : encode (read old) = encode (read clean)) : consumer old = consumer clean := by
  rw [factors old, factors clean, injectiveOn _ _ oldOk cleanOk same]

inductive AttemptOutcome where
  | success | missing | rejected | malformed | ioFailure | producerFailure
  | cancelled | unknown
  deriving DecidableEq

theorem nonSuccessCannotIssue {outcome : AttemptOutcome} {issued : Prop}
    (guard : issued → outcome = .success) (failed : outcome ≠ .success) : ¬ issued := by
  exact fun receipt => failed (guard receipt)

-- The real failure-to-abstract-bad map is a separate proof obligation.
theorem reflectedFailureExcluded {Concrete Abstract : Type}
    (related : Concrete → Abstract → Prop) (failed : Concrete → Prop)
    (bad : Abstract → Prop)
    (failureReflects : ∀ c a, related c a → failed c → bad a)
    {c : Concrete} {a : Abstract} (rel : related c a) (safe : ¬ bad a) : ¬ failed c := by
  exact fun failure => safe (failureReflects c a rel failure)

-- Mathematical framing model only: no Gambit reader, filesystem or native codec.
-- Scalar payload validity and Scheme object identity are separate admission duties.
inductive DatumAtomKind where
  | nil | boolean | integer | character | string | symbol | keyword
  deriving DecidableEq

def atomKindTag : DatumAtomKind → Int
  | .nil => 0 | .boolean => 1 | .integer => 2 | .character => 3
  | .string => 4 | .symbol => 5 | .keyword => 6

mutual
  inductive RecursiveDatum where
    | atom (kind : DatumAtomKind) (payload : List Int)
    | pair (car cdr : RecursiveDatum)
    | vector (elements : DatumSequence)
    deriving DecidableEq
  inductive DatumSequence where
    | nil
    | cons (head : RecursiveDatum) (tail : DatumSequence)
    deriving DecidableEq
end

def datumFrame (tag : Int) (body : List Int) : List Int :=
  tag :: (body.length : Int) :: body

def readDatumFrame : List Int → Option (Int × List Int × List Int)
  | tag :: length :: rest =>
      if 0 ≤ length ∧ length.toNat ≤ rest.length then
        some (tag, rest.take length.toNat, rest.drop length.toNat)
      else none
  | _ => none

theorem readDatumFrameAppend (tag : Int) (body tail : List Int) :
    readDatumFrame (datumFrame tag body ++ tail) = some (tag,body,tail) := by
  simp [readDatumFrame, datumFrame]

mutual
  def encodeRecursiveDatum : RecursiveDatum → List Int
    | .atom kind payload => datumFrame (atomKindTag kind) payload
    | .pair a d => datumFrame 7 (encodeRecursiveDatum a ++ encodeRecursiveDatum d)
    | .vector ds => datumFrame 8 (encodeDatumSequence ds)
  def encodeDatumSequence : DatumSequence → List Int
    | .nil => []
    | .cons d ds => encodeRecursiveDatum d ++ encodeDatumSequence ds
end

mutual
  def datumFuel : RecursiveDatum → Nat
    | .atom _ _ => 1
    | .pair a d => 1 + datumFuel a + datumFuel d
    | .vector ds => 1 + sequenceFuel ds
  def sequenceFuel : DatumSequence → Nat
    | .nil => 1
    | .cons d ds => 1 + datumFuel d + sequenceFuel ds
end

mutual
  def parseRecursiveDatum : Nat → List Int → Option (RecursiveDatum × List Int)
    | 0, _ => none
    | fuel+1, input => do
      let (tag, body, rest) ← readDatumFrame input
      match tag with
      | 0 => some (.atom .nil body, rest)
      | 1 => some (.atom .boolean body, rest)
      | 2 => some (.atom .integer body, rest)
      | 3 => some (.atom .character body, rest)
      | 4 => some (.atom .string body, rest)
      | 5 => some (.atom .symbol body, rest)
      | 6 => some (.atom .keyword body, rest)
      | 7 => do
          let (a, more) ← parseRecursiveDatum fuel body
          let (d, residue) ← parseRecursiveDatum fuel more
          if residue = [] then some (.pair a d, rest) else none
      | 8 => do
          let ds ← parseDatumSequence fuel body
          some (.vector ds, rest)
      | _ => none
  def parseDatumSequence : Nat → List Int → Option DatumSequence
    | 0, _ => none
    | _fuel+1, [] => some .nil
    | fuel+1, input@(_ :: _) => do
        let (d, rest) ← parseRecursiveDatum fuel input
        let ds ← parseDatumSequence fuel rest
        some (.cons d ds)
end

-- Enough fuel gives a suffix-preserving datum inverse and a whole-sequence inverse.
-- This theorem makes no assertion that actual GSC output belongs to this grammar.
theorem recursiveRoundtrip (fuel : Nat) :
    (∀ d tail, datumFuel d ≤ fuel →
      parseRecursiveDatum fuel (encodeRecursiveDatum d ++ tail) = some (d,tail)) ∧
    (∀ ds, sequenceFuel ds ≤ fuel →
      parseDatumSequence fuel (encodeDatumSequence ds) = some ds) := by
  induction fuel with
  | zero =>
      constructor
      · intro d tail h
        cases d <;> simp [datumFuel] at h
      · intro ds h
        cases ds <;> simp [sequenceFuel] at h
  | succ fuel ih =>
      constructor
      · intro d tail bound
        cases d with
        | atom kind payload =>
            cases kind <;>
              simp [encodeRecursiveDatum, atomKindTag, parseRecursiveDatum,
                readDatumFrameAppend]
        | pair a d =>
            have ha : datumFuel a ≤ fuel := by simp [datumFuel] at bound; omega
            have hd : datumFuel d ≤ fuel := by simp [datumFuel] at bound; omega
            simp only [encodeRecursiveDatum, parseRecursiveDatum, readDatumFrameAppend]
            have dRound : parseRecursiveDatum fuel (encodeRecursiveDatum d) = some (d,[]) := by
              simpa using ih.1 d [] hd
            simp [ih.1 a (encodeRecursiveDatum d) ha, dRound]
        | vector ds =>
            have hs : sequenceFuel ds ≤ fuel := by simp [datumFuel] at bound; omega
            simp [encodeRecursiveDatum, parseRecursiveDatum, readDatumFrameAppend, ih.2 ds hs]
      · intro ds bound
        cases ds with
        | nil => simp [encodeDatumSequence, parseDatumSequence]
        | cons d ds =>
            have hd : datumFuel d ≤ fuel := by simp [sequenceFuel] at bound; omega
            have hs : sequenceFuel ds ≤ fuel := by simp [sequenceFuel] at bound; omega
            have nonempty : encodeRecursiveDatum d ≠ [] := by
              cases d <;> simp [encodeRecursiveDatum, datumFrame]
            cases enc : encodeRecursiveDatum d with
            | nil => exact False.elim (nonempty enc)
            | cons x xs =>
                have head := ih.1 d (encodeDatumSequence ds) hd
                rw [enc] at head
                have headRound : parseRecursiveDatum fuel (x :: (xs ++ encodeDatumSequence ds)) =
                    some (d, encodeDatumSequence ds) := by
                  simpa only [List.cons_append] using head
                simp only [encodeDatumSequence, enc, List.cons_append, parseDatumSequence]
                rw [headRound]
                simp [ih.2 ds hs]

theorem recursiveEncodingInjective {a b : RecursiveDatum}
    (same : encodeRecursiveDatum a = encodeRecursiveDatum b) : a = b := by
  let fuel := max (datumFuel a) (datumFuel b)
  have ha := (recursiveRoundtrip fuel).1 a [] (Nat.le_max_left _ _)
  have hb := (recursiveRoundtrip fuel).1 b [] (Nat.le_max_right _ _)
  rw [same] at ha
  have pairEq : (b, ([] : List Int)) = (a, []) := Option.some.inj (hb.symm.trans ha)
  exact (Prod.mk.inj pairEq).1.symm

def decodeWholeDatum (fuel : Nat) (input : List Int) : Option RecursiveDatum := do
  let (d, rest) ← parseRecursiveDatum fuel input
  if rest = [] then some d else none

theorem decodeWholeEncoded (d : RecursiveDatum) :
    decodeWholeDatum (datumFuel d) (encodeRecursiveDatum d) = some d := by
  have round := (recursiveRoundtrip (datumFuel d)).1 d [] (Nat.le_refl _)
  simp at round
  simp [decodeWholeDatum, round]

theorem trailingTokensRejected {fuel : Nat} {input rest : List Int} {d : RecursiveDatum}
    (parsed : parseRecursiveDatum fuel input = some (d,rest)) (extra : rest ≠ []) :
    decodeWholeDatum fuel input = none := by
  simp [decodeWholeDatum, parsed, extra]

theorem shortFrameRejected {tag length : Int} {rest : List Int}
    (tooShort : rest.length < length.toNat) :
    readDatumFrame (tag :: length :: rest) = none := by
  simp [readDatumFrame, Nat.not_le.mpr tooShort]

theorem emptyDatumRejected (fuel : Nat) : parseRecursiveDatum fuel [] = none := by
  cases fuel <;> simp [parseRecursiveDatum, readDatumFrame]

theorem emptyPairFrameRejected (fuel : Nat) :
    decodeWholeDatum fuel (datumFrame 7 []) = none := by
  cases fuel <;>
    simp [decodeWholeDatum, parseRecursiveDatum, readDatumFrame, datumFrame,
      emptyDatumRejected]

end GambitBuild
