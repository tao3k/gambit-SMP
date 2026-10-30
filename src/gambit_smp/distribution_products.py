"""Qualify Git distribution products through the existing configure/Make service.

This owns no process executor, profile format or workspace copy. Callers supply
the established ExecutionContext and lease its existing mutable workspace.
"""
from pathlib import Path
import hashlib
import json
import os
import re

from gambit_smp.branch_evidence import archive_sources, canonical_source, source_manifest, unit_inventory
from gambit_smp.gambit_build_primitives import BootstrapPhaseProgress, build_errors
from gambit_smp.native_capabilities import bootstrap_phase_counts, configure_owned_source
from gambit_smp.native_development import configuration_request, generated_inventory
from gambit_smp.task_processes import run
from gambit_smp.workspace import checkpoint_build_source


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def git(repository, *arguments):
    p = run(["git", "-C", str(repository), *arguments], capture_output=True,
            timeout=30)
    if p.returncode:
        raise ValueError(p.stderr.decode(errors="replace"))
    return p.stdout


def retired_sources(old, desired, declared):
    """Require exact source retirement, never infer permission from absence."""
    removed = sorted(n for n in old if canonical_source(n) and n not in desired)
    declared = list(declared)
    if len(set(declared)) != len(declared) or sorted(declared) != removed:
        raise ValueError("explicit exact source retirement required")
    if any(old[n]["mode"] == "120000" for n in removed):
        raise ValueError("source retirement cannot follow a symlink")
    return removed


def native_inputs_equal(parent, desired):
    """Tests may change; every other source/product/mode remains byte-bound."""
    def inputs(tree):
        return {name: (row["mode"], row["sha256"]) for name, row in tree.items()
                if not name.startswith("tests/")}
    return inputs(parent) == inputs(desired)


def qualify(ctx, repository, source, target_tree, profile, proof, *, merge_parent=None,
            flags=None, check_monolithic=True, publish_generated=True,
            resume=None, resume_storage=None, source_removals=(), source_parent=None, source_predecessor=None):
    """Generate a selected source tree, then qualify its stock-C consumer.

    A failed attempt remains in place and retains its outputs and command
    receipts; it never reinstalls an old artifact as if it matched new sources.
    """
    source, repository = Path(source), Path(repository)
    base = git(repository, "rev-parse", "HEAD").decode().strip()
    old = archive_sources(git(repository, "archive", base))
    desired = archive_sources(git(repository, "archive", target_tree))
    manifest = source_manifest(desired)
    if resume and (resume["baseRevision"] != base or resume["targetTree"] != target_tree
                   or resume.get("complete")):
        raise ValueError("resume requires the exact unfinished source candidate")
    if resume and source_parent is not None:
        raise ValueError("unfinished resume and completed source parent are distinct")
    parent_sources = None
    owned = old
    if source_predecessor is not None:
        # An incomplete development generation may supply source custody only.
        # It supplies no completed stage, reusable compiler or native admission.
        if resume is not None or source_parent is not None:
            raise ValueError("unfinished source predecessor is not resume or completed reuse")
        if source_predecessor.get("baseRevision") != base:
            raise ValueError("same-base source predecessor required")
        predecessor_tree = source_predecessor["targetTree"]
        owned = archive_sources(git(repository, "archive", predecessor_tree))
        parent_sources = source_manifest(owned)
    parent_publication = None
    if source_parent is not None:
        if source_parent.get("producerComplete") is not True:
            raise ValueError("completed same-base source parent required")
        if source_parent.get("baseRevision") != base:
            # Publishing an already-qualified tree changes its commit identity,
            # not its source/artifact identity. The ordinary full source and
            # product checks below still apply before any workspace mutation.
            published_tree = git(repository, "rev-parse", base + "^{tree}").decode().strip()
            if published_tree != source_parent.get("targetTree"):
                raise ValueError("completed parent must be the exact published base tree")
            parent_publication = dict(commit=base, tree=published_tree,
                                      priorBaseRevision=source_parent["baseRevision"])
        owned = archive_sources(git(repository, "archive", source_parent["targetTree"]))
        parent_sources = source_manifest(owned)
        canonical_parent = {n: row["sha256"] for n, row in parent_sources.items()
                            if canonical_source(n) and row["mode"] != "120000"}
        if canonical_parent != source_parent.get("canonicalSources"):
            raise ValueError("complete parent canonical source identity required")
        for field in ("artifacts", "generatedArtifacts"):
            if not source_parent.get(field):
                raise ValueError("explicit parent native and generated identities required")
            for name, expected in source_parent[field].items():
                if Path(name).is_absolute() or ".." in Path(name).parts:
                    raise ValueError("workspace-relative parent artifact required")
                if sha(source / name) != expected:
                    raise ValueError("completed source parent artifact drift: " + name)
    expected_source = manifest if resume else (parent_sources or source_manifest(old))
    for name, row in expected_source.items():
        if canonical_source(name) and row["mode"] != "120000":
            if sha(source / name) != row["sha256"]:
                raise ValueError("unowned workspace source delta: " + name)
    changes = [n for n, row in manifest.items()
               if canonical_source(n) and row["mode"] != "120000"
               and (n not in owned or desired[n]["data"] != owned[n]["data"])]
    removed = retired_sources(owned, desired, source_removals)
    for name in removed:
        path = source / name
        if path.is_symlink() or (not resume and not path.is_file()):
            raise ValueError("regular owned retirement source required: " + name)
    if resume:
        saved = Path(resume_storage)
        if not saved.resolve().is_relative_to(ctx.directory.parent.parent.resolve()):
            raise ValueError("resume seed must belong to the same task cache")
        for name, expected in resume["priorArtifacts"].items():
            donor = saved / "prior-seed" / name
            if donor.is_symlink() or sha(donor) != expected:
                raise ValueError("preserved bootstrap input changed")
            target = source / name
            if not target.exists():
                target.write_bytes(donor.read_bytes())
                target.chmod(donor.stat().st_mode & 0o777)
    # Keep the old compiler independently recoverable without cloning sources.
    seed = ctx.directory / "prior-seed"
    seed.mkdir(exist_ok=False)
    prior = {}
    for name in ("gsi/gsi", "gsc/gsc", "gsc-boot", "lib/libgambit.a"):
        path = source / name
        prior[name] = sha(path)
        target = seed / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(path.read_bytes())
        target.chmod(path.stat().st_mode & 0o777)
        if sha(target) != prior[name] or os.path.samefile(path, target):
            raise ValueError("independent prior seed preservation failed")
    for name in changes:
        target = source / name
        if target.is_symlink():
            raise ValueError("source overlay cannot follow a symlink")
        if not target.exists() or sha(target) != manifest[name]["sha256"]:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(desired[name]["data"])
            target.chmod(int(manifest[name]["mode"], 8) & 0o777)
    for name in removed:
        path = source / name
        if path.exists():
            path.unlink()
    result = dict(complete=False, baseRevision=base, targetTree=target_tree,
                  priorArtifacts=prior, checks=[], sourcePaths=changes,
                  sourceCopies=0, wholeSmpAdmitted=False, sourceRemovals=removed,
                  wholeLimitSeconds=600, heapRaised=False, waitExtended=False)
    if source_parent is not None:
        result["sourceParent"] = dict(targetTree=source_parent["targetTree"],
                                     artifacts=source_parent["artifacts"],
                                     canonicalSources=source_parent["canonicalSources"])
        if parent_publication is not None:
            result["sourceParent"]["publication"] = parent_publication
    if source_predecessor is not None:
        result["sourcePredecessor"] = dict(
            targetTree=source_predecessor["targetTree"],
            completedStagesReused=False, nativeAdmissionInherited=False)
    if merge_parent:
        result["mergeParent"] = merge_parent

    def execute(name, argv, cwd, cap, *, boundary=None):
        code, log, timed, seconds = ctx.run(
            name, argv, cwd, min(cap, ctx.remaining()),
            **({"boundary": boundary} if boundary else {}))
        p = ctx.commands[-1]
        ok = (code == 0 and not timed and p["parentReaped"]
              and p["processGroupQuiescent"] is True and not build_errors(log))
        row = dict(stage=name, complete=ok, exit=code, timeout=timed,
                   seconds=seconds, tail=log[-700:])
        result["checks"].append(row)
        print(json.dumps({k: row[k] for k in ("stage", "complete", "seconds")}), flush=True)
        if not ok:
            raise ValueError(log[-1800:])
        return log

    try:
        # Read the existing job's feature flags, never add a persistent profile.
        if flags is None:
            line = next(x.strip() for x in desired[".github/workflows/ci.yml"]["data"].decode().splitlines()
                        if x.strip().startswith("./configure --enable-c-opt=-O0"))
            flags = line.split("&&", 1)[0].split()[1:]
        mode = dict(profile, flags=flags)
        result["configurationFlags"] = flags
        request = configuration_request(source, mode, ctx.tools, proof["requestIdentity"]["environment"])
        headers = {n: sha(source / n) for n in ("include/gambit.h", "include/config.h")
                   if (source / n).is_file()}
        reusable = (source_parent is not None and not check_monolithic
                    and source_parent.get("configurationFlags") == flags
                    and source_parent.get("generatedProductsPublished") == publish_generated
                    and source_parent.get("phaseCounts") == dict(phase1=2, phase2=2, phase3=2, phase4=2)
                    and native_inputs_equal(owned, desired))
        products_before = generated_inventory(source) if reusable else None
        if reusable and any(h != source_parent["generatedArtifacts"].get(n, owned.get(n, {}).get("sha256"))
                            for n, h in products_before.items()):
            raise ValueError("complete parent generated-product identity required")
        configure_owned_source(ctx, source, flags, managed=True, request_identity=request)
        if reusable:
            required = {"source-bootstrap", "clean-objects", "dummy-seed", "stock-core"}
            inherited = {row["stage"]: row for row in source_parent["checks"]
                         if row["stage"] in required and row["complete"]}
            if set(inherited) != required:
                raise ValueError("all completed parent producer stages required")
            if (any(sha(source / n) != h for n, h in headers.items())
                    or generated_inventory(source) != products_before
                    or any(sha(source / n) != h for n, h in prior.items())):
                raise ValueError("test-only configuration changed native producer inputs/outputs")
            result["checks"] = [dict(row, seconds=0, priorSeconds=row["seconds"],
                                      executed=False, reusedFromTree=source_parent["targetTree"])
                                for row in inherited.values()]
            result.update(producerComplete=True, producerReused=True,
                          phaseCounts=source_parent["phaseCounts"], phaseCountsInherited=True,
                          generatedArtifacts=source_parent["generatedArtifacts"],
                          generatedProductsPublished=publish_generated,
                          productionPaths=[], testPaths=[n for n in changes if n.startswith("tests/")],
                          canonicalSources={n: row["sha256"] for n, row in manifest.items()
                                            if canonical_source(n) and row["mode"] != "120000"},
                          artifacts=prior)
            return result
        # Stock core intentionally installs a dummy. It is never a producer
        # seed for from-scratch, whose first action deletes generated C.
        if sha(source / "gsc-boot") == sha(source / "gsc-boot.unix"):
            execute("install-real-seed", [ctx.tools["make"], "bootstrap"], source / "gsc", 10)
            if sha(source / "gsc-boot") != sha(source / "gsc/gsc"):
                raise ValueError("existing Make did not install the completed compiler seed")
        result["bootstrapSeedSha256"] = sha(source / "gsc-boot")
        execute("source-bootstrap", [ctx.tools["make"], "-j11", "GAMBOPT=p1", "from-scratch"],
                source, ctx.remaining(), boundary=BootstrapPhaseProgress(
                    observation_path=ctx.directory / "phase-observations.json"))
        result["phaseCounts"] = bootstrap_phase_counts(ctx.last_stdout)
        products = generated_inventory(source)
        generated = {n: h for n, h in products.items()
                     if n in manifest and h != manifest[n]["sha256"]}
        # A C/header-only runtime refactor may leave every emitted C byte
        # unchanged. Bind the complete output cohort; publish only its actual
        # differences. Empty differences are not missing producer outputs.
        if not products:
            raise ValueError("complete generated-product inventory required")
        result["generatedArtifacts"] = products
        result["changedGeneratedArtifacts"] = generated
        execute("clean-objects", [ctx.tools["make"], "clean"], source, 30)
        execute("dummy-seed", [ctx.tools["make"], "dummy-gsc-boot"], source, 10)
        if sha(source / "gsc-boot") != sha(source / "gsc-boot.unix"):
            raise ValueError("stock core must use the intentional dummy seed")
        execute("stock-core", [ctx.tools["make"], "-j11", "core"], source, 120)
        if generated_inventory(source) != products:
            raise ValueError("stock core changed its distribution inputs")
        if check_monolithic:
            log = execute("stock-check", [ctx.tools["make"], "check"], source, 120)
            if "ALL TESTS SUCCESSFUL" not in log:
                raise ValueError("original check lacks its success marker")
        for name, row in manifest.items():
            if canonical_source(name) and row["mode"] != "120000":
                if sha(source / name) != row["sha256"]:
                    raise ValueError("canonical input drift: " + name)
        if generated_inventory(source) != products:
            raise ValueError("tests changed distribution products")
        result.update(complete=check_monolithic, producerComplete=True,
                      generatedProductsPublished=publish_generated,
                      productionPaths=[n for n in changes + removed if not n.startswith("tests/")]
                                      + (sorted(generated) if publish_generated else []),
                      testPaths=[n for n in changes + removed if n.startswith("tests/")],
                      canonicalSources={n: x["sha256"] for n, x in manifest.items()
                                        if canonical_source(n) and x["mode"] != "120000"},
                      artifacts={n: sha(source / n) for n in prior})
    except Exception as error:
        result["error"] = dict(type=type(error).__name__, message=str(error))
    finally:
        result["commands"] = ctx.commands
        (ctx.directory / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        links = {"bin/" + n: "../gsi/gsi" for n in
                 ("gsi-script", "scheme-srfi-0", "scheme-r4rs", "six-script", "scheme-r5rs", "scheme-ieee-1178-1990", "six")}
        links["bin/gsc-script"] = "../gsc/gsc"
        checkpoint_build_source(source, broken_links=links, phase="distribution-qualified",
                                branchQualification=dict(completed=result["complete"], sourceOverlay=True))
    return result


def qualify_check_groups(ctx, repository, source, producer):
    """Reuse the completed producer; close every original check prerequisite.

    GSI retains its pre-existing 300s domain budget. A monolithic 120s check is
    never relabeled a pass. Make's assume-old applies only to a test11 receipt
    whose complete source, inventory and interpreter identities still match.
    """
    required = {"source-bootstrap", "clean-objects", "dummy-seed", "stock-core"}
    observed = {x["stage"]: x["complete"] for x in producer["checks"]}
    if not required <= observed.keys() or not all(observed[x] for x in required):
        raise ValueError("complete distribution producer required")
    source = Path(source)
    manifest = source_manifest(archive_sources(git(repository, "archive", producer["targetTree"])))
    canonical = {n: x["sha256"] for n, x in manifest.items()
                 if canonical_source(n) and x["mode"] != "120000"}
    inventory = unit_inventory(manifest)
    artifacts = {n: sha(source / n) for n in ("gsi/gsi", "gsc/gsc", "gsc-boot", "lib/libgambit.a")}
    makefile = (source / "tests/makefile").read_text()
    matches = re.findall(r"^check: ([^\n]+)$", makefile, re.M)
    if len(matches) != 1 or "\\" in matches[0]:
        raise ValueError("explicit original check prerequisite list required")
    targets = matches[0].split()
    if targets.count("test11") != 1 or "core" not in targets:
        raise ValueError("original GSI and core check targets required")
    if "test11:\n" not in makefile or "$(MAKE) ut" not in makefile:
        raise ValueError("original GSI target refinement unavailable")
    result = dict(producer, complete=False, checkPrerequisites=targets,
                  unitInventory=inventory, monolithicCheckPassed=False,
                  qualificationMode="source-bound original prerequisite composition")

    def stable():
        if not all(sha(source / n) == h for n, h in canonical.items()):
            raise ValueError("canonical check input drift")
        if not all(sha(source / n) == h for n, h in producer["generatedArtifacts"].items()):
            raise ValueError("generated check input drift")
        if not all(sha(source / n) == h for n, h in artifacts.items()):
            raise ValueError("native check identity drift")

    try:
        stable()
        for name, argv, cap in (
                ("original-gsi", [ctx.tools["make"], "test11"], 300),
                ("remaining-original-check", [ctx.tools["make"], "-o", "test11", "check"], 120)):
            stable()
            code, log, timed, seconds = ctx.run(name, argv, source / "tests", min(cap, ctx.remaining()))
            p = ctx.commands[-1]
            marker = ("PASSED ALL " + str(len(inventory)) + " UNIT TESTS"
                      if name == "original-gsi" else "ALL TESTS SUCCESSFUL")
            ok = (code == 0 and not timed and p["parentReaped"]
                  and p["processGroupQuiescent"] is True and marker in log)
            result["checks"].append(dict(stage=name, complete=ok, exit=code,
                                         timeout=timed, seconds=seconds))
            print(json.dumps(result["checks"][-1]), flush=True)
            if not ok:
                raise ValueError(log[-1800:])
            stable()
        result.update(complete=True, canonicalSources=canonical, artifacts=artifacts,
                      productionPaths=[n for n in producer["sourcePaths"] if not n.startswith("tests/")]
                                      + (sorted(producer["generatedArtifacts"])
                                         if producer.get("generatedProductsPublished", True) else []),
                      testPaths=[n for n in producer["sourcePaths"] if n.startswith("tests/")],
                      reusedPrerequisites=["test11"], allOriginalPrerequisitesCovered=True)
        result.pop("error", None)
    except Exception as error:
        result["error"] = dict(type=type(error).__name__, message=str(error))
    result["commands"] = [*producer["commands"], *ctx.commands]
    (ctx.directory / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    return result
