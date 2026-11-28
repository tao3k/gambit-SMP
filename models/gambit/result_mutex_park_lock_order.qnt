// Bounded lock-order control only. Does not model lock implementation or GC.
module result_mutex_park_lock_order {
 type State={nested:bool,p:int,v:int,a:int,b:int}
 var s:State
 action initNested=s'={nested:true,p:0,v:0,a:0,b:0}
 action initSplit=s'={nested:false,p:0,v:0,a:0,b:0}
 action prepare=all{s.a==0,s.p==0,s'={...s,p:1,a:1}}
 action releasePrepared=all{s.a==1,not(s.nested),s'={...s,p:0,a:2}}
 action registerIdle=all{(s.a==2 or (s.a==1 and s.nested)),s.v==0,
   s'={...s,v:1,a:3}}
 action releaseIdle=all{s.a==3,s'={...s,v:0,p:if(s.nested) 0 else s.p,a:4}}
 action validate=all{s.a==4,s.p==0,s'={...s,p:1,a:5}}
 action releaseCommit=all{s.a==5,s'={...s,p:0,a:6}}
 action selectIdle=all{s.b==0,s.v==0,s'={...s,v:2,b:1}}
 action releaseSelection=all{s.b==1,not(s.nested),s'={...s,v:0,b:2}}
 action publishReady=all{(s.b==2 or (s.b==1 and s.nested)),s.p==0,
   s'={...s,p:2,b:3}}
 action releasePublication=all{s.b==3,
   s'={...s,p:0,v:if(s.nested) 0 else s.v,b:4}}
 val done=s.a==6 and s.b==4
 val cycle=s.nested and s.a==1 and s.b==1 and s.p==1 and s.v==2
 val safe=not(cycle)
 action step=any{prepare,releasePrepared,registerIdle,releaseIdle,validate,
 releaseCommit,selectIdle,releaseSelection,publishReady,releasePublication,
 all{done or cycle,s'=s}}
 temporal completion=weakFair(step,Set(s)).implies(eventually(done))
}
