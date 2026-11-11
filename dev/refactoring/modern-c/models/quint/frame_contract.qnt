// Finite descriptor arithmetic, not a GC liveness or C weak-memory model.
module frame_contract {
 type Plan={kind:int,stored:int,link:int,roots:int,actual:int,outline:bool}
 var p:Plan
 def physical(kind:int,stored:int):int =
   if(kind==2) ((stored+3)/4)*4+9 else stored
 def make(kind:int,stored:int,link:int,roots:int):Plan =
   {kind:kind,stored:stored,link:link,roots:roots,
    actual:physical(kind,stored),outline:physical(kind,stored)>20}
 def inlineWord(x:Plan):int=x.kind+4*x.stored+128*x.link+4096*x.roots
 def outlineWord(x:Plan):int=x.kind+4*x.stored+65536*x.link
 def valid(x:Plan):bool=all{x.kind>=1,x.kind<=3,x.stored>=0,x.stored<16384,
   x.link>=0,x.link<x.actual,x.link<16384,x.roots>=0,x.roots<2^x.actual}
 def correspondence(x:Plan):bool=if(x.outline)
   all{outlineWord(x)%4==x.kind,(outlineWord(x)/4)%16384==x.stored,
       (outlineWord(x)/65536)%16384==x.link}
   else all{inlineWord(x)%4==x.kind,(inlineWord(x)/4)%32==x.stored,
       (inlineWord(x)/128)%32==x.link,(inlineWord(x)/4096)%1048576==x.roots}
 action init=p'=make(1,5,0,7)
 action choose= {
   nondet k=1.to(3).oneOf()
   nondet n=1.to(40).oneOf()
   nondet l=0.to(physical(k,n)-1).oneOf()
   nondet r=0.to(1).oneOf()
   p'=make(k,n,l,r)
 }
 action step=choose
 val safe=all{valid(p),p.actual==physical(p.kind,p.stored),
   p.outline==(p.actual>20),correspondence(p),nativeCapacity}
 action check=all{safe,p'=p}
 action normalBoundary=p'=make(1,20,19,1048575)
 action outlineBoundary=p'=make(1,21,20,2097151)
 action internal=p'=make(2,8,8,65535)
 run normalInlineTest=normalBoundary.then(check)
 run normalOutlineTest=outlineBoundary.then(check)
 run savedRegisterAreaTest=internal.then(check)
 action wrongSize=all{p.kind==2,p'={...p,actual:p.stored}}
 run lostInternalAreaCounterexampleTest=internal.then(wrongSize).then(all{not(safe),p'=p})
 action negativeInit=internal
 action negativeStep=wrongSize
  // C-facing arithmetic only: native pointer identity and descriptor lifetime
  // are NOT represented by an integer offset in this model.
  def words(fs:int,w:int):int=(fs+w-1)/w
  def tailWords(fs:int,w:int):int=if(words(fs,w)>0) words(fs,w)-1 else 0
  def loadNeeded(slot:int,fs:int,w:int):bool=slot<fs and slot%w==0
  def tailIndex(slot:int,w:int):int=(slot-1)/w
  val nativeCapacity=all{p.actual<=16393,
    words(p.actual,32)<=513,tailWords(p.actual,32)<=512,
    words(p.actual,64)<=257,tailWords(p.actual,64)<=256,p.actual+1<=32767}
  val nativeSpanContract=p.actual>=0
  val nativeWordContract=all{32==2^5,64==2^6}
  val nativeTailContract=all{tailWords(p.actual,32)>=0,tailWords(p.actual,64)>=0}
  run internalMaximumTest=init.then(all{physical(2,16383)==16393,
    words(16393,32)==513,tailWords(16393,32)==512,
    words(16393,64)==257,tailWords(16393,64)==256,p'=p})
  run lastRead32Test=init.then(all{loadNeeded(16384,16393,32),
    tailIndex(16384,32)==511,tailIndex(16384,32)<tailWords(16393,32),p'=p})
  run lastRead64Test=init.then(all{loadNeeded(16384,16393,64),
    tailIndex(16384,64)==255,tailIndex(16384,64)<tailWords(16393,64),p'=p})
  run endBoundaryNoReadTest=init.then(all{not(loadNeeded(64,64,64)),p'=p})
  run inlineNoReadTest=init.then(all{1.to(20).forall(s=>not(loadNeeded(s,20,32))),p'=p})
  run allocationNotViewCounterexampleTest=init.then(all{3<10,not(3<3),p'=p})
  run storedSizeBudgetCounterexampleTest=init.then(all{
    words(16383,32)==512,words(physical(2,16383),32)==513,p'=p})
  run malformedInlineCounterexampleTest=init.then(all{
    31<32,physical(2,31)>32,make(2,31,0,0).outline,p'=p})
}
