"""Drive the normal Research read with committed test campaign receipts."""

from contextlib import redirect_stdout
from copy import deepcopy
import hashlib
from io import StringIO
import json
from pathlib import Path
import shutil
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp import family6_recipes
from gambit_smp.framework import ROOT, digest
from gambit_smp.gate2_evidence import HANDLER_SOURCES, MEMORY_SOURCES, SCHEMA as GATE2_SCHEMA, SITES
from gambit_smp import make_lineage, rest_observation as obs
from gambit_smp.ascent_program import load_inert_catalog, query
from gambit_smp.ordered_stress_audit import RECIPE_TEMPLATE, original_inventory
from gambit_smp.reasoning_history import read_execution_checkpoint
from gambit_smp.recipes import tree_identity
from gambit_smp.research_kernel import main, retain_run_record, retain_terminal_run
from gambit_smp.rest_observation import runtime_identity_bytes
from gambit_smp.suite_primitives import partitions, runner_option
from tests.support import task_fixture
import test_observation as observation_fixture


GCC_SHA = "c" * 64
NATURAL = dict(observation_fixture.NATURAL, parentReaped=True)


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content if isinstance(content, str) else json.dumps(content))
    return digest(path)


class CampaignReceipt:
    def __init__(self, root, out, *, kind):
        self.root, self.out = root, out
        self.run = out / "run"
        template = json.loads((ROOT / RECIPE_TEMPLATE).read_text())
        self.step = deepcopy(template["steps"][2])
        plan = self.step["arguments"]["orderedStress"]
        for name in (RECIPE_TEMPLATE, family6_recipes.PROBE_DECLARATION, *plan.values()):
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        _, self.files = original_inventory(root)
        self.inputs = {name: digest(root / name) for name in plan.values()}
        self.runtime = self.run / "producer/runtime"
        executable = self.runtime / "gsi/gsi"
        self.gsi_sha = write(executable, "alternate executable identity" if kind == "gate2-alternate"
                             else "test executable identity")
        test_inputs = json.loads((root / plan["inputReceipt"]).read_text())["originalCampaign"]["testInputFiles"]
        for name in test_inputs:
            copied = self.runtime / "tests" / name
            copied.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / "vendor/gambit/tests" / name, copied)
        if kind in ("observation-provider", "observation-restored"):
            source, origin_inputs = None, {}
            gsc_sha = write(self.runtime / "gsc/gsc", "test observation compiler")
            source_files = {name: "b" * 64 for item in (6, 7, 8, 9)
                            for name in obs.required_sources([dict(checklist=item, situation="race")])}
            candidate = dict(schema="gambit-recipe-runtime-identity.v1", binarySha256=self.gsi_sha,
                             gscSha256=gsc_sha, sourceFiles=source_files)
            identity_sha = write(self.run / "producer/identity.json", candidate)
            producer = dict(id="producer", capability=family6_recipes.OBSERVATION_PROVIDER, outcome="PASS",
                            dependsOn=[], arguments=dict(source=self.runtime.relative_to(root).as_posix(),
                                                         gsiSha256=self.gsi_sha),
                            outputs=dict(runtime=dict(type="source-runtime", path="producer/runtime",
                                                      identity=tree_identity(self.runtime)),
                                         identity=dict(type="runtime-identity", path="producer/identity.json",
                                                       sha256=identity_sha)))
        else:
            source, producer, origin_inputs, candidate = self.make_producer(template, kind)
        self.identity_sha = producer["outputs"]["identity"]["sha256"]
        identity = self.run / producer["outputs"]["identity"]["path"]
        self.inputs.update(origin_inputs)
        self.rest_run = out.with_name(out.name + "-family-a")
        self.gate = self.family_a(source, producer, candidate, kind)
        plan["restEvidence"] = dict(run=self.gate["restRun"], receiptSha256=self.gate["restReceiptSha256"])
        if source is None:
            producer["arguments"]["retainedRuntime"] = dict(plan["restEvidence"], step=producer["id"])
        if kind == "observation-provider":
            producer["outputs"]["runtime"]["identity"]["gsi/gsi.observation"] = {
                "sha256": "d" * 64, "mode": 0o755}
        self.step["dependsOn"] = [producer["id"]]
        recipe = "observation-provider-campaign" if source is None else template["id"]
        header = dict(schema="research-run-header.v1", runId=out.name, clockEpoch="test-boot", recipe=recipe,
                      engineId="test-engine", inputs=self.inputs, budgetSeconds=300, stepBudgets={"stress": 295},
                      startedMonotonic=1000, deadlineMonotonic=1300,
                      declaration=dict(template, steps=[deepcopy(self.step)]))
        self.journal = retain_run_record(root, out / "run-header.json", "test-campaign", header, self.inputs)
        self.clock = dict(runId=out.name, clockEpoch="test-boot", headerSha256=self.journal["sha256"])
        self.step.update(outcome="PASS", commands=[], artifacts={}, observedInputs={
            str(executable): self.gsi_sha, str(identity): self.identity_sha,
            str(self.rest_run / "receipt.json"): self.gate["restReceiptSha256"],
            str(self.rest_run / "run/receipt.json"): self.gate["childReceiptSha256"],
            **{str(self.runtime / "tests" / name): sha for name, sha in test_inputs.items()},
        })
        self.progress = dict(campaignClock=self.clock, selectedFiles=self.files,
                             runtimeIdentitySha256=self.identity_sha, runtimeIdentityStable=True,
                             wholeFamilyComplete=True, completedMonotonic=1070,
                             manifestSha256=self.inputs[plan["manifest"]], profileSha256=self.inputs[plan["profile"]])
        self.child = dict(schema="evidence-recipe-run.v1", recipe=recipe, outcome="PASS", budgetSeconds=300,
                          workspacePolicy="in-place", wholeBudgetExhausted=False, journal=self.journal,
                          inputs={}, steps=[*([source] if source else []), producer, self.step])
        self.child["toolInputs"] = dict(path="tools.json", sha256=write(self.run / "tools.json", {}))
        self.outer = dict(schema="sealed-research-run.v1", recipe=recipe, outcome="PASS", root=str(root),
                          engineId="test-engine", engine=str(root / "test-engine"), journal=self.journal,
                          inputs=self.inputs, artifacts={}, budgetSeconds=300, stepBudgets={"stress": 295},
                          timeout=False, exit=0, parentReaped=True, processGroupQuiescent=True,
                          wholeSeconds=80, performanceBudgetExceeded=False)

    def commit(self, directory, recipe, rows, inputs, *, declaration=None, **extra):
        run = directory / "run"
        header = dict(schema="research-run-header.v1", runId=directory.name, recipe=recipe,
                      engineId="test-engine", inputs=inputs)
        if declaration is not None:
            header["declaration"] = declaration
        journal = retain_run_record(self.root, directory / "run-header.json", recipe, header, inputs)
        for row in rows:
            row["journal"] = retain_run_record(self.root, run / (row["id"] + ".observation.json"), recipe,
                dict(schema="research-step-observation.v1", runId=directory.name, header=journal, step=row), inputs)
        child = dict(schema="evidence-recipe-run.v1", recipe=recipe, outcome="PASS", inputsStable=True,
                     steps=rows, journal=journal, engine={"engineId": "test-engine"}, **extra)
        outer = dict(schema="sealed-research-run.v1", recipe=recipe, outcome="PASS", root=str(self.root),
                     engineId="test-engine", engine=str(self.root / "test-engine"), journal=journal,
                     inputs=inputs, timeout=False, exit=0, parentReaped=True, processGroupQuiescent=True,
                     childReceiptSha256=write(run / "receipt.json", child))
        write(directory / "receipt.json", outer)
        retain_terminal_run(self.root, directory, outer)
        return outer

    def make_producer(self, template, kind):
        root = self.root
        producer_run = self.out.with_name(self.out.name + "-bootstrap")
        self.producer_run = producer_run
        stage = producer_run / "run/bootstrap"
        lineage = stage / "make-lineage"
        workspace = self.runtime
        focused = kind == "gate2-collection"
        gcc_path = workspace / "fixture-gcc"
        gcc_sha = write(gcc_path, "test GCC identity") if focused else GCC_SHA
        scheme = {name: write(workspace / name, "Scheme test input " + name)
                  for name in ("gsi/_gsi.scm", "gsc/_gsc.scm", "gsc/_prims.scm", "gsc/_ptree2.scm",
                               "lib/_eval.scm", "lib/_kernel.scm")}
        labels = {}
        for number, (site, (unit, _, _, encoded, _)) in enumerate(SITES.items(), 1):
            labels[site] = f"___DEF_SLBL({number},___L{number}_{encoded})"
        generated = {}
        for name in scheme:
            c = str(Path(name).with_suffix(".c"))
            anchors = [labels[site] for site, (unit, *_) in SITES.items() if unit + ".c" == c]
            generated[c] = write(workspace / c, "\n".join(anchors) + "\n" if anchors else name)
        objects = {str(Path(name).with_suffix(".o")): write(workspace / Path(name).with_suffix(".o"), name)
                   for name in generated}
        objects["lib/mem.o"] = write(workspace / "lib/mem.o", "test memory object")
        memory = {name: write(workspace / name, name) for name in MEMORY_SOURCES}
        archives = {
            "lib/libgambit.a": ["lib/_eval.o", "lib/_kernel.o", "lib/mem.o"],
            "gsc/libgambitgsc.a": ["gsc/_prims.o", "gsc/_ptree2.o"],
        }
        archive_hashes = {name: write(workspace / name, "test archive " + name) for name in archives}
        compiler = "gsc/gsc"
        gsc_sha = write(workspace / compiler, "test compiler")
        header_sha = write(workspace / "include/gambit.h", "test configured header")
        makefiles = {name: write(workspace / name, name)
                     for name in ("makefile", "lib/makefile", "gsi/makefile", "gsc/makefile")}
        passes = []
        map_artifacts = {}
        for number in (1, 2):
            emitter = lineage / f"emitter-{number}/gsc-boot"
            seed = write(emitter, "test seed" if number == 1 else "test compiler")
            if number == 1:
                seed_sha = seed
            actions = {}

            def action(action_kind, target, output_sha, dependencies, *, link_members=()):
                action_dir = make_lineage.action_directory(lineage, number, action_kind, target)
                path = action_dir / "receipt.json"
                args = {str(workspace / name): sha for name, sha in dependencies.items()}
                tool = str(emitter) if action_kind == "emit" else str(gcc_path) if focused else "/test/gcc"
                record = dict(kind=action_kind, output=target, outputSha256=output_sha, pass_=number,
                              exit=0, inputs=args, executable=tool, cwd=str(workspace),
                              executedArgv=[tool, "-std=c23", *args] if action_kind == "object" else [tool, *args],
                              tool={"sha256": seed if action_kind == "emit" else gcc_sha},
                              orderedFileArguments=list(args), headersAndSources=args)
                if focused and action_kind in {"object", "link"}:
                    record["executedArgv"] += ["-o", target]
                    if action_kind == "object":
                        record["executedArgv"].insert(1, "-c")
                if action_kind == "link" and not (
                        kind in {"gate2-no-map", "gate2-ordinal-only", "gate2-collection"} and target == "gsi/gsi"):
                    map_path = action_dir / "link.map"
                    lines = ["# Object files:"] + [
                        f"[{index:3}] {workspace / archive}({Path(member).name})"
                        for index, (archive, member) in enumerate(link_members, 1)
                    ] + ["# Sections:"]
                    sha = write(map_path, "\n".join(lines) + "\n")
                    record["linkMap"] = dict(sha256=sha, format="darwin")
                    record["executedArgv"] += ["-Xlinker", "-map", "-Xlinker", str(map_path)]
                    map_artifacts[map_path.relative_to(producer_run / "run").as_posix()] = sha
                record["pass"] = record.pop("pass_")
                actions[path.relative_to(lineage).as_posix()] = write(path, record)

            for name, sha in generated.items():
                source = str(Path(name).with_suffix(".scm"))
                action("emit", name, sha, {source: scheme[source]})
            for name, sha in objects.items():
                c = str(Path(name).with_suffix(".c"))
                inputs = memory if name == "lib/mem.o" else {
                    c: "a" * 64 if kind == "broken-make-edge" and number == 2 else generated[c]}
                if kind in {"gate2-ordinal-only", "gate2-collection"} and name == "lib/mem.o" and number == 2:
                    inputs = {path: sha for path, sha in inputs.items() if path != "lib/_mem/heap-sections.inc"}
                action("object", name, sha, inputs)
            for archive, members in archives.items():
                action("archive", archive, archive_hashes[archive], {name: objects[name] for name in members})
                action("index", archive, archive_hashes[archive], {archive: archive_hashes[archive]})
            core, gsc = archives
            core_members = [(core, name) for name in archives[core]]
            action("link", compiler, gsc_sha, {"gsc/_gsc.o": objects["gsc/_gsc.o"], **archive_hashes},
                   link_members=[*core_members, *((gsc, name) for name in archives[gsc])])
            action("link", "gsi/gsi", self.gsi_sha, {"gsi/_gsi.o": objects["gsi/_gsi.o"], core: archive_hashes[core]},
                   link_members=[pair for pair in core_members
                                 if kind != "gate2-not-loaded" or pair[1] != "lib/_eval.o"])
            passes.append(dict(emitter=emitter.relative_to(lineage).as_posix(), emitterSha256=seed, actions=actions))
        manifest = lineage / "lineage.json"
        binding = dict(path=manifest.relative_to(producer_run / "run").as_posix(), gsiSha256=self.gsi_sha,
                       sha256=write(manifest, dict(schema="gambit-make-lineage.v1", passes=passes,
                           gsiSha256=self.gsi_sha, inputs=dict(workspace=str(workspace), generated=list(generated),
                               schemeInputs=scheme, makefiles=makefiles,
                               gcc=str(gcc_path) if focused else "/test/gcc",
                               gccSha256=gcc_sha))))
        source = dict(template["steps"][0], outcome="PASS")
        producer = deepcopy(template["steps"][1])
        lock_name = source["arguments"]["sourceLock"] = f"evidence/{self.out.name}-source.lock.json"
        proof_name = producer["arguments"]["producer"] = f"evidence/{self.out.name}-producer.json"
        patch_name = f"evidence/{self.out.name}-source.patch"
        patch_sha = write(root / patch_name, "test overlay")
        lock_sha = write(root / lock_name, dict(schema="gambit-runtime-source-lock.v1",
            repository="https://git.cons.io/mighty-gerbils/gambit.git", submodule="vendor/gambit",
            revision="a" * 40, runtimeAdmitted=False, releaseAdmitted=False, patch=patch_name, patchSha256=patch_sha,
            files={name: dict(baseSha256=None, candidateSha256=sha) for name, sha in scheme.items()}))
        profile = self.step["arguments"]["orderedStress"]["profile"]
        inputs = {lock_name: lock_sha, patch_name: patch_sha, profile: self.inputs[profile]}
        if kind != "gate2-no-receipt":
            gate_path = f"evidence/{self.out.name}-gate2.json"
            self.step["arguments"]["orderedStress"]["gate2Receipt"] = gate_path
            inputs[gate_path] = self.gate2_receipt(root / gate_path, kind, workspace, labels, lock_sha, binding["sha256"],
                                                  objects, gsc_sha)
        if kind == "missing-lineage":
            binding = None
        source_files = {name: "b" * 64 for item in (6, 7, 8, 9)
                        for name in obs.required_sources([dict(checklist=item, situation="race" if item == 9 else "")])}
        candidate = dict(schema="gambit-recipe-runtime-identity.v1", binarySha256=self.gsi_sha, gscSha256=gsc_sha,
                         sourceFiles=source_files, **({"makeLineage": binding} if binding else {}))
        raw_identity = json.dumps(candidate)
        identity_sha = write(stage / "identity.json", raw_identity)
        inventory = tree_identity(workspace)
        runtime_output = dict(type="source-runtime", identity=inventory)
        shutil.copytree(workspace, stage / "runtime")
        source["outputs"] = {"source": dict(type="source-tree", identity=inventory, path="producer/runtime")}
        upstream_source = dict(source)
        bootstrap = dict(id="bootstrap", capability="gambit.bootstrap", outcome="PASS", dependsOn=["seed"],
                         arguments=dict(runtime={"step": "seed", "output": "runtime"}, identity={"step": "seed"}),
                         fullTwoPassBootstrapEstablished=True,
                         phaseCounts=dict.fromkeys(("phase1", "phase2", "phase3", "phase4"), 2),
                         commands=[dict(stage="from-scratch", argv=["make", "from-scratch"], **NATURAL)],
                         outputs=dict(runtime=dict(runtime_output, path="bootstrap/runtime"), identity=dict(type="runtime-identity",
                                             path="bootstrap/identity.json", sha256=identity_sha)),
                         artifacts={binding["path"]: binding["sha256"], **map_artifacts} if binding else {},
                         **({"makeLineage": binding} if binding else {}))
        bootstrap_sha = write(stage / "step-receipt.json", bootstrap)
        rows = [upstream_source,
                dict(id="configure", capability="gambit.configure", outcome="PASS",
                     arguments={"source": {"step": source["id"]}, "buildProfile": profile},
                     configurationFiles={"include/gambit.h": header_sha, "lib/makefile": makefiles["lib/makefile"]}),
                dict(id="seed", capability="gambit.seed-core", outcome="PASS",
                     arguments={"source": {"step": "configure"}}, outputs={"runtime": {"identity": {
                         compiler: {"sha256": "f" * 64 if kind == "wrong-make-seed" else seed_sha}}}}), bootstrap]
        origin = self.commit(producer_run, "test-bootstrap", rows, inputs)
        proof = dict(schema="completed-bootstrap-reference.v1", run=producer_run.relative_to(root).as_posix(),
                     step="bootstrap", sourceLock=lock_name, gccSha256=gcc_sha, engineId=origin["engineId"],
                     sourceLockSha256="0" * 64 if kind == "wrong-source-lock" else lock_sha,
                     childReceiptSha256=origin["childReceiptSha256"], stepReceiptSha256=bootstrap_sha,
                     outerReceiptSha256=digest(producer_run / "receipt.json"))
        inputs[proof_name] = write(root / proof_name, proof)
        write(self.run / "producer/identity.json", raw_identity)
        producer.update(outcome="PASS", outputs=dict(runtime=dict(runtime_output, path="producer/runtime"),
                         identity=dict(type="runtime-identity", path="producer/identity.json", sha256=identity_sha)),
                        observedInputs={str(path): digest(path) for path in (root / proof_name,
                            producer_run / "receipt.json", producer_run / "run/receipt.json", stage / "step-receipt.json")})
        if binding:
            producer["makeLineage"] = binding
        return source, producer, inputs, candidate

    def gate2_receipt(self, path, kind, workspace, labels, lock_sha, lineage_sha, objects, gsc_sha):
        def span(name, line):
            raw = (workspace / name).read_bytes().splitlines(keepends=True)[line - 1]
            return dict(start=line, end=line, sha256=hashlib.sha256(raw).hexdigest())

        handlers = {image: dict(sources={name: digest(workspace / name) for name in HANDLER_SOURCES},
                                kernelObjectSha256=objects["lib/_kernel.o"], memoryObjectSha256=objects["lib/mem.o"])
                    for image in ("gsc/gsc", "gsi/gsi")}
        sites = []
        for site, (unit, image, procedure, _, baseline) in SITES.items():
            if kind == "gate2-no-site" and site == "F6-20-7":
                continue
            c = unit + ".c"
            line = (workspace / c).read_text().splitlines().index(labels[site]) + 1
            sites.append(dict(id=site, baselineSha256=baseline, procedure=procedure,
                              schemeSpan=span(unit + ".scm", 1), gvmEdge={"from": site + "-in", "to": site + "-out"},
                              regions=[dict(span(c, line), anchor=labels[site])],
                              generatedCSha256=digest(workspace / c), objectSha256=objects[unit + ".o"],
                              image=image, imageSha256=gsc_sha if image == "gsc/gsc" else self.gsi_sha))
        if kind == "gate2-wrong-image":
            sites[-1].update(image="gsc/gsc", imageSha256=gsc_sha)
        if kind == "gate2-wrong-object":
            sites[-1]["objectSha256"] = objects["gsc/_ptree2.o"]
        if kind == "gate2-wrong-generated":
            sites[-1]["generatedCSha256"] = digest(workspace / "gsc/_ptree2.c")
        if kind == "gate2-wrong-handler":
            handlers["gsi/gsi"]["sources"]["lib/_mem/heap-sections.inc"] = "d" * 64
        if kind == "gate2-wrong-semantic":
            sites[-1]["schemeSpan"]["sha256"] = "d" * 64
        if kind == "gate2-wrong-generation":
            lineage_sha = "d" * 64
        if kind in {"gate2-ordinal-only", "gate2-collection"}:
            del sites[-1]["schemeSpan"], sites[-1]["gvmEdge"]
            sites[-1]["directCallOrdinal"] = 12
        if kind == "gate2-semantic-first":
            del sites[-1]["objectSha256"], sites[-1]["image"], sites[-1]["imageSha256"]
        return write(path, dict(schema=GATE2_SCHEMA, sourceLockSha256=lock_sha, makeLineageSha256=lineage_sha,
                                sites=sites, handlers=handlers))

    def family_a(self, source, provider, candidate, kind):
        run = self.rest_run / "run"
        rest_runtime = run / "producer/runtime"
        shutil.copytree(self.runtime, rest_runtime)
        provider = deepcopy(provider)
        if kind == "observation-restored":
            provider["arguments"]["source"] = rest_runtime.relative_to(self.root).as_posix()
        options = family6_recipes.rest_probe_steps(provider["id"], root=self.root)
        ancestry = [source] if source else []
        terminal = dict(id="verdict", capability="evidence.evaluate", arguments={}, outcome="PASS",
                        dependsOn=[row["id"] for row in [*ancestry, provider, *options]])
        declarations = [{key: row[key] for key in ("id", "capability", "arguments", "dependsOn", "budgetSeconds")
                         if key in row} for row in [*ancestry, provider, *options, terminal]]
        rest_inputs = dict(self.inputs)
        for name in {obs.RULES, *(row["arguments"]["program"] for row in options)}:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
            rest_inputs[name] = digest(target)
        catalog = load_inert_catalog(self.root / obs.RULES)
        rows = []
        for row in options:
            if kind == "missing-family-case" and row["id"] == options[-1]["id"]:
                continue
            directory = run / row["id"]
            directory.mkdir(parents=True)
            args = row["arguments"]
            args["restObservation"]["capacity"] = 1024
            case = args["restObservation"]["case"]
            form = args["parameters"]["GAMBIT_SMP_REST_FORM"]
            (directory / "fixture.scm").write_bytes((self.root / args["program"]).read_bytes())
            write(directory / "fixture.o1", "test compiled module")
            commands = [
                dict(stage="compile-rest-fixture", cwd=str(directory), **NATURAL,
                     argv=[str(rest_runtime / "gsc/gsc"), "-f", "-dynamic", "-o", "fixture.o1", "fixture.scm"]),
                dict(stage="run-executable", cwd=str(directory), **NATURAL,
                     argv=[str(rest_runtime / "gsi/gsi"), "-:debug-settings=-,io-settings=lu",
                           "-f", str(directory / "fixture.o1")])]
            ctx = SimpleNamespace(root=self.root, directory=directory, env={}, bind=lambda paths: None,
                                  commands=commands)
            prepared = obs.prepare(args["restObservation"], ctx, candidate, self.gsi_sha, rest_runtime)
            prepared["fixture"] = obs.fixture_identity(directory, commands)
            trace = observation_fixture.ReceiptBindingTests().projected_case_trace(case, form)
            for event in trace["events"]:
                event["case"] = case["id"]
            (directory / "rest-observation.bin").write_bytes(observation_fixture.wire(trace, 1024))
            with patch("gambit_smp.suite_primitives.check_runtime"), \
                 patch("gambit_smp.evidence_capabilities.evaluate_observations",
                       side_effect=lambda ctx, rules, facts, queries, label, **kw: query(facts, catalog, queries)):
                descriptor = obs.finish(prepared, ctx)
            rows.append(dict(row, outcome="PASS", commands=commands, restObservation=descriptor,
                             executableSha256=self.gsi_sha, candidateReceiptSha256=provider["outputs"]["identity"]["sha256"],
                             artifacts={p.relative_to(run).as_posix(): digest(p) for p in directory.iterdir()}))
        if kind == "observation-provider":
            provider["outputs"]["runtime"]["identity"]["gsi/gsi.observation"] = {
                "sha256": "e" * 64, "mode": 0o755}
        provider["outputs"]["runtime"]["path"] = str(self.runtime.relative_to(self.run))
        identity = (self.run / "producer/identity.json").read_text()
        write(run / "producer/identity.json", identity)
        recipe = family6_recipes.FAMILY6_REST_RECIPE if source else "family-a-observation-receipt"
        receipt = self.commit(self.rest_run, recipe, [*ancestry, provider, *rows, terminal],
                              rest_inputs, plannedSteps=declarations)
        return dict(checklist=10, canStart=True, requiredCases=11, verifiedCases=11,
                    innerBudgetSeconds=295, wholeBudgetSeconds=300, runtimeAdmitted=False,
                    executableSha256=self.gsi_sha, provider=provider["id"],
                    runtimeIdentitySha256=hashlib.sha256(runtime_identity_bytes(candidate)).hexdigest(),
                    childReceiptSha256=receipt["childReceiptSha256"],
                    restRun=self.rest_run.relative_to(self.root).as_posix(),
                    restReceiptSha256=digest(self.rest_run / "receipt.json"))

    def sidecar(self, name, content):
        key = "stress/" + name
        self.step["artifacts"][key] = write(self.run / key, content)
        return self.step["artifacts"][key]

    def command(self, p, suffix, argv, output, start, *, timeout=False, failure=False, clock=None):
        name = f"p{p}-{suffix}"
        option = self.option(p)
        record = dict(stage=name, argv=[str(self.runtime / "gsi/gsi"), *argv],
                      campaignClock=dict(clock or self.clock, deadlineMonotonic=1295, startedMonotonic=start,
                                         endedMonotonic=1296 if timeout else start+1),
                      environment=dict(GAMBOPT=option, GAMBIT_SMP_EXPECTED_PROCESSORS=str(p)),
                      exit=-9 if timeout else 1 if failure else 0, timeout=timeout,
                      parentReaped=True, processGroupQuiescent=True, streamCaptureComplete=True,
                      log=name + ".log", logSha256=self.sidecar(name + ".log", output))
        self.sidecar(name + ".process.json", dict(record, schema="recipe-process-observation.v1", state="OBSERVED",
                                                 completionObserved=True, runtimeAdmitted=False))
        self.step["commands"].append(record)

    def option(self, p):
        runtime = self.runtime
        return f"p{p},~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"

    def topology(self, p, jobs, start, *, missing=False, timeout=False, failure=False, clock=None):
        self.command(p, "topology-runner", ["-:p1", "-e", '(println "PROCESSORS:" (##current-vm-processor-count))'],
                     "PROCESSORS:1\n", start, clock=clock)
        self.command(p, "topology-fixture", ["-:debug-settings=-,io-settings=lu", "-e",
                     '(println "PROCESSORS:" (##current-vm-processor-count))'],
                     f"PROCESSORS:{p}\n", start+2, clock=clock)
        for i, files in enumerate(partitions(self.files, jobs)):
            argv = ["-:" + runner_option(self.option(p)), "-f", "run-unit-tests.scm", "-gsi", "-stress",
                    *["unit-tests/" + file for file in files]]
            output = "".join(f"[{j:3}|  0]   0% ................ .0s {file}\n" for j, file in enumerate(files))
            if i == 0 and missing:
                continue
            if i == 0 and timeout:
                output = f"[  0|  0]   0% ................ .0s {files[0]}\n"
                self.command(p, f"suite-0-{i}", argv, output, start+4, timeout=True)
            elif i == 0 and failure:
                output = f"[  0|  0]   0% ................ .0s {files[0]}\n[  0|  1] 100% ################ .1s\n"
                self.command(p, f"suite-0-{i}", argv, output, start+4, failure=True)
            else:
                output += f"[{len(files):3}|  0] 100% ################ .1s\nPASSED ALL {len(files)} UNIT TESTS\n"
                self.command(p, f"suite-0-{i}", argv, output, start+4, clock=clock)

    def seal(self, *, timeout=False):
        self.sidecar("ordered-stress-progress.json", self.progress)
        self.sidecar("item10-preflight.json", self.gate)
        if timeout:
            self.step["outcome"] = "TIMEOUT"
            self.child["outcome"] = self.outer["outcome"] = "DENY"
            self.outer.update(timeout=True, exit=-9, wholeSeconds=300)
        self.step["journal"] = retain_run_record(self.root, self.run / "stress.observation.json", "test-campaign",
            dict(schema="research-step-observation.v1", runId=self.out.name, header=self.journal, step=self.step),
            self.inputs)
        self.outer["childReceiptSha256"] = write(self.run / "receipt.json", self.child)
        write(self.out / "receipt.json", self.outer)
        retain_terminal_run(self.root, self.out, self.outer)

    def read(self):
        stdout = StringIO()
        with patch("sys.argv", ["research", "--read", str(self.out)]), redirect_stdout(stdout), \
             patch("gambit_smp.research_kernel.manifest_paths",
                   return_value={"engineId": "test-engine", "hostTools": {"gcc": {"sha256": GCC_SHA}}}), \
             patch("gambit_smp.step_checkpoint.resumption", return_value={}):
            assert main.__wrapped__() == 0
        return json.loads(stdout.getvalue())["executionSummary"]["item12Audit"]


class Item12AuditTests(unittest.TestCase):
    def test_restored_tree_preserves_the_historical_family_a_paths(self):
        with task_fixture("family6-restored-campaign") as (root, cache):
            fixture = CampaignReceipt(root, cache / "runs" / "restored", kind="observation-restored")
            fixture.topology(2, 3, 1010)
            fixture.topology(1, 4, 1040)
            fixture.seal()
            (fixture.rest_run / "run/producer/runtime/gsi/gsi").unlink()
            audit = fixture.read()
            self.assertEqual("PASS", audit["links"]["familyA"]["status"], audit["gaps"])
            self.assertEqual(11, audit["links"]["familyA"]["verifiedCases"])

            write(fixture.runtime / "unexpected-file", "restored tree drift")
            audit = fixture.read()
            self.assertEqual("MISMATCH", audit["links"]["familyA"]["status"])
            self.assertIn("no longer matches", audit["links"]["familyA"]["reason"])

    def test_observation_campaign_reports_family_a_separately_from_make_lineage(self):
        from gambit_smp.observation_runtime import check_observation_tree

        scratch = {"gsi/gsi.observation": {"sha256": "d" * 64, "mode": 0o755}}
        check_observation_tree({}, scratch)
        with self.assertRaisesRegex(ValueError, "gsi/gsi"):
            check_observation_tree({}, {"gsi/gsi": scratch["gsi/gsi.observation"]})
        with self.assertRaisesRegex(ValueError, "gsi/gsi.observation"):
            check_observation_tree({}, {"gsi/gsi.observation": {"symlink": "gsi"}})
        with task_fixture("family6-observation-campaign") as (root, cache):
            fixture = CampaignReceipt(root, cache / "runs" / "observed", kind="observation-provider")
            fixture.topology(2, 3, 1010)
            fixture.topology(1, 4, 1040)
            fixture.seal()
            audit = fixture.read()
            links = audit["links"]
            self.assertEqual("PASS", links["familyA"]["status"], audit["gaps"])
            self.assertEqual(11, links["familyA"]["verifiedCases"])
            self.assertEqual("PASS", links["sealedGsi"]["status"])
            self.assertEqual("PASS", links["originalCampaign"]["status"])
            self.assertEqual("MISSING", links["sourceLock"]["status"])
            self.assertEqual("BLOCKED", links["makeLineage"]["status"])
            self.assertEqual("BLOCKED", links["gate2"]["status"])
            self.assertFalse(audit["passed"])

    def test_focused_collection_projects_and_rechecks_each_receipt(self):
        from gambit_smp.gate2_collection import CAPABILITY, collect

        with task_fixture("family6-gate2-collection") as (root, cache):
            shutil.copytree(ROOT / "evidence/dsl", root / "evidence/dsl")
            fixture = CampaignReceipt(root, cache / "runs" / "candidate", kind="gate2-collection")
            draft = root / fixture.step["arguments"]["orderedStress"]["gate2Receipt"]
            document = json.loads(draft.read_bytes())
            last = document["sites"][-1]
            del last["directCallOrdinal"]
            last["schemeSpan"] = dict(document["sites"][0]["schemeSpan"],
                                      sha256=digest(fixture.runtime / "lib/_eval.scm"))
            last["gvmEdge"] = {"from": "eval-in", "to": "eval-out"}
            write(draft, document)

            def read(run, bindings=()):
                argv = ["research", "--read", str(run)]
                if bindings:
                    request = " ".join(f"({json.dumps(key)} {json.dumps(value)})" for key, value in bindings)
                    argv.append(f"((bindings ({request})))")
                stdout = StringIO()
                with patch("sys.argv", argv), patch("gambit_smp.research_kernel.ROOT", root), \
                     patch("gambit_smp.research_kernel.manifest_paths", return_value={"engineId": "test-engine"}), \
                     patch("gambit_smp.step_checkpoint.resumption", return_value={}), redirect_stdout(stdout):
                    self.assertEqual(0, main.__wrapped__())
                return json.loads(stdout.getvalue())

            collection_runs = []
            # An isolated command fixture supplies byte-identical outputs and the sidecars.
            for kind, subject in (("scheme-gvm", "F6-20-7"), ("handler-inputs", "lib/mem.o"), ("link-map", "gsi/gsi")):
                bindings = [("review", "gate2"), ("gsiSha256", fixture.gsi_sha), ("collect", kind), ("subject", subject)]
                if kind == "scheme-gvm":
                    bindings.append(("correspondence", draft.relative_to(root).as_posix()))
                result = read(fixture.producer_run, bindings)
                recipe = result["reviews"]["request"]["collectionRecipe"]
                step, terminal = recipe["steps"]
                self.assertEqual(CAPABILITY, step["capability"])
                self.assertEqual([], step["dependsOn"])
                self.assertEqual([step["id"]], terminal["dependsOn"])
                out = cache / "runs" / kind
                run = out / "run"
                directory = run / step["id"]
                directory.mkdir(parents=True)
                commands = []

                def require_command(label, argv, cwd, timeout):
                    self.assertEqual(kind, label)
                    product = Path(argv[argv.index("-o") + 1])
                    self.assertEqual(directory, product.parent)
                    shutil.copyfile(fixture.runtime / subject, product)
                    sidecar = Path(argv[-1])
                    if kind == "handler-inputs":
                        names = " ".join(str(cwd / item) for item in MEMORY_SOURCES)
                        write(sidecar, f"{product}: {names}\n")
                    elif sys.platform == "darwin":
                        write(sidecar, "# Object files:\n" + "".join(
                            f"[{index}] lib/libgambit.a({name})\n" for index, name in
                            enumerate(("_eval.o", "_kernel.o", "mem.o"), 1)) + "# Sections:\n")
                    else:
                        write(sidecar, "Archive member included to satisfy reference by file (symbol)\n\n" +
                              "".join(f"lib/libgambit.a({name})\n" for name in ("_eval.o", "_kernel.o", "mem.o")) +
                              "\nMemory Configuration\n")
                    commands.append(dict(stage=label, argv=argv, cwd=str(cwd), **NATURAL))

                bound = {}
                def bind(paths):
                    bound.update((str(path.resolve()), digest(path)) for path in paths)

                ctx = SimpleNamespace(root=root, directory=directory, commands=commands, bind=bind,
                                      tools={"gcc": str(fixture.runtime / "fixture-gcc")}, require=require_command,
                                      remaining=lambda: 30)
                observed = collect(step["arguments"], ctx)
                row = dict(step, **observed, outcome="PASS", commands=commands, observedInputs=bound, artifacts={
                    path.relative_to(run).as_posix(): digest(path) for path in directory.iterdir()
                })
                inputs = {path: digest(root / path) for path in recipe["inputs"]}
                fixture.commit(out, recipe["id"], [row], inputs, declaration=recipe)
                collection_runs.append(out.relative_to(root).as_posix())
                summary = read(out)["executionSummary"]["gate2Collection"]
                self.assertEqual("PASS", summary["status"], summary)
                self.assertFalse(summary["runtimeAdmitted"])
                checks = summary["steps"][0]["checks"]
                self.assertEqual("PASS", checks["lib/_eval.o" if kind == "link-map" else subject]["status"])
                attached = read(fixture.producer_run, [("review", "gate2"), ("gsiSha256", fixture.gsi_sha),
                                                       ("collection", out.relative_to(root).as_posix())])
                self.assertEqual("PASS", attached["reviews"]["request"]["collectionReview"]["status"])
                direct = read(out, [("review", "gate2"), ("gsiSha256", fixture.gsi_sha)])["reviews"]["request"]
                self.assertEqual("PASS", direct["collectionReview"]["status"])
                self.assertEqual(fixture.producer_run.relative_to(root).as_posix(), direct["bootstrapRun"])
                wrong = read(out, [("review", "gate2"), ("gsiSha256", "0" * 64)])["reviews"]["request"]
                self.assertEqual("INVALID", wrong["status"])
                check = {"scheme-gvm": ("schemeGvm", "##comp-do"),
                         "handler-inputs": ("handlerCompileInputs", "lib/mem.o"),
                         "link-map": ("objectSelection", "lib/_eval.o")}[kind]
                reviewed = attached["reviews"]["request"]["investigation"]["sites"]["F6-20-7"]
                self.assertIn(dict(check=check[0], subject=check[1]), reviewed["reusable"])
            merged = read(fixture.producer_run, [("review", "gate2"), ("gsiSha256", fixture.gsi_sha),
                                                 ("collection", json.dumps(collection_runs))])
            merged_site = merged["reviews"]["request"]["investigation"]["sites"]["F6-20-7"]
            self.assertTrue({"objectSelection", "schemeGvm", "handlerCompileInputs"} <=
                            {row["check"] for row in merged_site["reusable"]})
            self.assertFalse(merged["runtimeAdmitted"])
            write(directory / "link.map", "replaced")
            changed = read(out)["executionSummary"]["gate2Collection"]
            self.assertEqual("MISMATCH", changed["steps"][0]["status"])

    def test_read_retained_bootstrap_for_exact_image(self):
        with task_fixture("family6-item12-link-review") as (root, cache):
            shutil.copytree(ROOT / "evidence/dsl", root / "evidence/dsl")
            fixture = CampaignReceipt(root, cache / "runs" / "link-review", kind="gate2-semantic-first")
            prefix = read_execution_checkpoint(root, fixture.producer_run)["prefixIdentity"]

            def invoke(request, *, stdin=False):
                stdout = StringIO()
                argv = ["research", "--read", str(fixture.producer_run), "-" if stdin else request]
                with patch("sys.argv", argv), patch("sys.stdin", StringIO(request)), \
                     patch("gambit_smp.research_kernel.ROOT", root), redirect_stdout(stdout):
                    self.assertEqual(0, main.__wrapped__())
                result = json.loads(stdout.getvalue())
                self.assertFalse(result["runtimeAdmitted"])
                self.assertFalse(result["executionAuthorized"])
                self.assertFalse(result["executionLaunched"])
                return result["reviews"]

            def review(target, draft=None):
                bindings = f'("review" "gate2") ("gsiSha256" "{target}")'
                if draft is not None:
                    bindings += f' ("correspondence" "{draft.relative_to(root).as_posix()}")'
                return invoke(f"((bindings ({bindings})))")["request"]

            rejected = review("0" * 64)
            self.assertEqual(("MISMATCH", "imageIdentity"), (rejected["status"], rejected["edge"]))
            self.assertEqual(fixture.gsi_sha, rejected["recordedImages"]["gsi/gsi"]["imageSha256"])
            self.assertEqual("BLOCKED", rejected["linkSelection"]["gsc/gsc"]["objects"]["gsc/_prims.o"]["status"])
            self.assertEqual({"makeProvenance", "nativeFrame", "schemeGvm"},
                             set(rejected["investigation"]["sites"]["F6-20-7"]["openRoutes"]))
            self.assertEqual({
                ("recover-exact-image", "0" * 64), ("review-recorded-image", fixture.gsi_sha),
            }, {(option["action"], option["gsiSha256"]) for option in rejected["investigation"]["targetOptions"]})
            self.assertEqual({}, rejected["investigation"]["draftAdditions"]["fields"])
            matched = review(fixture.gsi_sha)
            self.assertEqual("PASS", matched["status"], matched)
            self.assertEqual("PASS", matched["linkSelection"]["gsc/gsc"]["objects"]["gsc/_ptree2.o"]["status"])
            self.assertEqual("PASS", matched["linkSelection"]["gsi/gsi"]["objects"]["lib/_eval.o"]["status"])
            declaration = fixture.step["arguments"]["orderedStress"]["gate2Receipt"]
            draft = cache / "gate2-draft.json"
            document = json.loads((root / declaration).read_bytes())
            ordinal = deepcopy(document)
            del ordinal["sites"][-1]["schemeSpan"], ordinal["sites"][-1]["gvmEdge"]
            ordinal["sites"][-1]["directCallOrdinal"] = 12
            write(draft, ordinal)
            first = review(fixture.gsi_sha, draft)
            self.assertEqual(["nativeFrame", "schemeGvm"], first["investigation"]["sites"]["F6-20-7"]["openRoutes"])
            self.assertNotIn("F6-20-7", first["investigation"]["draftAdditions"]["fields"])
            self.assertIn("review-or-reobserve-mapping",
                          {row["action"] for row in first["investigation"]["sites"]["F6-20-7"]["evidenceNeeded"]})
            revised_sha = write(draft, document)
            revised = review(fixture.gsi_sha, draft)
            self.assertEqual(revised_sha, revised["correspondenceReview"]["receiptSha256"])
            self.assertEqual(["makeProvenance", "nativeFrame"], revised["investigation"]["sites"]["F6-20-7"]["openRoutes"])
            wrong_generation = review("0" * 64, draft)
            self.assertEqual("BLOCKED", wrong_generation["correspondenceReview"]["status"])
            earlier = cache / "gate2-ordinal.json"
            write(earlier, ordinal)
            alternate = CampaignReceipt(root, cache / "runs" / "alternate", kind="gate2-alternate")
            selector = """
                (define-evidence (choose)
                  (sources binding)
                  (outputs research_review research_operand)
                  (relation binding (name value))
                  (relation research_review (id kind))
                  (relation research_operand (id name value))
                  (fact (research_review (lit "earlier") (lit "gate2")))
                  (fact (research_review (lit "revised") (lit "gate2")))
                  (fact (research_review (lit "alternate") (lit "gate2")))
                  (fact (research_review (lit "invalid") (lit "gate2")))
                  (fact (research_review (lit "lost") (lit "gate2")))
                  ((research_operand Id (lit "gsiSha256") Sha) <--
                    (research_review Id _) (binding (lit "image") Sha)
                    (if (Id) (or (equal? Id "earlier") (equal? Id "revised"))))
                  ((research_operand (lit "alternate") (lit "gsiSha256") Sha) <--
                    (binding (lit "alternate-image") Sha))
                  ((research_operand (lit "lost") (lit "gsiSha256") Sha) <--
                    (binding (lit "lost-image") Sha))
                  ((research_operand Id (lit "correspondence") Path) <--
                    (research_review Id _) (binding Id Path))
                  ((research_operand (lit "alternate") (lit "run") Path) <--
                    (binding (lit "alternate-run") Path)))"""
            alternate_draft = alternate.step["arguments"]["orderedStress"]["gate2Receipt"]
            bindings = (f'("image" "{fixture.gsi_sha}") '
                        f'("earlier" "{earlier.relative_to(root).as_posix()}") '
                        f'("revised" "{draft.relative_to(root).as_posix()}") '
                        f'("alternate" "{alternate_draft}") '
                        f'("alternate-image" "{alternate.gsi_sha}") '
                        f'("lost-image" "{"0" * 64}") '
                        f'("alternate-run" "{alternate.producer_run.relative_to(root).as_posix()}")')
            reports = invoke(f'((bindings ({bindings})) (selector {json.dumps(selector)}) (constructor "choose"))',
                             stdin=True)
            self.assertEqual(["nativeFrame", "schemeGvm"],
                             reports["earlier"]["investigation"]["sites"]["F6-20-7"]["openRoutes"])
            self.assertEqual(["makeProvenance", "nativeFrame"],
                             reports["revised"]["investigation"]["sites"]["F6-20-7"]["openRoutes"])
            self.assertEqual("PASS", reports["alternate"]["correspondenceReview"]["status"])
            self.assertEqual(["nativeFrame"], reports["alternate"]["investigation"]["sites"]["F6-20-7"]["openRoutes"])
            self.assertEqual(str(alternate.producer_run), reports["alternate"]["run"])
            self.assertEqual("INVALID", reports["invalid"]["status"])
            self.assertEqual("MISMATCH", reports["lost"]["status"])
            # Apply only ASCENT's receipt-bound additions to a caller-owned draft.
            del document["handlers"]["gsi/gsi"]
            draft_sha = write(draft, document)
            repair = review(fixture.gsi_sha, draft)["investigation"]["draftAdditions"]
            self.assertEqual(draft_sha, repair["receiptSha256"])
            self.assertEqual({"objectSha256", "image", "imageSha256"}, set(repair["fields"]["F6-20-7"]))
            self.assertEqual(draft_sha, digest(draft))
            document["sites"][-1].update(repair["fields"]["F6-20-7"])
            document["handlers"]["gsi/gsi"] = repair["fields"]["gsi/gsi"]["handler"]
            write(draft, document)
            repaired = review(fixture.gsi_sha, draft)
            self.assertEqual("PASS", repaired["correspondenceReview"]["status"])
            self.assertEqual([
                dict(check=check, subject="##comp-do", action="observe-or-repair-native-frame")
                for check in ("firstWrite", "nativeFrameComplete", "noCommittedReplay",
                              "oldFrameBacking", "savedHandlerFp", "unwoundCallerFp")
            ], repaired["investigation"]["sites"]["F6-20-7"]["evidenceNeeded"])
            document["sites"][-1]["objectSha256"] = "a" * 64
            write(draft, document)
            conflicting = review(fixture.gsi_sha, draft)["investigation"]
            self.assertNotIn("F6-20-7", conflicting["draftAdditions"]["fields"])
            self.assertIn("resolve-conflict", {row["action"] for row in
                                              conflicting["sites"]["F6-20-7"]["evidenceNeeded"]})
            lineage = fixture.producer_run / "run/bootstrap/make-lineage"
            write(make_lineage.action_directory(lineage, 2, "link", "gsi/gsi") / "link.map", "replaced")
            changed = review(fixture.gsi_sha)
            self.assertEqual("MISMATCH", changed["status"])
            self.assertEqual("PASS", changed["linkSelection"]["gsc/gsc"]["objects"]["lib/mem.o"]["status"])
            self.assertEqual("BLOCKED", changed["linkSelection"]["gsi/gsi"]["objects"]["lib/mem.o"]["status"])
            (make_lineage.action_directory(lineage, 2, "link", "gsc/gsc") / "receipt.json").unlink()
            missing = review(fixture.gsi_sha)
            self.assertEqual(("MISSING", "finalLink"), (missing["status"], missing["edge"]))
            self.assertEqual("MISSING", missing["recordedImages"]["gsc/gsc"]["status"])
            self.assertEqual("PASS", missing["recordedImages"]["gsi/gsi"]["status"])
            for site, status in (("F6-20-1", "MISSING"), ("F6-20-7", "PASS")):
                checks = missing["investigation"]["sites"][site]["checks"]
                self.assertEqual(status, next(row["status"] for row in checks if row["check"] == "finalLink"))
            self.assertEqual(prefix, read_execution_checkpoint(root, fixture.producer_run)["prefixIdentity"])

    def test_original_campaign_read(self):
        with task_fixture("family6-item12") as (root, cache):
            shutil.copytree(ROOT / "evidence/dsl", root / "evidence/dsl")
            for kind in ("complete", "missing", "missing-child", "timeout", "failed-case", "old-clock", "old-step",
                         "overlap", "wrong-gsi", "wrong-inventory", "inner-overrun", "outer-overrun", "changed-output",
                         "wrong-source-lock", "missing-lineage", "wrong-make-seed", "broken-make-edge", "missing-family-case",
                         "changed-family-trace", "changed-gsi", "gate2-no-receipt", "gate2-no-site",
                         "gate2-no-map", "gate2-not-loaded", "gate2-wrong-image", "gate2-wrong-object", "gate2-wrong-generated",
                         "gate2-wrong-handler", "gate2-wrong-semantic", "gate2-wrong-generation", "gate2-changed-map",
                         "gate2-ordinal-only", "gate2-semantic-first"):
                with self.subTest(kind=kind):
                    fixture = CampaignReceipt(root, cache / "runs" / kind, kind=kind)
                    fixture.topology(2, 3, 1010, missing=kind == "missing", timeout=kind == "timeout")
                    if kind != "timeout":
                        p1_start = {"overlap": 1013, "inner-overrun": 1294}.get(kind, 1040)
                        fixture.topology(1, 4, p1_start,
                                         failure=kind == "failed-case",
                                         clock=dict(fixture.clock, runId="earlier-run") if kind == "old-clock" else None)
                    if kind == "wrong-gsi":
                        fixture.gate["executableSha256"] = "b" * 64
                    if kind == "wrong-inventory":
                        fixture.progress["selectedFiles"] = fixture.files[:-1]
                    if kind == "outer-overrun":
                        fixture.outer["wholeSeconds"] = 300.1
                    fixture.seal(timeout=kind == "timeout")
                    if kind == "missing-child":
                        (fixture.run / "receipt.json").unlink()
                    if kind == "old-step":
                        fixture.child["steps"][-1] = json.loads((cache / "runs/complete/run/receipt.json").read_text())["steps"][-1]
                        fixture.outer["childReceiptSha256"] = write(fixture.run / "receipt.json", fixture.child)
                        write(fixture.out / "receipt.json", fixture.outer)
                    if kind == "changed-output":
                        write(fixture.run / "stress/p1-suite-0-0.log", "replaced")
                    if kind == "changed-family-trace":
                        write(fixture.rest_run / "run/rest-9-ordinary-race/rest-observation.bin", "replaced")
                    if kind == "changed-gsi":
                        write(fixture.runtime / "gsi/gsi", "replaced")
                    if kind == "gate2-changed-map":
                        directory = fixture.producer_run / "run/bootstrap/make-lineage"
                        write(make_lineage.action_directory(directory, 2, "link", "gsi/gsi") / "link.map", "replaced")
                    audit = fixture.read()
                    investigation = audit["links"]["gate2"]["investigation"]
                    self.assertEqual(("ASCENT", "PROJECTED"), (investigation["backend"], investigation["status"]))
                    self.assertEqual(list(SITES), list(investigation["sites"]))
                    self.assertFalse(investigation["runtimeAdmitted"])
                    self.assertFalse(investigation["executionAuthorized"])
                    eval_site = investigation["sites"]["F6-20-7"]
                    checks = {(row["check"], row["subject"]): row["status"] for row in eval_site["checks"]}
                    self.assertEqual(kind == "complete", audit["passed"], audit["gaps"])
                    self.assertFalse(audit["runtimeAdmitted"])
                    self.assertFalse(audit["executionAuthorized"])
                    p2, p1 = audit["topologies"]
                    self.assertEqual([(2, 3), (1, 4)], [(row["processors"], row["jobs"]) for row in (p2, p1)])
                    self.assertEqual((295, 300), (audit["innerBudgetSeconds"], audit["wholeBudgetSeconds"]))
                    if kind == "complete":
                        self.assertEqual(["nativeFrame"], eval_site["openRoutes"])
                        self.assertTrue(all(link["status"] == "PASS" for link in audit["links"].values()))
                        sites = audit["links"]["gate2"]["sites"]
                        self.assertEqual([row["id"] for row in sites], list(SITES))
                        self.assertEqual([row["image"] for row in sites], ["gsc/gsc"] * 6 + ["gsi/gsi"])
                        self.assertEqual(sites[-1]["object"], "lib/_eval.o")
                        self.assertEqual(11, audit["links"]["familyA"]["verifiedCases"])
                        self.assertEqual(2, audit["links"]["makeLineage"]["actionsPerPass"]["link"])
                        self.assertEqual(fixture.files, p2["completed"])
                        self.assertEqual(fixture.files, p1["completed"])
                        self.assertEqual(fixture.gsi_sha, audit["executableSha256"])
                    if kind == "missing":
                        self.assertEqual(fixture.files[::3], p2["missing"])
                        self.assertEqual(fixture.files, p1["completed"])
                    if kind == "missing-child":
                        self.assertEqual(fixture.files, p2["missing"])
                        self.assertEqual(fixture.files, p1["missing"])
                    if kind == "timeout":
                        self.assertEqual([fixture.files[0]], p2["failed"])
                        self.assertEqual([fixture.files[3]], p2["missing"])
                        self.assertEqual(fixture.files, p1["missing"])
                    if kind == "failed-case":
                        self.assertEqual([fixture.files[0]], p1["failed"])
                    if kind == "old-step":
                        self.assertIn("committed run", audit["gaps"][0])
                    if kind == "old-clock":
                        self.assertTrue(any("another campaign clock" in gap for gap in audit["gaps"]))
                    broken = {
                        "wrong-source-lock": ("sourceLock", "MISMATCH"),
                        "missing-lineage": ("makeLineage", "MISSING"),
                        "wrong-make-seed": ("makeLineage", "MISMATCH"),
                        "broken-make-edge": ("makeLineage", "MISMATCH"),
                        "missing-family-case": ("familyA", "MISSING"),
                        "changed-family-trace": ("familyA", "MISMATCH"),
                        "changed-gsi": ("sealedGsi", "MISMATCH"),
                        "wrong-gsi": ("familyA", "MISMATCH"),
                        "changed-output": ("originalCampaign", "MISMATCH"),
                    }
                    if kind in broken:
                        link, status = broken[kind]
                        self.assertEqual(status, audit["links"][link]["status"], audit["gaps"])
                        if link in {"sourceLock", "makeLineage", "sealedGsi"}:
                            gate = audit["links"]["gate2"]
                            self.assertIn(link, gate["prerequisites"])
                            self.assertEqual(list(SITES), [row["id"] for row in gate["sites"]])
                            self.assertEqual("BLOCKED", gate["linkSelection"]["gsi/gsi"]["objects"]["lib/_eval.o"]["status"])
                        if link != "originalCampaign":
                            self.assertEqual("PASS", audit["links"]["originalCampaign"]["status"])
                    gate2_breaks = {
                        "gate2-no-receipt": ("MISSING", "receipt"),
                        "gate2-no-site": ("MISSING", "semantic"),
                        "gate2-no-map": ("MISSING", "link"),
                        "gate2-not-loaded": ("MISSING", "link"),
                        "gate2-wrong-image": ("MISMATCH", "link"),
                        "gate2-wrong-object": ("MISMATCH", "object"),
                        "gate2-wrong-generated": ("MISMATCH", "generatedC"),
                        "gate2-wrong-handler": ("MISMATCH", "handler"),
                        "gate2-wrong-semantic": ("MISMATCH", "semantic"),
                        "gate2-wrong-generation": ("MISMATCH", "receipt"),
                        "gate2-changed-map": ("MISMATCH", "link"),
                    }
                    if kind in gate2_breaks:
                        gate = audit["links"]["gate2"]
                        expected = gate2_breaks[kind]
                        self.assertEqual(expected[0], gate["status"], gate)
                        self.assertEqual(expected, (gate["sites"][-1]["status"], gate["sites"][-1]["edge"]), gate)
                        if expected[1] != "receipt":
                            self.assertTrue(all(row["status"] == "PASS" for row in gate["sites"][:-1]), gate)
                        self.assertEqual("PASS", audit["links"]["originalCampaign"]["status"])
                        if kind in {"gate2-no-receipt", "gate2-no-site", "gate2-not-loaded", "gate2-no-map", "gate2-changed-map"}:
                            gsc, gsi = (gate["linkSelection"][image] for image in ("gsc/gsc", "gsi/gsi"))
                            self.assertTrue(all(row["status"] == "PASS" for row in gsc["objects"].values()))
                            self.assertEqual({
                                "gate2-not-loaded": "MISSING", "gate2-no-map": "BLOCKED", "gate2-changed-map": "BLOCKED",
                            }.get(kind, "PASS"), gsi["objects"]["lib/_eval.o"]["status"])
                    if kind == "gate2-no-receipt":
                        self.assertEqual(["nativeFrame", "schemeGvm"], eval_site["openRoutes"])
                        self.assertEqual("PASS", checks["handlerCompileInputs", "lib/_kernel.o"])
                    if kind in {"gate2-no-map", "gate2-not-loaded"}:
                        self.assertEqual(["makeProvenance", "nativeFrame"], eval_site["openRoutes"])
                        self.assertEqual("PASS", checks["finalLink", "gsi/gsi"])
                        self.assertEqual("PASS", checks["schemeGvm", "##comp-do"])
                        self.assertEqual("PASS", checks["handlerCompileInputs", "lib/mem.o"])
                        self.assertEqual("MISSING", checks["objectSelection", "lib/_eval.o"])
                        self.assertIn(dict(check="handlerCompileInputs", subject="lib/mem.o"), eval_site["reusable"])
                        action = "review-successor" if kind == "gate2-not-loaded" else "recover-or-reobserve"
                        self.assertIn(dict(check="objectSelection", subject="lib/_eval.o", action=action),
                                      eval_site["evidenceNeeded"])
                    if kind == "gate2-wrong-handler":
                        self.assertEqual("MISMATCH", checks["handlerDeclaration", "gsi/gsi"])
                    if kind == "gate2-semantic-first":
                        self.assertEqual(["makeProvenance", "nativeFrame"], eval_site["openRoutes"])
                        self.assertEqual("PASS", checks["schemeGvm", "##comp-do"])
                        self.assertEqual("PASS", checks["objectSelection", "lib/_eval.o"])
                        self.assertEqual("MISSING", checks["objectDeclaration", "lib/_eval.o"])
                    if kind == "gate2-ordinal-only":
                        self.assertEqual({"makeProvenance", "nativeFrame", "schemeGvm"}, set(eval_site["openRoutes"]))
                        self.assertEqual("PASS", checks["finalLink", "gsi/gsi"])
                        self.assertEqual("PASS", checks["handlerCompileInputs", "lib/_kernel.o"])
                        for check in (("objectSelection", "lib/_eval.o"), ("handlerCompileInputs", "lib/mem.o"),
                                      ("schemeGvm", "##comp-do")):
                            self.assertEqual("MISSING", checks[check])

    def test_item12_audit_accepts_verified_toolchain_probes_and_rejects_stray_commands(self):
        with task_fixture("family6-item12-probes") as (root, cache):
            shutil.copytree(ROOT / "evidence/dsl", root / "evidence/dsl")
            fixture = CampaignReceipt(root, cache / "runs" / "with-probes", kind="complete")
            for stage, argv, output in (
                ("compiler-version", ["/usr/bin/gcc", "--version"], "gcc (Homebrew GCC 16.2.0)\n"),
                ("compiler-backend", ["/usr/bin/gcc", "-print-prog-name=cc1"], "/usr/libexec/cc1\n"),
            ):
                fixture.step["commands"].append(dict(
                    stage=stage, argv=argv, exit=0, timeout=False,
                    parentReaped=True, processGroupQuiescent=True, streamCaptureComplete=True,
                    log=stage + ".log", logSha256=fixture.sidecar(stage + ".log", output),
                ))
            fixture.topology(2, 3, 1010)
            fixture.topology(1, 4, 1040)
            fixture.seal()
            audit = fixture.read()
            self.assertTrue(audit["passed"], audit["gaps"])
            self.assertEqual("PASS", audit["links"]["originalCampaign"]["status"])

            stray = CampaignReceipt(root, cache / "runs" / "with-stray", kind="complete")
            stray.step["commands"].append(dict(
                stage="unexpected-helper", argv=["/bin/true"], exit=0, timeout=False,
                parentReaped=True, processGroupQuiescent=True, streamCaptureComplete=True,
                log="unexpected-helper.log", logSha256=stray.sidecar("unexpected-helper.log", ""),
            ))
            stray.topology(2, 3, 1010)
            stray.topology(1, 4, 1040)
            stray.seal()
            bad = stray.read()
            self.assertFalse(bad["passed"])
            self.assertEqual("MISMATCH", bad["links"]["originalCampaign"]["status"])
