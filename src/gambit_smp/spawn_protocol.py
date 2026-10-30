"""Child-owned birth, durable exec permission, and an EOF cancellation barrier.

The launcher replaces itself with the target; its kernel PID/birth never changes.
A per-token flock proves when no delayed launcher can still publish or execute.
"""
import hashlib
import json
import os
from pathlib import Path
import sys
from contextvars import ContextVar

_popen_authority=ContextVar('birth_exec_popen_authority',default=False)
_exec_authority=ContextVar('birth_exec_target_authority',default=False)


def _popen(argv,**kwargs):
    import subprocess
    token=_popen_authority.set(True)
    try:return subprocess.Popen(argv,**kwargs)
    finally:_popen_authority.reset(token)


def _write(path,value):
    # Use the existing atomic/fsynced writer, also in the child before exec.
    from gambit_smp.workspace import write
    write(path,value)


def child(directory,ready,gate,lock):
    from gambit_smp.process_identity import boot_id,process
    directory=Path(directory);request=json.loads((directory/'request.json').read_text())
    birth=dict(schema='task-spawn-birth.v1',token=request['token'],bootId=boot_id(),process=process(os.getpid()),
               requestSha256=hashlib.sha256((directory/'request.json').read_bytes()).hexdigest())
    _write(directory/'birth.json',birth)
    os.set_inheritable(ready,False)
    os.write(ready,b'B')
    def receive(size):
        data=b''
        while len(data)<size:
            block=os.read(gate,size-len(data))
            if not block:return None
            data+=block
        return data
    permission=receive(1)
    length=receive(8) if permission==b'X' else None
    payload=receive(int.from_bytes(length,'big')) if length is not None else None
    os.close(gate)
    if payload is None:
        _write(directory/'cancelled.json',dict(schema='task-spawn-cancelled.v1',token=request['token'],birth=birth,
               reason='exec-permission-channel-closed',targetExecuted=False))
        return 125
    target_environment=json.loads(payload)
    permission_record=json.loads((directory/'permission.json').read_text())
    if permission_record['token']!=request['token'] or permission_record['birth']!=birth:raise ValueError('exec permission owner mismatch')
    if hashlib.sha256(payload).hexdigest()!=permission_record['environmentSha256']:raise ValueError('exec environment transfer mismatch')
    _write(directory/'exec-intent.json',dict(schema='task-spawn-exec-intent.v1',token=request['token'],birth=birth))
    # The lock outlives exec. Other inherited task/workspace descriptors keep
    # exactly their original Popen inheritance semantics.
    os.set_inheritable(lock,True)
    from gambit_smp.spawn_protocol import _exec_authority
    authority=_exec_authority.set(True)
    try:os.execvpe(request.get('executable') or request['argv'][0],request['argv'],target_environment)
    except OSError as error:
        _write(directory/'exec-error.json',dict(errno=error.errno,token=request['token'],birth=birth))
        os.write(ready,('E'+str(error.errno)).encode())
        return 127
    finally:_exec_authority.reset(authority)


def launch(argv,*,record,token,planned=None,birth_budget=10,launch_deadline=None,**kwargs):
    """The single task-aware Popen boundary for every existing transport."""
    import fcntl
    import selectors
    import subprocess
    import time
    from gambit_smp.workspace import bounded,write
    from gambit_smp.process_identity import boot_id,process as identity,same_birth
    environment=kwargs.get('env') or {}
    managed=any(source.get('GAMBIT_SMP_TASK_ID') for source in (os.environ,environment))
    if managed and (record is None or not hasattr(record,'spawn_root')):
        raise ValueError('managed spawn requires a durable birth/exec recorder')
    if record is None:return _popen(argv,**kwargs)
    if not hasattr(record,'spawn_root'):
        # An in-memory observer is not a recoverable execution owner. Managed
        # task and research recorders always supply a durable spawn root.
        record('planned',token,dict(planned or {},argv=[str(v) for v in argv],cwd=str(kwargs.get('cwd',Path.cwd()))))
        process=_popen(argv,**kwargs)
        record('started',token,dict(pid=process.pid))
        return process
    import math
    if isinstance(argv,(str,bytes)) or not argv:raise ValueError('managed spawn requires a nonempty literal argv sequence')
    if isinstance(birth_budget,bool) or not math.isfinite(birth_budget) or birth_budget<=0:raise ValueError('positive finite birth budget required')
    root=Path(record.root)
    directory=bounded(root,str((record.spawn_root/(token+'.spawn')).relative_to(root)))
    if kwargs.get('shell') or kwargs.get('preexec_fn'):raise ValueError('managed spawn requires literal argv without preexec hooks')
    kwargs['start_new_session']=True
    directory.mkdir(mode=0o700,parents=True)
    lock=ready_read=ready_write=gate_read=gate_write=-1
    process=None
    started=time.monotonic()
    deadline=min(started+10,started+birth_budget,launch_deadline if launch_deadline is not None else float('inf'))
    try:
        lock=os.open(directory/'custody.lock',os.O_CREAT|os.O_RDWR|os.O_NOFOLLOW,0o600)
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        lock_stat=os.fstat(lock)
        request=dict(schema='task-spawn-request.v1',token=token,argv=[str(v) for v in argv],executable=kwargs.pop('executable',None))
        write(directory/'request.json',request)
        fields=dict(planned or {},argv=request['argv'],cwd=str(kwargs.get('cwd',Path.cwd())),
                    spawnProtocol=dict(schema='task-spawn-barrier.v1',directory=str(directory.relative_to(root)),
                        lockIdentity=[lock_stat.st_dev,lock_stat.st_ino],bootId=boot_id(),
                        launcherSha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),parent=identity(os.getpid())))
        ready_read,ready_write=os.pipe();gate_read,gate_write=os.pipe()
        record('planned',token,fields)
        inherited=tuple(set(kwargs.get('pass_fds',()))|{ready_write,gate_read,lock})
        kwargs['pass_fds']=inherited
        target_environment=dict(kwargs.get('env') if kwargs.get('env') is not None else os.environ)
        # No sitecustomize, PYTHONPATH, DYLD/LD injection, or target environment
        # is evaluated before durable birth. Secrets cross only the private pipe.
        kwargs['env']={k:v for k,v in target_environment.items() if k.startswith('GAMBIT_SMP_TASK_') or k in {'GAMBIT_SMP_ROOT','GAMBIT_SMP_WORKSPACE_LEASES','PATH'}}
        if time.monotonic()>=deadline:raise subprocess.TimeoutExpired(argv,birth_budget)
        process=_popen([sys.executable,'-I','-S','-B',str(Path(__file__).resolve()),str(directory),str(ready_write),str(gate_read),str(lock)],**kwargs)
        os.close(ready_write);ready_write=-1;os.close(gate_read);gate_read=-1
        with selectors.DefaultSelector() as selector:
            selector.register(ready_read,selectors.EVENT_READ)
            if not selector.select(max(.001,deadline-time.monotonic())):raise subprocess.TimeoutExpired(argv,birth_budget)
            if os.read(ready_read,1)!=b'B':raise RuntimeError('child exited before birth acknowledgement')
        birth=json.loads((directory/'birth.json').read_text())
        if (birth['token']!=token or birth['requestSha256']!=hashlib.sha256((directory/'request.json').read_bytes()).hexdigest()
                or birth['bootId']!=boot_id() or birth['process']['pid']!=process.pid or birth['process']['pgid']!=process.pid
                or not same_birth(birth['process'],identity(process.pid))):raise ValueError('child birth identity mismatch')
        # This record must commit before the child can execute user code.
        record('started',token,dict(pid=process.pid,birth=birth,phase='birth-committed-before-exec'))
        if time.monotonic()>=deadline:raise subprocess.TimeoutExpired(argv,birth_budget)
        payload=json.dumps(target_environment).encode()
        write(directory/'permission.json',dict(token=token,birth=birth,environmentSha256=hashlib.sha256(payload).hexdigest()))
        outgoing=memoryview(b'X'+len(payload).to_bytes(8,'big')+payload)
        os.set_blocking(gate_write,False)
        with selectors.DefaultSelector() as selector:
            selector.register(gate_write,selectors.EVENT_WRITE)
            while outgoing:
                remaining=deadline-time.monotonic()
                if remaining<=0 or not selector.select(remaining):raise subprocess.TimeoutExpired(argv,birth_budget)
                try:count=os.write(gate_write,outgoing)
                except BlockingIOError:continue
                outgoing=outgoing[count:]
        # The pipe closes on exec, not when birth is published. Preserve real
        # executable errors instead of silently changing Popen into exit 127.
        with selectors.DefaultSelector() as selector:
            selector.register(ready_read,selectors.EVENT_READ)
            if not selector.select(max(.001,deadline-time.monotonic())):raise subprocess.TimeoutExpired(argv,birth_budget)
            outcome=os.read(ready_read,128)
        if outcome:
            process.wait(timeout=2)
            if outcome.startswith(b'E'):
                error=int(outcome[1:]);raise OSError(error,os.strerror(error),str(argv[0]))
            raise ValueError('invalid child exec handshake')
        process.spawn_birth=birth
        return process
    except BaseException:
        # EOF prevents a not-yet-authorized target from ever starting. If the
        # target already has permission, terminate only this newly owned group.
        if process is not None:
            if gate_write>=0:os.close(gate_write);gate_write=-1
            try:process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                import signal
                try:os.killpg(process.pid,signal.SIGKILL)
                except ProcessLookupError:pass
                process.wait()
        raise
    finally:
        for fd in (ready_read,ready_write,gate_read,gate_write,lock):
            if fd>=0:os.close(fd)


def reconcile(root,row):
    """Inspect child-owned files only after exclusive custody can be reacquired."""
    import fcntl
    from gambit_smp.workspace import bounded
    from gambit_smp.process_identity import boot_id,process,same_birth
    protocol=row.get('spawnProtocol')
    if not protocol:return None
    current_boot=boot_id()
    if protocol.get('bootId') and protocol['bootId']!=current_boot:
        # Kernel processes and inherited lock FDs cannot survive a boot. Do
        # not authenticate replacement files, claim an exit status, or reuse
        # their outputs merely because the historical process is now gone.
        return dict(result='prior-boot-process-ended',targetExecuted=None,
                    previousBootId=protocol['bootId'],currentBootId=current_boot,
                    outputsAdmitted=False,replayAuthorized=False,
                    method='kernel-boot-boundary-no-output-admission')
    directory=bounded(root,protocol['directory']);lock=os.open(directory/'custody.lock',os.O_RDWR|os.O_NOFOLLOW)
    try:
        stat=os.fstat(lock)
        if [stat.st_dev,stat.st_ino]!=protocol['lockIdentity']:raise ValueError('spawn custody identity changed')
        try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:raise ValueError('spawn launcher or consumer still holds custody')
        birth_file=directory/'birth.json'
        if not birth_file.exists():
            if any((directory/name).exists() for name in ('permission.json','exec-intent.json','exec-error.json','cancelled.json')):raise ValueError('exec event without birth record')
            return dict(result='cancelled-before-birth',targetExecuted=False,method='exclusive-spawn-custody-and-no-birth')
        birth=json.loads(birth_file.read_text());request=(directory/'request.json').read_bytes()
        if birth['token']!=row['token'] or birth['requestSha256']!=hashlib.sha256(request).hexdigest():raise ValueError('spawn birth request mismatch')
        if hashlib.sha256(json.dumps(json.loads(request)['argv']).encode()).hexdigest()!=row['argvSha256']:raise ValueError('spawn argv binding changed')
        if birth['bootId']!=protocol['bootId']:raise ValueError('spawn birth boot mismatch')
        for name in ('permission.json','exec-intent.json','exec-error.json','cancelled.json'):
            file=directory/name
            if file.exists():
                event=json.loads(file.read_text())
                if event['token']!=row['token'] or event['birth']!=birth:raise ValueError('spawn event birth mismatch')
        current=process(birth['process']['pid']) if birth['bootId']==boot_id() else None
        if same_birth(birth['process'],current):raise ValueError('spawn process still alive')
        from gambit_smp.task_processes import observe_group
        group=observe_group(birth['process']['pgid'])
        if group['result']!='absent':raise ValueError('spawn process group not quiescent')
        cancelled=not (directory/'exec-intent.json').exists() or (directory/'exec-error.json').exists()
        return dict(result='cancelled-before-exec' if cancelled else 'exited-exec-outcome-unclaimed',
                    birth=birth,groupObservation=group,targetExecuted=False if cancelled else None,
                    method='kernel-birth-group-and-exclusive-spawn-custody')
    finally:os.close(lock)


if __name__=='__main__':
    sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
    raise SystemExit(child(sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),int(sys.argv[4])))
