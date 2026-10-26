import Std

-- C-facing arithmetic contract. These are integer/finite-word theorems, not a
-- C parser, pointer-provenance proof, descriptor lease, or GC completion proof.
namespace Gambit.FrameCursorNativeBounds

def NativeWidth (w : Nat) : Prop := w = 32 ∨ w = 64
def tailWords (fs w : Nat) : Nat := (fs + w - 1) / w - 1
def internalSize (stored : Nat) : Nat := ((stored + 3) / 4) * 4 + 9

theorem unsignedShift (w : Nat) (bits : BitVec w) :
    (bits >>> 1).toNat = bits.toNat / 2 := by
  rw [BitVec.toNat_ushiftRight, Nat.shiftRight_eq_div_pow]

theorem lowBit (n : Nat) : n &&& 1 = n % 2 := by
  exact Nat.and_two_pow_sub_one_eq_mod n 1

theorem boundaryMask (w n : Nat) (hw : NativeWidth w) :
    n &&& (w - 1) = n % w := by
  rcases hw with rfl | rfl
  · exact Nat.and_two_pow_sub_one_eq_mod n 5
  · exact Nat.and_two_pow_sub_one_eq_mod n 6

theorem signedWordCast (w : Nat) (signed : Int) :
    (BitVec.ofInt w signed).toNat = (signed % (2^w : Nat)).toNat :=
  BitVec.toNat_ofInt signed

-- Raw next points into the tail after the first bitmap word. The old index is
-- consumed before increment; a stored one-past cursor is never a load grant.
theorem tailReadBound (fs slot w : Nat) (hw : NativeWidth w)
    (hs : 1 ≤ slot) (hf : slot < fs) (hb : slot % w = 0) :
    (slot - 1) / w < tailWords fs w := by
  unfold tailWords
  rcases hw with rfl | rfl <;> omega

theorem tailPostincrementBound (fs slot w : Nat) (hw : NativeWidth w)
    (hs : 1 ≤ slot) (hf : slot < fs) (hb : slot % w = 0) :
    (slot - 1) / w + 1 ≤ tailWords fs w := by
  have h := tailReadBound fs slot w hw hs hf hb
  omega

theorem inlineNoRefill (fs slot w : Nat) (hw : NativeWidth w)
    (hi : fs ≤ 20) (hs : 1 ≤ slot) (hf : slot < fs) : slot % w ≠ 0 := by
  rcases hw with rfl | rfl <;> omega

theorem finalSlotNoRefill (fs slot : Nat) (h : slot = fs) : ¬ slot < fs := by omega

theorem packed32ToNative64 (fs : Nat) :
    (((fs + 31) / 32) + 1) / 2 = (fs + 63) / 64 := by omega

theorem internalSizeBound (stored : Nat) (h : stored < 16384) :
    internalSize stored ≤ 16393 := by unfold internalSize; omega

theorem cursorIntBound (fs slot intMax : Nat) (hf : fs ≤ 16393)
    (hs : slot ≤ fs) (hi : 32767 ≤ intMax) : slot + 1 ≤ intMax := by omega

theorem bitmapCapacity (fs w : Nat) (hw : NativeWidth w) (hf : fs ≤ 16393) :
    (w = 32 → (fs + w - 1) / w ≤ 513 ∧ tailWords fs w ≤ 512) ∧
    (w = 64 → (fs + w - 1) / w ≤ 257 ∧ tailWords fs w ≤ 256) := by
  unfold tailWords
  rcases hw with rfl | rfl <;> omega

-- Element coordinates within ONE live allocation; no conclusion about two
-- equal machine addresses or about storage after its generation retires.
theorem reversedRunBounds (fs fp size first past : Nat)
    (hf : fs ≤ fp) (hp : fp ≤ size)
    (_hfirst : 1 ≤ first) (_hr : first < past) (hend : past ≤ fs + 1) :
    fp - (past - 1) + (past - first) ≤ size := by omega

theorem reversedSlotIdentity (fs fp first past i : Nat)
    (hf : fs ≤ fp) (_hfirst : 1 ≤ first) (_hr : first ≤ i)
    (hi : i < past) (hend : past ≤ fs + 1) :
    fp - (past - 1) + (past - 1 - i) = fp - i := by omega

theorem allocationBoundIsNotViewBound :
    3 < 10 ∧ ¬ 3 < 3 := by omega

theorem internalMaximum : internalSize 16383 = 16393 ∧
    tailWords 16393 32 = 512 ∧ tailWords 16393 64 = 256 := by decide

end Gambit.FrameCursorNativeBounds
