import unittest
import hashlib
import tempfile
from pathlib import Path
from unittest.mock import patch
from types import SimpleNamespace

from gambit_smp.distribution_products import native_inputs_equal, qualify, retired_sources


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
                if name=="clean-objects":raise RuntimeError("stop after output custody")
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
