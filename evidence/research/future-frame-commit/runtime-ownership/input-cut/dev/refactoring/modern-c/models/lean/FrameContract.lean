import Std

-- Mathematical descriptor correspondence; C pointer validity, shifts and ABI
-- configuration remain separate source/native obligations.
namespace Gambit.FrameContract
def inlineWord (kind size link roots : Nat) := kind + 4*size + 128*link + 4096*roots
def outlineWord (kind size link : Nat) := kind + 4*size + 65536*link

theorem inlineKind (k s l r : Nat) (hk : k<4) : inlineWord k s l r % 4 = k := by
 unfold inlineWord; omega
theorem inlineSize (k s l r : Nat) (hk : k<4) (hs : s<32) :
 (inlineWord k s l r / 4) % 32 = s := by unfold inlineWord; omega
theorem inlineLink (k s l r : Nat) (hk : k<4) (hs : s<32) (hl : l<32) :
 (inlineWord k s l r / 128) % 32 = l := by unfold inlineWord; omega
theorem inlineRoots (k s l r : Nat) (hk : k<4) (hs : s<32) (hl : l<32)
 (hr : r<1048576) : (inlineWord k s l r / 4096) % 1048576 = r := by
 unfold inlineWord; omega
theorem outlineKind (k s l : Nat) (hk : k<4) : outlineWord k s l % 4 = k := by
 unfold outlineWord; omega
theorem outlineSize (k s l : Nat) (hk : k<4) (hs : s<16384) :
 (outlineWord k s l / 4) % 16384 = s := by unfold outlineWord; omega
theorem outlineLink (k s l : Nat) (hk : k<4) (hs : s<16384) (hl : l<16384) :
 (outlineWord k s l / 65536) % 16384 = l := by unfold outlineWord; omega
end Gambit.FrameContract
