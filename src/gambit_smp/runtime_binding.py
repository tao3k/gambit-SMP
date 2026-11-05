"""Consume one declared C/header runtime cut in the existing leased build.

The existing ExecutionContext, native-stage gate and Make own execution. This
module supplies source/artifact admission; it creates no runner or build profile.
"""
from pathlib import Path
import os
import hashlib
import json
from gambit_smp.native_development import (
    compile_phases, generated_inventory, generation_inputs,
    invalidate_native_outputs,
)
from gambit_smp.workspace import checkpoint_build_source


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def authenticate_predecessor(source, parent, rebuild_missing=()):
    """Rebuild declared missing native outputs; never reuse them as evidence.

    Generated inputs and the pinned bootstrap compiler remain mandatory. The
    caller retains the failed-step receipt authorizing this recovery set.
    Existing products must still match, even on a recovery path.
    """
    if parent.get('complete') is not True:
        raise ValueError('complete exact predecessor required')
    _authenticate_products(Path(source), parent, rebuild_missing)


def authenticate_distribution_predecessor(source, parent, *, generation_checkpoint=None):
    """Authenticate a two-pass producer and stock core without suite admission."""
    if (parent.get("producerComplete") is not True
            or parent.get("phaseCounts") != {f"phase{i}": 2 for i in range(1, 5)}
            or parent.get("phaseCountsInherited", False) is not (generation_checkpoint is not None)
            or parent.get("heapRaised") is not False
            or parent.get("waitExtended") is not False
            or parent.get("error")):
        raise ValueError("executed two-pass distribution producer required")

    required = ("source-bootstrap", "clean-objects", "dummy-seed", "stock-core")
    handoff = parent.get("bootstrapInputHandoff")
    if handoff is None:
        required = ("install-real-seed", *required)
    else:
        predecessor = parent.get("sourcePredecessor", {})
        if (handoff.get("source") != "failed predecessor preserved input gsc/gsc"
                or handoff.get("currentOutputRestored") is not False
                or not parent.get("bootstrapSeedSha256")
                or handoff.get("sha256") != parent["bootstrapSeedSha256"]
                or predecessor.get("completedStagesReused") is not False
                or predecessor.get("nativeAdmissionInherited") is not False
                or any(row.get("stage") == "install-real-seed"
                       for row in (*parent.get("checks", ()), *parent.get("commands", ())))):
            raise ValueError("exact preserved bootstrap input handoff required")
    checks = [row for row in parent.get("checks", ()) if row.get("stage") in required]
    commands = [row for row in parent.get("commands", ()) if row.get("stage") in required]
    if generation_checkpoint is not None:
        checks, commands = _bind_resumed_generation(source, parent, generation_checkpoint)
    if (tuple(row["stage"] for row in checks) != required
            or tuple(row["stage"] for row in commands) != required
            or any(row.get("complete") is not True or row.get("exit") != 0
                   or row.get("timeout") is not False for row in checks)
            or any(row.get("exit") != 0 or row.get("timeout") is not False
                   or row.get("parentReaped") is not True
                   or row.get("processGroupQuiescent") is not True for row in commands)):
        raise ValueError("complete ordered and quiescent producer stages required")

    artifacts = parent.get("artifacts", {})
    if not {"gsi/gsi", "gsc/gsc", "gsc-boot", "lib/libgambit.a"} <= set(artifacts):
        raise ValueError("complete distribution artifact inventory required")
    _authenticate_products(Path(source), parent, ())


def _bind_resumed_generation(source, parent, binding):
    from gambit_smp.native_capabilities import bootstrap_phase_counts

    path, expected_sha = binding
    path = Path(path)
    raw = path.read_bytes()
    if path.is_symlink() or hashlib.sha256(raw).hexdigest() != expected_sha:
        raise ValueError("generation checkpoint identity changed")
    generation = json.loads(raw)
    headers = generation.get("generatedSnapshotHeaders", {})
    identity = ("baseRevision", "targetTree", "phaseCounts", "bootstrapSeedSha256",
                "configurationFlags", "generatedArtifacts", "priorArtifacts")
    if (parent.get("composedStages") is not True
            or parent.get("resumedFromTree") != parent.get("targetTree")
            or generation.get("generationCheckpoint") is not True
            or generation.get("generatedSnapshot") != "generated-c"
            or generation.get("phaseCountsInherited") or generation.get("error")
            or generation.get("heapRaised") is not False or generation.get("waitExtended") is not False
            or generation.get("wholeLimitSeconds") != 600 or parent.get("wholeLimitSeconds") != 600
            or any(name not in generation or generation[name] != parent.get(name) for name in identity)
            or generation["bootstrapSeedSha256"] != generation["priorArtifacts"].get("gsc/gsc")
            or set(headers) != {"include/gambit.h", "include/config.h"}
            or any(sha(Path(source) / name) != expected for name, expected in headers.items())):
        raise ValueError("resume does not bind the same generated source and configuration")

    generation_checks = generation["checks"]
    generation_commands = generation["commands"]
    stock_stages = ("clean-objects", "dummy-seed", "stock-core")
    if (tuple(row["stage"] for row in generation_commands) != ("install-real-seed", "source-bootstrap")
            or tuple(row["stage"] for row in generation_checks) != ("install-real-seed", "source-bootstrap")
            or tuple(row["stage"] for row in parent["commands"]) != stock_stages
            or tuple(row["stage"] for row in parent["checks"]) != ("source-bootstrap", *stock_stages)
            or parent["checks"][0].get("executed") is not False
            or parent["checks"][0].get("priorSeconds") != generation_checks[-1]["seconds"]):
        raise ValueError("resume requires separately executed generation and stock core")
    bootstrap_stdout = None
    for command in generation_commands:
        for stream in ("stdout", "stderr"):
            log = path.with_name(command["stage"] + "." + stream)
            raw_log = log.read_bytes()
            if log.is_symlink() or hashlib.sha256(raw_log).hexdigest() != command[stream + "Sha256"]:
                raise ValueError("generation process stream identity changed")
            if command["stage"] == "source-bootstrap" and stream == "stdout":
                bootstrap_stdout = raw_log
    if bootstrap_phase_counts(bootstrap_stdout.decode(errors="replace")) != parent["phaseCounts"]:
        raise ValueError("resumed bootstrap phase counts differ from executed output")
    checks = generation_checks + parent["checks"][1:]
    seconds = [row["seconds"] for row in checks]
    if not all(0 < value <= 600 for value in seconds) or sum(seconds) > 600:
        raise ValueError("resumed distribution exceeds the original stage budget")
    return checks, generation_commands + parent["commands"]


def _authenticate_products(source, parent, rebuild_missing):
    missing = set(rebuild_missing)
    if (not missing <= set(parent.get('artifacts', {}))
            or 'gsc-boot' in missing):
        raise ValueError('only declared native outputs may be rebuilt')
    for group in ('canonicalSources', 'artifacts', 'generatedArtifacts'):
        if not parent.get(group):
            raise ValueError('complete predecessor source and product identities required')
        for name, expected in parent[group].items():
            path = Path(name)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError("workspace-relative predecessor identity required")
            if group == 'artifacts' and name in missing and not (source/name).exists():
                continue
            if sha(source/name) != expected:
                raise ValueError('predecessor drift: '+name)


def runtime_delta(source, incoming, parent):
    """Validate a complete source transition before any write or retirement.

    None retires a registered source, never a generated input or completed
    product. Absence is part of the resulting identity, not a cache miss.
    """
    source = Path(source)
    protected = set(parent.get('artifacts', {})) | set(parent.get('generatedArtifacts', {}))
    for name, raw in incoming.items():
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or str(path) != name:
            raise ValueError('contained runtime input required')
        if name in protected:
            raise ValueError('runtime delta cannot replace a product or generated input')
        cursor = source
        for part in path.parts:
            cursor = cursor/part
            if cursor.is_symlink():
                raise ValueError('runtime inputs cannot follow aliases')
        if raw is None:
            if name not in parent.get('canonicalSources', {}):
                raise ValueError('only a registered source can retire')
        elif not isinstance(raw, bytes):
            raise ValueError('source transition requires bytes or explicit retirement')
    return incoming


def consume(ctx, source, incoming, parent, *, make_jobs, rebuild_missing=()):
    source = Path(source)
    authenticate_predecessor(source, parent, rebuild_missing)
    runtime_delta(source, incoming, parent)
    generated = generated_inventory(source)
    generation = generation_inputs(source)
    for name, raw in incoming.items():
        path = Path(name)
        if path.is_absolute() or '..' in path.parts:
            raise ValueError('contained runtime input required')
        target = source/path
        if target.is_symlink():
            raise ValueError('runtime inputs cannot follow aliases')
        if raw is None:
            target.unlink()
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists() or target.read_bytes() != raw:
            target.write_bytes(raw)
    # Native-only source changes reuse the original effective configuration.
    # Config-status consumes the existing manifest; no configure probes run.
    manifest=(source/'include/gambit.h.in').read_text().splitlines()
    fragments=[line.removeprefix('#include "').removesuffix('"') for line in manifest]
    config='include/gambit.h:'+':'.join('include/'+name for name in fragments)
    outputs={name:((source/name).read_bytes(),(source/name).stat()) for name in ('include/gambit.h','lib/makefile')}
    ctx.env.update(CONFIG_FILES='lib/makefile '+config, CONFIG_HEADERS='')
    try:
        ctx.require('runtime-config-status',['./config.status'],source,90)
    finally:
        ctx.env.pop('CONFIG_FILES',None);ctx.env.pop('CONFIG_HEADERS',None)
    changed=[]
    for name,(raw,stat) in outputs.items():
        if (source/name).read_bytes()==raw:
            os.utime(source/name,ns=(stat.st_atime_ns,stat.st_mtime_ns))
        else:
            changed.append(name)
    invalidated=invalidate_native_outputs(source,changed,parameters_changed='include/gambit.h' in changed)
    try:
        logs=compile_phases(ctx,source,[ctx.tools['make'],'-j'+str(make_jobs),'GAMBOPT=p1'])
        if generated_inventory(source)!=generated or generation_inputs(source)!=generation:
            raise ValueError('native consumer changed its generated inputs')
        for name,raw in incoming.items():
            if ((source/name).exists() if raw is None else (source/name).read_bytes()!=raw):
                raise ValueError('runtime source changed during compilation: '+name)
        return dict(complete=True,producerComplete=True,qualificationKind='native-runtime',
                    canonicalSources={name:sha(source/name) for name in
                        (set(parent['canonicalSources'])|set(incoming))
                        if name not in incoming or incoming[name] is not None},
                    retiredSources={name:parent['canonicalSources'][name]
                                    for name,raw in incoming.items() if raw is None},
                    artifacts={name:sha(source/name)for name in parent['artifacts']},
                    generatedArtifacts=generated,generatedInputsReused=True,
                    generationPhasesRequested=[],nativeOutputsInvalidated=invalidated,
                    changedConfiguration=changed,
                    missingNativeOutputsRebuilt=list(rebuild_missing),
                    phaseNames=list(logs),sourceCopies=0,heapRaised=False,waitExtended=False)
    finally:
        checkpoint_build_source(source)


def prepare_consumers(source, parent, updates):
    """Compose declared test sources with an unchanged native producer.

    A consumer source change is not native compilation or product reuse. Reject
    unknown source drift before writing; runtime and generated inputs stay exact.
    The caller owns the existing workspace lease and checkpoints the transition.
    """
    source = Path(source)
    if parent.get('complete') is not True:
        raise ValueError('complete native producer required')
    for name in updates:
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or path.parts[0] != 'tests':
            raise ValueError('consumer transition is restricted to declared tests')
        cursor = source
        for part in path.parts:
            cursor = cursor/part
            if cursor.is_symlink():
                raise ValueError('consumer source alias refused')
    for group in ('canonicalSources', 'artifacts', 'generatedArtifacts'):
        for name, expected in parent[group].items():
            observed = sha(source/name)
            accepted = {expected}
            if group == 'canonicalSources' and name in updates:
                accepted.add(hashlib.sha256(updates[name]).hexdigest())
            if observed not in accepted:
                raise ValueError('consumer predecessor drift: '+name)
    transitions = {}
    for name, raw in updates.items():
        target = source/name
        if target.is_symlink():
            raise ValueError('consumer source alias refused')
        expected = hashlib.sha256(raw).hexdigest()
        if name not in parent['canonicalSources'] and target.exists() and sha(target) != expected:
            raise ValueError('unknown unregistered consumer source: '+name)
        if not target.exists() or sha(target) != expected:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(raw)
        transitions[name] = expected
    return transitions


def request_observation(output, composed):
    """Require the unchanged full workload; parse body timing independently."""
    import re
    import math
    if '(result . 4096)' not in output:
        raise ValueError('complete request population required')
    if composed and 'REQUEST-SERVICE-COMPOSED-PASS count=4096 resumes=8192 explicit-gc=16 mailbox-identity drained' not in output:
        raise ValueError('complete multi-shot/GC/mailbox population required')
    match=re.search(r'\(real-time \. ([^)]*)\)',output)
    if not match:
        raise ValueError('native body timing required')
    value=float(match[1])
    if value<0 or not math.isfinite(value):
        raise ValueError('finite body timing required')
    allocated=re.search(r'\(bytes-allocated \. ([^)]*)\)',output)
    return dict(complete=True,requests=4096,resumes=8192 if composed else 0,
                explicitCollections=16 if composed else 0,bodySeconds=value,
                rawBytesAllocated=float(allocated[1]) if allocated else None,
                allocationCounterAdmitted=False)


def generated_accessors(ctx, source, generated):
    """Observe the compiler's final macro selection, not header text order.

    The caller owns the existing workspace lease and generated-C custody.
    Preprocessing emits no object and does not alter the configured profile.
    """
    import re
    source, generated = Path(source), Path(generated)
    output = ctx.require('binding-preprocessor', [
        ctx.tools['gcc'], '-E', '-dM', '-I'+str(source/'include'), generated,
    ], generated.parent, 30)
    expected = {'___PRM': '___binding_primitive',
                '___GLO': '___binding_global',
                '___BEGIN_COD': 'context->binding_view'}
    observed = {}
    for name, accessor in expected.items():
        match = re.search(r'^#define '+name+r'(?:\([^\n]*?\))?\s+([^\n]+)$',
                          output, re.M)
        if match is None or accessor not in match[1]:
            raise ValueError('generated binding accessor not selected: '+name)
        observed[name] = match[1]
    if re.search(r'^#define ___ENTER_BINDINGS\b', output, re.M):
        raise ValueError('retired per-host binding activation is still selected')
    return dict(complete=True, generatedSha256=sha(generated),
                headerSha256=sha(source/'include/gambit.h'), macros=observed)
