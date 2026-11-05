"""Retain failed test scheduler queues as history, not pending native actions."""
from contextlib import ExitStack, closing, contextmanager
import hashlib
import json
import os
from pathlib import Path
import sqlite3


def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def producer_group(pid,ended_at):
    """Prove old-group exit even when its number belongs to a newer leader."""
    from datetime import datetime,timezone
    from gambit_smp.task_processes import run
    try:os.killpg(pid,0)
    except ProcessLookupError:return dict(pgid=pid,result='absent',kernelError='ESRCH')
    except PermissionError:probe='EPERM'
    else:probe='present'
    # Reuse requires the old process group to disappear first. Never signal
    # the newer group, or treat EPERM itself as evidence of absence.
    result=run(['ps','-p',str(pid),'-o','pid=,pgid=,lstart='],capture_output=True,text=True,
               timeout=10,env=dict(os.environ,LC_ALL='C',TZ='UTC'))
    if result.returncode!=0:return None
    fields=result.stdout.split(None,2)
    if len(fields)!=3 or fields[:2]!=[str(pid),str(pid)]:return None
    try:
        started=datetime.strptime(fields[2].strip(),'%a %b %d %H:%M:%S %Y').replace(tzinfo=timezone.utc)
        ended=datetime.fromisoformat(ended_at)
        if ended.tzinfo is None:return None
    except (ValueError,TypeError):return None
    if started.timestamp()<=ended.timestamp()+1:return None
    return dict(pgid=pid,result='reused-after-producer-exit',kernelProbe=probe,
                newLeaderStartedAt=started.isoformat(),producerEndedAt=ended_at,method='kernel-ps-lstart')


def _full_proof(path):
    """Only the known validation producer can declare disposable test queues."""
    receipt=path/'receipt.json';child=path/'test-result.json'
    if not receipt.is_file() or not child.is_file():return None
    row=json.loads(receipt.read_text())
    if row.get('schema')!='gambit-framework-validation.v1' or row.get('testResultSha256')!=digest(child):return None
    producer=row.get('producer',{});log=producer.get('log',{})
    name=Path(log.get('path',''))
    if name.is_absolute() or '..' in name.parts or not name.parts:return None
    file=path/name
    if not file.is_file() or digest(file)!=log.get('sha256') or not producer.get('endedAt'):return None
    if producer.get('pid') and producer_group(producer['pid'],producer['endedAt']) is None:return None
    queues=[]
    for index,domain in enumerate(row.get('executionDomains',[])):
        if domain.get('schema')!='sealed-validation-domain.v1':return None
        ids=domain.get('expectedTestIds',[])
        from gambit_smp.workspace import bounded
        queue=bounded(path,'domains/'+str(index)+'/queue.sqlite')
        if not queue.is_file():return None
        with closing(sqlite3.connect(queue.as_uri()+'?mode=ro',uri=True)) as db:
            tables=db.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
            columns=[r[1] for r in db.execute('PRAGMA table_info(jobs)')]
            if tables!=[('jobs',)] or columns!=['ordinal','id','lane']:return None
            jobs=db.execute('SELECT ordinal,id,lane FROM jobs ORDER BY ordinal').fetchall()
            if [r[0] for r in jobs]!=list(range(len(ids))) or [r[1] for r in jobs]!=ids:return None
        queues.append(dict(path=str(queue.relative_to(path)),jobsSha256=hashlib.sha256(json.dumps(jobs).encode()).hexdigest()))
    if not queues:return None
    return dict(schema='expired-validation-queues.v1',receiptSha256=digest(receipt),queues=queues,nativeAdmitted=False)


def _domain_proof(domain):
    """Authenticate a sealed test scheduler from its own immutable lane records."""
    receipt=domain/'receipt.json';queue=domain/'queue.sqlite'
    if not receipt.is_file() or not queue.is_file():return None
    row=json.loads(receipt.read_text())
    if row.get('schema')!='sealed-validation-domain.v1':return None
    artifacts=row.get('artifacts',{});ids=row.get('expectedTestIds',[])
    if len(ids)!=len(set(ids)) or artifacts.get('queue.sqlite')!=digest(queue):return None
    with closing(sqlite3.connect(queue.as_uri()+'?mode=ro',uri=True)) as db:
        if db.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()!=[('jobs',)]:return None
        if [r[1] for r in db.execute('PRAGMA table_info(jobs)')]!=['ordinal','id','lane']:return None
        jobs=db.execute('SELECT ordinal,id,lane FROM jobs ORDER BY ordinal').fetchall()
    if [r[0] for r in jobs]!=list(range(len(ids))) or [r[1] for r in jobs]!=ids:return None
    inputs={'receipt.json':digest(receipt),'queue.sqlite':digest(queue)};pids=[]
    for index,lane in enumerate(row.get('lanes',[])):
        # A saved termination boolean is insufficient; observe every actual group.
        pid=lane.get('pid')
        if not isinstance(pid,int) or pid<=0 or not lane.get('endedAt'):return None
        observation=producer_group(pid,lane['endedAt'])
        if observation is None:return None
        pids.append(observation)
        for name in (str(index)+'/request.json',str(index)+'/process.log'):
            file=domain/name
            if not file.is_file() or digest(file)!=artifacts.get(name):return None
            inputs[name]=digest(file)
        request=json.loads((domain/str(index)/'request.json').read_text())
        if (request.get('schema')!='sealed-validation-request.v1' or request.get('testIds')!=ids or
                request.get('engineId')!=row.get('engineId') or request.get('lane')!=index):return None
        requested=Path(request['queue'])
        if not requested.is_absolute():requested=Path(request['root'])/requested
        if requested.resolve()!=queue.resolve():return None
        result=domain/str(index)/'result.json'
        if result.exists():
            name=str(index)+'/result.json'
            if digest(result)!=artifacts.get(name):return None
            value=json.loads(result.read_text())
            if value.get('requestSHA')!=inputs[str(index)+'/request.json']:return None
            inputs[name]=digest(result)
    if not pids:return None
    return dict(schema='sealed-test-queue-custody.v1',inputs=inputs,producerGroups=pids,
                jobsSha256=hashlib.sha256(json.dumps(jobs).encode()).hexdigest(),
                pendingTestJobs=sum(lane is None for _,_,lane in jobs))


def proof(path):
    """Recognize full, nested and standalone sealed validation domains."""
    path=Path(path).resolve(strict=True)
    full=_full_proof(path)
    if full:return full
    queues=[]
    for queue in sorted(path.rglob('queue.sqlite')):
        if queue.is_symlink():return None
        bound=_domain_proof(queue.parent)
        if bound is None:return None
        queues.append(dict(path=str(queue.relative_to(path)),jobsSha256=bound['jobsSha256'],domain=bound))
    if not queues:return None
    return dict(schema='expired-validation-queues.v2',queues=queues,nativeAdmitted=False)


@contextmanager
def retain(root,path,provenance):
    """Lock actual queues, archive all jobs (including NULL lanes), then expire."""
    from gambit_smp.workspace import bounded
    if proof(path)!=provenance:raise ValueError('validation queue provenance changed')
    archived=[]
    with ExitStack() as stack:
        for row in provenance['queues']:
            queue=path/row['path']
            db=stack.enter_context(closing(sqlite3.connect(queue.as_uri()+'?mode=rw',uri=True,timeout=0)))
            db.execute('BEGIN IMMEDIATE')
            jobs=db.execute('SELECT ordinal,id,lane FROM jobs ORDER BY ordinal').fetchall()
            identity=hashlib.sha256(json.dumps(jobs).encode()).hexdigest()
            if identity!=row['jobsSha256']:raise ValueError('test queue changed before expiration')
            input_sha=digest(queue)
            archive=bounded(root,'.state/storage/validation-queues/'+input_sha+'-'+identity+'.sqlite')
            archive.parent.mkdir(parents=True,exist_ok=True)
            if not archive.exists():
                temporary=archive.with_suffix('.sqlite.tmp')
                with closing(sqlite3.connect(queue.as_uri()+'?mode=ro',uri=True)) as source,closing(sqlite3.connect(temporary)) as target:
                    source.backup(target)
                    if target.execute('PRAGMA integrity_check').fetchone()!=('ok',):raise ValueError('test queue archive integrity failure')
                with temporary.open('rb') as stream:os.fsync(stream.fileno())
                temporary.replace(archive)
            with closing(sqlite3.connect(archive.as_uri()+'?mode=ro',uri=True)) as backup:
                if backup.execute('SELECT ordinal,id,lane FROM jobs ORDER BY ordinal').fetchall()!=jobs:raise ValueError('test queue archive differs')
            archived.append(dict(path=str(archive.relative_to(root)),sha256=digest(archive),sourceQueueSha256=input_sha,jobsSha256=identity,
                                 pendingTestJobs=sum(lane is None for _,_,lane in jobs)))
        yield archived


def check_archives(root,rows):
    from gambit_smp.workspace import bounded
    for row in rows:
        archive=bounded(root,row['path'])
        if digest(archive)!=row['sha256']:raise ValueError('test queue archive changed during interrupted cleanup')
        with closing(sqlite3.connect(archive.as_uri()+'?mode=ro',uri=True)) as db:
            if db.execute('PRAGMA integrity_check').fetchone()!=('ok',):raise ValueError('test queue archive integrity failure')
            jobs=db.execute('SELECT ordinal,id,lane FROM jobs ORDER BY ordinal').fetchall()
            if hashlib.sha256(json.dumps(jobs).encode()).hexdigest()!=row['jobsSha256']:raise ValueError('test queue archived jobs differ')
