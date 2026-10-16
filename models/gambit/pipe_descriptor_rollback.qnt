module pipe_descriptor_rollback {
  // Descriptor numbers and bounded dup prefixes, not worker/CPU limits.
  type State = { policy: str, prefix: int, closeOnError: bool,
    phase: str, main: Set[int], mainTodo: Set[int], tempTodo: Set[int],
    live: Set[int], outside: Set[int], closed: Set[int], reused: bool,
    doubleClose: bool, foreignClose: bool, unpublishedRead: bool }
  var s: State
  pure def initial(policy: str, prefix: int, closeOnError: bool): State = {
    val main=Set(prefix,4)
    val temps=Set(0,1,2).filter(fd=>fd<prefix)
    val oldTemps=if (prefix==3) temps else Set(1,2).filter(fd=>fd<=prefix)
    {
      policy:policy, prefix:prefix, closeOnError:closeOnError,
      phase:if (policy=="old-helper" and prefix<3 and closeOnError) "initial" else "main",
      main:main, mainTodo:if (prefix<3 and closeOnError) main else Set(),
      tempTodo:if (policy=="old-helper") oldTemps else if (policy=="leak-temp") Set() else temps,
      live:main.union(temps).union(Set(6,7)), outside:Set(6,7), closed:Set(), reused:false,
      doubleClose:false, foreignClose:false, unpublishedRead:false
    }
  }
  action init = {
    nondet prefix=Set(0,1,2,3).oneOf()
    nondet closeOnError=Set(false,true).oneOf()
    s'=initial("owned",prefix,closeOnError)
  }
  action initOldHelper=s'=initial("old-helper",0,true)
  action initOldRetain=s'=initial("old-helper",2,false)
  action initUnpublishedCaller=s'=initial("old-caller",1,true)
  action initLeakedTemp=s'=initial("leak-temp",1,true)
  pure def closing(old: State, fd: int): State = {
    ...old, live:old.live.exclude(Set(fd)), closed:old.closed.union(Set(fd)),
    doubleClose:old.doubleClose or not(old.live.contains(fd)),
    foreignClose:old.foreignClose or old.outside.contains(fd)
  }
  action closeInitial=all { s.phase=="initial", s'={ ...closing(s,0),phase:"main" } }
  action closeMain={
    nondet fd=s.mainTodo.oneOf()
    all { s.phase=="main", s'={ ...closing(s,fd),mainTodo:s.mainTodo.exclude(Set(fd)) } }
  }
  action beginTemps=all { s.phase=="main", s.mainTodo.size()==0, s'={ ...s,phase:"temps" } }
  action closeTemp={
    nondet fd=s.tempTodo.oneOf()
    all { s.phase=="temps", s'={ ...closing(s,fd),tempTodo:s.tempTodo.exclude(Set(fd)) } }
  }
  action returnHelper=all { s.phase=="temps",s.tempTodo.size()==0,s'={ ...s,phase:"caller" } }
  action caller=all { s.phase=="caller",
    s'={ ...s,phase:"done",unpublishedRead:s.policy=="old-caller" and s.prefix<3 } }
  // A different OS thread may reuse a closed descriptor before cleanup ends.
  action reuse={
    nondet fd=s.closed.exclude(s.live).oneOf()
    all { not(s.reused),s.phase!="done",
      s'={ ...s,live:s.live.union(Set(fd)),outside:s.outside.union(Set(fd)),reused:true } }
  }
  action hold=all { s.phase=="done",s'=s }
  action step=any { closeInitial,closeMain,beginTemps,closeTemp,returnHelper,caller,reuse,hold }
  val returned=s.phase=="caller" or s.phase=="done"
  val failed=s.prefix<3
  val retained=not(failed) or not(s.closeOnError)
  val ownedAfterReturn=returned.implies(
    s.live.exclude(s.outside)==(if (retained) s.main else Set()))
  val safe=not(s.doubleClose) and not(s.foreignClose) and not(s.unpublishedRead)
    and s.outside.subseteq(s.live) and ownedAfterReturn
}
