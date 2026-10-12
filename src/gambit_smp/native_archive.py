"""Archive component observations without granting native/runtime admission."""
import argparse
import json
from pathlib import Path
import shutil

from gambit_smp.framework import digest, relative


def archive(source, destination, observed_exit, identity=None):
    source = source.resolve(strict=True)
    receipt = source / "receipt.json"
    saved = json.loads(receipt.read_text())
    if saved.get("schema") == "gambit-actlog-abort-source-unit.v1":
        return archive_source_unit(source, destination, observed_exit)
    if saved.get("schema") == "gambit-upstream-suite.v1":
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
    from gambit_smp.native_suite import admitted_suite, campaign_status
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


def validate(root, name):
    root = root.resolve()
    manifest = relative(root, name)
    saved = json.loads(manifest.read_text())
    if (saved.get("schema") not in {"gambit-component-observation-archive.v1", "gambit-scoped-suite-archive.v1", "gambit-source-unit-archive.v1"} or
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
    if saved["schema"] == "gambit-source-unit-archive.v1":
        if type(saved.get("observedParentExit")) is not int or saved["observedParentExit"] != 0:
            raise ValueError("source-unit parent exit differs")
        if not set(receipt["artifacts"]).issubset(saved["files"]):
            raise ValueError("source-unit artifacts omitted")
        source_unit_checked(manifest.parent, receipt)
        return inputs
    if saved["schema"] == "gambit-scoped-suite-archive.v1":
        from gambit_smp.native_suite import admitted_suite, campaign_status
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
    parser.add_argument("--observed-parent-exit", type=int, required=True)
    parser.add_argument("--identity", type=Path, help="exact candidate identity required for scoped suite archival")
    args = parser.parse_args()
    record = archive(args.source, args.out, args.observed_parent_exit, args.identity)
    print(json.dumps(dict(artifacts=len(record["files"]), runtimeAdmitted=False)))


if __name__ == "__main__":
    main()
