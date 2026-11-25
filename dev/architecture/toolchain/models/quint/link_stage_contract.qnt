// Pure projections/readiness/admission. Existing phase service owns scheduling.
module link_stage_contract {
 type Request={members:List[int],flags:List[int],code:int->int,observation:int->int,ccMeta:int->int,pkg:int,
   mode:int,base:int,name:int,format:int,abi:int,compiler:int,cc:int,ld:List[int],output:int,closed:bool}
 type LinkKey={members:List[int],flags:List[int],observations:List[int],mode:int,base:int,name:int,format:int,abi:int}
 type ObjKey={moduleId:int,code:int,ccMeta:int,pkg:int,abi:int,compiler:int,cc:int}
 type FinalKey={plan:LinkKey,objects:List[ObjKey],compiler:int,cc:int,pkg:int,ld:List[int],output:int}
 val r:Request={members:List(0,1),flags:List(0,1),code:Map(0->10,1->20),observation:Map(0->30,1->40),ccMeta:Map(0->0,1->0),pkg:0,
   mode:0,base:0,name:0,format:0,abi:0,compiler:0,cc:0,ld:List(1,2,1),output:0,closed:true}
 def valid(x:Request):bool=x.closed and Set(0,1).contains(x.mode) and x.members.length()==x.flags.length() and x.members.indices().forall(i=>Set(0,1).contains(x.members.nth(i)))
 def linkKey(x:Request):LinkKey={members:x.members,flags:x.flags,observations:x.members.foldl(List(),(acc,m)=>acc.append(x.observation.get(m))),mode:x.mode,base:x.base,name:x.name,format:x.format,abi:x.abi}
 def objKey(x:Request,m:int):ObjKey={moduleId:m,code:x.code.get(m),ccMeta:x.ccMeta.get(m),pkg:x.pkg,abi:x.abi,compiler:x.compiler,cc:x.cc}
 def finalKey(x:Request):FinalKey={plan:linkKey(x),objects:x.members.foldl(List(),(acc,m)=>acc.append(objKey(x,m))),compiler:x.compiler,cc:x.cc,pkg:x.pkg,ld:x.ld,output:x.output}
 def semanticReady(x:Request,g:Set[int]):bool=valid(x) and x.members.indices().forall(i=>g.contains(x.members.nth(i)))
 def finalReady(x:Request,g:Set[int],o:Set[int],linkObject:bool):bool=semanticReady(x,g) and x.members.indices().forall(i=>o.contains(x.members.nth(i))) and linkObject
 type Attempt={product:int,context:int,workspace:int,roots:bool,frozen:bool}
 val a:Attempt={product:0,context:0,workspace:0,roots:true,frozen:true}
 val b:Attempt={product:1,context:1,workspace:1,roots:true,frozen:true}
 def parallelAllowed(x:Attempt,y:Attempt):bool=x.product!=y.product and x.context!=y.context and x.workspace!=y.workspace and x.roots and y.roots and x.frozen and y.frozen
 run leafBodyPreservesSemanticTest=all{val x={...r,code:r.code.set(0,11)};all{linkKey(x)==linkKey(r),objKey(x,0)!=objKey(r,0),objKey(x,1)==objKey(r,1),finalKey(x)!=finalKey(r)}}
 run linkMetadataPreservesLeafObjectTest=all{val x={...r,observation:r.observation.set(0,31)};all{linkKey(x)!=linkKey(r),objKey(x,0)==objKey(r,0),finalKey(x)!=finalKey(r)}}
 run ccMetadataInvalidatesObjectTest=all{val x={...r,ccMeta:r.ccMeta.set(0,1)};all{objKey(x,0)!=objKey(r,0),objKey(x,1)==objKey(r,1),finalKey(x)!=finalKey(r)}}
 run pkgConfigAffectsBothTest=all{val x={...r,pkg:1};all{objKey(x,0)!=objKey(r,0),finalKey(x)!=finalKey(r)}}
 run nativeCompilerLeavesSemanticTest=all{val x={...r,compiler:1};all{linkKey(x)==linkKey(r),objKey(x,0)!=objKey(r,0),finalKey(x)!=finalKey(r)}}
 run abiInvalidatesBothTest=all{val x={...r,abi:1};all{linkKey(x)!=linkKey(r),objKey(x,0)!=objKey(r,0)}}
 run linkOptionsLeaveObjectsTest=all{val x={...r,ld:List(2,1,1)};all{linkKey(x)==linkKey(r),objKey(x,0)==objKey(r,0),finalKey(x)!=finalKey(r)}}
 run orderedMembersTest=all{linkKey({...r,members:List(1,0),flags:List(1,0)})!=linkKey(r)}
 run incrementalBaseTest=all{val x={...r,mode:1};all{linkKey(x)!=linkKey(r),linkKey({...x,base:1})!=linkKey(x)}}
 run fpoNeedsOwnProducerTest=all{not(valid({...r,mode:2}))}
 run generatedReadyBeforeObjectsTest=all{semanticReady(r,Set(0,1)),not(finalReady(r,Set(0,1),Set(0),true))}
 run finalNeedsLinkObjectTest=all{not(finalReady(r,Set(0,1),Set(0,1),false)),finalReady(r,Set(0,1),Set(0,1),true)}
 run immutableShareParallelTest=all{parallelAllowed(a,b)}
 run sharedContextRefusesTest=all{not(parallelAllowed(a,{...b,context:0}))}
 run sameProductJoinsTest=all{not(parallelAllowed(a,{...b,product:0}))}
 run sameInstanceRefusesTest=all{not(parallelAllowed(a,{...b,workspace:0}))}
 run unrootedRefusesTest=all{not(parallelAllowed(a,{...b,roots:false}))}
 run opaqueInputsRefuseTest=all{not(valid({...r,closed:false})),not(parallelAllowed(a,{...b,frozen:false}))}
}
