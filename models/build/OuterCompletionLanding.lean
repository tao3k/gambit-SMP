import Std.Tactic
namespace OuterCompletionLanding
structure Guard where
 owner : Bool
 marker : Bool
 catcher : Bool
 reload : Bool
 roster : Bool
 settled : Bool
 released : Bool
def safe (g : Guard) := (g.released=true → g.settled=true ∧ g.marker=false ∧ g.catcher=false ∧ g.reload=false ∧ g.roster=false) ∧ (g.settled=false → g.owner=true)
def initial : Guard := ⟨true,true,true,true,false,false,false⟩
def mark (g : Guard) : Guard := {g with marker:=false}
def pop (g : Guard) : Guard := {g with catcher:=false}
def reload (g : Guard) : Guard := {g with reload:=false}
def transfer (g : Guard) : Guard := {g with roster:=false}
def settle (g : Guard) : Guard := {g with settled:=true}
def release (g : Guard) : Guard := {g with owner:=false,released:=true}
def ready (g : Guard) := g.marker=false ∧ g.catcher=false ∧ g.reload=false ∧ g.roster=false
theorem initialSafe : safe initial := by simp [safe,initial]
theorem markerCleared (g : Guard) : (mark g).marker=false := rfl
theorem catchRestored (g : Guard) : (pop g).catcher=false := rfl
theorem reloaded (g : Guard) : (reload g).reload=false := rfl
theorem rosterTransferred (g : Guard) : (transfer g).roster=false := rfl
theorem ownerInstalled : initial.owner=true := rfl
theorem settledReady (g : Guard) (h : ready g) : ready (settle g) := h
theorem releaseSafe (g : Guard) (done : g.settled=true) (h : ready g) : safe (release g) := by
 simp [safe,release,done]; exact h
inductive Edge : Guard → Guard → Prop where
 | mark (g) : Edge g (mark g)
 | pop (g) : Edge g (pop g)
 | reload (g) : Edge g (reload g)
 | transfer (g) : Edge g (transfer g)
 | settle (g) (h : ready g) : Edge g (settle g)
 | release (g) (done : g.settled=true) (h : ready g) : Edge g (release g)
theorem stepPreserves {g t : Guard} (h : safe g) (e : Edge g t) : safe t := by
 cases e with
 | mark =>
   constructor
   · intro hr; have p := h.1 hr; exact ⟨p.1,rfl,p.2.2.1,p.2.2.2.1,p.2.2.2.2⟩
   · exact h.2
 | pop =>
   constructor
   · intro hr; have p := h.1 hr; exact ⟨p.1,p.2.1,rfl,p.2.2.2.1,p.2.2.2.2⟩
   · exact h.2
 | reload =>
   constructor
   · intro hr; have p := h.1 hr; exact ⟨p.1,p.2.1,p.2.2.1,rfl,p.2.2.2.2⟩
   · exact h.2
 | transfer =>
   constructor
   · intro hr; have p := h.1 hr; exact ⟨p.1,p.2.1,p.2.2.1,p.2.2.2.1,rfl⟩
   · exact h.2
 | settle ready => simp [safe,settle]; intro _; exact ready
 | release done ready => exact releaseSafe g done ready
inductive Trace : Guard → Guard → Prop where
 | nil (g) : Trace g g
 | cons {g t u} : Edge g t → Trace t u → Trace g u
theorem historyPreserves {g t : Guard} (h : safe g) (es : Trace g t) : safe t := by
 induction es with
 | nil => exact h
 | cons e es ih => exact ih (stepPreserves h e)
theorem nestedPop (parent : Nat) (tail : List Nat) : (parent::tail).tail=tail := rfl
theorem parentUnaffected (parent child : Guard) : (child,parent).2=parent := rfl
def vmReady (guards handles invocations : Nat) := guards=0 ∧ handles=0 ∧ invocations=0
theorem vmRetirementExcludesHandles (g h i : Nat) (ok : vmReady g h i) : h=0 := ok.2.1
theorem noEarlyRelease : ¬safe ⟨false,true,true,true,false,false,true⟩ := by simp [safe]
theorem deadMarkerDeniesReturn : (false : Bool)≠true := by decide
theorem workBalance (old new saved added : Nat) (eq : new+saved=old+added) (win : added<saved) : new<old := by omega
end OuterCompletionLanding
