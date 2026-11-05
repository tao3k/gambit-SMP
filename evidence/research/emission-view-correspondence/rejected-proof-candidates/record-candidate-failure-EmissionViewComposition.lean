import EmissionView
import ModuleHandleComposition
namespace EmissionViewComposition
open EmissionViewAst
structure Chunk where
 key : Nat
 payload : List Nat
 deriving DecidableEq
def byteOutput : List Chunk → List Nat
 | [] => []
 | x::xs => x.payload ++ byteOutput xs
def witnessOutput : List Chunk → List (Nat × List Nat)
 | [] => []
 | x::xs => (x.key,x.payload)::witnessOutput xs
def replay : List (Nat × List Nat) → List Nat
 | [] => []
 | x::xs => x.2 ++ replay xs
theorem orderedWitnessReplaysBytes (xs : List Chunk) : replay (witnessOutput xs)=byteOutput xs := by
 induction xs with
 | nil => rfl
 | cons x xs ih => simp [witnessOutput,replay,byteOutput,ih]
theorem matchingCountsDoNotProveBytes : ([65] : List Nat).length=([66] : List Nat).length ∧ ([65] : List Nat)≠[66] := by decide
theorem nativeQualifierFitsParent (q : State) (h : Safe q) (ready : q.nativeReady=true)
 (p : ModuleHandleAst.State) (sameOpaque : p.hasOpaque=q.opaqueSeen)
 (sameQualifier : p.qualified=q.nativeQualified) : p.hasOpaque=true → p.qualified=true := by
 have sufficient := EmissionView.nativeNeedsQualification q h ready
 rw [sameOpaque,sameQualifier]
 exact sufficient.2
def opaqueTextExample : State := { initial with phase:=3,snapshot:=1,cGen:=1,mGen:=1,
 frontCaptured:=true,lateCaptured:=true,aliasesClosed:=true,inputFrozen:=true,
 fragmentsOwned:=true,layoutDone:=true,opaqueSeen:=true,verifierQualified:=true,
 cDone:=true,mDone:=true,coverage:=true,ioComplete:=true,receipt:=true }
theorem textReceiptIsNotNativePermission : Safe opaqueTextExample ∧ ¬nativePermitGuard opaqueTextExample := by
 decide
end EmissionViewComposition
