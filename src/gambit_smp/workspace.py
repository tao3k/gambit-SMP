"""Provider-independent task custody and two-calendar-day artifact retention.

Source trees are reclaimed separately, through Git, never by cache expiry.
"""
import argparse
from contextlib import contextmanager, nullcontext
from datetime import datetime, timedelta
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import uuid
import hashlib
import sys
import signal
import math
import sqlite3
import threading
from contextlib import closing
from zoneinfo import ZoneInfo

ZONE = ZoneInfo("Asia/Shanghai")
_process_scope_lock = threading.RLock()


def now():
    return datetime.now(ZONE)


def bounded(root, relative):
    root = Path(root).resolve(strict=True)
    relative = Path(relative)
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError("bounded relative path required")
    path = root / relative
    for ancestor in (path, *path.parents):
        if ancestor == root:
            break
        if ancestor.is_symlink():
            raise ValueError("storage aliases are forbidden")
    return path


def identifier(value):
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,79}", value):
        raise ValueError("stable lowercase task ID required; do not include provider or date")
    return value


def paths(root, task):
    task = identifier(task)
    return (bounded(root, ".state/tasks/" + task + ".json"),
            bounded(root, ".cache/tasks/" + task),
            bounded(root, ".data/worktrees/" + task))


def context_owner(root,task):
    process=os.environ.get('GAMBIT_SMP_TASK_PROCESS')
    if process and os.environ.get('GAMBIT_SMP_TASK_ID')==task:
        from gambit_smp.work_process import paths as process_paths
        return process_paths(root,task,process)[0]
    return paths(root,task)[0]


def context_run(root,task,run):
    process=os.environ.get('GAMBIT_SMP_TASK_PROCESS')
    if process and os.environ.get('GAMBIT_SMP_TASK_ID')==task:
        from gambit_smp.work_process import run_path
        return run_path(root,task,process,run)
    return bounded(root,'.state/task-runs/'+task+'/'+identifier(run)+'.json')


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix="." + path.name + "-", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        temporary.replace(path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        temporary.unlink(missing_ok=True)


@contextmanager
def lease(root, task):
    record, _, _ = paths(root, task)
    record.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(record.with_suffix(".lock"), os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        yield fd
    finally:
        os.close(fd)


def git(root, *arguments):
    from gambit_smp.task_processes import run
    env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
    return run(["git", "-C", str(root), *arguments], check=True,
                          capture_output=True, text=True, env=env).stdout.strip()


def start(root, task, *, ref=None, adopt=False):
    """Adopt current checkout or create exactly one explicitly requested worktree."""
    root = Path(root).resolve(strict=True)
    if ref is not None and adopt:
        raise ValueError("choose a new worktree or explicit checkout adoption")
    from gambit_smp.work_items import admit
    admit(root,task)
    collect(root)
    record, cache, tree = paths(root, task)
    with lease(root, "work-item-admission"),lease(root, task):
        admit(root,task)
        if record.exists():
            value = json.loads(record.read_text())
            if value["state"] != "open":
                raise ValueError("closed task ID cannot silently restart")
            if ref is not None:
                raise ValueError("existing task already has a checkout; omit --ref to reuse it")
            return value
        if ref is None and not adopt:
            raise ValueError("new task requires --ref for a worktree or explicit --adopt")
        starting = git(root, "rev-parse", "--verify", "--end-of-options", ref + "^{commit}") if ref else git(root, "rev-parse", "HEAD")
        value = dict(schema=1, task=task, root=str(root), checkout=str(tree if ref else root),
                     ownedWorktree=ref is not None, state="preparing", createdAt=now().isoformat(),
                     lastActivity=now().isoformat(), cache=str(cache), head=starting)
        write(record, value)
        if ref is not None:
            tree.parent.mkdir(parents=True, exist_ok=True)
            # No --force, reset, branch deletion, or dirty-checkout copying.
            git(root, "worktree", "add", "-b", "task/" + task, str(tree), starting)
            value["head"] = git(tree, "rev-parse", "HEAD")
        cache.mkdir(parents=True, exist_ok=True)
        value["state"] = "open"
        write(record, value)
        return value


def inherited_lease(root, task):
    """An inherited open lock description, never an environment-only assertion."""
    raw = os.environ.get("GAMBIT_SMP_TASK_LOCK_FD")
    if raw is None:
        from gambit_smp.task_broker import borrow
        borrowed=borrow(Path(root).resolve(strict=True),task)
        if borrowed is None:return None
        raw=str(borrowed)
    fd = int(raw)
    record = context_owner(root,task)
    lock = record.with_suffix(".lock")
    try:
        actual = os.fstat(fd)
    except OSError:
        from gambit_smp.task_broker import borrow
        fd=borrow(Path(root).resolve(strict=True),task)
        if fd is None:raise ValueError('inherited task descriptor is closed')
        actual=os.fstat(fd)
    expected = lock.stat()
    if (actual.st_dev, actual.st_ino) != (expected.st_dev, expected.st_ino):
        from gambit_smp.task_broker import borrow
        replacement=borrow(Path(root).resolve(strict=True),task)
        if replacement is None:raise ValueError("inherited task lease identity differs")
        fd=replacement;actual=os.fstat(fd)
        if (actual.st_dev,actual.st_ino)!=(expected.st_dev,expected.st_ino):raise ValueError('broker lease identity differs')
    probe = os.open(lock, os.O_RDWR | os.O_NOFOLLOW)
    try:
        try:
            fcntl.flock(probe, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return fd
        raise ValueError("inherited task lease is not held")
    finally:
        os.close(probe)


def pending(root):
    """Read existing operational state; absence never creates an empty journal."""
    database = bounded(root, ".state/research-actions/requests.sqlite")
    if not database.exists():
        # A retired writer store cannot substitute for missing durable custody.
        if bounded(root, ".cache/research-actions/requests.sqlite").exists():
            raise ValueError("durable requests missing; reconcile before lifecycle transition")
        return 0
    with closing(sqlite3.connect(database.as_uri() + "?mode=ro", uri=True)) as db:
        if db.execute("PRAGMA quick_check").fetchone() != ("ok",):
            raise ValueError("request journal integrity failure")
        return db.execute("SELECT count(*) FROM requests WHERE result IS NULL").fetchone()[0]


def transition_check(root, value):
    """Conservative host observation, not a native recovery/admission result."""
    from gambit_smp.task_dependencies import dependencies
    for store in (".cache/workspace-leases", ".data/workspace-leases"):
        if any(bounded(root, store).glob("*.quarantine.json")):
            raise ValueError("workspace quarantine requires producer reconciliation")
    from gambit_smp.task_processes import check
    child_observations=check(root,value["task"])
    occupied = active_paths()
    dependency_observations = []
    watched = [Path(value["cache"]), *dependencies(root, value["task"], observations=dependency_observations)]
    if any(referenced(path, occupied) for path in watched):
        raise ValueError("task dependencies are occupied; transition deferred")
    for run in bounded(root, ".state/task-runs/" + value["task"]).glob("*.json"):
        row = json.loads(run.read_text())
        if row.get("state")=="running":
            supervisor=row.get("supervisorPid")
            if supervisor is None:raise ValueError("legacy running receipt lacks supervisor custody")
            try:os.kill(supervisor,0)
            except ProcessLookupError:pass
            else:raise ValueError("task supervisor still alive")
        if row.get("pgid") and row.get("custodyProtocol",0)<3:
            try:
                os.killpg(row["pgid"], 0)
            except ProcessLookupError:
                pass
            else:
                raise ValueError("recorded process group still present; reconcile without replay")
    if pending(root):
        raise ValueError("pending requests require real recovery; replay and completion denied")
    return {"observedAt": now().isoformat(), "pendingRequests": 0,
            "dependencyCount": len(watched), "dependencies": dependency_observations,
            "childObservations": child_observations, "nativeAdmitted": False}


@contextmanager
def execution_scope(root, task, provider="codex"):
    """All provider and legacy entries share lock custody and durable attempts."""
    root = Path(root).resolve(strict=True)
    from gambit_smp.work_items import admit
    admit(root,task,os.environ.get('GAMBIT_SMP_TASK_PROCESS'))
    record, cache, _ = paths(root, task)
    inherited = inherited_lease(root, task)
    if inherited is not None:
        value = json.loads(context_owner(root,task).read_text())
        run_id = os.environ.get("GAMBIT_SMP_TASK_RUN")
        run = context_run(root,task,run_id or "")
        receipt = json.loads(run.read_text())
        if value["state"] != "open" or receipt["state"] != "running" or value.get("run") != run_id:
            raise ValueError("inherited execution is not current")
        from gambit_smp.storage_policy import enforce
        with enforce(root,task):
            yield value, inherited, run
        return
    collect(root)
    with _process_scope_lock, lease(root, task) as fd:
        value = json.loads(record.read_text())
        if value["state"] != "open":
            raise ValueError("task is not open")
        if value.get("execution") in {"running", "interrupted"}:
            raise ValueError("uncertain previous execution; explicit workspace resume required")
        if value.get("run"):
            prior = json.loads(bounded(root, ".state/task-runs/" + task + "/" + identifier(value["run"]) + ".json").read_text())
            from gambit_smp.task_processes import check
            check(root,task)
            if prior.get("pgid") and prior.get("custodyProtocol",0)<3:
                try:
                    os.killpg(prior["pgid"], 0)
                except ProcessLookupError:
                    pass
                else:
                    raise ValueError("previous process group remains; refuse overlapping execution")
        module = Path(__file__).resolve()
        selected_module = Path(value["checkout"]) / "src/gambit_smp/workspace.py"
        if selected_module.exists() and selected_module.resolve() != module:
            raise ValueError("interpreter imports another checkout; bind task Python environment first")
        run_id = uuid.uuid4().hex
        run = bounded(root, ".state/task-runs/" + task + "/" + run_id + ".json")
        cache.mkdir(parents=True, exist_ok=True)
        write(run, dict(schema=1, custodyProtocol=3, task=task, run=run_id, provider=provider, state="running",
                        startedAt=now().isoformat(), nativeAdmitted=False,
                        supervisorPid=os.getpid(), interpreter=sys.executable, frameworkSource=str(module),
                        frameworkSha256=hashlib.sha256(module.read_bytes()).hexdigest(),
                        output=str(cache / "runs" / run_id)))
        value.pop("exit", None)
        value.update(run=run_id, execution="running", lastActivity=now().isoformat(), lastProvider=provider)
        write(record, value)
        names = dict(GAMBIT_SMP_TASK_ID=task, GAMBIT_SMP_TASK_ROOT=str(root),
                     GAMBIT_SMP_TASK_CACHE=str(cache), GAMBIT_SMP_TASK_LOCK_FD=str(fd),
                     GAMBIT_SMP_TASK_RUN=run_id)
        old = {key: os.environ.get(key) for key in names}
        os.environ.update(names)
        try:
            from gambit_smp.storage_policy import enforce
            from gambit_smp.task_broker import serve
            broker=serve(root,task,run_id,fd) if provider=="grok" else nullcontext()
            with enforce(root,task),broker:
                yield value, fd, run
        except SystemExit as outcome:
            value.update(execution="returned", exit=outcome.code if isinstance(outcome.code, int) else (0 if outcome.code is None else 1))
            raise
        except BaseException:
            value["execution"] = "interrupted"
            raise
        else:
            if value.get("execution")!="interrupted":value["execution"] = "returned"
        finally:
            receipt = json.loads(run.read_text())
            receipt.update(state=value["execution"], endedAt=now().isoformat())
            if "exit" in value:
                receipt["exit"] = value["exit"]
            write(run, receipt)
            value.update(lastActivity=now().isoformat(), descendants="unverified")
            write(record, value)
            for key, old_value in old.items():
                if old_value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = old_value


def execute(root, task, command, *, provider="codex", wall_seconds=1800):
    if not command or provider not in {"codex", "grok"}:
        raise ValueError("literal argv and supported provider required")
    if isinstance(wall_seconds, bool) or not math.isfinite(wall_seconds) or wall_seconds <= 0:
        raise ValueError("positive finite task wall budget required")
    with execution_scope(root, task, provider) as (value, fd, run):
        from gambit_smp.task_broker import serve
        external_agent=Path(str(command[0])).name in {'codex','grok'}
        if external_agent and os.environ.get('GAMBIT_SMP_TASK_PROCESS'):
            raise ValueError('provider sessions require the work-item execution owner; maintenance processes run bounded tools')
        broker=serve(Path(root).resolve(),task,os.environ['GAMBIT_SMP_TASK_RUN'],fd) if external_agent and not os.environ.get('GAMBIT_SMP_TASK_SOCKET') else nullcontext()
        with broker:
            from gambit_smp.task_processes import recorder
            record_child=recorder();token=uuid.uuid4().hex
            launch_deadline=__import__('time').monotonic()+wall_seconds
            try:
                from gambit_smp.artifact_storage import workspace_custody
                with workspace_custody() as (workspace_fds,environment):
                    from gambit_smp.spawn_protocol import launch
                    process = launch(command,record=record_child,token=token,birth_budget=min(10,wall_seconds),launch_deadline=launch_deadline,cwd=value['checkout'],env=environment,
                        pass_fds=tuple({fd,*workspace_fds}),start_new_session=True)
            except OSError:
                record_child('spawn-failed',token,{})
                raise
            except subprocess.TimeoutExpired:
                # launch() has reaped any helper it created; target exit is unknown.
                receipt = json.loads(run.read_text())
                if receipt.get('supervisorPid') == os.getpid():
                    receipt.update(exit=None, timedOut=True, parentReaped=True, spawnInterrupted=True)
                    write(run, receipt)
                record_child('interrupted',token,dict(exit=None,parentReaped=True,timedOut=True))
                raise
            receipt = json.loads(run.read_text())
            owns=receipt.get('supervisorPid')==os.getpid()
            if owns:
                receipt.update(pid=process.pid, pgid=process.pid, argv=[str(arg) for arg in command])
                write(run, receipt)
            try:
                code = process.wait(timeout=max(.001,launch_deadline-__import__('time').monotonic()))
            except BaseException as error:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait()
                receipt.update(exit=process.returncode, parentReaped=True,
                               timedOut=isinstance(error, subprocess.TimeoutExpired))
                if owns:write(run, receipt)
                record_child('interrupted',token,dict(exit=process.returncode,parentReaped=True))
                raise
            receipt.update(exit=code, parentReaped=True)
            if owns:write(run, receipt)
            record_child('finished',token,dict(exit=code,parentReaped=True))
            # Return status never proves detached descendants or native restoration.
            value["exit"] = code
            return code

def resume(root, task):
    """Reconcile custody without rerunning an action or restoring native memory."""
    record, cache, tree = paths(root, task)
    with lease(root, task):
        value = json.loads(record.read_text())
        if value["state"] == "preparing":
            checkout = Path(value["checkout"])
            if not checkout.exists() or git(checkout, "rev-parse", "--show-toplevel") != str(checkout):
                raise ValueError("incomplete worktree setup requires explicit reconciliation")
            if value["ownedWorktree"] and git(checkout, "symbolic-ref", "--short", "HEAD") != "task/" + task:
                raise ValueError("worktree branch differs from preparation")
            if git(checkout, "rev-parse", "HEAD") != value["head"]:
                raise ValueError("prepared worktree head changed; reconcile source explicitly")
            cache.mkdir(parents=True, exist_ok=True)
        elif value["state"] != "open":
            raise ValueError("closed task cannot resume")
        observation = transition_check(root, value)
        if value.get("run"):
            prior=bounded(root,".state/task-runs/"+task+"/"+identifier(value["run"])+".json")
            receipt=json.loads(prior.read_text())
            if receipt['state']=='running':receipt['state']='interrupted'
            if receipt['state']=='interrupted':receipt.setdefault('endedAt',observation['observedAt'])
            from gambit_smp.task_broker import cleanup
            cleanup(receipt)
            receipt['reconciliation']=observation
            write(prior,receipt)
        value.update(state="open", execution="reconciled", reconciliation=observation,
                     lastActivity=now().isoformat())
        write(record, value)
        return value


def finish(root, task):
    record, _, _ = paths(root, task)
    from gambit_smp.work_process import admission,check_all
    with lease(root, task),admission(root,task):
        value = json.loads(record.read_text())
        check_all(root,task)
        if value["state"] != "open":
            raise ValueError("only an open task may be closed")
        observation = transition_check(root, value)
        if value.get("execution") in {"running", "interrupted"}:
            raise ValueError("uncertain execution requires workspace resume before completion")
        value.update(state="closed", closure=observation, closedAt=now().isoformat(), lastActivity=now().isoformat())
        write(record, value)
    collect(root)
    return value


def collect_runs(root, task, *, today=None, opened=None):
    """Expire completed attempt outputs even while a campaign remains open."""
    from gambit_smp.task_dependencies import protected
    from gambit_smp.storage_retention import inspect, archive_records, remove_tree
    cutoff = (today or now().date()) - timedelta(days=1)
    results = []
    with lease(root, task):
        from gambit_smp.task_processes import check
        check(root,task)
        if pending(root):return []
        for record in bounded(root, ".state/task-runs/" + task).glob("*.json"):
            value = json.loads(record.read_text())
            if value["state"] not in {"returned","interrupted"}:continue
            if value["state"]=="interrupted" and not value.get("reconciliation"):continue
            if not value.get("endedAt") and value.get("reconciliation"):
                value["endedAt"]=value["reconciliation"]["observedAt"]
            if not value.get("endedAt"):continue
            if datetime.fromisoformat(value["endedAt"]).astimezone(ZONE).date() >= cutoff:
                continue
            output = bounded(root, paths(root, task)[1].relative_to(Path(root).resolve()) / "runs" / value["run"])
            if not output.exists():
                if value.get("cleanup", {}).get("state") == "removing":
                    value["cleanup"]["state"] = "removed"
                    write(record, value)
                continue
            if protected(root, output):
                continue
            opened = active_paths() if opened is None else opened
            if referenced(output, opened) or inspect(output, cutoff)["blocked"]:
                continue
            if value.get("pgid") and value.get("custodyProtocol",0)<3:
                try:
                    os.killpg(value["pgid"], 0)
                except ProcessLookupError:
                    pass
                else:
                    continue
            st = output.stat()
            identity = [st.st_dev, st.st_ino]
            old = value.get("cleanup", {})
            if old.get("state") == "removing" and old["identity"] != identity:
                raise ValueError("run output replaced during interrupted cleanup")
            records = old.get("archivedRecords", []) + archive_records(root, output)
            value["cleanup"] = dict(state="removing", identity=identity, archivedRecords=records)
            write(record, value)
            remove_tree(output)
            value["cleanup"]["state"] = "removed"
            write(record, value)
            results.append(value["run"])
        owner=json.loads(paths(root,task)[0].read_text())
        if owner.get('execution') not in {'running','interrupted'}:
            collect_builds(root,paths(root,task)[1],cutoff,opened)
    return results


def collect(root):
    """Startup/finalization hook; busy or unverifiable cleanup remains deferred."""
    directory = bounded(root, ".state/tasks")
    if not directory.exists():
        return []
    results = []
    opened = None
    cutoff = now().date() - timedelta(days=1)
    for record in sorted(directory.glob("*.json")):
        value = json.loads(record.read_text())
        try:
            from gambit_smp.task_retention import collect as collect_dependencies
            collect_dependencies(root,value["task"])
            collect_runs(root, value["task"])
            from gambit_smp.work_process import collect as collect_process
            for process_record in bounded(root,'.state/work-processes/'+value['task']).glob('*.json'):
                process=json.loads(process_record.read_text())['process']
                collect_process(root,value['task'],process)
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            results.append(dict(task=value["task"], runsRemoved=False, deferred=type(error).__name__))
        if (value["state"] != "closed" or
                datetime.fromisoformat(value["lastActivity"]).astimezone(ZONE).date() >= cutoff):
            continue
        try:
            if opened is None:
                opened = active_paths()
            results.append(reclaim(root, value["task"], opened=opened))
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            results.append(dict(task=value["task"], removed=False, deferred=type(error).__name__))
    if results:
        write(bounded(root, ".state/storage/task-retention.json"), dict(at=now().isoformat(), results=results))
    return results


def task_output(root, path):
    """Route new runtime outputs in a managed command to its stable task store."""
    task = os.environ.get("GAMBIT_SMP_TASK_ID")
    if not task:
        from gambit_smp.task_dependencies import default_task
        task = default_task(root)
        if task:
            control = Path(root).resolve(strict=True)
        else:
            return path
    else:
        control = Path(os.environ["GAMBIT_SMP_TASK_ROOT"]).resolve(strict=True)
    record, cache, _ = paths(control, task)
    if os.environ.get("GAMBIT_SMP_TASK_PROCESS"):
        from gambit_smp.work_process import paths as process_paths
        cache=process_paths(control,task,os.environ["GAMBIT_SMP_TASK_PROCESS"])[1]
    value = json.loads(record.read_text())
    if value["state"] != "open" or not any(os.path.samefile(root, owner) for owner in (control, Path(value["checkout"]))):
        raise ValueError("task context does not own this checkout")
    path = Path(path)
    declared = path if path.is_absolute() else Path(root) / path
    if declared.is_relative_to(cache):
        return bounded(control, declared.relative_to(control))
    local = Path(root) / ".cache"
    if declared.is_relative_to(local):
        relative = declared.relative_to(local)
        if relative.parts[:1] == ("tasks",):
            raise ValueError("output belongs to another task")
        run = os.environ.get("GAMBIT_SMP_TASK_RUN")
        store = cache / "runs" / identifier(run) if run else cache
        return bounded(control, store.relative_to(control) / "outputs" / relative)
    raise ValueError("runtime output requires its managed task cache")



def owned_build_reference(root, path, product):
    """Reference one registered same-work-item build without rerouting outputs.

    This grants neither writes nor quiescence. The consumer still acquires the
    existing exclusive workspace lease and authenticates every producer byte.
    """
    root=Path(root).resolve(strict=True);path=Path(path)
    task=os.environ.get('GAMBIT_SMP_TASK_ID')
    if not task:return task_output(root,path)
    control=Path(os.environ['GAMBIT_SMP_TASK_ROOT']).resolve(strict=True)
    _,cache,_=paths(control,task)
    role=os.environ.get('GAMBIT_SMP_TASK_PROCESS')
    own=cache
    if role:
        from gambit_smp.work_process import paths as process_paths
        own=process_paths(control,task,role)[1]
    task_output(root,own)  # Existing checkout/open-owner validation.
    candidate=bounded(control,path.relative_to(control))
    if candidate.is_relative_to(own):return task_output(root,candidate)
    if inherited_lease(root,task) is None:
        raise ValueError('shared build reference requires real current custody')
    owner=json.loads(context_owner(root,task).read_text())
    run=os.environ.get('GAMBIT_SMP_TASK_RUN')
    receipt=json.loads(context_run(root,task,run or '').read_text())
    if owner.get('run')!=run or owner.get('state')!='open' or receipt.get('state')!='running':
        raise ValueError('shared build reference requires current running custody')
    from gambit_smp.work_items import admit
    item=admit(control,task,role)
    if item.get('buildProducts',{}).get(product,{}).get('owner')!='task-or-registered-process':
        raise ValueError('shared build product is not registered for this work item')
    parts=candidate.relative_to(cache).parts
    if len(parts)==4 and parts[0]=='build':
        tail=parts
    elif len(parts)==6 and parts[0]=='processes' and parts[2]=='build':
        admit(control,task,identifier(parts[1]))
        tail=parts[2:]
    else:raise ValueError('cross-role reference must be a registered build source')
    key=tail[2]
    if tail[1]!=product or tail[3]!='source' or len(key)!=64 or any(c not in '0123456789abcdef' for c in key):
        raise ValueError('cross-role reference identifies another build product')
    declaration=candidate.parent/'configuration.json'
    if candidate.resolve()!=candidate or declaration.is_symlink():
        raise ValueError('shared build reference cannot be an alias')
    configuration=json.loads(declaration.read_text())
    if not isinstance(configuration,dict) or set(configuration)!={'compiler','compilerSha256','flags','environment'}:
        raise ValueError('shared build configuration schema differs')
    actual=hashlib.sha256(json.dumps(configuration,sort_keys=True).encode()).hexdigest()
    if actual!=key:raise ValueError('shared build configuration identity changed')
    compiler=Path(configuration['compiler'])
    if not compiler.is_file() or hashlib.sha256(compiler.read_bytes()).hexdigest()!=configuration['compilerSha256']:
        raise ValueError('shared build compiler identity changed')
    return candidate


def build_output(root, name, *, compiler, flags=()):
    """Stable native build work area; attempts/logs still use task_output.

    Build tools own dependency invalidation. Reusing this directory never
    admits old results and must not skip make or source/toolchain checks.
    """
    root=Path(root).resolve(strict=True);name=identifier(name)
    task=os.environ.get('GAMBIT_SMP_TASK_ID')
    if not task or inherited_lease(root,task) is None:
        raise ValueError('build workspace requires real current task/process custody')
    from gambit_smp.work_items import admit
    products = admit(root, task, os.environ.get('GAMBIT_SMP_TASK_PROCESS')).get('buildProducts')
    if products is not None and name not in products:
        raise ValueError('build product is not registered for this work item')
    owner=json.loads(context_owner(root,task).read_text());run=os.environ.get('GAMBIT_SMP_TASK_RUN')
    receipt=json.loads(context_run(root,task,run or '').read_text())
    if owner.get('run')!=run or owner.get('state')!='open' or receipt.get('state')!='running':
        raise ValueError('build workspace requires current running custody')
    # Reuse routing/checkout validation, but keep build objects outside run IDs.
    _,cache,_=paths(root,task)
    process=os.environ.get('GAMBIT_SMP_TASK_PROCESS')
    if process:
        from gambit_smp.work_process import paths as process_paths
        cache=process_paths(root,task,process)[1]
    compiler=Path(compiler).resolve(strict=True)
    if not compiler.is_file() or not os.access(compiler,os.X_OK):raise ValueError('executable compiler required')
    if not isinstance(flags,(list,tuple)) or any(type(flag) is not str for flag in flags):raise ValueError('literal build flags required')
    configuration=dict(compiler=str(compiler),compilerSha256=hashlib.sha256(compiler.read_bytes()).hexdigest(),flags=list(flags),
        environment={key:os.environ.get(key) for key in ('CC','CFLAGS','CPPFLAGS','LDFLAGS','LIBRARY_PATH','CPATH','SDKROOT','MACOSX_DEPLOYMENT_TARGET')})
    key=hashlib.sha256(json.dumps(configuration,sort_keys=True).encode()).hexdigest()
    target=task_output(root,cache/'build'/name/key)
    target.mkdir(parents=True,exist_ok=True)
    declaration=target/'configuration.json'
    if declaration.exists():
        if json.loads(declaration.read_text())!=configuration:raise ValueError('build configuration custody changed')
    else:write(declaration,configuration)
    # Retention measures actual owner use, not success or evidence freshness.
    os.utime(target,None)
    return target


def build_source_links(root, build, state):
    """Only declared pending inputs or registered generated aliases may be broken."""
    if state.get('phase') == 'updating':
        links={name:row['link'] for name,row in state.get('pending',{}).items()
               if isinstance(row,dict) and 'link' in row}
        from gambit_smp.work_items import build_recovery_links
        registered=build_recovery_links(root,Path(build).parent.name)
        for name,target in state.get('retiredGeneratedLinks',{}).items():
            if registered.get(name)!=target:raise ValueError('generated alias recovery policy changed')
            links[name]=target
        return links
    if state.get('phase') == 'building':
        from gambit_smp.work_items import build_recovery_links
        return build_recovery_links(root,Path(build).parent.name)
    return {}


def sync_build_source(root, build, staged, *, mutable=(), inventory=None, overlay_files=(), consume_staged=False,
                      initial_transfer=None):
    """Apply source deltas under the caller's existing exclusive workspace lease.

    Input and generated bytes are distinct. A killed update can contain either
    side of its recorded transition, but arbitrary source drift is never fixed
    by overwriting it. Every subsequent native build still runs its real tool.
    """
    from gambit_smp.recipes import tree_identity
    import shutil
    root, build, staged = Path(root).resolve(), Path(build), Path(staged)
    task = os.environ.get('GAMBIT_SMP_TASK_ID')
    if not task or inherited_lease(root, task) is None:
        raise ValueError('incremental source update requires real task custody')
    # Validate the same owner routing as build_output, including process areas.
    if task_output(root, build) != build or 'build' not in build.relative_to(root).parts:
        raise ValueError('incremental source requires an owned build area')
    source, state_path = build / 'source', build / 'source-state.json'
    staged_inventory = tree_identity(staged)
    incoming = staged_inventory if inventory is None else inventory
    if any(incoming.get(name) != entry for name, entry in staged_inventory.items()):
        raise ValueError('source delta differs from its complete input inventory')
    previous = json.loads(state_path.read_text()) if state_path.exists() else {}
    if previous:
        if (previous.get('schema') != 'incremental-source-state.v1'
                or previous.get('phase') not in {'ready', 'building', 'updating'}):
            raise ValueError('unknown incremental source state')
        receipt = bounded(root, previous['custody'])
        owner = json.loads(receipt.read_text())
        if owner.get('run') != previous['run'] or owner.get('task') != task:
            raise ValueError('incremental build custody changed')
        if previous['run'] != os.environ['GAMBIT_SMP_TASK_RUN']:
            if owner.get('state') not in {'returned', 'interrupted'} or (
                    owner['state'] == 'interrupted' and not owner.get('reconciliation')):
                raise ValueError('interrupted build requires real owner reconciliation')
            from gambit_smp.task_processes import check
            check(root, task, process=owner.get('process'), run=previous['run'])
    source.mkdir(exist_ok=True)
    pending = previous.get('pending', {})
    links = build_source_links(root,build,previous)
    actual = tree_identity(source, broken_links=links or None)
    retired_links = (dict(previous.get('retiredGeneratedLinks',{})) if previous.get('phase') == 'updating' else
                     {name:row['link'] for name,row in actual.items()
                      if row.get('unresolved') and previous.get('phase') == 'building'})
    actual = {name:{key:value for key,value in row.items() if key != 'unresolved'}
              for name,row in actual.items()}
    old = previous.get('inputs', {})
    if any(name in old or name in incoming for name in retired_links):
        raise ValueError('generated-link recovery cannot remove a source input')
    from gambit_smp.source_capabilities import source_name
    for name in set(old) | set(incoming):source_name(name)
    observed = previous.get('observed', old)
    mutables = set(previous.get('mutable', ()))
    if not old and any(entry not in (incoming.get(name), pending.get(name)) for name, entry in actual.items()):
        raise ValueError('initial build source contains unowned bytes')
    for name, entry in old.items():
        if entry.get('directory'):
            if actual.get(name) != entry:
                raise ValueError('incremental source directory drift: ' + name)
            continue
        allowed = [observed.get(name), entry]
        if name in pending:
            allowed.append(pending[name])
        if actual.get(name) not in allowed:
            if not (previous.get('phase') == 'building' and name in mutables):
                raise ValueError('incremental source drift: ' + name)
    changed = [name for name, entry in incoming.items() if old.get(name) != entry]
    if initial_transfer is not None and old:
        raise ValueError('bulk transfer is restricted to a verified initial import')
    removed = [name for name in old if name not in incoming and not old[name].get('directory')]
    for name in changed:
        if (name not in old and name in actual and actual[name] != incoming[name]
                and actual[name] != pending.get(name)):
            raise ValueError('new source collides with an existing generated output: ' + name)
    state = dict(schema='incremental-source-state.v1', inputs=old,
        pending={name: incoming.get(name) for name in set(changed) | set(removed)},
        mutable=sorted(mutable), observed=observed, phase='updating',
        run=os.environ['GAMBIT_SMP_TASK_RUN'],
        overlayFiles=previous.get('overlayFiles', []), pendingOverlayFiles=list(overlay_files),
        custody=str(context_run(root, task, os.environ['GAMBIT_SMP_TASK_RUN']).relative_to(root)))
    for key in ('regeneration', 'additionalFixtures'):
        if key in previous:state[key] = previous[key]
    if retired_links:state['retiredGeneratedLinks']=retired_links
    # Commit the complete delta before changing its first file.
    write(state_path, state)
    for name,target in retired_links.items():
        alias=source/name
        if not alias.is_symlink() and not alias.exists():continue
        if not alias.is_symlink() or os.readlink(alias)!=target or alias.exists():
            raise ValueError('registered generated alias changed during recovery')
        alias.unlink()
    if initial_transfer is not None:
        initial_transfer()
        if tree_identity(source) != incoming:
            raise ValueError('initial imported tree differs from its complete input inventory')
    # A verified, unpublished cold materialization can move into the empty
    # leased root without copying every byte twice. Never move authored inputs.
    consume = (consume_staged and not old and not actual
               and not any('link' in entry for entry in incoming.values()))
    if consume:
        if not staged.is_relative_to(root / '.cache/tasks' / task) or task_output(root, staged) != staged:
            raise ValueError('only owned ephemeral materialization may be consumed')
        for child in staged.iterdir():
            child.rename(source / child.name)
    for name in removed:
        (source / name).unlink(missing_ok=True)
    for name in sorted(changed, key=lambda name: (len(Path(name).parts), name)):
        if consume or initial_transfer is not None:continue
        entry, target, origin = incoming[name], source / name, staged / name
        if entry.get('directory'):
            target.mkdir(parents=True, exist_ok=True)
        elif 'link' in entry:
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists() or target.is_symlink():
                target.unlink()
            target.symlink_to(entry['link'])
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            # copyfile, not copy2: changed bytes must invalidate make timestamps.
            if target.is_symlink():
                target.unlink()
            shutil.copyfile(origin, target)
            target.chmod(entry['mode'])
            os.utime(target, None)
    state.update(inputs=incoming, pending={}, phase='building', overlayFiles=list(overlay_files), pendingOverlayFiles=[], observed={
        name: entry for name, entry in tree_identity(source).items() if name in incoming})
    write(state_path, state)
    return dict(changed=changed, removed=removed, source=str(source),
                retiredGeneratedLinks=retired_links,
                interruptedPhase=previous.get('phase') if previous.get('phase') in {'building', 'updating'} else None)


def checkpoint_build_source(source, **observations):
    """Retain actual post-command source bytes; no success is inferred from state."""
    from gambit_smp.recipes import tree_identity
    source = Path(source)
    state_path = source.parent / 'source-state.json'
    if not state_path.is_file():
        return
    state = json.loads(state_path.read_text())
    current = tree_identity(source)
    state['observed'] = {name: entry for name, entry in current.items() if name in state['inputs']}
    state.update(observations)
    write(state_path, state)


def collect_builds(root, cache, cutoff, opened=None):
    """Called only under the owning task/process lease after child checks."""
    from gambit_smp.storage_retention import inspect,archive_records,remove_tree
    from gambit_smp.task_retention import inventory,unchanged_remainder
    from gambit_smp.task_dependencies import protected
    removed=[]
    for target in (cache/'build').glob('*/*'):
        if protected(root,target):continue
        receipt=bounded(root,'.state/storage/build-expiry/'+hashlib.sha256(str(target).encode()).hexdigest()+'.json')
        previous=json.loads(receipt.read_text()) if receipt.exists() else {}
        continuing=previous.get('state')=='removing'
        if not continuing and datetime.fromtimestamp(target.stat().st_mtime,ZONE).date()>=cutoff:continue
        occupied=active_paths() if opened is None else opened
        if referenced(target,occupied) or inspect(target,cutoff,deleting=continuing)['blocked']:continue
        st=target.stat();identity=[st.st_dev,st.st_ino]
        if continuing:
            if previous['identity']!=identity:raise ValueError('build cache replaced during cleanup')
            unchanged_remainder(target,previous['inventory'])
        records=(previous.get('archivedRecords',[]) if continuing else [])+archive_records(root,target)
        value=dict(path=str(target),identity=identity,inventory=previous['inventory'] if continuing else inventory(target),
                   archivedRecords=records,nativeAdmitted=False,state='removing')
        write(receipt,value);remove_tree(target)
        value['state']='removed';write(receipt,value);removed.append(str(target))
    return removed


def active_paths():
    """Open files, mappings and working directories; failure defers reclamation."""
    from gambit_smp.task_processes import run
    result = run(["lsof", "-n", "-P", "-Fpn"], capture_output=True, text=True, timeout=30)
    if result.returncode != 0 or result.stderr:
        raise ValueError("process inventory unavailable; cleanup deferred")
    return [Path(line[1:]) for line in result.stdout.splitlines() if line.startswith("n/")]


def referenced(path, opened):
    """Conservatively match APFS case aliases, including now-closed file names."""
    prefix = str(path).casefold()
    return any(str(item).casefold() == prefix or str(item).casefold().startswith(prefix + os.sep)
               for item in opened)


def reclaim(root, task, *, today=None, opened=None):
    """Only closed, expired, unoccupied artifacts; source worktrees survive."""
    root = Path(root).resolve(strict=True)
    record, cache, _ = paths(root, task)
    with lease(root, task):
        value = json.loads(record.read_text())
        cutoff = (today or now().date()) - timedelta(days=1)
        expired = datetime.fromisoformat(value["lastActivity"]).astimezone(ZONE).date() < cutoff
        if value["state"] != "closed" or not expired or not cache.exists():
            return dict(task=task, removed=False, reason="open, recent, or absent")
        from gambit_smp.task_processes import check
        check(root,task,all_processes=True)
        from gambit_smp.work_process import check_all
        check_all(root,task)
        if pending(root):return dict(task=task,removed=False,reason="pending requests")
        opened = active_paths() if opened is None else opened
        if referenced(cache, opened):
            return dict(task=task, removed=False, reason="process reference")
        from gambit_smp.task_dependencies import protected
        if protected(root, cache):
            return dict(task=task, removed=False, reason="pinned dependency")
        # Recursively reject operational state and nested repositories. Historical
        # receipts belong in evidence/, not in the expiring artifact store.
        def unreadable(error):
            raise error
        for directory, dirs, files in os.walk(cache, followlinks=False, onerror=unreadable):
            if ".git" in dirs or ".git" in files or any(
                    name.endswith((".sqlite", ".sqlite3", ".db", ".sqlite-wal", ".sqlite-shm",
                                   ".sqlite3-wal", ".sqlite3-shm", ".db-wal", ".db-shm", ".quarantine.json")) for name in files):
                raise ValueError("source or operational database in task cache; migration required")
        from gambit_smp.storage_retention import archive_records, remove_tree
        previous = value.get("cleanup", {})
        st = cache.lstat()
        if previous.get("state") == "removing" and previous.get("identity") != [st.st_dev, st.st_ino]:
            raise ValueError("task cache replaced during interrupted cleanup")
        archived = {(row["source"], row["sha256"]): row for row in previous.get("archivedRecords", [])}
        archived.update({(row["source"], row["sha256"]): row for row in archive_records(root, cache)})
        value["cleanup"] = dict(state="removing", at=now().isoformat(), path=str(cache),
                                identity=[st.st_dev, st.st_ino], archivedRecords=list(archived.values()))
        write(record, value)
        remove_tree(cache)
        value["cleanup"]["state"] = "removed"
        write(record, value)
        return dict(task=task, removed=True)


def remove_worktree(root, task, *, base):
    """Git-flow gate: closed, clean, merged into explicit base, unoccupied."""
    record, _, tree = paths(root, task)
    with lease(root, task):
        value = json.loads(record.read_text())
        if value["state"] != "closed" or not value["ownedWorktree"] or value["checkout"] != str(tree):
            raise ValueError("closed owned worktree required")
        from gambit_smp.work_process import check_all
        check_all(root,task)
        if git(tree, "status", "--porcelain", "--untracked-files=all"):
            raise ValueError("dirty worktree must be saved first")
        integration = git(root, "rev-parse", "--verify", "--end-of-options", base + "^{commit}")
        git(tree, "merge-base", "--is-ancestor", "HEAD", integration)
        if referenced(tree, active_paths()):
            raise ValueError("worktree is occupied")
        git(root, "worktree", "remove", str(tree))
        value["worktreeRemovedAt"] = now().isoformat()
        write(record, value)
        return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(os.environ.get("GAMBIT_SMP_ROOT", Path.cwd())))
    commands = parser.add_subparsers(dest="operation", required=True)
    for name in ("absorb-process", "process-run", "process-resume", "process-gc", "start", "run", "resume", "finish", "gc", "remove-worktree", "adopt-paths", "release-paths", "migrate-script", "run-script", "scripts", "normalize"):
        sub = commands.add_parser(name)
        sub.add_argument("task")
        if name=='absorb-process':
            sub.add_argument('process');sub.add_argument('--from-task',required=True)
        if name.startswith('process-'):
            sub.add_argument('process')
            if name=='process-resume':
                sub.add_argument('--discard-metadata-read',metavar='TOKEN',help='forensically discard one exact unbound legacy Git read; never replay it')
                sub.add_argument('--argv-file',help='managed, root-relative JSON argv used for hash reconstruction')
            if name=='process-run':
                sub.add_argument('--wall-seconds',type=float,default=1800)
                sub.add_argument('--provider',choices=('codex','grok'),default='codex')
                sub.add_argument('argv',nargs=argparse.REMAINDER)
        if name == "normalize":
            sub.add_argument("--recovery", action="append", required=True)
        if name == "start":
            location = sub.add_mutually_exclusive_group()
            location.add_argument("--ref", help="create .data/worktrees/TASK from this Git ref")
            location.add_argument("--adopt", action="store_true", help="explicitly adopt the current checkout")
        if name in {"run", "run-script"}:
            sub.add_argument("--wall-seconds", type=float, default=1800)
            sub.add_argument("--provider", choices=("codex", "grok"), default="codex")
            if name == "run":
                sub.add_argument("argv", nargs=argparse.REMAINDER)
            else:
                sub.add_argument("key")
        if name in {"adopt-paths", "release-paths"}:
            sub.add_argument("--default", action="store_true")
            sub.add_argument("paths", nargs="+")
        if name == "migrate-script":
            sub.add_argument("--resume", action="store_true")
            sub.add_argument("script")
            sub.add_argument("--enable", action="store_true", help="enable reviewed campaign source; default disabled")
        if name == "remove-worktree":
            sub.add_argument("--merged-into", required=True)
    args = parser.parse_args()
    if args.operation=='absorb-process':
        from gambit_smp.work_process import absorb
        print(json.dumps(absorb(args.root,args.task,args.process,args.from_task),indent=2));return 0
    if args.operation.startswith('process-'):
        from gambit_smp import work_process
        if args.operation=='process-run':
            command=args.argv[1:] if args.argv[:1]==['--'] else args.argv
            with work_process.scope(args.root,args.task,args.process,args.provider):
                return execute(args.root,args.task,command,provider=args.provider,wall_seconds=args.wall_seconds)
        if args.operation=='process-resume':
            discard=None
            if bool(args.discard_metadata_read)!=bool(args.argv_file):parser.error('--discard-metadata-read and --argv-file must be supplied together')
            if args.argv_file:
                identifier(args.discard_metadata_read)
                argv=json.loads(bounded(args.root,args.argv_file).read_text())
                discard=(args.discard_metadata_read,argv)
            result=work_process.resume(args.root,args.task,args.process,discard_metadata_read=discard)
        else:result=work_process.collect(args.root,args.task,args.process)
        print(json.dumps(result,indent=2));return 0
    if args.operation == "scripts":
        rows=[json.loads(record.read_text()) for record in bounded(args.root,".state/task-scripts/"+identifier(args.task)).glob("*.json")]
        print(json.dumps([{key:row[key] for key in ("key","path","enabled","state","sha256")} for row in rows],indent=2))
        return 0
    if args.operation == "gc":
        from gambit_smp.task_retention import collect as collect_dependencies
        collect_dependencies(args.root,args.task)
        collect_runs(args.root, args.task)
    if args.operation == "run-script":
        return run_script(args.root, args.task, args.key, provider=args.provider, wall_seconds=args.wall_seconds)
    if args.operation == "run":
        command = args.argv[1:] if args.argv[:1] == ["--"] else args.argv
        return execute(args.root, args.task, command, provider=args.provider, wall_seconds=args.wall_seconds)
    if args.operation == "normalize":
        from gambit_smp.task_migration import normalize_programs
        from gambit_smp.task_retention import classify
        normalize_programs(args.root,args.task)
        value = classify(args.root,args.task,recovery=args.recovery)
    elif args.operation == "adopt-paths":
        from gambit_smp.task_dependencies import adopt
        value = adopt(args.root, args.task, args.paths, default=args.default)
    elif args.operation == "release-paths":
        from gambit_smp.task_dependencies import release
        value = release(args.root, args.task, args.paths)
    elif args.operation == "migrate-script":
        from gambit_smp.task_migration import migrate
        value = migrate(args.root, args.task, args.script, enabled=args.enable, resume=args.resume)
    elif args.operation == "start":
        value = start(args.root, args.task, ref=args.ref, adopt=args.adopt)
    elif args.operation == "resume":
        value = resume(args.root, args.task)
    elif args.operation == "finish":
        value = finish(args.root, args.task)
    elif args.operation == "remove-worktree":
        value = remove_worktree(args.root, args.task, base=args.merged_into)
    else:
        value = reclaim(args.root, args.task)
    print(json.dumps(value, indent=2))
    return 0


def require_execution(root, task, script):
    """New campaign scripts require a current held lease and their own source seal."""
    from gambit_smp.task_dependencies import dependencies
    root=Path(root).resolve(strict=True)
    script=Path(script).resolve(strict=True)
    if not script.is_relative_to(paths(root,task)[1]/'programs'):
        raise ValueError('task program must use its canonical program directory')
    matches=[]
    for record in bounded(root,'.state/task-scripts/'+identifier(task)).glob('*.json'):
        row=json.loads(record.read_text())
        if row['path']==str(script):matches.append(row)
    if len(matches)!=1 or matches[0]['state']!='migrated':
        raise ValueError('script is not admitted to the task source registry')
    entry=matches[0]
    if entry.get('processMigration',{}).get('state')=='prepared':
        raise ValueError('program birth/exec source migration requires completion')
    if not entry['enabled']:
        raise ValueError('campaign script disabled; migration grants no execution authority')
    if hashlib.sha256(script.read_bytes()).hexdigest()!=entry['sha256']:
        raise ValueError('campaign script source changed; review and seal explicitly')
    from gambit_smp.task_migration import rewrite_process_calls
    if rewrite_process_calls(script.read_bytes())[1]:
        raise ValueError('program needs direct birth/exec source migration; use workspace run-script')
    if os.environ.get('GAMBIT_SMP_TASK_ID')!=task or inherited_lease(root,task) is None:
        raise ValueError('launch with workspace run-script; real task execution custody required')
    run_id=identifier(os.environ.get('GAMBIT_SMP_TASK_RUN',''))
    receipt=json.loads(bounded(root,'.state/task-runs/'+task+'/'+run_id+'.json').read_text())
    task_record=json.loads(paths(root,task)[0].read_text())
    if receipt['state']!='running' or task_record.get('run')!=run_id or task_record['state']!='open':
        raise ValueError('task execution is not current')
    write(bounded(root,'.state/task-script-runs/'+task+'/'+run_id+'/'+entry['key']+'.json'),
          dict(script=str(script),sha256=entry['sha256'],at=now().isoformat(),nativeAdmitted=False))
    from gambit_smp.storage_policy import activate
    activate(root,task)
    return entry


def run_script(root,task,key,*,provider='codex',wall_seconds=1800):
    from gambit_smp.task_migration import script_record,rewrite_process_calls,upgrade_process_calls
    entry=json.loads(script_record(root,task,key).read_text())
    if entry['state']!='migrated' or not entry['enabled']:
        raise ValueError('campaign script disabled or incomplete')
    script=Path(entry['path'])
    if not script.is_relative_to(paths(root,task)[1]/'programs'):
        raise ValueError('task program is outside canonical storage')
    prepared=entry.get('processMigration',{}).get('state')=='prepared'
    if not prepared and hashlib.sha256(script.read_bytes()).hexdigest()!=entry['sha256']:
        raise ValueError('campaign script source changed')
    with execution_scope(root,task,provider=provider):
        if prepared or rewrite_process_calls(script.read_bytes())[1]:
            upgrade_process_calls(root,task)
        return execute(root,task,[sys.executable,str(script)],provider=provider,wall_seconds=wall_seconds)


if __name__ == "__main__":
    raise SystemExit(main())
