"""Proposed flag scope, not compiler correctness or performance admission."""
import itertools
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from gambit_smp.framework import ROOT, apply_untracked_patch, digest


class DarwinDynamicModuloScopeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.tree = Path(cls.temporary.name)
        parent = json.loads((ROOT / "evidence/fixtures/fdset-abort-owned-rollback/source.lock.json").read_text())
        candidate = json.loads((ROOT / "evidence/fixtures/darwin-dynamic-modulo-scope/source.lock.json").read_text())
        if set(parent["files"]) != set(candidate["files"]) or parent["revision"] != candidate["revision"]:
            raise AssertionError("candidate must retain the exact predecessor source slice")
        base = {}
        for name, row in parent["files"].items():
            base[name] = subprocess.check_output(
                ["git", "-C", str(ROOT / "vendor/gambit"), "show", parent["revision"] + ":" + name], timeout=10)
            target = cls.tree / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(base[name])
        parent_patch = ROOT / parent["patch"]
        if digest(parent_patch) != parent["patchSha256"]:
            raise AssertionError("predecessor patch drift")
        apply_untracked_patch(cls.tree, parent_patch.read_bytes(), set(base))
        cls.parent_configure = (cls.tree / "configure.ac").read_text()
        for name, row in parent["files"].items():
            if digest(cls.tree / name) != row["candidateSha256"]:
                raise AssertionError("predecessor source mismatch: " + name)
            (cls.tree / name).write_bytes(base[name])
        candidate_patch = ROOT / candidate["patch"]
        if digest(candidate_patch) != candidate["patchSha256"]:
            raise AssertionError("candidate patch drift")
        apply_untracked_patch(cls.tree, candidate_patch.read_bytes(), set(base))
        for name, row in candidate["files"].items():
            if digest(cls.tree / name) != row["candidateSha256"]:
                raise AssertionError("candidate source mismatch: " + name)
            if name != "configure.ac" and row != parent["files"][name]:
                raise AssertionError("unrelated candidate source change: " + name)
        cls.candidate_configure = (cls.tree / "configure.ac").read_text()
        anchor = 'FLAGS_DYN="$FLAGS_DYN $FLAGS_OBJ_DYN $FLAGS_OBJ_DYN_LIB_EXE $FLAGS_DYN_LIB"\n'
        before, after = cls.parent_configure.split(anchor)
        if not cls.candidate_configure.startswith(before + anchor) or not cls.candidate_configure.endswith(after):
            raise AssertionError("candidate changed more than the final dynamic flag insertion")
        cls.block = cls.candidate_configure[len(before + anchor):-len(after)]

    def test_source_delta_is_one_scoped_insertion(self):
        self.assertEqual(1, self.block.count("FLAGS_DYN="))
        self.assertNotIn("FLAGS_OBJ=", self.block)
        self.assertNotIn("FLAGS_LIB=", self.block)
        self.assertNotIn("FLAGS_EXE=", self.block)
        self.assertNotIn("schedule-insns2", self.block)
        self.assertNotIn("-O", self.block)

    def test_actual_shell_guard_matches_platform_compiler_and_capability_matrix(self):
        for host, compiler, opt, supported in itertools.product(
                ("darwin25", "linux-gnu", "mingw32"), ("gnu", "clang", "llvm"), (False, True), (False, True)):
            with self.subTest(host=host, compiler=compiler, opt=opt, supported=supported):
                env = {**os.environ, "target_os": host, "C_COMP_GNUC": "yes",
                       "C_COMP_CLANG": "yes" if compiler == "clang" else "no",
                       "C_COMP_LLVM": "yes" if compiler == "llvm" else "no",
                       "ENABLE_GCC_OPTS": "yes" if opt else "no",
                       "DASH_fmodulo_sched": " -fmodulo-sched" if supported else "",
                       "DASH_freschedule_modulo_scheduled_loops": " -freschedule-modulo-scheduled-loops" if supported else "",
                       "FLAGS_DYN": "dynamic", "FLAGS_OBJ": "rts-O3",
                       "FLAGS_LIB": "library", "FLAGS_EXE": "executable"}
                result = subprocess.run(["/bin/sh", "-c", self.block +
                    'printf "%s\\n" "$FLAGS_DYN" "$FLAGS_OBJ" "$FLAGS_LIB" "$FLAGS_EXE"'],
                    env=env, capture_output=True, text=True, check=True, timeout=5)
                expected = "dynamic"
                if host.startswith("darwin") and compiler == "gnu" and opt and supported:
                    expected += " -fno-modulo-sched -fno-reschedule-modulo-scheduled-loops"
                self.assertEqual([expected, "rts-O3", "library", "executable"], result.stdout.splitlines())
                self.assertEqual("", result.stderr)
