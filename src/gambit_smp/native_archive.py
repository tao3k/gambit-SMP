"""Archive component observations without granting native/runtime admission."""
import argparse
import json
from pathlib import Path
import shutil
import re
import math
import shlex
import hashlib

from gambit_smp.framework import digest, relative


def archive(source, destination, observed_exit, identity=None):
    source = source.resolve(strict=True)
    receipt = source / "receipt.json"
    saved = json.loads(receipt.read_text())
    if saved.get("schema") == "gambit-compiler-cost.v1":
        if observed_exit is not None:
            raise ValueError("historical compiler probe cannot invent its parent exit")
        return archive_compiler_probe(source, destination, identity)
    if saved.get("schema") == "gambit-two-pass-bootstrap.v1":
        return archive_bootstrap(source, destination, identity)
    if saved.get("schema") == "gambit-actlog-abort-source-unit.v1":
        return archive_source_unit(source, destination, observed_exit)
    if saved.get("schema") in {"gambit-upstream-suite.v1", "gambit-upstream-atomic-coverage.v1"}:
        if observed_exit is None:
            return archive_failed_suite(source, destination, identity)
        if saved.get("schema") == "gambit-upstream-atomic-coverage.v1":
            raise ValueError("atomic history cannot invent a whole-suite parent outcome")
        return archive_suite(source, destination, observed_exit, identity)
    if (saved.get("schema") != "gambit-notification-source-schedules.v1" or
            saved.get("runtimeAdmitted") is not False or saved.get("releaseAdmitted") is not False or
            saved.get("nativeGcPassed") is not False or type(observed_exit) is not int or observed_exit not in (0, 1)):
        raise ValueError("non-admitted component receipt and observed parent exit required")
    if (saved.get("status") == "source-schedules-observed") != (observed_exit == 0):
        raise ValueError("parent exit contradicts component result")
    files = {"receipt.json": (receipt, digest(receipt))}

    def add(name, expected):
        path = relative(source, name)
        if name in files or digest(path) != expected:
            raise ValueError("duplicate or changed native observation artifact: " + name)
        files[name] = (path, expected)

    def logs(rows, prefix=""):
        for row in rows:
            name = prefix + row["stage"]
            add(name + ".log", row["rawLogSha256"])
            add(name + ".portable.log", row["portableLogSha256"])

    logs(saved["setup"])
    fixture_name = "gc_notification_candidate_schedule.c"
    for row in saved["results"]:
        policy = row["policy"]
        if policy not in ("baseline", "candidate"):
            raise ValueError("unknown component policy")
        prefix = policy + "/"
        logs(row["stages"], prefix)
        add(prefix + "gc-publish-source.inc", row["publisherSha256"])
        add(prefix + "gc-wait-source.inc", row["waitSha256"])
        add(prefix + "gambit.h", saved["generatedHeaderSha256"])
        add(prefix + fixture_name, saved["inputs"]["models/gambit/native/" + fixture_name])
    # Portable archives retain exact receipt/log bytes only when already clean.
    for name, (path, _) in files.items():
        text = path.read_text()
        if "/Users/" in text or "/private/var/folders/" in text or "/var/folders/" in text:
            raise ValueError("personal or disposable absolute path in archive: " + name)
    destination.mkdir(parents=True, exist_ok=False)
    for name, (path, _) in files.items():
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)
    if any(digest(path) != sha for path, sha in files.values()):
        raise ValueError("observation changed during archival")
    record = dict(schema="gambit-component-observation-archive.v1", observedParentExit=observed_exit,
        archiveOnly=True, runtimeAdmitted=False, releaseAdmitted=False, nativeGcPassed=False,
        files={name: sha for name, (_, sha) in files.items()})
    (destination / "archive.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def source_unit_checked(source, saved):
    if (saved.get("schema") != "gambit-actlog-abort-source-unit.v1"
            or saved.get("status") != "source-unit-pass" or saved.get("sourceStable") is not True
            or saved.get("runtimeAdmitted") is not False or saved.get("releaseAdmitted") is not False):
        raise ValueError("stable non-admitted source-unit observation required")
    rows = {row["label"]: row for row in saved["results"]}
    expected = {"posix": 3, "void-init": 2, "disabled": 1}
    if len(rows) != len(saved["results"]) or set(rows) != set(expected) | {
            "ignored-mutex-error-control", "object-enabled", "object-disabled"}:
        raise ValueError("complete source-unit branch/control/object matrix required")
    for name, row in rows.items():
        if row.get("accepted") is not True:
            raise ValueError("source-unit matrix contains a rejection")
        if name.startswith("object-"):
            if row.get("exit") != 0 or row.get("timeout") is not False:
                raise ValueError("source object compilation failed")
            continue
        if row["compile"]["exit"] != 0 or row["compile"]["timeout"]:
            raise ValueError("source fixture compilation failed")
        result = row["observation"]
        output = (source / (name + "-observe.log")).read_text()
        if name in expected:
            if (result["exit"] != 0 or result["timeout"] or json.loads(output) !=
                    {"checks": expected[name], "arrayLive": 0, "mutexLive": 0}):
                raise ValueError("source-unit log does not support positive result")
        elif result["exit"] != 1 or result["timeout"] or output != "EXPECTED-MUTEX-ERROR\n":
            raise ValueError("source-unit negative control did not fail as expected")


def archive_source_unit(source, destination, observed_exit):
    saved = json.loads((source / "receipt.json").read_text())
    if type(observed_exit) is not int or observed_exit != 0:
        raise ValueError("source-unit archive requires successful observed parent exit")
    source_unit_checked(source, saved)
    files = {"receipt.json": digest(source / "receipt.json"), **saved["artifacts"]}
    for name, expected in files.items():
        path = relative(source, name)
        if digest(path) != expected or any(token in path.read_text() for token in ("/Users/", ".data/")):
            raise ValueError("source-unit artifact changed or contains personal/cache path")
    destination.mkdir(parents=True, exist_ok=False)
    for name in files:
        shutil.copyfile(source / name, destination / name)
    record = dict(schema="gambit-source-unit-archive.v1", archiveOnly=True, observedParentExit=0,
                  runtimeAdmitted=False, releaseAdmitted=False, nativeGcPassed=False, files=files)
    (destination / "archive.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def archive_suite(source, destination, observed_exit, identity):
    """Retain exact scoped suite observations; never promote full runtime admission."""
    from gambit_smp.suite_primitives import admitted_suite, campaign_status
    receipt = source / "receipt.json"
    saved = json.loads(receipt.read_text())
    if (type(observed_exit) is not int or observed_exit not in (0, 1)
            or saved.get("performanceAdmitted") is not False
            or not identity or digest(identity) != saved.get("candidateReceiptSha256")
            or saved.get("status") != campaign_status(saved["results"], saved["modes"])
            or (saved["status"] == "PASS") != (observed_exit == 0)):
        raise ValueError("suite archive requires bound identity and consistent parent exit")
    files = {"receipt.json": receipt, "identity.json": identity}
    for row in saved["results"]:
        files[row["mode"] + ".log"] = source / (row["mode"] + ".log")
        for shard in row.get("process", {}).get("shards", []):
            name = f'{row["mode"]}-{shard["shard"]}.log'
            path = source / name
            accepted = admitted_suite(shard["exit"], path.read_text(), shard["timeout"], len(shard["files"]))
            if shard["accepted"] != (accepted and shard["sourceStable"]):
                raise ValueError("suite shard log contradicts acceptance")
            files[name] = path
    files["processor-probe.log"] = source / "processor-probe.log"
    hashes = {name: digest(path) for name, path in files.items()}
    for name, path in files.items():
        content = path.read_text()
        if any(token in content for token in ("/Users/", "/private/var/folders/", ".data/")):
            raise ValueError("suite archive contains personal or cache path: " + name)
    destination.mkdir(parents=True, exist_ok=False)
    for name, path in files.items():
        shutil.copyfile(path, destination / name)
    if any(digest(path) != hashes[name] or digest(destination / name) != hashes[name]
           for name, path in files.items()):
        raise ValueError("suite observation changed during archival")
    record = {"schema": "gambit-scoped-suite-archive.v1", "archiveOnly": True,
              "observedParentExit": observed_exit, "runtimeAdmitted": False,
              "releaseAdmitted": False, "nativeGcPassed": False, "files": hashes,
              "scope": "Selected native file/mode observations; not full GC, lifecycle or bootstrap acceptance"}
    (destination / "archive.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def failed_suite_checked(saved, identity_sha):
    from gambit_smp.suite_primitives import campaign_status
    atomic = saved.get("schema") == "gambit-upstream-atomic-coverage.v1"
    modes, rows = saved.get("modes"), saved.get("results")
    cap = saved.get("atomicBatchBudgetPerMode" if atomic else "wholeSuiteBudgetPerMode")
    if (saved.get("schema") not in {"gambit-upstream-suite.v1", "gambit-upstream-atomic-coverage.v1"} or saved.get("status") != "DENY"
            or not isinstance(modes, list) or not modes or any(type(mode) is not str for mode in modes)
            or len(modes) != len(set(modes))
            or not set(modes) <= {"gsi", "gsc"} or not isinstance(rows, list)
            or any(not isinstance(row, dict) or type(row.get("mode")) is not str for row in rows)
            or len(rows) != len(modes) or {row.get("mode") for row in rows} != set(modes)
            or any(type(row.get("accepted")) is not bool or type(row.get("exit")) is not int
                   or type(row.get("timeout")) is not bool for row in rows)
            or campaign_status(rows, modes) != "DENY"
            or saved.get("candidateReceiptSha256") != identity_sha
            or type(cap) not in (int, float) or not math.isfinite(cap) or not 0 < cap <= 600
            or any(saved.get(key) is True for key in
                   ("runtimeAdmitted", "releaseAdmitted", "nativeGcPassed", "performanceAdmitted"))):
        raise ValueError("exact failed suite identity, mode results and original budget required")
    if atomic:
        inventory = saved.get("selectedFiles")
        if (not isinstance(inventory, list) or not inventory
                or any(not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts for name in inventory)
                or len(set(inventory)) != len(inventory) or saved.get("filesPerMode") != len(inventory)):
            raise ValueError("atomic history requires its complete original inventory")
        for row in rows:
            batches = row.get("process", {}).get("batches")
            if not isinstance(batches, list) or not batches:
                raise ValueError("atomic history requires observed batches")
            indices, observed = set(), set()
            for batch in batches:
                index, names = batch.get("batch"), batch.get("files")
                if (type(index) is not int or index < 0 or index in indices
                        or not isinstance(names, list) or not names
                        or any(not isinstance(name, str) for name in names) or len(set(names)) != len(names)
                        or not set(names) <= set(inventory) or observed.intersection(names)
                        or type(batch.get("accepted")) is not bool or type(batch.get("exit")) is not int
                        or type(batch.get("timeout")) is not bool):
                    raise ValueError("atomic history batch scope or outcome is unbound")
                indices.add(index)
                observed.update(names)


def failed_suite_logs(saved):
    names = set()
    for row in saved["results"]:
        mode = row["mode"]
        names.add(mode + ".log")
        for shard in row.get("process", {}).get("shards", []):
            names.add(f'{mode}-{shard["shard"]}.log')
        if saved["schema"] == "gambit-upstream-atomic-coverage.v1":
            for batch in row["process"]["batches"]:
                for shard in batch.get("shards", []):
                    index = shard.get("shard")
                    if type(index) is not int or index < 0:
                        raise ValueError("atomic history shard identity is unbound")
                    names.add(f'batches/{mode}/{batch["batch"]}/{mode}-{index}.log')
    return names


def archive_current_suite(source, destination, identity):
    """Retain actual framework shard observations without synthesizing a PASS."""
    preflight = json.loads((source / "retry-preflight.json").read_text())
    campaign = preflight["campaign"]
    groups = json.loads((source / "suite-progress.json").read_text())
    if (preflight.get("schema") != "typed-suite-retry-review.v2"
            or preflight.get("decision") not in {"NOT_REQUIRED", "RETRY_ELIGIBLE"}
            or campaign["candidateReceiptSha256"] != digest(identity)
            or campaign["mode"] not in {"gsi", "gsc"}
            or campaign["regime"] not in {"whole-sequential", "whole-parallel"}
            or not groups or not any(row["accepted"] is False for row in groups)
            or sorted(file for row in groups for file in row["files"]) != sorted(campaign["selectedFiles"])):
        raise ValueError("exact complete failed campaign, groups and identity required")
    originals = {"identity.json": identity, "retry-preflight.json": source / "retry-preflight.json",
                 "suite-progress.json": source / "suite-progress.json"}
    for row in groups:
        name = f'suite-{row["batch"]}-{row["shard"]}'
        for suffix in ("log", "process.json"):
            originals[name + "." + suffix] = source / (name + "." + suffix)
        process = json.loads(originals[name + ".process.json"].read_text())
        if (any(process[key] != row[key] for key in ("exit", "timeout", "seconds"))
                or process.get("parentReaped") is not True or process.get("processGroupQuiescent") is not True):
            raise ValueError("actual child result and completed teardown required")
    before = {name: digest(path) for name, path in originals.items()}
    identity_text = identity.read_text()
    if any(token in identity_text for token in ("/Users/", "/home/", ".data/")):
        raise ValueError("portable exact identity required")
    destination.mkdir(parents=True, exist_ok=False)
    shutil.copyfile(identity, destination / "identity.json")
    archived_logs = {}
    for name, path in originals.items():
        if not name.endswith(".log"):
            continue
        text = re.sub(r"/(?:Users|home)/[^/\s]+", "$HOME", path.read_text())
        text = re.sub(r"\.data/[^\s\"']+", "$CACHE_PATH", text)
        (destination / name).write_text(text)
        archived_logs[name] = digest(destination / name)
    rows = [{"mode": campaign["mode"], "accepted": False, "groups": groups}]
    record = dict(schema="gambit-current-suite-observation.v1", status="DENY", archiveOnly=True,
                  candidateReceiptSha256=digest(identity), selectedFiles=sorted(campaign["selectedFiles"]),
                  sourceFiles={"unit-tests/" + name: sha for name, sha in campaign["selectedFiles"].items()},
                  wholeSuiteBudgetPerMode=campaign["suiteBudgetSeconds"], results=rows,
                  files=archived_logs, originalFiles=before, runtimeAdmitted=False, nativeGcPassed=False,
                  scope="Actual complete selected shard observations; failure retained, not a legacy suite or parent exit")
    if any(digest(path) != before[name] for name, path in originals.items()):
        raise ValueError("current suite observation changed during archival")
    (destination / "receipt.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def archive_interrupted_suite(source, destination, identity, parent):
    """Project interrupted process observations, never reconstruct suite outcomes."""
    originals = {"identity": identity, "parent": parent,
                 "preflight": source / "retry-preflight.json"}
    root = json.loads(parent.read_text())
    preflight = json.loads(originals["preflight"].read_text())
    campaign = preflight["campaign"]
    if (root.get("schema") != "sealed-research-run.v1" or root.get("outcome") != "DENY"
            or root.get("executionLaunched") is not True or root.get("timeout") is not True
            or type(root.get("exit")) is not int or root["exit"] == 0
            or root.get("parentReaped") is not True or root.get("processGroupQuiescent") is not True
            or root.get("childReceiptSha256") is not None
            or root.get("runtimeAdmitted") is not False
            or preflight.get("schema") != "typed-suite-retry-review.v2"
            or preflight.get("decision") not in {"NOT_REQUIRED", "RETRY_ELIGIBLE"}
            or campaign.get("candidateReceiptSha256") != digest(identity)
            or campaign.get("mode") not in {"gsi", "gsc"}
            or root.get("budgetSeconds") != campaign.get("suiteBudgetSeconds")):
        raise ValueError("bound interrupted campaign and observed parent teardown required")
    selected = campaign.get("selectedFiles")
    if (source.resolve() != (parent.parent / "run" / ("native-" + campaign["mode"])).resolve()
            or not isinstance(root.get("engineId"), str)
            or not re.fullmatch(r"[0-9a-f]{64}", root["engineId"])
            or not isinstance(root.get("recipe"), str)
            or not re.fullmatch(r"[a-zA-Z0-9_-]+", root["recipe"])
            or type(root.get("wholeSeconds")) not in (int, float)
            or not math.isfinite(root["wholeSeconds"]) or root["wholeSeconds"] <= 0):
        raise ValueError("same root-owned suite directory and portable engine identity required")
    if (not isinstance(selected, dict) or not selected
            or any(not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts
                   or not isinstance(sha, str) or not re.fullmatch(r"[0-9a-f]{64}", sha)
                   for name, sha in selected.items())):
        raise ValueError("exact interrupted source inventory required")
    rows = []
    for path in sorted(source.glob("suite-*.process.json")):
        if not re.fullmatch(r"suite-[0-9]+-[0-9]+\.process\.json", path.name):
            raise ValueError("unbound suite process name")
        originals[path.name] = path
        value = json.loads(path.read_text())
        complete = value.get("completionObserved")
        if type(complete) is not bool or value.get("state") != ("OBSERVED" if complete else "STARTED"):
            raise ValueError("explicit process observation state required")
        row = {"group": path.name.removesuffix(".process.json"),
               "completionObserved": complete, "suiteAccepted": None}
        if complete:
            if (type(value.get("exit")) is not int or type(value.get("timeout")) is not bool
                    or type(value.get("seconds")) not in (int, float)
                    or not math.isfinite(value["seconds"]) or value["seconds"] < 0
                    or value.get("parentReaped") is not True
                    or value.get("processGroupQuiescent") is not True):
                raise ValueError("completed process observation requires real outcome and teardown")
            row.update({key: value[key] for key in
                        ("exit", "timeout", "seconds", "parentReaped", "processGroupQuiescent")})
        elif any(key in value for key in ("exit", "timeout", "seconds")):
            raise ValueError("unfinished process must not fabricate an outcome")
        log = source / (row["group"] + ".log")
        if log.is_file():
            originals[log.name] = log
        rows.append(row)
    if not rows:
        raise ValueError("actual started suite process observations required")
    before = {name: digest(path) for name, path in originals.items()}
    record = {"schema": "gambit-interrupted-suite-observation.v1", "status": "DENY",
              "archiveOnly": True, "runtimeAdmitted": False, "nativeGcPassed": False,
              "candidateReceiptSha256": digest(identity), "engineId": root["engineId"],
              "recipe": root["recipe"], "selectedFiles": selected,
              "budgetSeconds": root["budgetSeconds"], "wholeSeconds": root["wholeSeconds"],
              "parent": {key: root[key] for key in
                         ("exit", "timeout", "parentReaped", "processGroupQuiescent")},
              "processObservations": rows, "suiteCompletionObserved": False,
              "originalFiles": before,
              "scope": "Partial process observations only; no inferred file completion or suite acceptance"}
    if any(digest(path) != before[name] for name, path in originals.items()):
        raise ValueError("interrupted observations changed during projection")
    destination.mkdir(parents=True, exist_ok=False)
    (destination / "receipt.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def compiler_probe_checked(saved, identity_sha):
    if (saved.get("schema") != "gambit-compiler-cost.v1"
            or saved.get("diagnosticOnly") is not True or saved.get("sourceStable") is not True
            or saved.get("candidateReceiptSha256") != identity_sha
            or not isinstance(saved.get("selection"), str)
            or not isinstance(saved.get("sourceFiles"), dict)
            or saved["sourceFiles"].get("unit-tests/" + saved["selection"]) is None
            or type(saved.get("wholeProbeBudget")) not in (int, float)
            or not math.isfinite(saved["wholeProbeBudget"]) or saved["wholeProbeBudget"] <= 0):
        raise ValueError("stable original compiler probe, scope, budget and exact identity required")
    rows = saved.get("stages", [])
    if (not isinstance(rows, list) or len(rows) != 2
            or any(not isinstance(row, dict) for row in rows)
            or rows[0].get("name") != "scheme-to-c"
            or rows[0].get("accepted") is not True or rows[0].get("exit") != 0
            or rows[0].get("timeout") is not False
            or not isinstance(rows[0].get("artifactSha256"), str)
            or not re.fullmatch(r"[0-9a-f]{64}", rows[0]["artifactSha256"])
            or rows[1].get("name") != "c-to-dynamic-module"
            or rows[1].get("accepted") is not False or rows[1].get("timeout") is not True
            or type(rows[1].get("exit")) is not int or rows[1]["exit"] == 0):
        raise ValueError("original completed C generation and failed C-module phase required")


def compiler_invocation(log):
    lines = log.splitlines()
    if len(lines) != 1:
        raise ValueError("one unambiguous original compiler invocation required")
    argv = shlex.split(lines[0])
    if (not argv or re.fullmatch(r"gcc(?:-[0-9]+)?", Path(argv[0]).name) is None
            or any(word in {";", "&&", "||", "|", ">", "<"} for word in argv)
            or argv.count("-o") != 1 or argv[-1] != "probe.c"
            or argv.index("-o") + 1 >= len(argv)
            or argv[argv.index("-o") + 1] != "probe.o1" or "-bundle" not in argv):
        raise ValueError("recorded GNU dynamic-module command shape required")
    levels = [int(word[2:]) for word in argv if word in {"-O0", "-O1", "-O2", "-O3"}]
    if len(levels) != 1 or any(word.startswith("-O") and word not in {"-O0", "-O1", "-O2", "-O3"} for word in argv):
        raise ValueError("one explicit original optimization level required")
    includes = [word for word in argv if word.startswith("-I")]
    if len(includes) != 1 or not includes[0].endswith("/include"):
        raise ValueError("one recorded runtime include directory required")
    portable = [Path(argv[0]).name, *("-I$RUNTIME/include" if word == includes[0] else word for word in argv[1:])]
    if any("/Users/" in word or "/home/" in word or ".data/" in word for word in portable):
        raise ValueError("compiler projection contains a personal or cache path")
    return {"compilerBasename": portable[0], "optimizationLevel": levels[0],
            "argv": portable, "input": "probe.c", "output": "probe.o1", "phase": "c-to-dynamic-module"}


def configure_projection(command):
    argv = shlex.split(command)
    if (not argv or argv[0] != "./configure"
            or any(word in {";", "&&", "||", "|", ">", "<"} for word in argv)):
        raise ValueError("embedded configure command required")
    def unique(prefix):
        values = [word[len(prefix):] for word in argv if word.startswith(prefix)]
        if len(values) != 1:
            raise ValueError("one embedded binding required: " + prefix)
        return values[0]
    level = unique("--enable-c-opt=")
    compiler = Path(unique("CC=")).name
    if level not in {"-O0", "-O1", "-O2", "-O3"} or re.fullmatch(r"gcc(?:-[0-9]+)?", compiler) is None:
        raise ValueError("explicit GNU build configuration required")
    required = {"--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"}
    if (not required <= set(argv) or any(argv.count(word) != 1 for word in required)
            or any(word.startswith(option + "=") for word in argv for option in required)
            or any(word.startswith("--disable-") and word[10:].split("=", 1)[0] in
                   {"smp", "multiple-vms", "multiple-threaded-vms"} for word in argv)):
        raise ValueError("all three concurrency switches required")
    portable = ["--prefix=$PREFIX" if word.startswith("--prefix=") else
                "CC=" + compiler if word.startswith("CC=") else word for word in argv]
    if any(token in word for word in portable for token in ("/Users/", "/home/", ".data/", "/private/var/")):
        raise ValueError("embedded configuration contains an unprojected personal/cache path")
    return {"argv": portable, "compilerBasename": compiler,
            "optimizationLevel": int(level[2:]), "concurrencySwitches": sorted(required)}


def embedded_configuration(binary):
    data = binary.read_bytes()
    start, found = 0, []
    while True:
        offset = data.find(b"./configure ", start)
        if offset < 0:
            break
        end = data.find(b"\0", offset)
        if end < 0 or end - offset > 16384:
            raise ValueError("unterminated or oversized embedded configuration")
        raw = data[offset:end]
        found.append((offset, raw, configure_projection(raw.decode("ascii"))))
        start = end + 1
    if len(found) != 1:
        raise ValueError("one unambiguous image-bound configure string required")
    offset, raw, projected = found[0]
    return {**projected, "offset": offset, "rawBytes": len(raw),
            "rawConfigureSha256": hashlib.sha256(raw).hexdigest()}


def archive_compiler_configuration(history, binary, destination):
    if destination.exists():
        raise ValueError("fresh configuration observation required")
    inputs = validate(history.parent, history.name)
    saved = json.loads(history.read_text())
    receipt = json.loads((history.parent / "receipt.json").read_text())
    identity = json.loads((history.parent / "identity.json").read_text())
    before = digest(binary)
    if (saved["schema"] != "gambit-failed-suite-archive.v1"
            or before != receipt.get("gscSha256") or before != identity.get("gscSha256")
            or not any(row["mode"] == "gsc" and row["accepted"] is False for row in receipt["results"])):
        raise ValueError("original failed compiled suite and exact original compiler image required")
    observation = embedded_configuration(binary)
    if not receipt.get("compiler", "").startswith(observation["compilerBasename"] + " "):
        raise ValueError("embedded compiler and original compiler description differ")
    if before != digest(binary) or any(digest(history.parent / Path(name).name) != sha
                                      for name, sha in inputs.items()):
        raise ValueError("compiler configuration inputs changed during inspection")
    record = {"schema": "gambit-compiler-configuration-observation.v1", "archiveOnly": True,
              "runtimeAdmitted": False, "releaseAdmitted": False, "nativeGcPassed": False,
              "receiptSha256": saved["files"]["receipt.json"],
              "candidateReceiptSha256": saved["files"]["identity.json"],
              "gscSha256": before, "configuration": observation,
              "historicalDriverSha256": None, "historicalCommandObserved": False,
              "scope": "Image-bound embedded build configuration, not a recorded invocation or driver digest"}
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(record, indent=2) + "\n")
    return record


def archive_compiler_probe(source, destination, identity):
    if identity is None:
        raise ValueError("exact compiler-probe candidate identity required")
    receipt = source / "receipt.json"
    saved = json.loads(receipt.read_text())
    compiler_probe_checked(saved, digest(identity))
    descriptor = json.loads(identity.read_text())
    if saved.get("gscSha256") != descriptor.get("gscSha256"):
        raise ValueError("compiler probe and original candidate binary differ")
    generated = source / "runtime/tests/probe.c"
    if digest(generated) != saved["stages"][0]["artifactSha256"]:
        raise ValueError("original generated C differs from its phase receipt")
    originals = {"receipt.json": receipt, "identity.json": identity,
                 "scheme-to-c.log": source / "scheme-to-c.log",
                 "c-to-dynamic-module.log": source / "c-to-dynamic-module.log"}
    before = {name: digest(path) for name, path in originals.items()}
    invocation = compiler_invocation(originals["c-to-dynamic-module.log"].read_text())
    if not saved.get("compiler", "").startswith(invocation["compilerBasename"] + " "):
        raise ValueError("logged compiler differs from the original compiler description")
    for name in ("receipt.json", "identity.json"):
        if any(token in originals[name].read_text() for token in ("/Users/", "/home/", ".data/")):
            raise ValueError("compiler-probe metadata is not portable")
    destination.mkdir(parents=True, exist_ok=False)
    for name, path in originals.items():
        if name.endswith(".json"):
            shutil.copyfile(path, destination / name)
        elif name == "c-to-dynamic-module.log":
            (destination / name).write_text(shlex.join(invocation["argv"]) + "\n")
        else:
            text = re.sub(r"/(?:Users|home)/[^/\s]+", "$HOME", path.read_text())
            text = re.sub(r"\.data/[^\s\"']+", "$CACHE_PATH", text)
            (destination / name).write_text(text)
    invocation.update(originalLogSha256=before["c-to-dynamic-module.log"],
                      generatedCArtifactSha256=digest(generated),
                      rawLogBoundByOriginalReceipt=False)
    (destination / "compiler-invocation.json").write_text(json.dumps(invocation, indent=2) + "\n")
    if any(digest(path) != before[name] for name, path in originals.items()) or digest(generated) != saved["stages"][0]["artifactSha256"]:
        raise ValueError("compiler-probe inputs changed during archival")
    names = {*originals, "compiler-invocation.json"}
    record = dict(schema="gambit-compiler-probe-archive.v1", archiveOnly=True,
                  runtimeAdmitted=False, releaseAdmitted=False, nativeGcPassed=False,
                  observedParentExit=None, files={name: digest(destination / name) for name in names},
                  originalFiles=before, generatedCArtifactSha256=invocation["generatedCArtifactSha256"],
                  rawLogBoundByOriginalReceipt=False,
                  scope="Exact original failed compiler phase and explicit log association; generated C validated but not copied, no driver digest or parent outcome invented")
    (destination / "archive.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def archive_failed_suite(source, destination, identity):
    """Recover a failed observation without inventing the historical parent exit."""
    if identity is None:
        raise ValueError("exact failed suite identity required")
    saved = json.loads((source / "receipt.json").read_text())
    failed_suite_checked(saved, digest(identity))
    originals = {"receipt.json": source / "receipt.json", "identity.json": identity,
                 "processor-probe.log": source / "processor-probe.log"}
    for name in failed_suite_logs(saved):
        originals[name] = source / name
    before = {name: digest(path) for name, path in originals.items()}
    for name in ("receipt.json", "identity.json"):
        if any(token in originals[name].read_text() for token in ("/Users/", "/home/", "/private/var/folders/", ".data/")):
            raise ValueError("exact failed-suite metadata contains personal/cache paths")
    for row in saved["results"]:
        if "rawLogSha256" in row and row["rawLogSha256"] != before[row["mode"] + ".log"]:
            raise ValueError("original suite raw-log binding differs")
    destination.mkdir(parents=True, exist_ok=False)
    for name, path in originals.items():
        (destination / name).parent.mkdir(parents=True, exist_ok=True)
        if name.endswith(".json"):
            shutil.copyfile(path, destination / name)
        else:
            text = re.sub(r"/(?:Users|home)/[^/\s]+", "$HOME", path.read_text())
            text = re.sub(r"/private/var/folders/[^\s\"']+", "$TEMP_PATH", text)
            text = re.sub(r"\.data/[^\s\"']+", "$CACHE_PATH", text)
            (destination / name).write_text(text)
    if any(digest(path) != before[name] for name, path in originals.items()):
        raise ValueError("failed-suite inputs changed during archival")
    files = {name: digest(destination / name) for name in originals}
    record = dict(schema="gambit-failed-suite-archive.v1", archiveOnly=True,
                  runtimeAdmitted=False, releaseAdmitted=False, nativeGcPassed=False,
                  observedParentExit=None, files=files, originalFiles=before,
                  logTransform="home-temp-cache-redaction-v1",
                  rawLogsBoundByOriginalReceipt={row["mode"]: "rawLogSha256" in row for row in saved["results"]},
                  scope="Historical failed suite and partial completion only; no parent exit, root cause or retry permission inferred")
    (destination / "archive.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def archive_bootstrap(source, destination, identity):
    """Retain historical failed build inputs without inventing its parent exit."""
    receipt, log = source / "receipt.json", source / "bootstrap.log"
    saved = json.loads(receipt.read_text())
    if (saved.get("schema") != "gambit-two-pass-bootstrap.v1" or saved.get("status") != "DENY"
            or not identity or digest(identity) != saved.get("seedReceiptSha256")
            or type(saved.get("wholeBootstrapBudget")) not in (int, float)
            or saved["wholeBootstrapBudget"] <= 0
            or not any(row.get("name") == "from-scratch" and type(row.get("exit")) is int
                       and row["exit"] != 0 for row in saved.get("steps", []))
            or not log.is_file() or not log.stat().st_size):
        raise ValueError("failed bootstrap receipt, original budget, raw log and exact seed identity required")
    originals = {"receipt.json": receipt, "identity.json": identity, "bootstrap.log": log}
    before = {name: digest(path) for name, path in originals.items()}
    if "rawLogSha256" in saved and saved["rawLogSha256"] != before["bootstrap.log"]:
        raise ValueError("original bootstrap raw-log binding differs")
    for name in ("receipt.json", "identity.json"):
        if any(token in originals[name].read_text() for token in ("/Users/", "/private/var/folders/")):
            raise ValueError("exact bootstrap metadata contains personal paths: " + name)
    text = log.read_text()
    text = re.sub(r"/Users/[^/\s]+", "$HOME", text)
    text = re.sub(r"/private/var/folders/[^\s\"']+", "$TEMP_PATH", text)
    destination.mkdir(parents=True, exist_ok=False)
    for name in ("receipt.json", "identity.json"):
        shutil.copyfile(originals[name], destination / name)
    (destination / "bootstrap.log").write_text(text)
    if any(digest(path) != before[name] for name, path in originals.items()):
        raise ValueError("bootstrap inputs changed during archival")
    files = {name: digest(destination / name) for name in originals}
    record = dict(schema="gambit-failed-bootstrap-archive.v1", archiveOnly=True,
                  runtimeAdmitted=False, releaseAdmitted=False, nativeGcPassed=False,
                  observedParentExit=None, files=files, originalFiles=before,
                  logTransform="home-prefix-and-temporary-path-redaction-v1",
                  rawLogBoundByOriginalReceipt="rawLogSha256" in saved,
                  scope="Historical failed command observation; not root cause, retry permission or runtime admission")
    (destination / "archive.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def validate(root, name):
    root = root.resolve()
    manifest = relative(root, name)
    saved = json.loads(manifest.read_text())
    if (saved.get("schema") not in {"gambit-component-observation-archive.v1", "gambit-scoped-suite-archive.v1", "gambit-source-unit-archive.v1", "gambit-failed-bootstrap-archive.v1", "gambit-failed-suite-archive.v1", "gambit-compiler-probe-archive.v1"} or
            saved.get("archiveOnly") is not True or
            any(saved.get(key) is not False for key in ("runtimeAdmitted", "releaseAdmitted", "nativeGcPassed"))):
        raise ValueError("component archive must remain non-admitted")
    inputs = {name: digest(manifest)}
    for filename, expected in saved["files"].items():
        path = relative(manifest.parent, filename)
        if digest(path) != expected:
            raise ValueError("component archive artifact changed: " + filename)
        relative_name = path.relative_to(root).as_posix()
        if ".data" in Path(relative_name).parts:
            raise ValueError("component archive must not require cache inputs")
        inputs[relative_name] = expected
    if "receipt.json" not in saved["files"]:
        raise ValueError("component archive receipt missing")
    receipt = json.loads((manifest.parent / "receipt.json").read_text())
    if saved["schema"] == "gambit-compiler-probe-archive.v1":
        compiler_probe_checked(receipt, saved["files"].get("identity.json"))
        expected = {"receipt.json", "identity.json", "scheme-to-c.log", "c-to-dynamic-module.log", "compiler-invocation.json"}
        command = json.loads((manifest.parent / "compiler-invocation.json").read_text())
        parsed = compiler_invocation((manifest.parent / "c-to-dynamic-module.log").read_text())
        if (set(saved["files"]) != expected or set(saved["originalFiles"]) != expected - {"compiler-invocation.json"}
                or saved.get("observedParentExit") is not None or saved.get("rawLogBoundByOriginalReceipt") is not False
                or any(saved["files"][name] != saved["originalFiles"][name] for name in ("receipt.json", "identity.json"))
                or any(command.get(key) != value for key, value in parsed.items())
                or command.get("originalLogSha256") != saved["originalFiles"]["c-to-dynamic-module.log"]
                or command.get("rawLogBoundByOriginalReceipt") is not False
                or command.get("generatedCArtifactSha256") != receipt["stages"][0]["artifactSha256"]
                or saved.get("generatedCArtifactSha256") != command.get("generatedCArtifactSha256")):
            raise ValueError("compiler-probe archive identity or historical boundary changed")
        identity = json.loads((manifest.parent / "identity.json").read_text())
        if (receipt.get("gscSha256") != identity.get("gscSha256")
                or not isinstance(receipt.get("compiler"), str)
                or not receipt["compiler"].startswith(parsed["compilerBasename"] + " ")):
            raise ValueError("original compiler binary binding differs")
        return inputs
    if saved["schema"] == "gambit-failed-suite-archive.v1":
        failed_suite_checked(receipt, saved["files"].get("identity.json"))
        expected = {"receipt.json", "identity.json", "processor-probe.log"}
        expected.update(failed_suite_logs(receipt))
        if (saved.get("observedParentExit") is not None
                or set(saved["files"]) != expected or set(saved["originalFiles"]) != expected
                or any(saved["files"].get(key) != saved["originalFiles"].get(key) for key in ("receipt.json", "identity.json"))
                or "processor-probe.log" not in saved["files"]
                or any(mode + ".log" not in saved["files"] for mode in receipt["modes"])
                or saved.get("rawLogsBoundByOriginalReceipt") !=
                   {row["mode"]: "rawLogSha256" in row for row in receipt["results"]}):
            raise ValueError("failed-suite archive identity or historical boundary changed")
        for row in receipt["results"]:
            if "rawLogSha256" in row and row["rawLogSha256"] != saved["originalFiles"][row["mode"] + ".log"]:
                raise ValueError("failed-suite original raw-log binding changed")
        return inputs
    if saved["schema"] == "gambit-failed-bootstrap-archive.v1":
        if (receipt.get("schema") != "gambit-two-pass-bootstrap.v1" or receipt.get("status") != "DENY"
                or saved.get("observedParentExit") is not None
                or set(saved["files"]) != {"receipt.json", "identity.json", "bootstrap.log"}
                or saved["files"]["identity.json"] != receipt.get("seedReceiptSha256")
                or any(saved["files"][key] != saved["originalFiles"][key] for key in ("receipt.json", "identity.json"))):
            raise ValueError("failed bootstrap archive identity or historical boundary changed")
        return inputs
    if saved["schema"] == "gambit-source-unit-archive.v1":
        if type(saved.get("observedParentExit")) is not int or saved["observedParentExit"] != 0:
            raise ValueError("source-unit parent exit differs")
        if not set(receipt["artifacts"]).issubset(saved["files"]):
            raise ValueError("source-unit artifacts omitted")
        source_unit_checked(manifest.parent, receipt)
        return inputs
    if saved["schema"] == "gambit-scoped-suite-archive.v1":
        from gambit_smp.suite_primitives import admitted_suite, campaign_status
        if (receipt.get("schema") != "gambit-upstream-suite.v1"
                or receipt.get("performanceAdmitted") is not False
                or "identity.json" not in saved["files"]
                or digest(manifest.parent / "identity.json") != receipt.get("candidateReceiptSha256")
                or type(saved.get("observedParentExit")) is not int
                or saved["observedParentExit"] not in (0, 1)
                or receipt.get("status") != campaign_status(receipt["results"], receipt["modes"])
                or (receipt["status"] == "PASS") != (saved["observedParentExit"] == 0)):
            raise ValueError("scoped suite archive identity or exit mismatch")
        for row in receipt["results"]:
            for shard in row.get("process", {}).get("shards", []):
                name = f'{row["mode"]}-{shard["shard"]}.log'
                if name not in saved["files"]:
                    raise ValueError("suite shard log missing")
                accepted = admitted_suite(shard["exit"], (manifest.parent / name).read_text(),
                                          shard["timeout"], len(shard["files"]))
                if shard["accepted"] != (accepted and shard["sourceStable"]):
                    raise ValueError("suite shard log contradicts acceptance")
        return inputs
    if (receipt.get("schema") != "gambit-notification-source-schedules.v1" or
            type(saved.get("observedParentExit")) is not int or saved["observedParentExit"] not in (0, 1) or
            receipt.get("runtimeAdmitted") is not False or receipt.get("releaseAdmitted") is not False or
            receipt.get("nativeGcPassed") is not False or
            (receipt.get("status") == "source-schedules-observed") != (saved.get("observedParentExit") == 0)):
        raise ValueError("component receipt/archive admission or exit mismatch")
    return inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--observed-parent-exit", type=int,
                        help="omit only for failed histories whose parent exit was not recorded")
    parser.add_argument("--identity", type=Path, help="exact candidate identity required for scoped suite archival")
    parser.add_argument("--compiler-image", type=Path,
                        help="inspect a historical compiler image against --source archive.json; never execute it")
    parser.add_argument("--interrupted-parent", type=Path,
                        help="archive partial suite process observations against an actual timed-out root receipt")
    args = parser.parse_args()
    if args.interrupted_parent is not None:
        if args.identity is None or args.compiler_image is not None or args.observed_parent_exit is not None:
            raise ValueError("interrupted observation requires identity and no invented exit or compiler image")
        record = archive_interrupted_suite(args.source, args.out, args.identity, args.interrupted_parent)
        print(json.dumps({"schema": record["schema"], "status": record["status"],
                          "processes": len(record["processObservations"]), "runtimeAdmitted": False}))
        return
    if args.compiler_image is not None:
        if args.identity is not None or args.observed_parent_exit is not None or args.out.exists():
            raise ValueError("fresh compiler-configuration observation without invented parent exit required")
        record = archive_compiler_configuration(args.source, args.compiler_image, args.out)
        print(json.dumps({"schema": record["schema"], "runtimeAdmitted": False}))
        return
    record = archive(args.source, args.out, args.observed_parent_exit, args.identity)
    print(json.dumps(dict(artifacts=len(record["files"]), runtimeAdmitted=False)))


if __name__ == "__main__":
    main()
