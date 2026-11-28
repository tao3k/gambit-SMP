// Existing old-cohort arrival plus VM registry grace, and its scope limit.
module abort_quiescence_sources {
 type State={profile:int,irq:int,direct:int,external:int,reader:bool,
 arrived:bool,phase:int,closed:bool}
 var s:State
 pure def initial(p:int):State={profile:p,irq:1,direct:1,
 external:if(p==1 or p==2) 1 else 0,reader:true,arrived:false,phase:0,closed:false}
 action initExistingCovered=s'=initial(0)
 action initUntrackedExternal=s'=initial(1)
 action initPinnedExternal=s'=initial(2)
 action initEarlyReaderRelease=s'=initial(3)
 action irqInterrupted=all{s.irq==1,s'={...s,irq:2,reader:s.profile!=3}}
 action irqRetryFinishes=all{s.irq==2,s'={...s,irq:3,reader:false}}
 action directInterrupted=all{s.direct==1,s'={...s,direct:2}}
 action directRetryFinishes=all{s.direct==2,s'={...s,direct:3}}
 action externalFinishes=all{s.external==1,s'={...s,external:3}}
 action arriveOldCohort=all{s.direct==3,not(s.arrived),s'={...s,arrived:true}}
 action closeRegistry=all{s.arrived,s.phase==0,s'={...s,phase:1}}
 action publishReducedCount=all{s.phase==1,not(s.reader),s'={...s,phase:2}}
 action workerClosesFd=all{s.phase==2,
 s.profile!=2 or s.external==3,s'={...s,closed:true,phase:3}}
 val safe=not(s.closed) or (s.irq==3 and s.direct==3 and
 (s.external==0 or s.external==3))
 val done=s.closed and s.irq==3 and s.direct==3 and
 (s.external==0 or s.external==3)
 action step=any{irqInterrupted,irqRetryFinishes,directInterrupted,
 directRetryFinishes,externalFinishes,arriveOldCohort,closeRegistry,
 publishReducedCount,workerClosesFd,all{done,s'=s}}
 temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
