"""A closed research lane: sealed implementation, typed artifacts, native rules.

The seal is a reproducibility boundary, not a sandbox against a malicious host.
Research data cannot install handlers or select an executable implementation.
"""
import argparse
import ast
import hashlib
import importlib.util
import json
import os
import re
from pathlib import Path
import shutil
import stat
import sys
import time
import uuid
from functools import lru_cache

from gambit_smp.framework import ROOT, digest, execute, relative
from gambit_smp.family6_recipes import (
    rest_campaign_recipe, rest_check_recipe, rest_execution_summary,
)


SCHEMA = "evidence-recipe.v2"
ENGINE_SCHEMA = "research-engine-seal.v2"
PROCESS_PROTOCOL = 'child-birth-exec-and-audited-python.v2'
PROCESS_IMPLEMENTATION = ('__init__','spawn_protocol','task_processes','storage_policy','workspace','framework','process_observation','grok_session')


def process_transport_identity():
    package=Path(__file__).resolve().parent
    return {'python/gambit_smp/'+name+'.py':digest(package/(name+'.py')) for name in PROCESS_IMPLEMENTATION}
GENERATION = re.compile(r"\.o[1-9][0-9]*")
ALLOWED = frozenset({"sysml.project", "sysml.structure", "architecture.preflight", "architecture.views", "source.contract", "research.audit", "gambit.materialize", "source.overlay", "source.project", "source.bind",
                     "native.workspace-build", "native.test", "quint.parse", "quint.typecheck", "quint.test", "quint.verify", "quint.observe", "lean.check", "c.cbmc", "c.frama-c", "c.genmc",
                     "evidence.evaluate", "gambit.configure", "gambit.object", "gambit.seed-core", "gambit.seed-checkpoint", "gambit.bootstrap-input",
                     "gambit.regenerate-module", "gambit.source-core", "gambit.bootstrap", "gambit.suite", "gambit.review",
                     "gambit.completed-runtime", "gambit.probe", "gambit.executable-test", "gambit.compiler-observation",
                     "gambit.runtime-import", "gambit.upstream-tests", 'gerbil.build', 'gerbil.test',
                     'gambit.native-development', 'gambit.generation-artifact', 'gambit.gate2-collect',
                     'gambit.observation-identity'})
FORBIDDEN_IMPORTS = frozenset({"source_unit", "ffi_source_unit", "allocator_acquire", "allocator_object",
                               "sync_retirement_source", "gc_wait_source", "gc_queue_binding"})


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode()


def content_id(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def clock_epoch():
    """Read an OS boot identity; absence never establishes clock continuity."""
    try:
        if sys.platform == "darwin":
            import ctypes
            library = ctypes.CDLL(None, use_errno=True)
            query = library.sysctlbyname
            query.argtypes = [ctypes.c_char_p, ctypes.c_void_p,
                             ctypes.POINTER(ctypes.c_size_t), ctypes.c_void_p, ctypes.c_size_t]
            query.restype = ctypes.c_int
            buffer = ctypes.create_string_buffer(128)
            length = ctypes.c_size_t(len(buffer))
            if query(b"kern.bootsessionuuid", buffer, ctypes.byref(length), None, 0) != 0:
                return None
            value = buffer.value.decode("ascii")
        elif sys.platform.startswith("linux"):
            value = Path("/proc/sys/kernel/random/boot_id").read_text().strip()
        else:
            return None
        return str(uuid.UUID(value))
    except (OSError, ValueError, UnicodeError, AttributeError):
        return None


def retain_run_record(root, path, scope, payload, inputs):
    """Commit immutable transport evidence, not a published analysis or PASS."""
    pending = path.with_name(path.name + ".pending-" + uuid.uuid4().hex)
    try:
        if path.exists() or path.is_symlink():
            raise FileExistsError(path)
        with pending.open("x") as stream:
            json.dump(payload, stream, sort_keys=True, indent=2, allow_nan=False)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        reference = retain_record_observation(root, path, scope, payload, inputs, record_sha=digest(pending))
        os.link(pending, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
        return reference
    finally:
        pending.unlink(missing_ok=True)


def retain_record_observation(root, path, scope, payload, inputs, *, record_sha=None):
    from gambit_smp.reasoning_history import append_observation, CheckpointConflict
    header = payload.get("header")
    run = Path(header["path"]).parent if header else path.parent
    checkpoint = ({"run": str(run.resolve()), "runId": payload["runId"], "path": str(path.resolve()),
                   "scope": scope}
                  if payload.get("runId") else None)
    record_sha = digest(path) if record_sha is None else record_sha
    backend = {"name": "reported-process", "inputs": {}, "recordSha256": record_sha}
    try:
        identity = append_observation(root, scope, inputs, {"run_record": [payload]}, backend, checkpoint=checkpoint)
    except CheckpointConflict:
        append_observation(root, scope, inputs, {"run_record": [payload]},
                           dict(backend, publicationRejected=True))
        raise
    return {"path": str(path), "sha256": record_sha, "observation": identity, "scope": scope}


def process_recorder(root, run, journal, *, owner_path=None, deadline=None):
    """Record process births, including incomplete births, before exposing results."""
    from gambit_smp.reasoning_history import CheckpointConflict, CheckpointClosed
    def record(event, token, fields):
        header = json.loads(Path(journal["path"]).read_text())
        payload = {"schema": "research-process-observation.v1", "runId": header["runId"],
                   "header": journal, "event": event, "token": token,
                   "clockEpoch": clock_epoch(), **fields}
        suffix = event
        if event == "progress":
            if type(fields.get("count")) is not int or fields["count"] <= 0:
                raise ValueError("positive progress observation sequence required")
            suffix += "-" + str(fields["count"])
        if event == "resource-sample":
            sequence=fields.get('resourceSampleSequence')
            if type(sequence) is not int or sequence<=0:
                raise ValueError('positive resource observation sequence required')
            suffix += '-' + str(sequence)
        target = (owner_path if event == "started" and owner_path is not None else
                  run / ("process-" + token + "-" + suffix + ".json"))
        while True:
            try:
                return retain_run_record(root, target, journal["scope"], payload, header["inputs"])
            except CheckpointClosed:
                raise
            except CheckpointConflict:
                if deadline is None or time.monotonic() >= deadline:
                    raise
    record.root=Path(root).resolve()
    record.spawn_root=Path(run).resolve()/'process-starts'
    return record


def retain_terminal_run(root, out, receipt):
    """Bind completed parent/child receipts into the same durable observation store."""
    from gambit_smp.reasoning_history import read_execution_checkpoint
    state = read_execution_checkpoint(root, out)
    if not state["records"]:
        return
    if state["records"][-1]["payload"].get("schema") == "research-terminal-observation.v1":
        return
    header = state["records"][0]["payload"]
    child_path = out / "run/receipt.json"
    child = json.loads(child_path.read_text()) if child_path.is_file() else None
    if receipt.get("childReceiptSha256") is not None and (
            child is None or digest(child_path) != receipt["childReceiptSha256"]):
        raise ValueError("terminal checkpoint child receipt changed")
    payload = {"schema": "research-terminal-observation.v1", "runId": header["runId"],
               "header": {"path": str(out / "run-header.json")}, "outer": receipt, "child": child}
    retain_record_observation(root, out / "receipt.json", state["records"][0]["scope"], payload, header["inputs"])


def retain_existing_run(root, out):
    """Index only records already authenticated by the existing immutable journal."""
    from gambit_smp.reasoning_history import read_execution_checkpoint, read_journal, normalized
    if not (out / "run-header.json").is_file():
        return
    header = json.loads((out / "run-header.json").read_text())
    paths = [out / "run-header.json", *sorted((out / "run").glob("*.observation.json"))]
    scope = next((json.loads(path.read_text())["header"]["scope"] for path in paths[1:]),
                 "research:" + header["recipe"])
    observations = read_journal(root, scope)["observations"]
    known = {row["path"]: row for row in read_execution_checkpoint(root, out)["records"]}
    records = []
    for path in paths:
        payload = json.loads(path.read_text())
        matches = [(identity, body) for identity, body in observations.items()
                   if body.get("queries") == normalized({"run_record": [payload]})]
        if len(matches) != 1:
            raise ValueError("existing checkpoint record lacks immutable custody")
        records.append((path, payload, matches[0][1]["inputs"]))
    pending, published = records[1:], set()
    ordered = [records[0]]
    while pending:
        ready = [row for row in pending if set(row[1]["step"]["dependsOn"]) <= published]
        if not ready:
            raise ValueError("existing checkpoint dependency closure is incomplete")
        for row in ready:
            ordered.append(row)
            published.add(row[1]["step"]["id"])
            pending.remove(row)
    for path, payload, inputs in ordered:
        if str(path) in known:
            if known[str(path)]["payload"] != payload:
                raise ValueError("existing checkpoint differs from the committed prefix")
        else:
            retain_record_observation(root, path, scope, payload, inputs)
    if (out / "receipt.json").is_file():
        retain_terminal_run(root, out, json.loads((out / "receipt.json").read_text()))


@lru_cache(maxsize=256)
def _static_dependencies(source):
    """Parse exact bytes only; file availability and policy are never cached."""
    from gambit_smp import _PUBLIC_MODULES
    dependencies = []
    for node in ast.walk(ast.parse(source)):
        if isinstance(node, ast.ImportFrom) and node.module == "gambit_smp":
            dependencies.extend('__init__' if alias.name=='_PUBLIC_MODULES' else
                                _PUBLIC_MODULES.get(alias.name,alias.name) for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module and node.module.startswith("gambit_smp."):
            dependencies.append(node.module.removeprefix("gambit_smp.").replace(".", "/"))
        elif isinstance(node, ast.Import):
            dependencies.extend(alias.name.removeprefix("gambit_smp.").replace(".", "/") for alias in node.names
                                if alias.name.startswith("gambit_smp."))
    return tuple(dependencies)


def implementation_paths(package):
    """Seal the static implementation closure, not unrelated experiment runners."""
    pending = ["__init__", "research_kernel", "recipes", "native_capabilities", "source_capabilities",
               "evidence_capabilities", "process_observation", "ascent_program", "validation_domains"]
    used = set()
    parents = {}
    while pending:
        name = pending.pop()
        if name in used:
            continue
        if name.split("/")[0] in FORBIDDEN_IMPORTS or name == "cli":
            chain = [name]
            while chain[-1] in parents:
                chain.append(parents[chain[-1]])
            raise ValueError("historical producer reachable from the research kernel: " + " <- ".join(chain))
        path = package / (name + ".py")
        if not path.exists() and (package / name).is_dir():
            if (package / name).is_symlink():
                raise ValueError("unavailable static research implementation: " + name)
            path = package / name / "__init__.py"
        if not path.is_file() or path.is_symlink():
            raise ValueError("unavailable static research implementation: " + name)
        used.add(name)
        for child in _static_dependencies(path.read_bytes()):
            if child not in used and child not in pending:
                parents[child] = name
                pending.append(child)
    # Seal command transport bytes without treating its lazy operator registry as
    # kernel imports. A direct core import of cli still fails above.
    if 'task_entry' in used:
        transport=package/'cli.py'
        if not transport.is_file() or transport.is_symlink():
            raise ValueError('unavailable task command transport')
        used.add('cli')
    # Provider entrypoints have a lazy dispatcher registry, not kernel imports.
    # Every byte required by transport admission must nevertheless be sealed.
    for name in PROCESS_IMPLEMENTATION:
        path = package / (name + '.py')
        if not path.is_file() or path.is_symlink():
            raise ValueError('unavailable process transport implementation: ' + name)
        used.add(name)
    paths = [package / (name + ".py") if (package / (name + ".py")).is_file()
             else package / name / "__init__.py" for name in sorted(used)]
    # These source-owned Scheme resources are read by the static Python
    # closure. They must travel with it; an editable checkout is not a fallback.
    if 'gerbil_build/sources' in used:
        from gambit_smp.gerbil_build.sources import source_files
        for path in source_files(package):
            if path.suffix == '.py':
                continue
            if not path.is_file() or path.is_symlink():
                raise ValueError('unavailable static research resource: ' + path.name)
            paths.append(path)
    if 'compiler_trace' in used:
        for name in ('compiler_observer.scm', 'compiler_work.scm'):
            observer = package / name
            if not observer.is_file() or observer.is_symlink():
                raise ValueError('unavailable native compiler observer resource')
            paths.append(observer)
    return paths


def supervised_interruption(root, prior):
    """Bind reconciled supervisor interruption; never mint a child outcome.

    The attempt location chooses the existing supervisor record. A caller may
    not supply another receipt or turn missing process evidence into failure.
    Actual birth quiescence is independently required by failed_prefix_retry.
    """
    from gambit_smp.workspace import bounded
    from gambit_smp.recipes import read_json
    from datetime import datetime
    try:parts=prior.resolve(strict=True).relative_to(root.resolve()/'.cache/tasks').parts
    except ValueError:return None
    if len(parts)!=7 or (parts[1],parts[3],parts[5])!=('processes','runs','outputs'):
        return None
    task,process,run=parts[0],parts[2],parts[4]
    path=bounded(root,f'.state/work-process-runs/{task}/{process}/{run}.json')
    if not path.is_file():return None
    checksum=digest(path)
    row=read_json(path)
    if digest(path)!=checksum:raise ValueError('resource supervisor record changed during observation')
    resource_limit=row.get('rssLimitExceeded') is True or row.get('footprintLimitExceeded') is True
    for flag,limit,peak in [('rssLimitExceeded','rssLimitBytes','peakRegisteredRssBytes'),
                            ('footprintLimitExceeded','footprintLimitBytes','peakRegisteredFootprintBytes')]:
        if row.get(flag) is True and not (type(row.get(limit)) is int and row[limit]>0
                and type(row.get(peak)) is int and row[peak]>row[limit]):
            raise ValueError('interrupted supervisor has no measured limit crossing')
    expected=bounded(root,f'.cache/tasks/{task}/processes/{process}/runs/{run}')
    if (row.get('task')!=task or row.get('process')!=process or row.get('run')!=run
            or Path(row.get('output','')).resolve()!=expected or prior.resolve().parent.parent!=expected
            or row.get('state')!='interrupted' or row.get('exit')!=-9
            or row.get('parentReaped') is not True or not isinstance(row.get('reconciliation'),dict)
            or row['reconciliation'].get('nativeAdmitted') is not False
            or not isinstance(row.get('registeredGroupCleanup'),dict)):
        raise ValueError('interrupted supervisor lacks exact reconciled supervisor custody')
    unresolved=row['registeredGroupCleanup'].get('unresolved')
    if not isinstance(unresolved,list):
        raise ValueError('supervisor interruption lacks complete cleanup inventory')
    reconciled=[]
    pending_base=bounded(root,f'.state/task-processes/{task}/{run}')
    for pending in unresolved:
        if not isinstance(pending,dict) or pending.get('error')!='unresolved planned process birth':
            raise ValueError('supervisor interruption retains unresolved process custody')
        record=Path(pending.get('record','')).resolve(strict=True)
        if record.parent!=pending_base:
            raise ValueError('planned spawn is outside the interrupted execution')
        identity=digest(record);raw=read_json(record)
        if digest(record)!=identity:raise ValueError('planned spawn record changed during observation')
        if (raw.get('task')!=task or raw.get('run')!=run or raw.get('pgid') is not None
                or record.name!=raw.get('token','')+'.json'):
            raise ValueError('planned spawn belongs to another execution')
        from gambit_smp.spawn_protocol import reconcile
        closed=reconcile(root,raw)
        if (not closed or closed.get('result') not in ('cancelled-before-birth','cancelled-before-exec')
                or closed.get('targetExecuted') is not False or digest(record)!=identity):
            raise ValueError('planned spawn lacks current exclusive non-execution custody')
        reconciled.append(dict(record=str(record),sha256=identity,observation=closed))
    try:
        interval=(datetime.fromisoformat(row['endedAt'])-datetime.fromisoformat(row['startedAt'])).total_seconds()
    except (KeyError,TypeError,ValueError) as error:
        raise ValueError('interrupted supervisor lacks supervisor expenditure accounting') from error
    if interval<=0:
        raise ValueError('interrupted supervisor has invalid supervisor expenditure interval')
    return dict(supervisor=str(path),sha256=checksum,exit=row['exit'],
        kind='resource-limit' if resource_limit else 'supervisor-interruption',
        causeRecorded=row.get('interruptionError'),reconciledPlannedSpawns=reconciled,
        rssLimitExceeded=row.get('rssLimitExceeded',False),
        footprintLimitExceeded=row.get('footprintLimitExceeded',False),
        parentReaped=True,accountingOnly=True,nativeOutputsAdmitted=False,
        supervisorWallIntervalSeconds=interval)


def reconciled_task_interruption(root, prior):
    """A reconciled task-run stop is expenditure only, not a resumable child.

    Research outputs live under the task run, not a work-process supervisor.
    The run record must already say the supervisor was reaped and nothing native
    was admitted. A live supervisor is not an interruption.
    """
    from gambit_smp.workspace import bounded
    from gambit_smp.recipes import read_json
    from datetime import datetime
    try:
        parts = prior.resolve(strict=True).relative_to(root.resolve() / '.cache/tasks').parts
    except (OSError, ValueError):
        return None
    if len(parts) < 4 or parts[1] != 'runs' or parts[3] != 'outputs':
        return None
    task, run = parts[0], parts[2]
    path = bounded(root, f'.state/task-runs/{task}/{run}.json')
    if not path.is_file():
        return None
    checksum = digest(path)
    row = read_json(path)
    if digest(path) != checksum:
        raise ValueError('task interruption record changed during observation')
    recorded = Path(row.get('output', ''))
    try:
        recorded_ok = recorded.resolve() == (root.resolve() / '.cache/tasks' / task / 'runs' / run)
    except OSError:
        recorded_ok = False
    if (row.get('task') != task or row.get('run') != run or row.get('state') != 'interrupted'
            or row.get('nativeAdmitted') is not False or not isinstance(row.get('reconciliation'), dict)
            or not recorded_ok):
        return None
    supervisor = row.get('supervisorPid')
    if type(supervisor) is int and supervisor > 1:
        try:
            os.kill(supervisor, 0)
        except ProcessLookupError:
            pass
        else:
            return None
    try:
        interval = (datetime.fromisoformat(row['endedAt']) - datetime.fromisoformat(row['startedAt'])).total_seconds()
    except (KeyError, TypeError, ValueError) as error:
        raise ValueError('interrupted task run lacks expenditure accounting') from error
    if interval <= 0:
        raise ValueError('interrupted task run has an invalid expenditure interval')
    return dict(supervisor=str(path), sha256=checksum, exit=-9, kind='supervisor-interruption',
                causeRecorded=None, reconciledPlannedSpawns=[], rssLimitExceeded=False,
                footprintLimitExceeded=False, parentReaped=True, accountingOnly=True,
                nativeOutputsAdmitted=False, supervisorWallIntervalSeconds=interval)


def failed_prefix_retry(state, prefix, recipe, steps, inputs, engine_id, *, interruption=None):
    """A recorded failure or reconciled supervisor interruption is not a live resume.

    An external kill does not reconstruct the missing child/aggregate result.
    Only its observed expenditure and custody carry forward, never artifacts.
    """
    records = prefix['records']
    header = records[0]['payload']
    if not state['resumption']['relations'].get('failed_attempt_history') and interruption is None:
        return None
    if not state['resumption']['executionQuiescence']['observed']:
        raise ValueError('failed prefix retry requires observed process quiescence')
    if header['recipe'] != recipe['id']:
        raise ValueError('failed prefix retry requires the same recipe identity')
    old = header['declaration']
    graph = lambda rows: [(r['id'], r['capability'], r['dependsOn']) for r in rows]
    if graph(old['steps']) != graph(steps):
        raise ValueError('failed prefix retry requires the same capability graph')
    if recipe.get('timeoutPolicy') != old.get('timeoutPolicy'):
        raise ValueError('failed prefix retry cannot expand watchdog or phase budgets')
    # The recorded 600-second value is a hang guard. Raising only that guard,
    # up to the per-stage ceiling, does not resume a deadline or reuse artifacts.
    widened = 0
    for step in steps:
        recorded = header['stepBudgets'].get(step['id'])
        if recorded is None or step['budgetSeconds'] <= recorded:
            continue
        if recorded != 600 or step['budgetSeconds'] > 3600:
            raise ValueError('failed prefix retry cannot expand watchdog or phase budgets')
        widened += step['budgetSeconds'] - recorded
    if recipe['budgetSeconds'] > header['budgetSeconds'] + widened:
        raise ValueError('failed prefix retry cannot expand watchdog or phase budgets')
    changed = {name: sha for name, sha in inputs.items() if header['inputs'].get(name) != sha}
    # A reconciled external stop is not a logical failure. The same engine and
    # inputs may start again, and the partial artifacts stay unreused.
    external_stop = interruption is not None and interruption.get('kind') == 'supervisor-interruption'
    if not changed and header['engineId'] == engine_id and not external_stop:
        raise ValueError('unchanged failed prefix is not a fresh repair attempt')
    result=dict(committedPrefix=prefix['prefixIdentity'], engineId=header['engineId'],
                engineChanged=header['engineId'] != engine_id, changedInputs=changed,
                failedPrefixExpenditure=dict(accountingOnly=True, freshAttempt=True,
                    parentCompletionObserved=False, oldAggregateOutcome=None),
                runtimeAdmitted=False)
    if interruption is not None:
        key='externalResourceInterruption' if interruption.get('kind','resource-limit')=='resource-limit' else 'externalSupervisorInterruption'
        result[key]=interruption
        result['priorArtifactsReusable']=False
    return result


def validate_graph(recipe, steps):
    if any(step["capability"] not in ALLOWED for step in steps):
        raise ValueError("new research cannot call a historical producer or untyped C-file builder")
    # Python bytes may be parsed as data by the existing typed source contract;
    # they are never executable study/runner inputs. Other script inputs retain
    # the original denial. The capability validates the exact declared role.
    read_sources = {name for step in steps if step['capability']=='source.contract'
                    for name in step.get('arguments',{}).get('readSources',[])}
    c_sources = {name for step in steps if step['capability'] in {'c.cbmc', 'c.frama-c', 'c.genmc'}
                 for name in step['arguments']['sources']}
    for name in recipe["inputs"]:
        parts = Path(name).parts
        if ((name.endswith('.py') and name not in read_sources) or name.endswith('.sh') or
                (name.endswith('.inc') and name not in c_sources) or
                len(parts) >= 2 and parts[:2] in {("evidence", "source-results"), ("evidence", "model-results")}):
            raise ValueError("new research cannot consume executable scripts or archived producer outputs")
    evaluations = [step for step in steps if step["capability"] == "evidence.evaluate"]
    if len(evaluations) != 1 or steps[-1] != evaluations[0]:
        raise ValueError("one terminal native evidence evaluation required")
    dsl_only = len(steps) == 1 and "dsl" in evaluations[0]["arguments"]
    model_only = (any(step['capability'].startswith('quint.') or step['capability']=='lean.check' for step in steps)
                  and all(step['capability'].startswith('quint.') or step['capability'] in {'lean.check','evidence.evaluate'}
                          for step in steps))
    focused_gate2 = (any(step["capability"] == "gambit.gate2-collect" for step in steps)
                     and all(step["capability"] in {"gambit.gate2-collect", "evidence.evaluate"} for step in steps))
    focused_observation = (any(step["capability"] == "gambit.observation-identity" for step in steps)
                           and all(step["capability"] in {
                               "gambit.observation-identity", "gambit.executable-test",
                               "gambit.suite", "evidence.evaluate"}
                               or (step["capability"] == "gambit.object"
                                   and step["arguments"].get("matchRuntimeObject") is True)
                               for step in steps))
    source_contract_only = (any(step['capability'] in {'c.cbmc', 'c.frama-c', 'c.genmc', 'source.contract', 'research.audit', 'architecture.views', 'sysml.structure', 'sysml.project'} for step in steps)
                            and all(step['capability'] in {'c.cbmc', 'c.frama-c', 'c.genmc', 'sysml.project', 'sysml.structure', 'architecture.preflight', 'architecture.views', 'source.contract', 'research.audit', 'evidence.evaluate', 'quint.observe', 'quint.parse', 'quint.test', 'lean.check'}
                                    for step in steps))
    ci_producer = any(step['capability']=='gerbil.build' and step['arguments'].get('producer')=='bazel-ci' for step in steps)
    installed_control = (any(step['capability']=='gerbil.test' and 'sourceLock' in step['arguments'] for step in steps)
                         and all(step['capability'] in {'sysml.project','research.audit','gerbil.test','evidence.evaluate'} for step in steps))
    if not (dsl_only or model_only or source_contract_only or ci_producer or installed_control or focused_gate2 or focused_observation) and not any(step["capability"] in {
            "gambit.materialize", "gambit.generation-artifact"} for step in steps):
        raise ValueError("a new research run must start from a locked source producer")
    for step in steps:
        if step["capability"] in {"gambit.suite", "gambit.bootstrap", "gambit.upstream-tests"}:
            args = step["arguments"]
            if (args.get("failures") not in recipe["inputs"] or args.get("reviewRules") not in recipe["inputs"]
                    or not args["failures"].endswith(".json") or not args["reviewRules"].endswith(".ss")):
                raise ValueError("suite requires declared known-failure inventory and native review rules")
            if step["capability"] == "gambit.bootstrap":
                ref = args.get("identity")
                if (not isinstance(ref, dict) or ref.get("output") != "identity"
                        or ref.get("step") != args["runtime"]["step"] or ref["step"] not in step["dependsOn"]):
                    raise ValueError("bootstrap needs matching producer identity")
        if step["capability"] == "source.project":
            if not any(row["origin"]["kind"] == "source-artifact" for row in step["arguments"]["files"]):
                raise ValueError("workspace must contain actual locked-source bytes, not only a synthetic fixture")
            if any(row["origin"]["kind"] == "research-asset" and not row["origin"]["path"].endswith((".c", ".h"))
                   for row in step["arguments"]["files"]):
                raise ValueError("workspace research assets must be C sources or headers")


def sealed_inventory(engine):
    """Read each byte through no-follow directory handles, without path aliases."""
    found = {}
    def visit(fd, prefix):
        with os.scandir(fd) as entries:
            for entry in entries:
                name = prefix + entry.name
                if entry.is_symlink():
                    raise ValueError("sealed engine implementation drift")
                directory = entry.is_dir(follow_symlinks=False)
                if not directory and not entry.is_file(follow_symlinks=False):
                    raise ValueError("sealed engine implementation drift")
                flags = os.O_RDONLY | os.O_NOFOLLOW | (os.O_DIRECTORY if directory else os.O_NONBLOCK)
                child = os.open(entry.name, flags, dir_fd=fd)
                try:
                    mode = os.fstat(child).st_mode
                    if directory:
                        if not stat.S_ISDIR(mode):
                            raise ValueError("sealed engine implementation drift")
                        visit(child, name + "/")
                    else:
                        if not stat.S_ISREG(mode):
                            raise ValueError("sealed engine implementation drift")
                        sha = hashlib.sha256()
                        while block := os.read(child, 1048576):
                            sha.update(block)
                        found[name] = sha.hexdigest()
                finally:
                    os.close(child)
    fd = os.open(engine, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        visit(fd, "")
    finally:
        os.close(fd)
    return found


@lru_cache(maxsize=2)
def manifest_content_identity(manifest_bytes):
    """Memoize canonical encoding only, keyed by the entire immutable bytes."""
    manifest = json.loads(manifest_bytes)
    return content_id({key: value for key, value in manifest.items() if key != "engineId"})


def check_generation_identity(recorded, current, mounted_devices):
    """A device number is mount-local; hashed bytes and the inode remain checked."""
    if (not isinstance(recorded, list) or len(recorded) != 2
            or any(type(value) is not int for value in recorded)
            or current[1] != recorded[1]):
        raise ValueError("sealed generation inode drift")
    prior = mounted_devices.setdefault(recorded[0], current[0])
    if prior != current[0]:
        raise ValueError("sealed generation device mapping is inconsistent")


class HostToolDrift(ValueError):
    def __init__(self, tool):
        self.tool = tool
        super().__init__("sealed host tool drift: " + tool)


def manifest_paths(engine, *, _repair_rg=False):
    engine = engine.resolve(strict=True)
    manifest_bytes = (engine / "engine.json").read_bytes()
    manifest = json.loads(manifest_bytes)
    if manifest.get("schema") != ENGINE_SCHEMA:
        raise ValueError("sealed research engine required")
    if manifest.get("engineId") != manifest_content_identity(manifest_bytes):
        raise ValueError("engine manifest identity mismatch")
    inventory = sealed_inventory(engine)
    if inventory.get("engine.json") != hashlib.sha256(manifest_bytes).hexdigest():
        raise ValueError("engine manifest changed during validation")
    if set(inventory) != set(manifest["files"]) | {"engine.json"}:
        raise ValueError("sealed engine inventory drift")
    for name, expected in manifest["files"].items():
        if not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts:
            raise ValueError("relative sealed implementation path required")
        if inventory[name] != expected:
            raise ValueError("sealed engine implementation drift")
    if manifest["schema"] == ENGINE_SCHEMA:
        ownership = manifest.get("resourceOwnership", {})
        if ownership.get("contract") != "checked-generation-sharing.v1":
            raise ValueError("sealed generation ownership contract required")
        transfers = ownership.get("generations", {})
        expected = {name for name in manifest["files"]
                    if name.startswith(("native/syntax/", "runtime/", "python/ascent/")) and GENERATION.fullmatch(Path(name).suffix)}
        if set(transfers) != expected:
            raise ValueError("sealed generation ownership inventory drift")
        mounted_devices = {}
        for name, row in transfers.items():
            if row.get("sha256") != manifest["files"][name] or row.get("mode") not in ("linked-generation", "copied"):
                raise ValueError("sealed generation ownership identity drift")
            if row["mode"] == "linked-generation":
                info = (engine / name).stat(follow_symlinks=False)
                check_generation_identity(row.get("targetIdentity"),
                                          [info.st_dev, info.st_ino], mounted_devices)
    for name, row in manifest["hostTools"].items():
        if name == "rg" and _repair_rg:
            continue
        try:
            matches = digest(Path(row["path"])) == row["sha256"]
        except FileNotFoundError:
            matches = False
        if not matches:
            raise HostToolDrift(name)
    provider_schema = manifest.get("providerSources", {}).get("schema")
    if provider_schema in {"ascent.rust-source-archive.v1", "ascent.rust-wheel-archive.v1"}:
        build = json.loads((engine / "ascent-build.json").read_text())
        mapping = json.loads((engine / "ascent-runtime.json").read_text())
        if (build.get("schema") != "ascent.rust-build.v1" or not build.get("runtimeInputs")
                or manifest.get("externalRuntimeInputs") != ({} if provider_schema == "ascent.rust-wheel-archive.v1" else build["runtimeInputs"])
                or manifest["providerSources"].get("inputs") != build.get("sourceInputs")
                or manifest["providerSources"].get("runtimeInputs") != build["runtimeInputs"]
                or set(mapping) != set(build["runtimeInputs"])
                or any(manifest["files"].get(mapping[name]) != sha
                       for name, sha in build["runtimeInputs"].items())
                or any(manifest["files"].get("provider-source/" + name) != sha
                       for name, sha in build["sourceInputs"].items())):
            raise ValueError("sealed Rust provider source/runtime inventory drift")
        if provider_schema == "ascent.rust-wheel-archive.v1":
            if (not build.get("packageInputs")
                    or set(build.get("runtimePackagePaths", {})) != set(build["runtimeInputs"])
                    or any(manifest["files"].get("python/ascent/" + name) != sha
                           for name, sha in build["packageInputs"].items())
                    or any(mapping[name] != "python/ascent/" + relative
                           for name, relative in build["runtimePackagePaths"].items())):
                raise ValueError("sealed wheel package inventory drift")
    for name, expected in manifest.get("externalRuntimeInputs", {}).items():
        path = Path(name)
        if not path.is_absolute() or ".." in path.parts or path.is_symlink() or digest(path) != expected:
            raise ValueError("sealed runtime resource drift: " + name)
    return manifest


def seal(out, *, gcc, quint=None, node=None, lean=None, cbmc=None, z3=None, wp_runtime=None, genmc_runtime=None, ascent_api, provider_sources=None, portable=False, sysml_binary=None,
         _tool_repair=None):
    from gambit_smp.artifact_storage import transfer_generation, clone_file
    from gambit_smp.recipes import tool_files
    from gambit_smp.native_review import POLICY
    from gambit_smp.provider_contract import inspect_provider
    from gambit_smp.ascent_runtime import inventory, require_packaged_runtime
    out = out.resolve()
    if out.exists():
        raise ValueError("engine seals are immutable; a fresh directory is required")
    package = Path(__file__).resolve().parent
    if out.is_relative_to(package):
        raise ValueError("engine seal cannot overwrite its implementation")
    # Imported API callers obey the same output placement as the CLI.
    from gambit_smp.artifact_storage import runtime_output
    if out.is_relative_to(ROOT.resolve()):
        out = runtime_output(ROOT, out)
    # Explicit external export/test directories retain their existing contract.
    # The installed extension is authoritative; no alternate ABI directory.
    api = ascent_api.resolve(strict=True)
    if provider_sources is not None:
        manifest_paths(provider_sources)
    files, build = inventory(sealed_root=provider_sources)
    binding = files["ascent"].parent
    if api != binding:
        raise ValueError("ascent_api must identify the installed Rust Python package")
    require_packaged_runtime(build, binding)
    originals = {path: "python/gambit_smp/" + path.relative_to(package).as_posix()
                 for path in implementation_paths(package)}
    originals.update({path: "python/ascent/" + path.relative_to(binding).as_posix()
                      for path in (files["ascent"], files["ascent._core"])})
    originals[ROOT / POLICY] = "policy/suite-review-rules.ss"
    from gambit_smp.upstream_tests import POLICIES
    originals.update({ROOT / name: sealed for name, sealed in POLICIES.items()})
    sysml_provider = None
    if sysml_binary is not None:
        from gambit_smp.contract_capabilities import sdk_inventory, SERVICE_ENTRY, SERVICE_RULES
        sdk_files, sysml_provider = sdk_inventory(sysml_binary, ROOT / 'uv.lock')
        originals.update(sdk_files)
        originals.update({ROOT / SERVICE_ENTRY: 'policy/sysml-service.entry.json',
                          ROOT / SERVICE_RULES: 'policy/sysml-service.ss'})
    packaged = build.get("packageInputs", {})
    package_sources = {}
    for name, sha in packaged.items():
        path = relative(binding, name)
        if digest(path) != sha:
            raise ValueError("installed ASCENT package input drift")
        originals[path] = "python/ascent/" + name
    runtime = {}
    for name, path in files.items():
        if name.startswith("distribution:"):
            originals[path] = "python/" + path.parent.name + "/" + path.name
        elif name.startswith("package:"):
            originals[path] = "python/" + name.removeprefix("package:")
        elif name.startswith("source:"):
            if packaged:
                # The same bytes can have both source and runtime roles. Keep
                # the independent source archive when runtime mapping wins.
                package_sources[path] = ("provider-source/" + name.removeprefix("source:"),
                                         "python/ascent/_sources/" + name.removeprefix("source:"))
            originals[path] = "provider-source/" + name.removeprefix("source:")
        elif name.startswith("runtime:"):
            original = name.removeprefix("runtime:")
            target = ("python/ascent/" + build["runtimePackagePaths"][original] if packaged else
                      "runtime/" + hashlib.sha256(original.encode()).hexdigest() + "/" + path.name)
            originals[path] = target
            runtime[original] = target
    before = {path: digest(path) for path in originals}
    provider_contract = inspect_provider(api, binding)
    host = {"python": Path(sys.executable).resolve(strict=True), "gcc": gcc.absolute()}
    # Configure runs in a sanitized child environment. Carry observed tool
    # identities across that boundary instead of depending on the caller PATH.
    for name in ("aclocal", "autoconf", "m4"):
        selected = (os.environ.get('M4') or shutil.which(name)) if name == 'm4' else shutil.which(name)
        if selected is not None:
            path = Path(selected).resolve(strict=True)
            if not path.is_file() or not os.access(path, os.X_OK):
                raise ValueError('selected configure tool is not executable: ' + name)
            if name == 'm4' and (path.name == 'gm4' or 'XcodeDefault.xctoolchain' in path.parts):
                raise ValueError('selected m4 is Apple gm4 and does not accept --gnu: ' + str(path))
            host[name] = path
    if sys.platform == "darwin" and Path("/usr/bin/sample").is_file():
        host["darwinSample"] = Path("/usr/bin/sample")
    # Scientific services share one observed tool set; no study/version resolves
    # a fallback executable at execution time. Missing tools stay unavailable.
    for name in ('d2','emacs','rg','git','uname','file','nm','otool','dwarfdump','strings'):
        selected=shutil.which(name)
        if selected is not None:host[name]=Path(selected).resolve(strict=True)
    if lean is not None:
        compiler=lean.resolve(strict=True)
        if compiler.name!='lean' or not compiler.is_file() or not compiler.stat().st_mode & 0o111:
            raise ValueError('explicit Lean compiler required; toolchain-manager shims are not providers')
        host['lean']=compiler
    if cbmc is not None:
        checker = cbmc.resolve(strict=True)
        if checker.name != 'cbmc' or not checker.is_file() or not os.access(checker, os.X_OK):
            raise ValueError('explicit executable CBMC provider required')
        host['cbmc'] = checker
    if z3 is not None:
        prover = z3.resolve(strict=True)
        if prover.name != 'z3' or not prover.is_file() or not os.access(prover, os.X_OK):
            raise ValueError('explicit executable Z3 provider required')
        host['z3'] = prover
    if (quint is None) != (node is None):
        raise ValueError("Quint and Node must be sealed together")
    if quint is not None:
        host.update(quint=quint.absolute(), node=node.absolute())
        host.update({"quint-file:" + str(path): path for path in tool_files(quint, node)})
    tools = {name: {"path": str(path), "sha256": digest(path)} for name, path in host.items()}
    wp_provider = None
    if wp_runtime is not None:
        from gambit_smp.frama_c_capabilities import runtime_inventory
        declared = wp_runtime.resolve(strict=True)
        wp_paths, wp_provider = runtime_inventory(json.loads(declared.read_text()))
        wp_paths['wp-declaration'] = declared
        tools.update({name: {'path': str(path), 'sha256': digest(path)}
                      for name, path in wp_paths.items()})
    genmc_provider = None
    if genmc_runtime is not None:
        from gambit_smp.genmc_capabilities import runtime_inventory as genmc_inventory
        declared = genmc_runtime.resolve(strict=True)
        runtime_paths, genmc_provider = genmc_inventory(json.loads(declared.read_text()))
        runtime_paths['genmc-declaration'] = declared
        tools.update({name: {'path': str(path), 'sha256': digest(path)}
                      for name, path in runtime_paths.items()})
    if _tool_repair is not None:
        old, replacement = _tool_repair
        if (build["sourceInputs"] != old["providerSources"]["inputs"]
                or build["runtimeInputs"] != old["providerSources"]["runtimeInputs"]
                or sysml_provider != old.get("sysmlProvider")
                or genmc_provider != old.get("genmcRuntime")
                or wp_provider != old.get("wpRuntime")):
            raise ValueError("rg repair requires the same sealed providers")
        tools = {**old["hostTools"], "rg": replacement}
    out.mkdir(parents=True)
    generations, shared = {}, set()
    private_transfers = {"copy-on-write": 0, "byte-copy": 0}
    for path, name in originals.items():
        target = relative(out, name)
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() or target.is_symlink():
            if target.is_symlink() or not target.is_file() or digest(target) != before[path]:
                raise ValueError("sealed resource role collision")
            continue
        if name.startswith(("runtime/", "python/ascent/")) and GENERATION.fullmatch(path.suffix):
            mode = transfer_generation(path, target, portable=portable)
            if digest(target) != before[path]:
                raise ValueError("runtime generation changed during transfer")
            info = target.stat(follow_symlinks=False)
            generations[name] = {"mode": mode, "sha256": before[path],
                                 "source": str(path), "targetIdentity": [info.st_dev, info.st_ino]}
            if mode == "linked-generation":
                shared.add(target)
        else:
            private_transfers[clone_file(path, target)] += 1
    for path, names in package_sources.items():
        for name in names:
            target = relative(out, name)
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists() or target.is_symlink():
                if target.is_symlink() or not target.is_file() or digest(target) != before[path]:
                    raise ValueError("provider source/runtime role collision")
                continue
            private_transfers[clone_file(path, target)] += 1
    (out / "ascent-runtime.json").write_text(json.dumps(runtime, sort_keys=True, indent=2) + "\n")
    (out / "ascent-build.json").write_text(json.dumps(build, sort_keys=True, indent=2) + "\n")
    runner = out / "runner.py"
    runner.write_text("import sys\nfrom pathlib import Path\n"
                      "root = Path(__file__).resolve().parent\n"
                      "sys.path.insert(0, str(root / 'python'))\n"
                      "from gambit_smp.research_kernel import worker\n"
                      "raise SystemExit(worker(root))\n")
    if any(digest(path) != expected for path, expected in before.items()):
        raise ValueError("implementation/provider changed while sealing; incomplete seal is not admissible")
    sealed_files = {path.relative_to(out).as_posix(): digest(path)
                    for path in out.rglob("*") if path.is_file()}
    identity = {"schema": ENGINE_SCHEMA, "files": sealed_files, "hostTools": tools,
                "processProtocol": PROCESS_PROTOCOL,
                "privateFileTransfers": {**private_transfers, "hardlinks": False},
                "resourceOwnership": {"contract": "checked-generation-sharing.v1", "generations": generations,
                                      "boundary": "byte-bound resources; shared generations are not write-isolated"},
                "providerContract": provider_contract,
                "externalRuntimeInputs": {} if packaged else build["runtimeInputs"],
                "providerSources": {"schema": "ascent.rust-wheel-archive.v1" if packaged else "ascent.rust-source-archive.v1",
                                    "inputs": build["sourceInputs"],
                                    "runtimeInputs": build["runtimeInputs"]},
                "capabilities": sorted(ALLOWED), "pythonVersion": sys.version,
                "scope": "closed research implementation and installed PyO3 provider",
                "runtimeAdmitted": False, "releaseAdmitted": False}
    if genmc_provider is not None:
        identity['genmcRuntime'] = genmc_provider
    if wp_provider is not None:
        identity['wpRuntime'] = wp_provider
    if sysml_provider is not None:
        identity['sysmlProvider'] = sysml_provider
    if _tool_repair is not None:
        identity["hostToolRepair"] = {"priorEngineId": old["engineId"], "tool": "rg",
                                      "previous": old["hostTools"]["rg"], "replacement": replacement}
    manifest = {**identity, "engineId": content_id(identity)}
    (out / "engine.json").write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n")
    for path in out.rglob("*"):
        if path.is_file() and path not in shared:
            executable = identity.get('sysmlProvider', {}).get('executableFiles', [])
            path.chmod(0o555 if path.relative_to(out).as_posix() in executable else 0o444)
    for path in sorted((path for path in out.rglob("*") if path.is_dir()), reverse=True):
        path.chmod(0o555)
    out.chmod(0o555)
    manifest_paths(out)
    return manifest


def recover_launch_engine(engine, out):
    """Use a new immutable seal for observed rg drift on a fresh attempt."""
    try:
        return engine, manifest_paths(engine)
    except HostToolDrift as error:
        if error.tool != "rg" or out.exists():
            raise
    old = manifest_paths(engine, _repair_rg=True)
    selected = shutil.which("rg")
    if selected is None:
        raise ValueError("rg repair requires an executable rg on PATH")
    path = Path(selected).resolve(strict=True)
    replacement = {"path": str(path), "sha256": digest(path)}
    tools = old["hostTools"]
    spec = importlib.util.find_spec("ascent")
    api = Path(spec.origin).parent
    successor = out.with_name(out.name + ".engine")
    def tool(name):
        return Path(tools[name]["path"]) if name in tools else None

    if not successor.exists():
        seal(successor, gcc=tool("gcc"), quint=tool("quint"), node=tool("node"),
             lean=tool("lean"), ascent_api=api,
             genmc_runtime=tool("genmc-declaration") if "genmcRuntime" in old else None,
             wp_runtime=tool("wp-declaration") if "wpRuntime" in old else None,
             sysml_binary=engine / "tools/sysml-grpc" if "sysmlProvider" in old else None,
             _tool_repair=(old, replacement))
    manifest = manifest_paths(successor)
    expected = {"priorEngineId": old["engineId"], "tool": "rg",
                "previous": tools["rg"], "replacement": replacement}
    if (manifest.get("hostToolRepair") != expected
            or manifest["hostTools"] != {**tools, "rg": replacement}
            or manifest["providerSources"] != old["providerSources"]
            or any(manifest.get(key) != old.get(key)
                   for key in ("sysmlProvider", "genmcRuntime", "wpRuntime"))):
        raise ValueError("rg repair successor does not match the requested seal")
    return successor, manifest


def execution_origin(engine):
    """Check loaded code origins; filesystem identity is a separate boundary."""
    engine = engine.resolve(strict=True)
    code = engine / "python/gambit_smp"
    if not Path(__file__).resolve().is_relative_to(code.resolve()):
        raise ValueError("new research must execute the sealed implementation, not the editable checkout")
    for name, module in tuple(sys.modules.items()):
        if name.startswith("gambit_smp.") and name.rsplit(".", 1)[1] in FORBIDDEN_IMPORTS:
            raise ValueError("historical feature producer loaded into the new research lane")
        if (name == "ascent" or name.startswith(("gambit_smp", "ascent."))) and getattr(module, "__file__", None):
            path = Path(module.__file__).resolve()
            if not path.is_relative_to(engine):
                raise ValueError("research implementation escaped its engine seal")


def execution_identity(engine):
    manifest = manifest_paths(engine)
    execution_origin(engine)
    return manifest


def evaluation_teardown_deadline(recipe, requested_deadline, owner):
    """Use the last real progress-stage review window, not expired total wall time."""
    if recipe.get("timeoutPolicy", {}).get("mode") == "progress":
        return owner.deadline
    return requested_deadline


def begin_evaluation_teardown(recipe, requested_deadline, owner):
    """Recipe completion starts its declared close phase, not another review."""
    policy = recipe.get('timeoutPolicy', {})
    completed = owner.process is None or (bool(owner.records) and all(
        row.get('requestCompleted') is True and row.get('timeout') is False for row in owner.records))
    mode = 'original-deadline'
    if policy.get('mode') == 'progress' and completed:
        from gambit_smp.recipes import budget
        budget(policy['overheadSeconds'])
        owner.deadline = time.monotonic() + policy['overheadSeconds']
        mode = 'fresh-configured-phase'
    elif policy.get('mode') == 'progress':
        mode = 'unfinished-request'
    return dict(scope='owner-close-only', mode=mode,
        deadline=evaluation_teardown_deadline(recipe, requested_deadline, owner),
        budgetSeconds=policy.get('overheadSeconds') if mode == 'fresh-configured-phase' else None,
        nativeStageBudgetsChanged=False)


def worker(engine):
    task=os.environ.get('GAMBIT_SMP_TASK_ID')
    if task:
        from gambit_smp.workspace import execution_scope
        with execution_scope(Path(os.environ['GAMBIT_SMP_TASK_ROOT']),task):
            return _worker(engine)
    return _worker(engine)


def _worker(engine):
    from gambit_smp.recipes import load, read_json, run
    if sys.argv[1] == "runtime-export":
        from gambit_smp.runtime_artifact import export
        manifest = execution_identity(engine)
        request = read_json(Path(sys.argv[2]))
        root = Path(request["root"])
        producer = read_json(Path(request["run"]) / "receipt.json")
        if producer["engineId"] != manifest["engineId"]:
            raise ValueError("runtime export selected another producer engine")
        print(json.dumps(export(root, Path(request["run"]), request["step"], Path(request["out"]))))
        return 0
    if sys.argv[1] == "rules":
        from gambit_smp.evidence_capabilities import native_evaluate
        from gambit_smp.ascent_program import sealed_api_boundary
        with sealed_api_boundary(engine) as manifest:
            request = read_json(Path(sys.argv[2]))
            if request["engineId"] != manifest["engineId"]:
                raise ValueError("native evaluator selected a different engine seal")
            native_evaluate(request)
        return 0
    manifest = execution_identity(engine)
    request = read_json(Path(sys.argv[1]))
    if request["engineId"] != manifest["engineId"]:
        raise ValueError("launch selected a different engine seal")
    journal = request["journal"]
    header_path = Path(journal["path"])
    if digest(header_path) != journal["sha256"]:
        raise ValueError("launch run header changed")
    header = read_json(header_path)
    if header["request"] != {key: value for key, value in request.items() if key != "journal"}:
        raise ValueError("launch request differs from committed run header")
    if "launchOwner" in request:
        owner_path = Path(request["launchOwner"])
        while not owner_path.is_file():
            if time.monotonic() >= request["deadline"]:
                raise TimeoutError("launch owner observation was not committed")
            time.sleep(.01)
        owner = read_json(owner_path)
        if (owner.get("pid") != os.getpid() or owner.get("runId") != header["runId"]
                or owner.get("clockEpoch") != clock_epoch() or owner.get("event") != "started"):
            raise ValueError("launch owner identity mismatch")
    if header["inputs"] != {name: digest(Path(request["root"]) / name) for name in header["inputs"]}:
        raise ValueError("launch input differs from committed run header")
    def guard(event, args):
        if event == "import" and args[0].startswith("gambit_smp.") and args[0].split(".")[1] in FORBIDDEN_IMPORTS:
            raise ImportError("historical feature producers are unavailable in the sealed research lane")
    sys.addaudithook(guard)
    root = Path(request["root"])
    recipe, _ = load(root, root / request["recipe"])
    if recipe["schema"] != SCHEMA:
        raise ValueError("new research lane requires artifact-graph v2")
    tools = manifest["hostTools"]
    from gambit_smp.evidence_capabilities import evaluation_owner
    with evaluation_owner(engine, Path(request["out"]) / "evaluation-owner", request["deadline"]) as owner:
        receipt = run(root, root / request["recipe"], Path(request["out"]),
                      Path(tools["quint"]["path"]) if "quint" in tools else Path("quint"),
                      Path(tools["node"]["path"]) if "node" in tools else Path("node"),
                      Path(request["prior"]) if request["prior"] else None,
                      gcc=Path(tools["gcc"]["path"]), allow_native=request["allowNative"],
                      engine=engine, deadline=request["deadline"], journal=request["journal"],
                      budget_reservation=request.get("budgetReservation"), resume_prefix=request.get("resumePrefix"))
        owner_finalization_started = time.monotonic()
        teardown = begin_evaluation_teardown(recipe, request['deadline'], owner)
        teardown_deadline = teardown['deadline']
    owner_result = owner.receipt
    if owner_result is not None:
        owner_path = Path(request["out"]) / "evaluation-owner/receipt.json"
        receipt["evaluationOwner"] = {"path": "evaluation-owner/receipt.json", "sha256": digest(owner_path)}
        receipt["evaluationOwnerFinalizationSeconds"] = time.monotonic() - owner_finalization_started
        receipt['evaluationOwnerTeardownPolicy'] = teardown
        receipt["wholeSeconds"] += receipt["evaluationOwnerFinalizationSeconds"]
        if (owner_result["exit"] != 0 or owner_result["forcedTermination"]
                or any(not row["requestCompleted"] or row["timeout"] for row in owner_result["requests"])
                or time.monotonic() > teardown_deadline):
            receipt["outcome"] = "DENY"
        (Path(request["out"]) / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    if owner_result is not None and (owner_result["exit"] != 0 or owner_result["forcedTermination"]
            or any(not row["requestCompleted"] or row["timeout"] for row in owner_result["requests"])):
        raise ValueError("evaluation owner did not complete and tear down normally")
    if time.monotonic() > teardown_deadline:
        raise TimeoutError("research deadline exhausted during evaluation owner teardown")
    # A reaped owner just performed this exact full byte check. The parent
    # independently rehashes the seal after worker exit as well.
    if owner_result is None:
        execution_identity(engine)
    elif owner_result["engineId"] != manifest["engineId"] or owner_result["terminalIdentityError"] is not None:
        raise ValueError("evaluation owner terminal seal mismatch")
    print(json.dumps({"engineId": manifest["engineId"], "recipe": receipt["recipe"], "outcome": receipt["outcome"]}))
    return 0 if receipt["outcome"] == "PASS" else 2


def completed_stage_frontier(out, steps, journal):
    """Recognize completed execution, not permission for another native stage."""
    from gambit_smp.recipes import read_json
    try:
        header = read_json(Path(journal["path"]))
        if digest(Path(journal["path"])) != journal["sha256"]:
            return False
        for declared in steps:
            path = out / "run" / (declared["id"] + ".observation.json")
            if path.is_symlink():
                return False
            record = read_json(path)
            result = record["step"]
            if (record.get("schema") != "research-step-observation.v1"
                    or record.get("header") != journal or record.get("runId") != header["runId"]
                    or result.get("id") != declared["id"]
                    or result.get("outcome") not in ("PASS", "DENY", "STALE", "TIMEOUT", "FAIL", "BLOCKED")
                    or result.get("capability") != declared["capability"]
                    or result.get("arguments") != declared["arguments"]):
                return False
            observations = result.get("commands", [])
            if "exit" in result:
                observations = [*observations, result]
            if any(item.get("parentReaped") is not True or
                   item.get("processGroupQuiescent") is not True for item in observations):
                return False
        return bool(steps)
    except (OSError, KeyError, TypeError, ValueError):
        return False


def completed_work(out, steps, *, journal=None, required_inputs=None):
    """Observe completed checks/stages/processes/files, never timestamps or log volume."""
    count = 0
    run = out / "run"
    validation = run / 'input-validation.json'
    if journal is not None and required_inputs is not None and not validation.is_symlink():
        try:
            row = json.loads(validation.read_text())
            if (row.get('schema') == 'recipe-input-validation.v1'
                    and row.get('header') == journal
                    and row.get('scope') == 'declared-inputs-not-native-work'
                    and row.get('completed') is True
                    and row.get('requiredInputs') == required_inputs
                    and isinstance(row.get('observedInputs'), dict)
                    and all(row['observedInputs'].get(name) == sha for name, sha in required_inputs.items())):
                count += 1
        except (OSError, ValueError, TypeError):
            pass
    for step in steps:
        try:
            stage = json.loads((run / (step["id"] + ".observation.json")).read_text())
            if (stage.get("schema") == "research-step-observation.v1"
                    and stage.get("step", {}).get("id") == step["id"]
                    and stage.get("step", {}).get("outcome") in {"PASS", "DENY", "FAIL", "TIMEOUT", "STALE", "BLOCKED"}):
                count += 1
        except (OSError, ValueError, TypeError):
            pass
        directory = run / step["id"]
        for path in directory.glob("*.process.json"):
            try:
                row = json.loads(path.read_text())
                count += int(row.get("schema") == "recipe-process-observation.v1"
                             and row.get("state") == "OBSERVED" and type(row.get("exit")) is int
                             and row.get("completionObserved") is True and row.get("parentReaped") is True
                             and row.get('processGroupQuiescent') is True)
            except (OSError, ValueError, TypeError):
                pass
        for path in directory.glob("*.progress.json"):
            try:
                row = json.loads(path.read_text())
                value = row.get("completed")
                if row.get("schema") == "native-completed-progress.v1" and type(value) is int and value > 0:
                    count += value
            except (OSError, ValueError, TypeError):
                pass
    return count


def require_incremental_builds(recipe, steps):
    """All future provider/native build launches use the maintained workspaces.

    Retained observations and running older sealed programs remain readable.
    Historical declarations are not silently translated into another program.
    """
    by_id = {step['id']: step for step in steps}
    for step in steps:
        if (step['capability'] in {'gambit.runtime-import', 'gambit.completed-runtime'}
                and recipe.get('workspacePolicy') != 'in-place'):
            raise ValueError('runtime reuse requires in-place maintained workspace policy')
        if step['capability'] in {'gerbil.build','gerbil.test'} and recipe.get('workspacePolicy') != 'in-place':
            raise ValueError('Gerbil build execution requires in-place incremental workspace')
        if step['capability'] != 'gambit.configure':
            continue
        source = by_id[step['arguments']['source']['step']]
        if (recipe.get('workspacePolicy') != 'in-place' or source['capability'] != 'gambit.materialize'
                or source['arguments'].get('buildWorkspace') != 'gambit-core'):
            raise ValueError('native build execution requires its maintained incremental workspace Recipe')


def allocate_run_directory(out):
    """Claim only a new or empty container under the caller's execution lease.

    Durable header/prefix validation precedes this call. No retained bytes are
    removed, no prior attempt is qualified, and build-start arbitration still
    applies before native execution.
    """
    if out.is_symlink():
        raise ValueError('research output cannot be a directory alias')
    try:
        out.mkdir(parents=True, exist_ok=False)
        state = 'created'
    except FileExistsError:
        if not out.is_dir() or any(out.iterdir()):
            raise ValueError('unbound non-empty research output; inspect its evidence before recovery')
        state = 'adopted-empty'
    stat = out.stat()
    return dict(state=state, device=stat.st_dev, inode=stat.st_ino,
                priorBytesRemoved=False, nativeResultReused=False)


def run_sealed(root, path, out, engine, *, prior=None, allow_native=False, repair_plan=None):
    from gambit_smp.recipes import load, read_json, authorization_repair
    from gambit_smp import host_environment
    started = time.monotonic()
    if prior is not None:
        prior = prior.resolve()
    recipe, steps = load(root, path)
    progress_mode = recipe.get("timeoutPolicy", {}).get("mode") == "progress"
    if recipe["schema"] != SCHEMA:
        raise ValueError("historical recipes cannot claim a new architecture run")
    inputs = {name: digest(root / name) for name in [path.relative_to(root).as_posix(), *recipe["inputs"]]}
    out = out.resolve()
    if out.is_relative_to(root / "evidence") or any((root / name).resolve().is_relative_to(out) for name in inputs):
        raise ValueError("execution cannot overwrite its Evidence inputs")
    engine, manifest = recover_launch_engine(engine, out)
    from gambit_smp.reasoning_history import read_execution_checkpoint
    if (out / "run-header.json").is_file():
        retain_existing_run(root, out)
    prefix = read_execution_checkpoint(root, out)
    if (out / "receipt.json").is_file() or (out / "run-header.json").is_file() or prefix["records"]:
        if repair_plan is not None:
            raise ValueError('repair output already has evidence; inspect it with --read')
        if (out / "receipt.json").is_file():
            terminal = True
            original = read_json(out / "receipt.json")
        elif prefix["records"]:
            tail = prefix["records"][-1]["payload"]
            terminal = tail.get("schema") == "research-terminal-observation.v1"
            original = tail["outer"] if terminal else prefix["records"][0]["payload"]
        else:
            terminal = False
            original = read_json(out / "run-header.json")
        state = inspect(out, include_resumption=True)
        origin_root = original.get("root", original.get("request", {}).get("root"))
        matching = (origin_root == str(root.resolve()) and original.get("recipe") == recipe["id"]
                    and original.get("inputs") == inputs and original.get("engineId") == manifest["engineId"]
                    and original.get("stepBudgets") == {s["id"]: s["budgetSeconds"] for s in steps})
        reusable = False
        if terminal and original.get("outcome") == "PASS" and matching and state["resumption"]["relations"]["campaign_reusable"]:
            final_state = inspect(out)
            reusable = (final_state["identityStatus"] == "CURRENT"
                        and final_state["evidenceBindingStatus"] == "CURRENT"
                        and (digest(out / "receipt.json") == state["resumption"]["receiptSha256"]
                             if (out / "receipt.json").is_file() else
                             read_execution_checkpoint(root, out)["prefixIdentity"] == state["resumption"]["prefixIdentity"])
                        and inputs == {name: digest(root / name) for name in inputs})
        # A restart consumes the original receipt; it never rewrites history or
        # reports a repeated native launch. Partial/changed runs expose gaps.
        return {"schema": "research-resume-observation.v1", "recipe": recipe["id"],
                "engineId": manifest["engineId"],
                "outcome": "PASS" if reusable else "DENY", "recordedOutcome": original.get("outcome"),
                "resumeStatus": "REUSED" if reusable else "UNRESOLVED" if terminal else "INCOMPLETE",
                "requestedIdentityMatches": matching, "resumption": state["resumption"],
                "executionLaunched": False, "wholeSeconds": time.monotonic() - started,
                "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
    # Historical inspection above launches nothing; only a new execution needs
    # the current birth/exec transport. Do not invalidate retained history.
    transport = transport_compatibility(manifest)
    if not transport['current']:
        reason = ('sealed engine predates birth/exec admission' if manifest.get('processProtocol') != PROCESS_PROTOCOL
                  else 'sealed engine birth/exec implementation differs')
        raise ValueError(reason + '; transport evidence: ' + json.dumps(transport, sort_keys=True))
    require_incremental_builds(recipe, steps)
    repair = None
    if repair_plan is not None:
        if prior is None or out.is_relative_to(prior) or prior.is_relative_to(out):
            raise ValueError('repair requires a separate output and a committed prior')
        from gambit_smp.research_repair import review_repair
        repair = review_repair(root, prior, recipe, steps, inputs, manifest, repair_plan,
                               task=os.environ.get('GAMBIT_SMP_TASK_ID'))
        if repair['status'] != 'eligible':
            raise ValueError('repair candidate blocked: ' + json.dumps(repair['inference']['relations']['blocked']))
    allocation = allocate_run_directory(out)
    deadline = started + recipe["budgetSeconds"]
    request = {"engineId": manifest["engineId"], "root": str(root), "recipe": path.relative_to(root).as_posix(),
               "out": str(out / "run"), "prior": str(prior / "run") if prior else None,
               "allowNative": allow_native, "deadline": deadline}
    prior_identity = None
    analysis = None
    reservation = None
    if "continuationRequest" in recipe:
        from gambit_smp.recipe_continuation import reserve_budget
        continuation = read_json(root / recipe["continuationRequest"])
        ledger = read_json(root / recipe["continuationLedger"])
        reservation = reserve_budget(root, ledger, continuation, out.name)
        request["budgetReservation"] = reservation

    def retain_receipt(receipt):
        receipt['outputAllocation'] = allocation
        if analysis is not None:
            receipt['buildStartAnalysis'] = analysis
        if repair is not None:
            from gambit_smp.research_repair import verify_repair
            receipt['repair'] = verify_repair(out, receipt, repair)
        if "timeoutPolicy" in recipe:
            receipt["timeoutPolicy"] = recipe["timeoutPolicy"]
            receipt["supervisorWatchdogSeconds"] = recipe["budgetSeconds"]
            receipt["supervisorWatchdogKind"] = "no-progress" if progress_mode else "wall-clock"
            receipt["supervisorWatchdogExceeded"] = receipt.get("timeout", False) if progress_mode else time.monotonic() > deadline
            receipt.pop("performanceBudgetExceeded", None)
        if reservation is not None:
            receipt["budgetReservation"] = reservation
            if receipt.get("executionLaunched") is False:
                receipt.update(parentReaped=True, processGroupQuiescent=True,
                               wholeSeconds=time.monotonic() - started)
        target = out / "receipt.json"
        target.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n")
        retain_terminal_run(root, out, receipt)
        if reservation is not None:
            from gambit_smp.recipe_continuation import settle_budget
            settlement = settle_budget(root, reservation, target, digest(target))
            with (out / "budget-settlement.json").open("x") as stream:
                json.dump({"ledger": reservation["ledger"], "event": settlement,
                           "outerReceiptSha256": digest(target)}, stream, sort_keys=True)
                stream.write("\n")
        return receipt
    host = host_environment.observe(steps)
    if repair is not None:
        prior_identity = dict(repairIdentity=repair['identity'], failurePrefix=repair['plan']['baselinePrefix'])
        request['prior'] = None
    partial_prior = repair is None and prior is not None and not (prior / "receipt.json").is_file()
    if partial_prior:
        try:
            from gambit_smp.step_checkpoint import recovered_resumption
            state = recovered_resumption(root, prior)
            old = read_execution_checkpoint(root, prior)
            header = old["records"][0]["payload"]
            prior_identity = dict(committedPrefix=old['prefixIdentity'], engineId=header['engineId'],
                                  oldAggregateOutcome=None, runtimeAdmitted=False)
            interruption=supervised_interruption(root,prior)
            if interruption is None:
                interruption=reconciled_task_interruption(root,prior)
            retry = failed_prefix_retry(state, old, recipe, steps, inputs, manifest['engineId'],
                                        interruption=interruption)
            if retry is not None:
                prior_identity = retry
                request['prior'] = None
            elif (state["outcome"] != "INCOMPLETE" or state["engineId"] != manifest["engineId"]
                    or state["recipe"] != recipe["id"]):
                raise ValueError("interrupted continuation requires the same engine and recipe contract")
            if not state["resumption"]["executionQuiescence"]["observed"]:
                raise ValueError("interrupted process births are not observed quiescent")
            # A fresh attempt already checked hang-guard widening. A live resume
            # still cannot lengthen a phase that is being continued.
            if retry is None and any(step["budgetSeconds"] > header["stepBudgets"].get(step["id"], step["budgetSeconds"]) for step in steps):
                raise ValueError("interrupted continuation cannot expand a phase budget")
            if retry is None and header["inputs"] == inputs and state["resumption"]["relations"]["failed"]:
                raise ValueError("unchanged failed stage is not an interrupted-only continuation")
            if retry is None:
                request["resumePrefix"] = state["resumption"]["prefixIdentity"]
                prior_identity = {"committedPrefix": request["resumePrefix"], "engineId": header["engineId"],
                                  "interruptedContinuation": True, "oldAggregateOutcome": None,
                                  "changedInputs": {name: sha for name, sha in inputs.items() if header["inputs"].get(name) != sha}}
        except (OSError, KeyError, ValueError, TypeError) as error:
            return retain_receipt({"schema": "sealed-research-run.v1", "recipe": recipe["id"],
                "engine": str(engine), "engineId": manifest["engineId"], "inputs": inputs, "root": str(root),
                "stepBudgets": {s["id"]: s["budgetSeconds"] for s in steps}, "budgetSeconds": recipe["budgetSeconds"],
                "outcome": "DENY", "denial": str(error), "executionLaunched": False,
                "prior": prior_identity, "hostEnvironment": host, "artifacts": {}, "childReceiptSha256": None,
                "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False})
    if repair is None and prior is not None and not partial_prior:
        try:
            previous = read_json(prior / "receipt.json")
            prior_identity = {"receiptSha256": digest(prior / "receipt.json"), "engineId": previous["engineId"],
                              "changedInputs": {name: value for name, value in inputs.items() if previous["inputs"].get(name) != value},
                              "engineChanged": previous["engineId"] != manifest["engineId"]}
            if previous.get("schema") != "sealed-research-run.v1":
                raise ValueError("matching sealed prior observation required")
            from gambit_smp.recipes import checked_build_migration
            migration = checked_build_migration(root, path, recipe, previous) if previous['recipe'] != recipe['id'] else None
            if migration is not None:
                prior_identity['buildMigration'] = migration
            if previous["recipe"] != recipe["id"] and migration is None:
                if "timeoutPolicy" not in recipe:
                    raise ValueError("matching sealed prior observation required")
                old_request = prior / "request.json"
                if digest(old_request) != previous.get("artifacts", {}).get("request.json"):
                    raise ValueError("timeout migration requires the bound original request")
                old_name = read_json(old_request)["recipe"]
                old_path = root / old_name
                if digest(old_path) != previous["inputs"].get(old_name):
                    raise ValueError("timeout migration original recipe drifted")
                old_recipe, old_graph = load(root, old_path)
                old_mode = old_recipe.get("timeoutPolicy", {}).get("mode", "whole")
                migration = old_mode == "whole" or (old_mode == "per-stage" and progress_mode)
                if (not migration or old_recipe["id"] != previous["recipe"] or old_graph != steps
                        or not set(old_recipe["inputs"]) <= set(recipe["inputs"])
                        or any(previous["inputs"].get(name) != inputs.get(name)
                               for name in old_recipe["inputs"])):
                    raise ValueError("timeout migration must preserve the exact graph and input closure")
                if (previous.get("parentReaped") is not True
                        or previous.get("processGroupQuiescent") is not True):
                    raise ValueError("timeout migration requires a quiescent prior attempt")
                request["prior"] = None
                prior_identity["timeoutPolicyMigration"] = {
                    "originalRecipeSha256": digest(old_path), "sameGraph": True,
                    "sameInputs": True, "freshAttempt": True, "deadlineResumed": False}
            if "timeoutPolicy" not in recipe and recipe["budgetSeconds"] > previous["budgetSeconds"]:
                raise ValueError("prior budget cannot expand")
            from gambit_smp.recipes import hang_guard_widening
            child_steps = read_json(prior / "run/receipt.json").get("steps") if (prior / "run/receipt.json").is_file() else None
            widened = hang_guard_widening(previous, steps, child_steps=child_steps)
            if widened:
                prior_identity["hangGuardWidened"] = widened
            repaired_authorization = False
            repaired_environment = host_environment.repaired(previous, host, fresh_attempt=True)
            child_path = prior / "run/receipt.json"
            if previous.get("childReceiptSha256") is not None:
                if digest(child_path) != previous["childReceiptSha256"]:
                    raise ValueError("prior child receipt was changed")
                repaired_authorization = authorization_repair(read_json(child_path), allow_native,
                                                             manifest["hostTools"].get("gcc"))
            elif not repaired_environment and (previous.get("timeout") is True
                                               or previous.get("executionLaunched") is True):
                if (previous.get("parentReaped") is not True
                        or previous.get("processGroupQuiescent") is not True):
                    raise ValueError("prior process group must be quiescent before a fresh attempt")
                if child_path.exists():
                    raise ValueError("prior child receipt exists without a bound digest")
                request["prior"] = None
                prior_identity["interruptedPriorExpenditure"] = {
                    "wholeSeconds": previous.get("wholeSeconds"), "timeout": previous.get("timeout"),
                    "accountingOnly": True, "freshAttempt": True, "deadlineResumed": False}
            prior_identity["authorizationRepaired"] = repaired_authorization
            prior_identity["environmentRepaired"] = repaired_environment
            if repaired_environment:
                request["prior"] = None  # This exact prelaunch denial has no child run.
                prior_identity["environmentPriorExpenditure"] = {
                    "budgetSeconds": previous["budgetSeconds"], "wholeSeconds": previous["wholeSeconds"],
                    "freshAttempt": True, "deadlineResumed": False}
            source_resume = None
            if previous.get("childReceiptSha256") is not None:
                from gambit_smp.recipes import resumable_source_sync
                source_resume = resumable_source_sync(root, read_json(child_path))
            if (previous["outcome"] != "PASS" and previous["inputs"] == inputs
                    and previous["engineId"] == manifest["engineId"]
                    and not repaired_authorization and not repaired_environment
                    and source_resume is None):
                raise ValueError("unchanged failed research route; a new directory is not a causal change")
            if source_resume is not None:
                prior_identity["sourceSyncResumption"] = source_resume
        except (OSError, KeyError, ValueError, TypeError) as error:
            receipt = {"schema": "sealed-research-run.v1", "recipe": recipe["id"], "engine": str(engine),
                       "engineId": manifest["engineId"], "inputs": inputs, "root": str(root),
                       "budgetSeconds": recipe["budgetSeconds"], "stepBudgets": {s["id"]: s["budgetSeconds"] for s in steps},
                       "outcome": "DENY", "denial": str(error), "executionLaunched": False,
                       "prior": prior_identity, "hostEnvironment": host, "artifacts": {}, "childReceiptSha256": None,
                       "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
            return retain_receipt(receipt)
    if host is not None and host["available"] is not True:
        receipt = {"schema": "sealed-research-run.v1", "recipe": recipe["id"], "engine": str(engine),
                   "engineId": manifest["engineId"], "inputs": inputs, "root": str(root),
                   "budgetSeconds": recipe["budgetSeconds"], "stepBudgets": {s["id"]: s["budgetSeconds"] for s in steps},
                   "outcome": "DENY", "denial": host_environment.ERROR, "hostEnvironment": host,
                   "wholeSeconds": time.monotonic() - started,
                   "executionLaunched": False, "prior": prior_identity, "artifacts": {}, "childReceiptSha256": None,
                   "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
        return retain_receipt(receipt)
    request["launchOwner"] = str(out / "launch-owner.json")
    from gambit_smp.reasoning_history import build_start_analysis, CheckpointConflict
    analysis = build_start_analysis({'declaration': dict(recipe, steps=steps)})
    header = {"schema": "research-run-header.v1", "runId": uuid.uuid4().hex,
              "buildStartAnalysis": analysis,
              "outputAllocation": allocation,
              "declaration": dict(recipe, steps=steps),
              "recipe": recipe["id"], "inputs": inputs, "engineId": manifest["engineId"],
              "clockEpoch": clock_epoch(), "startedMonotonic": started, "deadlineMonotonic": deadline,
              "budgetSeconds": recipe["budgetSeconds"],
              "stepBudgets": {step["id"]: step["budgetSeconds"] for step in steps},
              "request": dict(request), "executionCompleted": False,
              "requestedPrior": str(prior) if prior is not None else None,
              "prior": prior_identity,
              "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
    if "timeoutPolicy" in recipe:
        header["timeoutPolicy"] = recipe["timeoutPolicy"]
    if repair is not None:
        header['repair'] = repair
    try:
        journal = retain_run_record(root, out / "run-header.json", "research:" + recipe["id"], header, inputs)
    except CheckpointConflict as error:
        return retain_receipt(dict(schema='sealed-research-run.v1', recipe=recipe['id'],
            engine=str(engine), engineId=manifest['engineId'], inputs=inputs, root=str(root),
            stepBudgets=header['stepBudgets'], budgetSeconds=recipe['budgetSeconds'],
            outcome='DENY', denial=str(error), executionLaunched=False, prior=prior_identity,
            buildStartAnalysis=analysis, parentReaped=True, processGroupQuiescent=True,
            wholeSeconds=time.monotonic() - started, artifacts={}, childReceiptSha256=None,
            runtimeAdmitted=False, releaseAdmitted=False, sourceRefinementAdmitted=False))
    request["journal"] = journal
    (out / "request.json").write_text(json.dumps(request, sort_keys=True, indent=2) + "\n")
    environment = host_environment.execution_environment(root, os.environ)
    metadata = {}
    command = [manifest["hostTools"]["python"]["path"], "-I", "-B", str(engine / "runner.py"), str(out / "request.json")]
    code, log, timeout, seconds = execute(command, root, max(0.001, deadline - time.monotonic()),
                                        env=environment, metadata=metadata,
                                        process_recorder=process_recorder(root, out, journal,
                                            owner_path=Path(request["launchOwner"]), deadline=deadline),
                                        completion_check=lambda: completed_stage_frontier(out, steps, journal),
                                        completion_grace=30,
                                        **({"progress_check": lambda stdout, stderr: completed_work(
                                            out, steps, journal=journal, required_inputs=inputs)}
                                           if progress_mode else {}))
    (out / "launch.log").write_text(log)
    child = out / "run/receipt.json"
    child_outcome = read_json(child)["outcome"] if child.is_file() else "DENY"
    try:
        manifest_paths(engine)
        stable = inputs == {name: digest(root / name) for name in inputs}
    except (OSError, ValueError):
        stable = False
    outcome = "STALE" if not stable else "PASS" if code == 0 and not timeout and child_outcome == "PASS" else "DENY"
    receipt = {"schema": "sealed-research-run.v1", "recipe": recipe["id"], "engine": str(engine),
               "engineId": manifest["engineId"], "inputs": inputs, "root": str(root), "budgetSeconds": recipe["budgetSeconds"],
               "stepBudgets": {step["id"]: step["budgetSeconds"] for step in steps},
               "outcome": outcome, "childOutcome": child_outcome, "argv": command, "environment": environment,
               "performanceBudgetExceeded": time.monotonic() > deadline,
               "exit": code, "timeout": timeout, "seconds": seconds, "wholeSeconds": time.monotonic() - started,
               "executionLaunched": True, "prior": prior_identity, "hostEnvironment": host,
               "journal": journal,
               "artifacts": {name: digest(out / name) for name in ("launch.log", "request.json")},
               "childReceiptSha256": digest(child) if child.is_file() else None,
               "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False,
               **metadata}
    return retain_receipt(receipt)


def transport_compatibility(manifest):
    """Expose launch premises separately from seal-byte identity and producer reuse."""
    from gambit_smp.ascent_program import load_component_catalog, query
    required = dict(process_transport_identity(), protocol=PROCESS_PROTOCOL)
    recorded = dict(manifest.get('files', {}))
    if manifest.get('processProtocol') is not None:
        recorded['protocol'] = manifest['processProtocol']
    catalog = load_component_catalog(ROOT/'evidence/dsl/components.json', entry='checkpoint-state',
        constructor='make-execution-transport', trusted=True)
    result = query(dict(transport_required=list(required.items()),
        transport_recorded=[(key, recorded[key]) for key in required if key in recorded],
        transport_enumerated=[()]), catalog, dict(gaps='transport_gap', current='transport_current'))
    return dict(current=bool(result['current']), gaps=result['gaps'],
                expectedProtocol=PROCESS_PROTOCOL, recordedProtocol=manifest.get('processProtocol'),
                scope='new-execution-transport-not-native-producer-identity', runtimeAdmitted=False)


def execution_summary(receipt, child):
    """Summarize receipt-bound cost and retained builds, never qualify them.

    Child command durations may overlap stage time and include witness work.
    They are not a measurement of Python overhead or avoidable rebuild cost.
    """
    stages, candidates, failures = [], [], []
    transports = {'gambit.seed-core': 'gambit.seed-checkpoint',
                  'gambit.source-core': 'gambit.runtime-import',
                  'gambit.bootstrap': 'gambit.completed-runtime'}
    for row in child.get('steps', []):
        stages.append({key: row.get(key) for key in
                       ('id', 'capability', 'outcome', 'stageSeconds', 'executionLaunched')})
        stages[-1]['commands'] = [{key: command.get(key) for key in
                                  ('stage', 'seconds', 'exit', 'timeout', 'log', 'logSha256')}
                                 for command in row.get('commands', [])]
        if 'handlerComparison' in row:
            stages[-1]['handlerComparison'] = row['handlerComparison']
        if 'cVerification' in row:
            proof = row['cVerification']
            observed = {key: value for key, value in proof.items()
                        if key not in {'properties', 'projections'}}
            # Keep the complete property inventory in the normal aggregate
            # read. Large traces remain at their receipt-bound raw reference.
            observed['properties'] = [
                dict(property=prop['property'], status=prop['status'],
                     description=prop.get('description'),
                     sourceLocation={key: value for key, value in
                                     prop.get('sourceLocation', {}).items()
                                     if key in {'file', 'line', 'function'}},
                     traceAvailable=bool(prop.get('trace')))
                for prop in proof.get('properties', [])]
            raw_path = row['id'] + '/' + proof['rawReport']
            observed['rawReport'] = dict(path=raw_path,
                sha256=row.get('artifacts', {}).get(raw_path))
            observed['verificationArtifact'] = row.get('outputs', {}).get('verification')
            stages[-1]['cVerification'] = observed
        if row.get('reused'):
            stages[-1]['reused'] = row['reused']
        if row.get('outcome') not in {'PASS', 'BLOCKED'}:
            failures.append({key: row.get(key) for key in ('id', 'capability', 'outcome', 'reason')})
        transport = transports.get(row.get('capability'))
        if row.get('outcome') == 'PASS' and transport:
            candidate = dict(step=row['id'], capability=transport, transportAdmitted=False,
                             outputs=row.get('outputs', {}))
            for name in ('makeLineage', 'makeLineagePreflight', 'fullTwoPassBootstrapEstablished'):
                if name in row:
                    candidate[name] = row[name]
            candidates.append(candidate)
    result = dict(schema='research-execution-summary.v1', childReceiptSha256=receipt['childReceiptSha256'],
                wholeSeconds=receipt.get('wholeSeconds'), stages=stages,
                checkpointConsumption=child.get('checkpointConsumption'),
                changedInputs=list(child.get('prior', {}).get('changedInputs', {})),
                changedTools=list(child.get('prior', {}).get('changedTools', {})),
                retainedBuildCandidates=candidates, failures=failures,
                nextBoundary='FAILED_STAGE' if failures else
                             ('DECLARED_RECIPE_COMPLETE' if receipt.get('outcome') == 'PASS' else 'OUTER_COMPLETION'),
                executionAuthorized=False, runtimeAdmitted=False)
    c_steps = {row['id'] for row in child.get('steps', []) if 'cVerification' in row}
    if c_steps:
        result['cContractEvidence'] = [dict(step=row['id'], answers=row['answers'])
            for row in child.get('steps', [])
            if row.get('capability') == 'evidence.evaluate' and 'answers' in row
            and c_steps.intersection(row.get('dependsOn', []))]
    return result


def bound_child_receipt(out, receipt):
    raw = (out / 'run/receipt.json').read_bytes()
    if hashlib.sha256(raw).hexdigest() != receipt['childReceiptSha256']:
        raise ValueError('execution summary child receipt identity changed')
    child = json.loads(raw)
    if child.get('recipe') != receipt['recipe'] or child.get('schema') != 'evidence-recipe-run.v1':
        raise ValueError('execution summary requires the matching recipe child')
    return child


def bound_execution_summary(out, receipt, *, checkpoint=None):
    """A stale or substituted child cannot supply timing/reuse guidance."""
    child = bound_child_receipt(out, receipt)
    result = execution_summary(receipt, child)
    result['nativeFailureDiagnostics'] = native_failure_diagnostics(out / 'run', child.get('steps', []))
    result.update(rest_execution_summary(out, receipt, child))
    from gambit_smp.ordered_stress_audit import declares_ordered_stress, item12_audit
    if declares_ordered_stress(child.get('plannedSteps', child['steps'])):
        result['item12Audit'] = item12_audit(out, receipt, child, checkpoint=checkpoint)
    from gambit_smp.gate2_collection import CAPABILITY, read_collection
    if any(step.get('capability') == CAPABILITY for step in child.get('plannedSteps', child['steps'])):
        result['gate2Collection'] = read_collection(Path(receipt['root']), out, outer=receipt, child=child,
                                                   checkpoint=checkpoint)
    for step in child.get('steps', []):
        if 'orderedStress' in step.get('arguments', {}):
            name = step['id']+'/item10-preflight.json'
            if sha := step.get('artifacts', {}).get(name):
                from gambit_smp.recipes import decode_json
                try:
                    raw = relative(out/'run', name).read_bytes()
                    if hashlib.sha256(raw).hexdigest() != sha:
                        raise ValueError('item 10 preflight receipt changed')
                    result['item10StartCheck'] = decode_json(raw)
                except (OSError, ValueError) as error:
                    result['item10StartCheck'] = dict(checklist=10, canStart=False, reason=str(error),
                                                      runtimeAdmitted=False)
    from gambit_smp.compiler_trace import module_compiler_trace
    traces = [trace for step in child.get('steps', [])
              if (trace := module_compiler_trace(out / 'run', step)) is not None]
    if traces:
        result['compilerTraces'] = traces
        from gambit_smp.compiler_trace import add_compiler_trace_facts
        from gambit_smp.research_repair import _project
        facts = {}
        for trace in traces:
            if trace['status'] == 'RECEIPT_BOUND':
                add_compiler_trace_facts(facts, trace, str(out / 'run' / trace['reference']))
        result['compilerObservations'] = _project(facts)
    differences = []
    # Diagnose current declared support separately from an archive-bound
    # historical receipt. This observation never grants checkpoint reuse.
    for name, expected in child.get('inputs', {}).items():
        try:
            actual = digest(Path(name))
            if actual != expected:
                differences.append(dict(path=name, expectedSha256=expected, observedSha256=actual))
        except OSError as error:
            differences.append(dict(path=name, expectedSha256=expected, error=str(error)))
    result['currentDeclaredInputDifferences'] = differences
    return result


def native_failure_diagnostics(run, steps):
    """Read failed commands' bound logs without rerunning any producer.

    Make's final Error 2 is usually a consequence. Retain the earlier native
    compiler diagnostic and its exact line, but do not infer its root cause.
    """
    diagnostics = []
    for step in steps:
        commands = step.get('commands', [])
        for index, command in enumerate(commands):
            terminal_failure = (step.get('outcome') not in (None, 'PASS', 'BLOCKED')
                                and index == len(commands) - 1)
            if command.get('exit') in (None, 0) and not command.get('timeout') and not terminal_failure:
                continue
            row = dict(step=step['id'], command=command['stage'], log=command.get('log'),
                       logSha256=command.get('logSha256'))
            try:
                path = relative(run, step['id'] + '/' + command['log'])
                raw = path.read_bytes()
                if hashlib.sha256(raw).hexdigest() != command.get('logSha256'):
                    raise ValueError('failed command log identity changed')
                messages = []
                lines = raw.decode('utf-8', errors='replace').splitlines()
                for number, line in enumerate(lines, 1):
                    if any(marker in line for marker in
                           ('*** ERROR', '*** in procedure', 'error:', 'Make lineage refused:')):
                        messages.append(dict(line=number, text=line[:2048]))
                        if len(messages) == 8:
                            break
                excerpt = [(i + 1, line) for i, line in enumerate(lines)
                           if i < 8 or i >= len(lines) - 8]
                row.update(status='RECEIPT_BOUND', diagnostics=messages,
                           commandExit=command.get('exit'), commandTimeout=command.get('timeout'),
                           logExcerpt=[dict(line=i, text=line[:512]) for i, line in excerpt],
                           logLineCount=len(lines), excerptTruncated=len(lines)>16 or any(len(s)>512 for _,s in excerpt))
            except (OSError, ValueError, KeyError, TypeError) as error:
                row.update(status='UNVERIFIED', reason=str(error))
            diagnostics.append(row)
    return diagnostics


def inspect(out, *, input_archive=None, include_resumption=False):
    from gambit_smp.recipes import inspect_run, read_json
    if (out / "engine.json").is_file():
        if input_archive is not None or (out / "receipt.json").exists():
            raise ValueError("engine inspection requires an unambiguous seal, not a run or input archive")
        manifest = manifest_paths(out)
        dependencies = {name for name in manifest["hostTools"] if name.startswith("quint-file:")}
        return {"artifactKind": "sealed-engine", "engineId": manifest["engineId"],
                "transportCompatibility": transport_compatibility(manifest),
                "hostTools": {name: row for name, row in manifest["hostTools"].items()
                              if name not in dependencies},
                "hostToolDependencyCount": len(dependencies),
                "capabilities": manifest["capabilities"],
                "identityStatus": "CURRENT", "executionLaunched": False,
                "runtimeAdmitted": False, "releaseAdmitted": False,
                "sourceRefinementAdmitted": False}
    if not (out / "receipt.json").exists():
        from gambit_smp.artifact_storage import repository_root
        from gambit_smp.step_checkpoint import recovered_resumption, interrupted_resumption
        from gambit_smp.reasoning_history import read_execution_checkpoint
        ancestor = out
        while not ancestor.exists():
            ancestor = ancestor.parent
        root = repository_root(ancestor)
        if read_execution_checkpoint(root, out)["records"]:
            # Inspection returns an authenticated immutable prefix, not execution
            # authority. Concurrent appends must not starve this read-only view.
            return recovered_resumption(root, out, require_current_prefix=False)
        if (out / "run-header.json").is_file():
            return interrupted_resumption(root, out)
        state = ('absent' if not out.exists() else 'empty' if out.is_dir() and not any(out.iterdir())
                 else 'unbound-content')
        return dict(artifactKind='unstarted-research-output', allocationState=state,
                    repairContext=dict(kind='output-allocation', durableCheckpointPresent=False,
                        emptyContainerReusable=state in {'absent', 'empty'},
                        boundary='Existing research entry must revalidate execution custody, prior lineage, tools and budgets.'),
                    executionLaunched=False, executionAuthorized=False,
                    runtimeAdmitted=False, releaseAdmitted=False, sourceRefinementAdmitted=False)
    receipt = read_json(out / "receipt.json")
    if receipt.get("schema") != "sealed-research-run.v1":
        raise ValueError("sealed research receipt required")
    child_state = None
    binding_stable = False
    inspection_failure = None
    try:
        from gambit_smp.historical_inputs import bindings, match
        root = Path(receipt["root"])
        archived, _ = bindings(root, out / "receipt.json", input_archive) if input_archive else ({}, [])
        engine = manifest_paths(Path(receipt["engine"]))
        stable = engine["engineId"] == receipt["engineId"]
        stable = stable and match({str(root / name): value for name, value in receipt["inputs"].items()}, archived)
        stable = stable and all(digest(out / name) == value for name, value in receipt["artifacts"].items())
        if receipt.get("executionLaunched", True):
            stable = stable and digest(out / "run/receipt.json") == receipt["childReceiptSha256"]
            child_state = inspect_run(out / "run", input_bindings=archived)
            binding_stable = stable and child_state["evidenceBindingStatus"] in {"CURRENT", "HISTORICAL_BOUND"}
            stable = stable and child_state["identityStatus"] in {"CURRENT", "HISTORICAL_BOUND"}
        else:
            binding_stable = stable
    except (OSError, KeyError, ValueError, TypeError) as error:
        stable = False
        inspection_failure = dict(errorType=type(error).__name__, reason=str(error))
    result = {"recipe": receipt["recipe"], "engineId": receipt["engineId"], "outcome": receipt["outcome"],
            "identityStatus": ("HISTORICAL_BOUND" if input_archive else "CURRENT") if stable else "STALE",
            "evidenceBindingStatus": (("HISTORICAL_BOUND" if input_archive else "CURRENT")
                                      if binding_stable else "STALE"),
            "artifactAvailability": child_state["artifactAvailability"] if child_state else
                                    {"status": "UNKNOWN", "outputs": []},
            "recordedOutcome": receipt["outcome"],
            "runtimeAdmitted": False, "sourceRefinementAdmitted": False}
    if inspection_failure is not None:
        result['inspectionFailure'] = inspection_failure
    if 'buildStartAnalysis' in receipt:
        result['buildStartAnalysis'] = receipt['buildStartAnalysis']
    header_path = out / 'run-header.json'
    retained_header = None
    projection_source = None
    prefix = None
    if header_path.is_file() and digest(header_path) == receipt.get('artifacts', {}).get('run-header.json'):
        retained_header = read_json(header_path)
        projection_source = dict(kind='receipt-bound-header', sha256=digest(header_path))
    elif header_path.is_file():
        from gambit_smp.reasoning_history import read_execution_checkpoint
        from subprocess import CalledProcessError
        try:
            prefix = read_execution_checkpoint(Path(receipt['root']), out)
            if prefix['records'] and prefix['records'][0]['payload'].get('schema') == 'research-run-header.v1':
                retained_header = prefix['records'][0]['payload']
                projection_source = dict(kind='immutable-execution-checkpoint', prefixIdentity=prefix['prefixIdentity'])
        except (OSError, ValueError, KeyError, TypeError, CalledProcessError) as error:
            result['currentBuildStartAnalysis'] = dict(status='UNVERIFIED', reason=str(error),
                                                      executionAuthorized=False, runtimeAdmitted=False)
    if retained_header is not None:
        try:
            header = retained_header
            if header['recipe'] != receipt['recipe'] or header['engineId'] != receipt['engineId']:
                raise ValueError('retained declaration belongs to another execution')
            from gambit_smp.reasoning_history import build_start_analysis
            result['currentBuildStartAnalysis'] = build_start_analysis(header)
            result['currentBuildStartAnalysis']['declarationSource'] = projection_source
            result['currentBuildStartAnalysis']['scope'] = 'Current ASCENT rules on the retained declaration; no native replay or historical requalification.'
        except (OSError, ValueError, KeyError, TypeError) as error:
            result['currentBuildStartAnalysis'] = dict(status='UNVERIFIED', reason=str(error),
                                                      executionAuthorized=False, runtimeAdmitted=False)
    if receipt.get('childReceiptSha256'):
        try:
            result['executionSummary'] = bound_execution_summary(out, receipt, checkpoint=prefix)
            result['executionSummary']['evidenceBindingStatus'] = result['evidenceBindingStatus']
            result['executionSummary']['artifactAvailabilityStatus'] = result['artifactAvailability']['status']
            check = result['executionSummary'].get('item10StartCheck')
            if check and check['canStart'] and not binding_stable:
                check.update(canStart=False, reason='sealed Research evidence is stale or unavailable')
            audit = result['executionSummary'].get('item12Audit')
            if audit and audit['passed'] and not binding_stable:
                reason = 'sealed Research evidence is stale or unavailable'
                audit.update(passed=False, gaps=[reason])
                audit['links']['originalCampaign'].update(status='MISMATCH', reason=reason)
        except (OSError, ValueError, KeyError, TypeError):
            result['executionSummary'] = {'status': 'UNVERIFIED', 'executionAuthorized': False}
    from gambit_smp.ordered_stress_audit import declares_ordered_stress, item12_audit
    summary = result.get('executionSummary', {})
    declaration = (retained_header or {}).get('declaration', {}).get('steps', [])
    if 'item12Audit' in summary or declares_ordered_stress(declaration):
        from gambit_smp.gate2_evidence import investigation

        summary = result.setdefault('executionSummary', {})
        if 'item12Audit' not in summary:
            summary['item12Audit'] = item12_audit(out, receipt, None, checkpoint=prefix)
        gate = summary['item12Audit']['links']['gate2']
        gate['investigation'] = investigation(gate)
    if include_resumption and input_archive is None:
        from gambit_smp.step_checkpoint import resumption
        result["resumption"] = resumption(Path(receipt["root"]), out, result)
        if any(row.get('capability') == 'gambit.regenerate-module'
               for row in result.get('executionSummary', {}).get('failures', [])):
            from gambit_smp.research_repair import repair_context
            try:
                context = repair_context(Path(receipt['root']), out, receipt)
                if context is not None:
                    result['repairContext'] = context
            except (OSError, ValueError, KeyError, TypeError, RuntimeError) as error:
                result['repairContext'] = dict(status='UNVERIFIED', reason=str(error), executionAuthorized=False)
    if 'repair' in receipt:
        from gambit_smp.research_repair import retained_repair
        try:
            result['repair'] = retained_repair(Path(receipt['root']), out, receipt)
        except (OSError, ValueError, KeyError, TypeError) as error:
            result['repair'] = dict(status='UNVERIFIED', reason=str(error), executionAuthorized=False)
    return result


from gambit_smp.gambit_build_primitives import MODULE_CHECK_INPUTS


def module_check_recipe(recipe, runtime_step, module=None, *, bootstrap_host=None, work_trace=False):
    """Project a checked import or hosted configured source into bounded checks.

    This constructs data only. It never imports a runtime, builds a seed or
    chooses a sibling workspace, and cannot slice a native acceptance run.
    """
    import copy
    if module is not None and (not isinstance(module, str)
                              or not re.fullmatch(r'lib/_[A-Za-z0-9_-]+\.scm', module)):
        raise ValueError('explicit library Scheme module required for configured C23 diagnosis')
    by_id = {row['id']: row for row in recipe['steps']}
    provider = by_id.get(runtime_step)
    if bootstrap_host is not None:
        if (provider is None or provider['capability'] != 'gambit.configure'
                or not isinstance(bootstrap_host, str) or not bootstrap_host.endswith('.json')):
            raise ValueError('hosted module checks require a configured target and a host specification')
    elif provider is None or provider['capability'] not in {
            'gambit.seed-checkpoint', 'gambit.runtime-import', 'gambit.completed-runtime'}:
        raise ValueError('module checks require a checked runtime import, or --bootstrap-host with a configured target')
    selected = set()
    def visit(name):
        if name in selected:
            return
        row = by_id[name]
        if row['capability'] in {'gambit.seed-core', 'gambit.source-core', 'gambit.bootstrap',
                                 'gambit.native-development', 'native.workspace-build', 'native.c-build',
                                 'gerbil.build', 'gambit.suite', 'gambit.upstream-tests'}:
            raise ValueError('module-check import ancestry contains a build or campaign')
        selected.add(name)
        for parent in row['dependsOn']:
            visit(parent)
    visit(runtime_step)
    if 'continuationRequest' in recipe or 'continuationLedger' in recipe:
        raise ValueError('module diagnosis cannot rewrite a reserved acceptance continuation')
    result = copy.deepcopy(recipe)
    if type(work_trace) is not bool or (work_trace and bootstrap_host is not None):
        raise ValueError('work trace requires the compiled native driver')
    result['id'] += '-module-checks' + ('-' + Path(module).stem.lstrip('_') if module else '')
    result['scope'] = 'Isolated actual emitter and configured GCC/C23 checks; no core, bootstrap, Family A or Family 6 admission.'
    result['steps'] = [copy.deepcopy(row) for row in recipe['steps'] if row['id'] in selected]
    if bootstrap_host is not None and bootstrap_host not in result['inputs']:
        result['inputs'].append(bootstrap_host)
    for name in ([module] if module else MODULE_CHECK_INPUTS):
        step = dict(id='check-' + Path(name).stem.lstrip('_'), capability='gambit.regenerate-module',
                    dependsOn=[runtime_step], budgetSeconds=120,
                    arguments=(dict(source=dict(step=runtime_step, output='source'),
                                    bootstrapHost=bootstrap_host, module=name, syntaxCheck=True)
                               if bootstrap_host is not None else
                               dict(runtime=dict(step=runtime_step, output='runtime'), module=name,
                                    syntaxCheck=True, phaseTrace=True, **({'workTrace':True} if work_trace else {}))))
        if 'component' in provider:
            step['component'] = provider['component']
        if step['id'] in selected:
            raise ValueError('module-check step identity collides with the import')
        result['steps'].append(step)
    entry = 'tests/recipes/framework-contracts/evidence-entry.json'
    rules = 'evidence/dsl/observation-contract.ss'
    for name in (entry, rules):
        if name not in result['inputs']:
            result['inputs'].append(name)
    terminal = dict(id='module-check-evidence', capability='evidence.evaluate',
                    dependsOn=[row['id'] for row in result['steps']], budgetSeconds=30,
                    arguments=dict(dsl=entry, queries={'missing_step': 'missing_step'},
                                   expected={'missing_step': []}))
    if terminal['id'] in selected:
        raise ValueError('module-check evidence identity collides with the import')
    if 'component' in provider:
        terminal['component'] = provider['component']
    result['steps'].append(terminal)
    if 'timeoutPolicy' in result:
        result.pop('budgetSeconds', None)  # load() computes this derived total.
    return result


def argument_parser():
    parser = argparse.ArgumentParser(description=__doc__, epilog=(
        'For a Gate 2 read, supply a Scheme request such as '
        '((bindings (("review" "gate2") ("gsiSha256" "FULL-DIGEST")))). '
        'Caller selectors may return named research_review and research_operand rows.'))
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--seal", type=Path,
        help="freeze framework/ASCENT code and host-tool identities; does not build Gambit, change a native producer or reset native budgets")
    selection.add_argument("--run")
    selection.add_argument("--read", type=Path,
                           help="read a run directory or sealed engine, not a prefixIdentity hash; includes live progress/checkpoint and detached execution; never execute")
    selection.add_argument("--export-producer", type=Path)
    selection.add_argument("--export-runtime", type=Path)
    selection.add_argument('--module-checks', type=Path,
        help='print focused checks from a checked runtime or --bootstrap-host configured source; never execute')
    selection.add_argument('--moving-rest-checks', type=Path,
        help='print the three item 8 observations from one checked runtime import Recipe; never execute')
    selection.add_argument('--rest-checks', type=Path,
        help='print all 11 item 6–9 observations from one checked runtime import Recipe; never execute')
    selection.add_argument('--rest-campaign', type=Path,
        help='print the original p2→p1 Recipe after verifying the completed eleven-case rest run')
    parser.add_argument('declaration', nargs='?',
        help='Scheme evidence request for --read or --rest-campaign; use - to read the request from stdin')
    parser.add_argument('--module',
        help='select an explicit lib/_NAME.scm for --module-checks; omission checks the three default cuts')
    parser.add_argument('--bootstrap-host',
        help='with --module-checks: diagnose configured target Scheme on a declared interpreter host; no target bootstrap required')
    parser.add_argument('--work-trace', action='store_true',
        help='with native --module-checks: inject source-bound frontend counters; diagnostic bodies, not native performance')
    parser.add_argument("--step", help="select a read/export step or module-check provider; never limits --run")
    parser.add_argument("--input-archive", help="exact historical source-input archive for producer export")
    parser.add_argument("--ancestry", help="explicit source-bound native bootstrap ancestry declaration")
    parser.add_argument("--engine", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--prior", type=Path)
    parser.add_argument('--repair-plan', type=Path,
        help='review a model-authored hosted diagnostic against --prior. Add --out to execute the eligible candidate')
    parser.add_argument("--gcc", type=Path)
    parser.add_argument("--quint", type=Path)
    parser.add_argument("--node", type=Path)
    parser.add_argument('--lean',type=Path,help='seal an explicit Lean compiler; never resolve/download a toolchain during a run')
    parser.add_argument('--cbmc',type=Path,help='seal an explicit CBMC verifier; never install/resolve a verifier during a run')
    parser.add_argument('--z3',type=Path,help='seal an explicit Z3 decision procedure for C verification')
    parser.add_argument('--genmc-runtime',type=Path,help='seal explicit GenMC, Clang, model/builtin headers and native library inputs; no installation during a run')
    parser.add_argument('--wp-runtime',type=Path,help='seal explicit Frama-C/WP binaries, package data and Why3 configuration; never resolve/install tools during verification')
    parser.add_argument("--ascent-api", type=Path)
    parser.add_argument('--sysml-binary', type=Path, help='seal the official SDK connected-model profile and pinned service binary; never download during a run')
    parser.add_argument("--provider-sources", type=Path,
                        help="validated engine archive for exact provider build inputs")
    parser.add_argument("--portable-seal", action="store_true",
                        help="copy sealed generations for transport to another host job")
    return parser


def execution_policy(arguments):
    args = argument_parser().parse_args(arguments)
    return "read" if (args.module_checks or args.moving_rest_checks or args.rest_checks or args.rest_campaign or
                      (args.read and args.out is None and not args.portable_seal)
                      or (args.run and args.repair_plan and args.out is None)) else "task"


def launch_summary(receipt, out):
    """Expose the actual allocated observation, not a workflow recommendation."""
    keys = (("recipe", "engineId", "outcome", "resumeStatus", "executionLaunched", "wholeSeconds",
             "requestedIdentityMatches", "resumption") if "resumption" in receipt else
            ("recipe", "engineId", "outcome", "exit", "timeout", "denial"))
    result = {key: receipt.get(key) for key in keys}
    result.update(out=str(out), receipt=str(out / 'receipt.json'))
    if 'repair' in receipt:
        result['repair'] = receipt['repair']
    child = out / 'run/receipt.json'
    if receipt.get('childReceiptSha256') and child.is_file():
        raw = child.read_bytes()
        if hashlib.sha256(raw).hexdigest() != receipt['childReceiptSha256']:
            raise ValueError('launch summary child receipt identity changed')
        result['stepFailures'] = [{key: row.get(key) for key in ('id', 'capability', 'outcome', 'reason')}
                                  for row in json.loads(raw).get('steps', [])
                                  if row.get('outcome') not in {'PASS', 'BLOCKED'}]
        result['executionSummary'] = bound_execution_summary(out, receipt)
    return result


def main():
    from gambit_smp.task_entry import present_observation
    from gambit_smp.recipes import discover, load, source_path
    parser = argument_parser()
    args = parser.parse_args()
    if args.step is not None and not (args.read or args.export_producer or args.export_runtime
                                      or args.module_checks or args.moving_rest_checks or args.rest_checks):
        parser.error("--step selects an inspection, export or Recipe projection; --run executes the complete recipe")
    if args.module is not None and not args.module_checks:
        parser.error('--module requires --module-checks; --run executes the complete declared recipe')
    if args.bootstrap_host is not None and not args.module_checks:
        parser.error('--bootstrap-host requires --module-checks')
    if args.work_trace and not args.module_checks:
        parser.error('--work-trace requires --module-checks')
    if args.declaration is not None and not (args.read or args.rest_campaign):
        parser.error('a Scheme evidence request requires --read or --rest-campaign')
    if args.declaration is not None and (args.step is not None or args.input_archive is not None):
        parser.error('a Scheme evidence request selects its own retained inputs')
    if args.portable_seal and not args.seal:
        parser.error("--portable-seal requires --seal")
    if args.ancestry and not args.export_producer:
        parser.error("--ancestry requires --export-producer")
    if args.repair_plan and not (args.run and args.prior and args.engine):
        parser.error('--repair-plan requires --run, --prior and --engine')
    from gambit_smp.artifact_storage import runtime_output
    if args.seal:
        args.seal = runtime_output(ROOT, args.seal)
    if args.out and not args.export_producer:
        args.out = runtime_output(ROOT, args.out)
    try:
        reviews = None
        if args.declaration is not None:
            from gambit_smp.research_request import request_reviews
            reviews = request_reviews(ROOT, sys.stdin.read() if args.declaration == '-' else args.declaration)
        if args.rest_campaign:
            if args.out is not None or args.prior is not None:
                parser.error('--rest-campaign prints Recipe data')
            correspondence = None
            if reviews is not None:
                if len(reviews) != 1:
                    raise ValueError('campaign declaration requires one Gate 2 correspondence')
                kind, operands = next(iter(reviews.values()))
                if kind != 'gate2' or operands.keys() != {'correspondence'}:
                    raise ValueError('campaign declaration requires one Gate 2 correspondence')
                correspondence = operands['correspondence']
            print(json.dumps(rest_campaign_recipe(ROOT, args.rest_campaign, gate2_receipt=correspondence), indent=2))
            return 0
        if args.moving_rest_checks or args.rest_checks:
            if args.step is None or args.out is not None or args.prior is not None:
                parser.error('rest Recipe projection requires a runtime --step and prints Recipe data')
            original, _ = load(ROOT, (args.moving_rest_checks or args.rest_checks).resolve())
            print(json.dumps(rest_check_recipe(ROOT, original, args.step,
                                               moving=args.moving_rest_checks is not None), indent=2))
            return 0
        if args.module_checks:
            if args.step is None or args.out is not None or args.prior is not None:
                parser.error('--module-checks requires a provider --step and prints Recipe data; no --out/--prior')
            original, _ = load(ROOT, args.module_checks.resolve())
            if args.bootstrap_host is not None:
                source_path(ROOT, args.bootstrap_host)
            print(json.dumps(module_check_recipe(original, args.step, args.module,
                                                bootstrap_host=args.bootstrap_host,
                                                work_trace=args.work_trace), indent=2))
            return 0
        if args.seal:
            if args.gcc is None or args.ascent_api is None:
                parser.error("--seal requires host-selected --gcc and --ascent-api")
            manifest = seal(args.seal, gcc=args.gcc, quint=args.quint, node=args.node, lean=args.lean, cbmc=args.cbmc, z3=args.z3, wp_runtime=args.wp_runtime, genmc_runtime=args.genmc_runtime,
                            ascent_api=args.ascent_api, provider_sources=args.provider_sources,
                            portable=args.portable_seal, sysml_binary=args.sysml_binary)
            print(json.dumps({"engineId": manifest["engineId"], "files": len(manifest["files"]), 'engine':str(args.seal)}))
            return 0
        if args.read:
            if reviews is not None:
                from gambit_smp.research_request import inspect_request
                result = inspect_request(ROOT.resolve(), args.read.resolve(), reviews)
                print(json.dumps(present_observation(result), indent=2))
            elif args.step is not None:
                from gambit_smp.step_checkpoint import observe_journal
                proof, _, _, _ = observe_journal(ROOT, args.read, args.step)
                print(json.dumps(proof, indent=2))
            else:
                result = inspect(args.read.resolve(), input_archive=args.input_archive,
                                 include_resumption=True)
                print(json.dumps(present_observation(result), indent=2))
            return 0
        if args.export_producer:
            from gambit_smp.completed_producer import export_reference
            if args.out is None or args.step is None:
                parser.error("--export-producer requires --step and a fresh research Evidence --out")
            print(json.dumps(export_reference(ROOT, args.export_producer, args.step, args.out,
                                              input_archive=args.input_archive, ancestry=args.ancestry), indent=2))
            return 0
        if args.export_runtime:
            from gambit_smp.runtime_artifact import supervised_export
            if args.out is None or args.step is None:
                parser.error("--export-runtime requires --step and a fresh archive --out")
            print(json.dumps(supervised_export(ROOT, args.export_runtime.resolve(), args.step, args.out), indent=2))
            return 0
        root = ROOT.resolve()
        if "/" in args.run or args.run.endswith(".recipe.json"):
            selected = source_path(root, args.run)
            load(root, selected)
        else:
            selected = discover(root).get(args.run)
        if selected is not None and args.repair_plan is not None and args.out is None:
            from gambit_smp.research_repair import review_repair
            from gambit_smp.task_entry import _observation_address
            recipe, steps = load(root, selected)
            inputs = {name: digest(root / name) for name in [selected.relative_to(root).as_posix(), *recipe['inputs']]}
            _, task = _observation_address.get()
            review = review_repair(root, args.prior.resolve(), recipe, steps, inputs,
                                   manifest_paths(args.engine.resolve()), args.repair_plan, task=task)
            print(json.dumps(review, indent=2))
            return 0 if review['status'] == 'eligible' else 2
        if selected is None or args.engine is None or args.out is None:
            parser.error("--run requires a declared recipe, --engine seal, and --out run directory")
        receipt = run_sealed(root, selected, args.out, args.engine.resolve(), prior=args.prior, allow_native=True,
                             **({'repair_plan': args.repair_plan} if args.repair_plan else {}))
        print(json.dumps(present_observation(launch_summary(receipt, args.out))))
        if args.repair_plan and receipt.get('repair', {}).get('status') not in {'verified', 'probe-observed'}:
            return 2
        return 0 if receipt["outcome"] == "PASS" else 2
    except (OSError, ValueError, KeyError, TypeError) as error:
        print("RESEARCH-DENY " + str(error), file=sys.stderr)
        return 2


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('research')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('research', main))
