"""Recover configuration from exact old image bytes, never execute old artifacts."""
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.framework import digest
from gambit_smp.native_archive import (
    archive, archive_compiler_configuration, configure_projection, embedded_configuration,
)
from gambit_smp.native_review import compiler_configuration_change


class CompilerConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.command = ("./configure '--prefix=/Users/private/.data/old' '--enable-smp' "
                        "'--enable-multiple-vms' '--enable-multiple-threaded-vms' "
                        "'--enable-c-opt=-O1' 'CC=/opt/gcc/bin/gcc-16'")
        self.image = self.root / "gsc"
        self.image.write_bytes(b"image-prefix\0" + self.command.encode() + b"\0image-suffix")

    def test_embedded_config_is_portable_and_not_an_invocation(self):
        result = embedded_configuration(self.image)
        self.assertEqual(1, result["optimizationLevel"])
        self.assertEqual(13, result["offset"])
        self.assertEqual(len(self.command), result["rawBytes"])
        self.assertEqual(64, len(result["rawConfigureSha256"]))
        self.assertEqual("gcc-16", result["compilerBasename"])
        self.assertNotIn("/Users/", json.dumps(result))
        self.assertNotIn(".data/", json.dumps(result))

    def test_duplicate_unknown_or_overridden_configuration_is_rejected(self):
        for command in (self.command + " '--enable-c-opt=-O0'", self.command.replace("gcc-16", "clang"),
                        self.command + " --disable-smp", self.command + " --enable-smp=no",
                        self.command.replace("--enable-c-opt=-O1", "--enable-c-opt=yes"),
                        self.command + " ; echo"):
            with self.subTest(command=command), self.assertRaises(ValueError):
                configure_projection(command)
        self.image.write_bytes((self.command + "\0" + self.command + "\0").encode())
        with self.assertRaises(ValueError):
            embedded_configuration(self.image)

    def test_archive_requires_exact_failed_receipt_identity_and_image(self):
        source = self.root / "original"
        source.mkdir()
        identity = self.root / "identity.json"
        identity.write_text(json.dumps({"gscSha256": digest(self.image)}))
        receipt = {"schema": "gambit-upstream-suite.v1", "status": "DENY", "modes": ["gsc"],
                   "candidateReceiptSha256": digest(identity), "gscSha256": digest(self.image),
                   "compiler": "gcc-16 (GNU fixture)", "wholeSuiteBudgetPerMode": 300,
                   "selectedFiles": ["a.scm"], "sourceFiles": {},
                   "results": [{"mode": "gsc", "accepted": False, "exit": -9, "timeout": True}]}
        (source / "receipt.json").write_text(json.dumps(receipt))
        (source / "gsc.log").write_text("compilation incomplete\n")
        (source / "processor-probe.log").write_text("PROCESSORS:3\n")
        history = self.root / "evidence/history"
        archive(source, history, None, identity)
        out = self.root / "evidence/configuration.json"
        result = archive_compiler_configuration(history / "archive.json", self.image, out)
        self.assertFalse(result["historicalCommandObserved"])
        self.assertIsNone(result["historicalDriverSha256"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertEqual(digest(self.image), result["gscSha256"])
        runtime = self.root / "current"
        (runtime / "bin").mkdir(parents=True)
        (runtime / "gsc").mkdir()
        current_gsc = runtime / "gsc/gsc"
        current_gsc.write_bytes(b"different exact current compiler image")
        compiler = self.root / "gcc-16"
        compiler.write_text("not executed\n")
        driver = runtime / "bin/gambuild-C"
        driver.write_text(f'C_COMPILER="{compiler}"\nFLAGS_OPT=" -O0"\nBUILD_DYN="${{FLAGS_OPT}} -bundle"\n')
        def correspondence():
            return compiler_configuration_change(self.root, "evidence/history/archive.json",
                "evidence/configuration.json", receipt, runtime, compiler)
        projected, inputs = correspondence()
        self.assertEqual((1, 0), (projected["originalOptimizationLevel"], projected["currentOptimizationLevel"]))
        self.assertEqual(digest(driver), projected["currentDriverSha256"])
        self.assertIn("evidence/configuration.json", inputs)
        for field, value in (("historicalCommandObserved", True), ("historicalDriverSha256", "a" * 64),
                             ("gscSha256", "b" * 64), ("runtimeAdmitted", True)):
            out.write_text(json.dumps(dict(result, **{field: value})))
            with self.subTest(field=field), self.assertRaises(ValueError):
                correspondence()
        out.write_text(json.dumps(result))
        current_gsc.write_bytes(self.image.read_bytes())
        with self.assertRaises(ValueError):
            correspondence()
        with self.assertRaises(ValueError):
            archive_compiler_configuration(history / "archive.json", self.image, out)
        self.image.write_bytes(b"changed")
        with self.assertRaises(ValueError):
            archive_compiler_configuration(history / "archive.json", self.image, self.root / "denied.json")
