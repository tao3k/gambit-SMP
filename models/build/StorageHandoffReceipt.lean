import Std.Tactic
namespace StorageHandoffReceipt
def maySeal (raw writer allocation pinned : Bool) (reserve : Nat) :=
 raw=false ∧ writer=false ∧ allocation=false ∧ pinned=false ∧ reserve=0
theorem rawBlocksSeal (w a p : Bool) (r : Nat) : ¬maySeal true w a p r := by simp [maySeal]
theorem reserveBlocksSeal (b w a p : Bool) (r : Nat) (h : 0<r) : ¬maySeal b w a p r := by simp [maySeal]; omega
def current (sealed epoch : Nat) := sealed=epoch
theorem epochInvalidates (epoch : Nat) : ¬current epoch (epoch+1) := by simp [current]
theorem chargeConservation (source deferred target reserve : Nat) :
 (source+target+reserve)+deferred=(source+deferred)+target+reserve := by omega
theorem handoffNoDoubleCharge (charged deferred target : Nat) :
 (charged+deferred+target)=charged+target+deferred := by omega
structure Arena where
 source : List Nat
 target : List Nat
 rcSource : List Nat
 rcTarget : List Nat
 committed : Bool
def transfer (a : Arena) : Arena := {source:=[], target:=a.source, rcSource:=[], rcTarget:=a.rcSource, committed:=true}
theorem exactChain (a : Arena) : (transfer a).target=a.source := rfl
theorem rcDetached (a : Arena) : (transfer a).rcSource=[] := rfl
def mayExit (a : Arena) := a.committed=true ∧ a.source=[] ∧ a.rcSource=[]
theorem transferredMayExit (a : Arena) : mayExit (transfer a) := by simp [mayExit,transfer]
def mayFree (lease unknown : Bool) (releaseState : Nat) := lease=false ∧ unknown=false ∧ (releaseState=2 ∨ releaseState=4)
theorem leaseBlocksFree (unknown : Bool) (r : Nat) : ¬mayFree true unknown r := by simp [mayFree]
theorem unknownBlocksFree (lease : Bool) (r : Nat) : ¬mayFree lease true r := by simp [mayFree]
theorem releaseErrorRetains (lease unknown : Bool) : ¬mayFree lease unknown 3 := by simp [mayFree]
theorem netBenefit (oldWork newWork saved overhead : Nat) (h : newWork+saved=oldWork+overhead) (p : overhead<saved) : newWork<oldWork := by omega
end StorageHandoffReceipt
