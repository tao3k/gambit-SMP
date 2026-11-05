"""Two-day custody for adopted outputs; explicit recovery/state pins remain durable."""
from datetime import timedelta, datetime
from contextlib import nullcontext
import json
import os
from pathlib import Path
import stat

from gambit_smp.workspace import bounded, lease, now, write, active_paths, referenced, pending, ZONE
from gambit_smp.task_dependencies import registry
from gambit_smp.storage_retention import SHARED, inspect, archive_records, remove_tree


def classify(root,task,*,recovery):
    """Replace the former blanket pin with an explicit retention classification."""
    with lease(root,'storage-retention'),lease(root,task):
        target=registry(root,task);value=json.loads(target.read_text())
        roots=[bounded(root,name) for name in recovery]
        for row in value['paths']:
            path=bounded(root,row['path']);st=path.stat()
            if [st.st_dev,st.st_ino]!=row['identity']:raise ValueError('dependency identity changed before classification')
            parts=Path(row['path']).parts
            if any(path==pin or path.is_relative_to(pin) for pin in roots):reason='explicit recovery dependency'
            elif len(parts)>1 and parts[1] in SHARED and parts[1]!='tasks':reason='shared operational store'
            elif path.is_dir() and (path/'.git').exists():reason='Git source custody'
            else:reason=None
            row.update(custody='in-place-pin' if reason else 'retained-output',
                       retention='owner-release' if reason else 'two-calendar-days',retentionReason=reason,
                       classifiedAt=now().isoformat())
        write(target,value)
        return value


def inventory(path):
    """Metadata CAS, without reading private streams or following aliases."""
    result={};todo=[path]
    while todo:
        node=todo.pop();st=node.lstat();kind=stat.S_IFMT(st.st_mode)
        result[str(node.relative_to(path))]=[st.st_dev,st.st_ino,kind,st.st_size,st.st_mtime_ns]
        if stat.S_ISDIR(st.st_mode):todo.extend(node.iterdir())
    return result


def unchanged_remainder(path,baseline):
    for name,current in inventory(path).items():
        old=baseline.get(name)
        if old is None:raise ValueError('new entry appeared during interrupted deletion')
        # Directory timestamps/sizes change during rmtree; its inode/type cannot.
        if (current[:3]!=old[:3] or (current[2]!=stat.S_IFDIR and current!=old)):
            raise ValueError('artifact replaced or modified during interrupted deletion')


def collect(root,task,*,today=None,opened=None):
    root=Path(root).resolve(strict=True)
    cutoff=(today or now().date())-timedelta(days=1)
    target=registry(root,task)
    if not target.exists():return []
    with lease(root,'storage-retention'),lease(root,task):
        value=json.loads(target.read_text())
        if pending(root):return [dict(deferred='pending requests')]
        for store in ('.cache/workspace-leases','.data/workspace-leases'):
            if any(bounded(root,store).glob('*.quarantine.json')):return [dict(deferred='workspace quarantine')]
        from gambit_smp.task_processes import check
        check(root,task,all_processes=True)
        from gambit_smp.work_process import check_all
        check_all(root,task)
        occupied=active_paths() if opened is None else opened
        removed=[];decisions=[]
        for row in list(value['paths']):
            if row.get('custody')!='retained-output':
                decisions.append(dict(path=row['path'],retained='explicit pin',reason=row.get('retentionReason')));continue
            path=bounded(root,row['path']);cleanup=row.get('cleanup',{});git_release=None;disposable_git=[]
            if referenced(path,occupied):
                decisions.append(dict(path=row["path"],retained="process reference"));continue
            if not path.exists():
                if cleanup.get('state')!='removing':raise ValueError('retained artifact disappeared outside cleanup')
            else:
                st=path.stat()
                if [st.st_dev,st.st_ino]!=row['identity']:raise ValueError('retained artifact identity changed')
                if cleanup.get('state')=='removing':
                    unchanged_remainder(path,cleanup['inventory'])
                    if inspect(path,cutoff,deleting=True,disposable_databases=[q['path'] for q in cleanup.get('validationQueues',{}).get('queues',[])],disposable_git=cleanup.get('disposableGit',[]))['blocked']:raise ValueError('interrupted deletion now contains protected state')
                else:
                    if datetime.fromtimestamp(st.st_mtime,ZONE).date()>=cutoff:
                        decisions.append(dict(path=row['path'],retained='two-day window'));continue
                    # Prove queue custody only after the inventory finds a DB.
                    # Do not recursively search every old source/cache tree first.
                    fixture=None
                    reason=inspect(path,cutoff)['blocked']
                    if reason=='operational state or quarantine' and path.is_dir():
                        from gambit_smp.validation_retention import proof
                        fixture=proof(path)
                        if fixture:
                            reason=inspect(path,cutoff,disposable_databases=[q['path'] for q in fixture['queues']])['blocked']
                    if reason=='nested Git checkout':
                        from gambit_smp.git_custody import assess,release_ready
                        destination=(row.get('gitCustody',{}).get('integration') or {}).get('checkout')
                        row['gitCustody']=assess(root,path,integration=destination)
                        write(target,value)
                        if release_ready(row['gitCustody']):
                            git_release=row['gitCustody']
                            disposable_git=[str((root/repo['path']/'.git').relative_to(path)) for repo in git_release['repositories']]+git_release['cacheSentinels']
                            reason=inspect(path,cutoff,disposable_git=disposable_git)['blocked']
                    if reason:
                        decisions.append(dict(path=row['path'],retained=reason,
                                              **({'gitCustody':row['gitCustody']} if reason=='nested Git checkout' else {})));continue
                    cleanup=dict(state='removing',at=now().isoformat(),inventory=inventory(path),
                                 archivedRecords=archive_records(root,path))
                    if fixture:cleanup['validationQueues']=fixture
                    if git_release:cleanup.update(gitRelease=git_release,disposableGit=disposable_git)
                    row['cleanup']=cleanup;write(target,value)
                if cleanup.get('gitRelease'):
                    from gambit_smp.git_custody import verify_saved
                    verify_saved(cleanup['gitRelease'])
                if cleanup.get('validationQueues'):
                    from gambit_smp.validation_retention import retain
                    if cleanup.get('queueArchives'):
                        # Deletion may already have removed the queues; the sealed
                        # original metadata inventory still controls the remainder.
                        from gambit_smp.validation_retention import check_archives
                        check_archives(root,cleanup['queueArchives'])
                        unchanged_remainder(path,cleanup['inventory'])
                        remove_tree(path)
                    else:
                        with retain(root,path,cleanup['validationQueues']) as queues:
                            cleanup['queueArchives']=queues;write(target,value)
                            remove_tree(path)
                else:remove_tree(path)
            cleanup['state']='removed';row['cleanup']=cleanup
            value['paths'].remove(row)
            value.setdefault('expired',[]).append(row)
            write(target,value);removed.append(row['path'])
        write(bounded(root,'.state/storage/retention-'+task+'.json'),dict(at=now().isoformat(),cutoff=cutoff.isoformat(),timezone=str(ZONE),removed=removed,retained=decisions))
        return removed
