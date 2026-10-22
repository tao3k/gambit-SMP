from pathlib import Path
p=Path('models/build/IncrementalBuild.lean');s=p.read_text();assert s.endswith('end GambitBuild\n')
s=s[:-len('end GambitBuild\n')]+'''-- Exact byte widening is injective; acquisition of the real file is external.
def byteEncoding (xs : List (Fin 256)) : List Int := xs.map (fun b => (b.val : Int))

theorem byteEncodingInjective {xs ys : List (Fin 256)}
    (same : byteEncoding xs = byteEncoding ys) : xs = ys := by
  have point : Function.Injective (fun b : Fin 256 => (b.val : Int)) := by
    intro a b h
    apply Fin.ext
    exact Int.ofNat.inj h
  exact List.map_injective_iff.mpr point same

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

end GambitBuild
''';p.write_text(s)
p=Path('models/build/incremental_build.qnt');s=p.read_text();s+='''
// Refined linker-observation admission specification only. Integers are tags,
// not an implemented Scheme parser, producer oracle or native failure adapter.
module gsc_link_fidelity {
  val Success = 0
  val Missing = 1
  val Rejected = 2
  val Malformed = 3
  val IoFailure = 4
  val ProducerFailure = 5
  val Cancelled = 6
  val Unknown = 7
  type Evidence = { outcome: int, shallowHeader: bool, fullRecord: bool,
    codecFaithful: bool, groupComplete: bool, settled: bool, current: bool,
    effectsClosed: bool, originQualified: bool, context: List[int],
    datum: List[int], rawC: List[int] }
  pure def bytesWellFormed(xs: List[int]): bool =
    xs.indices().forall(i => xs.nth(i) >= 0 and xs.nth(i) < 256)
  pure def linkEligible(e: Evidence): bool = all { e.outcome == Success,
    e.shallowHeader, e.fullRecord, e.codecFaithful, e.groupComplete,
    e.settled, e.current, e.effectsClosed, e.originQualified }
  pure def linkCutoff(a: Evidence, b: Evidence): bool = all {
    linkEligible(a), linkEligible(b), a.context == b.context, a.datum == b.datum }
  pure def cCutoff(a: Evidence, b: Evidence): bool = all {
    linkEligible(a), linkEligible(b), a.context == b.context,
    bytesWellFormed(a.rawC), bytesWellFormed(b.rawC), a.rawC == b.rawC }
  pure def failureBlocks(e: Evidence): bool =
    (e.outcome != Success) implies not(linkEligible(e))
  pure def malformedBlocks(e: Evidence): bool =
    (not(e.fullRecord)) implies not(linkEligible(e))
}
''';p.write_text(s)
