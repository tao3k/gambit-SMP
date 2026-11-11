import Std
namespace Gambit.FrameCursorAst
noncomputable section
attribute [local instance] Classical.propDecidable
structure Scan where
 fs : Int
 bitmap : Int
 slot : Int
 word : Int
 next : Int
 seen : (Int → Prop)
 visits : Int
 mode : Int
 excluded : Int
 first : Int
 past : Int
 delivered : (Int → Prop)
 runs : Int
 scanWidth : Int
def width  : Int := (4 : Int)
def start (n : Int) (b : Int) : Scan := {fs:=n, bitmap:=b, slot:=(1 : Int), word:=(b % ((2 : Int) ^ (width).toNat)), next:=(0 : Int), seen:=(fun _ : Int => False), visits:=(0 : Int), mode:=(0 : Int), excluded:=(0 : Int), first:=(0 : Int), past:=(0 : Int), delivered:=(fun _ : Int => False), runs:=(0 : Int), scanWidth:=width}
def startRun (n : Int) (b : Int) (e : Int) (w : Int) : Scan := {{{(start (n) (b)) with excluded:=e} with scanWidth:=w} with word:=(b % ((2 : Int) ^ (w).toNat))}
def root (bits : Int) (slot : Int) : Prop := (((bits / ((2 : Int) ^ ((slot - (1 : Int))).toNat)) % (2 : Int)) = (1 : Int))
def eligible (x : Scan) (i : Int) : Prop := ((root ((x).bitmap) (i)) ∧ (i ≠ (x).excluded))
def advanceCursor (x : Scan) : Scan := (let load := (((x).slot < (x).fs) ∧ (((x).slot % (x).scanWidth) = (0 : Int))); {{{x with slot:=((x).slot + (1 : Int))} with word:=(if load then (((x).bitmap / ((2 : Int) ^ ((((x).next + (1 : Int)) * (x).scanWidth)).toNat)) % ((2 : Int) ^ ((x).scanWidth).toNat)) else ((x).word / (2 : Int)))} with next:=(if load then ((x).next + (1 : Int)) else (x).next)})
def runWord (q : Scan) : Prop := (((q).slot > (q).fs) ∨ ((((q).word % (2 : Int)) = (1 : Int)) ↔ (root ((q).bitmap) ((q).slot))))
def runCoverage (q : Scan) : Prop := (((q).slot ≥ (1 : Int)) ∧ ((q).slot ≤ ((q).fs + (1 : Int))) ∧ (((q).fs = (0 : Int)) → ((q).next = (0 : Int))) ∧ (((q).fs > (0 : Int)) → ((q).next ≤ (((q).fs - (1 : Int)) / (q).scanWidth))) ∧ ((q).scanWidth > (0 : Int)) ∧ ((q).delivered = (fun i : Int => ((fun i : Int => (1 : Int)≤i ∧ i≤((if (((q).mode = (1 : Int)) ∨ ((q).mode = (2 : Int))) then (q).first else (q).slot) - (1 : Int)))) i ∧ (eligible (q) (i)))) ∧ ((((q).mode = (1 : Int)) ∨ ((q).mode = (2 : Int))) → (((q).first ≥ (1 : Int)) ∧ ((q).first ≤ (q).slot) ∧ (∀ i : Int, ((fun i : Int => (q).first≤i ∧ i≤((q).slot - (1 : Int)))) i → (eligible (q) (i))))) ∧ (((q).mode = (2 : Int)) → (((q).past = (q).slot) ∧ ((q).first < (q).past) ∧ (((q).slot > (q).fs) ∨ (¬(eligible (q) ((q).slot)))))) ∧ (((q).mode = (3 : Int)) → ((q).delivered = (fun i : Int => ((fun i : Int => (1 : Int)≤i ∧ i≤(q).fs)) i ∧ (eligible (q) (i))))) ∧ (¬(((q).delivered) (q).excluded)))
def runCurrent (q : Scan) : Prop := (((q).mode ≥ (0 : Int)) ∧ ((q).mode ≤ (3 : Int)) ∧ (((q).mode = (1 : Int)) → (((q).slot ≤ (q).fs) ∧ (eligible (q) ((q).slot)))) ∧ (((q).mode = (3 : Int)) → ((q).slot = ((q).fs + (1 : Int)))))
def runSafe (q : Scan) : Prop := (((runWord q) ∧ (runCoverage q)) ∧ (runCurrent q))
def runNext (q : Scan) : Scan := (if ((q).mode = (0 : Int)) then (if ((q).slot > (q).fs) then {q with mode:=(3 : Int)} else (if ((((q).word % (2 : Int)) = (1 : Int)) ∧ ((q).slot ≠ (q).excluded)) then {{q with mode:=(1 : Int)} with first:=(q).slot} else (advanceCursor (q)))) else (if ((q).mode = (1 : Int)) then (let a := (advanceCursor (q)); (let keep := ((((a).slot ≤ (a).fs) ∧ (((a).word % (2 : Int)) = (1 : Int))) ∧ ((a).slot ≠ (a).excluded)); (if keep then a else {{a with mode:=(2 : Int)} with past:=(a).slot}))) else (if ((q).mode = (2 : Int)) then {{{q with mode:=(0 : Int)} with delivered:=(fun i : Int => ((q).delivered) i ∨ ((fun i : Int => (q).first≤i ∧ i≤((q).past - (1 : Int)))) i)} with runs:=((q).runs + (1 : Int))} else q)))
end
end Gambit.FrameCursorAst
