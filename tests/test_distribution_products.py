import unittest
import hashlib
import json
import tempfile
from pathlib import Path
from unittest.mock import patch
from types import SimpleNamespace

from gambit_smp.distribution_products import (
    bootstrap_with_numeric_handoff, native_inputs_equal, qualify, retired_sources,
)


class NumericObjectHandoffTests(unittest.TestCase):
    def test_second_pass_reuses_only_identical_preprocessed_inputs(self):
        for scenario in ("stable", "first-drift", "second-drift"):
            with self.subTest(scenario=scenario), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                source = root / "source"
                (source / "lib").mkdir(parents=True)
                (source / "gsc").mkdir()
                output = root / "run"
                output.mkdir()
                tools = root / "tools"
                tools.mkdir()
                for name in ("gcc", "cc1", "as"):
                    path = tools / name
                    path.write_text(name)
                    path.chmod(0o755)
                gcc = str(tools / "gcc")
                ctx = SimpleNamespace(directory=output, tools={"make": "make", "gcc": gcc},
                                      env={"PATH": str(tools)}, remaining=lambda: 600)
                target = source / "lib/_num.o"
                stages = []
                compile_log = gcc + " -O1 -c -o _num.o _num.c\n"
                def execute(name, argv, cwd, cap):
                    stages.append(name)
                    if name == "pass-one-phase3":
                        target.write_bytes(b"completed object")
                        return compile_log
                    if name == "pass-one-bootstrap":
                        for path in ("gsc/gsc", "gsc-boot"):
                            (source / path).write_bytes(b"first compiler")
                    if name == "pass-two-clean":
                        target.unlink()
                    if argv[-1].startswith("-print-prog-name="):
                        return argv[-1].split("=")[-1]
                    if name.endswith("-preprocess"):
                        changed = ((scenario == "first-drift" and name.startswith("pass-one-num-after"))
                                   or (scenario == "second-drift" and name.startswith("pass-two")))
                        data = b"changed input" if changed else b"same input"
                        Path(argv[argv.index("-o") + 1]).write_bytes(data)
                    if name.endswith("-num-plan"):
                        return compile_log
                    if name == "pass-two-phase3":
                        self.assertEqual(target.exists(), scenario == "stable")
                        if scenario != "stable":
                            target.write_bytes(b"rebuilt object")
                            return compile_log
                    return ""

                result = bootstrap_with_numeric_handoff(ctx, source, execute)
                self.assertEqual(result["restored"], scenario == "stable")
                self.assertLess(stages.index("pass-one-num-before-preprocess"), stages.index("pass-one-phase3"))
                self.assertLess(stages.index("pass-one-phase3"), stages.index("pass-one-num-after-preprocess"))
                self.assertEqual(stages[-2:], ["pass-two-phase4", "pass-two-core"])
                self.assertEqual(json.loads((output / "numeric-handoff.json").read_text()), result)


class SourceRetirementTests(unittest.TestCase):
    def test_only_exact_declared_source_retirement_is_accepted(self):
        old = {"lib/old.c": {"mode": "100644"},
               "lib/live.c": {"mode": "100644"}}
        desired = {"lib/live.c": old["lib/live.c"]}
        self.assertEqual(retired_sources(old, desired, ["lib/old.c"]),
                         ["lib/old.c"])
        for declaration in ([], ["lib/live.c"],
                            ["lib/old.c", "lib/old.c"], ["../outside"]):
            with self.subTest(declaration=declaration), self.assertRaises(ValueError):
                retired_sources(old, desired, declaration)

    def test_symlinks_and_generated_products_are_not_source_retirements(self):
        with self.assertRaises(ValueError):
            retired_sources({"link": {"mode": "120000"}}, {}, ["link"])
        self.assertEqual(retired_sources({"lib/_kernel.c": {"mode": "100644"}},
                                         {}, []), [])
        with self.assertRaises(ValueError):
            retired_sources({"lib/_kernel.c": {"mode": "100644"}},
                            {}, ["lib/_kernel.c"])


class CompletedProducerCustodyTests(unittest.TestCase):
    def test_resume_never_installs_saved_inputs_as_current_outputs(self):
        raw = b"current source\n"
        h = hashlib.sha256(raw).hexdigest()
        tree = {"lib/live.c": dict(mode="100644", data=raw, bytes=len(raw), sha256=h)}
        names = ("gsi/gsi", "gsc/gsc", "gsc-boot", "lib/libgambit.a")
        for scenario in ("exact", "snapshot-before-clean", "snapshot-log-drift", "snapshot-phase-order", "generation-drift", "seed-drift", "incomplete", "flags-drift"):
            with self.subTest(scenario=scenario), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                source, saved, output = root / "source", root / "runs/prior", root / "runs/current"
                (source / "lib").mkdir(parents=True)
                saved.mkdir(parents=True)
                output.mkdir()
                (source / "lib/live.c").write_bytes(raw)
                (source / "gsc-boot.unix").write_bytes(b"dummy")
                (source / "gsc-boot").write_bytes(b"dummy")
                prior = {}
                for name in names:
                    donor = saved / "prior-seed" / name
                    donor.parent.mkdir(parents=True, exist_ok=True)
                    donor.write_bytes(b"old bootstrap input")
                    prior[name] = hashlib.sha256(donor.read_bytes()).hexdigest()
                receipt = dict(baseRevision="head", targetTree="candidate", complete=False,
                               priorArtifacts=prior, configurationFlags=[],
                               phaseCounts=dict(phase1=2, phase2=2, phase3=2, phase4=2),
                               bootstrapSeedSha256=prior["gsc-boot"],
                               generatedArtifacts={"lib/_kernel.c": "generated"},
                               changedGeneratedArtifacts={}, checks=[
                                   dict(stage=stage, complete=True, seconds=1)
                                   for stage in ("source-bootstrap", "clean-objects", "dummy-seed")])
                if scenario.startswith("snapshot-"):
                    from gambit_smp.distribution_products import preserve_generated_products
                    generated = source / "lib/_kernel.c"
                    generated.write_bytes(raw)
                    products = {"lib/_kernel.c": hashlib.sha256(raw).hexdigest()}
                    preserve_generated_products(source, saved, products)
                    generated.unlink()
                    (source / "gsc-boot").write_bytes(b"real compiler")
                    phases = (1, 2, 3, 4) if scenario != "snapshot-phase-order" else (1, 3, 2, 4)
                    stdout = "".join(f"*** making phase{i}\n" for i in phases * 2).encode()
                    (saved / "source-bootstrap.stdout").write_bytes(
                        stdout + b"drift" if scenario == "snapshot-log-drift" else stdout)
                    receipt.update(generatedArtifacts=products, generatedSnapshot="generated-c",
                                   generationCheckpoint=True, generatedSnapshotConfiguration={},
                                   generatedSnapshotHeaders={},
                                   checks=receipt["checks"][:1],
                                   commands=[dict(stage="source-bootstrap", exit=0, timeout=False,
                                                  parentReaped=True, processGroupQuiescent=True,
                                                  stdoutSha256=hashlib.sha256(stdout).hexdigest())])
                if scenario == "seed-drift":
                    (saved / "prior-seed/gsc/gsc").write_bytes(b"changed")
                if scenario == "incomplete":
                    receipt["checks"][0]["complete"] = False
                if scenario == "flags-drift":
                    receipt["configurationFlags"] = ["--different"]
                receipt_name = ("generation-checkpoint.json" if scenario.startswith("snapshot-")
                                else "result.json")
                (saved / receipt_name).write_text(json.dumps(receipt))
                context = SimpleNamespace(directory=output, tools={"make": "make"},
                                          commands=[], remaining=lambda: 120)
                def execute(stage, argv, cwd, cap, **kwargs):
                    if stage == 'clean-objects':
                        self.assertEqual(argv, ['make','clean'])
                        self.assertLessEqual(cap,30)
                        context.commands.append(dict(parentReaped=True,processGroupQuiescent=True))
                        return 0,'',False,0.1
                    if stage == "dummy-seed" and scenario == "snapshot-before-clean":
                        (source / "gsc-boot").write_bytes(b"dummy")
                        context.commands.append(dict(parentReaped=True, processGroupQuiescent=True))
                        return 0, "", False, 0.1
                    self.assertEqual(stage, "stock-core")
                    self.assertLessEqual(cap, 120)
                    for name in ("gsi/gsi", "gsc/gsc", "lib/libgambit.a"):
                        self.assertFalse((source / name).exists(), name)
                        path = source / name
                        path.parent.mkdir(parents=True, exist_ok=True)
                        path.write_bytes(b"current linked output")
                    context.commands.append(dict(parentReaped=True, processGroupQuiescent=True))
                    return 0, "", False, 0.1
                context.run = execute
                inventory = {"lib/_kernel.c": "drift" if scenario == "generation-drift" else "generated"}
                from gambit_smp.native_development import generated_inventory
                inspect_inventory = (generated_inventory if scenario == "snapshot-before-clean"
                                     else lambda _: inventory)
                with patch("gambit_smp.distribution_products.git", side_effect=lambda repo, *args:
                           b"head" if args[0] == "rev-parse" else b"tree"), \
                     patch("gambit_smp.distribution_products.archive_sources", return_value=tree), \
                     patch("gambit_smp.distribution_products.configuration_request", return_value={}), \
                     patch("gambit_smp.distribution_products.configure_owned_source"), \
                     patch("gambit_smp.distribution_products.generated_inventory", side_effect=inspect_inventory), \
                     patch("gambit_smp.distribution_products.checkpoint_build_source"):
                    if scenario in {"exact", "snapshot-before-clean"}:
                        result = qualify(context, root, source, "candidate", {},
                                         {"requestIdentity": {"environment": {}}}, flags=[],
                                         check_monolithic=False, resume=receipt, resume_storage=saved)
                        self.assertTrue(result["producerComplete"])
                        self.assertTrue(result["composedStages"])
                        if scenario == "snapshot-before-clean":
                            self.assertEqual(result["restoredGeneratedArtifacts"], ["lib/_kernel.c"])
                            self.assertEqual(len(context.commands), 3)
                        else:
                            self.assertEqual(len(context.commands), 2)
                        self.assertNotEqual(result["artifacts"]["gsi/gsi"], prior["gsi/gsi"])
                        self.assertEqual((output / "prior-seed/gsi/gsi").read_bytes(), b"old bootstrap input")
                    else:
                        with self.assertRaises(ValueError):
                            qualify(context, root, source, "candidate", {},
                                    {"requestIdentity": {"environment": {}}}, flags=[],
                                    resume=receipt, resume_storage=saved)
                        self.assertFalse((source / "gsi/gsi").exists())
                        self.assertEqual(context.commands, [])

    def test_published_tree_reuses_only_exact_completed_source_and_products(self):
        raw = b"published runtime source\n"
        h = hashlib.sha256(raw).hexdigest()
        tree = {"lib/live.c": dict(mode="100644", data=raw, bytes=len(raw), sha256=h)}
        for scenario in ("exact", "different-tree", "source-drift", "artifact-drift"):
            with self.subTest(scenario=scenario), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                source, output = root / "source", root / "run"
                output.mkdir()
                (source / "lib").mkdir(parents=True)
                (source / "lib/live.c").write_bytes(raw)
                artifacts = {}
                for name in ("gsi/gsi", "gsc/gsc", "gsc-boot", "lib/libgambit.a"):
                    p = source / name
                    p.parent.mkdir(parents=True, exist_ok=True)
                    p.write_bytes(b"completed native product")
                    artifacts[name] = hashlib.sha256(p.read_bytes()).hexdigest()
                parent = dict(producerComplete=True, baseRevision="prior-base", targetTree="published-tree",
                              canonicalSources={"lib/live.c": h}, artifacts=artifacts,
                              generatedArtifacts={"gsc-boot": artifacts["gsc-boot"]})
                if scenario == "source-drift":
                    (source / "lib/live.c").write_bytes(b"unqualified change")
                if scenario == "artifact-drift":
                    (source / "gsc/gsc").write_bytes(b"different compiler")
                def git(_repo, *args):
                    if args == ("rev-parse", "HEAD"):
                        return b"published-commit"
                    if args == ("rev-parse", "published-commit^{tree}"):
                        return b"other-tree" if scenario == "different-tree" else b"published-tree"
                    return b"archive"
                with patch("gambit_smp.distribution_products.git", side_effect=git), \
                     patch("gambit_smp.distribution_products.archive_sources", return_value=tree), \
                     patch("gambit_smp.distribution_products.configuration_request",
                           side_effect=ValueError("stop before configuration")), \
                     patch("gambit_smp.distribution_products.checkpoint_build_source"):
                    if scenario == "exact":
                        result = qualify(SimpleNamespace(directory=output, tools={}, commands=[]),
                                         root, source, "candidate", {},
                                         {"requestIdentity": {"environment": {}}},
                                         flags=[], source_parent=parent)
                        self.assertEqual(result["sourceParent"]["publication"],
                                         dict(commit="published-commit", tree="published-tree",
                                              priorBaseRevision="prior-base"))
                        self.assertFalse(result["complete"])
                        self.assertEqual(result["checks"], [])
                    else:
                        with self.assertRaises(ValueError):
                            qualify(None, root, source, "candidate", {}, {}, source_parent=parent)
                        self.assertEqual(list(output.iterdir()), [])

    def test_child_returning_to_head_restores_parent_source_before_configuration(self):
        def row(raw):
            return dict(mode="100644", data=raw, bytes=len(raw),
                        sha256=hashlib.sha256(raw).hexdigest())
        baseline = {"lib/_kernel.scm": row(b"baseline\n")}
        parent = {"lib/_kernel.scm": row(b"candidate-only experiment\n")}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source"
            (source / "lib").mkdir(parents=True)
            (source / "lib/_kernel.scm").write_bytes(parent["lib/_kernel.scm"]["data"])
            artifacts = {}
            for name in ("gsi/gsi", "gsc/gsc", "gsc-boot", "lib/libgambit.a"):
                target = source / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(b"retained binary")
                artifacts[name] = hashlib.sha256(target.read_bytes()).hexdigest()
            output = root / "run"
            output.mkdir()
            receipt = dict(producerComplete=True, baseRevision="head", targetTree="parent",
                           canonicalSources={"lib/_kernel.scm": hashlib.sha256(
                               parent["lib/_kernel.scm"]["data"]).hexdigest()},
                           artifacts=artifacts, generatedArtifacts={"gsc-boot": artifacts["gsc-boot"]})
            def git(_repo, *args):
                return b"head" if args[0] == "rev-parse" else args[1].encode()
            with patch("gambit_smp.distribution_products.git", side_effect=git), \
                 patch("gambit_smp.distribution_products.archive_sources",
                       side_effect=lambda name: parent if name == b"parent" else baseline), \
                 patch("gambit_smp.distribution_products.configuration_request",
                       side_effect=ValueError("stop before native configuration")), \
                 patch("gambit_smp.distribution_products.checkpoint_build_source"):
                result = qualify(SimpleNamespace(directory=output, tools={}, commands=[]),
                                 root, source, "child", {}, {"requestIdentity": {"environment": {}}},
                                 flags=[], source_parent=receipt)
            self.assertEqual((source / "lib/_kernel.scm").read_bytes(), b"baseline\n")
            self.assertEqual(result["sourcePaths"], ["lib/_kernel.scm"])
            self.assertEqual(result["commands"], [])
            self.assertEqual(result["error"]["message"], "stop before native configuration")

    def test_unfinished_predecessor_binds_sources_without_inheriting_success(self):
        def row(raw):
            return dict(mode="100644", data=raw, bytes=len(raw),
                        sha256=hashlib.sha256(raw).hexdigest())
        baseline={"lib/live.c":row(b"base\n")}
        predecessor={"lib/live.c":row(b"failed candidate\n")}
        candidate={"lib/live.c":row(b"refined candidate\n")}
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); source=root/"source"; (source/"lib").mkdir(parents=True)
            (source/"lib/live.c").write_bytes(predecessor["lib/live.c"]["data"])
            for name in ("gsi/gsi","gsc/gsc","gsc-boot","lib/libgambit.a"):
                path=source/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(b"retained seed")
            output=root/"run";output.mkdir()
            def git(_repo,*args):
                return b"head" if args[0]=="rev-parse" else args[1].encode()
            with patch("gambit_smp.distribution_products.git",side_effect=git), \
                 patch("gambit_smp.distribution_products.archive_sources",side_effect=lambda name:{b"head":baseline,b"failed":predecessor,b"candidate":candidate}[name]), \
                 patch("gambit_smp.distribution_products.configuration_request",side_effect=ValueError("stop before native")), \
                 patch("gambit_smp.distribution_products.checkpoint_build_source"):
                result=qualify(SimpleNamespace(directory=output,tools={},commands=[]),root,source,"candidate",{},
                    {"requestIdentity":{"environment":{}}},flags=[],
                    source_predecessor=dict(baseRevision="head",targetTree="failed",producerComplete=False))
            self.assertEqual((source/"lib/live.c").read_bytes(),b"refined candidate\n")
            self.assertFalse(result["complete"])
            self.assertNotIn("producerComplete",result)
            self.assertEqual(result["checks"],[])
            self.assertFalse(result["sourcePredecessor"]["completedStagesReused"])
            self.assertFalse(result["sourcePredecessor"]["nativeAdmissionInherited"])

    def test_failed_generation_preserves_inputs_without_restoring_missing_outputs(self):
        raw = b"source\n"
        tree = {"lib/live.c": dict(mode="100644", data=raw, bytes=len(raw),
                                   sha256=hashlib.sha256(raw).hexdigest())}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); source = root / "source"
            (source / "lib").mkdir(parents=True)
            (source / "lib/live.c").write_bytes(raw)
            saved = root / "runs/failed"; saved.mkdir(parents=True)
            receipt = dict(baseRevision="head", targetTree="candidate", priorArtifacts={})
            for name in ("gsi/gsi", "gsc/gsc", "gsc-boot", "lib/libgambit.a"):
                donor = saved / "prior-seed" / name
                donor.parent.mkdir(parents=True, exist_ok=True)
                donor.write_bytes(b"preserved input")
                receipt["priorArtifacts"][name] = hashlib.sha256(donor.read_bytes()).hexdigest()
            (saved / "result.json").write_text(json.dumps(receipt))
            output = root / "runs/refined"; output.mkdir()
            with patch("gambit_smp.distribution_products.git", side_effect=lambda repo,*args:
                       b"head" if args[0] == "rev-parse" else b"tree") as git, \
                 patch("gambit_smp.distribution_products.archive_sources", return_value=tree), \
                 patch("gambit_smp.distribution_products.configuration_request",
                       side_effect=ValueError("stop before native")), \
                 patch("gambit_smp.distribution_products.checkpoint_build_source"):
                def qualify_from_saved():
                    return qualify(SimpleNamespace(directory=output, tools={}, commands=[]),
                        root, source, "candidate", {}, {"requestIdentity":{"environment":{}}},
                        flags=[], source_predecessor=receipt, source_predecessor_storage=saved)
                result = qualify_from_saved()
                git.assert_any_call(root, "archive", "candidate")
                self.assertEqual(sum(call.args[1:] == ("archive", "candidate")
                                     for call in git.call_args_list), 1)
                self.assertFalse(result["complete"])
                self.assertFalse(result["sourcePredecessor"]["nativeAdmissionInherited"])
                self.assertFalse((source / "gsi/gsi").exists())
                self.assertEqual((output / "prior-seed/gsi/gsi").read_bytes(), b"preserved input")
                retry = root / 'runs/retry'; retry.mkdir()
                (source / 'gsc-boot').write_bytes(b'unqualified intermediate')
                (source / 'gsc-boot.unix').write_bytes(b'dummy')
                context = SimpleNamespace(directory=retry, tools={'make':'make'}, commands=[], remaining=lambda:120)
                def fail_after_seed_handoff(stage, argv, cwd, cap, **kwargs):
                    self.assertEqual(stage, 'source-bootstrap')
                    self.assertEqual((source/'gsc-boot').read_bytes(), b'preserved input')
                    for name in ('gsi/gsi','gsc/gsc','lib/libgambit.a'):
                        self.assertFalse((source/name).exists())
                    context.commands.append(dict(parentReaped=True,processGroupQuiescent=True))
                    return 1, 'controlled native failure', False, 0.1
                context.run=fail_after_seed_handoff
                with patch('gambit_smp.distribution_products.configuration_request',return_value={}), \
                     patch('gambit_smp.distribution_products.configure_owned_source'):
                    failed=qualify(context,root,source,'candidate',{},
                        {'requestIdentity':{'environment':{}}},flags=[],
                        source_predecessor=receipt,source_predecessor_storage=saved)
                self.assertFalse(failed.get('producerComplete',False))
                self.assertFalse(failed['bootstrapInputHandoff']['currentOutputRestored'])
                self.assertEqual((retry/'unqualified-bootstrap-seed').read_bytes(),b'unqualified intermediate')
                (saved / "prior-seed/gsc/gsc").write_bytes(b"drift")
                with self.assertRaisesRegex(ValueError, "predecessor bootstrap input changed"):
                    qualify_from_saved()
                self.assertFalse((source / "gsi/gsi").exists())

    def test_unchanged_generated_c_still_binds_the_complete_producer_cohort(self):
        raw=b"same emitted C\n"; sha=hashlib.sha256(raw).hexdigest()
        tree={"lib/_kernel.c":dict(mode="100644",data=raw,bytes=len(raw),sha256=sha)}
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);source=root/"source";output=root/"run";output.mkdir()
            for name in ("gsi/gsi","gsc/gsc","gsc-boot","lib/libgambit.a","lib/_kernel.c"):
                p=source/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
            (source/"gsc-boot.unix").write_bytes(b"dummy")
            context=SimpleNamespace(directory=output,tools={"make":"make"},commands=[],remaining=lambda:60,last_stdout="phases")
            def execute(name,argv,cwd,cap,**kwargs):
                context.commands.append(dict(parentReaped=True,processGroupQuiescent=True))
                if name=="clean-objects":
                    self.assertEqual((output/"generated-c/lib/_kernel.c").read_bytes(), raw)
                    checkpoint = json.loads((output / "generation-checkpoint.json").read_text())
                    self.assertTrue(checkpoint["generationCheckpoint"])
                    self.assertFalse(checkpoint["complete"])
                    self.assertEqual(checkpoint["generatedArtifacts"], {"lib/_kernel.c": sha})
                    self.assertEqual([row["stage"] for row in checkpoint["checks"]], ["source-bootstrap"])
                    self.assertFalse((output / "result.json").exists())
                    raise RuntimeError("stop after output custody")
                return 0,"",False,0.1
            context.run=execute
            with patch("gambit_smp.distribution_products.git",side_effect=lambda repo,*args:b"head" if args[0]=="rev-parse" else b"tree"), \
                 patch("gambit_smp.distribution_products.archive_sources",return_value=tree), \
                 patch("gambit_smp.distribution_products.configuration_request",return_value={}), \
                 patch("gambit_smp.distribution_products.configure_owned_source"), \
                 patch("gambit_smp.distribution_products.generated_inventory",return_value={"lib/_kernel.c":sha}), \
                 patch("gambit_smp.distribution_products.bootstrap_phase_counts",return_value=dict(phase1=2,phase2=2,phase3=2,phase4=2)), \
                 patch("gambit_smp.distribution_products.checkpoint_build_source"):
                result=qualify(context,root,source,"candidate",{}, {"requestIdentity":{"environment":{}}},flags=[],publish_generated=True)
            self.assertEqual(result["generatedArtifacts"],{"lib/_kernel.c":sha})
            self.assertEqual(result["changedGeneratedArtifacts"],{})
            self.assertEqual(result["error"]["message"],"stop after output custody")
            self.assertFalse(result["complete"])

    def test_generated_snapshot_restores_only_exact_missing_or_changed_inputs(self):
        from gambit_smp.distribution_products import preserve_generated_products, restore_generated_products

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, output = root / "source", root / "run"
            (source / "lib").mkdir(parents=True)
            output.mkdir()
            products = {}
            for name in ("lib/_kernel.c", "lib/_io.c"):
                raw = name.encode()
                (source / name).write_bytes(raw)
                products[name] = hashlib.sha256(raw).hexdigest()
            preserve_generated_products(source, output, products)
            unchanged = (source / "lib/_io.c").stat().st_ino
            (source / "lib/_kernel.c").unlink()
            self.assertEqual(restore_generated_products(source, output, products), ["lib/_kernel.c"])
            self.assertEqual((source / "lib/_io.c").stat().st_ino, unchanged)
            (output / "generated-c/lib/_kernel.c").write_bytes(b"drift")
            (source / "lib/_kernel.c").unlink()
            with self.assertRaisesRegex(ValueError, "inventory changed"):
                restore_generated_products(source, output, products)
            self.assertFalse((source / "lib/_kernel.c").exists())

    def test_runtime_generator_product_and_mode_changes_forbid_test_only_reuse(self):
        row = dict(mode="100644", sha256="original")
        old = {"lib/setup.c": row, "gsc/generator.scm": row,
               "lib/_kernel.c": row, "tests/control.scm": row}
        self.assertTrue(native_inputs_equal(old, dict(old, **{
            "tests/control.scm": dict(row, sha256="changed")})))
        for name in ("lib/setup.c", "gsc/generator.scm", "lib/_kernel.c"):
            for field, value in (("sha256", "changed"), ("mode", "100755")):
                with self.subTest(name=name, field=field):
                    altered = dict(old, **{name: dict(row, **{field: value})})
                    self.assertFalse(native_inputs_equal(old, altered))
        self.assertFalse(native_inputs_equal(old, {n: row for n in old if n != "lib/setup.c"}))

    def test_invalid_parent_cannot_mutate_the_owned_workspace(self):
        raw = b"owned source\n"
        digest = hashlib.sha256(raw).hexdigest()
        tree = {"lib/live.c": dict(mode="100644", sha256=digest,
                                  bytes=len(raw), data=raw)}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "lib").mkdir()
            (root / "lib/live.c").write_bytes(raw)
            (root / "binary").write_bytes(b"artifact")
            artifact = hashlib.sha256(b"artifact").hexdigest()
            good = dict(producerComplete=True, baseRevision="head", targetTree="parent",
                        canonicalSources={"lib/live.c": digest},
                        artifacts={"binary": artifact}, generatedArtifacts={"binary": artifact})
            bad = [dict(good, producerComplete=False), dict(good, baseRevision="stale"),
                   dict(good, canonicalSources={}), dict(good, artifacts={"binary": "wrong"}),
                   dict(good, generatedArtifacts={"../outside": artifact}), {}]
            def git(_repo, *args):
                return b"head" if args[0] == "rev-parse" else b"archive"
            for parent in bad:
                with self.subTest(parent=parent), \
                     patch("gambit_smp.distribution_products.git", side_effect=git), \
                     patch("gambit_smp.distribution_products.archive_sources", return_value=tree), \
                     self.assertRaises(ValueError):
                    qualify(None, root, root, "candidate", {}, {}, source_parent=parent)
                self.assertEqual((root / "lib/live.c").read_bytes(), raw)
                self.assertEqual((root / "binary").read_bytes(), b"artifact")
                self.assertEqual(sorted(p.name for p in root.iterdir()), ["binary", "lib"])
