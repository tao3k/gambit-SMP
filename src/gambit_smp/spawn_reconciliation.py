"""Narrow forensic closure of an unbound legacy metadata-read spawn.

Never authorizes replay, accepts partial outputs, or claims historical nonexecution.
New launches use child-owned birth barriers; this is not a legacy launch route.
"""
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re

from gambit_smp.workspace import bounded,write
from gambit_smp.process_identity import boot_id,process,pids


def metadata_read(root, argv):
    root=Path(root).resolve()
    if (len(argv)!=7 or argv[:4]!=['git','--no-optional-locks','-C',str(root)]
            or argv[4:6]!=['rev-parse','--verify']
            or not re.fullmatch(r'[0-9a-f]{40}\^\{commit\}',argv[6])):
        raise ValueError('only the exact pinned Git metadata-read primitive can be forensically discarded')


def inspect_legacy(root, task, role, run, token, argv):
    """Read-only OS census; the original command is never executed or signalled."""
    from gambit_smp.work_process import run_path
    from gambit_smp.task_processes import observe_group
    metadata_read(root,argv)
    journal=bounded(root,f'.state/task-processes/{task}/{run}/{token}.json')
    row=json.loads(journal.read_text())
    if row.get('event')!='planned' or row.get('pid') or row.get('spawnProtocol'):
        raise ValueError('unbound legacy planned spawn required')
    if (row['task'],row['process'],row['run'],row['token'])!=(task,role,run,token):raise ValueError('spawn ownership mismatch')
    if hashlib.sha256(json.dumps(argv).encode()).hexdigest()!=row['argvSha256']:raise ValueError('reconstructed argv does not match original hash')
    producer=json.loads(run_path(root,task,role,run).read_text())
    if not producer.get('parentReaped') or producer.get('state')!='interrupted' or not producer.get('endedAt'):
        raise ValueError('producer exit and reap evidence required')
    end=datetime.fromisoformat(producer['endedAt']).timestamp()
    start=datetime.fromisoformat(row['observedAt']).timestamp()
    if end<start:raise ValueError('inconsistent legacy launch interval')
    parents=[]
    for pid in {producer['supervisorPid'],producer['pid']}:
        current=process(pid)
        if current is not None and ('startSeconds' not in current or current['startSeconds']<=end+1):
            raise ValueError('legacy producer may still be alive')
        parents.append(dict(pid=pid,observed=current,result='absent' if current is None else 'pid-reused-after-producer-end'))
    group=observe_group(producer['pgid'])
    if group['result']!='absent':raise ValueError('legacy producer group not quiescent')
    epoch=boot_id();sweeps=[]
    # The only admissible intended target is Git's pinned metadata read. Any
    # current same-UID birth in the historical launch interval remains suspect,
    # even if it has changed argv/name. Keep a one-second timestamp margin.
    for _ in range(2):
        rows=[]
        for pid in pids(os.getuid()):
            current=process(pid)
            if current is None:continue
            if 'startSeconds' not in current:raise ValueError('legacy census needs kernel absolute birth timestamps')
            rows.append(current)
        suspects=[r for r in rows if start-1<=r['startSeconds']+r['startMicroseconds']/1e6<=end+1]
        if suspects:raise ValueError('live process birth overlaps unresolved legacy spawn')
        sweeps.append(dict(processes=rows,overlappingBirths=suspects))
    if boot_id()!=epoch:raise ValueError('boot changed during legacy census')
    return dict(schema='legacy-spawn-discard.v1',task=task,process=role,run=run,token=token,
                original=row,originalRecord=journal.read_text(),originalSha256=hashlib.sha256(journal.read_bytes()).hexdigest(),
                intendedArgv=argv,producer=producer,producerGroup=group,parents=parents,bootId=epoch,
                census=sweeps,result='metadata-read-discarded-current-quiescence-observed',
                historicalTargetExecution='unknown',outputsAdmitted=False,replayAuthorized=False,nativeAdmitted=False)


def reconcile_legacy(root, task, role, run, token, argv):
    from gambit_smp.work_process import lease,admission
    root=Path(root).resolve()
    with lease(root,task,role),admission(root,task):
        from gambit_smp.work_process import paths
        owner=json.loads(paths(root,task,role)[0].read_text())
        if owner.get('run')!=run or owner.get('execution')!='interrupted':raise ValueError('legacy reconciliation requires the same interrupted owner generation')
        receipt=inspect_legacy(root,task,role,run,token,argv)
        journal=bounded(root,f'.state/task-processes/{task}/{run}/{token}.json')
        target=bounded(root,f'.state/task-processes/{task}/{run}/{token}.legacy/receipt.json')
        if target.exists():raise ValueError('legacy reconciliation receipt already exists')
        write(target,receipt)
        if hashlib.sha256(journal.read_bytes()).hexdigest()!=receipt['originalSha256']:raise ValueError('legacy journal changed during reconciliation')
        updated=dict(receipt['original'],event='reconciled-discarded-read',legacyReconciliation=dict(
            path=str(target.relative_to(root)),sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
        write(journal,updated)
    return receipt


def verify_receipt(root,row):
    ref=row['legacyReconciliation'];path=bounded(root,ref['path']);raw=path.read_bytes()
    if hashlib.sha256(raw).hexdigest()!=ref['sha256']:raise ValueError('legacy reconciliation receipt changed')
    receipt=json.loads(raw)
    if (receipt.get('schema')!='legacy-spawn-discard.v1' or receipt.get('historicalTargetExecution')!='unknown'
            or receipt.get('outputsAdmitted') is not False or receipt.get('replayAuthorized') is not False
            or receipt.get('nativeAdmitted') is not False):raise ValueError('non-admitting legacy discard receipt required')
    original=receipt['original']
    if (hashlib.sha256(receipt['originalRecord'].encode()).hexdigest()!=receipt['originalSha256']
            or json.loads(receipt['originalRecord'])!=original):raise ValueError('legacy original journal custody mismatch')
    for key in ('task','process','run','token','argvSha256','observedAt'):
        if original.get(key)!=row.get(key):raise ValueError('legacy discard ownership mismatch')
    metadata_read(root,receipt['intendedArgv'])
    if hashlib.sha256(json.dumps(receipt['intendedArgv']).encode()).hexdigest()!=row['argvSha256']:raise ValueError('legacy discard argv mismatch')
    if any(sweep['overlappingBirths'] for sweep in receipt['census']):raise ValueError('legacy discard retained a live suspect')
