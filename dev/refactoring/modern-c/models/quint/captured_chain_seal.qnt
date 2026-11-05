module captured_chain_seal {
 type State={n:int,copied:int,sealed:int,published:int,target:int,ended:int,reserved:bool,initialized:bool,deferred:bool,owner:bool,suffixReady:bool,retag:bool,done:bool}
 pure val initial:State={n:3,copied:0,sealed:0,published:0,target:0,ended:0,reserved:false,initialized:false,deferred:false,owner:true,suffixReady:false,retag:false,done:false}
 var s:State
 action init=s'=initial
 action initEmpty=s'={...initial,n:0}
 val safe=all{
 s.n>=0,s.sealed>=0,s.sealed<=s.copied,s.copied<=s.n,s.copied<=s.sealed+2,
 s.published>=0,s.published<=s.sealed,
 not(s.initialized) implies s.copied<=s.sealed+1,
 s.initialized implies s.reserved,
 (s.reserved or s.copied>s.sealed or s.deferred) implies s.owner,
 s.deferred implies (s.target>0 and s.target<=s.copied),
 (s.ended==1 or s.ended==2) implies (s.copied==s.sealed and not(s.reserved)),
 s.ended==2 implies s.suffixReady,
 s.retag implies (s.ended==1 or s.ended==2),
 s.done implies (not(s.owner) and not(s.deferred) and s.retag and s.published==s.sealed)}
 action reserve=all{s.owner,s.ended==0,not(s.reserved),not(s.initialized),s.copied<s.n,s'={...s,reserved:true}}
 action initializeCopy=all{s.owner,s.reserved,not(s.initialized),s.ended==0,s.copied<s.n,s'={...s,copied:s.copied+1,initialized:true}}
 action resolvePrevious=all{s.initialized,s.copied==s.sealed+2,s'={...s,sealed:s.sealed+1}}
 action finishInstall=all{s.initialized,s.copied==s.sealed+1,s'={...s,initialized:false,reserved:false}}
 action deferChunk=all{s.owner,s.ended==0,not(s.reserved),s.copied==s.sealed+1,not(s.deferred),s'={...s,deferred:true,target:s.copied}}
 action publishDeferred=all{s.deferred,s.sealed>=s.target,s'={...s,deferred:false}}
 action publishPrefix=all{s.owner,s'={...s,published:s.sealed}}
 action certifySuffix=all{s.owner,s.ended==0,s'={...s,suffixReady:true}}
 action terminal=all{s.owner,s.ended==0,not(s.reserved),s.copied==s.n,s'={...s,sealed:s.copied,ended:1}}
 action forwarded=all{s.owner,s.ended==0,not(s.reserved),s.copied<s.n,s.suffixReady,s'={...s,sealed:s.copied,ended:2}}
 action capacityFailure=all{s.owner,s.ended==0,not(s.reserved),s'={...s,ended:3}}
 action retagRoot=all{(s.ended==1 or s.ended==2),s'={...s,retag:true}}
 action release=all{s.owner,s.retag,not(s.deferred),s.published==s.sealed,s'={...s,owner:false,done:true}}
 action step=any{reserve,initializeCopy,resolvePrevious,finishInstall,deferChunk,publishDeferred,publishPrefix,certifySuffix,terminal,forwarded,capacityFailure,retagRoot,release,all{s'=s}}
 action first=reserve.then(initializeCopy).then(finishInstall)
 action subsequent=reserve.then(initializeCopy).then(resolvePrevious).then(finishInstall)
 run fullChainTest=init.then(first).then(deferChunk).then(subsequent).then(publishDeferred).then(publishPrefix).then(deferChunk).then(subsequent).then(publishDeferred).then(terminal).then(publishPrefix).then(retagRoot).then(release).then(all{assert(safe and s.done and s.copied==3),s'=s})
 run terminalPendingTest=init.then(first).then(subsequent).then(subsequent).then(deferChunk).then(terminal).then(publishDeferred).then(all{assert(safe and s.copied==s.sealed),s'=s})
 run forwardedSuffixTest=init.then(first).then(deferChunk).then(certifySuffix).then(forwarded).then(publishDeferred).then(publishPrefix).then(retagRoot).then(release).then(all{assert(safe and s.done and s.copied==1),s'=s})
 run emptyChainTest=initEmpty.then(terminal).then(retagRoot).then(release).then(all{assert(safe and s.done and s.copied==0),s'=s})
 run failureCustodyTest=init.then(first).then(deferChunk).then(capacityFailure).then(all{assert(safe and s.owner and s.deferred and not(s.done)),s'=s})
 run transientTwoDebtTest=init.then(first).then(reserve).then(initializeCopy).then(all{assert(safe and s.copied==s.sealed+2),s'=s})
 run earlyReleaseControlTest=init.then(first).then(all{s'={...s,owner:false}}).then(all{assert(not(safe)),s'=s})
 run earlyPublishControlTest=init.then(first).then(all{s'={...s,published:s.copied}}).then(all{assert(not(safe)),s'=s})
 run unknownSuffixControlTest=init.then(first).then(all{s'={...s,sealed:s.copied,ended:2}}).then(all{assert(not(safe)),s'=s})
}
