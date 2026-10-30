import PrimitiveBindingAlgebra
namespace NativeBindingRefinement
open PrimitiveBindingAlgebra
structure Machine where
 resource : Resource
 header : List Nat
 slot : Nat
 label : Nat
 output : List Nat
 deriving DecidableEq
def publicView (s : Machine) := (s.header,s.slot,s.label,s.output)
def legacyFirst (s : Machine) : Machine := {s with resource:=demand s.resource,output:=s.output++[1]}
def readonlyFirst (s : Machine) : Machine := {s with output:=s.output++[1]}
def legacySecond (s : Machine) : Machine := {s with resource:=demand s.resource,output:=s.output++[2]}
def readonlySecond (s : Machine) : Machine := {s with output:=s.output++[2]}
-- This observer excludes resource aliases. Proving that it covers real observers is external.
theorem firstPublicEquivalent (s : Machine) : publicView (legacyFirst s)=publicView (readonlyFirst s) := by rfl
theorem bothPublicEquivalent (s : Machine) : publicView (legacySecond (legacyFirst s))=publicView (readonlySecond (readonlyFirst s)) := by rfl
theorem secondMetadataEquivalent (s : Machine) (h : s.resource.demanders=[""]) : legacySecond s=readonlySecond s := by
 have e := (exactDemandUnchanged s.resource).2 h
 simp only [legacySecond,readonlySecond,e]
theorem firstMetadataRequiresCanonical (r : Resource) : demand r=r ↔ r.demanders=[""] := exactDemandUnchanged r
theorem normalizationCanBePlannedOnce (r : Resource) : demand (demand r)=demand r := demandIdempotent r
theorem aliasDistinguishes : (demand ⟨"p",[],[""]⟩).demanders ≠ ([] : List String) := by decide
theorem interveningWriterBreaksSecond : (demand ⟨"p",["foreign"],[""]⟩).demanders ≠ ["foreign"] := by decide
theorem errorPrefixNotEquivalent : ([0,1,9] : List Nat) ≠ [9] := by decide
theorem replayNotRetry : ([0,1,1,2] : List Nat) ≠ [0,1,2] := by decide
theorem generationIsPartOfIdentity (a b n : Nat) (h : a ≠ b) : (a,n) ≠ (b,n) := by
 intro e; exact h (congrArg Prod.fst e)
end NativeBindingRefinement
