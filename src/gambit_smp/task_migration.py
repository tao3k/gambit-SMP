"""One-time source migration. No old entry point or runtime compatibility loader."""
import ast
import hashlib
import json
import os
from pathlib import Path

from gambit_smp.workspace import bounded, paths, lease, write, now, active_paths, referenced
from gambit_smp.task_dependencies import registry


def rewrite_process_calls(raw):
    """Direct source migration of subprocess calls, including import aliases."""
    tree=ast.parse(raw);modules=set();direct={};changed=[]
    names={'Popen':'spawn','run':'run','check_output':'check_output','call':'run','check_call':'run'}
    for node in ast.walk(tree):
        if isinstance(node,ast.Import):
            modules.update(a.asname or a.name for a in node.names if a.name=='subprocess')
        elif isinstance(node,ast.ImportFrom) and node.module=='subprocess':
            direct.update({a.asname or a.name:a.name for a in node.names if a.name in names})
    class Rewrite(ast.NodeTransformer):
        def visit_Call(self,node):
            node=self.generic_visit(node);f=node.func
            name=(f.attr if isinstance(f,ast.Attribute) and isinstance(f.value,ast.Name) and f.value.id in modules
                  else direct.get(f.id) if isinstance(f,ast.Name) else None)
            if name not in names:return node
            changed.append(dict(line=node.lineno,call=name))
            node.func=ast.Name('_birth_exec_'+names[name],ast.Load())
            if name=='check_call':node.keywords.append(ast.keyword('check',ast.Constant(True)))
            return ast.copy_location(ast.Attribute(node,'returncode',ast.Load()),node) if name in {'call','check_call'} else node
    tree=Rewrite().visit(tree)
    if not changed:return raw,[]
    prelude=ast.parse('from gambit_smp.task_processes import spawn as _birth_exec_spawn, run as _birth_exec_run, check_output as _birth_exec_check_output').body
    position=0
    if tree.body and isinstance(tree.body[0],ast.Expr) and isinstance(tree.body[0].value,ast.Constant) and isinstance(tree.body[0].value.value,str):position=1
    while position<len(tree.body) and isinstance(tree.body[position],ast.ImportFrom) and tree.body[position].module=='__future__':position+=1
    tree.body[position:position]=prelude
    result=(ast.unparse(ast.fix_missing_locations(tree))+'\n').encode()
    compile(result,'<birth-exec-source-migration>','exec')
    return result,changed


def script_record(root, task, key):
    from gambit_smp.workspace import identifier
    return bounded(root, '.state/task-scripts/' + identifier(task) + '/' + identifier(key) + '.json')


def migrate(root, task, script, *, enabled=False, opened=None, resume=False):
    """Rewrite source into the campaign, verify custody, then remove the old file."""
    root = Path(root).resolve(strict=True)
    script = bounded(root, script)
    with lease(root, 'storage-retention'), lease(root, task):
        return _migrate_locked(root,task,script,enabled=enabled,opened=opened,resume=resume)


def migrate_many(root,task,items):
    """One task boundary for the complete old-entry retirement transaction."""
    root=Path(root).resolve(strict=True)
    with lease(root,'storage-retention'),lease(root,task):
        opened=active_paths()
        result=[]
        for row in items:
            script=bounded(root,row['original'])
            key=hashlib.sha256(row['original'].encode()).hexdigest()
            record=script_record(root,task,key)
            if record.exists():
                entry=json.loads(record.read_text())
                if entry['state']=='migrated':
                    if script.exists() or hashlib.sha256(Path(entry['path']).read_bytes()).hexdigest()!=entry['sha256']:
                        raise ValueError('completed migration no longer matches source custody')
                    result.append(entry);continue
                resume=True
            else:resume=False
            result.append(_migrate_locked(root,task,script,enabled=row['enabled'],opened=opened,resume=resume))
        return result


def _migrate_locked(root,task,script,*,enabled,opened,resume):
    if json.loads(paths(root, task)[0].read_text())['state'] != 'open':
        raise ValueError('open task required for source migration')
    if referenced(script, active_paths() if opened is None else opened):
        raise ValueError('script occupied; migration deferred')
    key = hashlib.sha256(str(script.relative_to(root)).encode()).hexdigest()
    manifest=script_record(root,task,key)
    if resume:
        entry=json.loads(manifest.read_text())
        if entry['state']!='prepared':raise ValueError('prepared migration required')
        return commit(root,task,script,manifest,entry)
    original = script.read_bytes()
    identity=script.stat()
    raw,process_calls = rewrite_process_calls(original)
    source_sha = hashlib.sha256(original).hexdigest()
    archive = bounded(root, '.state/storage/script-sources/' + source_sha + '.py')
    archive.parent.mkdir(parents=True, exist_ok=True)
    if archive.exists() and archive.read_bytes() != original:
        raise ValueError('source archive differs')
    if not archive.exists():
        with archive.open('xb') as stream:
            stream.write(original);stream.flush();os.fsync(stream.fileno())
    relocations = bounded(root, '.state/storage/task-relocations.json')
    mappings = json.loads(relocations.read_text())['relocations'] if relocations.exists() else []

    class Rewrite(ast.NodeTransformer):
        output = False
        def visit_Assign(self, node):
            previous = self.output
            self.output = any(isinstance(n, ast.Name) and n.id.lower() in {'out', 'output', 'outdir', 'output_dir'} for target in node.targets for n in ast.walk(target))
            node = self.generic_visit(node)
            self.output = previous
            return node
        def visit_Constant(self, node):
            if not isinstance(node.value, str):
                return node
            name = Path(node.value)
            if name.is_absolute():
                if not name.is_relative_to(root):return node
                name = name.relative_to(root)
            if len(name.parts) < 2 or name.parts[0] not in {'.cache', '.data'}:
                return node
            path = bounded(root, name)
            for row in mappings:
                before = root / row['source']
                if path == before or path.is_relative_to(before):
                    return ast.copy_location(ast.Constant(str(bounded(root, Path(row['destination']) / path.relative_to(before)))),node)
            if self.output or (name.parts[0] == '.cache' and not path.exists()):
                # Ordinary framework output allocation in the rewritten code.
                return ast.copy_location(ast.Call(ast.Name('str',ast.Load()), [ast.Call(
                    ast.Name('_task_output',ast.Load()), [ast.Constant(str(root)),ast.Constant(str(name))],[])],[]),node)
            # Input paths keep their real physical checkpoint, without a resolver.
            return node

    tree = Rewrite().visit(ast.parse(raw))
    prelude = ast.parse('from gambit_smp.workspace import require_execution as _task_require_execution\n'
                        '_task_require_execution(' + repr(str(root)) + ', ' + repr(task) + ', __file__)\n'
                        'from gambit_smp.artifact_storage import runtime_output as _task_output\n').body
    position=0
    if tree.body and isinstance(tree.body[0],ast.Expr) and isinstance(tree.body[0].value,ast.Constant) and isinstance(tree.body[0].value.value,str):position=1
    while position<len(tree.body) and isinstance(tree.body[position],ast.ImportFrom) and tree.body[position].module=='__future__':position+=1
    tree.body[position:position]=prelude
    migrated=(ast.unparse(ast.fix_missing_locations(tree))+'\n').encode()
    compile(migrated,str(script),'exec')
    checkout=Path(json.loads(paths(root,task)[0].read_text())['checkout'])
    destination=bounded(root,paths(root,task)[1].relative_to(root)/'programs'/(key[:12]+'-'+script.name))
    manifest=script_record(root,task,key)
    if manifest.exists():raise ValueError('script already migrated; inspect its durable manifest')
    destination.parent.mkdir(parents=True,exist_ok=True)
    with destination.open('xb') as stream:
        stream.write(migrated);stream.flush();os.fsync(stream.fileno())
    entry=dict(task=task,key=key,path=str(destination),sha256=hashlib.sha256(migrated).hexdigest(),
               processCallMigration=process_calls,
               original=str(script.relative_to(root)),originalSha256=source_sha,archive=str(archive.relative_to(root)),
               enabled=enabled,state='prepared',at=now().isoformat(),nativeAdmitted=False,
               originalEntrySha256=hashlib.sha256(original).hexdigest(),
               originalIdentity=[identity.st_dev,identity.st_ino])
    write(manifest,entry)
    return commit(root,task,script,manifest,entry)

def commit(root,task,script,manifest,entry):
    destination=Path(entry['path'])
    if hashlib.sha256(destination.read_bytes()).hexdigest()!=entry['sha256']:
        raise ValueError('prepared campaign source changed')
    if hashlib.sha256(bounded(root,entry['archive']).read_bytes()).hexdigest()!=entry['originalSha256']:
        raise ValueError('original source archive changed')
    if script.exists():
        st=script.stat()
        if ([st.st_dev,st.st_ino]!=entry['originalIdentity'] or
                hashlib.sha256(script.read_bytes()).hexdigest()!=entry['originalEntrySha256']):
            raise ValueError('old source changed during migration')
    pins=registry(root,task)
    if pins.exists():
        deps=json.loads(pins.read_text());removed=[row for row in deps['paths'] if row['path']==entry['original']]
        deps['paths']=[row for row in deps['paths'] if row['path']!=entry['original']]
        deps.setdefault('migratedScripts',[]).extend(dict(row,destination=str(destination),sha256=entry['sha256']) for row in removed)
        write(pins,deps)
    script.unlink(missing_ok=True)
    entry['state']='migrated';write(manifest,entry)
    return entry


def upgrade_process_calls(root,task):
    """Migrate registered sources in place under the existing work-item owner.

    A prepared checkpoint binds both byte generations; interrupted replacement
    resumes from either exact generation. No compatibility execution or hash fix.
    """
    from gambit_smp.workspace import inherited_lease
    from gambit_smp.source_identity import retain_sources,read_source
    root=Path(root).resolve(strict=True)
    if os.environ.get('GAMBIT_SMP_TASK_PROCESS') or inherited_lease(root,task) is None:
        raise ValueError('program migration requires exclusive work-item execution custody')
    result=[]
    with lease(root,'storage-retention'):
        occupied=active_paths()
        for manifest in sorted(bounded(root,'.state/task-scripts/'+task).glob('*.json')):
            row=json.loads(manifest.read_text());script=bounded(root,Path(row['path']).relative_to(root))
            if row['state']!='migrated':raise ValueError('complete original source migration first')
            if referenced(script,occupied):raise ValueError('program occupied; source migration deferred')
            raw=script.read_bytes();previous=row.get('processMigration',{})
            if previous.get('state')=='prepared':
                before=read_source(root,previous['before']);after=read_source(root,previous['after'])
                if raw not in (before,after):raise ValueError('program changed during birth/exec migration')
            else:
                if hashlib.sha256(raw).hexdigest()!=row['sha256']:raise ValueError('program source seal changed')
                after,calls=rewrite_process_calls(raw)
                if not calls:continue
                sources=retain_sources(root,{'before':raw,'after':after})
                previous=dict(state='prepared',before=sources['before'],after=sources['after'],calls=calls,
                              previousSha256=row['sha256'],preparedAt=now().isoformat())
                row['processMigration']=previous;write(manifest,row)
            if raw!=after:
                temporary=script.with_name(script.name+'.birth-exec-tmp')
                try:
                    with temporary.open('xb') as stream:
                        stream.write(after);stream.flush();os.fsync(stream.fileno())
                    temporary.replace(script)
                    fd=os.open(script.parent,os.O_RDONLY)
                    try:os.fsync(fd)
                    finally:os.close(fd)
                finally:temporary.unlink(missing_ok=True)
            if script.read_bytes()!=after:raise ValueError('program source migration did not persist')
            row.update(sha256=hashlib.sha256(after).hexdigest())
            previous.update(state='migrated',completedAt=now().isoformat())
            write(manifest,row);result.append(dict(key=row['key'],calls=len(previous['calls']),path=row['path']))
    return result


def normalize_programs(root,task):
    """Retire the rejected root campaigns directory, preserving exact program bytes."""
    root=Path(root).resolve(strict=True)
    with lease(root,'storage-retention'),lease(root,task):
        directory=bounded(root,'.state/task-scripts/'+task)
        moved=[];opened=active_paths()
        for manifest in sorted(directory.glob('*.json')):
            row=json.loads(manifest.read_text())
            canonical=bounded(root,paths(root,task)[1].relative_to(root)/'programs'/Path(row['path']).name)
            if row['state']=='relocating':
                before=bounded(root,row['relocation']['from'])
            else:
                before=Path(row['path'])
                if before==canonical:continue
                if not before.is_relative_to(root/'campaigns'):raise ValueError('unexpected program location')
                before=bounded(root,before.relative_to(root))
                if referenced(before,opened):raise ValueError('program occupied; relocation deferred')
                st=before.stat()
                row.update(state='relocating',relocation=dict(
                    **{'from':str(before.relative_to(root))},to=str(canonical.relative_to(root)),identity=[st.st_dev,st.st_ino]))
                write(manifest,row)
            source=before if before.exists() else canonical
            raw=source.read_bytes();st=source.stat()
            if (hashlib.sha256(raw).hexdigest()!=row['sha256'] or [st.st_dev,st.st_ino]!=row['relocation']['identity']):
                raise ValueError('program changed during organization migration')
            archive=bounded(root,'.state/storage/program-sources/'+row['sha256']+'.py')
            archive.parent.mkdir(parents=True,exist_ok=True)
            if archive.exists() and archive.read_bytes()!=raw:raise ValueError('program archive differs')
            if not archive.exists():
                with archive.open('xb') as stream:stream.write(raw);stream.flush();os.fsync(stream.fileno())
            if before.exists():
                if canonical.exists():raise ValueError('program destination already occupied')
                canonical.parent.mkdir(parents=True,exist_ok=True)
                before.replace(canonical)
            row.update(path=str(canonical),state='migrated',programArchive=str(archive.relative_to(root)))
            write(manifest,row);moved.append(row['key'])
        # Remove only empty directories owned by the rejected organization.
        for relative in ['campaigns/'+task+'/scripts','campaigns/'+task,'campaigns']:
            path=bounded(root,relative)
            if path.exists() and not any(path.iterdir()):path.rmdir()
        return moved
