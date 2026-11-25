"""Join retained Family 6 observations without changing acceptance decisions."""

from pathlib import Path

from gambit_smp.framework import digest, relative
from gambit_smp.gate2_evidence import (
    HANDLER_OBJECTS, IMAGE_OBJECTS, SITES, investigation, linked_members, require, review_retained_links,
)
from gambit_smp.ordered_stress_audit import (
    INNER_SECONDS, WHOLE_SECONDS, checked_json, committed_header, passed_step, step_file,
)
from gambit_smp.recipes import artifact_path, fields, tree_identity


def committed_provider(root, reference):
    from gambit_smp.research_kernel import bound_child_receipt

    fields(reference, ("run", "receiptSha256", "step"))
    run = relative(root, reference["run"])
    outer = checked_json(run / "receipt.json", reference["receiptSha256"])
    require(outer["schema"] == "sealed-research-run.v1" and outer["root"] == str(root),
            "retained producer must belong to this repository")
    child = bound_child_receipt(run, outer)
    row = passed_step(child, reference["step"])
    committed_header(run, outer, child, [row])
    return run, row


def runtime_inventory(root, reference, target):
    run, row = committed_provider(root, reference)
    outputs = row["outputs"]
    require(row["capability"] == "gambit.observation-identity" and "retainedRuntime" in row["arguments"]
            and row["arguments"]["gsiSha256"] == target, "restoration receipt names another GSI")
    inventory = outputs["runtime"]["identity"]
    runtime = artifact_path(run / "run", outputs["runtime"], root=root)
    identity = outputs["identity"]
    checked = checked_json(artifact_path(run / "run", identity, root=root), identity["sha256"])
    require(checked["binarySha256"] == inventory["gsi/gsi"]["sha256"] == target
            and tree_identity(runtime) == inventory, "restored runtime differs from its committed tree")
    return runtime, inventory, identity["sha256"], row["arguments"]


def gsi_selection(root, reference, target, runtime, inventory, identity_sha):
    from gambit_smp.gate2_collection import same_linked_image

    run, row = committed_provider(root, reference)
    require(row["capability"] == "gambit.observation-identity"
            and row["arguments"]["gsiSha256"] == target
            and row["outputs"]["runtime"]["identity"] == inventory
            and row["outputs"]["identity"]["sha256"] == identity_sha,
            "GSI link replay belongs to a different runtime")
    mapping, replay = row["linkMap"], row["buildClosure"]
    base = run / "run"
    map_path, map_sha = step_file(base, row, "link.map", mapping["mapSha256"])
    replay_path, replay_sha = step_file(base, row, "gsi", mapping["replaySha256"])
    raw = map_path.read_bytes()
    require(digest(map_path) == map_sha and digest(replay_path) == replay_sha
            and mapping["sameLinkedImage"] is True
            and same_linked_image(replay_path.read_bytes(), (runtime / "gsi/gsi").read_bytes()),
            "retained GSI link map or replay image changed")
    def completed(stage):
        commands = [cmd for cmd in row["commands"] if cmd["stage"] == stage]
        require(len(commands) == 1, f"expected one process receipt for {stage}")
        command, = commands
        require(command["exit"] == 0 and command["timeout"] is False and command["parentReaped"] is True
                and command["processGroupQuiescent"] is True and command["streamCaptureComplete"] is True,
                f"{stage} has no naturally completed process receipt")
        return command

    link = completed("link-map")
    require(link["argv"][-4:] == ["-Xlinker", "-map", "-Xlinker", str(map_path)]
            and link["argv"][link["argv"].index("-o") + 1] == str(replay_path),
            "GSI link command differs from its recorded artifacts")
    members = linked_members(raw, "darwin")
    require([list(pair) for pair in members] == mapping["members"], "GSI link map members changed")
    configuration = {name: inventory[name]["sha256"] for name in ("config.status", "include/config.h")}
    require(configuration == {"config.status": replay["configStatusSha256"],
                              "include/config.h": replay["configHeaderSha256"]},
            "GSI replay configuration differs from the restored tree")
    objects = {}
    for name in IMAGE_OBJECTS["gsi/gsi"]:
        sha = inventory[name]["sha256"]
        if ("../lib/libgambit.a", Path(name).name) not in members:
            objects[name] = dict(status="MISSING", selection="not-selected", reason="absent from GSI link map")
        elif replay["objects"].get(name) != sha:
            objects[name] = dict(status="MISMATCH", reason="selected GSI object differs from the restored tree")
        else:
            command = completed("member-" + Path(name).name)
            path, stream_sha = step_file(base, row, command["stdoutPath"], command["stdoutSha256"])
            if stream_sha != sha or digest(path) != sha:
                objects[name] = dict(status="MISMATCH", reason="retained archive member bytes changed")
            else:
                objects[name] = dict(status="PASS", sha256=sha)
    return dict(status="PASS", imageSha256=target, linkMapSha256=map_sha,
                replaySha256=replay_sha, objects=objects, receipt=reference, configuration=configuration,
                compilerSha256=replay["compilerSha256"],
                scope="verified-link-replay", artifact=str(map_path.relative_to(root)))


def bootstrap_edges(root, reference, inventory):
    run, row = committed_provider(root, reference)
    binding = row["makeLineage"]
    report = {}

    def compare(runtime, origin, graph, current):
        require(origin["bootstrap"]["id"] == reference["step"], "bootstrap step changed")
        actions = graph["actions"]
        output = row["outputs"]["runtime"]["identity"]
        units = {}
        for unit in dict.fromkeys(site[0] for site in SITES.values()):
            scheme, generated, obj = (unit + suffix for suffix in (".scm", ".c", ".o"))
            try:
                emit, compile_ = actions["emit", generated], actions["object", obj]
                scheme_path = str(graph["workspace"] / scheme)
                generated_path = str(graph["workspace"] / generated)
                shas = {name: inventory[name]["sha256"] for name in (scheme, generated, obj)}
                require(emit["inputs"][scheme_path] == shas[scheme]
                        and emit["outputSha256"] == compile_["headersAndSources"][generated_path] == shas[generated]
                        and compile_["outputSha256"] == shas[obj], f"retained Make actions differ for {unit}")
                units[unit] = dict(status="PASS", files=shas, emitterSha256=emit["tool"]["sha256"])
            except KeyError as error:
                units[unit] = dict(status="MISSING", reason=f"missing retained Make field or action: {error}")
            except ValueError as error:
                units[unit] = dict(status="MISMATCH", reason=str(error))
        gsc = actions["link", "gsc/gsc"]
        require(gsc["outputSha256"] == inventory["gsc/gsc"]["sha256"], "retained GSC link differs")
        report.update(status="PASS", receipt=reference, makeLineageSha256=binding["sha256"],
                      gscSha256=gsc["outputSha256"], gsiSha256=binding["gsiSha256"], units=units,
                      objects={name: output[name]["sha256"] for name in IMAGE_OBJECTS["gsc/gsc"]},
                      handlerCompileInputs=current["linkSelection"]["gsc/gsc"]["handlerCompileInputs"])

    review_retained_links(root, run, binding["gsiSha256"], reference["step"], collect=compare)
    return report


def gsc_selection(root, reference, bootstrap):
    from gambit_smp.gate2_collection import read_collection

    fields(reference, ("run", "receiptSha256"))
    run = relative(root, reference["run"])
    checked_json(run / "receipt.json", reference["receiptSha256"])
    producer = bootstrap["receipt"]
    result = read_collection(root, run, expected_run=relative(root, producer["run"]),
                             expected_gsi=bootstrap["gsiSha256"], expected_step=producer["step"])
    require(len(result["steps"]) == 1, result.get("reason", "one GSC link-map collection is required"))
    row, = result["steps"]
    require(result["status"] == "PASS", row.get("reason", "GSC link-map collection did not verify"))
    require(row["kind"] == "link-map" and row["subject"] == "gsc/gsc", "expected a GSC link-map collection")
    require(digest(run / "receipt.json") == reference["receiptSha256"], "GSC collection receipt changed")
    objects = {}
    for name, check in row["checks"].items():
        if check["status"] == "PASS":
            objects[name] = dict(check, sha256=bootstrap["objects"][name])
        else:
            objects[name] = dict(check, status="MISSING", selection="not-selected",
                                 reason="retained GSC link did not select this object")
    return dict(status="PASS", imageSha256=bootstrap["gscSha256"], linkMapSha256=row["evidence"]["sidecarSha256"],
                objects=objects, receipt=reference, scope="verified-link-replay",
                artifact=(run / "run" / row["step"] / row["evidence"]["sidecar"]).relative_to(root).as_posix())


def handler_comparison(root, reference, restored_args, runtime, inventory, identity, selection, subject):
    from gambit_smp.gambit_build_primitives import command
    from gambit_smp.gate2_collection import dependencies
    from gambit_smp.gate2_evidence import MEMORY_SOURCES
    from gambit_smp.observation_runtime import DEFINE
    from gambit_smp.research_kernel import bound_child_receipt

    fields(reference, ("run", "receiptSha256", "step"))
    run = relative(root, reference["run"])
    outer = checked_json(run / "receipt.json", reference["receiptSha256"])
    require(outer["schema"] == "sealed-research-run.v1" and outer["root"] == str(root),
            "handler comparison must belong to this repository")
    child = bound_child_receipt(run, outer)
    rows = [row for row in child["steps"] if row["id"] == reference["step"]]
    require(len(rows) == 1, "one committed handler comparison step required")
    row, = rows
    ref = row["arguments"]["source"]
    provider = passed_step(child, ref["step"])
    committed_header(run, outer, child, [provider, row])
    require(ref["output"] == "runtime" and provider["capability"] == "gambit.observation-identity"
            and provider["arguments"] == restored_args
            and provider["outputs"]["runtime"]["identity"] == inventory
            and provider["outputs"]["identity"]["sha256"] == identity
            and artifact_path(run / "run", provider["outputs"]["runtime"], root=root) == runtime
            and row["capability"] == "gambit.object"
            and row["arguments"].get("matchRuntimeObject") is True
            and row["arguments"]["translationUnit"] == str(Path(subject).with_suffix(".c")),
            "handler comparison differs from the restored GSI or translation unit")
    if row["outcome"] != "PASS":
        return dict(status="MISSING", reason=row.get("reason", "handler comparison did not complete"), receipt=reference)
    selected = selection.get("objects", {}).get(subject, {})
    require(selected.get("status") == "PASS", "GSI object selection has not verified")
    observed = row["handlerComparison"]
    expected = selected["sha256"]
    base = run / "run"
    product, product_sha = step_file(base, row, Path(subject).name, observed["observedSha256"])
    sidecar, sidecar_sha = step_file(base, row, "gcc.d", observed["dependencySha256"])
    object_output = row["outputs"]["object"]
    require(observed["object"] == subject and observed["expectedSha256"] == expected
            and object_output["sha256"] == digest(product) == product_sha
            and digest(sidecar) == sidecar_sha, "retained handler comparison bytes changed")
    def completed(stage):
        commands = [cmd for cmd in row["commands"] if cmd["stage"] == stage]
        require(len(commands) == 1, f"expected one process receipt for {stage}")
        cmd, = commands
        require(cmd["exit"] == 0 and cmd["timeout"] is False and cmd["parentReaped"] is True
                and cmd["processGroupQuiescent"] is True and cmd["streamCaptureComplete"] is True
                and Path(cmd["cwd"]) == runtime / "lib", f"{stage} did not complete in the restored tree")
        return cmd

    dry_run = completed("object-recipe")
    cmd = completed("object-compile")
    gcc = Path(cmd["argv"][0]).resolve(strict=True)
    makefile = runtime / "lib/makefile"
    source = Path(subject).with_suffix(".c").name
    plan, plan_sha = step_file(base, row, dry_run["stdoutPath"], dry_run["stdoutSha256"])
    require(digest(plan) == plan_sha
            and digest(makefile) == row["observedInputs"][str(makefile)] == inventory["lib/makefile"]["sha256"]
            and digest(gcc) == row["observedInputs"][str(gcc)] == selection["compilerSha256"],
            "retained Make recipe, configuration or compiler changed")
    argv = command(plan.read_text(), gcc, source, product)
    if DEFINE not in argv:
        argv.insert(argv.index(source), DEFINE)
    require(cmd["argv"] == argv + ["-MD", "-MF", str(sidecar)] and "-std=c23" in argv,
            "handler compilation does not bind the completed process and outputs")
    paths = dependencies(sidecar.read_bytes(), Path(cmd["cwd"]))
    required = ("lib/_kernel.c",) if subject == "lib/_kernel.o" else MEMORY_SOURCES
    require({runtime / path for path in required} <= paths
            and observed["inputs"].keys() == {str(path) for path in paths}
            and all(digest(path) == observed["inputs"][str(path)] == row["observedInputs"][str(path)] for path in paths),
            "handler dependency closure changed")
    require(observed["status"] == ("PASS" if product_sha == expected else "MISMATCH"),
            "handler comparison status differs from its object bytes")
    return dict(status=observed["status"], scope="focused-object-reproduction", receipt=reference,
                expectedSha256=expected, observedSha256=product_sha, dependencySha256=sidecar_sha,
                compilerSha256=selection["compilerSha256"], dependencyCount=len(paths),
                runOutcome=outer["outcome"], runExceededBudget=outer["wallBudgetExceeded"],
                sources={name: observed["inputs"][str(runtime / name)] for name in required},
                reason=("focused compile reproduced the selected object"
                        if product_sha == expected else "focused compile did not reproduce the selected object"))


def incremental_sites(root, reference, runtime, inventory):
    from gambit_smp.gate2_evidence import span

    fields(reference, ("path", "sha256"))
    path = relative(root, reference["path"])
    draft = checked_json(path, reference["sha256"])
    require(draft["schema"] == "family6-gate2-incremental-observations.v1",
            "unsupported incremental Gate 2 observations")
    rows = {row["id"]: row for row in draft["sites"]}
    require(len(rows) == len(draft["sites"]) and rows.keys() <= SITES.keys(),
            "unknown or duplicate incremental Gate 2 sites")
    reports = {}
    for site, row in rows.items():
        try:
            unit, image, procedure, _, baseline = SITES[site]
            require((row["image"], row["procedure"], row["baselineSha256"]) == (image, procedure, baseline),
                    "incremental site refers to another baseline")
            scm, generated, obj = (unit + ext for ext in (".scm", ".c", ".o"))
            span((runtime / scm).read_bytes().splitlines(keepends=True), row["schemeSpan"])
            dump_ref = row["gvmDump"]
            dump = relative(path.parent, dump_ref["path"])
            require(digest(dump) == dump_ref["sha256"], "incremental GVM dump changed")
            span(dump.read_bytes().splitlines(keepends=True), row["gvmInstruction"])
            files = ((generated, "generatedCSha256"), (obj, "objectSha256"), (image, "imageSha256"))
            matching = {name: row[key] == inventory[name]["sha256"] for name, key in files}
            if matching[generated]:
                lines = (runtime / generated).read_bytes().splitlines(keepends=True)
                for region in row["regions"]:
                    span(lines, region)
            if not matching[generated]:
                gap = "candidate GVM maps to different generated C bytes"
            elif not row["gvmDumpFromLinkedEmission"]:
                gap = "candidate GVM dump is from a separate emission"
            elif not matching[obj] or not matching[image]:
                gap = "matching C region; candidate object or linked image differs"
            else:
                gap = "candidate mapping requires independent semantic review"
            reports[site] = dict(status="OPEN", schemeSpan=row["schemeSpan"], proposedGvmEdge=row["gvmEdge"],
                                 gvmDumpSha256=dump_ref["sha256"], gvmInstruction=row["gvmInstruction"],
                                 matchingArtifacts=matching,
                                 reason=gap,
                                 dumpFromLinkedEmission=row["gvmDumpFromLinkedEmission"])
        except (OSError, ValueError, KeyError, TypeError) as error:
            reports[site] = dict(status="MISMATCH", reason=str(error))
    return reports


def emission_locator(runtime, collection, row, site, locator):
    """Check a semantic review locator against the captured pair and the restored input."""
    import re
    from gambit_smp.gate2_evidence import sha_bytes, span

    fields(locator, ("schemeSpan", "gvmSpan", "gvmEdge", "regions"))
    evidence = row["evidence"]
    directory = collection / "run" / row["step"]
    c = directory / evidence["generatedC"]
    gvm = directory / evidence["gvm"]
    raw_c, raw_gvm = c.read_bytes(), gvm.read_bytes()
    require(sha_bytes(raw_c) == evidence["generatedCSha256"]
            and sha_bytes(raw_gvm) == evidence["gvmSha256"], "emission artifacts changed during locator review")
    span((runtime / site["schemeSource"]).read_bytes().splitlines(keepends=True), locator["schemeSpan"])
    gvm_lines = raw_gvm.splitlines(keepends=True)
    selected = span(gvm_lines, locator["gvmSpan"])
    first = locator["gvmSpan"]["start"]
    headers = [line.strip() for line in gvm_lines[:first - 1] if line.startswith(b"**** #<")]
    require(any(headers and headers[-1] == f"**** #<{kind} {site['procedure']}> =".encode()
                for kind in ("primitive", "procedure"))
            and not any(line.startswith(b"**** #<") for line in selected),
            "GVM span is outside the selected procedure")
    edge = locator["gvmEdge"]
    fields(edge, ("from", "to"))
    require(all(isinstance(value, str) and re.fullmatch(r"#[0-9]+", value) for value in edge.values()),
            "GVM coordinates must identify concrete block labels")
    origin, successor = (edge[key].encode() for key in ("from", "to"))
    jump = rb"^\s+jump(?:/\S+)?\s+.*\br0=" + successor + rb"(?=\s|$)"
    require(selected[0].startswith(origin + b" ") and any(re.search(jump, line) for line in selected),
            "GVM span does not identify the declared control edge")
    require(isinstance(locator["regions"], list) and locator["regions"], "generated C regions are missing")
    encoded = SITES[site["id"]][3].encode()
    c_lines = raw_c.splitlines(keepends=True)
    for region in locator["regions"]:
        lines = span(c_lines, region)
        anchor = region["anchor"].encode()
        require(anchor.endswith(encoded + b")") and anchor in [line.strip() for line in lines],
                "C span does not identify the selected procedure label")
    return dict(status="OPEN", **locator,
                reason="Scheme, GVM edge and C anchors verified; lowered effects and native handoff require review")


def retained_item12(root, declaration):
    """Return the independently verified edges and the remaining per-site obligations."""
    fields(declaration, ("schema", "gsiSha256", "restoration", "gsiLink", "bootstrap", "gscCollection"),
           ("handlerComparisons", "incrementalSites", "emissions", "nativeFrames"))
    require(declaration["schema"] == "family6-item12-retained-evidence.v1", "unsupported retained evidence declaration")
    target = declaration["gsiSha256"]
    runtime, inventory, identity, restored_args = runtime_inventory(root, declaration["restoration"], target)
    retained = restored_args["retainedRuntime"]
    result = dict(checklist=12, gsiSha256=target, runtime=str(runtime), identitySha256=identity,
                  status="OPEN", passed=False,
                  innerBudgetSeconds=INNER_SECONDS, wholeBudgetSeconds=WHOLE_SECONDS,
                  runtimeAdmitted=False, executionAuthorized=False)

    def verify(action):
        try:
            return action()
        except (OSError, ValueError, KeyError, TypeError) as error:
            missing = isinstance(error, (FileNotFoundError, KeyError))
            return dict(status="MISSING" if missing else "MISMATCH", reason=str(error))

    from gambit_smp.family6_recipes import rest_campaign_evidence

    def family_a():
        check, _ = rest_campaign_evidence(root, {k: retained[k] for k in ("run", "receiptSha256")})
        require(check["executableSha256"] == target and check["provider"] == retained["step"],
                "restoration names a different Family A provider")
        return dict(check, status="PASS")

    result["familyA"] = verify(family_a)
    bootstrap = verify(lambda: bootstrap_edges(root, declaration["bootstrap"], inventory))
    gsi = verify(lambda: gsi_selection(root, declaration["gsiLink"], target, runtime, inventory, identity))
    gsc = (verify(lambda: gsc_selection(root, declaration["gscCollection"], bootstrap))
           if bootstrap["status"] == "PASS" else dict(status="BLOCKED", reason="requires matching retained GSC link"))
    result.update(sourceLock=dict(status="MISSING", reason="no completed source-lock producer for this observation GSI"),
                  makeLineage=dict(status="MISSING", reason="no final Make action chain for the selected GSI",
                                   requiredEdges=["sourceLockToConfiguredTree", "handlerEmission",
                                                  "handlerObjectsToIndexedArchive", "indexedArchiveToExactGsi"]),
                  bootstrap=bootstrap, linkSelection={"gsi/gsi": gsi, "gsc/gsc": gsc})
    gsi_handlers = {name: dict(status="MISSING", reason="GSI link replay proves selection; compile-input receipt is missing")
                    for name in HANDLER_OBJECTS}
    comparisons = declaration.get("handlerComparisons", {})
    fields(comparisons, (), HANDLER_OBJECTS)
    for name, reference in comparisons.items():
        gsi_handlers[name] = verify(lambda: handler_comparison(
            root, reference, restored_args, runtime, inventory, identity, gsi, name))
    result["handlerCompileInputs"] = {
        "gsi/gsi": gsi_handlers,
        "gsc/gsc": {name: (bootstrap.get("handlerCompileInputs", {}).get(name, {"status": "MISSING"})
                          if gsc.get("objects", {}).get(name, {}).get("status") == "PASS"
                          else dict(status="BLOCKED", reason="GSC handler object selection is unresolved"))
                    for name in HANDLER_OBJECTS},
    }
    result["sites"] = [
        dict(id=name, procedure=procedure, image=image, object=unit + ".o",
             baselineSha256=baseline, schemeSource=unit + ".scm",
             status="OPEN",
             generatedUnit=bootstrap.get("units", {}).get(unit, {"status": "BLOCKED"}),
             objectSelection=result["linkSelection"][image].get("objects", {}).get(unit + ".o", {"status": "MISSING"}),
             handlerCompileInputs=result["handlerCompileInputs"][image],
             schemeGvm=dict(status="MISSING", reason="no retained semantic correspondence for this site",
                            requiredEdges=["schemeSpan", "gvmEdge", "loweredCRegions"]))
        for name, (unit, image, procedure, _, baseline) in SITES.items()
    ]
    if "incrementalSites" in declaration:
        candidates = verify(lambda: dict(status="OPEN", sites=incremental_sites(
            root, declaration["incrementalSites"], runtime, inventory)))
        result["incrementalSites"] = dict(candidates, receipt=declaration["incrementalSites"])
        for site in result["sites"]:
            if candidate := candidates.get("sites", {}).get(site["id"]):
                site["schemeGvm"]["candidate"] = candidate
                site["schemeGvm"]["reason"] = candidate["reason"]
    from gambit_smp.gate2_collection import EMISSION, read_collection

    def read_emission(reference):
        fields(reference, ("run", "receiptSha256"), ("locators",))
        fields(reference.get("locators", {}), (), SITES)
        require(bootstrap["status"] == "PASS", "a retained Make producer is required for emission review")
        run = relative(root, reference["run"])
        outer = checked_json(run / "receipt.json", reference["receiptSha256"])
        producer = bootstrap["receipt"]
        return read_collection(root, run, outer=outer, expected_run=relative(root, producer["run"]),
                               expected_gsi=bootstrap["gsiSha256"], expected_step=producer["step"])

    emissions = declaration.get("emissions", [])
    require(isinstance(emissions, list), "emissions must be a list of committed Research references")
    pairs_by_unit = {}
    for reference in emissions:
        collection = verify(lambda: read_emission(reference))
        result.setdefault("emissions", []).append(dict(collection, receipt={k: reference[k] for k in
                                                                             ("run", "receiptSha256")
                                                                             if isinstance(reference, dict) and k in reference}))
        for row in collection.get("steps", []):
            if row["kind"] != EMISSION:
                continue
            for site in result["sites"]:
                if site["schemeSource"] != row["subject"]:
                    continue
                unit = site["generatedUnit"]
                observed = row.get("evidence", {})
                status = row["status"]
                reason = row.get("reason", "focused C differs from the retained Make emission")
                if status == "PASS":
                    matched = unit["status"] == "PASS" and all(
                        inventory[name]["sha256"] == sha for name, sha in unit["files"].items())
                    status = "PASS" if matched else "MISMATCH"
                    reason = ("same-invocation GVM and C reproduce the matching Make unit; semantic review is open"
                              if matched else "the retained Make emission does not match this GSI/GSC tree")
                pair = dict(run=reference["run"], step=row["step"], status=status, reason=reason,
                            generatedCSha256=observed.get("generatedCSha256"), gvmSha256=observed.get("gvmSha256"))
                site["schemeGvm"].setdefault("emissions", []).append(pair)
                if status == "PASS":
                    evidence_ref = {k: pair[k] for k in ("run", "step", "generatedCSha256", "gvmSha256")}
                    captured = pairs_by_unit.setdefault(row["subject"], [])
                    if evidence_ref not in captured:
                        captured.append(evidence_ref)
                    site["schemeGvm"]["reason"] = reason
                    if locator := reference.get("locators", {}).get(site["id"]):
                        pair["locator"] = verify(lambda: emission_locator(
                            runtime, relative(root, reference["run"]), row, site, locator))
    ascent_selection = {}
    for image, link in result["linkSelection"].items():
        missing = dict(status="MISSING", reason=link.get("reason", "object selection is unresolved"))
        ascent_selection[image] = dict(
            link, finalLink=(result["makeLineage"] if image == "gsi/gsi" else
                             dict(status=bootstrap["status"], reason=bootstrap.get("reason", ""))),
            objects={name: link.get("objects", {}).get(name, missing) for name in IMAGE_OBJECTS[image]},
            handlerCompileInputs=result["handlerCompileInputs"][image])
    from gambit_smp.gate2_native import KIND, gap

    native_frames = declaration.get("nativeFrames", [])
    require(isinstance(native_frames, list), "nativeFrames must be a list of committed Research references")
    checked_native = {}
    for reference in native_frames:
        def read_native():
            fields(reference, ("run", "receiptSha256"))
            run = relative(root, reference["run"])
            outer = checked_json(run / "receipt.json", reference["receiptSha256"])
            return read_collection(root, run, outer=outer, expected_gsi=target)

        collection = verify(read_native)
        result.setdefault("nativeFrames", []).append(collection)
        for row in collection.get("steps", []):
            if row["kind"] == KIND and row.get("checks") and row.get("evidence"):
                checked_native.setdefault(row["subject"], []).append(row["checks"])
    for site in result["sites"]:
        site["nativeFrame"] = checked_native.get(site["id"], [gap(
            "no native-frame receipt for this exact GSI generation")])
    result["investigation"] = investigation(dict(linkSelection=ascent_selection, sites=result["sites"],
                                                  sameInvocationEmissions=pairs_by_unit,
                                                  nativeFrame=checked_native,
                                                  nativeFrameReason="no native-frame receipt for this exact GSI generation"))
    return result
