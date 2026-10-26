import FrameBitmapComposition
namespace Gambit.FrameCursorClosure
open Gambit
inductive Mode where
 | skip | run | pending | done
 deriving DecidableEq
structure State where
 mode : Mode
 pos : Nat
 first : Nat
 past : Nat
 delivered : Nat → Bool

def Safe (fs : Nat) (root : Nat → Bool) (q : State) : Prop :=
 0<q.pos ∧ q.pos≤fs+1 ∧
 match q.mode with
 | .skip => FrameRoots.Prefix root q.delivered q.pos
 | .run => 0<q.first ∧ q.first≤q.pos ∧ q.pos≤fs ∧
   FrameRoots.Prefix root q.delivered q.first ∧
   ∀ i, q.first≤i → i≤q.pos → root i=true
 | .pending => 0<q.first ∧ q.first<q.pos ∧ q.past=q.pos ∧
   FrameRoots.Prefix root q.delivered q.first ∧
   (∀ i, q.first≤i → i<q.pos → root i=true) ∧ (fs<q.pos ∨ root q.pos=false)
 | .done => q.pos=fs+1 ∧ FrameRoots.Prefix root q.delivered q.pos

def deliver (q : State) : Nat → Bool := fun i =>
 if q.first≤i ∧ i<q.pos then true else q.delivered i

inductive Move (fs : Nat) (root : Nat → Bool) : State → State → Prop where
 | skipDead (q) (mode : q.mode=.skip) (inside : q.pos≤fs) (dead : root q.pos=false) :
   Move fs root q {q with pos:=q.pos+1}
 | startRun (q) (mode : q.mode=.skip) (inside : q.pos≤fs) (live : root q.pos=true) :
   Move fs root q {q with mode:=.run,first:=q.pos}
 | endFrame (q) (mode : q.mode=.skip) (outside : fs<q.pos) :
   Move fs root q {q with mode:=.done}
 | continueRun (q) (mode : q.mode=.run) (inside : q.pos+1≤fs) (live : root (q.pos+1)=true) :
   Move fs root q {q with pos:=q.pos+1}
 | returnRun (q) (mode : q.mode=.run) (stop : fs<q.pos+1 ∨ root (q.pos+1)=false) :
   Move fs root q {q with mode:=.pending,pos:=q.pos+1,past:=q.pos+1}
 | deliverRun (q) (mode : q.mode=.pending) :
   Move fs root q {q with mode:=.skip,delivered:=deliver q}

theorem skipPreservesPrefix (root seen : Nat → Bool) (pos : Nat)
 (h : FrameRoots.Prefix root seen pos) (dead : root pos=false) :
 FrameRoots.Prefix root seen (pos+1) := by
 intro i
 rw [h i]
 constructor
 · rintro ⟨hi,hp,hr⟩; exact ⟨hi,by omega,hr⟩
 · rintro ⟨hi,hp,hr⟩
   have ne : i≠pos := by intro eq; subst i; simp [dead] at hr
   exact ⟨hi,by omega,hr⟩

theorem deliveryExtendsPrefix (q : State) (root : Nat → Bool)
 (positive : 0<q.first) (ordered : q.first≤q.pos)
 (before : FrameRoots.Prefix root q.delivered q.first)
 (live : ∀ i, q.first≤i → i<q.pos → root i=true) :
 FrameRoots.Prefix root (deliver q) q.pos := by
 intro i
 by_cases inside : q.first≤i ∧ i<q.pos
 · simp only [deliver,ite_eq_left inside,Bool.true_eq_true,true_iff]
   exact ⟨by omega,inside.2,live i inside.1 inside.2⟩
 · simp only [deliver,ite_eq_right inside]
   rw [before i]
   constructor
   · rintro ⟨hi,hf,hr⟩; exact ⟨hi,by omega,hr⟩
   · rintro ⟨hi,hp,hr⟩; exact ⟨hi,by omega,hr⟩

theorem preserves (fs : Nat) (root : Nat → Bool) (q r : State)
 (h : Safe fs root q) (step : Move fs root q r) : Safe fs root r := by
 cases step with
 | skipDead q mode inside dead =>
   simp only [Safe,mode] at h ⊢
   exact ⟨by omega,by omega,skipPreservesPrefix root q.delivered q.pos h.2.2 dead⟩
 | startRun q mode inside live =>
   simp only [Safe,mode] at h ⊢
   refine ⟨h.1,h.2.1,h.1,by omega,inside,h.2.2,?_⟩
   intro i hi hp
   have eq : i=q.pos := by omega
   simpa [eq] using live
 | endFrame q mode outside =>
   simp only [Safe,mode] at h ⊢
   exact ⟨h.1,h.2.1,by omega,h.2.2⟩
 | continueRun q mode inside live =>
   simp only [Safe,mode] at h ⊢
   rcases h with ⟨lo,hi,first,ordered,inOld,before,segment⟩
   refine ⟨by omega,by omega,first,by omega,inside,before,?_⟩
   intro i hf hp
   by_cases old : i≤q.pos
   · exact segment i hf old
   · have eq : i=q.pos+1 := by omega
     simpa [eq] using live
 | returnRun q mode stop =>
   simp only [Safe,mode] at h ⊢
   rcases h with ⟨lo,hi,first,ordered,inside,before,segment⟩
   exact ⟨by omega,by omega,first,by omega,rfl,before,
    fun i hf hp => segment i hf (by omega),stop⟩
 | deliverRun q mode =>
   simp only [Safe,mode] at h ⊢
   rcases h with ⟨lo,hi,first,ordered,past,before,segment,stop⟩
   exact ⟨lo,hi,deliveryExtendsPrefix q root first (by omega) before segment⟩

def initial : State := ⟨.skip,1,0,0,fun _=>false⟩
theorem initialSafe (fs : Nat) (root : Nat → Bool) : Safe fs root initial := by
 exact ⟨by decide,by omega,FrameRoots.initial root⟩

inductive Path (fs : Nat) (root : Nat → Bool) : State → State → Prop where
 | refl (q) : Path fs root q q
 | cons {q r t} : Move fs root q r → Path fs root r t → Path fs root q t

theorem pathPreserves (fs : Nat) (root : Nat → Bool) (q r : State)
 (h : Safe fs root q) (path : Path fs root q r) : Safe fs root r := by
 induction path with
 | refl => exact h
 | cons step path ih => exact ih (preserves fs root _ _ h step)

theorem completedExactly (fs : Nat) (root : Nat → Bool) (q : State)
 (path : Path fs root initial q) (done : q.mode=.done) :
 ∀ i, q.delivered i=true ↔ 0<i ∧ i≤fs ∧ root i=true := by
 have h := pathPreserves fs root initial q (initialSafe fs root) path
 simp only [Safe,done] at h
 have prefixDone : FrameRoots.Prefix root q.delivered (fs+1) := by simpa [h.2.2.1] using h.2.2.2
 exact FrameRoots.complete root q.delivered fs prefixDone

theorem pendingRangeIsFresh (fs : Nat) (root : Nat → Bool) (q : State)
 (h : Safe fs root q) (pending : q.mode=.pending) (i : Nat)
 (inside : q.first≤i ∧ i<q.pos) : q.delivered i≠true := by
 simp only [Safe,pending] at h
 have before := h.2.2.2.2.2.1
 intro already
 have old := (before i).mp already
 omega

def rank (fs : Nat) (q : State) : Nat :=
 match q.mode with
 | .skip => 3*(fs+1-q.pos)+2
 | .run => 3*(fs+1-q.pos)+1
 | .pending => 3*(fs+1-q.pos)+3
 | .done => 0

theorem rankDecreases (fs : Nat) (root : Nat → Bool) (q r : State)
 (h : Safe fs root q) (step : Move fs root q r) : rank fs r < rank fs q := by
 have lo := h.1
 have hi := h.2.1
 cases step with
 | skipDead q mode inside dead => simp [rank,mode]; omega
 | startRun q mode inside live => simp [rank,mode]
 | endFrame q mode outside => simp [rank,mode]
 | continueRun q mode inside live => simp [rank,mode]; omega
 | returnRun q mode stop =>
   have hq := h
   simp only [Safe,mode] at hq
   have inside := hq.2.2.2.2.1
   simp [rank,mode]
   omega
 | deliverRun q mode => simp [rank,mode]

theorem hasNext (fs : Nat) (root : Nat → Bool) (q : State)
 (h : Safe fs root q) (notDone : q.mode≠.done) : ∃ r, Move fs root q r := by
 cases mode : q.mode with
 | skip =>
   by_cases inside : q.pos≤fs
   · cases live : root q.pos with
     | false => exact ⟨_,Move.skipDead q mode inside live⟩
     | true => exact ⟨_,Move.startRun q mode inside live⟩
   · exact ⟨_,Move.endFrame q mode (by omega)⟩
 | run =>
   by_cases inside : q.pos+1≤fs
   · cases live : root (q.pos+1) with
     | false => exact ⟨_,Move.returnRun q mode (Or.inr live)⟩
     | true => exact ⟨_,Move.continueRun q mode inside live⟩
   · exact ⟨_,Move.returnRun q mode (Or.inl (by omega))⟩
 | pending => exact ⟨_,Move.deliverRun q mode⟩
 | done => exact False.elim (notDone mode)

theorem finiteClosure (fs : Nat) (root : Nat → Bool) (q : State) (h : Safe fs root q) :
 ∃ last, Path fs root q last ∧ last.mode=.done := by
 have close : ∀ n, ∀ q : State, rank fs q=n → Safe fs root q → ∃ last, Path fs root q last ∧ last.mode=.done := by
   intro n
   induction n using Nat.strong_induction_on with
   | h n ih =>
     intro q eq safe
     by_cases done : q.mode=.done
     · exact ⟨q,Path.refl q,done⟩
     · obtain ⟨next,step⟩ := hasNext fs root q safe done
       have lower := rankDecreases fs root q next safe step
       obtain ⟨last,path,done⟩ := ih (rank fs next) (by omega) next rfl (preserves fs root q next safe step)
       exact ⟨last,Path.cons step path,done⟩
 exact close (rank fs q) q rfl h
end Gambit.FrameCursorClosure
