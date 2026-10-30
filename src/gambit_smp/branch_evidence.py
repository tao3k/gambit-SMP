"""Branch qualification identities and verdicts; execution stays with recipes.

A dirty vendor checkout is not a branch producer. Source bytes come from a
fixed Git archive and observations must bind that revision, its manifest and
the declared profile. Patch-line progress is deliberately not an input.
"""
import hashlib
import io
import json
from pathlib import PurePosixPath
import tarfile


def content_digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True,
                                    separators=(",", ":")).encode()).hexdigest()


def archive_sources(raw):
    """Read immutable Git archive bytes without creating another checkout."""
    sources = {}
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        for entry in archive:
            name = PurePosixPath(entry.name)
            if name.is_absolute() or ".." in name.parts or str(name) in {"", "."}:
                raise ValueError("safe relative Git source path required")
            if entry.isdir():
                continue
            if str(name) in sources:
                raise ValueError("duplicate archive source")
            if entry.isfile():
                data = archive.extractfile(entry).read()
                mode = "100755" if entry.mode & 0o111 else "100644"
            elif entry.issym():
                data, mode = entry.linkname.encode(), "120000"
            else:
                raise ValueError("unsupported Git source kind")
            sources[str(name)] = {"mode": mode, "sha256": hashlib.sha256(data).hexdigest(),
                                  "bytes": len(data), "data": data}
    if not sources:
        raise ValueError("nonempty Git source archive required")
    return sources


def source_manifest(sources):
    return {name: {key: row[key] for key in ("mode", "sha256", "bytes")}
            for name, row in sorted(sources.items())}


def canonical_source(name):
    """Generated checked-in files keep their own producer identity after build."""
    path = PurePosixPath(name)
    return not (name in {"configure", "aclocal.m4"}
                or (path.parent.name in {"lib", "gsi", "gsc"}
                    and path.name.startswith("_") and path.suffix == ".c"))


def unit_inventory(manifest, *, stress=False):
    """Match the upstream runner's unit/stress input classification."""
    return sorted(name for name in manifest
                  if name.startswith("tests/unit-tests/") and name.endswith(".scm")
                  and PurePosixPath(name).name != "#.scm"
                  and name.endswith("_stress.scm") == stress)


def bind_case(plan, case, producer):
    if case not in plan["cases"]:
        raise ValueError("declared branch case required")
    for field in ("revision", "tree", "sourceManifestSha256", "profileSha256"):
        if producer.get(field) != plan.get(field):
            raise ValueError("branch producer mismatch: " + field)
    if producer.get("sourceOverlay") is not False:
        raise ValueError("branch qualification cannot borrow a research overlay")
    if not producer.get("artifacts"):
        raise ValueError("explicit native artifact identity required")
    return {"case": case, "planSha256": content_digest(plan),
            "producerSha256": content_digest(producer),
            "revision": plan["revision"], "definition": plan["cases"][case]}


def case_verdict(binding, process, *, contract_complete):
    """A successful process alone never means complete original coverage."""
    complete = (process.get("exit") == 0 and process.get("timeout") is False
                and process.get("parentReaped") is True
                and process.get("processGroupQuiescent") is True
                and contract_complete is True)
    if complete:
        status = "PASS"
    elif process.get("exit") is None or process.get("processGroupQuiescent") is not True:
        status = "UNRESOLVED"
    else:
        status = "FAIL"
    return {"case": binding["case"], "revision": binding["revision"],
            "planSha256": binding["planSha256"],
            "producerSha256": binding["producerSha256"],
            "status": status, "contractComplete": contract_complete,
            "process": process, "runtimeAdmitted": False,
            "inheritedPatchCredit": False, "aggregateProgress": None}


def progress(plan, producer, observations):
    """Report only this producer; leave semantic gate acceptance explicit."""
    statuses = {}
    for name in plan["cases"]:
        binding = bind_case(plan, name, producer)
        observation = observations.get(name)
        if observation is None:
            statuses[name] = "NOT-RUN"
            continue
        for field in ("revision", "planSha256", "producerSha256"):
            if observation.get(field) != binding[field]:
                raise ValueError("observation cannot transfer across branch producers")
        if observation.get("case") != name:
            raise ValueError("case identity mismatch")
        checked = case_verdict(binding, observation["process"],
                               contract_complete=observation["contractComplete"])
        if observation.get("status") != checked["status"]:
            raise ValueError("case status contradicts its terminal evidence")
        statuses[name] = observation["status"]
    return {"branch": plan["branch"], "revision": plan["revision"],
            "producerSha256": content_digest(producer), "cases": statuses,
            "requirements": {name: "UNESTABLISHED" for name in plan["requirements"]},
            "aggregateProgress": None, "inheritedPatchCredit": False}
