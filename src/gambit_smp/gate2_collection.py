"""Focused observations from a selected committed Make generation."""

from pathlib import Path
import os
import re
import shlex
import struct
import sys

from gambit_smp.framework import digest, relative


CAPABILITY = "gambit.gate2-collect"
RECIPE = "family6-gate2-collection"
RULES = "evidence/dsl/gate2-collection.ss"
REPORT = "gate2-collection.json"
EMISSION = "emit-gvm"
_MH_MAGIC_64 = 0xFEEDFACF
_LC_SEGMENT_64 = 0x19
_LC_UUID = 0x1B
_LC_CODE_SIGNATURE = 0x1D


def link_identity_spans(blob):
    """Bytes a Darwin relink may replace without changing the linked image.

    ld64 mints a new UUID, and the ad-hoc signature that covers it can change
    length. The signature segment's file size and the signature command's data
    size are the header fields that record that length. Every other byte stays
    put.
    """
    if len(blob) < 32 or struct.unpack_from("<I", blob, 0)[0] != _MH_MAGIC_64:
        return None
    ncmds, sizeofcmds = struct.unpack_from("<II", blob, 16)
    offset, spans = 32, []
    signature = None
    segments = []
    for _ in range(ncmds):
        if offset + 8 > len(blob):
            return None
        command, size = struct.unpack_from("<II", blob, offset)
        if size < 8 or offset + size > len(blob):
            return None
        if command == _LC_UUID and size == 24:
            spans.append((offset + 8, offset + 24))
        elif command == _LC_SEGMENT_64 and size >= 72:
            file_size = struct.unpack_from("<Q", blob, offset + 48)[0]
            file_offset = struct.unpack_from("<Q", blob, offset + 40)[0]
            segments.append((file_offset, file_offset + file_size, offset + 48))
        elif command == _LC_CODE_SIGNATURE and size >= 16:
            data_offset, data_size = struct.unpack_from("<II", blob, offset + 8)
            end = data_offset + data_size
            if data_offset > len(blob) or end > len(blob):
                return None
            signature = (data_offset, end)
            spans.append((data_offset, end))
            spans.append((offset + 12, offset + 16))
        offset += size
    if offset != 32 + sizeofcmds or signature is None:
        return None
    covered = [field for start, end, field in segments if start <= signature[0] < end]
    if len(covered) != 1:
        return None
    spans.append((covered[0], covered[0] + 8))
    return tuple(sorted(spans))


def same_linked_image(actual, expected):
    """True when two links differ only by a Darwin UUID and its signature."""
    if actual == expected:
        return True
    actual_spans = link_identity_spans(actual)
    expected_spans = link_identity_spans(expected)
    if actual_spans is None or expected_spans is None:
        return False

    common = min(len(actual), len(expected))
    def coverage(spans, start, end):
        merged = []
        for first, last in spans:
            first, last = max(first, start), min(last, end)
            if first >= last:
                continue
            if merged and first <= merged[-1][1]:
                first, previous_end = merged.pop()
                last = max(last, previous_end)
            merged.append((first, last))
        return merged

    excluded = coverage(actual_spans, 0, common)
    if excluded != coverage(expected_spans, 0, common):
        return False
    actual_bytes, expected_bytes = memoryview(actual), memoryview(expected)
    cursor = 0
    for start, end in excluded:
        if actual_bytes[cursor:start] != expected_bytes[cursor:start]:
            return False
        cursor = end
    if actual_bytes[cursor:common] != expected_bytes[cursor:common]:
        return False
    length = max(len(actual), len(expected))
    longer_spans = actual_spans if len(actual) > len(expected) else expected_spans
    return length == common or coverage(longer_spans, common, length) == [(common, length)]


def validate(args, inputs):
    from gambit_smp.gate2_evidence import HANDLER_OBJECTS, IMAGE_OBJECTS, SITES, require
    from gambit_smp.gate2_native import KIND
    from gambit_smp.recipes import fields

    subjects = {"link-map": IMAGE_OBJECTS, "handler-inputs": HANDLER_OBJECTS, "scheme-gvm": SITES,
                EMISSION: {unit + ".scm" for unit, *_ in SITES.values()}, KIND: SITES}
    fields(args, ("run", "gsiSha256", "receiptSha256", "kind", "subject"), ("step", "correspondence", "witness"))
    require(all(isinstance(value, str) and value for value in args.values()), "explicit Gate 2 operands required")
    require(all(re.fullmatch(r"[0-9a-f]{64}", args[key]) for key in ("gsiSha256", "receiptSha256")),
            "exact GSI and producer receipt digests required")
    require(args["subject"] in subjects.get(args["kind"], ()), "unknown Gate 2 collection subject")
    if args["kind"] in {"scheme-gvm", KIND}:
        require(args.get("correspondence") in inputs,
                "Scheme/GVM collection requires a declared correspondence input")
    else:
        require("correspondence" not in args, "native collection uses only the selected Make action")
    require((args.get("witness") in inputs and args["witness"].endswith(".json"))
            if args["kind"] == KIND else "witness" not in args,
            "native-frame collection requires a sealed witness declaration")


def project(root, run, target, report, *, step=None, correspondence=None, collect, subject=None, witness=None):
    """Project any caller-selected subset of the ASCENT collection relation."""
    from gambit_smp.artifact_storage import observation_root
    from gambit_smp.gate2_evidence import require
    from gambit_smp.gate2_native import KIND, validate_spec
    from gambit_smp.recipes import read_json, validate_recipe
    from gambit_smp.research_kernel import validate_graph

    observation_root(root, run)
    if collect == KIND:
        require(report.get("collectionReady"), report.get("reason", "native-frame requires retained Make lineage"))
        require(report.get("lockedPatch", {}).get("status") == "PASS",
                report.get("lockedPatch", {}).get("reason", "native-frame requires a checked source lock and patch"))
    options = report["investigation"].get("collectionOptions", [])
    selected = sorted({option["subject"] for option in options
                       if option["kind"] == collect and subject in (None, option["subject"])})
    require(selected, "ASCENT found no selected Gate 2 collection obligation for this generation")
    inputs = [RULES]
    args = dict(run=run.relative_to(root).as_posix(), gsiSha256=target,
                receiptSha256=report["producerReceiptSha256"], kind=collect)
    if step is not None:
        args["step"] = step
    if collect in {"scheme-gvm", KIND}:
        require(correspondence is not None, "provide the candidate Scheme/GVM declaration before collecting")
        args["correspondence"] = correspondence
        inputs.append(correspondence)
    if collect == KIND:
        require(witness is not None, "declare the native workload and verified emitter markers in a witness input")
        checked_sites = {site["id"] for site in report["correspondenceReview"]["sites"]
                         if site["status"] == "PASS"}
        spec = validate_spec(read_json(relative(root, witness)))
        require(spec["sourceLockSha256"] == report["sourceLock"]["sha256"],
                "native witness declares a different source lock")
        selected = [site for site in selected if site in spec["sites"] and site in checked_sites]
        require(selected, "no selected native-frame case has both complete correspondence and a witness declaration")
        args["witness"] = witness
        inputs.extend([witness, *(spec["sites"][site]["program"] for site in selected)])
        inputs = list(dict.fromkeys(inputs))
    seconds = 170 if collect == EMISSION else 60
    overhead = 90 if collect == EMISSION else 30
    steps = [dict(id=f"collect-{index}", capability=CAPABILITY, dependsOn=[], budgetSeconds=seconds,
                  arguments=dict(args, subject=item)) for index, item in enumerate(selected, 1)]
    steps.append(dict(id="evidence", capability="evidence.evaluate",
                      dependsOn=[row["id"] for row in steps], budgetSeconds=15,
                      arguments=dict(rules=[RULES], queries={"collection_step": "collection_step"},
                                     expected={}, recordedQueries=["collection_step"])))
    recipe = dict(schema="evidence-recipe.v2", id=RECIPE, scope="Focused Gate 2 evidence for one retained producer.",
                  inputs=inputs, budgetSeconds=seconds * len(selected) + overhead, steps=steps)
    validate_graph(*validate_recipe(root, recipe))
    return recipe


def replay_command(ctx, runtime, graph, action, subject, kind):
    """Replay one retained GCC action with fresh attempt-local outputs."""
    from gambit_smp.gate2_evidence import require

    workspace = graph["workspace"]
    directory = Path(action["cwd"]).relative_to(workspace)
    cwd = relative(runtime, directory.as_posix())
    gcc = Path(ctx.tools["gcc"]).resolve()
    require(digest(gcc) == action["tool"]["sha256"], "sealed GCC differs from the retained Make action")
    inputs = {}
    recorded = action["inputs"] | action.get("headersAndSources", {})
    for name, sha in recorded.items():
        path = Path(name)
        require(path.is_absolute(), "Make input path is not absolute")
        actual = relative(runtime, path.relative_to(workspace).as_posix()) if path.is_relative_to(workspace) else path
        require(digest(actual) == sha, f"Make replay input changed: {name}")
        inputs[actual] = sha
    ctx.bind([gcc, *inputs])
    args = list(action["executedArgv"])
    if kind == "handler-inputs" and args[-3:-1] == ["-MD", "-MF"]:
        del args[-3:]
    require(args.count("-o") == 1, "retained Make action requires one output")
    output_index = args.index("-o") + 1
    require(output_index < len(args) and (Path(action["cwd"]) / args[output_index]).resolve() == workspace / subject,
            "retained Make action names another output")
    require("-c" in args if kind == "handler-inputs" else "-c" not in args,
            "retained Make action has the wrong GCC mode")
    require(not any(value.startswith(("@", "-specs", "--specs", "-fplugin", "-save-temps",
                                      "-fdump", "-fprofile", "-MJ", "-MF", "-MT", "-MQ",
                                      "-Wp,", "-Wl,", "-Wa,", "-B", "-fuse-ld", "-flto"))
                    for value in args[1:]), "retained GCC action has unbounded auxiliary inputs or outputs")
    require(all(value.startswith(("-l", "-L", "-I", "-D", "-W", "-f", "-O", "-std=", "-m"))
                or value in {"-c", "-pipe", "-o", "-pthread", "-g", "-s", "-static", "-rdynamic"}
                or (not value.startswith("-") and
                    ((cwd / value).resolve() in inputs or
                     (Path(action["cwd"]) / value).resolve().as_posix() in recorded))
                for index, value in enumerate(args[1:], 1) if index != output_index),
            "focused replay requires bound file operands and supported GCC flags")
    output = ctx.directory / Path(subject).name
    args[0] = str(gcc)
    args[output_index] = str(output)
    for index, value in enumerate(args[1:], 1):
        if value.startswith(str(workspace) + "/"):
            args[index] = str(runtime / Path(value).relative_to(workspace))
        elif value.startswith(("-I" + str(workspace) + "/", "-L" + str(workspace) + "/")):
            args[index] = value[:2] + str(runtime / Path(value[2:]).relative_to(workspace))
    if kind == "link-map":
        require("linkMap" not in action, "replay expects a Make action without an attached linker map")
        sidecar = ctx.directory / "link.map"
        fmt = "darwin" if sys.platform == "darwin" else "gnu"
        args += ["-Xlinker", "-map" if fmt == "darwin" else "-Map", "-Xlinker", str(sidecar)]
    else:
        sidecar = ctx.directory / "gcc.d"
        args += ["-MD", "-MF", str(sidecar)]
    ctx.require(kind, args, cwd, ctx.remaining())
    if kind == "link-map":
        retained_path = relative(runtime, subject)
        require(digest(retained_path) == action["outputSha256"]
                and same_linked_image(output.read_bytes(), retained_path.read_bytes()),
                f"focused replay did not reproduce {subject}")
    else:
        require(digest(output) == action["outputSha256"], f"focused replay did not reproduce {subject}")
    return output, sidecar, cwd


def dependencies(raw, cwd):
    _, separator, inputs = raw.decode().replace("\\\n", " ").partition(":")
    if not separator or not inputs.strip():
        raise ValueError("GCC did not report its compile inputs")
    return {(cwd / token).resolve() for token in shlex.split(inputs)}


def emission_replay(runtime, graph, subject, directory):
    """Derive a read-only single-unit replay from the final Make emitter action."""
    from gambit_smp.gate2_evidence import SITES, require

    workspace = graph["workspace"]
    source = Path(subject)
    unit = source.with_suffix(".c").as_posix()
    action = graph["actions"]["emit", unit]
    emitter = graph["directory"] / "emitter-2/gsc-boot"
    original = action["executedArgv"]
    cwd = relative(runtime, source.parent.as_posix())
    require(Path(original[0]) == emitter and digest(emitter) == action["tool"]["sha256"]
            and Path(action["cwd"]) == workspace / source.parent,
            "frozen emitter or original module directory differs")
    options = iter(original[1:-1])
    for flag in options:
        if flag == "-prelude":
            require(bool(next(options, "")), "retained emitter prelude is missing")
        else:
            require(flag in {"-f", "-c", "-warnings", "-track-scheme", "-gvm", "-cfg"}
                    or re.fullmatch(r"-:(?:p[0-9]+,)?~~bin=\.\./bin,~~lib=\.\./lib,~~include=\.\./include", flag),
                    "retained emitter has unsupported options for focused replay")
    require(original[-1] == source.name and "-c" in original and "-f" in original,
            "focused emission requires the original single batch Scheme input")
    paths = {}
    for name, sha in action["inputs"].items():
        path = Path(name)
        require(path.is_relative_to(workspace), "retained emitter input is outside the Make tree")
        selected = relative(runtime, path.relative_to(workspace).as_posix())
        require(digest(selected) == sha, f"retained emitter input changed: {name}")
        paths[selected] = sha
    require(cwd / source.name in paths, "Make action does not bind the selected Scheme input")
    generated = relative(runtime, unit)
    require(digest(generated) == action["outputSha256"], "retained generated C changed")
    output = directory / generated.name
    argv = list(original[:-1])
    if "-gvm" not in argv:
        argv.append("-gvm")
    argv += ["-o", str(output), source.name]
    identity = dict(expectedCSha256=action["outputSha256"], emitterSha256=action["tool"]["sha256"],
                    inputs={str(path): sha for path, sha in paths.items()},
                    sites=[name for name, row in SITES.items()
                           if row[0] + ".scm" == subject])
    return argv, cwd, output, identity


def emission_outputs(output, identity):
    from gambit_smp.gate2_evidence import require

    gvm = output.with_suffix(".gvm")
    require(all(path.is_file() and not path.is_symlink() and path.stat().st_size > 0 for path in (output, gvm)),
            "the same emission did not produce both nonempty C and GVM files")
    actual = digest(output)
    return dict(identity, generatedC=output.name, generatedCSha256=actual,
                gvm=gvm.name, gvmSha256=digest(gvm),
                status="PASS" if actual == identity["expectedCSha256"] else "MISMATCH")


def collect(args, ctx):
    from gambit_smp.artifact_storage import observation_root
    from gambit_smp.gate2_evidence import (
        MEMORY_SOURCES, SITES, investigation, linked_members, require, review_retained_links,
    )
    from gambit_smp.make_lineage import action_directory
    from gambit_smp.gate2_native import KIND, replay as native_replay, run as native_run
    from gambit_smp.workspace import write

    root, kind, subject = ctx.root, args["kind"], args["subject"]
    run = relative(root, args["run"])
    observation_root(root, run)
    receipt = run / "receipt.json"
    require(digest(receipt) == args["receiptSha256"], "focused collection producer receipt changed")
    ctx.bind([receipt])

    def observe(runtime, origin, graph, report):
        require(report["producerReceiptSha256"] == args["receiptSha256"], "focused collection producer changed")
        binding = origin["bootstrap"]["makeLineage"]
        paths = [origin["run"] / binding["path"]]
        if kind not in {"scheme-gvm", KIND}:
            action_kind = {"link-map": "link", "handler-inputs": "object", EMISSION: "emit"}[kind]
            output = str(Path(subject).with_suffix(".c")) if kind == EMISSION else subject
            paths.append(action_directory(graph["directory"], 2, action_kind, output) / "receipt.json")
        ctx.bind(paths)
        if kind == "scheme-gvm":
            path = relative(root, args["correspondence"])
            ctx.bind([path])
            checked = report["correspondenceReview"]
            site = next(row for row in checked["sites"] if row["id"] == subject)
            require(site.get("schemeGvm", {}).get("status") == "PASS"
                    and digest(path) == checked["receiptSha256"],
                    site.get("reason", "selected Scheme/GVM declaration is incomplete"))
            unit = SITES[subject][0]
            ctx.bind([relative(runtime, unit + suffix) for suffix in (".scm", ".c")])
            return dict(correspondenceSha256=checked["receiptSha256"], mapping=site["schemeGvm"])
        if kind == KIND:
            from gambit_smp.recipes import source_path

            path = source_path(root, args["witness"])
            argv, env, identity = native_replay(root, runtime, origin, graph, args, path, ctx.directory, report)
            program = Path(argv[-1])
            name = program.relative_to(root).as_posix()
            inputs = ctx.receipt["inputs"]
            lookup = lambda key: inputs.get(key, inputs.get(str(source_path(root, key))))
            require(lookup(name) == identity["programSha256"]
                    and lookup(args["witness"]) == digest(path)
                    and lookup(args["correspondence"]) == identity["correspondenceSha256"],
                    "native workload is not declared in the sealed Recipe")
            lock = report["sourceLock"]["path"]
            patch = report["lockedPatch"]["path"]
            ctx.bind([path, program, Path(argv[0]), relative(root, args["correspondence"]),
                      relative(root, lock), relative(root, patch),
                      relative(root, identity["emission"]["run"]) / "receipt.json",
                      *[relative(runtime, name) for name in identity["sources"]]])
            return native_run(ctx, argv, env, identity)
        option = dict(kind=kind, subject=subject)
        require(option in investigation(report)["collectionOptions"],
                "selected Gate 2 obligation is absent from the current ASCENT review")
        if kind == EMISSION:
            argv, cwd, output, identity = emission_replay(runtime, graph, subject, ctx.directory)
            ctx.bind([Path(argv[0]), *(Path(name) for name in identity["inputs"])])
            ctx.require(EMISSION, argv, cwd, ctx.remaining())
            return emission_outputs(output, identity)
        action = graph["actions"][action_kind, subject]
        output, sidecar, cwd = replay_command(ctx, runtime, graph, action, subject, kind)
        if kind == "link-map":
            fmt = "darwin" if sys.platform == "darwin" else "gnu"
            detail = dict(format=fmt, members=[list(row) for row in linked_members(sidecar.read_bytes(), fmt)])
        else:
            observed = dependencies(sidecar.read_bytes(), cwd)
            expected = ("lib/_kernel.c",) if subject == "lib/_kernel.o" else MEMORY_SOURCES
            require({relative(runtime, name) for name in expected} <= observed,
                    "focused compile did not observe every required handler input")
            ctx.bind(observed)
            detail = dict(inputs={name: digest(relative(runtime, name)) for name in expected})
        return dict(outputSha256=digest(output), sidecar=sidecar.name, sidecarSha256=digest(sidecar),
                    **detail)

    report = review_retained_links(root, run, args["gsiSha256"], args.get("step"),
                                  correspondence=args.get("correspondence"), collect=observe)
    result = dict(schema="family6-gate2-collection.v1", producer=args,
                  makeLineageSha256=report["makeLineageSha256"], evidence=report["collection"],
                  runtimeAdmitted=False)
    path = ctx.directory / REPORT
    write(path, result)
    if kind == EMISSION:
        require(result["evidence"]["status"] == "PASS", "focused emission did not reproduce the Make C bytes")
    if kind == KIND:
        require(result["evidence"]["status"] == "PASS", "native-frame obligations remain open; see the retained trace")
    return dict(gate2Collection=result)


def collection_origin(root, out, target, step_id=None):
    """Follow a direct collection read to its single journal-bound producer."""
    from gambit_smp.gate2_evidence import require
    from gambit_smp.artifact_storage import observation_root
    from gambit_smp.ordered_stress_audit import committed_header
    from gambit_smp.recipes import decode_json
    from gambit_smp.research_kernel import bound_child_receipt

    receipt = out / "receipt.json"
    if not receipt.is_file():
        return None
    outer = decode_json(receipt.read_bytes())
    if outer.get("schema") != "sealed-research-run.v1" or not outer.get("childReceiptSha256"):
        return None
    child = bound_child_receipt(out, outer)
    if not any(row["capability"] == CAPABILITY for row in child.get("plannedSteps", child["steps"])):
        return None
    observation_root(root, out)
    require(outer["root"] == str(root), "Gate 2 collection belongs to another repository")
    header = committed_header(out, outer, child)
    references = {(args["run"], args["receiptSha256"], args["gsiSha256"], args.get("step"))
                  for row in header["declaration"]["steps"] if row["capability"] == CAPABILITY
                  for args in (row["arguments"],)}
    require(len(references) == 1, "direct Gate 2 review requires one retained collection producer")
    (producer, receipt_sha, image, step), = references
    require(image == target and (step_id is None or step is None or step == step_id),
            "direct Gate 2 collection names another image or bootstrap step")
    run = relative(root, producer)
    observation_root(root, run)
    require(run != out and digest(run / "receipt.json") == receipt_sha,
            "direct Gate 2 collection producer receipt changed")
    return run, step_id or step


def read_collection(root, out, *, expected_run=None, expected_gsi=None, expected_step=None,
                    outer=None, child=None, checkpoint=None, kinds=None):
    """Revalidate committed stage artifacts and their producer independently."""
    from gambit_smp.artifact_storage import observation_root
    from gambit_smp.gate2_evidence import (
        IMAGE_OBJECTS, MEMORY_SOURCES, READ_ERRORS, linked_members, map_objects, require, review_retained_links, sha_bytes,
    )
    from gambit_smp.ordered_stress_audit import checked_json, committed_header, step_file
    from gambit_smp.reasoning_history import read_execution_checkpoint
    from gambit_smp.recipes import decode_json
    from gambit_smp.research_kernel import bound_child_receipt
    from gambit_smp.gate2_native import KIND, TRACE, replay as native_replay, report as native_report

    result = dict(status="UNVERIFIED", steps=[], executionAuthorized=False, runtimeAdmitted=False)
    try:
        observation_root(root, out)
        outer = outer if outer is not None else decode_json((out / "receipt.json").read_bytes())
        require(outer["schema"] == "sealed-research-run.v1" and outer["root"] == str(root),
                "focused collection requires a committed Research run from this repository")
        child = child if child is not None else bound_child_receipt(out, outer)
        checkpoint = checkpoint if checkpoint is not None else read_execution_checkpoint(root, out)
        header = committed_header(out, outer, child, checkpoint=checkpoint)
        declared = [step for step in header["declaration"]["steps"] if step["capability"] == CAPABILITY
                    and (kinds is None or step["arguments"]["kind"] in kinds)]
        require(declared, "selected run declares no Gate 2 collection")
    except READ_ERRORS as error:
        return dict(result, reason=str(error))
    for planned in declared:
        args = planned["arguments"]
        row = dict(step=planned["id"], kind=args["kind"], subject=args["subject"], status="MISSING")
        result["steps"].append(row)
        try:
            validate(args, header["inputs"])
            found = [step for step in child["steps"] if step["id"] == row["step"]]
            if not found:
                raise FileNotFoundError("collection step receipt is missing")
            require(len(found) == 1, "duplicate collection step receipt")
            step, = found
            require(step["arguments"] == args and step["capability"] == CAPABILITY,
                    "collection step differs from its declaration")
            committed_header(out, outer, child, [step], checkpoint)
            mismatch_artifact = (args["kind"] in {EMISSION, KIND} and step["outcome"] in {"DENY", "TIMEOUT"}
                                 and f"{step['id']}/{REPORT}" in step["artifacts"])
            if step["outcome"] != "PASS" and not mismatch_artifact:
                row.update(status=step["outcome"], reason=step.get("reason", "collection did not complete"))
                continue
            run = relative(root, args["run"])
            require(expected_run in (None, run) and expected_gsi in (None, args["gsiSha256"]),
                    "collection belongs to a different Gate 2 candidate")
            require(digest(run / "receipt.json") == args["receiptSha256"], "collection producer receipt changed")
            directory = out / "run"
            report = checked_json(*step_file(directory, step, REPORT))
            require((report["evidence"]["status"] != "PASS" if mismatch_artifact
                     else report == step["gate2Collection"]) and report["producer"] == args
                    and report["schema"] == "family6-gate2-collection.v1",
                    "collection artifact differs from its committed receipt")
            evidence = report["evidence"]
            row["checks"] = {}

            def verify(runtime, origin, graph, current):
                require(current["makeLineageSha256"] == report["makeLineageSha256"]
                        and expected_step in (None, current["bootstrapStep"]),
                        "collection belongs to another Make lineage")
                if args["kind"] == "scheme-gvm":
                    require(header["inputs"][args["correspondence"]] == evidence["correspondenceSha256"],
                            "mapping differs from the sealed correspondence input")
                    mapping = next(site["schemeGvm"] for site in current["correspondenceReview"]["sites"]
                                   if site["id"] == args["subject"])
                    require(mapping["status"] == "PASS" and mapping == evidence["mapping"]
                            and current["correspondenceReview"]["receiptSha256"] == evidence["correspondenceSha256"],
                            "Scheme/GVM declaration changed since collection")
                    row["checks"][args["subject"]] = dict(status="PASS", check="schemeGvm")
                elif args["kind"] == KIND:
                    from gambit_smp.recipes import source_path
                    witness = source_path(root, args["witness"])
                    location = directory / step["id"]
                    argv, env, binding = native_replay(root, runtime, origin, graph, args, witness, location, current)
                    command, = step["commands"]
                    program = Path(argv[-1])
                    require(command["stage"] == KIND and command["argv"] == argv
                            and command["cwd"] == str(location)
                            and all(command["environment"].get(key) == value for key, value in env.items())
                            and header["inputs"][program.relative_to(root).as_posix()] == binding["programSha256"]
                            and digest(witness) == header["inputs"][args["witness"]]
                            and binding["correspondenceSha256"] == header["inputs"][args["correspondence"]],
                            "native-frame process or sealed workload differs")
                    emitter_receipt = relative(root, binding["emission"]["run"]) / "receipt.json"
                    require(step["observedInputs"][str(emitter_receipt)] == binding["emission"]["receiptSha256"],
                            "native-frame GVM producer differs from the observed input")
                    for name, value in binding["sources"].items():
                        require(step["observedInputs"][str(relative(runtime, name))] == value,
                                "native-frame observed input differs from the checked Make product")
                    trace, sha = step_file(directory, step, TRACE, evidence["traceSha256"])
                    require(not trace.is_symlink() and digest(trace) == sha, "native-frame trace changed")
                    measured = native_report(trace, binding, command, int(env["GAMBIT_GATE2_CASE"]))
                    if binding["image"] == "gsc/gsc":
                        product = "gate2-drive.c"
                        measured["driveCSha256"] = None
                        if f"{step['id']}/{product}" in step["artifacts"]:
                            c, c_sha = step_file(directory, step, product, evidence["driveCSha256"])
                            require(not c.is_symlink() and digest(c) == c_sha, "focused workload C changed")
                            measured["driveCSha256"] = c_sha
                        require(measured["status"] != "PASS" or measured["driveCSha256"],
                                "native compiler witness lacks its generated workload product")
                    require(measured == evidence, "native-frame verdict differs from the committed trace")
                    row["checks"].update(evidence["checks"])
                else:
                    commands = step["commands"]
                    require(len(commands) == 1 and commands[0]["stage"] == args["kind"]
                            and commands[0]["exit"] == 0 and commands[0]["timeout"] is False
                            and commands[0]["parentReaped"] is True and commands[0]["processGroupQuiescent"] is True,
                            "focused replay has no naturally completed process receipt")
                    if args["kind"] == EMISSION:
                        unit = Path(args["subject"])
                        output = directory / step["id"] / unit.with_suffix(".c").name
                        argv, cwd, output, identity = emission_replay(runtime, graph, args["subject"], output.parent)
                        require(commands[0]["argv"] == argv and commands[0]["cwd"] == str(cwd)
                                and commands[0]["streamCaptureComplete"] is True,
                                "emission process differs from the frozen Make replay")
                        require(all(step["observedInputs"][name] == sha
                                    for name, sha in (identity["inputs"] | {argv[0]: identity["emitterSha256"]}).items()),
                                "emission observed input differs from the Make action")
                        for name, sha in ((output.name, evidence["generatedCSha256"]),
                                          (output.with_suffix(".gvm").name, evidence["gvmSha256"])):
                            artifact, expected = step_file(directory, step, name, sha)
                            require(digest(artifact) == expected, f"emission artifact changed: {name}")
                        require(emission_outputs(output, identity) == evidence,
                                "recorded emission differs from the replay outputs")
                        for site in identity["sites"]:
                            row["checks"][site] = dict(status=evidence["status"], check="sameInvocationArtifacts")
                        return
                    action_kind = "link" if args["kind"] == "link-map" else "object"
                    action = graph["actions"][action_kind, args["subject"]]
                    product, sha = step_file(directory, step, Path(args["subject"]).name)
                    sidecar, sidecar_sha = step_file(directory, step, evidence["sidecar"])
                    sidecar_raw = sidecar.read_bytes()
                    produced = product.read_bytes()
                    retained_path = relative(runtime, args["subject"])
                    linked = (args["kind"] == "link-map" and digest(retained_path) == action["outputSha256"]
                              and same_linked_image(produced, retained_path.read_bytes()))
                    require(digest(product) == sha == evidence["outputSha256"]
                            and (linked or sha == action["outputSha256"])
                            and sha_bytes(sidecar_raw) == sidecar_sha == evidence["sidecarSha256"],
                            "focused replay product or sidecar identity changed")
                    if args["kind"] == "link-map":
                        members = linked_members(sidecar_raw, evidence["format"])
                        require([list(item) for item in members] == evidence["members"],
                                "link map members differ from the collection receipt")
                        workspace = graph["workspace"]
                        normalized = [(str(workspace / Path(archive).relative_to(runtime))
                                       if Path(archive).is_relative_to(runtime) else archive, member)
                                      for archive, member in members]
                        selected = map_objects(normalized, Path(action["cwd"]), workspace, graph["actions"], action)
                        for name in IMAGE_OBJECTS[args["subject"]]:
                            status = "PASS" if name in selected else "NOT_SELECTED"
                            if name in selected:
                                require(digest(relative(runtime, name)) == graph["actions"]["object", name]["outputSha256"],
                                        f"selected object bytes changed: {name}")
                            row["checks"][name] = dict(status=status, check="objectSelection")
                    else:
                        expected = ("lib/_kernel.c",) if args["subject"] == "lib/_kernel.o" else MEMORY_SOURCES
                        require(evidence["inputs"].keys() == set(expected)
                                and {relative(runtime, name) for name in expected} <=
                                    dependencies(sidecar_raw, Path(commands[0]["cwd"]))
                                and all(digest(relative(runtime, name)) == value
                                        == step["observedInputs"][str(relative(runtime, name))]
                                        for name, value in evidence["inputs"].items()),
                                "handler source inputs changed since focused compilation")
                        row["checks"][args["subject"]] = dict(status="PASS", check="handlerCompileInputs")

            review_retained_links(root, run, args["gsiSha256"], args.get("step"),
                                  correspondence=args.get("correspondence"), collect=verify)
            row.update(status=evidence["status"] if args["kind"] in {EMISSION, KIND} else "PASS",
                       evidence=evidence, gsiSha256=args["gsiSha256"], runOutcome=outer["outcome"])
        except READ_ERRORS as error:
            row.update(status="MISSING" if isinstance(error, FileNotFoundError) else "MISMATCH", reason=str(error))
    result["status"] = "PASS" if all(row["status"] == "PASS" for row in result["steps"]) else "OPEN"
    return result


def apply_observations(report, steps):
    """Project checked replay evidence into this read's investigation only."""
    from copy import deepcopy
    from gambit_smp.gate2_evidence import IMAGE_OBJECTS
    from gambit_smp.gate2_native import KIND

    view = deepcopy(report)
    replayed = {}
    for row in steps:
        if (row["kind"] == KIND and row.get("checks") and
                row.get("evidence", {}).get("correspondenceSha256")
                == view.get("correspondenceReview", {}).get("receiptSha256") and "evidence" in row):
            view.setdefault("nativeFrame", {}).setdefault(row["subject"], []).append(row["checks"])
            continue
        if row["status"] != "PASS":
            continue
        kind, subject = row["kind"], row["subject"]
        if kind == "link-map":
            link = view["linkSelection"][subject]
            if subject in replayed:
                if replayed[subject] != row["checks"]:
                    link.update(status="MISMATCH", reason="byte-identical relinks disagree on object selection")
                    for name in IMAGE_OBJECTS[subject]:
                        link["objects"][name].update(status="MISMATCH", reason=link["reason"])
                continue
            if not link.get("mapUnrecorded"):
                continue
            replayed[subject] = row["checks"]
            link.update(status="PASS", mapUnrecorded=False)
            for name, check in row["checks"].items():
                member = link["objects"][name]
                if check["status"] == "PASS":
                    member.update(status="PASS", reason="selected by a verified byte-identical focused relink")
                else:
                    member.update(status="MISSING", selection="not-selected",
                                  reason="verified focused relink did not select this object")
        elif kind == "handler-inputs":
            for link in view["linkSelection"].values():
                if link["handlerCompileInputs"][subject]["status"] == "MISSING":
                    link["handlerCompileInputs"][subject] = dict(
                        status="PASS", reason="observed by verified byte-identical focused compilation")
        elif kind == "scheme-gvm":
            correspondence = view.setdefault("correspondenceReview", {})
            sites = correspondence.setdefault("sites", [])
            site = next((item for item in sites if item["id"] == subject), None)
            mapping = row["evidence"]["mapping"]
            if site is None:
                sites.append(dict(id=subject, status="PASS", schemeGvm=mapping))
            elif site.get("schemeGvm", {}).get("status") == "PASS" and site["schemeGvm"] != mapping:
                site["schemeGvm"] = dict(status="MISMATCH", reason="verified correspondence declarations disagree")
            elif site.get("schemeGvm", {}).get("status") != "MISMATCH":
                site["schemeGvm"] = mapping
        elif kind == EMISSION:
            view.setdefault("sameInvocationEmissions", {}).setdefault(subject, []).append(row["evidence"])
    return view
