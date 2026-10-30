import PutObjsCustodyAst
import ThreadCacheTailAst
open PutObjsCustodyAst
def BeforeMirror (q : State) (r : ThreadCacheTailAst.State) : Prop := q.phase=12 → r.phase=4 ∧ r.count=1201 ∧ r.shared=0
theorem coarseCredits (q : State) (r : ThreadCacheTailAst.State) (g : publishReceiptGuard q) (hm : BeforeMirror q r) : (ThreadCacheTailAst.helperFlush800Next r).count=401 ∧ (ThreadCacheTailAst.helperFlush800Next r).shared=800 := by
 simp only [publishReceiptGuard] at g
 simp only [BeforeMirror] at hm
 simp only [ThreadCacheTailAst.helperFlush800Next]
 trace_state
 constructor <;> first | rfl | omega
