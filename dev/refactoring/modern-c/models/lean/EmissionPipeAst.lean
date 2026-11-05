import Std
namespace EmissionPipeAst
set_option maxRecDepth 10000
structure State where
 ep : Int
 profile : Int
 demand : Int
 epoch : Int
 planEpoch : Int
 certEpoch : Int
 outputCalls : Int
 pc : Int
 wlo : Int
 whi : Int
 rlo : Int
 rhi : Int
 emitted : Int
 delivered : Int
 index : Int
 savedIndex : Int
 wgen : Int
 rgen : Int
 resumes : Int
 completed : Int
 writer : Int
 savedWriter : Int
 unknown : Bool
 fault : Bool
 attested : Bool
 certificate : Bool
 special : Bool
 shared : Bool
 locked : Bool
 captured : Bool
 custody : Bool
 clobbered : Bool
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.ep≥(0)) ∧ (q.ep≤(6)) ∧ (q.profile≥(0)) ∧ (q.profile≤(2)) ∧ (q.demand≥(0)) ∧ (q.demand≤(2)) ∧ (q.epoch≥(1)) ∧ (q.planEpoch≥(1)) ∧ (q.certEpoch≥(0)) ∧ (q.outputCalls≥(0)) ∧ (¬(q.special=true)) ∧ ((q.certificate=true) → (((((((((q.ep=(4)) ∨ (q.ep=(5))) ∧ (q.attested=true)) ∧ (q.profile≤(1))) ∧ (q.demand=(1))) ∧ (q.epoch=q.planEpoch)) ∧ (q.certEpoch=q.epoch)) ∧ (¬(q.unknown=true))) ∧ (¬(q.fault=true)))) ∧ (q.pc≥(0)) ∧ (q.pc≤(5)) ∧ (q.wlo≥(0)) ∧ (q.wlo≤(32)) ∧ (q.whi≥(0)) ∧ (q.whi≤(32)) ∧ (q.rlo≥(0)) ∧ (q.rlo≤q.rhi) ∧ (q.rhi≤(32)) ∧ (q.emitted≥(0)) ∧ (q.delivered≥(0)) ∧ ((q.emitted-q.delivered)=((q.wlo+q.whi)-q.rlo)) ∧ (q.emitted≥q.delivered) ∧ (q.savedIndex=(58)) ∧ ((q.index=(58)) ∨ (q.index=(80))) ∧ (q.wgen≥(1)) ∧ (q.rgen≥(0)) ∧ (q.rgen<(q.wgen+(1))) ∧ ((q.shared=true) → (((q.wlo=(0)) ∧ (q.rhi≤q.whi)) ∧ (q.rgen=q.wgen))) ∧ ((¬(q.shared=true)) → ((q.wlo=q.rhi) ∧ (q.rgen<q.wgen))) ∧ (q.resumes≥(0)) ∧ (q.completed≥(0)) ∧ (q.completed≤q.resumes) ∧ ((((q.pc=(2)) ∨ (q.pc=(3))) ∨ (q.pc=(4))) → ((q.completed+(1))=q.resumes)) ∧ ((((q.pc=(0)) ∨ (q.pc=(1))) ∨ (q.pc=(5))) → (q.completed=q.resumes)) ∧ (q.writer≥(0)) ∧ (q.writer≤(2)) ∧ (q.savedWriter=(1)) ∧ ((q.pc≥(1)) → ((q.captured=true) ∧ (q.custody=true))) ∧ ((q.pc=(1)) → (((q.whi=(32)) ∧ (q.index=(58))) ∧ (¬(q.locked=true)))) ∧ ((q.pc=(2)) → (((((q.shared=true) ∧ (q.rlo=q.whi)) ∧ (q.rhi=q.whi)) ∧ (q.locked=true)) ∧ (q.index=(58)))) ∧ ((q.pc=(3)) → ((((¬(q.shared=true)) ∧ (q.whi=(0))) ∧ (q.locked=true)) ∧ (q.index=(58)))) ∧ ((q.pc=(4)) → ((((¬(q.shared=true)) ∧ (q.whi=(23))) ∧ (q.locked=true)) ∧ (q.index=(80)))) ∧ ((q.pc=(5)) → (((q.whi=(23)) ∧ (q.index=(80))) ∧ (¬(q.locked=true)))) ∧ ((q.pc=(0)) → (¬(q.locked=true))) ∧ ((q.pc=(0)) → (((((((((((q.emitted=(0)) ∧ (q.delivered=(0))) ∧ (q.wlo=(0))) ∧ (q.whi=(0))) ∧ (q.rlo=(0))) ∧ (q.rhi=(0))) ∧ (q.resumes=(0))) ∧ (q.completed=(0))) ∧ (q.rgen=(0))) ∧ (q.wgen=(1))) ∧ (q.index=(58)))))
def initial : State := {ep:=(0), profile:=(0), demand:=(0), epoch:=(1), planEpoch:=(1), certEpoch:=(0), outputCalls:=(0), pc:=(0), wlo:=(0), whi:=(0), rlo:=(0), rhi:=(0), emitted:=(0), delivered:=(0), index:=(58), savedIndex:=(58), wgen:=(1), rgen:=(0), resumes:=(0), completed:=(0), writer:=(1), savedWriter:=(1), unknown:=false, fault:=false, attested:=false, certificate:=false, special:=false, shared:=false, locked:=false, captured:=false, custody:=false, clobbered:=false}
def firstGuard (q : State) : Prop := (q.ep=(0))
def firstNext (q : State) : State := {q with ep:=(1), demand:=(1), planEpoch:=q.epoch}
def selectDebugGuard (q : State) : Prop := (q.ep=(0))
def selectDebugNext (q : State) : State := {q with profile:=(1)}
def selectCustomGuard (q : State) : Prop := (q.ep=(0))
def selectCustomNext (q : State) : State := {q with profile:=(2)}
def prmRemainderGuard (q : State) : Prop := (q.ep=(1))
def prmRemainderNext (q : State) : State := {q with ep:=(2)}
def initTextGuard (q : State) : Prop := (q.ep=(2))
def initTextNext (q : State) : State := {q with ep:=(3)}
def gloPrefixGuard (q : State) : Prop := (q.ep=(3))
def gloPrefixNext (q : State) : State := {q with ep:=(4)}
def scalarDispatchGuard (q : State) : Prop := (q.ep≥(1)) ∧ (q.ep≤(4))
def scalarDispatchNext (q : State) : State := {q with outputCalls:=(q.outputCalls+(1))}
def namedEffectGuard (q : State) : Prop := (q.ep≥(1)) ∧ (q.ep≤(4))
def namedEffectNext (q : State) : State := {q with demand:=(1)}
def customRawGuard (q : State) : Prop := (q.ep≥(1)) ∧ (q.ep≤(4)) ∧ (q.profile=(2))
def customRawNext (q : State) : State := {q with demand:=(2), attested:=false, certificate:=false}
def replaceEntryGuard (q : State) : Prop := (q.ep≥(1)) ∧ (q.ep≤(4))
def replaceEntryNext (q : State) : State := {q with epoch:=(q.epoch+(1)), demand:=(0), attested:=false, certificate:=false}
def unknownEffectGuard (q : State) : Prop := (q.ep≥(1)) ∧ (q.ep≤(4))
def unknownEffectNext (q : State) : State := {q with unknown:=true, attested:=false, certificate:=false}
def ioAbortGuard (q : State) : Prop := (q.ep≥(1)) ∧ (q.ep≤(4))
def ioAbortNext (q : State) : State := {q with ep:=(6), fault:=true, attested:=false, certificate:=false}
def attestGuard (q : State) : Prop := (q.ep=(4)) ∧ (q.profile≤(1)) ∧ (q.demand=(1)) ∧ (q.epoch=q.planEpoch) ∧ (¬(q.unknown=true)) ∧ (¬(q.fault=true))
def attestNext (q : State) : State := {q with attested:=true}
def issueGuard (q : State) : Prop := (q.ep=(4)) ∧ (q.profile≤(1)) ∧ (q.demand=(1)) ∧ (q.epoch=q.planEpoch) ∧ (¬(q.unknown=true)) ∧ (¬(q.fault=true)) ∧ (q.attested=true)
def issueNext (q : State) : State := {q with certificate:=true, certEpoch:=q.epoch}
def secondGuard (q : State) : Prop := (q.ep=(4))
def secondNext (q : State) : State := {q with ep:=(5), demand:=(1)}
def omitSecondGuard (q : State) : Prop := (q.ep=(4)) ∧ (q.certificate=true)
def omitSecondNext (q : State) : State := {q with ep:=(5)}
def pauseGuard (q : State) : Prop := (q.pc=(0))
def pauseNext (q : State) : State := {q with pc:=(1), wlo:=(32), whi:=(32), rlo:=(0), rhi:=(32), emitted:=(64), captured:=true, custody:=true, writer:=(0), wgen:=(2), rgen:=(1)}
def readChunkGuard (q : State) : Prop := (q.pc=(1)) ∧ (¬(q.shared=true)) ∧ (q.rlo<q.rhi)
def readChunkNext (q : State) : State := {q with delivered:=((q.delivered+q.rhi)-q.rlo), rlo:=q.rhi}
def advanceReaderGuard (q : State) : Prop := ((q.pc=(1)) ∨ (q.pc=(5))) ∧ (¬(q.shared=true)) ∧ (q.rlo=q.rhi)
def advanceReaderNext (q : State) : State := {q with wlo:=(q.wlo-q.rlo), rlo:=(0), rhi:=(0), shared:=true, rgen:=q.wgen}
def exposeWriterGuard (q : State) : Prop := ((q.pc=(1)) ∨ (q.pc=(5))) ∧ (q.shared=true) ∧ (q.rhi<q.whi)
def exposeWriterNext (q : State) : State := {q with rhi:=q.whi}
def consumeWriterGuard (q : State) : Prop := ((q.pc=(1)) ∨ (q.pc=(5))) ∧ (q.shared=true) ∧ (q.rlo<q.rhi)
def consumeWriterNext (q : State) : State := {q with delivered:=((q.delivered+q.rhi)-q.rlo), rlo:=q.rhi}
def resumeGuard (q : State) : Prop := ((q.pc=(1)) ∨ (q.pc=(5))) ∧ (q.shared=true) ∧ (q.rlo=q.whi) ∧ (q.captured=true) ∧ (q.custody=true)
def resumeNext (q : State) : State := {q with pc:=(2), locked:=true, index:=q.savedIndex, resumes:=(q.resumes+(1))}
def publishGuard (q : State) : Prop := (q.pc=(2)) ∧ (q.locked=true) ∧ (q.shared=true) ∧ ((q.wlo-q.rlo)≤(1))
def publishNext (q : State) : State := {q with pc:=(3), wlo:=(q.wlo+q.whi), whi:=(0), shared:=false, wgen:=(q.wgen+(1))}
def appendTailGuard (q : State) : Prop := (q.pc=(3)) ∧ (q.index=(58)) ∧ (q.whi=(0))
def appendTailNext (q : State) : State := {q with pc:=(4), index:=(80), whi:=(23), emitted:=(q.emitted+(23))}
def finishGuard (q : State) : Prop := (q.pc=(4))
def finishNext (q : State) : State := {q with pc:=(5), locked:=false, writer:=q.savedWriter, completed:=(q.completed+(1)), clobbered:=(decide ((q.clobbered=true) ∨ (q.writer=(2))))}
def installNewGuard (q : State) : Prop := ((q.pc=(1)) ∨ (q.pc=(5)))
def installNewNext (q : State) : State := {q with writer:=(2)}
def Step (q r : State) : Prop := (firstGuard q ∧ r=firstNext q) ∨ (selectDebugGuard q ∧ r=selectDebugNext q) ∨ (selectCustomGuard q ∧ r=selectCustomNext q) ∨ (prmRemainderGuard q ∧ r=prmRemainderNext q) ∨ (initTextGuard q ∧ r=initTextNext q) ∨ (gloPrefixGuard q ∧ r=gloPrefixNext q) ∨ (scalarDispatchGuard q ∧ r=scalarDispatchNext q) ∨ (namedEffectGuard q ∧ r=namedEffectNext q) ∨ (customRawGuard q ∧ r=customRawNext q) ∨ (replaceEntryGuard q ∧ r=replaceEntryNext q) ∨ (unknownEffectGuard q ∧ r=unknownEffectNext q) ∨ (ioAbortGuard q ∧ r=ioAbortNext q) ∨ (attestGuard q ∧ r=attestNext q) ∨ (issueGuard q ∧ r=issueNext q) ∨ (secondGuard q ∧ r=secondNext q) ∨ (omitSecondGuard q ∧ r=omitSecondNext q) ∨ (pauseGuard q ∧ r=pauseNext q) ∨ (readChunkGuard q ∧ r=readChunkNext q) ∨ (advanceReaderGuard q ∧ r=advanceReaderNext q) ∨ (exposeWriterGuard q ∧ r=exposeWriterNext q) ∨ (consumeWriterGuard q ∧ r=consumeWriterNext q) ∨ (resumeGuard q ∧ r=resumeNext q) ∨ (publishGuard q ∧ r=publishNext q) ∨ (appendTailGuard q ∧ r=appendTailNext q) ∨ (finishGuard q ∧ r=finishNext q) ∨ (installNewGuard q ∧ r=installNewNext q) ∨ r=q
end EmissionPipeAst
