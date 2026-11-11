"""Executable CLI/process acceptance with controlled providers and real cc/make.

No mocks, production task mutation, external model calls, or native admission.
Run through the existing audit role; pass its owned output directory to main.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from datetime import timedelta

from gambit_smp import workspace as w
from gambit_smp.validation_domains import isolated_test_context


def _accept(output):
    output=Path(output).resolve();output.mkdir(parents=True,exist_ok=True)
    root=output/'checkout';root.mkdir()
    env=dict(os.environ)
    for key in list(env):
        if key.startswith(('GAMBIT_SMP_TASK_','GAMBIT_SMP_WORKSPACE_')):env.pop(key)
    calls=[]
    def invoke(argv,expected=0):
        result=subprocess.run(argv,cwd=root,env=env,capture_output=True,text=True,timeout=20)
        index=len(calls)
        (output/f'{index:02d}.stdout').write_text(result.stdout)
        (output/f'{index:02d}.stderr').write_text(result.stderr)
        calls.append(dict(argv=argv,exit=result.returncode))
        assert result.returncode==expected,(argv,result.returncode,result.stderr)
        return result
    def cli(operation,*args,expected=0):
        if operation=='run':
            separator=args.index('--')
            tail=[*args[:separator],'repair',*args[separator:]]
        else:tail=['repair',*args]
        return invoke([sys.executable,'-m','gambit_smp','workspace','--root',str(root),operation,*tail],expected)
    invoke(['git','init','-q'])
    invoke(['git','-c','user.name=Acceptance','-c','user.email=acceptance@example.invalid','commit','--allow-empty','-qm','fixture'])
    source=root/'src';source.mkdir()
    (source/'a.c').write_text('int a(void){return 1;}\n')
    (source/'b.c').write_text('int b(void){return 2;}\n')
    (source/'Makefile').write_text('all: a.o b.o\n%.o: %.c\n\t$(CC) -c $< -o $@\n\t@echo $@ >> compiled.log\n')
    tools=root/'tools';tools.mkdir()
    driver='''import json,os,sys,shutil,time
is_grok=os.path.basename(sys.argv[0])=='grok'
session='01a15562-916b-7da0-b55e-5d85db65485a'
if is_grok:
 print(json.dumps(dict(type='init',sessionId=session)),flush=True)
 if '--resume' not in sys.argv:time.sleep(30)
from pathlib import Path
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
root=Path(os.environ['GAMBIT_SMP_TASK_ROOT']);cc=shutil.which('cc')
build=w.build_output(root,'native',compiler=cc,flags=['-O0'])
target=build/'source';target.mkdir(exist_ok=True)
with workspace_lease(root,target,tree_identity(target)):
 w.sync_build_source(root,build,root/'src')
 assert w.execute(root,'repair',[shutil.which('make'),'-j1','-C',str(target),'CC='+cc])==0
 w.checkpoint_build_source(target,phase='ready')
if is_grok:
 print(json.dumps(dict(type='end',sessionId=session,stopReason='end_turn')),flush=True)
elif '--interrupt' in sys.argv:time.sleep(30)
'''
    for name in ('codex','grok'):
        binary=tools/name;binary.write_text('#!'+sys.executable+'\n'+driver);binary.chmod(0o700)
    env['PATH']=str(tools)+os.pathsep+env['PATH']
    cli('start','--adopt')
    cli('run','--wall-seconds','5','--provider','codex','--',str(tools/'codex'))
    cli('run','--wall-seconds','1','--provider','codex','--',str(tools/'codex'),'--interrupt',expected=1)
    owner_path=w.paths(root,'repair')[0]
    owner=json.loads(owner_path.read_text());assert owner['execution']=='interrupted'
    first_run=owner['run']
    build=next((root/'.cache/tasks/repair/build/native').iterdir())
    runtime=build/'source';inode=runtime.stat().st_ino
    checkpoint=json.loads((build/'source-state.json').read_text())
    objects={name:(runtime/name).stat().st_mtime_ns for name in ('a.o','b.o')}
    cli('finish',expected=1)
    cli('resume')
    cli('run','--wall-seconds','5','--provider','codex','--',str(tools/'codex'),'--resume','fixture-session')
    assert runtime.stat().st_ino==inode
    assert objects=={name:(runtime/name).stat().st_mtime_ns for name in objects}
    prompt=root/'.cache/tasks/repair/agents/diagnostic/prompt.txt'
    prompt.parent.mkdir(parents=True);prompt.write_text('Controlled lifecycle acceptance only')
    # The existing public Grok API, in a separate real controller process, gives
    # its supervisor the normal bounded budget without changing native limits.
    code="""import sys,json
from pathlib import Path
from gambit_smp.grok_session import Launch,run
r=run(Launch(Path(sys.argv[1]),'diagnostic',Path(sys.argv[2]),'controlled lifecycle acceptance',resume=sys.argv[3] or None,task='repair'),execute=True,wall_seconds=float(sys.argv[4]))
print(json.dumps(r));raise SystemExit(not r['sessionCompleted'])
"""
    grok=[sys.executable,'-c',code,str(root),str(prompt)]
    failed=json.loads(invoke(grok+['','1'],expected=1).stdout)
    assert failed['timedOut'] and not failed['sessionCompleted']
    assert failed['completion'] is None
    cli('resume')
    done=json.loads(invoke(grok+['01a15562-916b-7da0-b55e-5d85db65485a','5']).stdout)
    assert done['sessionCompleted'] and done['reasoningEffort']=='high'
    current=json.loads((build/'source-state.json').read_text())
    assert runtime.stat().st_ino==inode
    assert {k:v for k,v in checkpoint.items() if k not in {'run','custody'}}=={k:v for k,v in current.items() if k not in {'run','custody'}}
    assert checkpoint['run']!=current['run'] and Path(root/current['custody']).exists()
    assert objects=={name:(runtime/name).stat().st_mtime_ns for name in objects}
    assert (runtime/'compiled.log').read_text().splitlines()==['a.o','b.o']
    rows=[json.loads(path.read_text()) for path in (root/'.state/task-processes/repair').glob('*/*.json')]
    assert rows and all(row.get('birth') and row.get('spawnProtocol') for row in rows)
    # Inject the collector's supported clock, not record dates or success bits.
    future=w.now().date()+timedelta(days=3)
    assert not w.reclaim(root,'repair',today=future)['removed']
    cli('finish')
    within=w.reclaim(root,'repair',today=w.now().date()+timedelta(days=1))
    assert not within['removed'] and within['reason']=='open, recent, or absent'
    with (runtime/'a.o').open('rb'):
        held=w.reclaim(root,'repair',today=future)
        assert not held['removed'] and held['reason']=='process reference'
    removed=w.reclaim(root,'repair',today=future)
    assert removed['removed'] and owner_path.exists() and (root/'.git').exists()
    assert not w.paths(root,'repair')[1].exists()
    original=json.loads((root/'.state/task-runs/repair'/f'{first_run}.json').read_text())
    assert original['state']=='interrupted' and original['reconciliation']
    value=dict(schema='provider-lifecycle-real-acceptance.v1',calls=calls,providerMode='controlled-local-executables',
        sameTask='repair',sameBuild=str(build),sourceInode=inode,compiledObjects=2,noOpReuse=True,
        checkpointReused=True,spawnRecords=len(rows),allHaveBirthProtocol=True,
        interruptionPreserved=original['state'],cleanupClock=str(future),heldFileDeferred=held,
        cleanup=removed,withinTwoDays=within,sourceGitPreserved=True,nativeAdmitted=False,externalModelsInvoked=False)
    w.write(output/'receipt.json',value)
    return value


def teardown(output):
    """Drain only this fixture through real custody, archive JSON, remove fixture."""
    output=Path(output).resolve();root=output/'checkout'
    if not root.exists():return
    owner=w.paths(root,'repair')[0]
    if owner.exists():
        value=json.loads(owner.read_text())
        if value['state']=='open':
            if value.get('execution') in {'running','interrupted'}:w.resume(root,'repair')
            w.finish(root,'repair')
    from gambit_smp.storage_retention import archive_records
    project=Path(__file__).resolve().parents[1]
    archived=archive_records(project,root)
    shutil.rmtree(root)
    w.write(output/'fixture-teardown.json',dict(schema='controlled-fixture-teardown.v1',
        fixture=str(root.relative_to(project)),archivedRecords=archived,removed=True,nativeAdmitted=False))


def accept(output):
    try:return _accept(output)
    finally:teardown(output)


def accept_run_script(output):
    """Exercise the registered CLI entry with real controller death and reuse."""
    try:return _accept_run_script(Path(output).resolve())
    finally:teardown(output)


def _accept_run_script(output):
    import signal
    import time
    from gambit_smp.process_identity import process,same_birth
    output.mkdir(parents=True,exist_ok=True);root=output/'checkout';root.mkdir()
    env={k:v for k,v in os.environ.items() if not k.startswith(('GAMBIT_SMP_TASK_','GAMBIT_SMP_WORKSPACE_'))}
    calls=[]
    def invoke(argv,expected=0):
        result=subprocess.run(argv,cwd=root,env=env,capture_output=True,text=True,timeout=15)
        index=len(calls);(output/f'{index:02d}.stdout').write_text(result.stdout)
        (output/f'{index:02d}.stderr').write_text(result.stderr)
        calls.append(dict(argv=argv,exit=result.returncode))
        assert result.returncode==expected,(argv,result.returncode,result.stderr)
        return result
    base=[sys.executable,'-m','gambit_smp','workspace','--root',str(root)]
    invoke(['git','init','-q'])
    invoke(['git','-c','user.name=Acceptance','-c','user.email=acceptance@example.invalid','commit','--allow-empty','-qm','fixture'])
    invoke(base+['start','repair','--adopt'])
    source=root/'src';source.mkdir()
    (source/'a.c').write_text('int a(void){return 1;}\n')
    (source/'b.c').write_text('int b(void){return 2;}\n')
    (source/'Makefile').write_text('all: a.o b.o\n%.o: %.c\n\t$(CC) -c $< -o $@\n\t@echo $@ >> compiled.log\n')
    original=root/'.cache/registered-build.py'
    original.write_text('''import json,os,sys,shutil,time
from pathlib import Path
from subprocess import Popen as start,PIPE,STDOUT
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
root=Path.cwd();cc=shutil.which('cc')
build=w.build_output(root,'native',compiler=cc,flags=['-O0'])
target=build/'source';target.mkdir(exist_ok=True)
with workspace_lease(root,target,tree_identity(target)):
 w.sync_build_source(root,build,root/'src')
 child=start([shutil.which('make'),'-j1','-C',str(target),'CC='+cc],stdout=PIPE,stderr=STDOUT,text=True)
 log,_=child.communicate(timeout=10)
 assert child.returncode==0,log
 w.checkpoint_build_source(target,phase='ready')
 out=w.task_output(root,'.cache/registered-ready.json')
 w.write(out,dict(pid=os.getpid(),build=str(build),run=os.environ['GAMBIT_SMP_TASK_RUN']))
 if os.environ.get('CONTROLLED_REGISTERED_INTERRUPT')=='1':
  deadline=time.monotonic()+10
  while not (root/'.cache/tasks/repair/acceptance-release').exists():
   if time.monotonic()>=deadline:raise RuntimeError('fixture release event absent')
   time.sleep(.01)
print(json.dumps(dict(build=str(build),run=os.environ['GAMBIT_SMP_TASK_RUN'])))
''')
    original_sha=__import__('hashlib').sha256(original.read_bytes()).hexdigest()
    migrated=json.loads(invoke(base+['migrate-script','repair','.cache/registered-build.py','--enable']).stdout)
    key=migrated['key'];script=Path(migrated['path'])
    from gambit_smp.task_migration import rewrite_process_calls
    assert not original.exists() and not rewrite_process_calls(script.read_bytes())[1]
    assert len(migrated['processCallMigration'])==1
    cold=json.loads(invoke(base+['run-script','--provider','codex','--wall-seconds','10','repair',key]).stdout)
    build=Path(cold['build']);runtime=build/'source';inode=runtime.stat().st_ino
    objects={name:(runtime/name).stat().st_mtime_ns for name in ('a.o','b.o')}
    env['CONTROLLED_REGISTERED_INTERRUPT']='1'
    with (output/'interrupted.stdout').open('w') as stdout,(output/'interrupted.stderr').open('w') as stderr:
        controller=subprocess.Popen(base+['run-script','--provider','codex','--wall-seconds','15','repair',key],cwd=root,env=env,stdout=stdout,stderr=stderr)
        controller_birth=process(controller.pid)
        target_birth=None
        try:
            deadline=time.monotonic()+10;ready=None
            while time.monotonic()<deadline:
                owner=json.loads(w.paths(root,'repair')[0].read_text());run=owner.get('run')
                path=root/'.cache/tasks/repair/runs'/str(run)/'outputs/registered-ready.json'
                if run!=cold['run'] and path.exists():ready=json.loads(path.read_text());break
                if controller.poll() is not None:raise AssertionError((output/'interrupted.stderr').read_text())
                time.sleep(.01)
            assert ready is not None,'registered target did not reach its checkpoint'
            run=ready['run'];target=ready['pid'];target_birth=process(target)
            assert target_birth is not None and same_birth(controller_birth,process(controller.pid))
            controller.send_signal(signal.SIGKILL);assert controller.wait(timeout=5)==-signal.SIGKILL
            held=invoke(base+['resume','repair'],expected=1)
            assert 'temporarily unavailable' in held.stderr or 'custody' in held.stderr or 'process group' in held.stderr
            assert same_birth(target_birth,process(target))
            (root/'.cache/tasks/repair/acceptance-release').write_text('natural fixture consumer exit')
            deadline=time.monotonic()+5
            while process(target) is not None and time.monotonic()<deadline:time.sleep(.01)
            assert process(target) is None,'fixture consumer did not exit naturally'
        finally:
            (root/'.cache/tasks/repair/acceptance-release').write_text('fixture cleanup release')
            if controller.poll() is None:
                assert same_birth(controller_birth,process(controller.pid))
                controller.kill();controller.wait(timeout=5)
    env.pop('CONTROLLED_REGISTERED_INTERRUPT')
    invoke(base+['resume','repair'])
    interrupted=json.loads((root/'.state/task-runs/repair'/f'{run}.json').read_text())
    assert interrupted['state']=='interrupted' and interrupted['reconciliation']
    recovered=json.loads(invoke(base+['run-script','--provider','grok','--wall-seconds','10','repair',key]).stdout)
    assert recovered['build']==cold['build'] and runtime.stat().st_ino==inode
    assert objects=={name:(runtime/name).stat().st_mtime_ns for name in objects}
    assert (runtime/'compiled.log').read_text().splitlines()==['a.o','b.o']
    records=[json.loads(path.read_text()) for path in (root/'.state/task-processes/repair').glob('*/*.json')]
    assert records and all(r.get('birth') and r.get('spawnProtocol') for r in records)
    invoke(base+['finish','repair'])
    value=dict(schema='registered-run-script-real-acceptance.v1',calls=calls,entry='workspace run-script',
        key=key,originalSha256=original_sha,migratedSha256=__import__('hashlib').sha256(script.read_bytes()).hexdigest(),
        migration=migrated,controllerBirth=controller_birth,consumerBirth=target_birth,
        interruptedRun=interrupted,interruptedChildRecords=[r for r in records if r['run']==run],
        recoveryRun=recovered['run'],build=str(build),sourceInode=inode,objectTimestamps=objects,
        compiledObjects=2,spawnRecords=len(records),allBirthBound=True,noRawProcessCalls=True,
        lastConsumerExitedNaturally=True,noOpAfterRecovery=True,nativeAdmitted=False)
    w.write(output/'receipt.json',value);return value


def main():
    with isolated_test_context():value=accept(sys.argv[1])
    print(json.dumps(dict(receipt=str(Path(sys.argv[1])/'receipt.json'),spawnRecords=value['spawnRecords'],cleanup=value['cleanup'])))


if __name__=='__main__':main()
