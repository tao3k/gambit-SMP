"""Bounded maintenance processes inside a work item, with real lease custody."""
from contextlib import contextmanager
from datetime import datetime,timedelta
import fcntl
import json
import os
from pathlib import Path
import uuid


def paths(root,task,process):
    from gambit_smp.workspace import bounded,identifier
    task=identifier(task);process=identifier(process)
    return (bounded(root,'.state/work-processes/'+task+'/'+process+'.json'),
            bounded(root,'.cache/tasks/'+task+'/processes/'+process))


def run_path(root,task,process,run):
    from gambit_smp.workspace import bounded,identifier
    return bounded(root,'.state/work-process-runs/'+identifier(task)+'/'+identifier(process)+'/'+identifier(run)+'.json')


@contextmanager
def lease(root,task,process):
    record,_=paths(root,task,process);record.parent.mkdir(parents=True,exist_ok=True)
    fd=os.open(record.with_suffix('.lock'),os.O_CREAT|os.O_RDWR|os.O_NOFOLLOW,0o600)
    try:
        fcntl.flock(fd,fcntl.LOCK_EX|fcntl.LOCK_NB);yield fd
    finally:os.close(fd)


@contextmanager
def admission(root,task):
    from gambit_smp.workspace import bounded,identifier
    path=bounded(root,'.state/work-processes/'+identifier(task)+'/.admission.lock');path.parent.mkdir(parents=True,exist_ok=True)
    fd=os.open(path,os.O_CREAT|os.O_RDWR|os.O_NOFOLLOW,0o600)
    try:
        fcntl.flock(fd,fcntl.LOCK_EX|fcntl.LOCK_NB);yield
    finally:os.close(fd)


def check_all(root,task):
    from gambit_smp.workspace import bounded
    from gambit_smp.task_processes import check
    for file in bounded(root,'.state/work-processes/'+task).glob('*.json'):
        row=json.loads(file.read_text())
        with lease(root,task,row['process']):
            check(root,task,process=row['process'])
            if row.get('execution') in {'running','interrupted'}:raise ValueError('process requires explicit reconciliation')


@contextmanager
def scope(root,task,process,provider='codex'):
    from gambit_smp import workspace as w
    from gambit_smp.work_items import admit
    from gambit_smp.storage_policy import enforce
    from gambit_smp.task_processes import check
    root=Path(root).resolve(strict=True);admit(root,task,process)
    parent=json.loads(w.paths(root,task)[0].read_text())
    if parent['state']!='open':raise ValueError('work item is not open')
    record,cache=paths(root,task,process)
    if record.exists():collect(root,task,process)
    with w._process_scope_lock,lease(root,task,process) as fd:
        with admission(root,task):
            parent=json.loads(w.paths(root,task)[0].read_text())
            if parent['state']!='open':raise ValueError('work item is not open')
            owner=json.loads(record.read_text()) if record.exists() else dict(task=task,process=process,state='open')
            if owner.get('execution') in {'running','interrupted'}:raise ValueError('uncertain process execution; explicit process-resume required')
            check(root,task,process=process)
            run=uuid.uuid4().hex;target=run_path(root,task,process,run);cache.mkdir(parents=True,exist_ok=True)
            w.write(target,dict(schema=1,custodyProtocol=3,task=task,process=process,run=run,provider=provider,
                 state='running',startedAt=w.now().isoformat(),supervisorPid=os.getpid(),output=str(cache/'runs'/run),nativeAdmitted=False))
            owner.update(state='open',execution='running',run=run,checkout=parent['checkout'],lastActivity=w.now().isoformat())
            w.write(record,owner)
        environment=dict(GAMBIT_SMP_TASK_ID=task,GAMBIT_SMP_TASK_PROCESS=process,GAMBIT_SMP_TASK_ROOT=str(root),
                         GAMBIT_SMP_TASK_CACHE=str(cache),GAMBIT_SMP_TASK_RUN=run,GAMBIT_SMP_TASK_LOCK_FD=str(fd))
        previous={key:os.environ.get(key) for key in environment};os.environ.update(environment)
        try:
            with enforce(root,task):yield owner,fd,target
        except BaseException:
            owner['execution']='interrupted';raise
        else:owner['execution']='returned'
        finally:
            row=json.loads(target.read_text());row.update(state=owner['execution'],endedAt=w.now().isoformat())
            if 'exit' in owner:row['exit']=owner['exit']
            w.write(target,row);w.write(record,owner)
            for key,value in previous.items():
                if value is None:os.environ.pop(key,None)
                else:os.environ[key]=value
    collect(root,task,process)


def resume(root,task,process):
    from gambit_smp import workspace as w
    from gambit_smp.task_processes import check
    from gambit_smp.work_items import admit
    admit(root,task,process)
    record,cache=paths(root,task,process)
    with lease(root,task,process),admission(root,task):
        if json.loads(w.paths(root,task)[0].read_text())['state']!='open':raise ValueError('work item is not open')
        owner=json.loads(record.read_text());check(root,task,process=process)
        if w.pending(root):raise ValueError('pending operational requests require owner reconciliation')
        if owner.get('run'):
            target=run_path(root,task,process,owner['run']);row=json.loads(target.read_text())
            if row['state']=='running':row['state']='interrupted'
            row.setdefault('endedAt',w.now().isoformat());row['reconciliation']=dict(observedAt=w.now().isoformat(),nativeAdmitted=False)
            from gambit_smp.task_broker import cleanup
            cleanup(row);w.write(target,row)
        owner['execution']='reconciled';w.write(record,owner)
    return owner


def collect(root,task,process,*,today=None,opened=None):
    from gambit_smp import workspace as w
    from gambit_smp.task_processes import check
    from gambit_smp.storage_retention import inspect,archive_records,remove_tree
    cutoff=(today or w.now().date())-timedelta(days=1);removed=[]
    record,cache=paths(root,task,process)
    with lease(root,task,process):
        check(root,task,process=process)
        if record.exists() and json.loads(record.read_text()).get('execution') in {'running','interrupted'}:return []
        if w.pending(root):return []
        occupied=w.active_paths() if opened is None else opened
        for target in run_path(root,task,process,'placeholder').parent.glob('*.json'):
            row=json.loads(target.read_text())
            if row['state']=='running' or (row['state']=='interrupted' and not row.get('reconciliation')):continue
            if datetime.fromisoformat(row['endedAt']).astimezone(w.ZONE).date()>=cutoff:continue
            output=cache/'runs'/row['run']
            if not output.exists() or w.referenced(output,occupied):continue
            if inspect(output,cutoff)['blocked']:continue
            row['archivedRecords']=archive_records(root,output);w.write(target,row)
            remove_tree(output);row['outputRemovedAt']=w.now().isoformat();w.write(target,row);removed.append(row['run'])
        w.collect_builds(root,cache,cutoff,occupied)
    history=w.bounded(root,'.state/work-process-history/'+task+'/'+process)
    for descriptor in history.glob('*.json'):
        row=json.loads(descriptor.read_text());path=Path(row['path'])
        if datetime.fromisoformat(row['closedAt']).astimezone(w.ZONE).date()>=cutoff or not path.exists():continue
        with lease(root,task,process):
            check(root,task,process=process)
            if w.referenced(path,w.active_paths() if opened is None else opened) or inspect(path,cutoff)['blocked']:continue
            row['archivedRecords']=archive_records(root,path);w.write(descriptor,row);remove_tree(path)
            row['removedAt']=w.now().isoformat();w.write(descriptor,row);removed.append('history:'+row['legacyTask'])
    return removed


def absorb(root,task,process,legacy):
    """Relocate a closed role-task as byte-preserved process history, not a shim."""
    import hashlib
    from gambit_smp import workspace as w
    from gambit_smp.work_items import admit
    from gambit_smp.storage_retention import archive_records
    root=Path(root).resolve();admit(root,task,process)
    old_record,old_cache,_=w.paths(root,legacy);new_record,cache=paths(root,task,process)
    destination=cache/'history'/legacy
    journal=w.bounded(root,'.state/storage/task-to-process-'+legacy+'.json')
    with w.lease(root,'storage-retention'),w.lease(root,legacy),lease(root,task,process):
        old=json.loads(old_record.read_text())
        if old['state']!='closed':raise ValueError('role task must finish naturally before relocation')
        if journal.exists():receipt=json.loads(journal.read_text())
        else:
            if w.referenced(old_cache,w.active_paths()):raise ValueError('role task still has live references')
            from gambit_smp.task_processes import check
            check(root,legacy,all_processes=True)
            st=old_cache.stat()
            receipt=dict(schema='task-to-process.v1',task=task,process=process,legacyTask=legacy,state='prepared',
                         originalIdentity=[st.st_dev,st.st_ino],source=str(old_cache),destination=str(destination),
                         closedAt=old['closedAt'],archivedRecords=archive_records(root,old_cache),nativeAdmitted=False)
            w.write(journal,receipt)
        if old_cache.exists():
            if destination.exists():raise ValueError('process history collision')
            st=old_cache.stat()
            if [st.st_dev,st.st_ino]!=receipt['originalIdentity']:raise ValueError('role cache identity changed')
            destination.parent.mkdir(parents=True,exist_ok=True);old_cache.rename(destination)
        st=destination.stat()
        if [st.st_dev,st.st_ino]!=receipt['originalIdentity']:raise ValueError('relocated process history identity changed')
        history=w.bounded(root,'.state/work-process-history/'+task+'/'+process)
        for namespace in ('task-runs','task-processes'):
            source=w.bounded(root,'.state/'+namespace+'/'+legacy);target=history/namespace/legacy
            if source.exists():
                if target.exists():raise ValueError('process journal custody collision')
                target.parent.mkdir(parents=True,exist_ok=True);source.rename(target)
        old['retiredInto']=dict(task=task,process=process,history=str(destination));w.write(old_record,old)
        w.write(history/(legacy+'.json'),dict(schema='work-process-history.v1',task=task,process=process,
                                            path=str(destination),closedAt=receipt['closedAt'],legacyTask=legacy))
        receipt.update(state='complete');receipt.setdefault('completedAt',w.now().isoformat());w.write(journal,receipt)
    return receipt
