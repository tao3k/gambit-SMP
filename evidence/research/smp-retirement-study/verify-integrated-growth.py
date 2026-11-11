"""Evidence-only bootstrap + staged growth protocol controls; no native execution."""
from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check,counterexample
ROOT=Path(__file__).resolve().parents[3]
NAMES=['initSuccess', 'initCreatePrefix', 'initPartialViews', 'initBlockedJoin', 'initNativeCloseFault', 'initHeldPublisher', 'initAbortRetry', 'initGateDeadline', 'initStartupFailure', 'initBootstrapRepeatOpen', 'initBootstrapWrongVm', 'initBootstrapWrongSlot', 'initBootstrapSlotFail', 'initBootstrapProcFail', 'initBootstrapLateFail', 'initBootstrapCleanupFault', 'initBootstrapRepeatRetained', 'initBootstrapRetryClean', 'initBootstrapRepeatClosed', 'initBootstrapTeardownSetup', 'initBootstrapOpenFail', 'initEarlyOpen', 'initEarlyBind', 'initEagerAllocator', 'initGcDuringPrivate', 'initFreeBeforeJoin', 'initDropPrimaryOnHintDenial', 'initCheckThenPin', 'initRevokePriorLease', 'initForgetQueueLease', 'initForgetWakeLease', 'initReuseRetained', 'initStaleEpochGo', 'initDebtReset', 'initStaleThunk', 'initPostGoRollback', 'initAckFutureDebt', 'initForeignHeapNode', 'initReusedSectionPair', 'initBootstrapLookupBeforeBind', 'initBootstrapAliasP0', 'initBootstrapOpenBeforeReady', 'initBootstrapDestroyUninitialized', 'initBootstrapDoubleDestroy', 'initBootstrapResetLive', 'initBootstrapForgetRetained', 'initBootstrapEraseError', 'initBootstrapDoubleInit', 'initBootstrapGrowthBeforeOpen', 'initBootstrapRootDropOnOpenFail', 'initMissingGateDeadline', 'initAssumeJoinRecovers', 'initStopJoinLaneAfterResume', 'initTicketConcurrent', 'initTicketRecursive', 'initTicketNested', 'initTicketStaleNonce', 'initTicketRetained', 'initTicketOpenReturn', 'initTicketRenewal', 'initTicketGuardUninitialized', 'initTicketGuardAcrossScheme', 'initTicketConcurrentReset', 'initTicketRecursiveReuse', 'initTicketNestedAuthority', 'initTicketStaleDelegate', 'initTicketDropContext', 'initTicketStackRecord', 'initTicketEarlyRenewal', 'initMappedReady', 'initMappedOpenFailure', 'initMappedTailFailure', 'initMappedRenewal', 'initDeclaredNotSpilled', 'initSpillWithoutMap', 'initGcInsideBridge', 'initUseBeforeReload', 'initPublishBeforeSlotRelease', 'initObserveWithoutAcquire', 'initDestroyBorrowedMutex', 'initDropPinBeforeTail', 'initThrowWithNativeBorrow', 'initRenewBeforeTail', 'initEraseObligationsOnReturn']
NEGATIVE=set(['initEarlyOpen', 'initEarlyBind', 'initEagerAllocator', 'initGcDuringPrivate', 'initFreeBeforeJoin', 'initDropPrimaryOnHintDenial', 'initCheckThenPin', 'initRevokePriorLease', 'initForgetQueueLease', 'initForgetWakeLease', 'initReuseRetained', 'initStaleEpochGo', 'initDebtReset', 'initStaleThunk', 'initPostGoRollback', 'initAckFutureDebt', 'initForeignHeapNode', 'initReusedSectionPair', 'initBootstrapLookupBeforeBind', 'initBootstrapAliasP0', 'initBootstrapOpenBeforeReady', 'initBootstrapDestroyUninitialized', 'initBootstrapDoubleDestroy', 'initBootstrapResetLive', 'initBootstrapForgetRetained', 'initBootstrapEraseError', 'initBootstrapDoubleInit', 'initBootstrapGrowthBeforeOpen', 'initBootstrapRootDropOnOpenFail', 'initTicketGuardUninitialized', 'initTicketGuardAcrossScheme', 'initTicketConcurrentReset', 'initTicketRecursiveReuse', 'initTicketNestedAuthority', 'initTicketStaleDelegate', 'initTicketDropContext', 'initTicketStackRecord', 'initTicketEarlyRenewal', 'initDeclaredNotSpilled', 'initSpillWithoutMap', 'initGcInsideBridge', 'initUseBeforeReload', 'initPublishBeforeSlotRelease', 'initObserveWithoutAcquire', 'initDestroyBorrowedMutex', 'initDropPinBeforeTail', 'initThrowWithNativeBorrow', 'initRenewBeforeTail', 'initEraseObligationsOnReturn'])
TEMPORAL={'initMissingGateDeadline': 'progress', 'initAssumeJoinRecovers': 'unconditional', 'initStopJoinLaneAfterResume': 'progress'}
def distinguished(name,s):
 def aset(k):
  v=s[k];return set(v.get('$integerSet',[])) if isinstance(v,dict) else set(v)
 def at(k,i):
  v=s[k];return v[i-1] if isinstance(v,list) else v.get(str(i),v.get(i))
 tests={
 'initEarlyOpen':lambda:s['publicOpen'] and aset('ready')!={2,3},
 'initEarlyBind':lambda:not aset('bound').issubset(aset('go')),
 'initEagerAllocator':lambda:s['held'] and s['assigned']!=s['base'],
 'initGcDuringPrivate':lambda:s['held'] and not s['excluded'],
 'initFreeBeforeJoin':lambda:s['controlFreed'] and aset('joined')!=aset('created'),
 'initDropPrimaryOnHintDenial':lambda:not s['primaryDone'] and not s['hintDebt'],
 'initCheckThenPin':lambda:1 in aset('leases') and at('grantGen',1)==0,
 'initRevokePriorLease':lambda:at('req',2)==1 and 2 not in aset('leases'),
 'initForgetQueueLease':lambda:s['freed'] and bool(aset('queue')),
 'initForgetWakeLease':lambda:s['freed'] and bool(aset('wake')),
 'initReuseRetained':lambda:s['joinFault'] and s['epoch']==2,
 'initStaleEpochGo':lambda:s['epoch']==2 and bool(aset('go')) and not s['committed'],
 'initDebtReset':lambda:s['cut']>s['demand'],
 'initStaleThunk':lambda:s['staleRead'],
 'initPostGoRollback':lambda:s['committed'] and s['assigned']==s['base'],
 'initAckFutureDebt':lambda:s['ack']>s['cut'],
 'initForeignHeapNode':lambda:99 in aset('usedNodes'),
 'initReusedSectionPair':lambda:len(aset('usedNodes'))!=2*len(aset('views')),
 'initBootstrapLookupBeforeBind':lambda:s['invalidLookup'] and not s['identityBound'],
 'initBootstrapAliasP0':lambda:s['identityBound'] and s['bootVm']!=1,
 'initBootstrapOpenBeforeReady':lambda:s['bootOpen'] and not s['bootReady'],
 'initBootstrapDestroyUninitialized':lambda:not aset('bootDestroyed').issubset(aset('bootEver')),
 'initBootstrapDoubleDestroy':lambda:s['doubleDestroy'],
 'initBootstrapResetLive':lambda:s['bootBorrow'] and s['bootGrantKey']!=s['bootEpoch'],
 'initBootstrapForgetRetained':lambda:s['boot']==8 and not s['bootPin'],
 'initBootstrapEraseError':lambda:s['bootHadError'] and s['bootErr']==0,
 'initBootstrapDoubleInit':lambda:s['doubleInit'],
 'initBootstrapGrowthBeforeOpen':lambda:s['phase']>0 and not s['bootOpen'],
 'initBootstrapRootDropOnOpenFail':lambda:s['bootReturnPending'] and not s['bootRoots'],
 'initTicketGuardUninitialized':lambda:not s['guardReady'],
 'initTicketGuardAcrossScheme':lambda:s['guardHeld'] and s['contextReader'],
 'initTicketConcurrentReset':lambda:s['recordLive'] and s['ticketNonce']!=s['bootEpoch'],
 'initTicketRecursiveReuse':lambda:s['doubleInit'],
 'initTicketNestedAuthority':lambda:s['scopeId']==2 and s['scopeViolation'],
 'initTicketStaleDelegate':lambda:s['recordLive'] and s['ticketEpoch']!=s['bootEpoch'],
 'initTicketDropContext':lambda:s['contextReader'] and not s['recordLive'],
 'initTicketStackRecord':lambda:s['boot']==8 and s['stackRecord'],
 'initTicketEarlyRenewal':lambda:s['contextReader'] and s['ticketNonce']!=s['bootEpoch'],
 'initDeclaredNotSpilled':lambda:s['nativeBridge'] and not s['registersSpilled'],
 'initSpillWithoutMap':lambda:s['rootVersion']>0 and not s['mappedLanding'],
 'initGcInsideBridge':lambda:s['nativeBridge'] and s['gcInside'],
 'initUseBeforeReload':lambda:s['rootUsed'] and s['cachedVersion']!=s['rootVersion'],
 'initPublishBeforeSlotRelease':lambda:s['registryRelease'] and not s['slotRelease'],
 'initObserveWithoutAcquire':lambda:s['registryAcquire'] and not s['registryRelease'],
 'initDestroyBorrowedMutex':lambda:s['lockBorrow'] and not s['lockAlive'],
 'initDropPinBeforeTail':lambda:s['tailLive'] and not s['contextReader'] and not s['bootPin'],
 'initThrowWithNativeBorrow':lambda:s['bootReturnPending'] and s['lockBorrow'],
 'initRenewBeforeTail':lambda:s['tailLive'] and not s['contextReader'] and s['ticketNonce']!=s['bootEpoch'],
 'initEraseObligationsOnReturn':lambda:s['boot']==7 and not s['contextReader'] and not s['recordLive'] and bool(aset('bootRes')) and not s['tailLive']}
 return bool(tests[name]())
def project_initializer(canonical,name,target):
 text=canonical.read_text();decls={}
 for line in text.splitlines(keepends=True):
  m=re.match(r'  action (init[A-Z][A-Za-z0-9_]*)=',line)
  if m:
   key=m.group(1)
   assert key not in decls,key
   decls[key]=line
 assert set(decls)==set(NAMES),(set(decls)-set(NAMES),set(NAMES)-set(decls))
 # Erasure is sound only for zero-reference alternative entry declarations.
 for key in decls:assert len(re.findall(r'\b'+key+r'\b',text))==1,key
 erased=[key for key in decls if key!=name]
 projected=text
 for key in erased:projected=projected.replace(decls[key],'')
 assert decls[name] in projected and len(projected)<len(text)
 # bug is immutable: only its State declaration and initial constructor assign it.
 assert len(re.findall(r'\bbug\s*:',text))==2
 calls=re.findall(r'(?:initial|bootInitial|ticketInitial)\(\d+,(\d+)\)',decls[name]);assert len(calls)==1
 bug=int(calls[0]);removed=[]
 def split_top(body):
  parts=[];depth=0;start=0
  for i,c in enumerate(body):
   if c in '([{':depth+=1
   elif c in ')]}':depth-=1
   elif c==',' and depth==0:parts.append(body[start:i].strip());start=i+1
  parts.append(body[start:].strip());return parts
 for action in ['bad','bootBad','ticketBad','bridgeBad']:
  match=re.search(r'  action '+action+r'=any \{',projected);assert match,action
  start=match.end();depth=1;end=start
  while depth:
   if projected[end]=='{':depth+=1
   elif projected[end]=='}':depth-=1
   end+=1
  branches=split_top(projected[start:end-1]);kept=[]
  for branch in branches:
   guard=re.match(r'all \{s\.bug==(\d+),',branch);assert guard,(action,branch[:80])
   n=int(guard[1])
   if n==bug:kept.append(branch)
   else:removed.append(dict(action=action,guardBug=n))
  replacement='any {'+','.join(kept)+'}' if kept else "all {false,s'=s}"
  projected=projected[:match.start()]+'  action '+action+'='+replacement+projected[end:]
 # Additional scene selectors are immutable in every protocol action.
 selectors=['mode','bootMode','ticketMode','mapMode']
 call=re.search(r'\b(initial|bootInitial|ticketInitial)\((\d+),(\d+)\)',decls[name]);assert call
 values=dict(mode=0,bootMode=0,ticketMode=0,mapMode=0)
 values[{'initial':'mode','bootInitial':'bootMode','ticketInitial':'ticketMode'}[call[1]]]=int(call[2])
 for field in selectors:
  override=re.findall(r'\b'+field+r':(\d+)',decls[name])
  if override:values[field]=int(override[-1])
 # All constructors are the canonical fixed functions; no step action writes
 # these fields or replaces the state through an initializer/constructor.
 actions=list(re.finditer(r'^  action (\w+)(?:\([^\n]*?\))?(?::bool)?=',text,re.M))
 for i,m in enumerate(actions):
  if m[1].startswith('init'):continue
  end=actions[i+1].start() if i+1<len(actions) else len(text)
  body=text[m.end():end]
  # Terminate before following pure/value/temporal declaration.
  body=re.split(r'\n  (?:pure |val |temporal )',body,maxsplit=1)[0]
  assert not re.search(r'\b(?:mode|bootMode|ticketMode|mapMode)\s*:',body),m[1]
  assert not re.search(r'\b(?:initial|bootInitial|ticketInitial)\(',body),m[1]
 for field,value in values.items():projected=re.sub(r'\bs\.'+field+r'\b',str(value),projected)
 target.write_text(projected)
 proof=dict(kind='unreferenced-initializer-erasure-and-immutable-bug-specialization' ,canonicalSha256=hashlib.sha256(canonical.read_bytes()).hexdigest(),
  compiledSha256=hashlib.sha256(target.read_bytes()).hexdigest(),selected=name,erased=erased,
  disabledBugBranches=removed,immutableBug=bug,allInvariantsAndFairnessUnmodified=True,immutableSceneSelectors=values,normalActionsOnlyImmutableSelectorReadsSpecialized=True)
 (target.parent/'projection.json').write_text(json.dumps(proof,indent=2)+'\n')
 return proof


def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/integrated-growth-model');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/integrated_growth.qnt';snapshot=out/model.name;snapshot.write_bytes(model.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  receipt=dict(schema='integrated-growth-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],nativeAdmitted=False,perCaseTimeoutSeconds=30)
  for i,name in enumerate(NAMES):
   case=out/name;case.mkdir();neg=name in NEGATIVE;temporal=None if neg else TEMPORAL.get(name,'progress')
   compiled=case/model.name;projection=project_initializer(snapshot,name,compiled)
   row,log,trace=check(compiled,initializer=name,invariant='safe',negative=neg,temporal=temporal,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   row['sourceProjection']=projection
   (case/'check.log').write_text(log)
   if neg:
    row['expected']='invariant-counterexample';row['witness']=(trace or {}).get('states',[])[-1:]
    row['accepted']=bool(row['accepted'] and row['witness'] and distinguished(name,row['witness'][0]['s']))
   elif name in TEMPORAL:
    row['expected']='temporal-counterexample';row['backendAccepted']=row['accepted']
    cleaned=re.sub(r'^State \d+: Stuttering[^\n]*\n','',log,flags=re.M)
    try:trace=counterexample(cleaned)
    except ValueError:trace=None
    loop=re.search(r'Back to state (\d+)|State (\d+): Stuttering',log)
    row['cycleMarker']=loop.group(0) if loop else None
    row['accepted']=bool(not row['timeout'] and row['exit']!=0 and
      re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and loop and trace and
      row['checker']['inputsStable'] and row['checker']['phase']=='tlc')
    if trace:(case/'counterexample.json').write_text(json.dumps(trace,indent=2)+'\n')
   else:row['expected']='safety-and-conditional-progress'
   receipt['rows'].append(dict(initializer=name,**row));receipt['allAccepted']=len(receipt['rows'])==len(NAMES) and all(x['accepted'] for x in receipt['rows'])
   (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),row.get('cycleMarker'),flush=True)
   if 'parsing failed' in log or 'typechecking failed' in log or row['checker'].get('phase')=='compile' and not row['accepted']:break
  print(out,flush=True)
 if not receipt['allAccepted']:raise RuntimeError('integrated bootstrap/growth controls incomplete; retained result is not a pass')
if __name__=='__main__':main()
