"""Historical command recovery preserves denial, identity and privacy boundaries."""
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.framework import ROOT, digest
from gambit_smp.native_archive import archive, compiler_invocation, validate
from gambit_smp.native_review import compiler_options_change


class CompilerProbeArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "original"
        (self.source / "runtime/tests").mkdir(parents=True)
        generated = self.source / "runtime/tests/probe.c"
        generated.write_text("int original_generated_source;\n")
        self.identity = self.root / "identity.json"
        self.identity.write_text(json.dumps({"gscSha256": "a" * 64}))
        self.receipt = {"schema": "gambit-compiler-cost.v1", "diagnosticOnly": True,
            "sourceStable": True, "candidateReceiptSha256": digest(self.identity),
            "gscSha256": "a" * 64, "compiler": "gcc-16 (GNU test fixture)",
            "selection": "number.scm", "sourceFiles": {"unit-tests/number.scm": "b" * 64},
            "wholeProbeBudget": 90, "status": "DENY", "stages": [
                {"name": "scheme-to-c", "accepted": True, "exit": 0, "timeout": False,
                 "artifactSha256": digest(generated)},
                {"name": "c-to-dynamic-module", "accepted": False, "exit": -9, "timeout": True}]}
        self.save()
        (self.source / "scheme-to-c.log").write_text("generated probe.c\n")
        (self.source / "c-to-dynamic-module.log").write_text(
            '/opt/gcc/bin/gcc-16 -O1 -bundle -I"/Users/private/.data/old/source/include" -o probe.o1 probe.c\n')

    def save(self):
        (self.source / "receipt.json").write_text(json.dumps(self.receipt))

    def test_recovery_is_portable_and_does_not_invent_driver_or_raw_log_binding(self):
        out = self.root / "evidence/compiler-history"
        result = archive(self.source, out, None, self.identity)
        validate(self.root, "evidence/compiler-history/archive.json")
        command = json.loads((out / "compiler-invocation.json").read_text())
        self.assertEqual(1, command["optimizationLevel"])
        self.assertFalse(command["rawLogBoundByOriginalReceipt"])
        self.assertNotIn("buildDriver", command)
        self.assertFalse(result["runtimeAdmitted"])
        self.assertIsNone(result["observedParentExit"])
        self.assertEqual((self.source / "receipt.json").read_bytes(), (out / "receipt.json").read_bytes())
        self.assertFalse((out / "probe.c").exists())
        for path in out.iterdir():
            self.assertNotIn("/Users/", path.read_text())
            self.assertNotIn(".data/", path.read_text())

    def test_generated_c_or_original_identity_drift_is_rejected(self):
        self.receipt["gscSha256"] = "c" * 64
        self.save()
        with self.assertRaises(ValueError):
            archive(self.source, self.root / "denied", None, self.identity)
        self.receipt["gscSha256"] = "a" * 64
        self.save()
        (self.source / "runtime/tests/probe.c").write_text("changed\n")
        with self.assertRaises(ValueError):
            archive(self.source, self.root / "denied", None, self.identity)

    def test_original_parent_exit_is_not_recovered_from_phase_exit(self):
        with self.assertRaises(ValueError):
            archive(self.source, self.root / "denied", 1, self.identity)

    def test_ambiguous_non_gnu_or_extra_command_is_rejected(self):
        original = (self.source / "c-to-dynamic-module.log").read_text()
        for log in (original + original, original.replace("gcc-16", "clang"),
                    original.replace("-O1", "-O1 -O3"),
                    original.replace("-o probe.o1", "-o probe.o1 ; echo")):
            with self.subTest(log=log), self.assertRaises(ValueError):
                compiler_invocation(log)

    def test_snapshot_tampering_is_not_accepted_by_archive_validation(self):
        out = self.root / "evidence/compiler-history"
        archive(self.source, out, None, self.identity)
        (out / "compiler-invocation.json").write_text("{}")
        with self.assertRaises(ValueError):
            validate(self.root, "evidence/compiler-history/archive.json")

    def test_current_options_bind_real_driver_and_unchanged_fixture(self):
        out = self.root / "evidence/compiler-history"
        unit = self.root / "tests"
        unit.mkdir()
        fixture = unit / "number.scm"
        fixture.write_text("(display 1)\n")
        self.receipt["sourceFiles"]["unit-tests/number.scm"] = digest(fixture)
        self.save()
        archive(self.source, out, None, self.identity)
        runtime = self.root / "runtime"
        (runtime / "bin").mkdir(parents=True)
        compiler = self.root / "gcc-16"
        compiler.write_text("fixture compiler path; never executed\n")
        driver = runtime / "bin/gambuild-C"
        valid = f'C_COMPILER="{compiler}"\nFLAGS_OPT=" -O0"\nBUILD_DYN="${{FLAGS_OPT}} -bundle"\n'
        driver.write_text(valid)
        def check():
            return compiler_options_change(self.root, "evidence/compiler-history/archive.json",
                                           self.receipt, runtime, unit, compiler)
        result, inputs = check()
        self.assertEqual((1, 0), (result["originalOptimizationLevel"], result["currentOptimizationLevel"]))
        self.assertEqual(digest(driver), result["currentDriverSha256"])
        self.assertFalse(result["rawLogBoundByOriginalReceipt"])
        self.assertEqual(6, len(inputs))
        for invalid in (valid.replace("-O0", "$FLAGS"), valid + 'FLAGS_OPT=" -O1"\n',
                        valid.replace("${FLAGS_OPT}", "${FLAGS_OPT_RTS}"),
                        valid.replace(str(compiler), "/nonexistent/clang")):
            driver.write_text(invalid)
            with self.subTest(driver=invalid), self.assertRaises(ValueError):
                check()
        driver.write_text(valid)
        fixture.write_text("(display 2)\n")
        with self.assertRaises(ValueError):
            check()

    def test_nonstring_artifact_identity_is_typed_rejection(self):
        self.receipt["stages"][0]["artifactSha256"] = 12
        self.save()
        with self.assertRaises(ValueError):
            archive(self.source, self.root / "denied", None, self.identity)


if __name__ == "__main__":
    unittest.main()
