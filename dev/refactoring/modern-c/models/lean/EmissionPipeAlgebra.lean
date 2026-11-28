import FormatterLegalAlgebra
namespace EmissionPipeAlgebra
open PrimitiveBindingAlgebra BindingWriterClosure
theorem secondUnderNamedWriters {a b : Resource} (h : canonical a) (steps : NamedHistory a b) : demand b=b := FormatterLegalAlgebra.secondUnderNamedWriters h steps
-- These are scalar correspondence lemmas. Source simulation still needs identity and effect closure.
def unread (wlo rlo : Int) := wlo-rlo
theorem pausedPressure : (1 : Int)<unread 32 0 := by unfold unread; omega
theorem drainedNoPressure (r : Int) (h : 0≤r) : ¬ ((1 : Int)<unread 0 r) := by unfold unread; omega
theorem rebasePending (wlo whi rlo : Int) : (wlo-rlo)+whi-0=wlo+whi-rlo := by omega
theorem publishPending (wlo whi rlo : Int) : (wlo+whi)+0-rlo=wlo+whi-rlo := by omega
theorem tailFitsFresh : (23 : Int)<32 := by decide
end EmissionPipeAlgebra
