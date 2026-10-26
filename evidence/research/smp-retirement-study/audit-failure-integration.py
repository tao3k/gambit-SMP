from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
R=Path(__file__).resolve().parents[3];E=R/'evidence/research/smp-retirement-study'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_text())
def apply_unified(src,patch,name,reverse=False):
 lines=patch.splitlines(keepends=True);start=next(i for i,z in enumerate(lines) if z.rstrip()=='--- a/'+name);end=next((i for i in range(start+2,len(lines)) if lines[i].startswith('--- a/')),len(lines))
 old=src.splitlines(keepends=True);result=[];cursor=0;i=start+2
 while i<end:
  m=re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',lines[i])
  if not m:i+=1;continue
  pos=int(m[3 if reverse else 1])-1;assert pos>=cursor;result+=old[cursor:pos];cursor=pos;i+=1
  while i<end and not lines[i].startswith('@@ '):
   z=lines[i];i+=1
   if z.startswith('\\'):continue
   op=z[:1];body=z[1:]
   if reverse and op in [' ','+','-']:op={'+':'-','-':'+',' ':' '}[op]
   if op in [' ','-']:assert old[cursor]==body,(name,cursor);cursor+=1
   if op in [' ','+']:result.append(body)
 result+=old[cursor:];return ''.join(result)
def defs(t):
 a=t.splitlines();found=[]
 for i,z in enumerate(a):
  m=re.match(r'\(define(?:-prim)? \((##[^\s()]+)',z)
  if m:found.append((i,m[1]))
 result={}
 for k,(i,name) in enumerate(found):result.setdefault(name,{'first':i+1,'last':(found[k+1][0] if k+1<len(found) else len(a))})
 return result
protected=load(E/'diagnostic-order-id-generated-c.json')['protectedInputs'];before={n:sha(R/n) for n in protected}
lock=R/'evidence/research/processor-interrupt-collective-wait/scan-session-cut.lock.json';L=load(lock)
old=load(E/'diagnostic-order-id-generated-c.json');oldroot=R/old['candidate']
newroot=R/'.cache/tasks/repair-9-12/processes/audit/runs/b2ea3ef93eb841b2aa22bb24de539809/outputs/scan-session-cut-implementation/candidate'
good=load(E/'owned-request-native-validation.json');patch=E/'owned-request-fault-coordinator-native.patch'
assert sha(R/L['patch'])==L['patchSha256'];assert sha(patch)==good['patches'][patch.name]
with work_process.scope(R,'repair-9-12','audit'):
 out=workspace.task_output(R,R/'.cache/failure-integration-audit');out.mkdir(parents=True,exist_ok=True)
 current={}
 for name,row in L['files'].items():
  p=newroot/name if (newroot/name).exists() else oldroot/name
  if sha(p)!=row['candidateSha256']:
   prior=oldroot/name;assert sha(prior)==old['sourceHashes'][name]
   base=apply_unified(prior.read_text(),(R/old['patch']).read_text(),name,True)
   assert hashlib.sha256(base.encode()).hexdigest()==row['baseSha256'],name
   text=apply_unified(base,(R/L['patch']).read_text(),name)
   p=out/'current-lock-source'/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
  assert sha(p)==row['candidateSha256'],name
  current[name]={'path':str(p.relative_to(R)),'sha256':sha(p)}
 reconstructed={}
 for name,row in good['sources'].items():
  p=R/row['beforePath'];assert sha(p)==row['before'];text=apply_unified(p.read_text(),patch.read_text(),name)
  q=out/'native-tested-source'/name;q.parent.mkdir(parents=True,exist_ok=True);q.write_text(text);assert sha(q)==row['after'],name
  reconstructed[name]={'path':str(q.relative_to(R)),'sha256':sha(q),'currentLockBound':name in current,'currentLockSame':current[name]['sha256']==sha(q) if name in current else None}
 native=[]
 for name,row in good['native'].items():
  p=R/row['receipt'];assert sha(p)==row['sha256'];data=load(p);assert data['gsiSha256']==good['gsiSha256']
  checks=[r for r in data.get('rows',data.get('stages',[])) if 'passed' in r];assert all(r['passed'] for r in checks)
  native.append({'name':name,'path':str(p.relative_to(R)),'sha256':sha(p),'gsiSha256':data['gsiSha256'],'checks':checks})
 final=load(R/good['native']['owned-request-final']['receipt']);fp=(R/good['native']['owned-request-final']['receipt']).parent/'flood.scm';assert sha(fp)==final['floodSha256']
 for r in final['rows']:
  if r['name'].startswith('flood-'):
   log=fp.parent/(r['name']+'.log');assert log.exists() and 'PROBE-DONE 100000' in log.read_text();r['retainedLogSha256']=sha(log)
 ct=(R/current['lib/_thread.scm']['path']).read_text();gt=(out/'native-tested-source/lib/_thread.scm').read_text()
 markers=['##thread-intr-notify!','##thread-intr-wake!','##thread-intr-execute!','##thread-intr-drain!']
 features={k:{'currentDefinition':k in defs(ct),'testedDefinition':k in defs(gt)} for k in markers}
 features['nativeWaitBackend']={'currentCappedBackend':'device_select_with_cap' in (R/current['lib/os_io.c']['path']).read_text(),'testedCappedBackend':'device_select_with_cap' in (out/'native-tested-source/lib/os_io.c').read_text()}
 features['requestConstructor']={'current2Fields':"(interrupt (##vector '() result-mutex))" in ct,'tested4Fields':"(interrupt (##vector '() result-mutex thread 0))" in gt}
 features['preRemovalPredicate']={'currentSignature':'(define-prim (##thread-lock-remove-btq-toq! thread proc arg1)' in ct,'testedSignature':[z for z in gt.splitlines() if z.startswith('(define-prim (##thread-lock-remove-btq-toq!')]}
 funcs={'current':defs(ct),'tested':defs(gt)}
 tfib=load(E/'tfib-crash-binding.json');tr=R/tfib['auditReceipt']
 report=dict(schema='failure-integration-audit.v1',sourceLock=str(lock.relative_to(R)),sourceLockSha256=sha(lock),patchSha256=L['patchSha256'],all26CurrentFilesVerified=current,nativeTestedPatchSha256=sha(patch),nativeTestedSources=reconstructed,nativeReceiptsRehashed=native,testedGsiSha256=good['gsiSha256'],flood=dict(path=str(fp.relative_to(R)),sha256=sha(fp),rows=[r for r in final['rows'] if r['name'].startswith('flood-')]),features=features,functionRanges=funcs,tfib=dict(binding=str((E/'tfib-crash-binding.json').relative_to(R)),bindingSha256=sha(E/'tfib-crash-binding.json'),auditReceipt=str(tr.relative_to(R)),auditReceiptAvailable=tr.exists(),auditReceiptSha256=sha(tr) if tr.exists() else None,failedGsiSha256=tfib['files']['gsi/gsi']['sha256'],fault=tfib['fault'],firstCorruptingWriterEstablished=False),protectedInputsUnchanged=before=={n:sha(R/n) for n in protected},nativeRuns=0,modelReruns=0,runtimeChanged=False,qualifierChanged=False,historicalReceiptsChanged=False,peerAction=False,commitOrPush=False)
 assert report['protectedInputsUnchanged'];(out/'receipt.json').write_text(json.dumps(report,indent=2)+'\n');print(out/'receipt.json');print(json.dumps(features,indent=2));print('seven-source-match',[(k,v['currentLockSame']) for k,v in reconstructed.items()])
