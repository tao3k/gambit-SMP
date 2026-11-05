import Std.Tactic
namespace RootProducerCensus
def current (required : Nat → Prop) (version seen : Nat → Nat) := ∀ i, required i → seen i=version i
def update (v : Nat → Nat) (i n : Nat) := fun j => if j=i then n else v j
theorem scanPreserves (r : Nat → Prop) (v seen : Nat → Nat) (i : Nat) (h : current r v seen) : current r v (update seen i (v i)) := by
 intro j hj; by_cases e : j=i
 · simp [update,e]
 · simp [update,e]; exact h j hj
theorem idleNeedsOwnRoots (required : Nat → Prop) (owner version seen : Nat → Nat) (w : Nat)
 (h : ∀ i, required i → owner i=w → seen i=version i) (i : Nat) (hr : required i) (ho : owner i=w) : seen i=version i := h i hr ho
theorem rcOmissionBlocks (r : Nat → Prop) (v seen : Nat → Nat) (i : Nat) (hr : r i) (missing : seen i≠v i) : ¬current r v seen := by
 intro h; exact missing (h i hr)
theorem committedWriteInvalidates (r : Nat → Prop) (v seen : Nat → Nat) (i : Nat) (hr : r i) (h : current r v seen) : ¬current r (update v i (v i+1)) seen := by
 intro post; have a := h i hr; have b := post i hr; simp [update] at b; omega
def frozen (admission : Bool) (pending : Nat → Prop) := admission=false ∧ ∀ i, ¬pending i
theorem freezeDrainsLeases (a : Bool) (p : Nat → Prop) (h : frozen a p) : ∀ i, ¬p i := h.2
theorem waitingWriterPreventsFreeze (a : Bool) (p : Nat → Prop) (i : Nat) (waiting : p i) : ¬frozen a p := by
 intro h; exact h.2 i waiting
def owned (debt active : Nat → Prop) (owner : Nat → Nat) := ∀ d, debt d → active (owner d)
theorem zeroClosesDebts (d a : Nat → Prop) (o : Nat → Nat) (h : owned d a o) (zero : ∀ w, ¬a w) : ∀ x, ¬d x := by
 intro x hx; exact zero (o x) (h x hx)
theorem transferPreserves (d a : Nat → Prop) (o : Nat → Nat) (h : owned d a o) (x dst : Nat) (ha : a dst) : owned d a (update o x dst) := by
 intro y hy; by_cases e : y=x
 · simpa [update,e] using ha
 · simpa [update,e] using h y hy
def permit (zero manifest stable maps native : Bool) := zero=true ∧ manifest=true ∧ stable=true ∧ maps=true ∧ native=true
theorem incompleteManifestBlocks (z s m n : Bool) : ¬permit z false s m n := by simp [permit]
def markerSafe (allocated rooted : Bool) := allocated=true → rooted=true
theorem markerBeforeAllocation : ¬markerSafe true false := by simp [markerSafe]
theorem netBenefit (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end RootProducerCensus
