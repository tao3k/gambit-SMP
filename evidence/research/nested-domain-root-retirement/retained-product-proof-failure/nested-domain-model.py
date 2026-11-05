from pathlib import Path
import json
R=Path('/Users/guangtao/ghq/github.com/tao3k/gerbil-bazel/.data/gambit-SMP');B=R/'dev/refactoring/modern-c';T='nested-domain-root-retirement';C=R/'.cache/tasks'/T;C.mkdir(parents=True,exist_ok=True)
fields='source target ack pubReply outerGuard innerGuard outerRight innerRight unwind landed captured gcReader descriptor rootClosed rootGrace rootRetired codeClosed codeGrace detached outcome shotGuard shotTicket'.split();initial={f:0 for f in fields};initial.update(source=1,descriptor=1)
inv=[f's.{f}>=0' for f in fields]+[f's.{f}<={3 if f in ["outerGuard","innerGuard","unwind"] else 2 if f=="shotTicket" else 1}' for f in fields]
inv += [
'(s.source==1 or s.target==1 or s.rootRetired==1)',
'(s.pubReply==1) implies (s.source==1 and s.ack==0 and s.outerGuard==0)',
'(s.ack==1) implies (s.target==1 or s.rootRetired==1)',
'(s.outerGuard>0) implies (s.ack==1 and s.source==0)',
'(s.innerGuard>0) implies (s.outerGuard>0)',
'(s.outerGuard==1 or s.outerGuard==2 or s.innerGuard==1 or s.innerGuard==2 or s.shotGuard==1) implies (s.target==1 and s.descriptor==1 and s.rootRetired==0)',
'(s.outerRight==1) implies (s.outerGuard==1 and s.unwind==0 and s.landed==0)',
'(s.innerRight==1) implies (s.innerGuard==1 and s.outerRight==1)',
'(s.outerGuard==1) implies (s.outerRight==1 and s.unwind==0)',
'(s.innerGuard==1) implies (s.innerRight==1 and s.outerGuard==1)',
'(s.outerGuard==2 or s.innerGuard==2) implies (s.unwind>=1)',
'(s.unwind>=1) implies (s.outerRight==0 and s.innerRight==0 and s.outerGuard>=2 and s.innerGuard>=2)',
'(s.unwind==1 or s.unwind==2) implies (s.outerGuard==2 and s.innerGuard==2 and s.landed==0 and s.captured==1)',
'(s.landed==1) implies (s.unwind==3 and s.outcome==0)',
'(s.unwind==3) implies (s.landed==1)',
'(s.innerGuard==3) implies (s.landed==1)',
'(s.outerGuard==3) implies (s.innerGuard==3)',
'(s.outcome==1) implies (s.unwind==2 and s.landed==0 and s.outerGuard==2 and s.innerGuard==2)',
'(s.captured==1) implies (s.target==1 and s.descriptor==1 and s.rootClosed==0)',
'(s.gcReader==1) implies (s.target==1 and s.descriptor==1 and s.rootGrace==0 and s.codeGrace==0)',
'(s.rootClosed==1) implies (s.source==0 and s.ack==1 and s.landed==1 and s.outerGuard==3 and s.innerGuard==3 and s.captured==0 and s.shotGuard==0)',
'(s.rootGrace==1) implies (s.rootClosed==1 and s.gcReader==0)',
'(s.codeClosed==1) implies (s.rootClosed==1)',
'(s.codeGrace==1) implies (s.codeClosed==1 and s.gcReader==0)',
'(s.rootRetired==1) implies (s.target==0 and s.source==0 and s.rootClosed==1 and s.rootGrace==1 and s.gcReader==0)',
'(s.descriptor==0) implies (s.rootRetired==1 and s.codeClosed==1 and s.codeGrace==1 and s.gcReader==0)',
'(s.detached==1) implies (s.descriptor==0 and s.rootRetired==1 and s.landed==1)',
'(s.shotGuard==1) implies (s.landed==1 and s.outerGuard==3 and s.innerGuard==3 and s.captured==1 and s.shotTicket>=1)',
'(s.shotTicket>0) implies (s.landed==1 and s.outerGuard==3 and s.innerGuard==3)'
]
E=[]
def edge(n,g,**u):E.append((n,g,u))
edge('publishRoots','s.source==1 and s.target==0 and s.pubReply==0',target='1')
edge('publicationReplyLost','s.source==1 and s.target==0 and s.pubReply==0',target='1',pubReply='1')
edge('publicationAbsentUnknown','s.source==1 and s.target==0 and s.pubReply==0',pubReply='1')
edge('resolvePublication','s.pubReply==1',pubReply='0')
edge('acknowledgeRoots','s.target==1 and s.pubReply==0 and s.ack==0',ack='1')
edge('releaseSource','s.source==1 and s.target==1 and s.ack==1 and s.pubReply==0',source='0')
edge('enterOuter','s.outerGuard==0 and s.source==0 and s.target==1 and s.ack==1 and s.rootClosed==0 and s.codeClosed==0',outerGuard='1',outerRight='1')
edge('enterInner','s.outerGuard==1 and s.outerRight==1 and s.innerGuard==0 and s.rootClosed==0 and s.codeClosed==0',innerGuard='1',innerRight='1')
edge('captureInner','s.innerGuard==1 and s.captured==0',captured='1')
edge('startGcReader','s.target==1 and s.descriptor==1 and s.rootClosed==0 and s.codeClosed==0 and s.gcReader==0',gcReader='1')
edge('finishGcReader','s.gcReader==1',gcReader='0')
edge('escrowOuterUnwind','s.outerGuard==1 and s.innerGuard==1 and s.captured==1 and s.unwind==0',outerGuard='2',innerGuard='2',outerRight='0',innerRight='0',unwind='1')
edge('issueOuterUnwind','s.unwind==1',unwind='2')
edge('landingObserved','s.unwind==2 and s.outcome==0',unwind='3',landed='1')
edge('landingReplyLost','s.unwind==2 and s.outcome==0',outcome='1')
edge('reconcileLanding','s.unwind==2 and s.outcome==1',unwind='3',landed='1',outcome='0')
edge('settleInnerGuard','s.unwind==3 and s.innerGuard==2',innerGuard='3')
edge('settleOuterGuard','s.unwind==3 and s.innerGuard==3 and s.outerGuard==2',outerGuard='3')
edge('resumeCaptured','s.captured==1 and s.outerGuard==3 and s.innerGuard==3 and s.shotGuard==0 and s.shotTicket<2 and s.rootClosed==0 and s.codeClosed==0',shotGuard='1',shotTicket='s.shotTicket+1')
edge('rejectInnerReturn','s.shotGuard==1 and s.innerRight==0')
edge('finishResumption','s.shotGuard==1',shotGuard='0')
edge('closeCapturedHolders','s.captured==1 and s.outerGuard==3 and s.innerGuard==3 and s.shotGuard==0',captured='0')
edge('closeRootAdmission','s.captured==0 and s.outerGuard==3 and s.innerGuard==3 and s.shotGuard==0 and s.rootClosed==0',rootClosed='1')
edge('closeCodeAdmission','s.rootClosed==1 and s.codeClosed==0',codeClosed='1')
edge('ackRootGrace','s.rootClosed==1 and s.gcReader==0 and s.rootGrace==0',rootGrace='1')
edge('retireRootSlots','s.rootClosed==1 and s.rootGrace==1 and s.gcReader==0 and s.target==1',target='0',rootRetired='1')
edge('ackCodeGrace','s.codeClosed==1 and s.gcReader==0 and s.codeGrace==0',codeGrace='1')
edge('retireDescriptor','s.rootRetired==1 and s.codeClosed==1 and s.codeGrace==1 and s.gcReader==0 and s.descriptor==1',descriptor='0')
edge('detachNativeOwner','s.rootRetired==1 and s.descriptor==0 and s.gcReader==0 and s.detached==0',detached='1')
q=['module nested_domain_root_retirement {','// Bounded product: two accepted domains, one admitted source, one GC reader, two resumptions.','type State={'+','.join(f+':int' for f in fields)+'}','pure val initial:State={'+','.join(k+':'+str(v) for k,v in initial.items())+'}','var s:State',"action init=s'=initial",'val safe=all{'+',\n'.join(inv)+'}']
q+=['action '+n+'=all{'+g+",s'={...s"+''.join(','+k+':'+v for k,v in u.items())+'}}' for n,g,u in E]
q+=["action step=any{"+','.join(n for n,_,_ in E)+",all{s'=s}}"]
entry=['publishRoots','acknowledgeRoots','releaseSource','enterOuter','enterInner','captureInner'];escrow=['escrowOuterUnwind','issueOuterUnwind'];settle=['landingObserved','settleInnerGuard','settleOuterGuard'];close=['closeCapturedHolders','closeRootAdmission','closeCodeAdmission'];retire=['ackRootGrace','retireRootSlots','ackCodeGrace','retireDescriptor','detachNativeOwner']
hist=[('normalRetirement',entry+escrow+settle+close+retire,'s.detached==1'),('gcOverUnwind',entry+['startGcReader']+escrow+settle+close+['finishGcReader']+retire,'s.descriptor==0'),('unknownLanding',entry+escrow+['landingReplyLost','startGcReader'],'s.outcome==1 and s.innerGuard==2 and s.descriptor==1'),('unknownReconciled',entry+escrow+['landingReplyLost','reconcileLanding','settleInnerGuard','settleOuterGuard']+close+retire,'s.detached==1'),('twoRestorations',entry+escrow+settle+['resumeCaptured','rejectInnerReturn','finishResumption','resumeCaptured','rejectInnerReturn','finishResumption']+close+retire,'s.shotTicket==2 and s.innerRight==0'),('publicationUnknownGc',['publicationReplyLost','startGcReader','resolvePublication','acknowledgeRoots','releaseSource','finishGcReader']+entry[3:]+escrow+settle+close+retire,'s.detached==1'),('publicationAbsentRetry',['publicationAbsentUnknown','resolvePublication']+entry+escrow+settle+close+retire,'s.detached==1'),('capturedKeepsDescriptor',entry+escrow+settle+['startGcReader','finishGcReader'],'s.captured==1 and s.descriptor==1 and s.target==1'),('codeGraceBeforeRootRetire',entry+escrow+settle+close+['ackCodeGrace','ackRootGrace','retireRootSlots','retireDescriptor'],'s.descriptor==0')]
q+=['run '+n+'Test=init'+''.join('.then('+a+')' for a in aa)+'.then(all{assert('+goal+"),assert(safe),s'=s})" for n,aa,goal in hist]+['}']
(B/'models/quint/nested_domain_root_retirement.qnt').write_text('\n'.join(q)+'\n')
p=R/'dev/modeling/tools/nested-domain-root-retirement-projection.py';src=(R/'dev/modeling/tools/native-return-domains-projection.py').read_text();a=src.index('SPEC=');b=src.index('\ndef generate',a);p.write_text(src[:a]+'SPEC='+repr(dict(module='nested_domain_root_retirement',namespace='NestedDomainAst',fields={f:'int' for f in fields},actions=[n for n,_,_ in E]))+src[b:])
lean=['import NestedDomainAst','namespace NestedDomain','open NestedDomainAst','set_option maxRecDepth 10000','set_option linter.unusedSimpArgs false']
for n,g,u in E:lean+=['theorem '+n+'Preserves (q : State) (h : Safe q) (g : '+n+'Guard q) : Safe ('+n+'Next q) := by\n simp_all ['+n+'Guard,'+n+'Next,Safe]\n <;> omega']
lean+=['theorem initialSafe : Safe initial := by simp [Safe,initial]','theorem stepPreserves (q t : State) (h : Safe q) (g : Step q t) : Safe t := by\n rcases g with '+'|'.join('g' for _ in range(len(E)+1))]+[' · rcases g with ⟨g,rfl⟩; exact '+n+'Preserves q h g' for n,_,_ in E]+[' · simpa [g] using h','inductive Reachable : State → Prop where\n | init : Reachable initial\n | next {q t : State} : Reachable q → Step q t → Reachable t','theorem reachableSafe {q : State} (h : Reachable q) : Safe q := by\n induction h with\n | init => exact initialSafe\n | next _ step ih => exact stepPreserves _ _ ih step']
props=[('entryHandoff','q.outerGuard=1','q.target=1 ∧ q.ack=1 ∧ q.source=0 ∧ q.descriptor=1'),('outerInvalidatesInner','q.unwind≥1','q.outerRight=0 ∧ q.innerRight=0'),('unknownKeepsCustody','q.outcome=1','q.outerGuard=2 ∧ q.innerGuard=2 ∧ q.target=1 ∧ q.descriptor=1'),('scannerPinsDescriptor','q.gcReader=1','q.descriptor=1 ∧ q.target=1'),('capturePinsDescriptor','q.captured=1','q.descriptor=1 ∧ q.target=1'),('descriptorRetirementCut','q.descriptor=0','q.gcReader=0 ∧ q.captured=0 ∧ q.outerGuard=3 ∧ q.innerGuard=3 ∧ q.rootRetired=1 ∧ q.landed=1'),('lateEntryClosed','q.rootClosed=1','q.shotGuard=0 ∧ q.captured=0'),('retiredRootsNoReader','q.rootRetired=1','q.gcReader=0 ∧ q.source=0 ∧ q.target=0'),('settledOuterNeedsSettledInner','q.outerGuard=3','q.innerGuard=3 ∧ q.landed=1'),('resumptionNoNativeRevival','q.shotGuard=1','q.innerRight=0 ∧ q.outerRight=0 ∧ q.shotTicket≥1')]
for n,g,p in props:lean+=['theorem '+n+' (q : State) (h : Safe q) (g : '+g+') : '+p+' := by\n simp only [Safe] at h\n omega']
lean+=['end NestedDomain'];(B/'models/lean/NestedDomain.lean').write_text('\n'.join(lean)+'\n')
(C/'model-data.json').write_text(json.dumps(dict(fields=fields,initial=initial,invariants=inv,edges=E,histories=len(hist),properties=props),indent=2))
print(len(fields),'fields',len(inv),'invariants',len(E),'actions',len(hist),'histories')
