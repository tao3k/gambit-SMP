"""Read-only Git ownership decisions for nested source and package caches."""
import hashlib
import os
from pathlib import Path
import re

from gambit_smp.task_processes import run


def git(directory,*arguments):
    result=run(['git','--no-optional-locks','-C',str(directory),*arguments],
               capture_output=True,timeout=30)
    return result.stdout if result.returncode==0 else None


def _project(path):
    # Attribute the owner from package declarations or a recorded fetch URL,
    # never from a cache directory's date/name.
    candidates=[path/'gerbil.pkg',path/'source/gerbil.pkg']
    for file in candidates:
        if file.is_file():
            found=re.search(r'\(package:\s+([^\s()]+)',file.read_text())
            if found:return found.group(1)
    for file in path.glob('git-v0/db/*/.git/FETCH_HEAD'):
        found=re.search(r'https://github.com/([^\s]+)',file.read_text())
        if found:return found.group(1)
    return 'unassigned-source-owner'


def assess(root,path,*,integration=None):
    root=Path(root).resolve();path=Path(path).resolve(strict=True)
    repositories=[];markers=[]
    for marker in sorted(path.rglob('.git')):
        if marker.is_symlink():raise ValueError('nested Git alias requires owner reconciliation')
        if marker.is_file():
            # uv uses an empty .git sentinel in its sdist cache, not a worktree.
            if marker.read_bytes()==b'':markers.append(str(marker.relative_to(path)));continue
        directory=marker.parent
        location=git(directory,'rev-parse','--absolute-git-dir')
        if location is None:raise ValueError('unrecognized nested Git marker')
        gitdir=Path(location.decode().strip()).resolve()
        if not gitdir.is_relative_to(path):raise ValueError('linked Git directory belongs to another checkout')
        head=git(directory,'rev-parse','--verify','HEAD')
        refs=git(directory,'for-each-ref','--format=%(objectname) %(refname)') or b''
        status=git(directory,'status','--porcelain=v1','-z') or b''
        staged=git(directory,'diff','--cached','--binary','--no-ext-diff') or b''
        working=git(directory,'diff','--binary','--no-ext-diff') or b''
        origin=git(directory,'config','--get','remote.origin.url')
        fetch=gitdir/'FETCH_HEAD';fetched=[]
        if fetch.is_file():
            for line in fetch.read_text().splitlines():
                token=line.split('\t',1)[0]
                if re.fullmatch('[a-f0-9]{40,64}',token):fetched.append(token)
        changed=(git(directory,'diff','--name-only','--no-renames','-z','HEAD') or b'').split(b'\0') if head else []
        untracked=(git(directory,'ls-files','--others','--exclude-standard','-z') or b'').split(b'\0')
        details=[]
        for raw in sorted(set(changed+untracked)-{b''}):
            name=os.fsdecode(raw);file=directory/name
            if Path(name).is_absolute() or '..' in Path(name).parts:raise ValueError('noncanonical Git path')
            item=dict(path=name,kind='untracked' if raw in untracked else 'tracked-change')
            if file.is_symlink():item.update(kind='symlink',target=os.readlink(file))
            elif file.is_file():item.update(sha256=hashlib.sha256(file.read_bytes()).hexdigest(),bytes=file.stat().st_size)
            else:item['kind']='deleted-or-nonregular'
            details.append(item)
        repositories.append(dict(path=str(directory.relative_to(root)),gitdir=str(gitdir.relative_to(root)),
             head=head.decode().strip() if head else None,refs=refs.decode().splitlines(),fetchHeads=fetched,
             origin=origin.decode().strip() if origin else None,
             dirty=bool(status),changedPaths=details,statusSha256=hashlib.sha256(status).hexdigest(),
             stagedPatchSha256=hashlib.sha256(staged).hexdigest(),workingPatchSha256=hashlib.sha256(working).hexdigest()))
    if not repositories:return None
    tag=path/'CACHEDIR.TAG'
    cache=tag.is_file() and tag.read_bytes().startswith(b'Signature: 8a477f597d28d172789f06886806bc55')
    kind='package-source-cache' if cache else 'source-working-area'
    integration_record=None
    if integration is not None:
        canonical=Path(integration).resolve(strict=True)
        actual=git(canonical,'rev-parse','--show-toplevel')
        if actual is None or Path(actual.decode().strip()).resolve()!=canonical:raise ValueError('exact integration checkout required')
        canonical_head=git(canonical,'rev-parse','--verify','HEAD').decode().strip()
        integration_record=dict(checkout=str(canonical),head=canonical_head,ref='HEAD',repositories=[])
        for repository in repositories:
            # Dependencies have separate Git histories and must be reconciled
            # against their own canonical package checkout, never the parent.
            nested='/.gerbil/pkg/' in repository['path']
            commits=set(repository['fetchHeads'])|({repository['head']} if repository['head'] else set())
            commits.update(ref.split(' ',1)[0] for ref in repository['refs'])
            checks=[];destination=canonical;head=canonical_head;unresolved=False
            if nested:
                suffix=repository['path'].split('/.gerbil/pkg/',1)[1]
                destination=(canonical/'.gerbil/pkg'/suffix).resolve()
                location=git(destination,'rev-parse','--show-toplevel') if destination.is_dir() else None
                unresolved=(location is None or Path(location.decode().strip()).resolve()!=destination)
                if not unresolved:head=git(destination,'rev-parse','HEAD').decode().strip()
            if not unresolved:
                for commit in sorted(commits):
                    result=run(['git','--no-optional-locks','-C',str(destination),'merge-base','--is-ancestor',commit,head],capture_output=True,timeout=30)
                    checks.append(dict(commit=commit,commandExit=result.returncode,reachableFromIntegration=result.returncode==0))
            integration_record['repositories'].append(dict(path=repository['path'],commits=checks,
                         integrationCheckout=str(destination),integrationHead=head,
                         separatePackageReconciliationRequired=unresolved,dirty=repository['dirty']))
        if git(canonical,'rev-parse','HEAD').decode().strip()!=canonical_head:raise ValueError('integration ref changed during audit')
    if cache:
        condition=['producer task quiescent','no live path references',
                   'all refs and FETCH_HEAD objects preserved in the canonical source store or verified Git archive',
                   'dirty/untracked source preserved or explicitly released by its owner']
    else:
        condition=['source owner names an integration checkout and ref','all local commits reachable from that integration ref',
                   'staged, unstaged and untracked source integrated or preserved in a verified custody archive',
                   'all nested package repositories reconciled','producer task quiescent','no live path references']
    return dict(schema='nested-git-custody.v1',kind=kind,ownerProject=_project(path),
                root=str(path.relative_to(root)),repositories=repositories,cacheSentinels=markers,
                integration=integration_record,cleanupConditions=condition,releaseStatus='owner-reconciliation-required',ageAloneReleases=False)


def release_ready(assessment):
    """A named integration ref and real clean histories, never a stored pass flag."""
    if not assessment or not assessment.get('integration'):return False
    if any(repo['dirty'] for repo in assessment['repositories']):return False
    for repo in assessment['integration']['repositories']:
        if repo['separatePackageReconciliationRequired'] or not repo['commits']:return False
        if any(not row['reachableFromIntegration'] for row in repo['commits']):return False
    return True


def verify_saved(assessment):
    """Recheck integrated commits even after a partial deletion removed .git."""
    if not release_ready(assessment):raise ValueError('Git source custody not released')
    for repo in assessment['integration']['repositories']:
        for row in repo['commits']:
            result=run(['git','--no-optional-locks','-C',repo['integrationCheckout'],'merge-base','--is-ancestor',row['commit'],repo['integrationHead']],capture_output=True,timeout=30)
            if result.returncode!=0:raise ValueError('integrated Git history unavailable during cleanup')
