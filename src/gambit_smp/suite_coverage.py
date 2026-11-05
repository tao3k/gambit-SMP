"""Checked file-coverage projection; never native or performance authorization."""
import re
import argparse
import json
import sys
from pathlib import Path
from gambit_smp.artifact_storage import observation_root, fixture_name, fixture_path

from gambit_smp.framework import ROOT, digest
from gambit_smp.recipes import read_json

SMP_LEDGER_FOLDER = Path("evidence/research/retained/modern-c/delivery-plan/current")
SMP_ORIGINAL_INVENTORY = "evidence/research/retained/modern-c/tcl-callback/scoped-receipt.json"


def _sha(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value) is not None


def project_suite_files(receipt):
    """Project validated executor results, not caller-supplied PASS labels alone."""
    result = {"observed_suite": [], "observed_suite_file": []}
    for step in receipt.get("steps", []):
        if step.get("capability") != "gambit.suite" or step.get("outcome") != "PASS":
            continue
        if "passedFiles" not in step:
            continue
        name, args = step["id"], step["arguments"]
        passed, expected = step["passedFiles"], args["expectedFiles"]
        if (not isinstance(passed, list) or not passed or not isinstance(expected, list) or
                any(not isinstance(file, str) or Path(file).is_absolute() or ".." in Path(file).parts for file in passed)
                or len(passed) != len(set(passed)) or sorted(passed) != sorted(expected)
                or step.get("mode") != args["mode"] or args["mode"] not in {"gsi", "gsc"}):
            raise ValueError("suite coverage requires exact complete declared file results")
        groups, covered = step.get("suiteGroups"), []
        if not isinstance(groups, list) or not groups:
            raise ValueError("suite coverage requires actual completed groups")
        phase_files = set(args.get("compilerPhaseFiles", []))
        if not phase_files <= set(passed) or phase_files and args["mode"] != "gsc":
            raise ValueError("compiled phases must belong to the declared compiled inventory")
        for group in groups:
            if (group.get("accepted") is not True or type(group.get("exit")) is not int
                    or group["exit"] != 0 or group.get("timeout") is not False):
                raise ValueError("failed or uncompleted suite group cannot qualify")
            files = group["files"]
            if not isinstance(files, list) or not files or any(not isinstance(file, str) for file in files):
                raise ValueError("exact completed group file list required")
            covered.extend(files)
            requested_phases = phase_files.intersection(files)
            if requested_phases:
                rows = group.get("compilerPhases", [])
                if (len(files) != 1 or group.get("assertionProtocol") != "original-gsi-loader-and-unit-test-exit"
                        or group.get("phaseInactivitySeconds") != args["fileBudgetSeconds"][files[0]]
                        or [row.get("phase") for row in rows] !=
                           ["scheme-to-c", "c-to-dynamic-module", "compiled-execution"]
                        or any(row.get("accepted") is not True or type(row.get("exit")) is not int
                               or row["exit"] != 0 or row.get("timeout") is not False for row in rows)
                        or not all(_sha(row.get("artifactSha256")) for row in rows[:2])):
                    raise ValueError("compiled phase coverage requires original loader and all real phase artifacts")
            elif "compilerPhases" in group:
                raise ValueError("undeclared compiled phase protocol")
        if sorted(covered) != sorted(passed):
            raise ValueError("suite groups must cover the exact file inventory once")
        artifacts = step.get("artifacts", {})
        for file in passed:
            sha = artifacts.get(name + "/runtime/tests/unit-tests/" + file)
            additional = args.get("additionalFixtures", {}).get(file)
            if not _sha(sha) or additional is not None and sha != additional["sha256"]:
                raise ValueError("suite fixture hash is missing or differs from its declared source")
            result["observed_suite_file"].append([name, file, sha])
        whole = args["selection"] == ["."] and args["regime"] in {"whole-parallel", "whole-sequential"}
        result["observed_suite"].append([name, args["mode"], args.get("inventory", "unit"), whole])
    return result


def require_numeric_smp_evidence(groups, processes):
    """Check that the original numeric case passed inside one 90-second window."""
    numeric = [group for group in groups if group["files"] == ["03-number/_num.scm"]]
    if len(numeric) != 1:
        raise ValueError("one original numeric group required")
    group = numeric[0]
    stages = ("scheme-to-c", "c-to-dynamic-module", "compiled-execution")
    phases = group.get("compilerPhases", [])
    if (group.get("sharedPhaseBudgetSeconds") != 90
            or group.get("assertionProtocol") != "original-gsi-loader-and-assertion-witness"
            or [row.get("phase") for row in phases] != list(stages)
            or any(row.get("accepted") is not True or row.get("exit") != 0
                   or row.get("timeout") is not False for row in phases)
            or not all(_sha(row.get("artifactSha256")) for row in phases[:2])
            or phases[-1].get("originalAssertionsWitness") is not True):
        raise ValueError("complete original numeric phases and assertion witness required")
    prefix = f'suite-{group["batch"]}-{group["shard"]}-'
    commands = [row for row in processes if row.get("stage", "").startswith(prefix)]
    if [row["stage"] for row in commands] != [prefix + name for name in stages]:
        raise ValueError("exact numeric phase process records required")
    caps = [row.get("effectiveBudgetSeconds") for row in commands]
    seconds = [row.get("seconds") for row in commands]
    if (not all(type(n) in (int, float) and 0 < n <= 90 for n in caps + seconds)
            or any(next_cap > cap - used
                   for cap, used, next_cap in zip(caps, seconds, caps[1:]))
            or sum(seconds) > 90):
        raise ValueError("original shared numeric budget exceeded")


def _load_smp_evidence(root, path, expected=None):
    path = Path(path)
    if path.is_absolute() or ".." in path.parts or not path.parts:
        raise ValueError("repository-relative SMP evidence required")
    absolute = (root / path).resolve(strict=True)
    if not absolute.is_relative_to(root):
        raise ValueError("SMP evidence escapes repository")
    raw = absolute.read_bytes()
    from hashlib import sha256
    identity = sha256(raw).hexdigest()
    if expected is not None and identity != expected:
        raise ValueError("SMP evidence identity changed")
    return json.loads(raw), dict(path=path.as_posix(), sha256=identity)


def _published_pr_source(root, source_binding, name, expected):
    """Read an exact published source period, never an orphaned subject tree."""
    import hashlib
    from gambit_smp.task_processes import check_output

    _, record = _load_smp_evidence(root, source_binding)
    revision = check_output(["git", "-C", root, "log", "-1", "--format=%H", "--",
                             str(source_binding)], timeout=10).decode().strip()
    if not revision:
        raise ValueError("PR historical source record has no published commit")
    committed = check_output(["git", "-C", root, "show",
                              revision + ":" + str(source_binding)], timeout=10)
    if hashlib.sha256(committed).hexdigest() != record["sha256"]:
        raise ValueError("PR historical source record differs from its published epoch")
    original = check_output(["git", "-C", root, "show", revision + ":" + name], timeout=10)
    if hashlib.sha256(original).hexdigest() != expected:
        raise ValueError("PR historical source differs from its published epoch")
    return original


def _fixture_projection_source(root, proof, function, *, source_binding=None):
    """Keep a historical pure projection bound across unrelated module edits.

    The full historical blob must still have its recorded digest. Only the
    identical function syntax may be reused; this does not accept a changed
    implementation or reinterpret an old native result as current execution.
    """
    import ast
    import hashlib
    path = root / proof["projectionSource"]
    if digest(path) == proof["projectionSha256"]:
        return True
    original = _published_pr_source(root, proof.get(
        "sourceBinding", source_binding or "evidence/research/retained/modern-c/pr-gsi/submission/source.json"),
        proof["projectionSource"], proof["projectionSha256"])
    def body(raw):
        definitions = [node for node in ast.parse(raw).body
                       if isinstance(node, ast.FunctionDef) and node.name == function]
        return ast.dump(definitions[0], include_attributes=False) if len(definitions) == 1 else None
    old, current = body(original), body(path.read_bytes())
    return old is not None and old == current


def require_pr_smp_evidence(root, receipt):
    """Revalidate the model-bound whole PR population, never a focused PASS."""
    import hashlib
    from gambit_smp.suite_primitives import thread_request_fixture, thread_interrupt_lifetime_fixture
    from gambit_smp.task_processes import check_output

    mode = receipt.get("mode")
    if mode not in {"gsi", "gsc"} or receipt.get("family") != "pr-" + mode:
        raise ValueError("PR family must match its actual interpreted or compiled mode")
    folder = Path("evidence/research/retained/modern-c") / ("pr-" + mode)
    reference = receipt["nativeReference"]
    raw, _ = _load_smp_evidence(root, reference["path"], reference["sha256"])
    if raw.get("complete") is not True or any(receipt.get(k) != v for k, v in raw.items()):
        raise ValueError("PR acceptance must retain its complete raw native campaign")
    manifest, _ = _load_smp_evidence(root, folder / "manifest.json", receipt["manifestSha256"])
    binding, _ = _load_smp_evidence(root, folder / "model-binding.json",
                                    receipt["modelBindingSha256"])
    spec, cases = manifest["spec"], manifest["cases"]
    bootstrap, _ = _load_smp_evidence(
        root, "evidence/research/retained/modern-c/frozen-568e0276-smp/shared-procedure-dispatch-bootstrap.json")
    if (bootstrap["sourceTree"] != receipt["sourceTree"]
            or bootstrap["producerSha256"] != receipt["producerSha256"]):
        raise ValueError("PR immutable source-reader base lacks its exact producer")
    read_base = bootstrap["baseRevision"]
    if mode == "gsc":
        runner = check_output(["git", "-C", root / "vendor/gambit", "show",
                               read_base + ":tests/run-unit-tests.scm"], timeout=10)
        if receipt["testInputFiles"].get("run-unit-tests.scm") != hashlib.sha256(runner).hexdigest():
            raise ValueError("compiled PR acceptance requires the original compile/load runner")
    if (binding.get("complete") is not True or binding.get("diagnostics") != []
            or binding.get("manifestMatched") is not True or binding["cases"] != cases
            or any(binding["spec"].get(k) != v for k, v in spec.items())
            or binding["modelInputs"] != manifest["modelInputs"]):
        raise ValueError("PR population needs its diagnostic-free native SDK binding")
    for name, expected in binding["modelInputs"].items():
        if digest(root / name) != expected:
            # An accepted earlier family retains its own model epoch. A later
            # support-policy edit must not relabel that historical receipt as
            # a current-model run or discard its exact original model bytes.
            _published_pr_source(root, folder / "submission/source.json", name, expected)
    originals = {}
    for name, expected in manifest["originalReferences"].items():
        originals[name], _ = _load_smp_evidence(root, name, expected)
    suite = next(s for s in originals[spec["originalSuite"]]["steps"]
                 if s["id"] == "native-" + mode)
    selection = next(s["arguments"] for s in originals[spec["originalSelection"]]["steps"]
                     if s["id"] == "pr-regressions-gsi")
    additional = suite["arguments"]["additionalFixtures"]
    controls = set(selection["selection"]) - set(selection["additionalFixtures"])
    expected = set(additional) | controls
    actual = [row["target"] for row in cases]
    if len(actual) != len(set(actual)) or set(actual) != expected:
        raise ValueError("PR manifest omits or duplicates an original requirement")
    for row in cases:
        if row["kind"] == "additional":
            if {k: row[k] for k in ("source", "sha256")} != additional.get(row["target"]):
                raise ValueError("PR fixture differs from the original pinned source")
            if digest(root / row["source"]) != row["sha256"]:
                raise ValueError("PR original fixture source changed")
        elif row["kind"] not in {"original-control", "source-refined-control"} or row["target"] not in controls:
            raise ValueError("PR control is outside the original selection")
        else:
            data = check_output(["git", "-C", root / "vendor/gambit", "show",
                                 read_base + ":tests/unit-tests/" + row["target"]], timeout=10)
            if row["kind"] == "source-refined-control":
                if mode != "gsc" or "controlRefinementEvidence" not in spec:
                    raise ValueError("undeclared PR control refinement")
                proof = originals[spec["controlRefinementEvidence"]]
                projected = thread_interrupt_lifetime_fixture(data)
                published = receipt.get("publicationSource")
                if published is None:
                    delivered = (root / row["source"]).read_bytes()
                else:
                    import re
                    if (published.get("repository") != "vendor/gambit"
                            or "vendor/gambit/" + published.get("path", "") != row["source"]
                            or not re.fullmatch("[0-9a-f]{40}", published.get("revision", ""))):
                        raise ValueError("PR fixture publication needs its exact vendor source identity")
                    delivered = check_output(["git", "-C", root / "vendor/gambit", "show",
                                              published["revision"] + ":" + published["path"]], timeout=10)
                if (receipt.get("controlRefinement") != proof or row["target"] != proof["target"]
                        or row["source"] != proof["source"]
                        or hashlib.sha256(data).hexdigest() != proof["originalSha256"]
                        or hashlib.sha256(projected).hexdigest() != proof["projectedSha256"]
                        or not _fixture_projection_source(root, proof, "thread_interrupt_lifetime_fixture",
                                                          source_binding=folder / "submission/source.json")
                        or delivered != projected):
                    raise ValueError("PR control lifetime refinement differs from its original source")
                data = projected
            if hashlib.sha256(data).hexdigest() != row["sha256"]:
                raise ValueError("PR original control differs from the published source")
    if (receipt["sourceTree"] != spec["canonicalTree"]
            or receipt["profileSha256"] != spec["profile"]
            or receipt["producerSha256"] != spec["producer"]
            or receipt["baselineRevision"] != spec["baseline"]
            or receipt["publishedTree"] != spec["publishedTree"]
            or receipt["wholeBudgetSeconds"] != suite["budgetSeconds"]
            or receipt["wholeBudgetSeconds"] != spec["wholeSeconds"]
            or receipt["innerBudgetSeconds"] != spec["innerSeconds"]
            or not 0 < receipt["seconds"] <= spec["innerSeconds"]
            or receipt.get("heapRaised") is not False or receipt.get("waitExtended") is not False
            or receipt.get("observationsSpliced") is not False):
        raise ValueError("PR source, producer or original resource contract differs")
    proof = originals[spec["requestProjectionEvidence"]]
    if receipt.get("requestProjection") != proof:
        raise ValueError("PR private-constructor refinement changed")
    header = check_output(["git", "-C", root / "vendor/gambit", "show",
                           read_base + ":" + proof["producerHeader"]], timeout=10)
    original = (root / additional["06-thread/thread_interrupt_ended.scm"]["source"]).read_bytes()
    projected = thread_request_fixture(original, header)
    if (hashlib.sha256(header).hexdigest() != proof["producerHeaderSha256"]
            or hashlib.sha256(projected).hexdigest() != proof["projectedSha256"]
            or not _fixture_projection_source(root, proof, "thread_request_fixture")):
        raise ValueError("PR constructor does not match the producer-bound source projection")
    limits = {row["target"]: row["seconds"] for row in cases if row["seconds"]}
    original_limits = {name: seconds for name, seconds in
                       suite["arguments"].get("fileBudgetSeconds", {}).items()
                       if name in expected}
    groups = None
    if mode == "gsc":
        legacy = next(s for s in originals[spec["legacySuite"]]["steps"]
                      if s["id"] == "native-gsi")
        if legacy["arguments"]["additionalFixtures"] != additional:
            raise ValueError("compiled PR population differs from its interpreted source")
        for name, seconds in legacy["arguments"].get("fileBudgetSeconds", {}).items():
            if name in expected:
                original_limits[name] = min(seconds, original_limits.get(name, seconds))
        original_group = suite["arguments"]["groupBudgetSeconds"]["thread-completion"]
        members = [name for name in original_group["files"] if name in expected]
        if (spec["threadCompletionFiles"].split(";") != members
                or spec["threadCompletionSeconds"] != original_group["budgetSeconds"]):
            raise ValueError("compiled PR thread-completion guard differs from the original")
        groups = {"thread-completion": dict(files=members,
                                            budgetSeconds=original_group["budgetSeconds"])}
    if limits != original_limits:
        raise ValueError("PR fixture guard differs from its original source budgets")
    for row in cases:
        expected_hash = proof["projectedSha256"] if row["target"] == "06-thread/thread_interrupt_ended.scm" else row["sha256"]
        if receipt["testInputFiles"].get("unit-tests/" + row["target"]) != expected_hash:
            raise ValueError("PR executed fixture differs from its declared source")
    populations = list(map(int, spec["processors"].split(";")))
    jobs = {int(k): int(v) for k, v in (x.split(":") for x in spec["jobs"].split(";"))}
    if [run["processors"] for run in receipt["topologies"]] != populations:
        raise ValueError("PR requires every declared processor population exactly once")
    for run in receipt["topologies"]:
        request = run["request"]
        if (run.get("complete") is not True or run["jobs"] != jobs[run["processors"]]
                or request["mode"] != mode or request["processors"] != run["processors"]
                or request["jobs"] != run["jobs"] or request["fileBudgetSeconds"] != limits
                or request["expectedFiles"] != sorted(expected)):
            raise ValueError("PR topology or unchanged fixture budget is incomplete")
        if groups is not None and request.get("groupBudgetSeconds") != groups:
            raise ValueError("compiled PR group guard is missing or changed")
        if ([p["role"] for p in run["probes"]] != ["runner", "fixture"]
                or any(p.get("complete") is not True or p.get("exit") != 0
                       or p.get("timeout") is not False or p.get("expected") != n
                       or p.get("observed") != "PROCESSORS:" + str(n)
                       or not 0 < p["seconds"] <= 10
                       for p, n in zip(run["probes"], (1, run["processors"])))):
            raise ValueError("PR needs real runner and fixture processor probes")
        rows = run["observations"]
        if (sorted(n for row in rows for n in row["files"]) != sorted(expected)
                or any(row.get("accepted") is not True or row.get("exit") != 0
                       or row.get("timeout") is not False
                       or sorted(row["observedFiles"]) != sorted(row["files"]) for row in rows)):
            raise ValueError("PR needs every original case to complete in each topology")
        if mode == "gsc":
            for row in rows:
                stage = "suite-" + str(row["batch"]) + "-" + str(row["shard"])
                commands = [p for p in receipt["processes"]
                            if p.get("topology") == run["processors"] and p.get("stage") == stage]
                if len(commands) != 1:
                    raise ValueError("compiled PR group lacks its unique actual command")
                command = commands[0]
                argv = command.get("argv", [])
                cap = spec["innerSeconds"]
                if len(row["files"]) == 1:
                    cap = min(cap, limits.get(row["files"][0], cap))
                for group in groups.values():
                    if group["files"] == row["files"]:
                        cap = min(cap, group["budgetSeconds"])
                actual_cap = command.get("effectiveBudgetSeconds")
                expected_arguments = ["run-unit-tests.scm", "-gsc",
                                      *["unit-tests/" + name for name in row["files"]]]
                if (len(argv) < 4 or argv[3:] != expected_arguments
                        or Path(argv[0]).name != "gsi" or argv[2] != "-f"
                        or command.get("exit") != 0 or command.get("timeout") is not False
                        or command.get("parentReaped") is not True
                        or command.get("processGroupQuiescent") is not True
                        or type(actual_cap) not in {int, float} or not 0 < actual_cap <= cap
                        or not 0 < command.get("seconds", 0) <= actual_cap):
                    raise ValueError("compiled PR group did not execute its original GSC runner")


def accepted_smp_status(root):
    """Report the recorded milestone from its own bound evidence period."""
    root = Path(root).resolve()
    ledger, _ = _load_smp_evidence(root, SMP_LEDGER_FOLDER / "accepted-smp-progress.json")

    def bound(ref):
        if not _sha(ref["sha256"]):
            raise ValueError("SMP ledger requires a receipt digest")
        return _load_smp_evidence(root, ref["path"], ref["sha256"])[0]

    origin = bound(ledger["origin"])
    packet = bound(ledger["accepted"])
    ids = [row["id"] for row in origin["families"]]
    closed = [row[0] for row in packet["answers"]["closed"]]
    passed = len(closed)
    if (ledger["origin"]["path"] != str(SMP_LEDGER_FOLDER / "smp-acceptance.json")
            or len(ids) != 12 or len(set(ids)) != 12 or set(ids[:passed]) != set(closed)
            or passed < origin["passed"]
            or ledger["originPassed"] != origin["passed"]
            or ledger["passed"] != packet["currentPassed"] or ledger["passed"] != passed
            or ledger["remaining"] != len(ids) - passed or ledger["closed"] != ids[:passed]
            or ledger["sourceTree"] != packet["sourceTree"]
            or ledger["profileSha256"] != packet["profileSha256"]
            or ledger["profileSha256"] != origin["profileSha256"]
            or ledger["wholeSmpAdmitted"] is not (passed == len(ids))
            or ledger["originalInventory"]["path"] != SMP_ORIGINAL_INVENTORY
            or set(ledger["receipts"]) != set(closed)):
        raise ValueError("SMP ledger disagrees with its bound acceptance evidence")
    bound(ledger["originalInventory"])
    for family, ref in ledger["receipts"].items():
        row = packet["receipts"][family]
        receipt = bound(ref)
        if (row["qualified"] is not True or row["path"] != ref["path"] or row["sha256"] != ref["sha256"]
                or receipt["sourceTree"] != ledger["sourceTree"]
                or receipt["profileSha256"] != ledger["profileSha256"]):
            raise ValueError("SMP ledger has a mismatched family receipt")
    return ledger


def accepted_smp_progress(root, baseline_path, candidate_path, previous=None):
    """Project an immutable acceptance packet into the rolling SMP ledger."""
    from gambit_smp.ascent_program import load_catalog, query

    root = Path(root).resolve()
    baseline, origin = _load_smp_evidence(root, baseline_path)
    packet, accepted = _load_smp_evidence(root, candidate_path)
    families = [[row["id"], row["evidenceKind"]] for row in baseline["families"]]
    facts = packet["facts"]
    tree, profile = packet["sourceTree"], packet["profileSha256"]
    if (len(families) != 12 or facts["acceptanceFamily"] != families
            or facts["acceptanceSource"] != [[tree, profile]]
            or profile != baseline["profileSha256"]):
        raise ValueError("SMP candidate differs from the declared checklist or profile")
    claimed = packet["currentPassed"]
    if type(claimed) is not int or not baseline["passed"] <= claimed <= len(families):
        raise ValueError("SMP candidate cannot replace the accepted prefix")
    if previous is not None:
        same_milestone = claimed == previous["passed"] and previous["accepted"] != accepted
        correction = False
        if same_milestone and packet.get("metadataCorrectionOf") == previous["accepted"]:
            old, _ = _load_smp_evidence(root, previous["accepted"]["path"],
                                        previous["accepted"]["sha256"])
            # Only a wrong redundant remainder may be normalized. Native
            # receipts, source, facts, model epoch and answers must be identical.
            before = {k: v for k, v in old.items() if k != "currentRemaining"}
            after = {k: v for k, v in packet.items()
                     if k not in {"currentRemaining", "metadataCorrectionOf"}}
            correction = (before == after and old.get("currentRemaining") != len(families) - claimed
                          and packet.get("currentRemaining") == len(families) - claimed)
        if (previous["origin"] != origin or claimed < previous["passed"]
                or (same_milestone and not correction)):
            raise ValueError("SMP history cannot regress or replace an equal milestone")

    policy = "dev/modeling/ascent/delivery-plan.rules.scm"
    if digest(root / policy) != packet["policySha256"]:
        raise ValueError("SMP acceptance policy changed")
    for name, expected in packet["modelInputs"].items():
        path = Path(name)
        if path.is_absolute() or ".." in path.parts or digest(root / path) != expected:
            raise ValueError("SMP model input changed")
    answers = query(facts, load_catalog(root / policy),
                    dict(closed="acceptanceClosed", open="acceptanceOpen", veto="acceptanceVeto"))
    closed = {row[0] for row in answers["closed"]}
    if (set(answers) != set(packet["answers"])
            or any(sorted(map(tuple, rows)) != sorted(map(tuple, packet["answers"][key]))
                   for key, rows in answers.items())
            or len(closed) != packet["currentPassed"]):
        raise ValueError("SMP inference differs from candidate evidence")

    ids = [row[0] for row in families]
    prefix = ids[:len(closed)]
    if set(prefix) != closed or len(prefix) < baseline["passed"]:
        raise ValueError("accepted SMP history requires a contiguous advancing prefix")

    inventory, inventory_binding = _load_smp_evidence(root, SMP_ORIGINAL_INVENTORY)
    expected = sorted(name.removeprefix("tests/unit-tests/")
                      for name in inventory["original"]["unitInventory"])
    if len(expected) != 408 or len(set(expected)) != len(expected):
        raise ValueError("exact original SMP unit inventory required")

    def quiescent_success(rows):
        return bool(rows) and all(
            row.get("exit") == 0 and row.get("timeout") is False
            and row.get("parentReaped") is True and row.get("processGroupQuiescent") is True
            for row in rows)

    references = {}
    producer = None
    for family in prefix:
        row = packet["receipts"][family]
        receipt, identity = _load_smp_evidence(root, row["path"], row["sha256"])
        if row["qualified"] is not True or (receipt["sourceTree"], receipt["profileSha256"]) != (tree, profile):
            raise ValueError("accepted SMP family lacks exact same-source evidence")
        if not quiescent_success(receipt.get("processes", [])):
            raise ValueError("accepted SMP family lacks successful quiescent processes")
        if family == "bootstrap":
            producer = receipt["producerSha256"]
            artifacts = receipt["artifacts"]
            if receipt["phaseCounts"] != {f"phase{i}": 2 for i in range(1, 5)}:
                raise ValueError("two actual bootstrap phases required")
        elif (receipt.get("complete") is not True or receipt.get("producerSha256") != producer
              or receipt.get("runtimeArtifacts") != artifacts):
            raise ValueError("accepted SMP consumer lacks its producer binding")
        if family in {"gsi", "gsc"}:
            if (receipt.get("mode") != family or sorted(receipt.get("selectedFiles", [])) != expected
                    or receipt.get("manifestDifference") != {"extra": [], "missing": []}):
                raise ValueError("accepted SMP consumer requires the exact original inventory")
        if family == "gsi":
            original = receipt["original"]
            if (original.get("marker") is not True or original.get("exit") != 0
                    or original.get("timeout") is not False or not 0 < original["seconds"] <= 300
                    or sorted(receipt.get("observedFiles", [])) != expected):
                raise ValueError("accepted GSI requires observed complete original execution")
        if family == "gsc":
            groups = receipt.get("observations", [])
            if (sorted(name for group in groups for name in group["files"]) != expected
                    or any(group.get("accepted") is not True or group.get("exit") != 0
                           or group.get("timeout") is not False for group in groups)):
                raise ValueError("accepted GSC requires all original groups to complete")
            require_numeric_smp_evidence(groups, receipt["processes"])
            if any(sorted(group.get("observedFiles", [])) != sorted(group["files"])
                   for group in groups if group["files"] != ["03-number/_num.scm"]):
                raise ValueError("accepted GSC requires per-file runner completion")
        if family in {"pr-gsi", "pr-gsc"}:
            if receipt.get("family") != family:
                raise ValueError("accepted PR receipt belongs to another family")
            require_pr_smp_evidence(root, receipt)
        references[family] = identity

    return dict(origin=origin, originPassed=baseline["passed"], accepted=accepted,
                sourceTree=tree, profileSha256=profile, passed=len(prefix),
                remaining=len(families)-len(prefix), closed=prefix, receipts=references,
                originalInventory=inventory_binding,
                wholeSmpAdmitted=len(prefix)==len(families))


def checked_suite_coverage(run):
    """Require current sealed receipt custody before projecting observed coverage."""
    from gambit_smp.research_kernel import inspect
    run = Path(run).resolve(strict=True)
    root = ROOT.resolve()
    observation_root(root, run)
    before = digest(run / "receipt.json")
    outer, child = read_json(run / "receipt.json"), read_json(run / "run/receipt.json")
    if (outer.get("outcome") != "PASS" or outer.get("exit") != 0
            or Path(outer.get("root", "")).resolve() != root
            or outer.get("timeout") is not False or outer.get("parentReaped") is not True
            or outer.get("processGroupQuiescent") is not True
            or digest(run / "run/receipt.json") != outer.get("childReceiptSha256")
            or child.get("outcome") != "PASS" or inspect(run).get("identityStatus") != "CURRENT"):
        raise ValueError("suite coverage requires current complete quiescent sealed evidence")
    facts = project_suite_files(child)
    if digest(run / "receipt.json") != before or digest(run / "run/receipt.json") != outer["childReceiptSha256"]:
        raise ValueError("suite receipt changed during projection")
    return {"schema": "checked-native-suite-coverage.v1", "run": run.relative_to(root).as_posix(),
            "outerReceiptSha256": before, "childReceiptSha256": outer["childReceiptSha256"],
            "engineId": outer["engineId"], "facts": facts,
            "runtimeAdmitted": False, "sourceRefinementAdmitted": False, "performanceAdmitted": False}


def execution_policy(argv):
    return "read" if argv == ["--smp-status"] else "execute"


def main():
    from gambit_smp.framework import execute
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.recipes import fields, source_path
    parser = argparse.ArgumentParser(description=__doc__)
    smp = parser.add_mutually_exclusive_group()
    smp.add_argument("--advance-smp-history", type=Path)
    smp.add_argument("--smp-status", action="store_true", help="report the evidence-bound SMP milestone")
    parser.add_argument("--run", type=Path)
    parser.add_argument("--contract")
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument)
    args = parser.parse_args()
    if args.smp_status or args.advance_smp_history:
        if args.run or args.contract or args.out:
            parser.error("SMP ledger operations are separate from suite coverage")
        if args.smp_status:
            print(json.dumps(accepted_smp_status(ROOT), indent=2))
            return 0
        from gambit_smp.workspace import write

        output = ROOT / SMP_LEDGER_FOLDER / "accepted-smp-progress.json"
        previous = accepted_smp_status(ROOT) if output.exists() else None
        result = accepted_smp_progress(ROOT, SMP_LEDGER_FOLDER / "smp-acceptance.json",
                                       args.advance_smp_history, previous)
        write(output, result)
        print(json.dumps(dict(passed=result["passed"], remaining=result["remaining"],
                              tree=result["sourceTree"])))
        return 0
    if not (args.run and args.contract and args.out):
        parser.error("--run, --contract and --out are required for suite coverage")
    contract_path = source_path(ROOT, args.contract)
    contract_sha = digest(contract_path)
    contract = read_json(contract_path)
    if digest(contract_path) != contract_sha:
        raise ValueError("coverage contract changed during read")
    fields(contract, ("schema", "rules", "queries", "expected", "evaluationSeconds"))
    if contract["schema"] != "native-suite-coverage-contract.v1":
        raise ValueError("typed suite coverage contract required")
    rules = [source_path(ROOT, path) for path in contract["rules"]]
    out = args.out.resolve()
    if out.exists():
        raise ValueError("fresh same-project coverage output required")
    bindings = {str(path.relative_to(ROOT)): digest(path)
                for path in [contract_path, *rules, Path(__file__).resolve()]}
    record = checked_suite_coverage(args.run)
    outer = read_json(args.run / "receipt.json")
    engine = Path(outer["engine"])
    manifest = manifest_paths(engine)
    if manifest["engineId"] != record["engineId"]:
        raise ValueError("coverage engine differs from the sealed native run")
    out.mkdir(parents=True)
    request = {"rules": [str(path) for path in rules], "facts": record["facts"],
               "queries": contract["queries"], "engineId": record["engineId"], "output": str(out)}
    request_path = out / "evaluation.json"
    request_path.write_text(json.dumps(request, sort_keys=True, indent=2) + "\n")
    process = {}
    code, output, timeout, seconds = execute(
        [sys.executable, "-I", "-B", str(engine / "runner.py"), "rules", str(request_path)],
        ROOT, contract["evaluationSeconds"], metadata=process)
    (out / "evaluation.log").write_text(output)
    answers = read_json(out / "answers.json") if code == 0 and not timeout else {}
    accepted = code == 0 and not timeout and set(answers) == set(contract["expected"]) and all(
        sorted(map(tuple, answers[name])) == sorted(map(tuple, expected))
        for name, expected in contract["expected"].items())
    if digest(args.run / "receipt.json") != record["outerReceiptSha256"]:
        raise ValueError("suite source receipt changed during coverage query")
    if any(digest(ROOT / path) != sha for path, sha in bindings.items()):
        raise ValueError("coverage rule or checker changed during query")
    record.update(outcome="PASS" if accepted else "DENY", answers=answers,
        execution={"exit": code, "timeout": timeout, "seconds": seconds, **process},
        contract=args.contract, sourceInputs=bindings,
        scope="checked sealed suite file coverage only; not whole SMP or performance acceptance")
    (out / "receipt.json").write_text(json.dumps(record, indent=2, sort_keys=True) + "\n")
    print(json.dumps({"outcome": record["outcome"], "answers": answers,
                      "runtimeAdmitted": False, "performanceAdmitted": False}))
    return 0 if accepted else 2


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('suite-coverage')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('suite-coverage', main))
