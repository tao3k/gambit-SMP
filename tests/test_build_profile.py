import unittest
import json
from pathlib import Path
import tempfile
from unittest.mock import patch
from types import SimpleNamespace

from gambit_smp.build_profile import darwin_profile, read_profile
from gambit_smp.framework import ROOT
from gambit_smp.native_capabilities import validate_configure, configure


PROFILE = "evidence/fixtures/gerbil-bazel-build-profile/profile.json"


class BuildProfileTests(unittest.TestCase):
    def test_profile_executor_binds_input_and_uses_full_bazel_flags(self):
        calls, bound = [], []
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name).resolve()
        (root / PROFILE).parent.mkdir(parents=True)
        (root / PROFILE).write_bytes((ROOT / PROFILE).read_bytes())
        lock = root / "source.lock.json"
        lock.write_text('{}')
        gcc = root / "gcc"
        gcc.write_text('unit compiler identity; never executed')
        ctx = SimpleNamespace(root=root, tools={"autoconf": "autoconf", "sh": "sh", "gcc": str(gcc)}, env={},
            receipt={"steps": [{"id": "source", "arguments": {"sourceLock": "source.lock.json"}}]},
            remaining=lambda: 90,
            bind=lambda paths: bound.extend(paths),
            require=lambda name, argv, cwd, cap: calls.append((name, argv, cap)),
            publish=lambda *args: {})
        with patch("gambit_smp.native_capabilities.clone", return_value=ROOT), \
             patch("gambit_smp.native_capabilities.compiler"):
            result = configure({"source": {"step": "source", "output": "source"}, "buildProfile": PROFILE}, ctx)
        self.assertEqual([root / PROFILE], bound)
        self.assertEqual("-pipe", ctx.env["CFLAGS"])
        self.assertEqual(read_profile(ROOT / PROFILE), result["buildProfile"])
        self.assertEqual(["sh", "./configure", *result["buildProfile"]["flags"]], calls[-1][1])
        self.assertEqual(90, calls[-1][2])

    def test_pinned_bazel_profile_is_not_the_two_level_experiment(self):
        result = read_profile(ROOT / PROFILE)
        self.assertIn("--enable-c-opt=-O1", result["flags"])
        self.assertIn("--enable-c-opt-rts=yes", result["flags"])
        self.assertIn("--enable-inline-jumps", result["flags"])
        self.assertIn("--enable-single-host=0", result["flags"])
        self.assertEqual("-pipe", result["cflags"])
        self.assertEqual(["--enable-multiple-threaded-vms"], result["requiredGoalOverlay"])
        self.assertFalse(any("$" in word for word in result["flags"]))

    def test_drift_ambiguous_arrays_and_non_darwin_extensions_fail_closed(self):
        text = json.loads((ROOT / PROFILE).read_text())["sourceText"]
        for value in (text.replace("--enable-smp)", "--disable-smp)"),
                      text.replace("--enable-c-opt=-O1", "--enable-c-opt=$(evil)"),
                      text + '\nargs+=(--enable-smp)\n',
                      text.replace('export GERBIL_BUILD_AOT_TOOLS=yes', 'export DIFFERENT=yes'),
                      text.replace('export CFLAGS="-pipe${CFLAGS:+ $CFLAGS}"', 'export CFLAGS=-O0')):
            with self.subTest(value=value[-20:]), self.assertRaises(ValueError):
                darwin_profile(value)

    def test_profile_must_be_declared_and_cannot_mix_diagnostic_levels(self):
        args = {"source": {"step": "source", "output": "source"}, "buildProfile": PROFILE}
        validate_configure(args, [PROFILE])
        with self.assertRaises(ValueError):
            validate_configure(args, [])
        with self.assertRaises(ValueError):
            validate_configure(dict(args, cOptimization=0, rtsOptimization=0), [PROFILE])
