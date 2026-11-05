// Two-atomic admission refinement, not a complete C11 memory-model checker.
// The weak initializer permits the store-buffering observation allowed by
// separate acquire/release locations. SC uses one interleaving order instead.
// A valid host VM borrow is a precondition before touching either atomic.
module writer_close_admission {
  var weak: bool
  var count: int
  var closed: bool
  var writer: int
  var cleaner: int
  var admitted: bool
  var freed: bool
  action init = all {weak'=false,count'=0,closed'=false,writer'=0,
    cleaner'=0,admitted'=false,freed'=false}
  action initAcquireRelease = all {weak'=true,count'=0,closed'=false,writer'=0,
    cleaner'=0,admitted'=false,freed'=false}
  action enter = all {writer==0,count'=count+1,writer'=1,
    closed'=closed,cleaner'=cleaner,admitted'=admitted,freed'=freed,weak'=weak}
  action inspect = all {writer==1,writer'=if(closed and not(weak)) 3 else 2,
    admitted'=(not(closed) or weak),count'=count,closed'=closed,
    cleaner'=cleaner,freed'=freed,weak'=weak}
  action finish = all {writer==2 or writer==3,count'=count-1,writer'=4,
    closed'=closed,cleaner'=cleaner,admitted'=false,freed'=freed,weak'=weak}
  action close = all {cleaner==0,cleaner'=1,closed'=true,
    count'=count,writer'=writer,admitted'=admitted,freed'=freed,weak'=weak}
  action observe = all {cleaner==1,cleaner'=2,
    freed'=(count==0 or weak),count'=count,closed'=closed,writer'=writer,
    admitted'=admitted,weak'=weak}
  action idle = all {weak'=weak,count'=count,closed'=closed,writer'=writer,
    cleaner'=cleaner,admitted'=admitted,freed'=freed}
  action step = any {enter,inspect,finish,close,observe,idle}
  val safe = not(freed and admitted)
}
