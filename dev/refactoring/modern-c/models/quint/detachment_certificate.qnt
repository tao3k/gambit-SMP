module detachment_certificate {
 type State={layout:int,code:int,certLayout:int,certCode:int,entry:bool,callbacks:bool,schemeRef:bool,oldReturn:bool,terminal:bool,pending:bool,unknown:bool,semantic:bool,foreign:bool,resident:bool,cert:bool,observerOpen:bool,active:int,observerLayout:int,freed:bool}
 pure val initial:State={layout:1,code:1,certLayout:0,certCode:0,entry:true,callbacks:true,schemeRef:true,oldReturn:true,terminal:false,pending:true,unknown:false,semantic:false,foreign:false,resident:false,cert:false,observerOpen:true,active:0,observerLayout:0,freed:false}
 var s:State
 action init=s'=initial
 val dataOnly=not(s.entry) and not(s.callbacks) and not(s.schemeRef) and not(s.oldReturn) and s.terminal
 val valid=s.cert and s.certLayout==s.layout and s.certCode==s.code and dataOnly and not(s.pending) and not(s.unknown)
 val safe=all{s.active>=0,s.active<=1,s.layout>=1,s.layout<=2,
 s.cert implies (s.certLayout==s.layout and s.certCode==s.code and dataOnly and s.semantic and s.foreign and s.resident and not(s.pending) and not(s.unknown)),
 s.active>0 implies (s.observerLayout==s.layout and dataOnly),
 s.freed implies (dataOnly and not(s.pending) and not(s.unknown))}
 action closeEntry=all{s'={...s,entry:false}}
 action drainCallbacks=all{not(s.entry),s'={...s,callbacks:false}}
 action dropSchemeRefs=all{s'={...s,schemeRef:false}}
 action retireReturns=all{s'={...s,oldReturn:false}}
 action terminalize=all{s'={...s,terminal:true}}
 action settle=all{s'={...s,pending:false}}
 action endorseSemantic=all{not(s.schemeRef),not(s.oldReturn),s'={...s,semantic:true}}
 action endorseForeign=all{not(s.entry),not(s.callbacks),s'={...s,foreign:true}}
 action endorseResident=all{s.terminal,s'={...s,resident:true}}
 action issue=all{s.semantic,s.foreign,s.resident,dataOnly,not(s.pending),not(s.unknown),not(s.freed),s'={...s,cert:true,certLayout:s.layout,certCode:s.code}}
 action admit=all{valid,s.observerOpen,s.active==0,s'={...s,active:1,observerLayout:s.layout}}
 action finish=all{s'={...s,active:0}}
 action revoke=all{s'={...s,cert:false,observerOpen:false}}
 action changeLayout=all{not(s.freed),not(s.observerOpen),s.active==0,s.layout<2,s'={...s,layout:s.layout+1,cert:false,semantic:false,foreign:false,resident:false}}
 action reopen=all{valid,s'={...s,observerOpen:true}}
 action freeCode=all{valid,s'={...s,freed:true}}
 action step=any{closeEntry,drainCallbacks,dropSchemeRefs,retireReturns,terminalize,settle,endorseSemantic,endorseForeign,endorseResident,issue,admit,finish,revoke,changeLayout,reopen,freeCode,all{s'=s}}
 action qualify=all{s'={...s,entry:false,callbacks:false,schemeRef:false,oldReturn:false,terminal:true,pending:false,semantic:true,foreign:true,resident:true}}
 run observerOutlivesCodeTest=init.then(qualify).then(issue).then(admit).then(freeCode).then(revoke).then(all{assert(safe and s.active==1 and s.freed and not(s.cert)),s'=s}).then(finish).then(all{assert(safe),s'=s})
 run reissueNewLayoutTest=init.then(qualify).then(issue).then(revoke).then(changeLayout).then(endorseSemantic).then(endorseForeign).then(endorseResident).then(issue).then(reopen).then(admit).then(all{assert(safe and s.certLayout==2),s'=s})
 run drainedButUnendorsedTest=init.then(closeEntry).then(drainCallbacks).then(dropSchemeRefs).then(retireReturns).then(terminalize).then(settle).then(all{assert(safe and not(s.cert)),s'=s})
 run missingRootClosureControlTest=init.then(all{s'={...s,cert:true,certLayout:1,certCode:1}}).then(all{assert(not(safe)),s'=s})
 run staleLayoutCertificateControlTest=init.then(qualify).then(issue).then(revoke).then(changeLayout).then(all{s'={...s,cert:true}}).then(all{assert(not(safe)),s'=s})
 run mutateBorrowedLayoutControlTest=init.then(qualify).then(issue).then(admit).then(all{s'={...s,layout:2}}).then(all{assert(not(safe)),s'=s})
 run restoreOldCodeAliasControlTest=init.then(qualify).then(issue).then(freeCode).then(all{s'={...s,callbacks:true}}).then(all{assert(not(safe)),s'=s})
}
