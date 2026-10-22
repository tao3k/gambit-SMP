"""Durable child-process observations shared by both providers and native adapters."""
import hashlib
import json
import os
from pathlib import Path


def recorder():
    task=os.environ.get('GAMBIT_SMP_TASK_ID')
    if not task:return None
    from gambit_smp.workspace import inherited_lease, bounded, write, now, identifier
    from pathlib import Path
    root=Path(os.environ['GAMBIT_SMP_TASK_ROOT']).resolve(strict=True)
    if inherited_lease(root,task) is None:raise ValueError('child execution requires live task custody')
    run=identifier(os.environ['GAMBIT_SMP_TASK_RUN'])
    from gambit_smp.workspace import context_owner,context_run
    owner=json.loads(context_owner(root,task).read_text())
    current=json.loads(context_run(root,task,run).read_text())
    if owner['state']!='open' or owner.get('run')!=run or current['state']!='running':
        raise ValueError('child spawn requires current running task custody')
    def record(event,token,fields):
        target=bounded(root,'.state/task-processes/'+task+'/'+run+'/'+identifier(token)+'.json')
        row=json.loads(target.read_text()) if target.exists() else dict(task=task,run=run,token=token,process=os.environ.get('GAMBIT_SMP_TASK_PROCESS'))
        row.update(event=event,observedAt=now().isoformat())
        if event=='planned':
            row['argvSha256']=hashlib.sha256(json.dumps(fields.get('argv',[])).encode()).hexdigest()
            row['cwd']=str(fields.get('cwd',''))
            row['workspaces']=fields.get('workspaces',[])
            if fields.get('spawnProtocol'):row['spawnProtocol']=fields['spawnProtocol']
        else:row.update(fields)
        if event=='started':row['pgid']=fields['pid']
        if event in {'finished','interrupted'} and row.get('pgid'):
            row['groupObservation']=observe_group(row['pgid'])
        write(target,row)
    record.root=root
    record.spawn_root=bounded(root,str((Path(current['output'])/'outputs/process-starts').relative_to(root)))
    return record


def check(root,task,*,process=None,all_processes=False,run=None):
    from gambit_smp.workspace import bounded
    observed=[]
    for path in bounded(root,'.state/task-processes/'+task).glob('*/*.json'):
        row=json.loads(path.read_text())
        if run is not None and row.get('run') != run:continue
        if not all_processes and row.get('process')!=process:continue
        if row['event']=='reconciled-discarded-read':
            from gambit_smp.spawn_reconciliation import verify_receipt
            verify_receipt(root,row)
        if row.get('spawnProtocol') and not row.get('spawnQuiescence'):
            from gambit_smp.spawn_protocol import reconcile
            observation=reconcile(root,row)
            from gambit_smp.workspace import write
            row['spawnQuiescence']=dict(observation,protocol=row['spawnProtocol'])
            if row['event'] not in {'finished','interrupted','reconciled'}:
                row.update(event='reconciled',spawnReconciliation=dict(observation,previousEvent=row['event']))
            if observation.get('birth'):
                row.update(pid=observation['birth']['process']['pid'],pgid=observation['birth']['process']['pgid'],birth=observation['birth'])
                row['groupObservation']=observation['groupObservation']
            # Move this turn's early prototype runtime files into the existing
            # owned run output. Keep inode identity and every file byte intact.
            old=bounded(root,row['spawnProtocol']['directory'])
            if old.is_relative_to(bounded(root,'.state/task-processes')):
                if row.get('process'):
                    from gambit_smp.work_process import run_path
                    producer=run_path(root,task,row['process'],row['run'])
                else:producer=bounded(root,'.state/task-runs/'+task+'/'+row['run']+'.json')
                output=Path(json.loads(producer.read_text())['output'])
                destination=bounded(root,str((output/'outputs/process-starts'/old.name).relative_to(root)))
                destination.parent.mkdir(parents=True,exist_ok=True)
                old.rename(destination)
                row['spawnStorageMigration']=dict(previous=str(old.relative_to(root)),current=str(destination.relative_to(root)))
                row['spawnProtocol']=dict(row['spawnProtocol'],directory=str(destination.relative_to(root)))
                row['spawnQuiescence']['protocol']=row['spawnProtocol']
            write(path,row)
        if row.get('spawnQuiescence'):
            retained=row['spawnQuiescence']
            if retained.get('protocol')!=row.get('spawnProtocol') or retained.get('method') not in {'exclusive-spawn-custody-and-no-birth','kernel-birth-group-and-exclusive-spawn-custody'}:
                raise ValueError('spawn quiescence custody mismatch')
        if row['event']=='planned' and not row.get('pid'):
            raise ValueError('unresolved spawn journal; explicit process reconciliation required')
        if row.get('pgid') and row.get('groupObservation',{}).get('result')!='absent':
            observation=observe_group(row['pgid'])
            if observation['result']!='absent':raise ValueError('task child process group still present')
            from gambit_smp.workspace import write
            row['groupObservation']=observation;write(path,row)
        observed.append(row['token'])
    return observed


def observe_group(pgid):
    from gambit_smp.workspace import now
    result=dict(pgid=pgid,method='killpg-0',observedAt=now().isoformat())
    try:os.killpg(pgid,0)
    except ProcessLookupError:result.update(result='absent',kernelError='ESRCH')
    except PermissionError:result.update(result='unverifiable',kernelError='EPERM')
    else:result['result']='present'
    return result


def spawn(argv,*,observer=None,spawn_token=None,birth_budget=10,launch_deadline=None,**kwargs):
    """The remaining pipe/observation owners use the same custody transport."""
    import subprocess,uuid
    check_deferred_environment(kwargs.get("env"))
    task_record=recorder()
    record=task_record or observer
    if task_record is not None and observer is not None:
        def record(event,token,fields):
            task_record(event,token,fields);observer(event,token,fields)
        record.root=task_record.root;record.spawn_root=task_record.spawn_root
    from gambit_smp.artifact_storage import workspace_custody
    if task_record is None:
        with workspace_custody(kwargs.get('env')) as (fds,env):
            kwargs['env']=env
            kwargs['pass_fds']=tuple(set(kwargs.get('pass_fds',()))|set(fds))
            from gambit_smp.spawn_protocol import launch
            return launch(argv,record=record,token=spawn_token or uuid.uuid4().hex,birth_budget=birth_budget,launch_deadline=launch_deadline,**kwargs)
    from gambit_smp.workspace import inherited_lease
    from pathlib import Path
    root=Path(os.environ['GAMBIT_SMP_TASK_ROOT']);task=os.environ['GAMBIT_SMP_TASK_ID']
    fd=inherited_lease(root,task)
    kwargs['pass_fds']=tuple(set(kwargs.get('pass_fds',()))|{fd})
    kwargs['start_new_session']=True
    if kwargs.get('env') is not None:
        env=dict(kwargs['env']);env.update({k:v for k,v in os.environ.items() if k.startswith('GAMBIT_SMP_TASK_')});kwargs['env']=env
    token=spawn_token or uuid.uuid4().hex
    try:
        with workspace_custody(kwargs.get('env')) as (fds,env):
            kwargs['env']=env
            kwargs['pass_fds']=tuple(set(kwargs['pass_fds'])|set(fds))
            from gambit_smp.spawn_protocol import launch
            process=launch(argv,record=record,token=token,birth_budget=birth_budget,launch_deadline=launch_deadline,planned=dict(
                workspaces=[row['source'] for row in json.loads(env.get('GAMBIT_SMP_WORKSPACE_LEASES','[]'))]),**kwargs)
    except OSError as error:
        record('spawn-failed',token,dict(spawnError=dict(type=type(error).__name__,errno=error.errno)));raise
    original_wait,original_communicate=process.wait,process.communicate
    def complete():
        if process.returncode is not None:task_record('finished',token,dict(exit=process.returncode,parentReaped=True))
    def wait(*args,**options):
        result=original_wait(*args,**options);complete();return result
    def communicate(*args,**options):
        result=original_communicate(*args,**options);complete();return result
    process.wait,process.communicate=wait,communicate
    return process


def check_deferred_environment(environment):
    if environment and environment.get('GAMBIT_SMP_TASK_ID'):
        names=('GAMBIT_SMP_TASK_ID','GAMBIT_SMP_TASK_ROOT','GAMBIT_SMP_TASK_RUN','GAMBIT_SMP_TASK_PROCESS')
        if any(environment.get(key)!=os.environ.get(key) for key in names):
            raise ValueError('deferred child context is no longer current; launch denied')


def run(argv, *, input=None, capture_output=False, timeout=None, check=False, **kwargs):
    """Synchronous adapters retain standard subprocess results and real custody."""
    import subprocess,signal
    check_deferred_environment(kwargs.get('env'))
    if not os.environ.get('GAMBIT_SMP_TASK_ID'):
        return subprocess.run(argv,input=input,capture_output=capture_output,timeout=timeout,check=check,**kwargs)
    if input is not None:
        if kwargs.get('stdin') is not None:raise ValueError('stdin and input are mutually exclusive')
        kwargs['stdin']=subprocess.PIPE
    if capture_output:
        if kwargs.get('stdout') is not None or kwargs.get('stderr') is not None:raise ValueError('capture_output conflicts with output handles')
        kwargs.update(stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    import time
    started=time.monotonic()
    process=spawn(argv,birth_budget=min(10,timeout) if timeout is not None else 10,launch_deadline=started+timeout if timeout is not None else None,**kwargs)
    try:
        stdout,stderr=process.communicate(input,timeout=max(.001,timeout-(time.monotonic()-started)) if timeout is not None else None)
    except BaseException:
        # Only the process group created by this call is eligible for termination.
        try:os.killpg(process.pid,signal.SIGKILL)
        except ProcessLookupError:pass
        process.communicate()
        raise
    result=subprocess.CompletedProcess(argv,process.returncode,stdout,stderr)
    if check:result.check_returncode()
    return result


def check_output(argv,**kwargs):
    import subprocess
    check_deferred_environment(kwargs.get('env'))
    if not os.environ.get('GAMBIT_SMP_TASK_ID'):
        return subprocess.check_output(argv,**kwargs)
    if 'stdout' in kwargs:raise ValueError('stdout is reserved by check_output')
    return run(argv,stdout=subprocess.PIPE,check=True,**kwargs).stdout
