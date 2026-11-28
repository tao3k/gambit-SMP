// Bounded asynchronous evidence protocol. Arithmetic and key encoding belong to Lean.
module package_benchmark_admission {
 type Request={generation:int,phase:int,profile:int,lastLabel:int,cases:Set[int],verified:bool,timedOut:bool,rooted:bool,receipt:bool}
 val fresh:Request={generation:1,phase:0,profile:0,lastLabel:0,cases:Set(),verified:false,timedOut:false,rooted:false,receipt:false}
 val Required=Set(0,1,2,3,4)
 var s:int->Request
 action init=s'=Map(0->fresh,1->fresh)
 action start(r,p)=all{s.get(r).phase==0,s'=s.set(r,{...s.get(r),phase:1,profile:p,rooted:true})}
 action label(r,n)=all{s.get(r).phase==1,s'=s.set(r,{...s.get(r),lastLabel:n})}
 action recordCase(r,k)=all{Set(1,2).contains(s.get(r).phase),s'=s.set(r,{...s.get(r),cases:s.get(r).cases.union(Set(k))})}
 action processExit(r)=all{s.get(r).phase==1,s'=s.set(r,{...s.get(r),phase:2})}
 action verify(r)=all{s.get(r).phase==2,s'=s.set(r,{...s.get(r),verified:true})}
 def canPublish(r:int,g:int):bool=s.get(r).generation==g and s.get(r).phase==2 and s.get(r).profile==1 and s.get(r).verified and s.get(r).cases==Required and not(s.get(r).timedOut)
 action publish(r,g)=all{canPublish(r,g),s'=s.set(r,{...s.get(r),phase:3,receipt:true})}
 action timeout(r)=all{Set(1,2).contains(s.get(r).phase),s'=s.set(r,{...s.get(r),phase:4,timedOut:true})}
 // Late terminal observation settles process custody, never erases censoring.
 action lateExit(r)=all{s.get(r).phase==4,s'=s.set(r,{...s.get(r),phase:5})}
 action detach(r)=all{s.get(r).phase==5,s'=s.set(r,{...s.get(r),rooted:false})}
 action restart(r)=all{s.get(r).phase==5,not(s.get(r).rooted),s.get(r).generation==1,s'=s.set(r,{...fresh,generation:2})}
 val bothReady=s.get(0).receipt and s.get(1).receipt
 val safe=Set(0,1).forall(r=>(s.get(r).receipt implies s.get(r).phase==3 and s.get(r).profile==1 and not(s.get(r).timedOut) and s.get(r).verified and s.get(r).cases==Required) and (s.get(r).phase==4 implies s.get(r).rooted) and (s.get(r).timedOut implies not(s.get(r).receipt)))
 action casesDone(r)=recordCase(r,0).then(recordCase(r,1)).then(recordCase(r,2)).then(recordCase(r,3)).then(recordCase(r,4))
 action ready(r)=start(r,1).then(casesDone(r)).then(processExit(r)).then(verify(r)).then(publish(r,1))
 action step={nondet r=Set(0,1).oneOf();nondet k=Required.oneOf();any{start(r,0),start(r,1),label(r,14),recordCase(r,k),processExit(r),verify(r),publish(r,1),publish(r,2),timeout(r),lateExit(r),detach(r),restart(r),s'=s}}
 run unknownProfileCannotPublishTest=init.then(start(0,0)).then(casesDone(0)).then(processExit(0)).then(verify(0)).expect(safe and not(canPublish(0,1)))
 run labelIsNotCompletionTest=init.then(start(0,1)).then(label(0,14)).expect(safe and not(s.get(0).receipt) and s.get(0).cases==Set())
 run timeoutCannotAdmitTest=init.then(start(0,1)).then(timeout(0)).expect(safe and not(bothReady) and s.get(0).rooted)
 run lateExitDoesNotUncensorTest=init.then(start(0,1)).then(timeout(0)).then(lateExit(0)).then(detach(0)).expect(safe and s.get(0).timedOut and not(s.get(0).receipt))
 run staleGenerationCannotPublishTest=init.then(start(0,1)).then(timeout(0)).then(lateExit(0)).then(detach(0)).then(restart(0)).then(start(0,1)).then(casesDone(0)).then(processExit(0)).then(verify(0)).expect(safe and not(canPublish(0,1)) and canPublish(0,2))
 run publicationNeedsOutputVerificationTest=init.then(start(0,1)).then(casesDone(0)).then(processExit(0)).expect(safe and not(canPublish(0,1)))
 run missingCaseBlocksPublicationTest=init.then(start(0,1)).then(recordCase(0,0)).then(processExit(0)).then(verify(0)).expect(safe and not(canPublish(0,1)))
 run duplicateCaseDoesNotCountTwiceTest=init.then(start(0,1)).then(recordCase(0,0)).then(recordCase(0,0)).then(processExit(0)).then(verify(0)).expect(safe and s.get(0).cases==Set(0) and not(canPublish(0,1)))
 run oneRepositoryCannotAdmitBothTest=init.then(ready(0)).expect(safe and not(bothReady))
 run reorderedCompletionCanAdmitBothTest=init.then(ready(1)).then(ready(0)).expect(safe and bothReady)
 run timeoutAfterExitBeforePublishTest=init.then(start(0,1)).then(casesDone(0)).then(processExit(0)).then(verify(0)).then(timeout(0)).expect(safe and not(canPublish(0,1)))
 run oldReceiptCannotPublishNewExecutionTest=init.then(ready(0)).expect(safe and not(canPublish(0,1)))
}
