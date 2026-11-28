from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.gambit_build_primitives import build_hosted_core
from gambit_smp.native_capabilities import validate_seed


class HostedBootstrapTests(unittest.TestCase):
    def test_old_c_is_removed_before_target_build_and_self_pass_is_not_invented(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("lib", "gsi", "gsc"):
                (root/name).mkdir()
            (root/"gsc/igsc.scm").write_text("current source compiler")
            (root/"lib/_a.scm").write_text("(define a 1)")
            (root/"lib/_a.c").write_text("old ABI")
            (root/"lib/_gambit.c").write_text("old linker metadata")
            calls = []

            class Stages:
                def run(self, stage, argv, cwd, timeout, **kwargs):
                    calls.append(stage)
                    if stage == "hosted-bootclean":
                        (root/"lib/_a.c").unlink()
                        (root/"lib/_gambit.c").unlink()
                    else:
                        self_outer.assertFalse((root/"lib/_a.c").exists())
                        (root/"lib/_a.c").write_text("new ABI")
                        (root/"lib/_gambit.c").write_text("new linker metadata")
                        for name in ("lib/libgambit.a", "gsi/gsi", "gsc/gsc"):
                            (root/name).write_text("new target")
                    return 0, "", False, 0.01

            self_outer = self
            with patch("gambit_smp.gambit_build_primitives.available_processors", return_value=2):
                ok, result = build_hosted_core(Stages(), root, 5)
            self.assertTrue(ok)
            self.assertEqual(calls, ["hosted-bootclean", "seed-core"])
            self.assertTrue(result["sourceRegenerationEstablished"])
            self.assertFalse(result["hostRuntimeLinkedIntoTarget"])
            self.assertFalse(result["fullTwoPassBootstrapEstablished"])
            self.assertEqual(result["missingGeneratedSources"], [])
            self.assertIn("lib/_gambit.c", result["generatedSources"])

    def test_cleanup_failure_does_not_enter_native_target_build(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("lib", "gsi", "gsc"):(root/name).mkdir()
            (root/"gsc/igsc.scm").write_text("source compiler")
            (root/"lib/_a.scm").write_text("scheme")
            (root/"lib/_a.c").write_text("old ABI")
            calls = []

            class Stages:
                def run(self, stage, *args, **kwargs):
                    calls.append(stage)
                    return 2, "cleanup failed", False, 0.01

            ok, result = build_hosted_core(Stages(), root, 5)
            self.assertFalse(ok)
            self.assertEqual(calls, ["hosted-bootclean"])
            self.assertEqual(result["remainingOldC"], ["lib/_a.c"])

    def test_host_must_be_an_explicit_declared_input(self):
        source = {"step": "configured", "output": "source"}
        validate_seed({"source": source}, [])
        with self.assertRaisesRegex(ValueError, "declared byte-bound bootstrap host"):
            validate_seed({"source": source, "bootstrapHost": "host.json"}, [])
        validate_seed({"source": source, "bootstrapHost": "host.json"}, ["host.json"])

    def test_failed_emission_cannot_erase_the_manifest_required_units(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("lib", "gsi", "gsc"):(root/name).mkdir()
            (root/"gsc/igsc.scm").write_text("current compiler")
            (root/"lib/_a.scm").write_text("source")
            required = ["lib/_a.c", "lib/_gambit.c"]

            class Stages:
                def run(self, stage, *args, **kwargs):
                    if stage == "seed-core":
                        for name in required + ["gsi/gsi", "gsc/gsc", "lib/libgambit.a"]:
                            (root/name).write_text("new product")
                    return 0, "", False, 0.01

            with patch("gambit_smp.gambit_build_primitives.available_processors", return_value=2):
                ok, result = build_hosted_core(Stages(), root, 5, required_generated=required)
            self.assertTrue(ok)
            self.assertEqual(result["generatedSources"], required)

    def test_compiled_host_is_the_boot_compiler_without_target_runtime_import(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("lib", "gsi", "gsc"):(root/name).mkdir()
            host = root/"qualified-host"
            host.write_text("complete current compiler with independent host ABI")
            (root/"gsc/igsc.scm").write_text("interpreted fallback must not be selected")
            required = ["lib/_a.c", "lib/_gambit.c"]

            class Stages:
                def run(self, stage, *args, **kwargs):
                    self_outer.assertEqual((root/"gsc-boot").read_bytes(), host.read_bytes())
                    if stage == "seed-core":
                        for name in required + ["gsi/gsi", "gsc/gsc", "lib/libgambit.a"]:
                            (root/name).write_text("fresh target product")
                    return 0, "", False, 0.01

            self_outer = self
            with patch("gambit_smp.gambit_build_primitives.available_processors", return_value=2):
                ok, result = build_hosted_core(Stages(), root, 5,
                    required_generated=required, bootstrap_compiler=host)
            self.assertTrue(ok)
            self.assertFalse(result["hostRuntimeLinkedIntoTarget"])
            self.assertFalse(result["fullTwoPassBootstrapEstablished"])
