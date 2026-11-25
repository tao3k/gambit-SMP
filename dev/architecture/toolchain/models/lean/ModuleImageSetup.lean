-- Value refinement only. QNT owns protocol ordering; this is not C extraction.
namespace Gambit.ModuleImageSetup
structure ABI where
  wordBytes : Nat
  registers : Nat
  arguments : Nat
  tagBits : Nat
  frameAlign : Nat
  frameReserve : Nat
  labelWords : Nat
  stateSchema : Nat
  deriving DecidableEq

def load (imageABI runtimeABI : ABI) (fixed : Bool)
    (image live : List Nat) : Option (List Nat) :=
  if imageABI = runtimeABI then some (if fixed then live else image) else none

theorem reject_preserves (a b : ABI) (h : a ≠ b) (f : Bool) (i l : List Nat) :
    load a b f i l = none := by simp [load, h]
theorem initial_tables (a : ABI) (i l : List Nat) :
    load a a false i l = some i := by simp [load]
theorem reload_preserves_fixups (a : ABI) (i l : List Nat) :
    load a a true i l = some l := by simp [load]
theorem reload_independent_of_initial (a : ABI) (i j l : List Nat) :
    load a a true i l = load a a true j l := by simp [load]
theorem failed_tuple_cannot_publish (a b : ABI) (h : a ≠ b)
    (f : Bool) (i l out : List Nat) : load a b f i l ≠ some out := by
  simp [load, h]
end Gambit.ModuleImageSetup
