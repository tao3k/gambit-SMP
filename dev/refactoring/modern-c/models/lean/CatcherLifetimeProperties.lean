import CatcherSettlementAst
namespace CatcherSettlement
open CatcherSettlementAst
set_option maxRecDepth 10000
theorem preReturnFrameLive (q : State) (h : Safe q) (g : q.phase=8) : q.targetActive=1 ∧ q.receipt=0 := by
 grind [Safe]
theorem nativeBorrowFresh (q : State) (h : Safe q) (g : q.borrow=1) : q.cache=q.slot ∧ q.reader=0 ∧ q.root=1 ∧ q.copyReady=1 := by
 grind [Safe]
theorem unreadyObjectHasCustodian (q : State) (h : Safe q) (g : q.copyReady=0) : q.reader=1 ∧ q.borrow=0 ∧ q.critical=0 ∧ q.root=1 ∧ q.descriptor=1 := by
 grind [Safe]
theorem partialCopyNotExposed (q : State) (h : Safe q) (g : q.scanStage=1) : q.reader=1 ∧ q.borrow=0 ∧ q.shotActive=1 := by
 grind [Safe]
theorem resumedSlotCoherent (q : State) (h : Safe q) (g : q.shotActive=1 ∧ q.reader=0) : q.contextSlot=q.slot := by
 grind [Safe]
theorem retirementCut (q : State) (h : Safe q) (g : q.descriptor=0) : q.rootRetired=1 ∧ q.captured=0 ∧ q.reader=0 ∧ q.doneI=1 ∧ q.doneO=1 ∧ q.targetActive=0 := by
 grind [Safe]
theorem captureKeepsDescriptor (q : State) (h : Safe q) (g : q.captured=1) : q.descriptor=1 ∧ q.root=1 := by
 grind [Safe]
theorem queryInnerDoesNotReplay (q : State) : (queryInnerReleaseNext q).effectsI=q.effectsI ∧ (queryInnerReleaseNext q).refI=q.refI := by constructor <;> rfl
theorem queryOuterDoesNotReplay (q : State) : (queryOuterReleaseNext q).effectsO=q.effectsO ∧ (queryOuterReleaseNext q).refO=q.refO := by constructor <;> rfl

end CatcherSettlement
