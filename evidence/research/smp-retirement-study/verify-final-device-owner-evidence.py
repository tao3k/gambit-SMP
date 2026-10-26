"""Verification-only receipt: do not mutate, compile or publish runtime code."""
from pathlib import Path
import hashlib,json
from gambit_smp import workspace,work_process
from gambit_smp.framework import execute
ROOT=Path(__file__).resolve().parents[3]
AREA=ROOT/'evidence/research/smp-retirement-study'
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text())
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/final-device-owner-verification');out.mkdir(parents=True,exist_ok=True)
  previous=read(AREA/'device-callback-native-validation.json')
  guard_path=ROOT/'.cache/tasks/repair-9-12/runs/3fc0e6d6492844bcb7ae9de0c46282e0/outputs/fault-owner-guard/receipt.json';guard=read(guard_path)
  receipt=dict(schema='final-device-owner-verification.v1',task='repair-9-12',producer=str(BUILD.relative_to(ROOT)),gsiSha256=sha(SOURCE/'gsi/gsi'),runtimeModifiedByVerification=False,integrationOwner='Grok; no other thread contacted or operated on',nativeAdmitted=False,qualification='8/12 unchanged',sources={},native=[],patchReplay=[])
  assert receipt['gsiSha256']==guard['gsiSha256']=='7263fe0376e89ddf1d4527a7a9701c5943136346f82477c14d2de05e51104808'
  assert guard['sources']['lib/_thread.scm']['before']==previous['sources']['lib/_thread.scm']['after']
  for n,v in previous['sources'].items():
   expected=guard['sources'][n]['after'] if n in guard['sources'] else v['after'];assert sha(SOURCE/n)==expected
   receipt['sources'][n]=dict(sha256=expected)
   base=ROOT/v['beforePath'];p=out/'replay'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(base.read_bytes())
  old=read(AREA/'owned-request-native-validation.json')
  for n,v in old['sources'].items():
   if n not in receipt['sources']:assert sha(SOURCE/n)==v['after'];receipt['sources'][n]=dict(sha256=v['after'])
  for name in ['device-callback-full-closure.patch','fault-owner-guard.patch']:
   artifact=AREA/name;snapshot=out/name;snapshot.write_bytes(artifact.read_bytes());meta={}
   rc,log,to,sec=execute(['/usr/bin/patch','--batch','-p1','-i',str(snapshot)],out/'replay',30,metadata=meta);(out/(name+'.log')).write_text(log)
   receipt['patchReplay'].append(dict(name=name,sha256=sha(snapshot),exit=rc,timedOut=to,seconds=sec,process=meta));assert not rc and not to
  receipt['replayMatchesFinal']=all(sha(out/'replay'/n)==sha(SOURCE/n) for n in previous['sources']);assert receipt['replayMatchesFinal']
  run='0435aab786604b139a320715f8535ec4'
  for name,key in [('fault-owner-native','rows'),('device-callback-native','rows'),('real-device-close','rows'),('owned-request-native','rows'),('marker-ffi-native','stages'),('owned-request-final','rows'),('accepted-fault-native','rows'),('final-deadline-native','rows')]:
   selected_run='5f62b1bf99b443e9b092f0766b300109' if name=='fault-owner-native' else run
   p=ROOT/'.cache/tasks/repair-9-12/runs'/selected_run/'outputs'/name/'receipt.json';data=read(p);checks=[x for x in data[key] if 'passed' in x]
   assert data['gsiSha256']==receipt['gsiSha256'] and checks and all(x['passed'] and not x['timedOut'] and x['process']['parentReaped'] and x['process']['processGroupQuiescent'] for x in checks)
   receipt['native'].append(dict(name=name,receipt=str(p.relative_to(ROOT)),sha256=sha(p),checks=checks))
  receipt['targetedNativeControls']=sum(len(x['checks']) for x in receipt['native']);assert receipt['targetedNativeControls']==39
  p=ROOT/'.cache/tasks/repair-9-12/processes/audit/runs/51de1dacc83d4ec48713e651e5ce7ee3/outputs/device-callback-model/receipt.json';data=read(p)
  assert data['allAccepted'] and len(data['rows'])==11 and data['modelSha256']==sha(ROOT/'models/gambit/device_callback_retention.qnt')
  receipt['qnt']=dict(receipt=str(p.relative_to(ROOT)),sha256=sha(p),modelSha256=data['modelSha256'],controls=11,positive=1,negative=10)
  receipt['generated']={n:sha(SOURCE/n) for n in ['lib/_thread.c','lib/_gambit.c','include/gambit.h']}
  receipt['conclusion']=dict(deviceFailureOwnership='closed for checked cleanup/canonical native devices on tested Darwin producer',callbackEscape='closed for public winding exits and protected coordinator terminate/suspend on tested producer',integration='not landed; Grok owns integration',fullQualification='not executed; 8/12 remains')
  receipt['allAccepted']=True
  (out/'receipt.json').write_text(json.dumps(receipt,indent=2));(AREA/'final-device-owner-verification.json').write_text(json.dumps(receipt,indent=2))
  note='''

### 2026-10-23 Verification-only handoff: protected coordinator and final device/root regression

The latest user instruction assigns runtime integration to Grok. Verification
performed after that boundary did not modify or recompile runtime sources; it
only exercised the already-built experimental producer, extended QNT negatives,
replayed existing patches in an audit fixture and retained evidence. No message
was sent to another thread. No new commit, staging, push or full inventory ran.

Final experimental GSI SHA256 is7263fe0376e89ddf1d4527a7a9701c5943136346f82477c14d2de05e51104808.
Build3fc0e6d6492844bcb7ae9de0c46282e0 finished the previously started coordinator
owner protection. `##thread-terminate!` and `##thread-suspend!` reject the active
fault control thread at their private entry, outside held scheduler/thread locks
and before consuming its lifecycle state. This is necessary because actual
`##thread-end-current-thread!` terminates/schedules without a winding transition.
The per-callback dynamic-wind guard alone could not protect that path.

Native run0435aab786604b139a320715f8535ec4 binds all39 targeted control rows to
that one GSI. Permanent EBADF and persistent EINTR each triggered actual public
self-terminate and self-suspend attempts. Each attempt marker occurred once; the
coordinator survived, processed the suffix, retained the actual refusal/error
and payload through GC, then reached P0 preparation, ten worker marker retirements
and zero wake-writer/selector/marker grace with deliberate exit70. These are real
invocations, not merely checking that guard source exists.

The same final executable passed device read/write/release failures, EAGAIN wait
recheck, real file-port EIO/EBADF/EINTR-before-close/EINTR-after-close injection,
exit-job call/cc and final-will continuation-graft escape/reentry, canonical
foreign wrapper one-shot release, and P1-created wrappers across GC/retirement
handoff. Failed close/release retains the native owner and VM roots and reports
failure before destruction. Successful wrapper release happens once. Every
original file close was attempted once; a replacement descriptor was usable and
was closed by its own owner. The earlier24 request/wake/FFI/active-sender/deadline
controls also passed on these same bytes, including8/8 rounds of100000 requests
atp11 and600 nested C/Scheme calls across GC. The250ms wait measured255.118132ms.

Audit51de1dacc83d4ec48713e651e5ce7ee3 passed the final combined model's safety
and fair terminal-disposition control plus ten decoded negatives. Separate
terminate-coordinator and suspend-coordinator initializers expose loss of the
unique carrier; foreign last-consumer and premature root/group/device release
negatives remain. Terminal disposition includes checked retained failure and
does not require incorrectly freeing failed storage.

`evidence/research/smp-retirement-study/final-device-owner-verification.json`
is the final identity/receipt index. Existing device-callback-full-closure and
fault-owner-guard patches were replayed together in an audit fixture; the result
matches all six changed source files byte-for-byte, while the four other prior
source identities remain unchanged. They are experimental evidence for Grok's
integration, not an instruction that integration or qualification is complete.
The function/ownership/root correspondence is in `fault-owner-verification.md`.

Conclusion: the two named gaps are closed within the tested checked-host,
canonical-device and public-winding/protected-owner contracts. Valid quiesced VM
ownership and finite callback/unwind bodies remain prerequisites; arbitrary raw
private no-winding/C jumps keep the previously tested cleanup-refusal boundary.
This is not complete native/Gerbil or 9/12 acceptance. Qualification remains8/12,
producer source phase building/runtimeAdmitted=false. Runtime landing belongs to
Grok; this verification does not grant admission or modify the other thread.
'''
  doc=ROOT/'docs/current-repair-research.md';doc.write_text(doc.read_text()+note)
  print(out,flush=True)
if __name__=='__main__':main()
