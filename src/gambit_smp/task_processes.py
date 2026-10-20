"""Durable child-process observations shared by both providers and native adapters."""
import hashlib
import json
import os


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
        else:row.update(fields)
        if event=='started':row['pgid']=fields['pid']
        if event in {'finished','interrupted'} and row.get('pgid'):
            row['groupObservation']=observe_group(row['pgid'])
        write(target,row)
    return record


def check(root,task,*,process=None,all_processes=False):
    from gambit_smp.workspace import bounded
    observed=[]
    for path in bounded(root,'.state/task-processes/'+task).glob('*/*.json'):
        row=json.loads(path.read_text())
        if not all_processes and row.get('process')!=process:continue
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


def spawn(argv,**kwargs):
    """The remaining pipe/observation owners use the same custody transport."""
    import subprocess,uuid
    check_deferred_environment(kwargs.get("env"))
    record=recorder()
    if record is None:return subprocess.Popen(argv,**kwargs)
    from gambit_smp.workspace import inherited_lease
    from pathlib import Path
    root=Path(os.environ['GAMBIT_SMP_TASK_ROOT']);task=os.environ['GAMBIT_SMP_TASK_ID']
    fd=inherited_lease(root,task)
    kwargs['pass_fds']=tuple(set(kwargs.get('pass_fds',()))|{fd})
    kwargs['start_new_session']=True
    if kwargs.get('env') is not None:
        env=dict(kwargs['env']);env.update({k:v for k,v in os.environ.items() if k.startswith('GAMBIT_SMP_TASK_')});kwargs['env']=env
    token=uuid.uuid4().hex
    record('planned',token,dict(argv=[str(a) for a in argv],cwd=str(kwargs.get('cwd',Path.cwd()))))
    try:process=subprocess.Popen(argv,**kwargs)
    except OSError:
        record('spawn-failed',token,{});raise
    record('started',token,dict(pid=process.pid))
    original_wait,original_communicate=process.wait,process.communicate
    def complete():
        if process.returncode is not None:record('finished',token,dict(exit=process.returncode,parentReaped=True))
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
    process=spawn(argv,**kwargs)
    try:
        stdout,stderr=process.communicate(input,timeout=timeout)
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
