"""Transport a completed source-core generation, never resume a failed build.

The archive is a trusted-host observation, not a signature or retry permission.
Consumers bind its bytes as a Recipe input and independently review tests.
"""
import hashlib
import io
import json
import posixpath
from pathlib import Path, PurePosixPath
import tarfile
import time

from gambit_smp.framework import digest, relative


SCHEMA = "gambit-source-core-artifact.v1"


def export_deadline(run, outer):
    from gambit_smp.recipes import read_json
    from gambit_smp.research_kernel import clock_epoch
    header_path = run / "run-header.json"
    reference = outer["journal"]
    if reference["path"] != str(header_path) or digest(header_path) != reference["sha256"]:
        raise ValueError("immutable producer clock header required")
    header = read_json(header_path)
    epoch = clock_epoch()
    started, deadline = header["startedMonotonic"], header["deadlineMonotonic"]
    import math
    if (epoch is None or header["clockEpoch"] != epoch or header["engineId"] != outer["engineId"]
            or header["inputs"] != outer["inputs"] or header["budgetSeconds"] != outer["budgetSeconds"]
            or any(type(value) not in (int, float) or not math.isfinite(value) for value in (started, deadline))
            or abs(deadline - started - outer["budgetSeconds"]) > 0.000001):
        raise ValueError("same-boot original build deadline required; no clock reset")
    if time.monotonic() >= deadline:
        raise TimeoutError("original build deadline expired before artifact export")
    return started, deadline


def source_core_ancestry(rows):
    """The archive and retained phase share one native type/configuration contract."""
    from gambit_smp.step_checkpoint import ancestry, seed_ancestry
    core = rows[-1]
    if (core["capability"] != "gambit.source-core"
            or set(core["outputs"]) != {"runtime", "identity"}
            or core.get("claim") != "source-regenerated-core-not-full-two-pass-bootstrap"
            or core["outputs"]["runtime"]["type"] != "source-runtime"
            or core["outputs"]["identity"]["type"] != "runtime-identity"):
        raise ValueError("source-core cannot be replaced by a seed or full-bootstrap claim")
    if core.get("effectiveConcurrency") != {"smp": True, "multipleVMs": True, "multipleThreadedVMs": True}:
        raise ValueError("final source-core has no effective three-flag observation")
    if (set(core["configurationFiles"]) != {"include/gambit.h", "lib/makefile"}
            or any(core["outputs"]["runtime"]["identity"].get(name, {}).get("sha256") != sha
                   for name, sha in core["configurationFiles"].items())):
        raise ValueError("final configuration bytes differ from the exported generation")
    configured, materialized = seed_ancestry(ancestry(rows, core["arguments"]["runtime"]["step"]))
    flags = {"--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"}
    commands = [row for row in configured['commands'] if row['stage'] == 'configure']
    if not commands:
        reused = configured.get('configurationReuse', {})
        if (reused.get('schema') != 'gambit-configure-reuse.v1' or
                any(reused.get('files', {}).get(name) != sha
                    for name, sha in configured.get('configurationFiles', {}).items())):
            raise ValueError('reused configuration must bind current generated files')
        raw = reused.get('receiptBytes', '')
        receipt = json.loads(raw) if raw else {}
        if (hashlib.sha256(raw.encode()).hexdigest() != reused.get('receiptSha256')
                or receipt.get('state') != 'OBSERVED' or receipt.get('stage') != 'configure'
                or receipt.get('exit') != 0 or receipt.get('timeout') is not False
                or receipt.get('parentReaped') is not True or receipt.get('processGroupQuiescent') is not True):
            raise ValueError('reused configuration lacks its actual process observation')
        commands = reused.get('commands', [])
        if len(commands) != 1 or any(receipt.get(key) != item for key, item in commands[0].items()):
            raise ValueError('reused configure command differs from its process observation')
    if len(commands) != 1 or commands[0].get('exit') != 0 or commands[0].get('timeout') is not False:
        raise ValueError('one completed actual configure command or its bound reuse proof required')
    if not flags <= set(commands[0]["argv"]):
        raise ValueError("all three concurrency flags required in actual configure command")
    if configured.get("effectiveConcurrency") != {"smp": True, "multipleVMs": True, "multipleThreadedVMs": True}:
        raise ValueError("effective three-flag configuration was not established")
    return configured, materialized


def checked_manifest(value):
    from gambit_smp.step_checkpoint import ancestry, content_id
    if value.get("schema") != SCHEMA:
        raise ValueError("typed source-core archive required")
    outer = json.loads(value["outerReceipt"])
    child = json.loads(value["childReceipt"])
    engine = value["engineManifest"]
    proof = value["checkpoint"]
    if (outer.get("schema") != "sealed-research-run.v1" or child.get("schema") != "evidence-recipe-run.v1"
            or outer.get("executionLaunched") is not True or outer.get("recipe") != child.get("recipe")
            or proof.get("schema") != "successful-step-checkpoint.v1" or proof.get("campaignOutcome") != "PASS"
            or proof.get("runtimeAdmitted") is not False or proof.get("resumptionAuthorized") is not False
            or hashlib.sha256(value["outerReceipt"].encode()).hexdigest() != proof["outerReceiptSha256"]
            or hashlib.sha256(value["childReceipt"].encode()).hexdigest() != proof["childReceiptSha256"]
            or outer.get("childReceiptSha256") != proof["childReceiptSha256"]
            or outer.get("outcome") != "PASS" or child.get("outcome") != "PASS"
            or outer.get("parentReaped") is not True or outer.get("processGroupQuiescent") is not True
            or outer.get("timeout") is not False or outer.get("exit") != 0
            or child.get("inputsStable") is not True or outer.get("engineId") != proof["engineId"]):
        raise ValueError("completed quiescent producer and exact receipts required")
    from gambit_smp.recipes import budget
    import math
    budget(outer["budgetSeconds"])
    if ("timeoutPolicy" in outer or type(outer.get("wholeSeconds")) not in (int, float)
            or not math.isfinite(outer["wholeSeconds"]) or not 0 < outer["wholeSeconds"] <= outer["budgetSeconds"]):
        raise ValueError("completed fixed-wall-budget producer required; no timer-policy conversion")
    if (content_id({key: item for key, item in engine.items() if key != "engineId"}) != proof["engineId"]
            or engine["engineId"] != proof["engineId"]
            or engine["hostTools"]["gcc"]["sha256"] != value["compilerSha256"]):
        raise ValueError("producer engine/compiler manifest changed")
    if (value["logs"].get("receipt.json") != proof["outerReceiptSha256"]
            or value["logs"].get("run/receipt.json") != proof["childReceiptSha256"]
            or any(value["logs"].get(name) != sha for name, sha in outer.get("artifacts", {}).items())
            or "journal" in outer and value["logs"].get("run-header.json") != outer["journal"]["sha256"]):
        raise ValueError("original producer receipt/header/launch evidence binding differs")
    rows = ancestry(child["steps"], proof["step"])
    if ([{"id": row["id"], "observationContentId": content_id(row)} for row in rows] != proof["ancestry"]
            or content_id(rows[-1]["outputs"]) != proof["outputsContentId"]):
        raise ValueError("source-core dependency closure changed")
    for row in rows:
        for command in row.get("commands", []):
            for path_key, sha_key in (("log", "logSha256"), ("stdoutPath", "stdoutSha256"), ("stderrPath", "stderrSha256")):
                name = command[path_key]
                if (Path(name).name != name or
                        value["logs"].get("run/" + row["id"] + "/" + name) != command[sha_key]):
                    raise ValueError("original command log/stream binding missing or changed")
    core = rows[-1]
    _, materialized = source_core_ancestry(rows)
    if (value["runtimeIdentity"] != json.loads(value["identityBytes"])
            or hashlib.sha256(value["identityBytes"].encode()).hexdigest() != core["outputs"]["identity"]["sha256"]
            or value["files"] != core["outputs"]["runtime"]["identity"]
            or value["sourceIdentity"] != materialized["outputs"]["source"]["identity"]
            or value["sourceLock"] != materialized["arguments"]["sourceLock"]
            or value["sourceLockSha256"] != outer["inputs"].get(value["sourceLock"])
            or value.get("runtimeAdmitted") is not False or value.get("resumptionAuthorized") is not False):
        raise ValueError("archive provenance, type or full inventory differs")
    return outer, child, rows


def export(root, run, step, out):
    from gambit_smp.step_checkpoint import observe
    from gambit_smp.recipes import artifact_path, tree_identity
    if out.resolve().is_relative_to(root.resolve() / "evidence"):
        raise ValueError("runtime archives are local/CI outputs, not Evidence source assets")
    proof, outer, rows, selected, engine = observe(root, run, step)
    started, deadline = export_deadline(run, outer)
    by_id = {row["id"]: row for row in rows}
    seed = by_id[selected["arguments"]["runtime"]["step"]]
    from gambit_smp.step_checkpoint import seed_ancestry, ancestry
    _, source = seed_ancestry(ancestry(rows, seed["id"]))
    runtime = artifact_path(run / "run", selected["outputs"]["runtime"], root=root)
    identity = artifact_path(run / "run", selected["outputs"]["identity"], root=root)
    value = {"schema": SCHEMA, "checkpoint": proof,
             "outerReceipt": (run / "receipt.json").read_text(),
             "childReceipt": (run / "run/receipt.json").read_text(),
             "identityBytes": identity.read_text(), "runtimeIdentity": json.loads(identity.read_text()),
             "files": tree_identity(runtime), "sourceIdentity": source["outputs"]["source"]["identity"],
             "sourceLock": source["arguments"]["sourceLock"],
             "sourceLockSha256": outer["inputs"][source["arguments"]["sourceLock"]],
             "compilerSha256": engine["hostTools"]["gcc"]["sha256"], "engineManifest": engine,
             "runtimeAdmitted": False, "resumptionAuthorized": False}
    # Complete original stream/process logs travel with the generation, outside Git.
    artifact_roots = [artifact_path(run / "run", descriptor, root=root)
                      for row in rows for descriptor in row.get("outputs", {}).values() if "identity" in descriptor]
    logs = {path.relative_to(run).as_posix(): path for path in run.rglob("*")
            if path.is_file() and not path.is_symlink()
            and path.suffix in {".log", ".stdout", ".stderr", ".json"}
            and not any(path.is_relative_to(directory) for directory in artifact_roots)}
    value["logs"] = {name: digest(path) for name, path in logs.items()}
    checked_manifest(value)
    if time.monotonic() >= deadline:
        raise TimeoutError("original build budget exhausted before artifact export")
    out.parent.mkdir(parents=True, exist_ok=True)
    try:
        with out.open("xb") as stream, tarfile.open(fileobj=stream, mode="w", dereference=False) as archive:
            raw = json.dumps(value, sort_keys=True, allow_nan=False).encode()
            info = tarfile.TarInfo("manifest.json")
            info.size, info.mode = len(raw), 0o644
            archive.addfile(info, io.BytesIO(raw))
            archive.add(runtime, arcname="runtime")
            for name, path in logs.items():
                archive.add(path, arcname="evidence/" + name, recursive=False)
        if tree_identity(runtime) != value["files"] or any(digest(path) != value["logs"][name] for name, path in logs.items()):
            raise ValueError("producer changed during artifact export")
    except BaseException:
        # Preserve a failed export; never overwrite/reuse it as a generation.
        raise
    archive_sha = digest(out)
    combined = time.monotonic() - started
    if time.monotonic() > deadline:
        raise TimeoutError("artifact export exceeded the unchanged build budget")
    return {"schema": SCHEMA, "sha256": archive_sha, "checkpoint": proof,
            "buildAndExportSeconds": combined, "budgetSeconds": outer["budgetSeconds"],
            "runtimeAdmitted": False, "resumptionAuthorized": False}


def supervised_export(root, run, step, out):
    """Run the producer's sealed transport under its original hard deadline."""
    import os
    from dataclasses import asdict
    from gambit_smp.recipes import read_json
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.process_observation import capture
    from gambit_smp.host_environment import execution_environment
    outer = read_json(run / "receipt.json")
    _, deadline = export_deadline(run, outer)
    engine = Path(outer["engine"])
    manifest = manifest_paths(engine)
    if manifest["files"].get("python/gambit_smp/runtime_artifact.py") != digest(Path(__file__)):
        raise ValueError("runtime export requires the matching sealed transport implementation")
    out = out.resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    request = out.with_suffix(".export-request.json")
    with request.open("x") as stream:
        json.dump({"root": str(root.resolve()), "run": str(run.resolve()),
                   "step": step, "out": str(out)}, stream)
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        raise TimeoutError("original build budget exhausted before export worker launch")
    result = capture([manifest["hostTools"]["python"]["path"], "-I", "-B", str(engine / "runner.py"),
                      "runtime-export", str(request)], root, remaining,
                     execution_environment(root.resolve(), os.environ))
    receipt = out.with_suffix(".export-receipt.json")
    with receipt.open("x") as stream:
        json.dump({"scope": "artifact-transport-only", "processBudgetSeconds": remaining,
                   "producerDeadlineMonotonic": deadline, "runtimeAdmitted": False, **asdict(result)}, stream, indent=2)
    if result.exit != 0 or result.timeout or result.group_quiescent is not True:
        raise ValueError("runtime export worker failed/expired/unquiescent; see " + str(receipt))
    if time.monotonic() > deadline:
        raise TimeoutError("original build deadline exhausted during export teardown")
    return json.loads(result.stdout)


def archive_manifest(archive, *, verify_runtime=False):
    """Authenticate inventory and retained observations without unpacking trees."""
    members = archive.getmembers()
    names = set()
    links = set()
    for member in members:
        parts = PurePosixPath(member.name)
        if (parts.is_absolute() or ".." in parts.parts or str(parts) != member.name
                or member.name in names or member.islnk() or member.mode & ~0o777
                or not (member.isfile() or member.isdir() or member.issym())):
            raise ValueError("unsafe or duplicate artifact archive member")
        names.add(member.name)
        if member.issym():
            link = PurePosixPath(member.linkname)
            resolved = posixpath.normpath(str(parts.parent / link))
            if (link.is_absolute() or not member.name.startswith("runtime/")
                    or not resolved.startswith("runtime/")):
                raise ValueError("artifact link must remain inside its runtime")
            links.add(parts)
    if any(parent in links for name in names for parent in PurePosixPath(name).parents):
        raise ValueError('artifact entry writes through a symlink ancestor')
    if "manifest.json" not in names or not archive.getmember("manifest.json").isfile():
        raise ValueError("regular artifact manifest required")
    value = json.load(archive.extractfile("manifest.json"))
    checked_manifest(value)
    expected = {"manifest.json", "runtime", *["runtime/" + name for name in value["files"]],
                *["evidence/" + name for name in value["logs"]]}
    if names != expected:
        raise ValueError("archive member inventory differs from declared full inventory")
    for name, sha in value['logs'].items():
        member = archive.getmember('evidence/' + name)
        if not member.isfile() or hashlib.file_digest(archive.extractfile(member), 'sha256').hexdigest() != sha:
            raise ValueError('original evidence log changed')
    if verify_runtime:
        for name, row in value['files'].items():
            member = archive.getmember('runtime/' + name)
            if 'sha256' in row:
                matches = (member.isfile() and member.mode == row['mode']
                           and hashlib.file_digest(archive.extractfile(member), 'sha256').hexdigest() == row['sha256'])
            elif 'link' in row:
                matches = member.issym() and member.linkname == row['link']
            else:
                matches = member.isdir()
            if not matches:
                raise ValueError('reproduction archive runtime content differs from its inventory')
    return value


def unpack(path, destination, *, retained_runtime=None, context=None, metadata_only=False):
    """Reject aliases, extra members and special files before extraction."""
    from gambit_smp.recipes import tree_identity
    if destination.exists():
        raise ValueError("fresh artifact destination required")
    with tarfile.open(path) as archive:
        value = archive_manifest(archive)
        members = archive.getmembers()
        if context is not None:
            from gambit_smp.artifact_storage import extract_archive
            extract_archive(path,destination,context,stage='runtime-extract',
                            omit_runtime=retained_runtime is not None or metadata_only)
        else:
            destination.mkdir()
            selected = members if retained_runtime is None and not metadata_only else [member for member in members
                           if member.name != 'runtime' and not member.name.startswith('runtime/')]
            archive.extractall(destination, members=selected, filter="data")
    if not metadata_only or retained_runtime is not None:
        actual = tree_identity(destination / 'runtime' if retained_runtime is None else retained_runtime)
        observed = actual if retained_runtime is None else {name:actual.get(name) for name in value['files']}
        if observed != value["files"]:
            raise ValueError("runtime path, mode, link or content drift")
    if any(digest(destination / "evidence" / name) != sha for name, sha in value["logs"].items()):
        raise ValueError("original evidence log changed")
    return value


def producer_generation(root, slot, value, current):
    """Authenticate an explicitly pinned old seal; never execute its Python.

    This transports completed bytes, not an interrupted stage or retry grant.
    Source, configuration, tool and output checks in consume remain mandatory.
    """
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.recipes import fields
    reference = slot.get('producerEngine')
    if reference is None:
        if current['files'] != value['engineManifest']['files']:
            raise ValueError('different producer implementation requires its explicit sealed generation')
        return dict(kind='same-implementation', engineId=value['engineManifest']['engineId'])
    fields(reference, ('path', 'engineId'))
    path = Path(reference['path'])
    if path.is_absolute() or '..' in path.parts or path.parts[:1] != ('.cache',):
        raise ValueError('pinned producer seal must belong to this project Cache')
    producer = manifest_paths(relative(root, path.as_posix()))
    original = json.loads(value['outerReceipt'])
    if (producer != value['engineManifest'] or producer['engineId'] != reference['engineId']
            or original['engineId'] != reference['engineId']):
        raise ValueError('pinned original producer generation differs from the archive')
    return dict(kind='pinned-completed-generation', engineId=producer['engineId'],
                consumerEngineId=current['engineId'], runtimeAdmitted=False, resumptionAuthorized=False)


def validate_import(args, inputs):
    from gambit_smp.recipes import fields
    from gambit_smp.native_capabilities import reference
    fields(args, ("source", "archive"))
    reference(args["source"])
    if args["archive"] not in inputs or not args["archive"].endswith(".json"):
        raise ValueError("declared typed runtime input descriptor required")


def import_steps(ctx):
    plan = getattr(ctx, 'planned_steps', ctx.receipt.get('plannedSteps', ()))
    imports = [step for step in plan if step['capability'] == 'gambit.runtime-import'
               and step['arguments']['source']['step'] == ctx.directory.name]
    reference = dict(step=ctx.directory.name, output='source')
    def consumes(value):
        if isinstance(value, dict):
            return value == reference or any(consumes(item) for item in value.values())
        return isinstance(value, (list, tuple)) and any(consumes(item) for item in value)
    if imports and any(step['capability'] != 'gambit.runtime-import' and consumes(step['arguments']) for step in plan):
        raise ValueError('import source projection cannot serve a mutable source consumer')
    return imports


def reuse_import_source(args, ctx):
    """The existing materializer borrows authenticated producer bytes for imports."""
    imports = import_steps(ctx)
    if not imports:
        return None
    archives = {step['arguments']['archive'] for step in imports}
    if len(archives) != 1:
        raise ValueError('one completed generation required for an import source')
    runtime, value, _, storage = prepare_import(archives.pop(), ctx)
    if args['sourceLock'] != value['sourceLock']:
        raise ValueError('consumer source lock differs from the completed generation')
    return {'outputs': ctx.publish('source', 'source-tree', runtime),
            'sourceReuse': source_projection(value, storage),
            'claim': 'authenticated-producer-source-projection-not-native-admission'}


def source_projection(value, storage):
    from gambit_smp.step_checkpoint import content_id
    transport = 'checkpointSha256' if 'checkpointSha256' in storage else 'archiveSha256'
    return dict(schema='completed-import-source.v1', sourceLockSha256=value['sourceLockSha256'],
                sourceIdentity=content_id(value['sourceIdentity']), **{transport: storage[transport]})


def prepare_stage_import(slot, path, ctx):
    """Borrow the exact completed source-core phase, even if later testing failed."""
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.recipes import fields, source_path, artifact_path, tree_identity, read_json
    from gambit_smp.step_checkpoint import observe_stage_record, content_id
    from gambit_smp.reasoning_history import read_execution_checkpoint, execution_checkpoint_head
    from gambit_smp.artifact_storage import checked_workspace_state
    from gambit_smp.workspace import task_output
    from gambit_smp.suite_primitives import check_runtime
    reference = slot.get('producerEngine')
    if not isinstance(reference, dict):
        raise ValueError('stage consumption requires its explicitly pinned producer seal')
    fields(reference, ('path', 'engineId'))
    engine_path = Path(reference['path'])
    if engine_path.is_absolute() or '..' in engine_path.parts or engine_path.parts[:1] != ('.cache',):
        raise ValueError('pinned producer seal must belong to this project Cache')
    producer = manifest_paths(relative(ctx.root, engine_path.as_posix()))
    if producer['engineId'] != reference['engineId']:
        raise ValueError('pinned producer generation identity changed')
    proof, header, rows, run = observe_stage_record(ctx.root, path, producer)
    _, materialized = source_core_ancestry(rows)
    core = rows[-1]
    lock = materialized['arguments']['sourceLock']
    if (digest(source_path(ctx.root, lock)) != header['inputs'].get(lock)
            or digest(Path(ctx.tools['gcc'])) != producer['hostTools']['gcc']['sha256']):
        raise ValueError('consumer source or compiler differs from completed phase')
    selected_ids = {row['id'] for row in rows}
    prefix = read_execution_checkpoint(ctx.root, run)
    paths = [path, run / 'run-header.json', relative(ctx.root, reference['path']) / 'engine.json']
    for entry in prefix['records']:
        if entry['payload'].get('step', {}).get('id') not in selected_ids:
            continue
        paths.append(Path(entry['path']))
        paths.extend(Path(name) if Path(name).is_absolute() else ctx.root / name for name in entry['inputs'])
        paths.extend(Path(name) for name in entry['payload']['toolInputs'])
        paths.extend(Path(name) for name in entry['payload']['step'].get('observedInputs', {}))
    for row in rows:
        for descriptor in row.get('outputs', {}).values():
            if 'identity' in descriptor:
                if 'stateEvidence' not in descriptor:
                    raise ValueError('phase ancestry lacks retained workspace evidence')
                checked_workspace_state(ctx.root, descriptor['stateEvidence'], descriptor['identity'])
                paths.append(relative(ctx.root, descriptor['stateEvidence']['path']))
    output = core['outputs']['runtime']
    if 'workspace' not in output:
        raise ValueError('phase import requires its existing managed producer; no duplicate fallback')
    runtime = artifact_path(run / 'run', output, root=ctx.root)
    if task_output(ctx.root, runtime) != runtime:
        raise ValueError('completed phase belongs to another task or process')
    observed = tree_identity(runtime)
    if observed != output['identity']:
        raise ValueError('completed phase runtime drift; no duplicate fallback')
    runtime = ctx.lease_workspace(runtime, observed)
    identity_path = artifact_path(run / 'run', core['outputs']['identity'], root=ctx.root)
    if digest(identity_path) != core['outputs']['identity']['sha256']:
        raise ValueError('completed phase runtime identity changed')
    identity_bytes = identity_path.read_text()
    runtime_identity = json.loads(identity_bytes)
    check_runtime(runtime, runtime_identity)
    from gambit_smp.upstream_tests import preflight_import
    make_scope = preflight_import(ctx, runtime)
    if execution_checkpoint_head(ctx.root, run) != proof['prefixIdentity']:
        raise ValueError('producer prefix changed during phase consumption')
    ctx.bind([*paths, identity_path, source_path(ctx.root, lock)])
    current = manifest_paths(Path(ctx.receipt['engine']['path']))
    value = dict(checkpoint=proof, sourceLock=lock, sourceLockSha256=header['inputs'][lock],
        sourceIdentity=materialized['outputs']['source']['identity'], files=output['identity'],
        runtimeIdentity=runtime_identity, identityBytes=identity_bytes, producerBudgetSeconds=header['budgetSeconds'])
    generation = dict(kind='pinned-completed-stage', engineId=producer['engineId'],
        consumerEngineId=current['engineId'], runtimeAdmitted=False, resumptionAuthorized=False)
    return runtime, value, generation, dict(managed=True, warm=True, mode='same-producer-workspace',
        workspace=str(runtime), sourceContentId=content_id(output['identity']), checkpointSha256=digest(path),
        makeScopePreflight=make_scope, copiedFiles=0)


def prepare_import(name, ctx):
    from gambit_smp.recipes import source_path, tree_identity, read_json, fields
    from gambit_smp.suite_primitives import check_runtime
    from gambit_smp.step_checkpoint import content_id
    if ctx.receipt.get('workspacePolicy') != 'in-place':
        raise ValueError('runtime reuse requires in-place maintained workspace policy')
    descriptor = source_path(ctx.root, name)
    slot = read_json(descriptor)
    fields(slot, ("schema", "path"), ('producerEngine',))
    if (slot["schema"] != "runtime-artifact-input.v1" or not isinstance(slot["path"], str)
            or Path(slot["path"]).is_absolute() or ".." in Path(slot["path"]).parts
            or ".git" in Path(slot["path"]).parts or Path(slot['path']).suffix not in {'.tar', '.json'}):
        raise ValueError("repository-relative runtime artifact input required")
    incoming = ctx.root / slot["path"]
    if any(path.is_symlink() for path in (incoming, *incoming.parents) if path.is_relative_to(ctx.root)):
        raise ValueError("runtime artifact input must not traverse aliases")
    archive = relative(ctx.root, slot["path"])
    if not archive.is_file():
        raise ValueError("runtime artifact input unavailable or aliased")
    ctx.bind([descriptor, archive])
    if archive.suffix == '.json':
        return prepare_stage_import(slot, archive, ctx)
    before = digest(archive)
    with tarfile.open(archive) as stream:
        value = archive_manifest(stream)
        child = json.loads(value['childReceipt'])
        tools = child['toolInputs']
        member = 'evidence/run/' + tools['path']
        if value['logs'].get('run/' + tools['path']) != tools['sha256']:
            raise ValueError('producer tool inventory changed')
        tool_inputs = json.load(stream.extractfile(member))
        core = next(step for step in child['steps'] if step['id'] == value['checkpoint']['step'])
        output = core['outputs']['runtime']
        location = None
        if 'workspace' in output:
            member = 'run/' + output['path']
            if value['logs'].get(member) != output.get('locationSha256'):
                raise ValueError('managed producer location is not bound by archive provenance')
            location = json.load(stream.extractfile('evidence/' + member))
            if location != dict(schema='managed-workspace-location.v1', workspace=output['workspace']):
                raise ValueError('managed producer location differs from completed output')
    ctx.remaining()
    from gambit_smp.research_kernel import manifest_paths
    current = manifest_paths(Path(ctx.receipt["engine"]["path"]))
    generation = producer_generation(ctx.root, slot, value, current)
    if 'producerEngine' in slot:
        ctx.bind([relative(ctx.root, slot['producerEngine']['path']) / 'engine.json'])
    original = json.loads(value["outerReceipt"])
    paths = [source_path(ctx.root, name) for name in original["inputs"]]
    if any(digest(path) != original["inputs"][path.relative_to(ctx.root).as_posix()] for path in paths):
        raise ValueError("producer source inputs changed")
    ctx.bind(paths)
    if not tool_inputs or len(tool_inputs) != tools["count"]:
        raise ValueError("complete producer tool inventory required")
    for name, sha in tool_inputs.items():
        tool = Path(name)
        if not tool.is_absolute() or digest(tool) != sha:
            raise ValueError("producer tool bytes differ on artifact consumer")
    ctx.bind([Path(name) for name in tool_inputs])
    if (digest(source_path(ctx.root, value['sourceLock'])) != value['sourceLockSha256']
            or digest(Path(ctx.tools['gcc'])) != value['compilerSha256']):
        raise ValueError("consumer source or compiler differs from completed generation")
    runtime = None
    if location is not None:
        from gambit_smp.workspace import bounded, owned_build_reference
        candidate = bounded(ctx.root, location['workspace'])
        from gambit_smp.artifact_storage import fixture_root
        fixture_root(ctx.root, candidate)
        if candidate.exists():
            if owned_build_reference(ctx.root, candidate, 'gambit-core') != candidate:
                raise ValueError('completed producer belongs to another work item')
            runtime = ctx.lease_workspace(candidate, tree_identity(candidate))
    warm = runtime is not None
    mode = 'same-producer-workspace'
    if runtime is None:
        from gambit_smp.workspace import build_output, sync_build_source
        from gambit_smp.artifact_storage import extract_archive
        # Archive envelope/log changes do not create another native generation.
        work = build_output(ctx.root, 'gambit-core', compiler=ctx.tools['gcc'],
                            flags=['completed-runtime-import.v1', content_id(value['files'])])
        runtime = work / 'source'
        runtime.mkdir(exist_ok=True)
        state_path = work / 'source-state.json'
        state = read_json(state_path) if state_path.is_file() else {}
        links = {name: row['link'] for name, row in state.get('pending', {}).items()
                 if state.get('phase') == 'updating' and isinstance(row, dict) and 'link' in row}
        ctx.lease_workspace(runtime, tree_identity(runtime, broken_links=links or None), broken_links=links or None)
        warm = state.get('phase') in {'building', 'ready'}
        # Empty staging is only a delta carrier; runtime bytes install once.
        staged = ctx.directory / 'import-staging'
        staged.mkdir()
        transfer=None if warm else lambda: extract_archive(archive,runtime,ctx,stage='runtime-install',
            runtime_only=True,existing_inputs=value['files'])
        sync_build_source(ctx.root, work, staged, inventory=value['files'],initial_transfer=transfer)
        staged.rmdir()
        mode = 'retained-import-workspace' if warm else 'installed-import-workspace'
    observed = tree_identity(runtime)
    if {name: observed.get(name) for name in value['files']} != value['files']:
        raise ValueError('completed producer runtime path, mode, link or content drift; no duplicate fallback')
    check_runtime(runtime, value["runtimeIdentity"])
    from gambit_smp.upstream_tests import preflight_import
    make_scope = preflight_import(ctx, runtime)
    if digest(archive) != before:
        raise ValueError("runtime archive changed during consumption")
    return runtime, value, generation, dict(managed=True, warm=warm, mode=mode, workspace=str(runtime),
        sourceContentId=content_id(value['files']), archiveSha256=before,
        makeScopePreflight=make_scope,
        copiedFiles=0 if warm else sum('sha256' in row for row in value['files'].values()))


def consume(args, ctx):
    from gambit_smp.recipes import tree_identity
    runtime, value, generation, storage = prepare_import(args['archive'], ctx)
    source = ctx.artifact(args['source'], 'source-tree')
    source_step = next(row for row in ctx.receipt['steps'] if row['id'] == args['source']['step'])
    proof = source_projection(value, storage)
    projected = source_step.get('sourceReuse') == proof and source == runtime
    if (source_step['capability'] != 'gambit.materialize'
            or source_step['arguments']['sourceLock'] != value['sourceLock']
            or (not projected and tree_identity(source) != value['sourceIdentity'])):
        raise ValueError('consumer source differs from completed generation')
    identity = ctx.directory / 'identity.json'
    identity.write_text(value['identityBytes'])
    return {"outputs": {**ctx.publish("runtime", "source-runtime", runtime),
                        **ctx.publish("identity", "runtime-identity", identity)},
            "producerCheckpoint": value["checkpoint"],
            'producerGeneration': generation,
            'workspaceReuse': storage,
            "producerBudgetSeconds": value['producerBudgetSeconds'] if 'producerBudgetSeconds' in value
                                     else json.loads(value["outerReceipt"])["budgetSeconds"],
            "claim": "completed-source-core-reuse-not-bootstrap-or-retry-permission",
            "runtimeAdmitted": False, "resumptionAuthorized": False}
