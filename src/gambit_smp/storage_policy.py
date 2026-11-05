"""Validate Python writes before the operating system sees them.

Native subprocesses remain governed by their supervisors and workspace leases.
"""
from contextlib import contextmanager
from contextvars import ContextVar
import os
from pathlib import Path
import sys

_scope = ContextVar('gambit_storage_scope', default=None)
_retirements = ContextVar('gambit_storage_retirements', default=())
_roots = set()
_installed = False
SHARED = {'fixtures','fixture-archives','fixture-evidence','research','history','reasoning',
          'research-actions','workspace-leases','tools','venv','source-cache','source-overlays',
          'source-slices','bench','papers','.gerbil-bench.lock'}
GENERATED_CONTAINERS = {'pro','profile','profiles','prompt','prompts','policy','policies','private','provider-source'}
SOURCE_AREAS = {'src','vendor','provider','providers','provide','vr','.venv'}
SOURCE = {'src','tests','docs','dev','models','evidence','patches','.git','.agents','.codex'}
EVIDENCE_CACHE_SUFFIXES = frozenset({'.gz', '.olean', '.txt', '.rb', '.sh', '.log', '.stdout', '.stderr'})


class StoragePolicyError(ValueError):
    pass


def validate(root, path, *, task=None, deleting=False):
    root=Path(root)
    path=Path(os.fsdecode(path)).absolute()
    if not path.is_relative_to(root):
        prefix=str(root).casefold()+os.sep
        if not str(path).casefold().startswith(prefix):return
        path=root/str(path)[len(str(root))+1:]
    relative=path.relative_to(root)
    if not relative.parts:return
    if '..' in relative.parts:raise StoragePolicyError('noncanonical storage path')
    resolved=(path.parent.resolve()/path.name) if deleting else path.resolve()
    if resolved.is_relative_to(root):
        resolved_parts=resolved.relative_to(root).parts
        if resolved_parts and resolved_parts[0].casefold()=='campaigns' and not deleting:
            raise StoragePolicyError('campaigns/ is forbidden; use the task program/output allocator')
    if relative.parts[0] in {'.cache','.data'} and resolved!=path:
        parent=path.parent
        # Native script links stay in their storage owner. Their resolved target
        # must also pass task/process policy; an inert-looking link is not custody.
        owner=relative.parts[:3] if relative.parts[:2] in {('.cache','tasks'),('.data','worktrees')} else relative.parts[:2]
        internal=(path.is_symlink() and parent.resolve()==parent.absolute()
                  and resolved.is_relative_to(root.resolve())
                  and resolved.relative_to(root.resolve()).parts[:len(owner)]==owner)
        if not internal:
            raise StoragePolicyError('storage aliases are forbidden')
        validate(root,resolved,task=task,deleting=deleting)
    first=relative.parts[0]
    if first.casefold()=='campaigns':
        if deleting:return
        raise StoragePolicyError('campaigns/ is forbidden; use the task program/output allocator')
    # Source editing authority never admits generated runtime subtrees. Apply
    # before the unscoped return and to resolved paths, including source aliases.
    parts=resolved.relative_to(root).parts if resolved.is_relative_to(root) else relative.parts
    if len(parts)>3 and parts[:2]==('.data','worktrees'):
        parts=parts[3:]
    if (not deleting and parts and parts[0].casefold() == 'evidence'
            and Path(parts[-1]).suffix.casefold() in EVIDENCE_CACHE_SUFFIXES):
        raise StoragePolicyError('compressed archives, compiled output, scratch text and scripts do not belong in evidence/: '+str(relative))
    if not deleting and parts and parts[0].casefold() in SOURCE_AREAS:
        if any(part.casefold() in GENERATED_CONTAINERS for part in parts[1:]):
            raise StoragePolicyError('generated runtime directories require .cache/: '+str(relative))
    if not task:return
    if deleting and any(path == target or path.is_relative_to(target) for target in _retirements.get()):
        return
    if first in {'.state','.git','.venv'} or first in SOURCE:return
    if first=='.cache':
        if not task:return  # Historical unscoped readers are not execution custody.
        process=os.environ.get('GAMBIT_SMP_TASK_PROCESS')
        if relative.parts[1:3]==('tasks',task):
            if not process or relative.parts[3:5]==('processes',process):return
            raise StoragePolicyError('process cannot write another work-item execution area')
        if len(relative.parts)>1 and relative.parts[1] in SHARED:return
        # mkdir(parents=True) may probe already-existing common ancestors.
        if path.is_dir() and len(relative.parts)<=2:return
        from gambit_smp.task_dependencies import dependencies
        if not os.environ.get('GAMBIT_SMP_TASK_PROCESS') and any(path==saved or path.is_relative_to(saved) for saved in dependencies(root,task)):return
        raise StoragePolicyError('unmanaged task write; allocate task output: '+str(relative))
    if first=='.data':
        if not task:return
        if relative.parts[1:2]==('worktrees',) or (len(relative.parts)>1 and relative.parts[1] in SHARED):return
        from gambit_smp.task_dependencies import dependencies
        if not os.environ.get('GAMBIT_SMP_TASK_PROCESS') and any(path==saved or path.is_relative_to(saved) for saved in dependencies(root,task)):return
        raise StoragePolicyError('unmanaged task workspace; use the workspace allocator')
    if len(relative.parts)>1:
        raise StoragePolicyError('unregistered top-level output directory: '+first)
    if path.suffix in {'.log','.jsonl','.stdout','.stderr'}:
        raise StoragePolicyError('runtime output must use the task allocator')


@contextmanager
def retiring_fixture(path):
    """A checked pruner may delete one old task fixture, never build products."""
    scope = _scope.get()
    target = Path(path).absolute()
    if scope:
        root, task = scope
        store = root / '.cache/tasks' / task / 'fixtures'
        if target == store or not target.is_relative_to(store) or target.resolve() != target:
            raise StoragePolicyError('retirement requires an exact non-alias owned fixture')
    token = _retirements.set((*_retirements.get(), target))
    try:
        yield
    finally:
        _retirements.reset(token)


def _directory_target(path, descriptor):
    if not isinstance(path, (str, bytes, os.PathLike)) or descriptor in (None, -1) or Path(os.fsdecode(path)).is_absolute():
        return path
    if sys.platform == 'darwin':
        import fcntl
        # F_GETPATH from the platform sys/fcntl.h; the FD, not cwd, owns this name.
        base = Path(os.fsdecode(fcntl.fcntl(descriptor, 50, bytes(1024)).split(b'\0', 1)[0]))
    else:
        base = Path(os.readlink('/proc/self/fd/' + str(descriptor)))
    actual, held = base.stat(), os.fstat(descriptor)
    if (actual.st_dev, actual.st_ino) != (held.st_dev, held.st_ino):
        raise StoragePolicyError('directory descriptor identity changed')
    return base / os.fsdecode(path)


def _audit(event,args):
    scope=_scope.get()
    if scope and event in {'subprocess.Popen','os.system','os.posix_spawn','os.fork','os.forkpty','os.exec'}:
        from gambit_smp.spawn_protocol import _popen_authority,_exec_authority
        permitted=(event=='subprocess.Popen' and _popen_authority.get()) or (event=='os.exec' and _exec_authority.get())
        if not permitted:
            raise StoragePolicyError('child execution must use the durable birth/exec boundary')
    targets=[];deleting=False;descriptor=None
    if event=='open':
        mode,flags=args[1],args[2]
        if (isinstance(mode,str) and any(c in mode for c in 'wax+')) or (isinstance(flags,int) and flags & (os.O_WRONLY|os.O_RDWR|os.O_CREAT|os.O_TRUNC)):
            targets=[args[0]]
    elif event in {'os.mkdir','os.chmod','os.utime','os.truncate'}:
        targets=[args[0]]
        descriptor = args[-1] if event != 'os.truncate' else None
    elif event in {'os.remove','os.rmdir'}:
        targets=[args[0]];deleting=True;descriptor=args[1]
    elif event in {'os.rename','os.link','os.symlink'}:
        targets=[args[1]];descriptor=args[2] if event == 'os.symlink' else args[3]
    scope=_scope.get()
    if not scope and deleting:return  # Custody-controlled removal never creates a forbidden root.
    for target in targets:
        if not isinstance(target,(str,bytes,os.PathLike)):continue
        target = _directory_target(target, descriptor)
        if scope:
            validate(scope[0],target,task=scope[1],deleting=deleting)
        else:
            for root in tuple(_roots):validate(root,target,deleting=deleting)


def install(root):
    global _installed
    _roots.add(Path(root).resolve())
    if not _installed:
        sys.addaudithook(_audit);_installed=True


@contextmanager
def runtime_environment(root):
    """One cache location across providers; no directory creation on entry."""
    root=Path(root).resolve()
    values={'PYTHONPYCACHEPREFIX':str(root/'.cache/tools/python/pycache'),
            'UV_CACHE_DIR':str(root/'.cache/tools/uv'),
            'XDG_CACHE_HOME':str(root/'.cache/tools/xdg')}
    previous={name:os.environ.get(name) for name in values}
    prefix=sys.pycache_prefix
    os.environ.update(values);sys.pycache_prefix=values['PYTHONPYCACHEPREFIX']
    try:yield
    finally:
        sys.pycache_prefix=prefix
        for name,value in previous.items():
            if value is None:os.environ.pop(name,None)
            else:os.environ[name]=value


@contextmanager
def enforce(root,task):
    install(root)
    token=_scope.set((Path(root).resolve(),task))
    try:
        with runtime_environment(root):yield
    finally:_scope.reset(token)


def activate(root,task):
    install(root)
    _scope.set((Path(root).resolve(),task))
