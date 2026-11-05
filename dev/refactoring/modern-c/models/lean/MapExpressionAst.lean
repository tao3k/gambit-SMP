import RetiOfdSemantics
namespace MapExpressionAst
open MapFrameAbi RetiOfdSemantics
-- GENERATED from official typed IR of SHA256 1b1bc0dfcd46172f19806bdd4780d1ce41461b4ac54456f0536d6bb5ea8d87e7
def initialAst : List Update := [(.int .cb (.lit (7))), (.int .rc (.lit (9))), (.int .fs (.lit (5))), (.int .link (.lit (0))), (.bool .captured (.lit false)), (.bool .root (.lit false)), (.bool .pin (.lit false)), (.bool .running (.lit false)), (.int .epoch (.lit (0))), (.int .loaded (.lit (0))), (.int .shots (.lit (0))), (.int .frameAbi (.lit (1))), (.int .runtimeAbi (.lit (1))), (.int .abi (.lit (1))), (.int .emitAbi (.lit (1))), (.int .objAbi (.lit (1))), (.bool .emitted (.lit true)), (.bool .native (.lit true)), (.int .tool (.lit (1))), (.int .objTool (.lit (1)))]
def safeAst : BExpr := (.conj (.eqI (.get .cb) (.lit (7))) (.conj (.eqI (.get .rc) (.lit (9))) (.conj (.eqI (.get .fs) (.lit (5))) (.conj (.eqI (.get .link) (.lit (0))) (.conj (.le (.lit (0)) (.get .shots)) (.conj (.le (.get .shots) (.lit (3))) (.conj (.implies (.truth (.get .captured)) (.conj (.conj (.truth (.get .root)) (.truth (.get .pin))) (.eqI (.get .frameAbi) (.get .runtimeAbi)))) (.conj (.implies (.truth (.get .running)) (.conj (.truth (.get .captured)) (.eqI (.get .loaded) (.get .epoch)))) (.conj (.implies (.truth (.get .emitted)) (.eqI (.get .emitAbi) (.get .abi))) (.conj (.implies (.truth (.get .native)) (.conj (.conj (.truth (.get .emitted)) (.eqI (.get .objAbi) (.get .abi))) (.eqI (.get .objTool) (.get .tool)))) (.truth (.lit true))))))))))))
def a_capture : Action := (.atom (.conj (.neg (.truth (.get .captured))) (.conj (.neg (.truth (.get .running))) (.truth (.lit true)))) [(.bool .captured (.lit true)), (.bool .root (.lit true)), (.bool .pin (.lit true)), (.int .frameAbi (.get .runtimeAbi)), (.int .shots (.lit (0)))])
def a_collect : Action := (.atom (.conj (.truth (.get .captured)) (.conj (.truth (.get .root)) (.conj (.neg (.truth (.get .running))) (.truth (.lit true))))) [(.int .epoch (.add (.get .epoch) (.lit (1))))])
def a_reload : Action := (.atom (.conj (.neg (.truth (.get .running))) (.truth (.lit true))) [(.int .loaded (.get .epoch))])
def a_resume : Action := (.atom (.conj (.truth (.get .captured)) (.conj (.truth (.get .root)) (.conj (.truth (.get .pin)) (.conj (.neg (.truth (.get .running))) (.conj (.eqI (.get .loaded) (.get .epoch)) (.conj (.lt (.get .shots) (.lit (3))) (.truth (.lit true)))))))) [(.bool .running (.lit true)), (.int .shots (.add (.get .shots) (.lit (1))))])
def a_returnShot : Action := (.atom (.conj (.truth (.get .running)) (.truth (.lit true))) [(.bool .running (.lit false))])
def a_abiEdit : Action := (.atom (.conj (.truth (.lit true)) (.truth (.lit true))) [(.int .abi (.add (.get .abi) (.lit (1)))), (.bool .emitted (.lit false)), (.bool .native (.lit false))])
def a_emit : Action := (.atom (.conj (.truth (.lit true)) (.truth (.lit true))) [(.int .emitAbi (.get .abi)), (.bool .emitted (.lit true)), (.bool .native (.lit false))])
def a_compile : Action := (.atom (.conj (.truth (.get .emitted)) (.truth (.lit true))) [(.int .objAbi (.get .emitAbi)), (.int .objTool (.get .tool)), (.bool .native (.lit true))])
def a_toolEdit : Action := (.atom (.conj (.truth (.lit true)) (.truth (.lit true))) [(.int .tool (.add (.get .tool) (.lit (1)))), (.bool .native (.lit false))])
def a_bind : Action := (.atom (.conj (.truth (.get .native)) (.conj (.neg (.truth (.get .captured))) (.conj (.neg (.truth (.get .running))) (.truth (.lit true))))) [(.int .runtimeAbi (.get .abi))])
def a_releaseCaptured : Action := (.atom (.conj (.truth (.get .captured)) (.conj (.neg (.truth (.get .running))) (.truth (.lit true)))) [(.bool .captured (.lit false)), (.bool .root (.lit false)), (.bool .pin (.lit false))])
def a_stutter : Action := (.atom (.truth (.lit true)) [])
def stepAst : Action := (.choice a_capture (.choice a_collect (.choice a_reload (.choice a_resume (.choice a_returnShot (.choice a_abiEdit (.choice a_emit (.choice a_compile (.choice a_toolEdit (.choice a_bind (.choice a_releaseCaptured a_stutter)))))))))))
theorem captureMeaning (q q' : QState) : runAction a_capture q q' ↔ qStep .capture q q' := by
 simp [a_capture,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem collectMeaning (q q' : QState) : runAction a_collect q q' ↔ qStep .collect q q' := by
 simp [a_collect,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem reloadMeaning (q q' : QState) : runAction a_reload q q' ↔ qStep .reload q q' := by
 simp [a_reload,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem resumeMeaning (q q' : QState) : runAction a_resume q q' ↔ qStep .resume q q' := by
 simp [a_resume,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem returnShotMeaning (q q' : QState) : runAction a_returnShot q q' ↔ qStep .returnShot q q' := by
 simp [a_returnShot,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem abiEditMeaning (q q' : QState) : runAction a_abiEdit q q' ↔ qStep .abiEdit q q' := by
 simp [a_abiEdit,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem emitMeaning (q q' : QState) : runAction a_emit q q' ↔ qStep .emit q q' := by
 simp [a_emit,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem compileMeaning (q q' : QState) : runAction a_compile q q' ↔ qStep .compile q q' := by
 simp [a_compile,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem toolEditMeaning (q q' : QState) : runAction a_toolEdit q q' ↔ qStep .toolEdit q q' := by
 simp [a_toolEdit,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem bindMeaning (q q' : QState) : runAction a_bind q q' ↔ qStep .bind q q' := by
 simp [a_bind,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem releaseCapturedMeaning (q q' : QState) : runAction a_releaseCaptured q q' ↔ qStep .releaseCaptured q q' := by
 simp [a_releaseCaptured,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem stutterMeaning (q q' : QState) : runAction a_stutter q q' ↔ qStep .stutter q q' := by
 simp [a_stutter,runAction,evalB,evalBV,evalI,evalUpdates,applyUpdate,setI,setB,getI,getB,qStep,qGuard,qNext,and_assoc]
theorem invariantMeaning (q : QState) : evalB safeAst q ↔ qSafe q := by simp [safeAst,evalB,evalBV,evalI,getI,getB,qSafe,and_assoc]
theorem initialMeaning : evalUpdates initial initialAst initial=initial := by decide
theorem stepMeaning (q q' : QState) : runAction stepAst q q' ↔ ∃ e : Event, qStep e q q' := by
 change (runAction a_capture q q' ∨ runAction a_collect q q' ∨ runAction a_reload q q' ∨ runAction a_resume q q' ∨ runAction a_returnShot q q' ∨ runAction a_abiEdit q q' ∨ runAction a_emit q q' ∨ runAction a_compile q q' ∨ runAction a_toolEdit q q' ∨ runAction a_bind q q' ∨ runAction a_releaseCaptured q q' ∨ runAction a_stutter q q') ↔ ∃ e : Event, qStep e q q'
 simp only [captureMeaning,collectMeaning,reloadMeaning,resumeMeaning,returnShotMeaning,abiEditMeaning,emitMeaning,compileMeaning,toolEditMeaning,bindMeaning,releaseCapturedMeaning,stutterMeaning]
 constructor
 · intro h; rcases h with h|h|h|h|h|h|h|h|h|h|h|h
   all_goals first | exact ⟨Event.capture,h⟩ | exact ⟨Event.collect,h⟩ | exact ⟨Event.reload,h⟩ | exact ⟨Event.resume,h⟩ | exact ⟨Event.returnShot,h⟩ | exact ⟨Event.abiEdit,h⟩ | exact ⟨Event.emit,h⟩ | exact ⟨Event.compile,h⟩ | exact ⟨Event.toolEdit,h⟩ | exact ⟨Event.bind,h⟩ | exact ⟨Event.releaseCaptured,h⟩ | exact ⟨Event.stutter,h⟩
 · rintro ⟨e,h⟩; cases e <;> simp_all
theorem astToNested (q q' : QState) (h : runAction stepAst q q') : ∃ e : Event, lStep e (alpha q) (alpha q') := by
 obtain ⟨e,step⟩ := (stepMeaning q q').mp h; exact ⟨e,forwardSimulation e q q' (alpha q) rfl step⟩
theorem astPreserves (q q' : QState) (safe : evalB safeAst q) (h : runAction stepAst q q') : evalB safeAst q' := by
 obtain ⟨e,guard,next⟩ := (stepMeaning q q').mp h
 apply (invariantMeaning q').mpr; rw [next]; exact qPreserves e q ((invariantMeaning q).mp safe) guard
def simultaneous : List Update := [.int .epoch (.add (.get .epoch) (.lit 1)),.int .loaded (.get .epoch)]
theorem simultaneousReadsOld (q : QState) : (evalUpdates q simultaneous q).loaded=q.epoch := rfl
end MapExpressionAst
