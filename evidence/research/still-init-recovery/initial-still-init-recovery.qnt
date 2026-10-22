module still_init_recovery {
  // One operation, two initializer owners, a three-field body, one result slot.
  // ownedBlock8 is abstract potential backing, not native bytes. No crash recovery.
  type State={allocated:bool,prefix:int,physical:int,writes:int,busy:bool,busyGen:int,
    owner:int,gen:int,frozen:bool,transfer:bool,unknown:bool,inputRoot:bool,custody:bool,
    ready:bool,sourceRoot:bool,targetRoot:bool,offered:bool,accepted:bool,
    accepts:int,receipt:bool,sourceDone:bool,held:int,cancel:bool,atomic:bool,
    aborted:bool,retired:bool,userWrite:bool,queries:int}
  var s:State
  action init=s'={allocated:false,prefix:0,physical:0,writes:0,busy:false,busyGen:0,
    owner:0,gen:0,frozen:false,transfer:false,unknown:false,inputRoot:true,custody:true,
    ready:false,sourceRoot:false,targetRoot:false,offered:false,accepted:false,
    accepts:0,receipt:false,sourceDone:false,held:0,cancel:false,atomic:false,
    aborted:false,retired:false,userWrite:false,queries:0}
  val safe=s.prefix>=0 and s.prefix<=s.physical and s.physical<=3 and
    s.physical<=s.prefix+1 and s.writes==s.physical and s.accepts>=0 and s.accepts<=1 and
    (not(s.busy) or (s.busyGen==s.gen and not(s.frozen))) and
    (not(s.transfer) or (s.frozen and not(s.busy) and s.inputRoot and s.custody)) and
    (not(s.ready) or (s.prefix==3 and s.physical==3 and not(s.busy))) and
    (not(s.sourceRoot) or s.ready) and (not(s.targetRoot) or s.ready) and
    (not(s.accepted) or (s.targetRoot and s.ready and s.accepts==1)) and
    (not(s.allocated) or s.retired or s.held==8) and
    (not(s.unknown) or (s.held==8 and (s.custody or s.targetRoot))) and
    (not(s.allocated) or s.ready or s.retired or (s.inputRoot and s.custody)) and
    (not(s.ready) or s.retired or s.sourceRoot or s.targetRoot) and
    (not(s.sourceDone) or (s.accepted and s.receipt and s.targetRoot)) and
    (not(s.aborted) or (s.atomic and s.frozen and not(s.busy) and not(s.accepted))) and
    (not(s.retired) or (s.aborted and not(s.unknown)))
  action chooseAtomic=all{not(s.allocated),s'={...s,atomic:true}}
  action allocate=all{not(s.allocated),s'={...s,allocated:true,held:8}}
  action reserve=all{s.allocated,s.prefix<3,not(s.busy),not(s.frozen),not(s.aborted),
    s'={...s,busy:true,busyGen:s.gen}}
  action write=all{s.busy,s.physical==s.prefix,s.busyGen==s.gen,not(s.frozen),
    s'={...s,physical:s.physical+1,writes:s.writes+1}}
  action commitProgress=all{s.busy,s.physical==s.prefix+1,s.busyGen==s.gen,
    s'={...s,prefix:s.physical,busy:false}}
  action loseReply=all{s.allocated,not(s.retired),s'={...s,unknown:true}}
  action query=all{s.allocated,s.queries<2,s'={...s,unknown:false,queries:s.queries+1}}
  action freeze=all{s.allocated,not(s.busy),not(s.accepted),not(s.sourceDone),
    s'={...s,frozen:true}}
  action prepareTransfer=all{s.frozen,not(s.busy),s.owner==0,s.gen==0,not(s.aborted),
    s.inputRoot,s.custody,s'={...s,transfer:true}}
  action commitTransfer=all{s.transfer,s.frozen,not(s.busy),s.owner==0,s.gen==0,
    s'={...s,owner:1,gen:1,transfer:false,frozen:false}}
  action rejectTransfer=all{s.transfer,s'={...s,transfer:false,frozen:false}}
  action publish=all{s.allocated,s.prefix==3,not(s.busy),not(s.frozen),not(s.aborted),
    not(s.ready),s'={...s,ready:true,sourceRoot:true}}
  action offer=all{s.ready,s.sourceRoot,not(s.accepted),not(s.cancel),
    s'={...s,offered:true}}
  action accept=all{s.offered,s.ready,not(s.cancel),not(s.accepted),
    s'={...s,accepted:true,targetRoot:true,accepts:s.accepts+1}}
  action duplicateAccept=all{s.accepted,s.targetRoot,s'=s}
  action readReceipt=all{s.accepted,s.targetRoot,s'={...s,receipt:true,unknown:false}}
  action cleanupSource=all{s.accepted,s.receipt,s.targetRoot,not(s.unknown),
    s'={...s,sourceRoot:false,inputRoot:false,custody:false,sourceDone:true}}
  action mutateDelivered=all{s.accepted,s.targetRoot,s'={...s,userWrite:true}}
  action cancel=all{s.allocated,not(s.retired),s'={...s,cancel:true}}
  action withdraw=all{s.cancel,s.offered,not(s.accepted),s'={...s,offered:false}}
  action abortAtomic=all{s.atomic,s.cancel,s.frozen,not(s.busy),not(s.ready),
    not(s.offered),not(s.accepted),not(s.transfer),s'={...s,aborted:true}}
  action retireAtomic=all{s.aborted,not(s.unknown),s'={...s,retired:true,held:0,
    custody:false,inputRoot:false}}
  action stutter=s'=s
  action step=any{chooseAtomic,allocate,reserve,write,commitProgress,loseReply,query,
    freeze,prepareTransfer,commitTransfer,rejectTransfer,publish,offer,accept,
    duplicateAccept,readReceipt,cleanupSource,mutateDelivered,cancel,withdraw,
    abortAtomic,retireAtomic,stutter}
  action one=reserve.then(write).then(commitProgress)
  action fill=one.then(one).then(one).then(publish)
  run partialReadbackTest=init.then(allocate).then(one).then(loseReply).then(query).expect(safe and s.prefix==1 and s.writes==1)
  run unknownOwnerContinuesTest=init.then(allocate).then(one).then(loseReply).then(one).then(query).expect(safe and s.prefix==2 and s.writes==2)
  run inFlightReadTest=init.then(allocate).then(reserve).then(write).then(loseReply).then(query).expect(safe and s.busy and s.prefix==0 and s.physical==1)
  run completeUndeliveredTest=init.then(allocate).then(fill).then(loseReply).then(query).expect(safe and s.ready and s.sourceRoot and not(s.accepted))
  run transferPrefixTest=init.then(allocate).then(one).then(freeze).then(prepareTransfer).then(commitTransfer).then(one).expect(safe and s.owner==1 and s.prefix==2 and s.writes==2)
  run transferLostAckTest=init.then(allocate).then(one).then(freeze).then(prepareTransfer).then(commitTransfer).then(loseReply).then(query).expect(safe and s.gen==1 and s.prefix==1)
  run rejectedTransferTest=init.then(allocate).then(one).then(freeze).then(prepareTransfer).then(rejectTransfer).then(one).expect(safe and s.owner==0 and s.prefix==2)
  run pendingTransferRetainsTest=init.then(allocate).then(one).then(freeze).then(prepareTransfer).then(loseReply).expect(safe and s.frozen and s.inputRoot and s.held==8)
  run publishAfterLastProgressTest=init.then(allocate).then(one).then(one).then(one).then(publish).expect(safe and s.sourceRoot)
  run acceptedLostReplyTest=init.then(allocate).then(fill).then(offer).then(accept).then(loseReply).then(duplicateAccept).then(readReceipt).then(cleanupSource).expect(safe and s.accepts==1 and s.targetRoot)
  run duplicateQueryTest=init.then(allocate).then(fill).then(loseReply).then(query).then(query).expect(safe and s.writes==3 and s.accepts==0)
  run preserveUserWriteTest=init.then(allocate).then(fill).then(offer).then(accept).then(mutateDelivered).then(loseReply).then(query).then(duplicateAccept).expect(safe and s.userWrite and s.writes==3 and s.accepts==1)
  run cancelBeforeAcceptTest=init.then(allocate).then(fill).then(offer).then(cancel).then(withdraw).expect(safe and not(s.accepted) and s.sourceRoot)
  run cancelAfterAcceptTest=init.then(allocate).then(fill).then(offer).then(accept).then(cancel).then(readReceipt).expect(safe and s.accepted and s.targetRoot)
  run atomicPartialAbortTest=init.then(chooseAtomic).then(allocate).then(one).then(cancel).then(freeze).then(abortAtomic).then(retireAtomic).expect(safe and s.retired)
  run unknownAbortRetainsTest=init.then(chooseAtomic).then(allocate).then(one).then(cancel).then(freeze).then(abortAtomic).then(loseReply).expect(safe and s.held==8 and s.custody)
  run prefixResetControlTest=init.then(allocate).then(one).then(loseReply).then(s'={...s,prefix:0}).expect(not(safe))
  run duplicateWriteControlTest=init.then(allocate).then(one).then(s'={...s,writes:s.writes+1}).expect(not(safe))
  run inFlightTransferControlTest=init.then(allocate).then(reserve).then(write).then(s'={...s,transfer:true,frozen:true}).expect(not(safe))
  run staleOwnerWriteControlTest=init.then(allocate).then(one).then(freeze).then(prepareTransfer).then(commitTransfer).then(s'={...s,busy:true,busyGen:0}).expect(not(safe))
  run earlyReadyControlTest=init.then(allocate).then(one).then(s'={...s,ready:true,sourceRoot:true}).expect(not(safe))
  run unrootedCompleteControlTest=init.then(allocate).then(fill).then(s'={...s,sourceRoot:false}).expect(not(safe))
  run rootGapControlTest=init.then(allocate).then(fill).then(offer).then(s'={...s,sourceRoot:false}).expect(not(safe))
  run duplicateDeliveryControlTest=init.then(allocate).then(fill).then(offer).then(accept).then(s'={...s,accepts:2}).expect(not(safe))
  run unknownRefundControlTest=init.then(allocate).then(one).then(loseReply).then(s'={...s,held:0}).expect(not(safe))
  run pointerPartialAbortControlTest=init.then(allocate).then(one).then(cancel).then(freeze).then(s'={...s,aborted:true}).expect(not(safe))
  run earlySourceCleanupControlTest=init.then(allocate).then(fill).then(s'={...s,sourceDone:true,sourceRoot:false}).expect(not(safe))
  run unknownRetireControlTest=init.then(chooseAtomic).then(allocate).then(one).then(cancel).then(freeze).then(abortAtomic).then(loseReply).then(s'={...s,retired:true,held:0}).expect(not(safe))
}
