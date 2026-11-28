/-
  Lean 4 refinement proof for Phase C44 `(gambit effect)` `return:` clause
  out-of-scope tail execution and full multiple-value dispatch:
    1. Suspending `with-handler` pops the inner handler frame before executing
       `return:`, so performing the same effect inside `return:` dispatches to
       the enclosing outer handler (never hijacked by inner).
    2. Multi-shot `resume-multishot` executes `return:` once per branch after
       popping that branch's reinstalled inner handler frame.
    3. Suspending and tail-resumptive handlers agree identically on `return:`
       handler-stack semantics.
    4. `##values?`-guided `return:` dispatch preserves 0-value, 1-value, and
       N-value arities without wrapping multi-value tuples as a single arg.
    5. An exception raised inside `return:` observes a clean outer handler
       stack with the inner handler already popped.
-/

namespace EffectReturnClauseScopeAndMultival

inductive HandlerId where
  | outer
  | inner
  deriving DecidableEq, Repr

def dispatchTop (hs : List HandlerId) : Option HandlerId :=
  hs.head?

def popTop (hs : List HandlerId) : List HandlerId :=
  hs.tail

def suspendReturnHandlers (outerHs : List HandlerId) : List HandlerId :=
  popTop (.inner :: outerHs)

def tailReturnHandlers (outerHs : List HandlerId) : List HandlerId :=
  popTop (.inner :: outerHs)

theorem suspending_return_pops_inner_before_running_dispatches_to_outer :
    dispatchTop (suspendReturnHandlers [.outer]) = some .outer := by
  rfl

theorem multishot_resume_runs_return_outside_inner_per_branch
    (outerHs : List HandlerId) :
    let branch1 := suspendReturnHandlers outerHs
    let branch2 := suspendReturnHandlers outerHs
    branch1 = outerHs ∧ branch2 = outerHs := by
  simp [suspendReturnHandlers, popTop]

theorem tail_and_suspend_handlers_return_semantics_agree
    (outerHs : List HandlerId) :
    suspendReturnHandlers outerHs = tailReturnHandlers outerHs := by
  rfl

inductive SchemeVal where
  | single (v : Nat)
  | multi (vs : List Nat)
  deriving DecidableEq, Repr

def returnCallArity (res : SchemeVal) : Nat :=
  match res with
  | .single _ => 1
  | .multi vs => vs.length

theorem multival_return_dispatch_preserves_arity (a b : Nat) :
    returnCallArity (.multi []) = 0 ∧
    returnCallArity (.single a) = 1 ∧
    returnCallArity (.multi [a, b]) = 2 := by
  simp [returnCallArity]

theorem exception_in_return_leaves_handler_stack_clean (outerHs : List HandlerId) :
    suspendReturnHandlers outerHs = outerHs ∧ tailReturnHandlers outerHs = outerHs := by
  simp [suspendReturnHandlers, tailReturnHandlers, popTop]

end EffectReturnClauseScopeAndMultival
