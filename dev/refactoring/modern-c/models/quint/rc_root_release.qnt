module rc_root_release {
// Single-node safety abstraction. Gate ownership and external alias closure are refinement premises.
type State={admission:int,owner:int,borrow:int,scanner:int,alias:int,registered:int,permit:int,phase:int,origin:int,receipt:int,domainLive:int,reader:int}
pure val initial:State={admission:1,owner:1,borrow:0,scanner:0,alias:0,registered:1,permit:0,phase:0,origin:1,receipt:0,domainLive:1,reader:0}
var s:State
action init=s'=initial
val safe=all{s.admission>=0,s.owner>=0,s.borrow>=0,s.scanner>=0,s.alias>=0,s.registered>=0,s.permit>=0,s.phase>=0,s.origin>=0,s.receipt>=0,s.domainLive>=0,s.reader>=0,s.admission<=1,s.owner<=1,s.borrow<=1,s.scanner<=1,s.alias<=1,s.registered<=1,s.permit<=1,s.phase<=3,s.origin<=1,s.receipt<=1,s.domainLive<=1,s.reader<=1,s.registered==0 implies all{s.owner==0,s.borrow==0,s.scanner==0,s.alias==0,s.admission==0},s.permit==1 implies all{s.registered==0,s.phase==0,s.origin==1},s.phase>=1 implies all{s.registered==0,s.permit==0},s.phase<=2 implies s.origin==1,s.phase==3 implies all{s.origin==0,s.receipt==1},s.phase==0 implies s.receipt==0,s.domainLive==0 implies all{s.admission==0,s.reader==0,s.registered==0,s.phase==3},s.scanner==1 implies all{s.registered==1,s.domainLive==1},s.registered==1 implies all{s.phase==0,s.permit==0,s.domainLive==1},s.admission==1 implies s.registered==1,s.reader==1 implies s.domainLive==1,s.phase==0 and s.registered==0 implies s.permit==1}
action acquireBorrow=all{s.admission==1 and s.owner==1 and s.borrow==0 and s.scanner==0,s'={...s,borrow:1}}
action exportAlias=all{s.admission==1 and s.owner==1 and s.alias==0,s'={...s,alias:1}}
action closeSource=all{s.admission==1,s'={...s,admission:0}}
action dropOwner=all{s.owner==1 and s.scanner==0,s'={...s,owner:0}}
action returnBorrow=all{s.borrow==1 and s.scanner==0,s'={...s,borrow:0}}
action returnAlias=all{s.alias==1,s'={...s,alias:0}}
action beginScan=all{s.registered==1 and s.scanner==0,s'={...s,scanner:1}}
action endScan=all{s.scanner==1,s'={...s,scanner:0}}
action enterReader=all{s.admission==1 and s.domainLive==1 and s.reader==0,s'={...s,reader:1}}
action exitReader=all{s.reader==1,s'={...s,reader:0}}
action unlinkAndPermit=all{s.admission==0 and s.owner==0 and s.borrow==0 and s.scanner==0 and s.alias==0 and s.registered==1,s'={...s,registered:0,permit:1}}
action beginFree=all{s.permit==1 and s.phase==0 and s.origin==1,s'={...s,phase:1,permit:0}}
action loseFreeResult=all{s.phase==1,s'={...s,phase:2}}
action backendReceipt=all{(s.phase==1 or s.phase==2) and s.receipt==0,s'={...s,receipt:1}}
action settleFree=all{(s.phase==1 or s.phase==2) and s.receipt==1,s'={...s,phase:3,origin:0}}
action retireDomain=all{s.admission==0 and s.reader==0 and s.registered==0 and s.owner==0 and s.borrow==0 and s.scanner==0 and s.alias==0 and s.phase==3 and s.domainLive==1,s'={...s,domainLive:0}}
action step=any{acquireBorrow,exportAlias,closeSource,dropOwner,returnBorrow,returnAlias,beginScan,endScan,enterReader,exitReader,unlinkAndPermit,beginFree,loseFreeResult,backendReceipt,settleFree,retireDomain,all{s'=s}}
run ownerLastTest=init.then(acquireBorrow).then(returnBorrow).then(closeSource).then(dropOwner).then(unlinkAndPermit).then(beginFree).then(backendReceipt).then(settleFree).then(retireDomain).then(all{assert(safe),s'=s})
run borrowLastTest=init.then(acquireBorrow).then(closeSource).then(dropOwner).then(returnBorrow).then(unlinkAndPermit).then(all{assert(safe),s'=s})
run scanGraceTest=init.then(beginScan).then(closeSource).then(endScan).then(dropOwner).then(unlinkAndPermit).then(all{assert(safe),s'=s})
run unknownReleaseTest=init.then(closeSource).then(dropOwner).then(unlinkAndPermit).then(beginFree).then(loseFreeResult).then(all{assert(safe),s'=s})
run aliasAndReaderTest=init.then(exportAlias).then(enterReader).then(closeSource).then(dropOwner).then(returnAlias).then(unlinkAndPermit).then(beginFree).then(backendReceipt).then(settleFree).then(exitReader).then(retireDomain).then(all{assert(safe),s'=s})
}
