import CatcherSettlementAst
namespace CatcherSettlement
open CatcherSettlementAst
set_option maxRecDepth 10000
theorem partialKeepsOriginal (q : State) (h : Safe q) (g : q.escrow=0) : q.root=1 ∧ q.descriptor=1 ∧ q.refI=1 ∧ q.refO=1 ∧ q.validI=1 := by
 grind [Safe]
theorem landingIssuerCut (q : State) (h : Safe q) (g : q.receipt=1) : q.caught=1 ∧ q.current=0 ∧ q.issued=1 ∧ q.validated=1 ∧ q.errorClass=1 := by
 grind [Safe]
theorem transitHasNoReceipt (q : State) (h : Safe q) (g : q.phase=6) : q.receipt=0 ∧ q.caught=2 ∧ q.current=1 := by
 grind [Safe]
theorem innerGapHasCustodian (q : State) (h : Safe q) (g : q.phase=10) : q.critical=1 ∧ q.borrow=1 ∧ q.refI=0 ∧ q.doneI=0 ∧ q.reader=0 := by
 grind [Safe]
theorem outerGapHasCustodian (q : State) (h : Safe q) (g : q.phase=12) : q.critical=2 ∧ q.borrow=1 ∧ q.refO=0 ∧ q.doneO=0 := by
 grind [Safe]
theorem innerExactlyOnce (q : State) (h : Safe q) (g : q.doneI=1) : q.effectsI=1 ∧ q.refI=0 ∧ q.receipt=1 := by
 grind [Safe]
theorem outerAfterInner (q : State) (h : Safe q) (g : q.doneO=1) : q.doneI=1 ∧ q.effectsO=1 ∧ q.refO=0 ∧ q.targetActive=0 := by
 grind [Safe]

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
