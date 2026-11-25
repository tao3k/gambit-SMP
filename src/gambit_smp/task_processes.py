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
        if event=='started':
            row['pgid']=fields['pid']
            row['sessionProtocol']='birth-anchored-posix-session'
        if event in {'finished','interrupted'} and row.get('pgid'):
            row['groupObservation']=observe_group(row['pgid'])
            row['sessionObservation']=observe_session(row['pgid'])
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
            if retained.get('protocol')!=row.get('spawnProtocol') or retained.get('method') not in {'exclusive-spawn-custody-and-no-birth','kernel-birth-group-and-exclusive-spawn-custody','kernel-boot-boundary-no-output-admission'}:
                raise ValueError('spawn quiescence custody mismatch')
            if retained.get('method')=='kernel-boot-boundary-no-output-admission':
                if (retained.get('previousBootId')!=row['spawnProtocol'].get('bootId')
                        or not retained.get('currentBootId')
                        or retained['currentBootId']==retained['previousBootId']
                        or retained.get('outputsAdmitted') is not False
                        or retained.get('replayAuthorized') is not False
                        or retained.get('targetExecuted') is not None):
                    raise ValueError('invalid non-admitting boot closure')
                # A reused numeric PID/group belongs to the new boot. It is
                # not the historical child and must neither block nor be killed.
                observed.append(row['token'])
                continue
        if row['event']=='planned' and not row.get('pid'):
            raise ValueError('unresolved spawn journal; explicit process reconciliation required')
        if row.get('pgid') and row.get('groupObservation',{}).get('result')!='absent':
            observation=observe_group(row['pgid'])
            if observation['result']=='unverifiable':
                from gambit_smp.process_identity import pids, process, same_birth
                birth=(row.get('birth') or {}).get('process')
                owned=False
                if birth:
                    for pid in pids(pgid=row['pgid']):
                        try: info=process(pid)
                        except PermissionError: info=None
                        if same_birth(birth, info):
                            owned=True
                            break
                if not owned:
                    observation=dict(observation, result='absent', recycledIdentity=True)
            if observation['result']!='absent':raise ValueError('task child process group still present')
            from gambit_smp.workspace import write
            row['groupObservation']=observation;write(path,row)
        if (row.get('sessionProtocol')=='birth-anchored-posix-session'
                and row.get('sessionObservation',{}).get('result')!='absent'):
            observation=observe_session(row['pgid'])
            if observation['result']!='absent':
                raise ValueError('task child POSIX session still present or unknown')
            from gambit_smp.workspace import write
            row['sessionObservation']=observation;write(path,row)
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


def observe_session(sid):
    from gambit_smp.workspace import now
    from gambit_smp.process_observation import probe_session
    state=probe_session(sid)
    return dict(sid=sid,method='kernel-uid-census-getsid',observedAt=now().isoformat(),
                result={True:'absent',False:'present',None:'unverifiable'}[state])


def memory_sample(root,task,run,*,footprint=False,root_group=None):
    """Registered nested sessions share one RSS budget, never one budget each."""
    from gambit_smp.workspace import bounded,identifier
    from gambit_smp.process_identity import groups_memory,boot_id,process,same_birth
    from gambit_smp.process_identity import CensusChanged
    restarts=[]
    # A child may enter its registered session while the kernel census runs.
    # Re-read the journal as well as the kernel; never accept a partial sample.
    for attempt in range(3):
        groups={root_group} if root_group is not None else set()
        sessions={}
        rows=[]
        directory=bounded(root,'.state/task-processes/'+identifier(task)+'/'+identifier(run))
        for path in directory.glob('*.json'):
            row=json.loads(path.read_text())
            if row.get('task')!=task or row.get('run')!=run:
                raise ValueError('process journal execution mismatch')
            if (row.get('groupObservation') or {}).get('result')=='absent':continue
            if row.get('pgid') is None:continue  # Target cannot pass the birth barrier yet.
            if row.get('birth',{}).get('bootId')!=boot_id():
                raise ValueError('resource census boot identity mismatch')
            rows.append(row)
        if root_group is not None:
            descendants={root_group}
            while True:
                expanded=descendants|{
                    row['pgid'] for row in rows
                    if row.get('spawnProtocol',{}).get('parent',{}).get('pgid') in descendants
                }
                if expanded==descendants:break
                descendants=expanded
            rows=[row for row in rows if row['pgid'] in descendants]
        for row in rows:
            groups.add(row['pgid'])
            birth=row.get('birth',{}).get('process',{})
            current=process(row['pgid'])
            if same_birth(birth,current):
                try:
                    if os.getsid(row['pgid'])==row['pgid']:sessions[row['pgid']]=birth
                except ProcessLookupError:pass
        options={'footprint':True} if footprint else {}
        if sessions:options['sessions']=sessions
        try:
            sample=groups_memory(groups,**options)
        except CensusChanged as error:
            restarts.append(error.observation)
            if attempt==2:raise
            continue
        if root_group is not None:sample['pgid']=root_group
        if restarts:sample['censusRestarts']=restarts
        return sample

def stop_run(root,task,run,*,anchors=(),root_group=None):
    """Stop only authenticated groups registered to this exact execution.

    Unknown/reused births are retained as unresolved, never signalled by PID
    alone. A dead leader needs a surviving birth-attested resource member.
    """
    import signal
    from gambit_smp.workspace import bounded,identifier
    from gambit_smp.process_identity import process,same_birth,boot_id
    directory=bounded(root,'.state/task-processes/'+identifier(task)+'/'+identifier(run))
    result=dict(stopped=[],unresolved=[])
    registered={}
    for path in directory.glob('*.json'):
        row=json.loads(path.read_text())
        if row.get('task')==task and row.get('run')==run and row.get('pgid'):
            registered[row['pgid']]=row
    if root_group is not None:
        if root_group not in registered:
            result['unresolved'].append(dict(pgid=root_group, error='nested root group is not registered'))
            return result
        # Nested executions borrow the task lease. Their cleanup must not
        # signal the provider or other work already using that same run.
        descendants = {root_group}
        while True:
            expanded = descendants | {
                group for group, row in registered.items()
                if row.get('spawnProtocol', {}).get('parent', {}).get('pgid') in descendants
            }
            if expanded == descendants:
                break
            descendants = expanded
        registered = {group: row for group, row in registered.items() if group in descendants}
    # GNU timeout may create another process group inside an owned session.
    # Only a live birth observed in that session authorizes its group; a bare
    # numeric SID or an unregistered detached session never grants permission.
    for anchor in anchors:
        identity=anchor.get('process',{});group=identity.get('pgid')
        sid=anchor.get('sessionId');owner=registered.get(sid,{})
        if not sid or group in registered:continue
        if root_group is not None and sid not in registered:continue
        try:
            birth=owner.get('birth',{})
            if (birth.get('bootId')!=boot_id()
                    or birth.get('process')!=anchor.get('sessionOwnerBirth')):
                raise ValueError('nested session owner identity mismatch')
            current=process(identity['pid'])
            if current is None:continue
            if not same_birth(identity,current) or current['pgid']!=group or os.getsid(identity['pid'])!=sid:
                raise ValueError('nested session member birth or membership changed')
            try:os.killpg(group,signal.SIGKILL)
            except ProcessLookupError:pass
            result['stopped'].append(dict(token=owner['token'],pgid=group,sessionId=sid))
        except Exception as error:
            result['unresolved'].append(dict(sessionId=sid,pgid=group,error=str(error)))
    for path in directory.glob('*.json'):
        try:
            row=json.loads(path.read_text());group=row.get('pgid')
            if group is None:
                if row.get('event')=='planned':raise ValueError('unresolved planned process birth')
                continue
            if root_group is not None and group not in registered:
                continue
            if row.get('task')!=task or row.get('run')!=run:
                raise ValueError('process journal execution mismatch')
            if (row.get('groupObservation') or {}).get('result')=='absent':continue
            if observe_group(group)['result']=='absent':continue
            birth=row.get('birth',{})
            if birth.get('bootId')!=boot_id():
                raise ValueError('process group boot identity mismatch')
            identities=[birth.get('process',{})]+[
                item.get('process',{}) for item in row.get('resourceSample',{}).get('members',[])]+[
                item.get('process',{}) for item in anchors]
            verified=False
            for identity in identities:
                if identity.get('pgid')!=group or not identity.get('pid'):continue
                current=process(identity['pid'])
                if current and current['pgid']==group and same_birth(identity,current):
                    verified=True;break
            if not verified:raise ValueError('no live birth anchor for registered group')
            try:os.killpg(group,signal.SIGKILL)
            except ProcessLookupError:pass
            result['stopped'].append(dict(token=row['token'],pgid=group))
        except Exception as error:
            result['unresolved'].append(dict(record=str(path),error=str(error)))
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
