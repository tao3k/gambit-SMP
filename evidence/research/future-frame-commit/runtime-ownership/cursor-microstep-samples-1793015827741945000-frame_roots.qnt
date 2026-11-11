// The original scalar scan uses width four. The ordinary-run microstep model
// also explores mathematical widths32/64; native C word types, descriptor
// memory lifetime and pointer/provenance still need separate source evidence.
module frame_roots {
  type Scan = {fs:int, bitmap:int, slot:int, word:int, next:int,
               seen:Set[int], visits:int, mode:int, excluded:int, first:int, past:int, delivered:Set[int], runs:int,scanWidth:int}
  var s:Scan
  val width=4
  def root(bits:int, slot:int):bool=(bits/(2^(slot-1)))%2==1
  def tailWord(bits:int, index:int):int=(bits/(2^((index+1)*width)))%(2^width)
  def query(bits:int, slot:int):bool={
    val bit=slot-1
    val word=if(bit<width) bits%(2^width) else tailWord(bits,bit/width-1)
    (word/(2^(bit%width)))%2==1
  }
  def start(n:int,b:int):Scan={fs:n,bitmap:b,slot:1,word:b%(2^width),
                               next:0,seen:Set(),visits:0,mode:0,excluded:0,first:0,past:0,delivered:Set(),runs:0,scanWidth:width}
  action init={
    nondet n=1.to(12).oneOf()
    nondet b=0.to(2^n-1).oneOf()
    s'=start(n,b)
  }
  action step=if(s.slot<=s.fs) {
    val live=s.word%2==1
    val load=s.slot<s.fs and s.slot%width==0
    s'={...s,slot:s.slot+1,
        word:if(load) tailWord(s.bitmap,s.next) else s.word/2,
        next:if(load) s.next+1 else s.next,
        seen:if(live) s.seen.union(Set(s.slot)) else s.seen,
        visits:s.visits+(if(live) 1 else 0)}
  } else s'=s
  val safe=all{
    s.slot>=1,s.slot<=s.fs+1,s.next<=(s.fs-1)/width,
    s.visits==s.seen.size(),
    s.seen==1.to(s.slot-1).filter(i=>root(s.bitmap,i)),
    1.to(s.fs).forall(i=>query(s.bitmap,i)==root(s.bitmap,i)),
    s.slot>s.fs or (s.word%2==1)==root(s.bitmap,s.slot)
  }
  action check=all{safe,s'=s}
  run crossingWordTest=(s'=start(9,273)).then(step).then(step).then(step)
    .then(step).then(step).then(step).then(step).then(step).then(step).then(check)
  run allRootsTest=(s'=start(8,255)).then(step).then(step).then(step).then(step)
    .then(step).then(step).then(step).then(step).then(step).then(check)
  run emptyRootsTest=(s'=start(3,0)).then(step).then(step).then(step).then(check)
  // The original kernel queried tail[block], although tail begins after word 0.
  val legacyMiss=all{root(16,5),not((tailWord(16,(5-1)/width)/2^0)%2==1)}
  run skippedTailCounterexampleTest=(s'=start(9,16)).then(all{legacyMiss,s'=s})
  action negativeInit=s'=start(9,16)
  action negativeStep=s'={...s,word:tailWord(s.bitmap,1),slot:5,next:1}

  // Source-selected composition of the existing 32-bit emitter chunks and target words.
  def emit32(bits:int,index:int):int=(bits/(2^(32*index)))%(2^32)
  def packedWord(bits:int,width:int,index:int):int=
    if(width==32) emit32(bits,index) else emit32(bits,2*index)+(2^32)*emit32(bits,2*index+1)
  def packedQuery(bits:int,width:int,slot:int):bool={
    val i=slot-1
    (packedWord(bits,width,i/width)/(2^(i%width)))%2==1
  }
  val packingLaw=1.to(s.fs).forall(i=>packedQuery(s.bitmap,32,i)==root(s.bitmap,i) and packedQuery(s.bitmap,64,i)==root(s.bitmap,i))
  val ordinary=1.to(s.fs).filter(i=>root(s.bitmap,i) and i!=33)
  val control=1.to(s.fs).filter(i=>root(s.bitmap,i) and i==33)
  val controlPartition=ordinary.union(control)==1.to(s.fs).filter(i=>root(s.bitmap,i)) and ordinary.intersect(control).size()==0
  run emitterPackingBoundaryTest=(s'=start(65,2^31+2^32+2^63+2^64)).then(all{packingLaw,s'=s})
  run highBitAndEmptyWordTest=(s'=start(70,2^69+2^32)).then(all{packingLaw,s'=s})
  run structuralLinkBoundaryTest=(s'=start(65,2^31+2^32+2^63+2^64)).then(all{controlPartition,root(s.bitmap,33),s'=s})
  run reversedPackingCounterexampleTest=(s'=start(33,2^32)).then(all{
    root(s.bitmap,33),packedQuery(s.bitmap,64,33),
    not(((emit32(s.bitmap,1)+(2^32)*emit32(s.bitmap,0))/(2^32))%2==1),s'=s})

  // Microsteps of ordinary next_run plus its caller's separate mark_array delivery.
  // mode: 0 skip, 1 collect nonempty run, 2 returned run awaiting delivery, 3 end.
  def eligible(x:Scan,i:int):bool=root(x.bitmap,i) and i!=x.excluded
  def advanceCursor(x:Scan):Scan={
    val load=x.slot<x.fs and x.slot%x.scanWidth==0
    {...x,slot:x.slot+1,word:if(load) (x.bitmap/(2^((x.next+1)*x.scanWidth)))%(2^x.scanWidth) else x.word/2,
      next:if(load) x.next+1 else x.next}
  }
  def startRun(n:int,b:int,e:int,w:int):Scan={...start(n,b),excluded:e,scanWidth:w,word:b%(2^w)}
  action runInit={
    nondet n=0.to(70).oneOf()
    nondet pattern=Set(0,1,3,15,255,2^31+2^32+2^63+2^64,2^69,2^70-1).oneOf()
    nondet e=0.to(n).oneOf()
    nondet w=Set(4,32,64).oneOf()
    s'=startRun(n,pattern%(2^n),e,w)
  }
  action runStep=if(s.mode==0) {
    if(s.slot>s.fs) s'={...s,mode:3}
    else if(s.word%2==1 and s.slot!=s.excluded) s'={...s,mode:1,first:s.slot}
    else s'=advanceCursor(s)
  } else if(s.mode==1) {
    val a=advanceCursor(s)
    val keep=a.slot<=a.fs and a.word%2==1 and a.slot!=a.excluded
    s'=if(keep) a else {...a,mode:2,past:a.slot}
  } else if(s.mode==2) {
    s'={...s,mode:0,delivered:s.delivered.union(s.first.to(s.past-1)),runs:s.runs+1}
  } else s'=s
  val runWord=s.slot>s.fs or (s.word%2==1)==root(s.bitmap,s.slot)
  val runCoverage=all{
    s.slot>=1,s.slot<=s.fs+1,(s.fs==0 implies s.next==0),(s.fs>0 implies s.next<=(s.fs-1)/s.scanWidth),s.scanWidth>0,
    s.delivered==1.to((if(s.mode==1 or s.mode==2) s.first else s.slot)-1).filter(i=>eligible(s,i)),
    (s.mode==1 or s.mode==2) implies all{s.first>=1,s.first<=s.slot,s.first.to(s.slot-1).forall(i=>eligible(s,i))},
    s.mode==2 implies all{s.past==s.slot,s.first<s.past,s.slot>s.fs or not(eligible(s,s.slot))},
    s.mode==3 implies s.delivered==1.to(s.fs).filter(i=>eligible(s,i)),
    not(s.delivered.contains(s.excluded))}
  val runSafe=runWord and runCoverage
  action finishBounded=40.reps(i=>runStep)
  run excludedLinkSplitsRunTest=(s'={...start(5,31),excluded:3}).then(finishBounded).then(all{runSafe,s.runs==2,s.delivered==Set(1,2,4,5),s'=s})
  run spanningWordRunTest=(s'=start(9,511)).then(finishBounded).then(all{runSafe,s.runs==1,s.delivered.size()==9,s'=s})
  run sparseAndTailRunTest=(s'={...start(9,273),excluded:5}).then(finishBounded).then(all{runSafe,s.runs==2,s.delivered==Set(1,9),s'=s})
  run emptyOrdinaryRunTest=(s'={...start(1,1),excluded:1}).then(finishBounded).then(all{runSafe,s.runs==0,s.delivered.size()==0,s'=s})
  run emptyFrameRunTest=(s'=start(0,0)).then(runStep).then(all{runSafe,s.mode==3,s.delivered.size()==0,s'=s})
  action abandonPending=s'={...s,mode:3}
  action includeControl=s'={...s,delivered:s.delivered.union(Set(s.excluded))}
  run lostReturnedRunNegativeTest=(s'=start(1,1)).then(runStep).then(runStep).then(abandonPending).then(all{not(runSafe),s'=s})
  run scannedLinkNegativeTest=(s'={...start(5,31),excluded:3}).then(finishBounded).then(includeControl).then(all{not(runSafe),s'=s})
  action finishWide=160.reps(i=>runStep)
  run width32MicrostepsTest=(s'=startRun(65,2^31+2^32+2^63+2^64,33,32)).then(finishWide).then(all{runSafe,s.mode==3,s.runs==2,s.delivered==Set(32,64,65),s'=s})
  run width64MicrostepsTest=(s'=startRun(65,2^31+2^32+2^63+2^64,33,64)).then(finishWide).then(all{runSafe,s.mode==3,s.runs==2,s.delivered==Set(32,64,65),s'=s})
}
