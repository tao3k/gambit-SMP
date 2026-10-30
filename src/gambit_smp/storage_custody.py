"""Resource-scoped ownership audit; never borrow or release a running task lock."""
from datetime import timedelta
import hashlib
import json
from pathlib import Path

from gambit_smp.workspace import bounded,lease,now,write,active_paths,referenced
from gambit_smp.task_dependencies import registry
from gambit_smp.storage_retention import inspect


def audit(root,task,*,archive_queues=False,opened=None,paths=None,integration=None):
    root=Path(root).resolve(strict=True);cutoff=now().date()-timedelta(days=1)
    with lease(root,'storage-retention'):
        target=registry(root,task);original=target.read_bytes();value=json.loads(original)
        occupied=active_paths() if opened is None else opened
        try:
            with lease(root,task):pass
            owner='lease available; collector must recheck before deletion'
        except BlockingIOError:owner='task lease held; deletion deferred'
        decisions=[]
        selected=set(paths or [])
        all_paths={row['path'] for row in value['paths']}|{row['path'] for row in value.get('expired',[])}
        if selected-all_paths:raise ValueError('custody audit path is not registered')
        previous=bounded(root,'.state/storage/custody-'+task+'.json')
        prior=json.loads(previous.read_text()) if previous.exists() else {}
        prior_git={row['path'] for row in prior.get('decisions',[]) if row.get('git')}
        for row in value.get('expired',[]):
            cleanup=row.get('cleanup',{})
            if cleanup.get('validationQueues',{}).get('schema')!='expired-validation-queues.v2':continue
            from gambit_smp.validation_retention import check_archives
            check_archives(root,cleanup['queueArchives'])
            decisions.append(dict(path=row['path'],task=task,cleanup='removed by owning-task collector',
                 queueCustody=cleanup['validationQueues'],queueArchives=cleanup['queueArchives'],
                 removalAt=cleanup['at'],nativeAdmitted=False))
        for row in value['paths']:
            if selected and row['path'] not in selected:continue
            if row.get('custody')!='retained-output':continue
            path=bounded(root,row['path']);st=path.stat()
            if [st.st_dev,st.st_ino]!=row['identity']:raise ValueError('custody path identity changed')
            reason=inspect(path,cutoff)['blocked']
            if row['path'] in selected|prior_git and any(path.rglob('.git')):reason='nested Git checkout'
            if reason not in {'operational state or quarantine','nested Git checkout'}:continue
            decision=dict(path=row['path'],identity=row['identity'],task=task,taskCustody=owner,
                          livePathReference=referenced(path,occupied))
            if reason=='nested Git checkout':
                from gambit_smp.git_custody import assess
                decision['git']=assess(root,path,integration=integration);decision['cleanup']='Git owner reconciliation required'
            else:
                from gambit_smp.validation_retention import proof,retain
                from gambit_smp.task_processes import observe_group
                domains=[]
                for queue in sorted(path.rglob('queue.sqlite')):
                    file=queue.parent/'receipt.json'
                    if not file.is_file():continue
                    saved=json.loads(file.read_text())
                    domains.append(dict(queue=str(queue.relative_to(path)),schema=saved.get('schema'),
                        engineId=saved.get('engineId'),testCount=len(saved.get('expectedTestIds',[])),
                        receiptSha256=hashlib.sha256(file.read_bytes()).hexdigest(),
                        producerObservations=[observe_group(lane['pid']) for lane in saved.get('lanes',[]) if lane.get('pid')]))
                decision['validationDomains']=domains
                bound=proof(path)
                decision['queueCustody']=bound
                decision['cleanup']=('two-day validation output; archive then collect when owner quiescent' if bound
                                     else 'producer custody unverifiable; retain without reset or replay')
                if bound and archive_queues and not decision['livePathReference']:
                    # Separate artifact/SQLite locks suffice for copying old queues;
                    # deletion still requires the owning task lease in collect().
                    token=hashlib.sha256(row['path'].encode()).hexdigest()
                    with lease(root,'queue-archive-'+token[:24]),retain(root,path,bound) as archives:
                        decision['queueArchives']=archives
                        write(bounded(root,'.state/storage/prepared-queues/'+token+'.json'),decision)
            decisions.append(decision)
        if target.read_bytes()!=original:raise ValueError('task dependency inventory changed during custody audit')
        metadata='deferred: owner task lock held'
        try:
            with lease(root,task):
                if target.read_bytes()!=original:raise ValueError('task dependency inventory changed before ownership registration')
                by_path={row['path']:row for row in value['paths']}
                for decision in decisions:
                    if decision.get('git'):by_path[decision['path']]['gitCustody']=decision['git']
                write(target,value);metadata='registered under owning task lease'
        except BlockingIOError:pass
        receipt=dict(schema='storage-custody-audit.v1',task=task,at=now().isoformat(),cutoff=cutoff.isoformat(),
                     taskCustody=owner,ownershipRegistration=metadata,decisions=decisions,nativeAdmitted=False)
        write(bounded(root,'.state/storage/custody-'+task+'.json'),receipt)
        return receipt
