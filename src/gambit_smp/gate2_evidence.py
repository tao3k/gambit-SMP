"""Audit the Family 6 correspondence against the final Make link receipts."""

from functools import lru_cache
import hashlib
import os
from pathlib import Path
import re
from subprocess import CalledProcessError

from gambit_smp.framework import ROOT, digest, relative
from gambit_smp.make_lineage import action_directory
from gambit_smp.recipes import decode_json, fields


SCHEMA = "family6-gate2-correspondence.v1"
PRIMS = ("gsc/_prims", "gsc/gsc", "c#setup-prim-expanders", "c_23_setup_2d_prim_2d_expanders",
         "e2262104d093b54498756e8cec83e190fe11402e83fbe94237e4ad449a1ad53c")
PTREE = ("gsc/_ptree2", "gsc/gsc", "c#br-app", "c_23_br_2d_app",
         "54edbe817aff8cd1ff1bfeead029a4d5cb1c56a3c05dc5a17fa5490ef978a8fd")
EVAL = ("lib/_eval", "gsi/gsi", "##comp-do", "_23__23_comp_2d_do",
        "b1980ca2ff8bd5b1c610d99de11c6a5671492eaf554bc1bd88e7ae24d74dd4ef")
SITES = {f"F6-20-{number}": site for number, site in enumerate((PRIMS,) * 5 + (PTREE, EVAL), 1)}
HANDLER_OBJECTS = ("lib/_kernel.o", "lib/mem.o")
IMAGE_OBJECTS = {
    "gsc/gsc": ("gsc/_prims.o", "gsc/_ptree2.o", *HANDLER_OBJECTS),
    "gsi/gsi": ("lib/_eval.o", *HANDLER_OBJECTS),
}
MEMORY_SOURCES = ("lib/mem.c", "lib/_mem/heap-sections.inc", "lib/_mem/rc-allocation.inc")
HANDLER_SOURCES = ("lib/_kernel.scm", "lib/_kernel.c", *MEMORY_SOURCES)
READ_ERRORS = (OSError, KeyError, ValueError, TypeError)


def require(condition, reason):
    if not condition:
        raise ValueError(reason)


def sha_bytes(data):
    return hashlib.sha256(data).hexdigest()


def linked_members(raw, format_name):
    """Return the archive members selected by the linker, before section output."""
    text = raw.decode("utf-8")
    if format_name == "darwin":
        require("# Object files:" in text, "missing Darwin link-map object table")
        table = text.split("# Object files:", 1)[1].split("\n# ", 1)[0]
        paths = (match[1] for match in re.finditer(r"^\[\s*\d+\]\s+(.+)$", table, re.M))
    elif format_name == "gnu":
        marker = "Archive member included to satisfy reference by file (symbol)"
        require(marker in text, "missing GNU link-map archive selection table")
        table = text.split(marker, 1)[1].split("\n\nDiscarded input sections", 1)[0]
        table = re.split(r"\n(?:Memory Configuration|Linker script and memory map|Allocating common symbols)", table, maxsplit=1)[0]
        paths = (match[1] for match in re.finditer(r"^(.+?\.a\([^()]+\))(?=\s|$)", table, re.M))
    else:
        raise ValueError("unsupported linker map format")
    return [match.groups() for name in paths
            if (match := re.fullmatch(r"(.+\.a)\(([^()/]+)\)", name.strip()))]


def span(lines, spec):
    fields(spec, ("start", "end", "sha256"), ("anchor",))
    first, last = spec["start"], spec["end"]
    require(type(first) is int and type(last) is int and 1 <= first <= last <= len(lines),
            "line span falls outside its source")
    selected = lines[first - 1:last]
    require(sha_bytes(b"".join(selected)) == spec["sha256"], "line span digest changed")
    return selected


def issue(error, edge):
    reason = f"missing field or binding: {error}" if isinstance(error, KeyError) else str(error)
    return dict(status="MISSING" if isinstance(error, (FileNotFoundError, KeyError)) else "MISMATCH",
                edge=edge, reason=reason or "missing correspondence evidence")


def retained_source(runtime, inventory):
    @lru_cache(maxsize=None)
    def source(name):
        raw = relative(runtime, name).read_bytes()
        require(sha_bytes(raw) == inventory[name]["sha256"], f"sealed bytes changed for {name}")
        return raw

    return source


def blocked_selection(edge, reason):
    state = dict(status="BLOCKED", edge=edge, reason=reason)
    return {image: dict(state, objects={name: dict(state) for name in objects})
            for image, objects in IMAGE_OBJECTS.items()}


def check_object_source(actions, workspace, source, object_name, source_name):
    inputs = actions["object", object_name]["headersAndSources"]
    path = str(workspace / source_name)
    if path not in inputs:
        raise FileNotFoundError(f"{object_name} has no compile input receipt for {source_name}")
    sha = sha_bytes(source(source_name))
    require(inputs[path] == sha,
            f"{object_name} compiled different bytes for {source_name}")
    return sha


def audit_handler_compile_inputs(graph, source):
    """Verify the final Make compile inputs even when a link map is absent."""
    actions, workspace = graph["actions"], graph["workspace"]
    checks = {}
    for name, inputs in zip(HANDLER_OBJECTS, (("lib/_kernel.c",), MEMORY_SOURCES), strict=True):
        row = checks[name] = {}
        try:
            require(actions["object", name]["outputSha256"] == sha_bytes(source(name)),
                    f"{name} differs from its final Make object")
            inputs_sha = {path: check_object_source(actions, workspace, source, name, path) for path in inputs}
            if name == "lib/_kernel.o":
                scheme, generated = HANDLER_SOURCES[:2]
                scheme_sha = sha_bytes(source(scheme))
                emitted = actions["emit", generated]
                require(emitted["inputs"][str(workspace / scheme)] == scheme_sha
                        and emitted["outputSha256"] == inputs_sha[generated],
                        "generated kernel does not bind its Scheme handler")
                inputs_sha[scheme] = scheme_sha
            row.update(status="PASS", sources=inputs_sha)
        except READ_ERRORS as error:
            row.update(issue(error, "handlerCompileInputs"))
    return checks


def map_objects(rows, cwd, workspace, actions, link):
    direct = set(link["orderedFileArguments"])
    objects = {name: None for kind, name in actions if kind == "object" and str(workspace / name) in direct}
    for archive, member in rows:
        path = Path(os.path.normpath(cwd / archive))
        if str(path) not in direct or not path.is_relative_to(workspace):
            continue
        archive_name = path.relative_to(workspace).as_posix()
        packed = actions["archive", archive_name]
        members = [Path(name) for name in packed["orderedFileArguments"] if Path(name).name == member]
        require(len(members) == 1 and members[0].is_relative_to(workspace),
                f"{archive_name}({member}) has no unique Make object")
        name = members[0].relative_to(workspace).as_posix()
        require(name not in objects or objects[name] == archive_name, f"ambiguous linker inputs for {name}")
        objects[name] = archive_name
    return objects


def audit_link_selection(origin, graph, source):
    """Read the linker and object edges independently of semantic declarations."""
    actions, workspace = graph["actions"], graph["workspace"]
    artifacts = origin["bootstrap"]["artifacts"]

    def selected(image, link, report):
        map_ref = link.get("linkMap")
        if not map_ref:
            report["mapUnrecorded"] = True
            raise FileNotFoundError(f"{image} final Make link has no retained link map")
        path = action_directory(graph["directory"], 2, "link", image) / "link.map"
        artifact = path.relative_to(origin["run"]).as_posix()
        require(not path.is_symlink() and path.resolve().is_relative_to(graph["directory"]),
                f"{image} link map escapes the Make receipt")
        raw = path.read_bytes()
        require(sha_bytes(raw) == map_ref["sha256"] == artifacts[artifact], f"{image} link map digest changed")
        flags = ["-Xlinker", "-map" if map_ref["format"] == "darwin" else "-Map", "-Xlinker", str(path)]
        require(link["executedArgv"][-4:] == flags, f"{image} link command did not request its recorded map")
        cwd = Path(link["cwd"])
        direct = set(link["orderedFileArguments"])
        actual = {os.path.normpath(cwd / arg) for arg in link["executedArgv"][1:-4]
                  if not arg.startswith("-") and Path(arg).suffix in {".o", ".a"}}
        require(direct <= actual, f"{image} recorded link inputs are absent from its command")
        objects = map_objects(linked_members(raw, map_ref["format"]), cwd, workspace, actions, link)
        report["linkMapSha256"] = map_ref["sha256"]
        return objects

    result = {}
    handler_inputs = audit_handler_compile_inputs(graph, source)
    for image, required in IMAGE_OBJECTS.items():
        members = {name: {} for name in required}
        report = result[image] = {"objects": members, "handlerCompileInputs": handler_inputs}
        for name, row in members.items():
            if action := actions.get(("object", name)):
                row["recordedObjectSha256"] = action["outputSha256"]
        try:
            link = actions["link", image]
            report["recordedImageSha256"] = link["outputSha256"]
            require(sha_bytes(source(image)) == link["outputSha256"], f"sealed executable differs from {image} link")
            report["imageSha256"] = link["outputSha256"]
            report["finalLink"] = dict(status="PASS")
            objects = selected(image, link, report)
        except READ_ERRORS as error:
            report.update(issue(error, "link"))
            report.setdefault("finalLink", issue(error, "finalLink"))
            for row in members.values():
                row.update(status="BLOCKED", edge="link", reason=report["reason"])
            continue
        report["status"] = "PASS"
        for name, row in members.items():
            try:
                if name not in objects:
                    row["selection"] = "not-selected"
                    raise FileNotFoundError(f"{image} linker map did not select {name}")
                row.update(selection="direct" if objects[name] is None else "archive",
                           archive=objects[name])
                sha = actions["object", name]["outputSha256"]
                require(sha_bytes(source(name)) == sha, f"{name} differs from its final Make object")
                row.update(status="PASS", objectSha256=sha)
            except READ_ERRORS as error:
                row.update(issue(error, "link" if name not in objects else "object"))
    return result


def require_checked(row):
    if row["status"] == "MISSING":
        raise FileNotFoundError(row["reason"])
    require(row["status"] == "PASS", row.get("reason"))


def require_selection(selection, image, name):
    link = selection[image]
    require_checked(link["objects"][name] if link["status"] == "PASS" else link)


def review_retained_links(root, out, target_sha, step_id=None, *, correspondence=None, collect=None):
    """Compare a caller-selected committed bootstrap to an exact GSI digest."""
    from gambit_smp.completed_producer import bootstrap_ancestry
    from gambit_smp.make_lineage import audit_retained_graph
    from gambit_smp.ordered_stress_audit import checked_json, committed_header, passed_step
    from gambit_smp.recipes import artifact_path
    from gambit_smp.research_kernel import bound_child_receipt

    result = dict(targetGsiSha256=target_sha, executionLaunched=False, executionAuthorized=False,
                  runtimeAdmitted=False)
    edge = "bootstrapReceipt"
    try:
        outer_raw = (out / "receipt.json").read_bytes()
        outer = decode_json(outer_raw)
        result["producerReceiptSha256"] = sha_bytes(outer_raw)
        require(outer["schema"] == "sealed-research-run.v1" and outer["root"] == str(root),
                "review requires a sealed Research receipt from this repository")
        child = bound_child_receipt(out, outer)
        candidates = [row["id"] for row in child["steps"] if row["capability"] == "gambit.bootstrap"
                      and (step_id is None or row["id"] == step_id)]
        if not candidates:
            raise FileNotFoundError("selected run has no bootstrap step receipt")
        require(len(candidates) == 1, "select one bootstrap with a step binding")
        bootstrap = passed_step(child, candidates[0])
        committed_header(out, outer, child, [bootstrap])
        result["bootstrapStep"] = bootstrap["id"]

        edge = "makeLineage"
        binding = bootstrap["makeLineage"]
        run = out / "run"
        manifest_path = relative(run, binding["path"])
        require(binding["sha256"] == bootstrap["artifacts"][binding["path"]], "Make lineage binding differs")
        manifest = checked_json(manifest_path, binding["sha256"])
        require(manifest["schema"] == "gambit-make-lineage.v1" and len(manifest["passes"]) == 2
                and manifest["gsiSha256"] == binding["gsiSha256"]
                and bootstrap["fullTwoPassBootstrapEstablished"] is True,
                "bootstrap has no complete final Make lineage")
        result["makeLineageSha256"] = binding["sha256"]
        final = manifest["passes"][1]["actions"]
        output = bootstrap["outputs"]["runtime"]
        inventory = output["identity"]
        recorded = result["recordedImages"] = {}
        edge = "finalLink"
        for image in IMAGE_OBJECTS:
            try:
                path = action_directory(manifest_path.parent, 2, "link", image) / "receipt.json"
                sha = final[path.relative_to(manifest_path.parent).as_posix()]
                link = checked_json(relative(run, path.relative_to(run).as_posix()), sha)
                require(link["kind"] == "link" and link["pass"] == 2 and link["exit"] == 0
                        and link["output"] == image and link["outputSha256"] == inventory[image]["sha256"],
                        f"retained final Make link differs from bootstrap output {image}")
                recorded[image] = dict(status="PASS", imageSha256=link["outputSha256"], receiptSha256=sha,
                                       recordedLinkMapSha256=link.get("linkMap", {}).get("sha256"))
            except READ_ERRORS as error:
                recorded[image] = issue(error, edge)
        link_errors = [f"{image}: {row['reason']}" for image, row in recorded.items() if row["status"] != "PASS"]
        if link_errors:
            reason = " | ".join(link_errors)
            if any(row["status"] == "MISMATCH" for row in recorded.values()):
                raise ValueError(reason)
            raise FileNotFoundError(reason)
        edge = "imageIdentity"
        require(recorded["gsi/gsi"]["imageSha256"] == binding["gsiSha256"] == target_sha,
                f"selected Make generation produced GSI {binding['gsiSha256']}, requested {target_sha}")

        edge = "makeLineage"
        reference = bootstrap["arguments"]["runtime"]
        seed = passed_step(child, reference["step"])
        require(seed["id"] in bootstrap["dependsOn"]
                and bootstrap["arguments"]["identity"]["step"] == seed["id"],
                "bootstrap seed and identity refer to different producers")
        compiler = "gsc-boot" if seed["capability"] == "gambit.bootstrap-input" else "gsc/gsc"
        _, graph = audit_retained_graph(
            run, binding, target_sha, inventory, manifest["inputs"]["gccSha256"],
            seed_sha=seed["outputs"][reference["output"]]["identity"][compiler]["sha256"])
        edge = "sealedRuntime"
        runtime = artifact_path(run, output, root=root)
        origin = dict(run=run, bootstrap=bootstrap)
        source = retained_source(runtime, inventory)
        selection = audit_link_selection(origin, graph, source)
        result["linkSelection"] = selection
        result["collectionReady"] = True
        issues = [row for image in selection.values()
                  for row in (image, *image["objects"].values(), *image["handlerCompileInputs"].values())
                  if row["status"] in {"MISMATCH", "MISSING"}]
        result["status"] = ("MISMATCH" if any(row["status"] == "MISMATCH" for row in issues)
                            else "MISSING" if issues else "PASS")
        if issues:
            result["gaps"] = list(dict.fromkeys(row["reason"] for row in issues))
        if correspondence is not None:
            try:
                steps = {row["id"]: row for row in child["steps"]}
                require(len(steps) == len(child["steps"]), "bootstrap receipt has duplicate step IDs")
                _, _, materialized = bootstrap_ancestry(root, steps, bootstrap)
                lock = materialized["arguments"]["sourceLock"]
                origin["sha"] = outer["inputs"][lock]
                origin["lock"] = lock
                origin["lockedFiles"] = materialized["outputs"]["source"]["identity"]
                origin["producerInputs"] = outer["inputs"]
                result["sourceLock"] = dict(path=lock, sha256=origin["sha"])
                from gambit_smp.gate2_native import accounted_lock, checked_source
                try:
                    selected_lock = checked_source(root, result["sourceLock"], result["sourceLock"], outer["inputs"])
                    require(accounted_lock(selected_lock, origin["lockedFiles"]),
                            "materialized source differs from the lock")
                    result["lockedPatch"] = dict(status="PASS", path=selected_lock["patch"],
                                                 sha256=selected_lock["patchSha256"])
                except READ_ERRORS as error:
                    result["lockedPatch"] = issue(error, "sourceLock")
                raw = relative(root, correspondence).read_bytes()
            except READ_ERRORS as error:
                review = unavailable_correspondence(selection, issue(error, "receipt"))
            else:
                review = audit_declared_correspondence(raw, origin, graph, source, selection)
            review.pop("linkSelection")
            result["correspondenceReview"] = review
        if collect is not None:
            result["collection"] = collect(runtime, origin, graph, result)
    except READ_ERRORS as error:
        if collect is not None:
            raise
        result.update(issue(error, edge))
        result["linkSelection"] = blocked_selection(edge, result["reason"])
        if correspondence is not None:
            state = dict(status="BLOCKED", edge=edge, reason=result["reason"])
            review = unavailable_correspondence(result["linkSelection"], state)
            review.pop("linkSelection")
            result["correspondenceReview"] = review
    return result


def unavailable_correspondence(selection, state):
    return dict(state, linkSelection=selection,
                sites=[dict(id=name, image=site[1], schemeGvm=state, **state) for name, site in SITES.items()])


def audit_correspondence(root, outer, step, runtime, origin, graph):
    """Join declared semantic locators to actual compiler, object and link bytes."""
    bootstrap = origin["bootstrap"]
    inventory = bootstrap["outputs"]["runtime"]["identity"]
    source = retained_source(runtime, inventory)
    selection = audit_link_selection(origin, graph, source)
    try:
        path = step["arguments"]["orderedStress"].get("gate2Receipt")
        if path is None:
            raise FileNotFoundError("campaign does not declare a Gate 2 correspondence receipt")
        raw = relative(root, path).read_bytes()
        require(sha_bytes(raw) == outer["inputs"][path], "Gate 2 receipt differs from the sealed campaign input")
    except READ_ERRORS as error:
        return unavailable_correspondence(selection, issue(error, "receipt"))
    return audit_declared_correspondence(raw, origin, graph, source, selection)


def audit_declared_correspondence(raw, origin, graph, source, selection):
    actions, workspace = graph["actions"], graph["workspace"]
    bootstrap = origin["bootstrap"]
    inventory = bootstrap["outputs"]["runtime"]["identity"]
    result = {"status": "BLOCKED", "sites": [], "linkSelection": selection}

    @lru_cache(maxsize=None)
    def handler(image):
        bound = document["handlers"][image]
        fields(bound, ("sources", "kernelObjectSha256", "memoryObjectSha256"))
        for object_name, digest_key in zip(HANDLER_OBJECTS, ("kernelObjectSha256", "memoryObjectSha256"), strict=True):
            require_selection(selection, image, object_name)
            require_checked(selection[image]["handlerCompileInputs"][object_name])
            require(bound[digest_key] == actions["object", object_name]["outputSha256"]
                    == sha_bytes(source(object_name)), f"{image} handler object differs: {object_name}")
        require(bound["sources"] == {name: sha_bytes(source(name)) for name in HANDLER_SOURCES},
                f"{image} handler source bytes differ")
        return bound

    try:
        document = decode_json(raw)
        fields(document, ("schema", "sourceLockSha256", "makeLineageSha256", "sites"), ("handlers",))
        require(document["schema"] == SCHEMA, "wrong Gate 2 receipt schema")
        require(document["sourceLockSha256"] == origin["sha"]
                and document["makeLineageSha256"] == bootstrap["makeLineage"]["sha256"],
                "Gate 2 receipt belongs to a different source lock or Make generation")
        require(isinstance(document.get("handlers", {}), dict), "Gate 2 handler declarations must be a map")
        require(isinstance(document["sites"], list), "Gate 2 site list required")
        rows = {row["id"]: row for row in document["sites"]}
        require(len(rows) == len(document["sites"]) and rows.keys() <= SITES.keys(),
                "Gate 2 receipt has duplicate or unknown site IDs")
    except READ_ERRORS as error:
        return unavailable_correspondence(selection, issue(error, "receipt"))

    seen_edges = set()
    fill_candidates = result["draftCandidates"] = {}
    for image, link in selection.items():
        # Use only verified selections and compile inputs for the same image.
        if image in document.get("handlers", {}) or link["status"] != "PASS":
            continue
        inputs = link["handlerCompileInputs"]
        if all(link["objects"][name]["status"] == inputs[name]["status"] == "PASS" for name in HANDLER_OBJECTS):
            fill_candidates[image] = dict(handler=dict(
                sources={path: sha for name in HANDLER_OBJECTS for path, sha in inputs[name]["sources"].items()},
                kernelObjectSha256=link["objects"]["lib/_kernel.o"]["objectSha256"],
                memoryObjectSha256=link["objects"]["lib/mem.o"]["objectSha256"]))
    for name, (unit, image, procedure, encoded, baseline) in SITES.items():
        output = dict(id=name, image=image, procedure=procedure, generatedC=unit + ".c", object=unit + ".o")
        result["sites"].append(output)
        edge = "semantic"
        try:
            if name not in rows:
                raise FileNotFoundError(f"missing Gate 2 correspondence for {name}")
            row = rows[name]
            if missing := {"schemeSpan", "gvmEdge"} - row.keys():
                raise FileNotFoundError(f"{name} lacks Scheme/GVM coordinates: {', '.join(sorted(missing))}")
            fields(row, ("id", "baselineSha256", "procedure", "schemeSpan", "gvmEdge", "regions",
                         "generatedCSha256"), ("objectSha256", "image", "imageSha256"))
            require(row["baselineSha256"] == baseline and row["procedure"] == procedure,
                    "legacy baseline or Scheme procedure differs")
            mapping = row["gvmEdge"]
            fields(mapping, ("from", "to"))
            require(all(isinstance(point, str) and point.strip() for point in mapping.values()),
                    "both GVM edge coordinates are required")
            semantic = procedure, mapping["from"], mapping["to"]
            require(semantic not in seen_edges, "GVM edge is already assigned to another legacy site")
            seen_edges.add(semantic)
            scheme_name, c_name, object_name = unit + ".scm", unit + ".c", unit + ".o"
            span(source(scheme_name).splitlines(keepends=True), row["schemeSpan"])
            edge = "generatedC"
            emitted = actions["emit", c_name]
            c = source(c_name)
            require(row["generatedCSha256"] == emitted["outputSha256"] == sha_bytes(c)
                    and emitted["inputs"][str(workspace / scheme_name)] == inventory[scheme_name]["sha256"],
                    "emission receipt, Scheme input and generated C differ")
            require(isinstance(row["regions"], list) and bool(row["regions"]), "mapped generated C regions required")
            lines = c.splitlines(keepends=True)
            for region in row["regions"]:
                selected_lines = span(lines, region)
                label_line = region["anchor"]
                require(isinstance(label_line, str) and bool(label_line), "generated C label line required")
                anchor = label_line.encode()
                label = rb"___L\d+_" + encoded.encode() + rb"\b"
                require(re.search(label, anchor) and anchor in [line.strip() for line in selected_lines],
                        "generated C anchor does not locate this procedure")
            output["schemeGvm"] = dict(status="PASS", reason="receipt-bound Scheme span, declared GVM edge and C region",
                                       schemeSpan=row["schemeSpan"], gvmEdge=mapping, regions=row["regions"],
                                       generatedCSha256=row["generatedCSha256"])
            edge = "object"
            link = selection[image]
            member = link["objects"][object_name]
            if member["status"] == "PASS":
                # Suggest only absent fields and independently check the C-to-object edge.
                check_object_source(actions, workspace, source, object_name, c_name)
                expected = dict(objectSha256=member["objectSha256"], image=image, imageSha256=link["imageSha256"])
                if all(row.get(field, value) == value for field, value in expected.items()):
                    additions = {field: value for field, value in expected.items() if field not in row}
                    if additions:
                        fill_candidates[name] = additions
            require(row["objectSha256"] == actions["object", object_name]["outputSha256"]
                    == sha_bytes(source(object_name)), "object digest differs from the final Make pass")
            check_object_source(actions, workspace, source, object_name, c_name)
            edge = "link"
            require(row["image"] == image and row["imageSha256"] == actions["link", image]["outputSha256"],
                    f"site must bind to its {image} executable in this Make generation")
            require_selection(selection, image, object_name)
            edge = "handler"
            bound_handler = handler(image)
            output.update(status="PASS", gvmEdge=mapping, schemeSpan=row["schemeSpan"], regions=row["regions"],
                          generatedCSha256=row["generatedCSha256"], objectSha256=row["objectSha256"],
                          imageSha256=row["imageSha256"], linkMapSha256=actions["link", image]["linkMap"]["sha256"],
                          kernelObjectSha256=bound_handler["kernelObjectSha256"],
                          memoryObjectSha256=bound_handler["memoryObjectSha256"],
                          handlerSources=bound_handler["sources"])
        except READ_ERRORS as error:
            output.update(issue(error, edge))
            output.setdefault("schemeGvm", issue(error, "schemeGvm"))
    failures = [row for row in result["sites"] if row["status"] != "PASS"]
    result["status"] = ("MISMATCH" if any(row["status"] == "MISMATCH" for row in failures)
                        else "MISSING" if failures else "PASS")
    result["receiptSha256"] = sha_bytes(raw)
    if failures:
        result["reason"] = " | ".join(f"{row['id']} {row['edge']}: {row['reason']}" for row in failures)
    return result


def investigation(report):
    """Project receipt checks into independent ASCENT investigation routes."""
    from gambit_smp.ascent_program import load_component_catalog, query
    from gambit_smp.gate2_native import OBLIGATIONS, gap

    selection = report["linkSelection"]
    correspondence = report.get("correspondenceReview", report)
    audits = {row["id"]: row for row in correspondence.get("sites", [])}
    candidates = correspondence.get("draftCandidates", {})
    facts = dict(gate2_site=[], gate2_site_unit=[(name, unit + ".scm") for name, (unit, *_) in SITES.items()],
                 gate2_handler=[(name,) for name in HANDLER_OBJECTS],
                 gate2_image_check=[], gate2_member_check=[], gate2_site_check=[],
                 gate2_draft_candidate=[(scope, key) for scope, fields in candidates.items() for key in fields],
                 gate2_emission_pair=[(unit,) for unit in sorted(report.get("sameInvocationEmissions", {}))],
                 gate2_target=[], gate2_not_selected=[],
                 gate2_collection_ready=[()] if report.get("collectionReady") else [],
                 gate2_missing_map=[(image,) for image, link in selection.items() if link.get("mapUnrecorded")])
    recorded = report.get("recordedImages", {}).get("gsi/gsi", {})
    if recorded.get("status") == "PASS":
        facts["gate2_target"].append((report["targetGsiSha256"], recorded["imageSha256"]))
    unread_mapping = dict(status="MISSING", reason="this bootstrap review has no Scheme/GVM correspondence receipt")

    def observation(row):
        return row["status"], row.get("reason", "")

    for image, link in selection.items():
        final = link.get("finalLink", link)
        if report.get("edge") == "imageIdentity":
            final = report
        elif "finalLink" not in link:
            final = report.get("recordedImages", {}).get(image, final)
        facts["gate2_image_check"].append((image, "finalLink", image, *observation(final)))
        for name, member in link["objects"].items():
            state = link if final["status"] == "PASS" and link["status"] != "PASS" else member
            facts["gate2_member_check"].append((image, name, *observation(state)))
            if member.get("selection") == "not-selected":
                facts["gate2_not_selected"].append((image, name))
        for name in HANDLER_OBJECTS:
            state = link.get("handlerCompileInputs", {}).get(name, link["objects"][name])
            facts["gate2_image_check"].append((image, "handlerCompileInputs", name, *observation(state)))

    for name, (unit, image, procedure, _, _) in SITES.items():
        object_name = unit + ".o"
        facts["gate2_site"].append((name, image, object_name))
        audit = audits.get(name, unread_mapping)
        semantic = audit.get("schemeGvm", audit)
        captures = report.get("sameInvocationEmissions", {}).get(unit + ".scm", [])
        if captures and semantic["status"] == "MISSING" and name not in audits:
            semantic = dict(status="MISSING",
                            reason="same-invocation GVM/C is verified; the Scheme operands and lowered effect join still need review")
        facts["gate2_site_check"].append((name, "schemeGvm", procedure, *observation(semantic)))
        if captures:
            facts["gate2_site_check"].append((name, "sameInvocationArtifacts", unit + ".scm", "PASS",
                                             "the retained emitter reproduced C and captured GVM in one process"))
        native = report.get("nativeFrame", {}).get(name, [])
        fallback = gap(report.get("nativeFrameReason", "no single checked native-frame receipt covers this site"))
        complete = next((row for row in native if all(row[k]["status"] == "PASS" for k in OBLIGATIONS)), None)
        partial = max(native, key=lambda row: sum(x["status"] == "PASS" for x in row.values()), default=None)
        for check in OBLIGATIONS:
            states = [row[check] for row in native]
            state = next((row for row in states if row["status"] == "MISMATCH"),
                         (complete or partial or fallback)[check])
            facts["gate2_site_check"].append((name, check, procedure, *observation(state)))
        facts["gate2_site_check"].append((name, "nativeFrameComplete", procedure,
                                         "PASS" if complete and not any(
                                             check["status"] == "MISMATCH" for row in native for check in row.values())
                                         else "MISSING",
                                         "one lossless invocation receipt must cover all five native checks"))
        if semantic["status"] != "PASS" or audit["status"] == "PASS":
            continue
        link = selection[image]
        if audit["edge"] == "object":
            check, subject = "objectDeclaration", object_name
        elif audit["edge"] == "link" and link["objects"][object_name]["status"] == "PASS":
            check, subject = "imageDeclaration", image
        elif audit["edge"] == "handler" and all(
                link["objects"][item]["status"] == link["handlerCompileInputs"][item]["status"] == "PASS"
                for item in HANDLER_OBJECTS):
            check, subject = "handlerDeclaration", image
        else:
            continue
        facts["gate2_site_check"].append((name, check, subject, *observation(audit)))

    result = dict(backend="ASCENT", executionAuthorized=False, runtimeAdmitted=False)
    try:
        catalog = load_component_catalog(ROOT / "evidence/dsl/components.json", entry="gate2-investigation",
                                         constructor="make-gate2-investigation", trusted=True)
        names = ("gate2_evidence_status", "gate2_open_route", "gate2_reusable", "gate2_repair_need",
                 "gate2_fillable", "gate2_target_option", "gate2_collection")
        relations = query(facts, catalog, {name: name for name in names})
        bindings = catalog["sourceInputs"]
        require(all(digest(Path(path)) == sha for path, sha in bindings.items()),
                "Gate 2 investigation rules changed during inference")
    except (*READ_ERRORS, RuntimeError, CalledProcessError) as error:
        return dict(result, status="UNVERIFIED", reason=str(error))
    sites = {name: dict(image=image, openRoutes=[], checks=[], reusable=[], evidenceNeeded=[])
             for name, image, _ in facts["gate2_site"]}
    for name, route, check, subject, status, reason in sorted(relations["gate2_evidence_status"]):
        sites[name]["checks"].append(dict(route=route, check=check, subject=subject, status=status, reason=reason))
    for name, route in sorted(relations["gate2_open_route"]):
        sites[name]["openRoutes"].append(route)
    for name, check, subject in sorted(relations["gate2_reusable"]):
        sites[name]["reusable"].append(dict(check=check, subject=subject))
    for name, check, subject, action in sorted(relations["gate2_repair_need"]):
        sites[name]["evidenceNeeded"].append(dict(check=check, subject=subject, action=action))
    draft_additions = {}
    for scope, field in sorted(relations["gate2_fillable"]):
        draft_additions.setdefault(scope, {})[field] = candidates[scope][field]
    return dict(result, status="PROJECTED", sourceInputs=bindings, sites=sites,
                draftAdditions=dict(receiptSha256=correspondence.get("receiptSha256"), fields=draft_additions),
                sameInvocationEmissions=report.get("sameInvocationEmissions", {}),
                targetOptions=[dict(action=action, gsiSha256=sha) for action, sha in sorted(relations["gate2_target_option"])],
                collectionOptions=[dict(kind=kind, subject=subject) for kind, subject in sorted(relations["gate2_collection"])])
