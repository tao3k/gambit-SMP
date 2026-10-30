from pathlib import Path
p=Path('models/build/IncrementalBuild.lean');s=p.read_text();assert s.endswith('end GambitBuild\n')
new='''-- Source-aligned script-line selection and complete-observation specification.
-- No actual Scheme heap acquisition, textual reader or emitter is implemented.
inductive ScriptValue where
  | falseValue
  | text (units : List Int)
  | invalid (identity : Nat)
  deriving DecidableEq

def chooseScript (previous next : ScriptValue) : ScriptValue :=
  match next with | .falseValue => previous | _ => next

def foldScript (initial : ScriptValue) : List ScriptValue → ScriptValue
  | [] => initial
  | x :: xs => foldScript (chooseScript initial x) xs

-- Boolean match abstracts actual assq/eq? membership in the qualified universe.
def firstScript : List (Bool × ScriptValue) → ScriptValue
  | [] => .falseValue
  | (matches, value) :: rest => if matches then value else firstScript rest

theorem scriptFalseRetainsPrevious (previous : ScriptValue) :
    chooseScript previous .falseValue = previous := rfl

theorem scriptEmptyTextWins (previous : ScriptValue) :
    chooseScript previous (.text []) = .text [] := rfl

theorem scriptFoldAppend (a b : List ScriptValue) (initial : ScriptValue) :
    foldScript initial (a ++ b) = foldScript (foldScript initial a) b := by
  induction a generalizing initial with
  | nil => rfl
  | cons x xs ih => simpa [foldScript] using ih (chooseScript initial x)

theorem scriptTrailingFalseRetains (a : List ScriptValue) (initial : ScriptValue) :
    foldScript initial (a ++ [.falseValue]) = foldScript initial a := by
  rw [scriptFoldAppend]
  rfl

theorem scriptFirstMatchWins (a b : ScriptValue) :
    firstScript [(true,a),(true,b)] = a := rfl

theorem malformedLatestRemainsVisible :
    foldScript .falseValue [.text [35,33], .invalid 7] = .invalid 7 := rfl

theorem singletonScriptEncodingReflects {a b : List Int}
    (same : encodeRecursiveDatum (.atom .string a) = encodeRecursiveDatum (.atom .string b)) :
    a = b := by
  exact (RecursiveDatum.atom.inj (recursiveEncodingInjective same)).2

def replaceLogicalNode (heap : Nat → SchemeNodeView) (changed : Nat)
    (value : SchemeNodeView) : Nat → SchemeNodeView :=
  fun id => if id = changed then value else heap id

theorem untouchedPayloadPreservesView {reads : List Nat} {heap : Nat → SchemeNodeView}
    {changed : Nat} (unread : changed ∉ reads) (value : SchemeNodeView) :
    StableValueCut reads heap (replaceLogicalNode heap changed value) := by
  intro id used
  have different : id ≠ changed := by
    intro same
    exact unread (same ▸ used)
  simp [replaceLogicalNode, different]

inductive LinkDisposition where
  | success | compilerAbort | raised (condition : Nat) | refused | unsettled
  deriving DecidableEq

structure LinkTraceObservation where
  returnPath : Option Nat
  disposition : LinkDisposition
  emitted : List Int
  diagnostics : List Int
  effects : List Nat
  settled : Bool
  context : Nat
  deriving DecidableEq

theorem sameReturnedPathCanChangeDiagnostics :
    let a : LinkTraceObservation := ⟨some 1, .success, [2], [], [3], true, 4⟩
    let b : LinkTraceObservation := ⟨some 1, .success, [2], [5], [3], true, 4⟩
    a.returnPath = b.returnPath ∧ a ≠ b := by decide

theorem abortCanRetainPartialWrite :
    let a : LinkTraceObservation := ⟨none, .compilerAbort, [2], [5], [1,2], false, 4⟩
    a.returnPath = none ∧ a.emitted ≠ [] ∧ a.settled = false := by decide

-- Other binds full non-script records, filenames, flags, ordering and context.
-- Factors must cover exception, diagnostic, effect and custody observations too.
theorem scriptFullObservationCongruence {Actual Other : Type}
    (script : Actual → List Int) (other : Actual → Other)
    (observe : Actual → LinkTraceObservation)
    (kernel : List Int → Other → LinkTraceObservation)
    (factors : ∀ x, observe x = kernel (script x) (other x)) {a b : Actual}
    (sameScript : encodeRecursiveDatum (.atom .string (script a)) =
      encodeRecursiveDatum (.atom .string (script b))) (sameOther : other a = other b) :
    observe a = observe b := by
  have units := singletonScriptEncodingReflects sameScript
  rw [factors a, factors b, units, sameOther]

theorem scriptPropertyReflection (property : LinkTraceObservation → Prop)
    {reference candidate : LinkTraceObservation} (same : reference = candidate)
    (safe : property reference) : property candidate := by
  rwa [← same]

'''
s=s[:-len('end GambitBuild\n')]+new+'end GambitBuild\n';p.write_text(s)
p=Path('models/build/incremental_build.qnt');s=p.read_text();s+='''
// Script-line source rules and trace-aware qualification, not a concrete adapter.
module gsc_script_line {
  type Script = { truthy: bool, text: bool, units: List[int] }
  type Entry = { matches: bool, value: Script }
  pure val noScript: Script = { truthy: false, text: false, units: List() }
  pure def scriptText(units: List[int]): Script = { truthy: true, text: true, units: units }
  pure def chooseScript(previous: Script, next: Script): Script = if (next.truthy) next else previous
  pure def scriptSelection(values: List[Script]): Script = values.foldl(noScript, (a,b) => chooseScript(a,b))
  pure def firstScript(entries: List[Entry]): Script = entries.foldr(noScript, (e,a) => if (e.matches) e.value else a)
  pure val emptyTextWins = chooseScript(scriptText(List(1)), scriptText(List())) == scriptText(List())
  pure val falseDoesNotClear = chooseScript(scriptText(List(1)), noScript) == scriptText(List(1))
  type Lease = { contentEpoch: int, capturedEpoch: int, allWriters: bool,
    externalQuiescent: bool, rootCovered: bool, noReentrantWrite: bool }
  pure def sourceBorrowEligible(v: Lease): bool = all { v.contentEpoch == v.capturedEpoch,
    v.allWriters, v.externalQuiescent, v.rootCovered, v.noReentrantWrite }
  pure def payloadWrite(v: Lease): Lease = { ...v, contentEpoch: v.contentEpoch + 1 }
  pure def payloadWriteBlocks(v: Lease): bool = sourceBorrowEligible(v) implies not(sourceBorrowEligible(payloadWrite(v)))
  type LinkTrace = { result: int, disposition: int, emitted: List[int], diagnostics: List[int],
    effects: List[int], settled: bool, context: int }
  pure def fullLinkEquivalent(a: LinkTrace, b: LinkTrace): bool = a == b
  pure val sameResultIsInsufficient = {
    val a: LinkTrace = { result: 1, disposition: 0, emitted: List(2), diagnostics: List(), effects: List(3), settled: true, context: 4 }
    val b = { ...a, diagnostics: List(5) }
    a.result == b.result and not(fullLinkEquivalent(a,b))
  }
}
''';p.write_text(s)
print('Added 12 Lean statements and eighth QNT module')
