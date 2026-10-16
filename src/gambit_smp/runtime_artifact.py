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

from gambit_smp.framework import digest


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


def checked_manifest(value):
    from gambit_smp.step_checkpoint import ancestry, content_id, seed_ancestry
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
    command = next(row for row in configured["commands"] if row["stage"] == "configure")
    if not flags <= set(command["argv"]):
        raise ValueError("all three concurrency flags required in actual configure command")
    if configured.get("effectiveConcurrency") != {"smp": True, "multipleVMs": True, "multipleThreadedVMs": True}:
        raise ValueError("effective three-flag configuration was not established")
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


def unpack(path, destination):
    """Reject aliases, extra members and special files before extraction."""
    from gambit_smp.recipes import tree_identity
    if destination.exists():
        raise ValueError("fresh artifact destination required")
    with tarfile.open(path) as archive:
        members = archive.getmembers()
        names = set()
        for member in members:
            parts = PurePosixPath(member.name)
            if (parts.is_absolute() or ".." in parts.parts or str(parts) != member.name
                    or member.name in names or member.islnk()
                    or not (member.isfile() or member.isdir() or member.issym())):
                raise ValueError("unsafe or duplicate artifact archive member")
            names.add(member.name)
            if member.issym():
                link = PurePosixPath(member.linkname)
                resolved = posixpath.normpath(str(parts.parent / link))
                if (link.is_absolute() or not member.name.startswith("runtime/")
                        or not resolved.startswith("runtime/")):
                    raise ValueError("artifact link must remain inside its runtime")
        if "manifest.json" not in names or not archive.getmember("manifest.json").isfile():
            raise ValueError("regular artifact manifest required")
        value = json.load(archive.extractfile("manifest.json"))
        checked_manifest(value)
        expected = {"manifest.json", "runtime", *["runtime/" + name for name in value["files"]],
                    *["evidence/" + name for name in value["logs"]]}
        if names != expected:
            raise ValueError("archive member inventory differs from declared full inventory")
        destination.mkdir()
        archive.extractall(destination, filter="data")
    if tree_identity(destination / "runtime") != value["files"]:
        raise ValueError("runtime path, mode, link or content drift")
    if any(digest(destination / "evidence" / name) != sha for name, sha in value["logs"].items()):
        raise ValueError("original evidence log changed")
    return value


def validate_import(args, inputs):
    from gambit_smp.recipes import fields
    from gambit_smp.native_capabilities import reference
    fields(args, ("source", "archive"))
    reference(args["source"])
    if args["archive"] not in inputs or not args["archive"].endswith(".json"):
        raise ValueError("declared typed runtime input descriptor required")


def consume(args, ctx):
    from gambit_smp.recipes import source_path, tree_identity, read_json, fields
    from gambit_smp.framework import relative
    from gambit_smp.suite_primitives import check_runtime
    descriptor = source_path(ctx.root, args["archive"])
    slot = read_json(descriptor)
    fields(slot, ("schema", "path"))
    if (slot["schema"] != "runtime-artifact-input.v1" or not isinstance(slot["path"], str)
            or Path(slot["path"]).is_absolute() or ".." in Path(slot["path"]).parts
            or ".git" in Path(slot["path"]).parts or not slot["path"].endswith(".tar")):
        raise ValueError("repository-relative runtime artifact input required")
    incoming = ctx.root / slot["path"]
    if any(path.is_symlink() for path in (incoming, *incoming.parents) if path.is_relative_to(ctx.root)):
        raise ValueError("runtime artifact input must not traverse aliases")
    archive = relative(ctx.root, slot["path"])
    if not archive.is_file():
        raise ValueError("runtime artifact input unavailable or aliased")
    ctx.bind([descriptor, archive])
    before = digest(archive)
    value = unpack(archive, ctx.directory / "generation")
    ctx.remaining()
    from gambit_smp.research_kernel import manifest_paths
    current = manifest_paths(Path(ctx.receipt["engine"]["path"]))
    if current["files"] != value["engineManifest"]["files"]:
        raise ValueError("artifact producer and consumer implementation/provider differ")
    original = json.loads(value["outerReceipt"])
    paths = [source_path(ctx.root, name) for name in original["inputs"]]
    if any(digest(path) != original["inputs"][path.relative_to(ctx.root).as_posix()] for path in paths):
        raise ValueError("producer source inputs changed")
    ctx.bind(paths)
    child = json.loads(value["childReceipt"])
    tools = child["toolInputs"]
    original_tools = relative(ctx.directory / "generation/evidence/run", tools["path"])
    if digest(original_tools) != tools["sha256"]:
        raise ValueError("producer tool inventory changed")
    tool_inputs = read_json(original_tools)
    if not tool_inputs or len(tool_inputs) != tools["count"]:
        raise ValueError("complete producer tool inventory required")
    for name, sha in tool_inputs.items():
        tool = Path(name)
        if not tool.is_absolute() or digest(tool) != sha:
            raise ValueError("producer tool bytes differ on artifact consumer")
    ctx.bind([Path(name) for name in tool_inputs])
    source = ctx.artifact(args["source"], "source-tree")
    source_step = next(row for row in ctx.receipt["steps"] if row["id"] == args["source"]["step"])
    if (source_step["capability"] != "gambit.materialize"
            or source_step["arguments"]["sourceLock"] != value["sourceLock"]
            or digest(source_path(ctx.root, value["sourceLock"])) != value["sourceLockSha256"]
            or tree_identity(source) != value["sourceIdentity"]
            or digest(Path(ctx.tools["gcc"])) != value["compilerSha256"]):
        raise ValueError("consumer source or compiler differs from completed generation")
    runtime = ctx.directory / "generation/runtime"
    check_runtime(runtime, value["runtimeIdentity"])
    identity = ctx.directory / "identity.json"
    identity.write_text(value["identityBytes"])
    if digest(archive) != before:
        raise ValueError("runtime archive changed during consumption")
    return {"outputs": {**ctx.publish("runtime", "source-runtime", runtime),
                        **ctx.publish("identity", "runtime-identity", identity)},
            "producerCheckpoint": value["checkpoint"],
            "producerBudgetSeconds": json.loads(value["outerReceipt"])["budgetSeconds"],
            "claim": "completed-source-core-reuse-not-bootstrap-or-retry-permission",
            "runtimeAdmitted": False, "resumptionAuthorized": False}
