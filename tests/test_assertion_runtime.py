"""Shared source construction, including the late fixture-state regression."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest

from gambit_smp.assertion_runtime import SharedAssertionRuntime, shared_assertion_sources
from gambit_smp.native_capabilities import validate_suite


ROOT = Path(__file__).resolve().parents[1]


class AssertionRuntimeTests(unittest.TestCase):
    def setUp(self):
        folder = ROOT / "evidence/research/retained/modern-c/frozen-568e0276-smp"
        self.receipt = json.loads((folder / "assertion-runtime-gsc.json").read_text())
        def original(name):
            return subprocess.check_output(
                [shutil.which("git"), "-C", str(ROOT / "vendor/gambit"),
                 "show", self.receipt["revision"] + ":" + name], timeout=10)
        self.harness = original("tests/unit-tests/#.scm")
        self.runner = original("tests/run-unit-tests.scm")

    def test_projection_matches_actual_native_inputs(self):
        folder = ROOT / "evidence/research/retained/modern-c/frozen-568e0276-smp"
        receipt = self.receipt
        construction = json.loads((folder / "assertion-runtime-construction.json").read_text())
        provider = construction["providerPath"]
        support, fixture, runner = shared_assertion_sources(self.harness, self.runner, provider)
        sha = lambda value: hashlib.sha256(value).hexdigest()
        self.assertEqual(sha(self.harness), receipt["assertionRuntime"]["harness"]["original"])
        self.assertEqual(sha(self.runner), receipt["assertionRuntime"]["runner"]["original"])
        self.assertEqual(sha(support), receipt["sharedRuntimeBuild"]["sourceSha256"])
        self.assertEqual(sha(fixture), receipt["assertionRuntime"]["harness"]["shared"])
        self.assertEqual(sha(runner), receipt["assertionRuntime"]["runner"]["shared"])

    def test_state_stays_in_fixture_and_hook_reads_it_late(self):
        support, fixture, runner = shared_assertion_sources(self.harness, self.runner, "/provider.o1")
        self.assertIn(b"(define ##failed-test? #f)", fixture)
        self.assertIn(b"(define epsilon 0)", fixture)
        self.assertIn(b"(##test-install-exit-hook (lambda () ##tested-procs))", fixture)
        self.assertNotIn(b"##tested-procs", support)
        self.assertIn(b"(##not (##eq? creator ##call-thunk))", support)
        self.assertEqual(self.harness.count(b"\n"), fixture.count(b"\n"))
        self.assertIn(b'"-f" "/provider.o1" file)', runner)

    def test_ambiguous_or_missing_sources_refuse_projection(self):
        with self.assertRaises(ValueError):
            shared_assertion_sources(self.harness + b"(define (##failed-test ", self.runner, "/provider.o1")
        with self.assertRaises(ValueError):
            shared_assertion_sources(self.harness.replace(b"                       ##tested-procs)", b"changed"), self.runner, "/provider.o1")
        with self.assertRaises(ValueError):
            shared_assertion_sources(self.harness, self.runner + self.runner, "/provider.o1")

    def test_provider_path_is_scheme_string_data(self):
        provider = '/provider with "quotes" and \\slashes.o1'
        _, _, runner = shared_assertion_sources(self.harness, self.runner, provider)
        self.assertIn(json.dumps(provider, ensure_ascii=False).encode(), runner)
        with self.assertRaises(ValueError):
            shared_assertion_sources(self.harness, self.runner, "bad\0path")

    def prepare_runtime(self, directory):
        copied = directory / "inputs"
        (copied / "unit-tests").mkdir(parents=True)
        (copied / "unit-tests/#.scm").write_bytes(self.harness)
        (copied / "run-unit-tests.scm").write_bytes(self.runner)
        ctx = SimpleNamespace(directory=directory, commands=[], receipt={}, remaining=lambda: 30)
        def run(stage, argv, cwd, budget):
            (cwd / "assertion-support.c").write_text("unit-only compiled input")
            (cwd / "assertion-support.o1").write_bytes(b"unit-only bundle")
            ctx.commands.append(dict(stage=stage, parentReaped=True, processGroupQuiescent=True))
            return 0, "", False, 0.001
        ctx.run = run
        support = SharedAssertionRuntime(ctx, directory, copied, "p1")
        return copied, ctx, support

    def test_one_build_serves_two_settled_fixture_loads(self):
        with tempfile.TemporaryDirectory() as temporary:
            work, ctx, support = self.prepare_runtime(Path(temporary))
            for stage in ("first", "second"):
                with support.fixture_sources(work, stage):
                    self.assertEqual((work / "unit-tests/#.scm").read_bytes(), support.fixture)
                    ctx.commands.append(dict(stage=stage, parentReaped=True, processGroupQuiescent=True))
                self.assertEqual((work / "unit-tests/#.scm").read_bytes(), self.harness)
                self.assertEqual((work / "run-unit-tests.scm").read_bytes(), self.runner)
            self.assertEqual(sum(row["stage"] == "suite-support-build" for row in ctx.commands), 1)

    def test_unknown_child_retains_source_custody(self):
        with tempfile.TemporaryDirectory() as temporary:
            work, ctx, support = self.prepare_runtime(Path(temporary))
            with self.assertRaisesRegex(ValueError, "unsettled fixture"):
                with support.fixture_sources(work, "unknown"):
                    ctx.commands.append(dict(stage="unknown", parentReaped=True, processGroupQuiescent=False))
            self.assertEqual((work / "unit-tests/#.scm").read_bytes(), support.fixture)
            self.assertEqual((work / "run-unit-tests.scm").read_bytes(), support.loader)

    def test_changed_bundle_refuses_overlay(self):
        with tempfile.TemporaryDirectory() as temporary:
            work, _, support = self.prepare_runtime(Path(temporary))
            support.bundle.write_bytes(b"changed")
            with self.assertRaisesRegex(ValueError, "source or provider changed"):
                with support.fixture_sources(work, "refused"):
                    self.fail("changed provider must refuse entry")
            self.assertEqual((work / "unit-tests/#.scm").read_bytes(), self.harness)

    def test_capability_selects_only_compiled_unit_protocol(self):
        ref = dict(step="runtime", output="runtime")
        args = dict(runtime=ref, identity=ref, mode="gsc", regime="whole-parallel",
                    selection=["00-test/test_error_tail.scm"],
                    expectedFiles=["00-test/test_error_tail.scm"], sharedAssertions=True)
        validate_suite(args, {})
        for change in (dict(mode="gsi"), dict(sharedAssertions=1), dict(inventory="stress")):
            with self.assertRaises(ValueError):
                validate_suite({**args, **change}, {})
