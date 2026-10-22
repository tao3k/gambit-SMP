from pathlib import Path
p=Path('models/build/IncrementalBuild.lean');s=p.read_text();assert s.endswith('end GambitBuild\n')
s=s[:-len('end GambitBuild\n')]+'''-- Mathematical framing model only: no Gambit reader, filesystem or native codec.
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
  simp [readDatumFrame, datumFrame, List.take_left, List.drop_left]

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
    | fuel+1, [] => some .nil
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
            simp [ih.1 a (encodeRecursiveDatum d) ha, ih.1 d [] hd]
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
                simp [encodeDatumSequence, enc, parseDatumSequence, head, ih.2 ds hs]

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

end GambitBuild
''';p.write_text(s)
p=Path('models/build/incremental_build.qnt');s=p.read_text()+'''
// Structural framing specification; actual Scheme parser/domain bridge is open.
module gsc_datum_projection {
  pure def frameDatum(tag: int, payload: List[int]): List[int] =
    List(tag, payload.length()).concat(payload)
  pure def frameShape(xs: List[int]): bool = if (xs.length() < 2) false else
    all { xs.nth(0) >= 0, xs.nth(0) <= 8, xs.nth(1) >= 0,
      xs.nth(1) == xs.length() - 2 }
  pure def scalarPayloadAdmitted(tag: int, body: List[int]): bool =
    if (tag == 0) body.length() == 0 else
    if (tag == 1) body.length() == 1 and (body.nth(0) == 0 or body.nth(0) == 1) else
    if (tag == 2 or tag == 3) body.length() == 1 else
    tag >= 4 and tag <= 6
}
''';p.write_text(s)
