// Admission companion; scheduling remains owned by the existing phase service.
module link_product_admission {
 type Plan={members:List[int],metadata:List[int],abi:int,tool:int}
 type State={current:Plan,snapshot:Plan,active:bool,complete:bool,selected:bool,
   generated:bool,object:bool,linkInfo:bool,success:bool,closed:bool}
 val base:Plan={members:List(0,1),metadata:List(10,20),abi:0,tool:0}
 val initial:State={current:base,snapshot:base,active:false,complete:false,selected:false,
   generated:false,object:false,linkInfo:false,success:false,closed:true}
 var s:State
 action init=s'=initial
 action start=all{not(s.active),s'={...s,snapshot:s.current,active:true}}
 action outputs=s'={...s,generated:true,object:true,linkInfo:true,success:true}
 action partial=s'={...s,generated:true,object:false,linkInfo:true,success:true}
 val admissible=s.closed and s.success and s.generated and s.object and s.linkInfo and s.snapshot==s.current
 action publish=all{s.active,admissible,s'={...s,active:false,complete:true}}
 action selectProduct=all{s.complete,admissible,s'={...s,selected:true}}
 action reorder=s'={...s,current:{...s.current,members:List(1,0)},selected:false}
 action changeMeta=s'={...s,current:{...s.current,metadata:List(20,10)},selected:false}
 action changeTool=s'={...s,current:{...s.current,tool:1},selected:false}
 action refuseOpaque=s'={...s,closed:false,selected:false}
 action unsafePublish=s'={...s,active:false,complete:true,selected:true}
 action lostReply=s'=s
 action repeatSelect=selectProduct
 val safe=not(s.selected) or (s.complete and admissible)
 run exactGroupTest=init.then(start).then(outputs).then(publish).then(selectProduct).expect(safe and s.selected)
 run partialGroupRejectsTest=init.then(start).then(partial).then(unsafePublish).expect(not(safe))
 run orderedMembersRejectsTest=init.then(start).then(outputs).then(reorder).then(unsafePublish).expect(not(safe))
 run metadataOrderRejectsTest=init.then(start).then(outputs).then(changeMeta).then(unsafePublish).expect(not(safe))
 run toolChangeRejectsTest=init.then(start).then(outputs).then(changeTool).then(unsafePublish).expect(not(safe))
 run opaqueEffectRejectsTest=init.then(start).then(outputs).then(refuseOpaque).then(unsafePublish).expect(not(safe))
 run unknownReplyKeepsProductTest=init.then(start).then(outputs).then(publish).then(lostReply).then(selectProduct).expect(safe and s.complete)
 run repeatedConsumerTest=init.then(start).then(outputs).then(publish).then(selectProduct).then(repeatSelect).expect(safe and s.selected)
}
