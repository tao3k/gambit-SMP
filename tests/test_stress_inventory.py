"""Exact stress inventory transport; no runtime acceptance is implied."""
from pathlib import Path
import json
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp.framework import ROOT, digest
from gambit_smp.suite_primitives import selected_files
from gambit_smp.native_capabilities import run_suite_groups, validate_suite
from gambit_smp.ordered_stress import ordered_stress_start_check, ordered_stress_suite
from tests.support import task_fixture


class StressInventoryTests(unittest.TestCase):
    def test_explicit_inventory_preserves_default_and_helpers(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name in ("a.scm", "a_stress.scm", "#.scm"):
                (root / name).write_text("")
            self.assertEqual([Path("a.scm")], selected_files(root, ["."]))
            self.assertEqual([Path("a_stress.scm")], selected_files(root, ["."], inventory="stress"))
            with self.assertRaises(ValueError):
                selected_files(root, ["a_stress.scm"])
            with self.assertRaises(ValueError):
                selected_files(root, ["."], inventory="all")

    def test_completed_bootstrap_keeps_the_qualified_profile(self):
        from gambit_smp.completed_producer import SCHEMA, campaign_configuration
        producer_rel = "evidence/research/retained/modern-c/family6-local-admit-v9/completed-producer.json"
        producer = json.loads((ROOT / producer_rel).read_text())
        self.assertEqual(SCHEMA, producer["schema"])
        if (ROOT / producer["run"] / "run/receipt.json").is_file():
            configuration = campaign_configuration(ROOT, producer_rel)
            self.assertEqual("884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69",
                             configuration["profileSha256"])
            self.assertEqual({"include/gambit.h", "lib/makefile"}, set(configuration["files"]))
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            profile_path = root / "evidence/fixtures/test-profile/profile.json"
            profile_path.parent.mkdir(parents=True)
            profile_path.write_text(json.dumps({"flags": ["--enable-smp"]}))
            profile_sha = digest(profile_path)
            run_dir = root / ".cache/tasks/test-task/completed-run"
            (run_dir / "run").mkdir(parents=True)
            cfg_files = {"include/gambit.h": "a" * 64, "lib/makefile": "b" * 64}
            child = {
                "inputs": {"evidence/fixtures/test-profile/profile.json": profile_sha},
                "steps": [
                    {"id": "candidate", "capability": "gambit.materialize", "dependsOn": [], "outcome": "PASS"},
                    {"id": "configure", "capability": "gambit.configure", "dependsOn": ["candidate"],
                     "outcome": "PASS",
                     "arguments": {"source": {"step": "candidate"}, "buildProfile": "evidence/fixtures/test-profile/profile.json"},
                     "buildProfile": {"flags": ["--enable-smp"]},
                     "configurationFiles": cfg_files},
                    {"id": "seed", "capability": "gambit.seed-core", "dependsOn": ["configure"],
                     "outcome": "PASS", "arguments": {"source": {"step": "configure"}}},
                    {"id": "bootstrap", "capability": "gambit.bootstrap", "dependsOn": ["seed"],
                     "outcome": "PASS",
                     "arguments": {"runtime": {"step": "seed"}, "identity": {"step": "seed"}},
                     "configurationFiles": cfg_files},
                ],
            }
            (run_dir / "run/receipt.json").write_text(json.dumps(child))
            ref = root / "evidence/research/retained/test/completed-producer.json"
            ref.parent.mkdir(parents=True)
            ref.write_text(json.dumps({
                "schema": SCHEMA,
                "run": ".cache/tasks/test-task/completed-run",
                "step": "bootstrap",
            }))
            cfg = campaign_configuration(root, "evidence/research/retained/test/completed-producer.json")
            self.assertEqual(profile_sha, cfg["profileSha256"])
            self.assertEqual({"include/gambit.h", "lib/makefile"}, set(cfg["files"]))

    def test_all_four_unmodified_upstream_stress_files_are_selected(self):
        root = ROOT / "vendor/gambit/tests/unit-tests"
        self.assertEqual([
            Path("06-thread/tfib_stress.scm"),
            Path("06-thread/thread_interrupt2_stress.scm"),
            Path("06-thread/thread_interrupt_stress.scm"),
            Path("06-thread/thread_terminate_stress.scm"),
        ], selected_files(root, ["."], inventory="stress"))

    def test_runner_switch_and_exact_stress_completion(self):
        with task_fixture('stress-inventory') as (root, cache):
            runtime, copied = root / "runtime", root / "copied"
            for name in ('gsi', 'gsc', 'lib', 'include', 'bin'):
                (runtime / name).mkdir(parents=True)
            copied.mkdir()
            for inventory, observed, accepted in (
                    ("unit", None, True),
                    ("stress", "fixture_stress.scm", True),
                    ("stress", "other_stress.scm", False),
                    ("stress", None, False)):
                output = cache / 'runs' / f'{inventory}-{observed}'
                output.mkdir(parents=True)
                argv = []

                def run(name, command, cwd, cap):
                    argv.extend(command)
                    markers = (f"[  0|  0]   0% ................ .0s {observed}\n"
                               "[  1|  0] 100% ################ .1s\n"
                               if observed else "")
                    return 0, markers + "PASSED ALL 1 UNIT TESTS\n", False, 0.1

                ctx = SimpleNamespace(root=root, directory=output,
                    deadline=time.monotonic() + 10, run=run, env={}, tools={}, commands=[])
                prefixes = ("p2-", "p1-") if inventory == "stress" and accepted else ("",)
                for prefix in prefixes:
                    rows = run_suite_groups(ctx, runtime, copied,
                        {"mode": "gsi", "regime": "whole-parallel", "inventory": inventory},
                        [Path("fixture_stress.scm" if inventory == "stress" else "fixture.scm")],
                        1, "p2", prefix=prefix)
                    self.assertTrue((output / f"{prefix}suite-plan.json").is_file())
                    self.assertEqual(inventory == "stress", "-stress" in argv)
                    self.assertEqual(accepted, rows[0]["accepted"])
                    if inventory == "stress":
                        self.assertEqual([observed] if accepted else [], rows[0]["observedFiles"])

    def test_ordered_populations_use_one_deadline_and_retain_failures(self):
        for first in ("pass", "rest-prerequisite", "failure", "timeout", "unknown-custody", "runner-drift", "driver-drift",
                      "stage-import", "import-cache-drift", "identity-drift", "final-identity-drift"):
            with self.subTest(first=first), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                out = root / "attempt/run"
                directory = out / "stress"
                directory.mkdir(parents=True)
                runtime = root / "cache/source"
                files = [Path(f"06-thread/{name}_stress.scm")
                         for name in ("tfib", "interrupt2", "interrupt", "terminate")]

                def put(path, content):
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text(content if isinstance(content, str) else json.dumps(content))
                    return digest(path)

                inputs = {name: put(runtime / "tests" / name, name) for name in
                          ("run-unit-tests.scm", "unit-tests/#.scm", "unit-tests/06-thread/#.scm",
                           *("unit-tests/" + str(file) for file in files))}
                profile = put(root / "profile.json", {})
                manifest = put(root / "manifest.json", {
                    "spec": dict(profile=profile, mode="gsi", inventory="stress", processors="2;1",
                                 jobs="2:3;1:4", innerSeconds=295, wholeSeconds=300),
                    "cases": [dict(target=str(file), kind="original-stress", seconds=0,
                                   sha256=inputs["unit-tests/" + str(file)]) for file in files],
                })
                put(root / "inputs.json", {"originalCampaign": dict(
                    manifestSha256=manifest, profileSha256=profile, testInputFiles=inputs)})
                configuration = {name: put(runtime / name, name)
                                 for name in ("include/gambit.h", "lib/makefile")}
                configured = dict(id="configure", capability="gambit.configure", dependsOn=[], outcome="PASS",
                                  arguments={"buildProfile": "profile.json"}, buildProfile={"flags": []},
                                  configurationFiles=configuration)
                producer = dict(id="producer", capability="gambit.source-core", dependsOn=["configure"],
                                outcome="PASS", configurationFiles=configuration)
                if first in {"stage-import", "import-cache-drift"}:
                    producer = dict(id="producer", capability="gambit.runtime-import", dependsOn=[], outcome="PASS",
                        workspaceReuse={"mode": "same-producer-workspace" if first == "stage-import" else "installed-import-workspace"},
                        producerGeneration={"kind": "pinned-completed-stage", "configuration": dict(
                            profileSha256=profile, profile={"flags": []}, files=configuration)})
                header = out.parent / "run-header.json"
                header_sha = put(header, dict(schema="research-run-header.v1",
                                              budgetSeconds=300, stepBudgets={"stress": 295},
                                              startedMonotonic=1000, deadlineMonotonic=1300))
                identity = directory / "identity.json"
                put(identity, {})
                plan = dict(manifest="manifest.json", inputReceipt="inputs.json", profile="profile.json")
                args = dict(runtime=dict(step="producer", output="runtime"),
                            identity=dict(step="producer", output="identity"), mode="gsi",
                            inventory="stress", regime="whole-parallel", selection=["."],
                            expectedFiles=list(map(str, files)), failures="evidence/native-failures.json",
                            reviewRules="rules.ss", orderedStress=plan)
                declared = {*plan.values(), args["failures"], args["reviewRules"]}
                validate_suite(args, declared)
                with self.assertRaisesRegex(ValueError, "fixed populations"):
                    validate_suite({**args, "jobs": 1}, declared)
                if first == "runner-drift":
                    put(runtime / "tests/run-unit-tests.scm", "altered runner")
                now = [1010]
                groups = []
                commands = []
                env = {"TEST": "unchanged"}

                def probe(name, argv, cwd, cap):
                    commands.append(dict(parentReaped=True, processGroupQuiescent=True))
                    population = 1 if name.endswith("-runner") else int(name[1])
                    return 0, f"PROCESSORS:{population}\n", False, 0.1

                def run_groups(ctx, runtime, copied, request, files, jobs, option, *, prefix):
                    self.assertEqual(1295, ctx.deadline)
                    self.assertEqual(f"p{request['processors']}-", prefix)
                    groups.append((request["processors"], jobs))
                    outcome = first if request["processors"] == 2 else "pass"
                    if outcome == "timeout":
                        now[0] = 1295
                    if ((first == "identity-drift" and request["processors"] == 2)
                            or (first == "final-identity-drift" and request["processors"] == 1)):
                        put(identity, {"replacement": "different producer"})
                    commands.append(dict(parentReaped=True, processGroupQuiescent=outcome != "unknown-custody"))
                    return [dict(files=list(map(str, files)),
                                 accepted=outcome in {"pass", "driver-drift", "stage-import", "identity-drift", "final-identity-drift"})]

                def review(ctx, request, *unused, label):
                    return dict(decision="NOT_REQUIRED", inputs=[], campaign=dict(
                        effectiveProcessors=request["processors"], effectiveJobs=request["jobs"]))

                ctx = SimpleNamespace(root=root, out=out, directory=directory, deadline=1300,
                    env=env, progress_mode=False, commands=commands, bind=lambda _: None, run=probe,
                    receipt={"budgetSeconds": 300, "inputs": {"profile.json": profile},
                             "steps": [configured, producer],
                             "journal": {"path": str(header), "sha256": header_sha}})
                ctx.remaining = lambda: ctx.deadline - now[0]
                with patch("gambit_smp.ordered_stress.time.monotonic", side_effect=lambda: now[0]), \
                     patch("gambit_smp.suite_primitives.check_runtime"), \
                     patch("gambit_smp.ordered_stress.gnu_build_driver",
                           return_value="changed" if first == "driver-drift" else "driver"), \
                     patch("gambit_smp.build_profile.read_profile", return_value={"flags": []}), \
                     patch("gambit_smp.native_review.preflight", side_effect=review), \
                     patch("gambit_smp.native_capabilities.run_suite_groups", side_effect=run_groups), \
                     patch("gambit_smp.ordered_stress.ordered_stress_start_check",
                           side_effect=ordered_stress_start_check if first == "rest-prerequisite" else None,
                           return_value={"canStart": True}):
                    if first in {"pass", "stage-import"}:
                        result = ordered_stress_suite(ctx, args, runtime, identity, files, "gcc", "driver")
                        self.assertTrue(result["wholeFamilyComplete"])
                    else:
                        with self.assertRaises(ValueError):
                            ordered_stress_suite(ctx, args, runtime, identity, files, "gcc", "driver")
                self.assertEqual(1300, ctx.deadline)
                self.assertIs(env, ctx.env)
                if first in {"runner-drift", "import-cache-drift", "rest-prerequisite"}:
                    self.assertEqual([], groups)
                    self.assertEqual([], commands)
                    if first == "rest-prerequisite":
                        gate = json.loads((directory / "item10-preflight.json").read_text())
                        self.assertFalse(gate["canStart"])
                    continue
                report = json.loads((directory / "ordered-stress-progress.json").read_text())
                self.assertEqual(first in {"pass", "stage-import"}, report["wholeFamilyComplete"])
                self.assertFalse(report["observationsSpliced"])
                if first in {"identity-drift", "final-identity-drift"}:
                    self.assertFalse(report['runtimeIdentityStable'])
                    self.assertNotEqual(report['runtimeIdentitySha256'], digest(identity))
                if first in {"pass", "failure", "driver-drift", "stage-import", "final-identity-drift"}:
                    self.assertEqual([(2, 3), (1, 4)], groups)
                    self.assertTrue(report["topologies"][1]["started"])
                else:
                    self.assertEqual([(2, 3)], groups)
                    self.assertFalse(report["topologies"][1]["started"])
                    self.assertEqual("whole-deadline-exhausted-before-topology"
                                     if first == "timeout" else "runtime-identity-drift"
                                     if first == "identity-drift" else "predecessor-unresolved",
                                     report["topologies"][1]["reason"])

    def test_matches_original_profile_allows_only_rest_observation_overlay(self):
        from gambit_smp.ordered_stress import _matches_original_profile

        base = {"flags": ["--enable-smp"], "cflags": "-pipe -std=c23", "languageStandard": "c23"}
        self.assertTrue(_matches_original_profile(base, base))
        self.assertTrue(_matches_original_profile(
            dict(base, cflags="-pipe -std=c23 -D___GAMBIT_REST_OBSERVATION",
                 cflagsBinding=["-D___GAMBIT_REST_OBSERVATION"]),
            base,
        ))
        self.assertFalse(_matches_original_profile(
            dict(base, cflags="-pipe -std=c23 -DOTHER", cflagsBinding=["-DOTHER"]),
            base,
        ))
        self.assertFalse(_matches_original_profile(
            dict(base, flags=["--enable-smp", "--enable-debug"],
                 cflags="-pipe -std=c23 -D___GAMBIT_REST_OBSERVATION",
                 cflagsBinding=["-D___GAMBIT_REST_OBSERVATION"]),
            base,
        ))
