"""Immutable source identities: committed Git objects or existing task checkpoints.

No source copies or replay patches are published under evidence/.
"""
import base64
import hashlib
import json
from pathlib import Path
import re
from subprocess import CalledProcessError

from gambit_smp.workspace import bounded, task_output


def sha(data):
    return hashlib.sha256(data).hexdigest()


class SourceUnavailable(ValueError):
    """A well-formed immutable identity has no local backing object/journal."""


def git_source(root, repository, revision, path):
    from gambit_smp.view_materialize import git
    from gambit_smp.workspace import bounded
    if Path(repository).is_absolute():raise ValueError('relative Git repository locator required')
    if '..' in Path(repository).parts:
        raise ValueError('contained Git repository locator required')
    if not re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}', revision):
        raise ValueError('full immutable Git commit required')
    candidate = Path(root)/repository
    if not candidate.is_dir():
        raise SourceUnavailable('source repository unavailable: '+repository)
    repo = candidate.resolve(strict=True)
    if repo != Path(root).resolve() and not (repo/'.git').exists():
        raise SourceUnavailable('source repository is not initialized: '+repository)
    if Path(git(repo,'rev-parse','--show-toplevel').decode().strip()).resolve()!=repo:
        raise ValueError('exact source Git repository required')
    name = Path(path)
    if name.is_absolute() or '..' in name.parts or str(name) != path:
        raise ValueError('canonical Git source path required')
    try:
        commit = git(repo, 'rev-parse', '--verify', revision+'^{commit}').decode().strip()
    except CalledProcessError as error:
        raise SourceUnavailable('immutable source commit unavailable: '+revision) from error
    if commit != revision:
        raise ValueError('full immutable Git commit required')
    try:
        blob = git(repo, 'rev-parse', revision+':'+path).decode().strip()
    except CalledProcessError as error:
        raise SourceUnavailable('immutable source path unavailable: '+revision+':'+path) from error
    if git(repo, 'cat-file', '-t', blob).strip() != b'blob':
        raise ValueError('Git source must be a blob')
    data = git(repo, 'cat-file', 'blob', blob)
    return dict(kind='git', repository=repository, revision=revision, path=path,
                blob=blob, sha256=sha(data))


def retain_sources(root, sources):
    """Retain unique dirty/historical bytes through the existing execution journal."""
    root=Path(root).resolve(strict=True)
    from gambit_smp.research_kernel import retain_run_record
    from gambit_smp.reasoning_history import read_execution_checkpoint
    references={}
    for content,data in {sha(data):data for data in sources.values()}.items():
        record=task_output(root,root/'.cache/source-identities'/content/'record.json')
        if not record.is_relative_to(root/'.cache/tasks'):
            raise ValueError('source retention requires an existing managed task')
        record.parent.mkdir(parents=True,exist_ok=True)
        payload=dict(schema='source-identity-observation.v1',runId=content,
                     entries={content:base64.b64encode(data).decode('ascii')})
        prefix=read_execution_checkpoint(root,record.parent)
        if not prefix['records']:
            if record.exists():raise ValueError('uncommitted source checkpoint record')
            retain_run_record(root,record,'source-identities',payload,{})
            prefix=read_execution_checkpoint(root,record.parent)
        if len(prefix['records'])!=1 or prefix['records'][0]['payload']!=payload:
            raise ValueError('source checkpoint identity collision')
        references[content]=dict(kind='task-checkpoint',run=str(record.parent.relative_to(root)),
                                 identity=prefix['prefixIdentity'],sha256=content)
    return {name:references[sha(data)] for name,data in sources.items()}


def read_source(root, identity):
    if identity.get('kind') == 'git':
        current = git_source(root, identity['repository'], identity['revision'], identity['path'])
        if current != identity:
            raise ValueError('Git source identity mismatch')
        from gambit_smp.view_materialize import git
        return git((Path(root)/identity['repository']).resolve(strict=True), 'cat-file', 'blob', identity['blob'])
    if identity.get('kind') != 'task-checkpoint' or set(identity) != {'kind','run','identity','sha256'}:
        raise ValueError('typed immutable source identity required')
    run = bounded(root, identity['run'])
    if not run.is_relative_to(Path(root)/'.cache/tasks'):
        raise ValueError('source checkpoint requires managed task storage')
    from gambit_smp.reasoning_history import read_execution_checkpoint
    prefix = read_execution_checkpoint(root, run)
    if not prefix['records']:
        raise SourceUnavailable('source checkpoint unavailable: '+identity['run'])
    if prefix['prefixIdentity'] != identity['identity'] or len(prefix['records']) != 1:
        raise ValueError('source checkpoint prefix mismatch')
    payload = prefix['records'][0]['payload']
    if payload.get('schema') != 'source-identity-observation.v1':
        raise ValueError('source checkpoint payload required')
    data = base64.b64decode(payload['entries'][identity['sha256']], validate=True)
    if sha(data) != identity['sha256']:
        raise ValueError('source checkpoint bytes changed')
    return data


def read_git_sources(root, identities):
    """Batch immutable reads, preserving caller order and byte-level checks.

    None denotes unavailable local Git backing, never a path/cache fallback.
    Every present commit/path/blob and content digest must agree. There is no
    cross-call cache: removal or replacement is observable on the next read.
    """
    from gambit_smp.view_materialize import git
    root=Path(root).resolve(strict=True)
    identities=list(identities)
    if len(identities)>4096:raise ValueError('bounded immutable read population required')
    groups={};results=[None]*len(identities)
    for index,identity in enumerate(identities):
        if (set(identity)!={'kind','repository','revision','path','blob','sha256'}
                or identity['kind']!='git'
                or not re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}',identity['revision'])
                or not re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}',identity['blob'])
                or not re.fullmatch(r'[0-9a-f]{64}',identity['sha256'])):
            raise ValueError('full immutable Git identity required')
        repository,name=identity['repository'],identity['path']
        for value in (repository,name):
            if (not isinstance(value,str) or not value or Path(value).is_absolute()
                    or '..' in Path(value).parts or str(Path(value))!=value
                    or any(ord(c)<32 for c in value)):
                raise ValueError('contained canonical Git locator required')
        groups.setdefault(repository,[]).append((index,identity))
    total_bytes=0
    for repository,rows in groups.items():
        candidate=root/repository
        if not candidate.is_dir():continue
        repo=candidate.resolve(strict=True)
        if not repo.is_relative_to(root):raise ValueError('source repository escaped root')
        if repo!=root and not (repo/'.git').exists():continue
        if Path(git(repo,'rev-parse','--show-toplevel').decode().strip()).resolve()!=repo:
            raise ValueError('exact source Git repository required')
        queries=list(dict.fromkeys(query for _,item in rows for query in
            (item['revision']+'^{commit}',item['revision']+':'+item['path'])))
        raw=git(repo,'cat-file','--batch-check=%(objectname) %(objecttype) %(objectsize)',
                input=('\n'.join(queries)+'\n').encode())
        lines=raw.splitlines()
        if len(lines)!=len(queries):raise ValueError('incomplete Git identity response')
        metadata={}
        for query,line in zip(queries,lines):
            if line==(query+' missing').encode():metadata[query]=None;continue
            parts=line.decode().split()
            if (len(parts)!=3 or not re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}',parts[0])
                    or not parts[2].isdecimal()):raise ValueError('invalid Git identity response')
            metadata[query]=(parts[0],parts[1],int(parts[2]))
        blobs={};available=[]
        for index,item in rows:
            commit=metadata[item['revision']+'^{commit}']
            blob=metadata[item['revision']+':'+item['path']]
            if commit is None or blob is None:continue
            if commit[:2]!=(item['revision'],'commit') or blob[:2]!=(item['blob'],'blob'):
                raise ValueError('Git source identity mismatch')
            blobs[item['blob']]=blob[2];available.append((index,item))
        total_bytes+=sum(blobs.values())
        if total_bytes>128*1024*1024:raise ValueError('immutable source byte budget exceeded')
        if not blobs:continue
        raw=git(repo,'cat-file','--batch',input=('\n'.join(blobs)+'\n').encode())
        cursor=0;contents={}
        for blob,size in blobs.items():
            end=raw.find(b'\n',cursor)
            if end<0 or raw[cursor:end]!=(blob+' blob '+str(size)).encode():
                raise ValueError('Git byte capture header mismatch')
            cursor=end+1;body=raw[cursor:cursor+size];cursor+=size
            if len(body)!=size or raw[cursor:cursor+1]!=b'\n':raise ValueError('truncated Git bytes')
            cursor+=1;contents[blob]=body
        if cursor!=len(raw):raise ValueError('unexpected trailing Git bytes')
        for index,item in available:
            data=contents[item['blob']]
            if sha(data)!=item['sha256']:raise ValueError('Git source identity mismatch')
            results[index]=data
    return results


def reference_bytes(root, ref):
    if 'identity' in ref:
        data = read_source(root, ref['identity'])
        if sha(data) != ref['sha256']:
            raise ValueError('reference source identity mismatch')
        return data
    from gambit_smp.framework import relative
    return relative(Path(root).resolve(), ref['path']).read_bytes()


def identity_observation(root, identity):
    """Missing immutable storage is observable; malformed identities still fail."""
    try:
        return sha(read_source(root, identity))
    except SourceUnavailable:
        return None


def committed_source(root, path, data):
    """Find a reachable committed owner; never manufacture dangling Git blobs."""
    from gambit_smp.view_materialize import git
    from subprocess import CalledProcessError
    for revision in git(root, 'log', '--all', '--format=%H', '--', path).decode().splitlines():
        try:
            identity = git_source(root, '.', revision, path)
        except CalledProcessError:
            continue
        if identity['sha256'] == sha(data):
            return identity
    return None


def migrate_source_storage(root):
    """One-way conversion of every legacy source review and generated snapshot.

    Historical receipts keep their original contents in the existing checkpoint;
    only authored references are converted. No source declaration is admitted.
    """
    import tempfile
    from gambit_smp.view_materialize import git
    from gambit_smp.task_processes import run
    from gambit_smp.workspace import write, lease
    root = Path(root).resolve()
    manifest_path=root/'evidence/review/source-storage-migration.json'
    if manifest_path.exists():
        return finish_source_migration(root,json.loads(manifest_path.read_text()))
    originals = {}; replacements = {}; identities = {}; obsolete = set(); targets = {}
    reviews = []
    for file in (root/'evidence').rglob('*.json'):
        try:
            document = json.loads(file.read_bytes())
        except (ValueError, UnicodeError):
            continue
        if isinstance(document, dict) and document.get('schema') == 'ascent.source-binding-review.v1':
            reviews.append((file,document))
    def remember(path):
        name = str(path.relative_to(root))
        originals.setdefault(name,path.read_bytes())
        return name
    def identify(name, data, path):
        originals[name] = data
        targets[name] = path
        identity = committed_source(root,path,data) if path else None
        if identity:identities[name] = identity
    for file, review in reviews:
        remember(file)
        for index, change in enumerate(review['changes']):
            baseline = bounded(root, change['baseline']);delta = bounded(root,change['patch'])
            before = baseline.read_bytes();patch = delta.read_bytes()
            # Git parses the old patch only during this explicit migration.
            names = [line[6:] for line in patch.decode().splitlines() if line.startswith('+++ b/')]
            if len(names) != 1:raise ValueError('single source patch required for migration')
            path = names[0]
            with tempfile.TemporaryDirectory(prefix='source-migration-') as folder:
                temp=Path(folder);target=bounded(temp,path);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(before)
                run(['git','apply','--whitespace=nowarn','-'],cwd=temp,input=patch,capture_output=True,check=True,timeout=30)
                after=target.read_bytes()
            key=str(file.relative_to(root))+':'+str(index)
            identify(key+':before',before,path);identify(key+':after',after,path)
            remember(delta);obsolete.add(change['patch'])
            # Historical model result inputs have independent consumers/custody.
            if change['baseline'].startswith(('evidence/source-snapshots/','evidence/source-reviews/','evidence/review/')):
                remember(baseline);obsolete.add(change['baseline'])
    # Include abandoned sibling copies, not just the paths named by a review.
    for folder in (root/'evidence/review/repair-trajectory-closure',root/'evidence/source-reviews'):
        if folder.exists():
            for file in folder.rglob('*'):
                if file.is_file() and file.suffix in ('.patch','.baseline','.py'):
                    obsolete.add(remember(file))
    snapshots=list((root/'evidence/source-snapshots').rglob('*')) if (root/'evidence/source-snapshots').exists() else []
    for file in snapshots:
        if file.is_file():
            name=remember(file);obsolete.add(name)
    # Retain the exact pre-migration records too: historical receipts must not be
    # silently rewritten when their paths become immutable identity references.
    for file in (root/'evidence').rglob('*.json'):
        raw=file.read_bytes()
        if any(name.encode() in raw for name in obsolete):remember(file)
    # Retain exact previously cited bytes for concurrent dirty sources. Never
    # replace their expected digest with the current worktree digest.
    pins={}
    for declaration in (root/'evidence').rglob('*.view.source.json'):
        document=json.loads(declaration.read_bytes())
        for row in document['references']:
            locator=row['source'];path=locator.get('path')
            if set(locator)!={'path','sha256'} or path in obsolete:continue
            file=bounded(root,path);expected=locator['sha256']
            if file.is_file() and sha(file.read_bytes())==expected:continue
            found=None
            for revision in git(root,'log','--all','--format=%H','--',path).decode().splitlines():
                candidate=git_source(root,'.',revision,path)
                if candidate['sha256']==expected:
                    found=candidate;break
            if found is None:
                candidates=[data for data in originals.values() if sha(data)==expected]
                if not candidates:
                    for patch_file in (root/'evidence/review').rglob('*.patch'):
                        base=patch_file.with_suffix(Path(path).suffix)
                        if not base.is_file():continue
                        patch=patch_file.read_bytes()
                        if ('+++ b/'+path+'\n').encode() not in patch:continue
                        with tempfile.TemporaryDirectory(prefix='source-migration-') as folder:
                            temp=Path(folder);target=bounded(temp,path);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(base.read_bytes())
                            run(['git','apply','--whitespace=nowarn','-'],cwd=temp,input=patch,capture_output=True,check=True,timeout=30)
                            data=target.read_bytes()
                        if sha(data)==expected:candidates.append(data);break
                if not candidates:raise ValueError('previously cited source unavailable: '+path)
                key='cited-source:'+expected
                originals[key]=candidates[0]
                found=key
            pins[(str(declaration.relative_to(root)),row['id'])]=found
        if any(name==str(declaration.relative_to(root)) for name,_ in pins):remember(declaration)
    pending={name:data for name,data in originals.items() if name not in identities}
    if pending:identities.update(retain_sources(root,pending))
    for file,review in reviews:
        updated=dict(review,schema='ascent.source-binding-review.v2')
        updated['previousReview']=identities[str(file.relative_to(root))]
        changes=[]
        for index,change in enumerate(review['changes']):
            key=str(file.relative_to(root))+':'+str(index)
            changes.append({**{k:v for k,v in change.items() if k not in ('baseline','patch')},
                            'before':identities[key+':before'],'after':identities[key+':after']})
        updated['changes']=changes
        replacements[str(file.relative_to(root))]=updated
    def convert(value):
        if isinstance(value,dict):
            if isinstance(value.get('path'),str) and value['path'] in obsolete and 'sha256' in value:
                name=value['path'];return dict(value,path='checkpoint-source/'+value['sha256'],identity=identities[name])
            result={}
            for key,item in value.items():
                # Input maps retain the original path as a historical label;
                # the original receipt is preserved, and gets an explicit map.
                if key in obsolete or any(key==str(root/name) for name in obsolete):
                    name=key if key in obsolete else str(Path(key).relative_to(root))
                    result['source-identity:'+identities[name]['sha256']]=identities[name]
                else:result[key]=convert(item)
            return result
        if isinstance(value,list):return [convert(item) for item in value]
        if isinstance(value,str):
            if value in obsolete:return identities[value]
            if value.startswith(str(root)+'/') and value[len(str(root))+1:] in obsolete:return identities[value[len(str(root))+1:]]
        return value
    for name,data in list(originals.items()):
        if name in obsolete or name in replacements or not name.endswith('.json') or name.endswith(('.view.json','.view.binding.json')):continue
        try:document=json.loads(data)
        except ValueError:continue
        updated=convert(document)
        for row in updated.get('references',[]):
            pin=pins.get((name,row['id']))
            if pin is not None:row['source']['identity']=identities[pin] if isinstance(pin,str) else pin
        if updated!=document:
            if not name.endswith('.view.source.json'):
                updated['storageMigration']=dict(previous=identities[name],runtimeAdmitted=False)
            replacements[name]=updated
    manifest=dict(schema='source-storage-migration.v1', sources={name:identities[name] for name in sorted(obsolete)},
                  previousDocuments={name:identities[name] for name in replacements},
                  reviews=sorted(str(p.relative_to(root)) for p,_ in reviews),runtimeAdmitted=False)
    # Validate *all* retained bytes before touching a published reference.
    for name,identity in identities.items():
        if read_source(root,identity)!=originals[name]:raise ValueError('migration retention mismatch')
    planned=retain_sources(root,{name:json.dumps(document,indent=2).encode()+b'\n' for name,document in replacements.items()})
    manifest['documents']=planned
    manifest['state']='pending'
    with lease(root,'evidence-view-publication'):
        for name in set(replacements)|obsolete:
            if bounded(root,name).read_bytes()!=originals[name]:raise ValueError('source migration raced with author')
        write(manifest_path,manifest)
    return finish_source_migration(root,manifest)


def finish_source_migration(root, manifest):
    """Replay an interrupted migration plan; reject any concurrent source edit."""
    from gambit_smp.workspace import lease, write
    root=Path(root).resolve()
    if manifest.get('schema')!='source-storage-migration.v1':raise ValueError('source migration plan required')
    if manifest.get('state')=='completed':
        compact_view_sources(root)
        return dict(reviews=len(manifest['reviews']),removed=len(manifest['sources']),documents=len(manifest['documents']),manifest='evidence/review/source-storage-migration.json')
    planned={name:read_source(root,identity) for name,identity in manifest['documents'].items()}
    previous={name:read_source(root,identity) for name,identity in manifest['previousDocuments'].items()}
    retained={name:read_source(root,identity) for name,identity in manifest['sources'].items()}
    with lease(root,'evidence-view-publication'):
        for name,data in planned.items():
            if bounded(root,name).read_bytes() not in (data,previous[name]):raise ValueError('source migration raced with author')
        for name,data in retained.items():
            file=bounded(root,name)
            if file.exists() and file.read_bytes()!=data:raise ValueError('source migration copy changed')
        for name,data in planned.items():
            if bounded(root,name).read_bytes()!=data:write(bounded(root,name),json.loads(data))
    from gambit_smp.view_materialize import materialize
    for declaration in sorted((root/'evidence').rglob('*.view.source.json')):
        spec=json.loads(declaration.read_bytes());output=bounded(root,spec['output'])
        materialize(root,str(declaration.relative_to(root)),expected_view_sha=sha(output.read_bytes()) if output.exists() else None)
    with lease(root,'evidence-view-publication'):
        for name,data in planned.items():
            if bounded(root,name).read_bytes()!=data:raise ValueError('source migration raced with author')
        for name,data in retained.items():
            if bounded(root,name).exists() and bounded(root,name).read_bytes()!=data:raise ValueError('source migration copy changed')
        for name in retained:bounded(root,name).unlink(missing_ok=True)
        for parent in sorted({p for name in retained for p in bounded(root,name).parents if p!=root and p.is_relative_to(root/'evidence')},key=lambda p:len(p.parts),reverse=True):
            try:parent.rmdir()
            except OSError:pass
        write(root/'evidence/review/source-storage-migration.json',dict(manifest,state='completed'))
    return dict(reviews=len(manifest['reviews']),removed=len(retained),documents=len(planned),manifest='evidence/review/source-storage-migration.json')


def compact_view_sources(root):
    """Rebind compound journal prerequisites without changing their source bytes."""
    from gambit_smp.reasoning_history import read_execution_checkpoint
    from gambit_smp.workspace import write,lease
    from gambit_smp.view_materialize import materialize
    for file in sorted((root/'evidence').rglob('*.view.source.json')):
        raw=file.read_bytes();document=json.loads(raw);changes=[]
        for row in document['references']:
            identity=row['source'].get('identity',{})
            if identity.get('kind')!='task-checkpoint':continue
            data=read_source(root,identity)
            prefix=read_execution_checkpoint(root,root/identity['run'])
            if len(prefix['records'][0]['payload']['entries'])==1:continue
            replacement=retain_sources(root,{'source':data})['source']
            changes.append(dict(reference=row['id'],before=identity,after=replacement))
            row['source']['identity']=replacement
        if changes:
            # Keep the exact previous declaration and rebind receipt in the same
            # journal. The old compound record stays immutable historical input.
            previous=retain_sources(root,{'declaration':raw})['declaration']
            audit=dict(schema='source-checkpoint-rebind.v1',declaration=str(file.relative_to(root)),
                       previous=previous,changes=changes,runtimeAdmitted=False)
            retain_sources(root,{'rebind':json.dumps(audit,sort_keys=True).encode()})
            with lease(root,'evidence-view-publication'):
                if file.read_bytes()!=raw:raise ValueError('source compaction raced with author')
                write(file,document)
    # Generate after metadata-only rebinding, and whenever the producer changed.
    for file in sorted((root/'evidence').rglob('*.view.source.json')):
        document=json.loads(file.read_bytes());output=bounded(root,document['output'])
        materialize(root,str(file.relative_to(root)),expected_view_sha=sha(output.read_bytes()) if output.exists() else None)
