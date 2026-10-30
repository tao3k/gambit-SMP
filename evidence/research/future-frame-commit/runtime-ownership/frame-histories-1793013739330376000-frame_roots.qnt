// Word width four is a finite abstraction. Native 32/64-bit bit operations,
// module metadata lifetime and stack/heap coordinates need separate evidence.
module frame_roots {
  type Scan = {fs:int, bitmap:int, slot:int, word:int, next:int,
               seen:Set[int], visits:int}
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
                               next:0,seen:Set(),visits:0}
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
}
