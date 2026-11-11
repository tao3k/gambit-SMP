module will_strong_cut {
 import will_strong_parameters.* from "./will_strong_parameters"
 // mode 0 = source control-flow abstraction; mode 1 = proposed decision cut.
 // kind 0 = movable forwarding; kind 1 = still mark. mark: 0 unseen, 1 strong, 2 weak.
 type State={mode:int,kind:int,phase:int,epoch:int,members:Set[int],registered:Set[int],willRoots:Set[int],
  allocated:bool,strong:bool,mark:int,pc:int->int,decided:Set[int],selected:Set[int],decisionEpoch:int->int,
  cut:bool,receiptEpoch:int,receiptMembers:Set[int],weakEvents:int,firstWeakDecided:Set[int],
  copyPending:Set[int],stillPending:bool,aliases:Set[int],testatorIds:int->int}
 pure val initial:State={mode:1,kind:0,phase:0,epoch:7,members:Set(0,1),registered:Set(),willRoots:Set(),
  allocated:true,strong:false,mark:0,pc:Map(0->0,1->0),decided:Set(),selected:Set(),decisionEpoch:Map(0-> -1,1-> -1),
  cut:false,receiptEpoch:-1,receiptMembers:Set(),weakEvents:0,firstWeakDecided:Set(),copyPending:Set(),stillPending:false,aliases:Set(),testatorIds:Map(0->99,1->99)}
 var s:State
 action init=s'=initial
 action initOther=s'={...initial,kind:1}
 action initSource=s'={...initial,mode:0}
 action initSourceStill=s'={...initial,mode:0,kind:1}
 action initStrong=s'={...initial,strong:true}
 action initImmediate=s'={...initial,allocated:false}
 action register(p)=all {s.phase==0,s.members.contains(p),not(s.registered.contains(p)),
  s'={...s,registered:s.registered.union(Set(p)),willRoots:s.willRoots.union(Set(p))}}
 // Qualified strong closure: both wills rooted, their action closures do not capture testator.
 action strongClose=all {s.phase==0,s.registered==s.members,s.willRoots==s.members,
  s'={...s,phase:1,mark:if(s.strong and s.allocated) 1 else 0}}
 action classify(p)=all {s.phase==1,s.members.contains(p),s.pc.get(p)==0,not(s.cut),
  s'={...s,pc:s.pc.set(p,1),decided:s.decided.union(Set(p)),decisionEpoch:s.decisionEpoch.set(p,s.epoch),
   selected:if(s.allocated and s.mark==0) s.selected.union(Set(p)) else s.selected}}
 action sealCut=all {s.mode==1,s.phase==1,s.decided==s.members,s.weakEvents==0,not(s.cut),
  s.members.forall(p=>s.decisionEpoch.get(p)==s.epoch),
  s'={...s,cut:true,receiptEpoch:s.epoch,receiptMembers:s.members}}
 // Direct source seam: process_wills local decision -> mark_array(testator) -> weak closure.
 action publishWeak(p)=all {s.phase==1,s.members.contains(p),s.pc.get(p)==1,
  s.mode==0 or (s.cut and s.receiptEpoch==s.epoch and s.receiptMembers==s.members),
  s'={...s,pc:s.pc.set(p,2),mark:if(s.allocated and s.mark==0) 2 else s.mark,weakEvents:s.weakEvents+1,
   firstWeakDecided:if(s.weakEvents==0) s.decided else s.firstWeakDecided,
   copyPending:if(s.allocated and s.mark==0 and s.kind==0) s.copyPending.union(Set(p)) else s.copyPending,
   stillPending:s.stillPending or (s.allocated and s.mark==0 and s.kind==1),
   aliases:if(s.allocated) s.aliases.union(Set(p)) else s.aliases}}
 action finishCopy(p)=all {s.copyPending.contains(p),s'={...s,copyPending:s.copyPending.exclude(Set(p))}}
 action drainStill=all {s.stillPending,s'={...s,stillPending:false}}
 action complete=all {s.phase==1,s.members.forall(p=>s.pc.get(p)==2),s.copyPending==Set(),not(s.stillPending),s'={...s,phase:2}}
 def expected=if(s.allocated and not(s.strong)) s.members else Set()
 def semanticSafe=(s.decided==s.members implies s.selected==expected)
 def structuralSafe=s.registered.subseteq(s.members) and s.willRoots==s.registered and s.selected.subseteq(s.decided) and
  s.decided.subseteq(s.members) and s.copyPending.subseteq(s.aliases) and
  s.members.forall(p=>s.testatorIds.get(p)==99 and (s.decided.contains(p) implies s.decisionEpoch.get(p)==s.epoch)) and
  (s.phase==2 implies s.members.forall(p=>s.pc.get(p)==2) and s.copyPending==Set() and not(s.stillPending))
 def cutSafe=(s.cut implies s.decided==s.members and s.receiptMembers==s.members and s.receiptEpoch==s.epoch) and
  (s.mode==1 and s.weakEvents>0 implies s.cut and s.firstWeakDecided==s.members)
 def safe=structuralSafe and (s.mode==1 implies cutSafe and semanticSafe)
 action step={nondet p=0.to(WorkspaceCount-1).oneOf();any {register(p),strongClose,classify(p),sealCut,publishWeak(p),finishCopy(p),drainStill,complete,s'=s}}
 // Deterministic source replay: publisher's full copy/scan completes before the late read.
 action sourceWitnessStep=any {
  all {s.phase==0,not(s.registered.contains(0)),register(0)},
  all {s.phase==0,s.registered==Set(0),register(1)},
  all {s.phase==0,s.registered==s.members,strongClose},
  all {s.phase==1,s.pc.get(0)==0,classify(0)},
  all {s.phase==1,s.pc.get(0)==1,publishWeak(0)},
  all {s.phase==1,s.copyPending.contains(0),finishCopy(0)},
  all {s.phase==1,s.stillPending,drainStill},
  all {s.phase==1,s.pc.get(0)==2,s.copyPending==Set(),not(s.stillPending),s.pc.get(1)==0,classify(1)},
  all {s.phase==1,s.pc.get(1)==1,publishWeak(1)},
  complete
 }
 action setup=register(0).then(register(1)).then(strongClose)
 action modernClassify=classify(0).then(classify(1)).then(sealCut)
 action race=classify(0).then(publishWeak(0)).then(finishCopy(0)).then(classify(1)).then(publishWeak(1)).then(complete)
 action stillRace=classify(0).then(publishWeak(0)).then(drainStill).then(classify(1)).then(publishWeak(1)).then(complete)
 action forceSeal=s'={...s,cut:true,receiptEpoch:s.epoch,receiptMembers:s.members}
 action staleReceipt=s'={...s,receiptEpoch:s.epoch-1}
 action omitMember=s'={...s,receiptMembers:Set(0)}
 action forceComplete=s'={...s,phase:2}
 action loseDecision=s'={...s,selected:s.selected.exclude(Set(1))}
 action crossVmAlias=s'={...s,testatorIds:s.testatorIds.set(1,100)}
 action weakWithoutCut=s'={...s,weakEvents:1,firstWeakDecided:s.decided}
 run sourceMovableWitnessTest=initSource.then(setup).then(race).expect(structuralSafe and not(semanticSafe) and s.selected==Set(0))
 run sourceStillWitnessTest=initSourceStill.then(setup).then(stillRace).expect(structuralSafe and not(semanticSafe) and s.selected==Set(0))
 run sourceBothDecideFirstTest=initSource.then(setup).then(classify(0)).then(classify(1)).then(publishWeak(0)).then(finishCopy(0)).then(publishWeak(1)).then(complete).expect(structuralSafe and semanticSafe and s.selected==Set(0,1))
 run modernMovableTest=init.then(setup).then(modernClassify).then(publishWeak(0)).then(finishCopy(0)).then(publishWeak(1)).then(complete).expect(safe and semanticSafe)
 run modernStillTest=initOther.then(setup).then(modernClassify).then(publishWeak(1)).then(drainStill).then(publishWeak(0)).then(complete).expect(safe and semanticSafe)
 run reverseDecisionTest=init.then(setup).then(classify(1)).then(classify(0)).then(sealCut).then(publishWeak(1)).then(finishCopy(1)).then(publishWeak(0)).then(complete).expect(safe and s.selected==Set(0,1))
 run strongTestatorTest=initStrong.then(setup).then(modernClassify).then(publishWeak(0)).then(publishWeak(1)).then(complete).expect(safe and s.selected==Set())
 run immediateTestatorTest=initImmediate.then(setup).then(modernClassify).then(publishWeak(0)).then(publishWeak(1)).then(complete).expect(safe and s.selected==Set())
 run copyStillPendingTest=init.then(setup).then(modernClassify).then(publishWeak(0)).expect(safe and s.copyPending==Set(0))
 run strongBarrierAloneTest=initSource.then(setup).then(race).expect(not(semanticSafe) and s.firstWeakDecided==Set(0))
 run partialDecisionControlTest=init.then(setup).then(classify(0)).then(forceSeal).expect(not(safe))
 run staleEpochControlTest=init.then(setup).then(modernClassify).then(staleReceipt).expect(not(safe))
 run missingDomainControlTest=init.then(setup).then(modernClassify).then(omitMember).expect(not(safe))
 run uninitializedWorkerControlTest=init.then(register(0)).then(forceComplete).expect(not(safe))
 run unfinishedCopyControlTest=init.then(setup).then(modernClassify).then(publishWeak(0)).then(publishWeak(1)).then(forceComplete).expect(not(safe))
 run unfinishedStillControlTest=initOther.then(setup).then(modernClassify).then(publishWeak(0)).then(publishWeak(1)).then(forceComplete).expect(not(safe))
 run changedClassificationControlTest=init.then(setup).then(modernClassify).then(loseDecision).expect(not(safe))
 run wrongTestatorIdentityControlTest=init.then(setup).then(crossVmAlias).expect(not(safe))
 run publicationWithoutCutControlTest=init.then(setup).then(classify(0)).then(weakWithoutCut).expect(not(safe))
}
