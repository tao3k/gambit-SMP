"""Bind the tested generation, replay the delta and update Current Work."""
from pathlib import Path
import difflib,hashlib,json
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
  out=workspace.task_output(ROOT,ROOT/'.cache/device-callback-final');out.mkdir(parents=True,exist_ok=True)
  old=read(AREA/'owned-request-native-validation.json')
  receipt=dict(schema='device-callback-final.v1',baseGsiSha256=old['gsiSha256'],gsiSha256=sha(SOURCE/'gsi/gsi'),sources={},native=[],nativeAdmitted=False,qualification='8/12 unchanged',fullInventoryExecuted=False)
  first=ROOT/'.cache/tasks/repair-9-12/runs/04c02a93cc894799b8a2de54b6b2175d/outputs/device-callback-closure/before'
  second=ROOT/'.cache/tasks/repair-9-12/runs/180f1b10e65f4c04930705ff6bab2cdd/outputs/device-foreign-handoff/before'
  patch='';names=['lib/os_io.c','lib/os_io.h','lib/setup.c','lib/_thread.scm','lib/mem.c','lib/mem.h']
  for n in names:
   p=first/n if (first/n).exists() else second/n
   if n in old['sources']:assert sha(p)==old['sources'][n]['after']
   target=out/'replay'/n;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(p.read_bytes())
   receipt['sources'][n]=dict(before=sha(p),after=sha(SOURCE/n),beforePath=str(p.relative_to(ROOT)))
   patch+=''.join(difflib.unified_diff(p.read_text().splitlines(keepends=True),(SOURCE/n).read_text().splitlines(keepends=True),fromfile='a/'+n,tofile='b/'+n))
  for n,v in old['sources'].items():
   if n not in names:assert sha(SOURCE/n)==v['after']
  artifact=out/'device-callback-full-closure.patch';artifact.write_text(patch);(AREA/artifact.name).write_text(patch)
  meta={};rc,log,to,sec=execute(['/usr/bin/patch','--batch','-p1','-i',str(artifact)],out/'replay',30,metadata=meta);(out/'patch-replay.log').write_text(log)
  receipt['patch']=dict(path=str((AREA/artifact.name).relative_to(ROOT)),sha256=sha(artifact),exit=rc,timedOut=to,seconds=sec,process=meta,identical=all(sha(out/'replay'/n)==sha(SOURCE/n) for n in names));assert not rc and not to and receipt['patch']['identical']
  native=[('ed884cbaefe34fdd84498e8f59446198','device-callback-native','rows'),('b8ffeb54c80741cabf669e13c1f35a19','real-device-close','rows'),('b8ffeb54c80741cabf669e13c1f35a19','owned-request-native','rows'),('b8ffeb54c80741cabf669e13c1f35a19','marker-ffi-native','stages'),('b8ffeb54c80741cabf669e13c1f35a19','owned-request-final','rows'),('b8ffeb54c80741cabf669e13c1f35a19','accepted-fault-native','rows'),('b8ffeb54c80741cabf669e13c1f35a19','final-deadline-native','rows')]
  for run,name,key in native:
   p=ROOT/'.cache/tasks/repair-9-12/runs'/run/'outputs'/name/'receipt.json';d=read(p);rows=[x for x in d[key] if 'passed' in x]
   assert d['gsiSha256']==receipt['gsiSha256'] and rows and all(x['passed'] and not x['timedOut'] and x['process']['parentReaped'] and x['process']['processGroupQuiescent'] for x in rows),name
   receipt['native'].append(dict(name=name,receipt=str(p.relative_to(ROOT)),sha256=sha(p),checks=rows))
  receipt['targetedNativeControls']=sum(len(x['checks']) for x in receipt['native']);assert receipt['targetedNativeControls']==37
  p=ROOT/'.cache/tasks/repair-9-12/processes/audit/runs/c211afe312e241249e728c66409823ae/outputs/device-callback-model/receipt.json';model=read(p)
  assert model['allAccepted'] and len(model['rows'])==9 and model['modelSha256']==sha(ROOT/'models/gambit/device_callback_retention.qnt')
  receipt['model']=dict(receipt=str(p.relative_to(ROOT)),sha256=sha(p),controls=9,modelSha256=model['modelSha256'])
  receipt['generated']={n:sha(SOURCE/n) for n in ['lib/_thread.c','lib/_gambit.c','include/gambit.h']}
  receipt['allAccepted']=True
  receipt['boundary']=['Darwin POSIX producer and canonical device foreign release functions.', 'Hard close/release failure reports retained-owner failure; it does not resume the poisoned VM.', 'Public winding continuations are contained; raw private no-winding/C jumps retain the earlier checked-cleanup refusal contract.', 'Finite callback bodies/unwind handlers and a valid quiesced host VM borrow remain required.', 'No complete native inventory, performance/ABI admission, Gerbil acceptance or 9/12 increment is claimed.']
  (out/'receipt.json').write_text(json.dumps(receipt,indent=2));(AREA/'device-callback-native-validation.json').write_text(json.dumps(receipt,indent=2))
  note='''

### 2026-10-23 Applied device-error ownership and callback-escape closure

The two previously open paths now have actual source changes and same-producer
native controls. This supersedes the earlier device-close ownership and public
winding callback-escape limitations; historical receipts remain unchanged.
`evidence/research/smp-retirement-study/device-callback-native-validation.json`
binds the six-file delta, source/generated-C/GSI identities, actual patch replay,
37 targeted native controls and the new nine-control QNT receipt. The delta is
`device-callback-full-closure.patch`, applied after the preceding1a32b364 GSI
source generation. It is not a new workspace, framework seal or completed producer.

Native device close errors are sticky immediate codes. A hard read/write/select
error keeps the node linked and its owning reference intact. Close success is
required before unlink; release failure restores a retained allocation/reference
and group link, without re-entering the partly executed release callback. Checked
group/module cleanup returns the error and preserves the failed node and untouched
suffix. POSIX file/pipe/socket device close uses one syscall attempt: EINTR cannot
authorize a second close of an ambiguously consumed descriptor number. A readiness
select EINTR after close returned EAGAIN is instead rechecked as a soft wait event.
The native EAGAIN control exposed this distinction and it was fixed in source.

The actual final consumer is not only the group: still-object Scheme foreign
wrappers may retain the device release callback. `___prepare_device_foreigns_vmstate`
walks those canonical wrappers under sealed/quiescent teardown, calls their
one-shot `___release_foreign` while every VM root remains intact, and checks each
result. Device group cleanup follows only afterward. Normal `free_still_objs`
then sees disarmed wrappers and cannot double-release. Any failure returns from
`___cleanup_checked` before processor/VM/GC memory destruction. The error state is
retained and cannot be treated as a successful cleanup or a resumable VM.

Each fault exit job/final will runs inside `##fault-control-callback!`, with a
mapped recovery continuation outside a per-invocation dynamic-wind guard. Public
outward continuation return/graft is intercepted by the after action, which
retires that invocation, records a rooted escape diagnostic/current item, and
returns to the coordinator's recovery point. The consumed prefix stays consumed;
the remaining cursor continues once. The guard's before action rejects retired
continuation reentry. Item, suffix and error remain VM-rooted through nested GC.

Final GSI SHA256 is60b1260d3369b97b5c5f2bc50f9d7b7b1afb74dfdbbe6fcc548746029b6dee03.
Nativeed884cbaefe34fdd84498e8f59446198 passed five local device cases (success,
read failure, write failure, EAGAIN, release failure), exit-job call/cc escape,
final-will continuation-graft escape, retired-continuation attempts, global
device-error retention and real Scheme foreign wrapper success/failure. P1-created
wrappers were retained across GC and actual retirement handoff: success releases
once; failure leaves the wrapper disarmed, native owner linked and VM root live.
Both callback lanes preserve the suffix/error across GC and reach prepared exit.

Nativeb8ffeb54c80741cabf669e13c1f35a19 interposed actual Scheme file-port close
syscalls with EIO, EBADF, EINTR-before-close and EINTR-after-real-close. All four
record one original close attempt. Replacement files remain usable and close
through their own legitimate owner. Permanent device failures deliberately exit70
with retained runtime resources. The same final executable also passed every
prior targeted request/wake/FFI/active-sender/deadline control, including8/8 rounds
of100000 requests atp11. The250ms deadline measured255.076885ms. These are37
targeted control rows, including expected fatal/refusal negatives, not37 full
inventory gates. All recorded parents were reaped and groups quiescent.

Auditc211afe312e241249e728c66409823ae passed candidate safety/fair terminal
disposition and eight decoded QNT negatives: early unlink, free-group-on-error,
forgetting a close error because stage is CLOSED, callback escape, stale callback
replay, roots freed before IO outcome, failed release freeing allocation, and
group release before the foreign last-consumer handoff. Terminal disposition
includes checked retained failure; it does not assert that failed storage is freed.

Earlier fixture compile failures, the invalid raw VM-field probe/SIGSEGV, the
incorrect thread migration name, and fd-number reuse misclassification remain
retained. The final probes use the generated STRUCTUREREF representation and
distinguish the replacement file's valid close from an original-device retry.
One active audit/model launcher correctly blocked a production takeover; it
exited naturally and production continued through normal custody. No peer was
signalled or operated on.

Costs: one immediate error word per native device, a sticky-error branch on close,
one linear canonical-foreign traversal per VM teardown, and winding/recovery
allocation per fault callback. No matched application performance claim is made.
These controls establish the two requested paths on the Darwin producer under
the live/quiesced host and public winding API contracts. Nonterminating callback
code and raw private no-winding/native jumps are not made generally recoverable.
Qualification remains8/12; full native/Gerbil acceptance is not run. Source phase
remains building/runtimeAdmitted=false. No commit, staging, push, unrelated source
change or other-thread operation was performed.
'''
  doc=ROOT/'docs/current-repair-research.md';doc.write_text(doc.read_text()+note)
  print(out,flush=True)
if __name__=='__main__':main()
