"""Compile and run standalone C23 Amp-1/Amp-2/Amp-4 prototypes under -O3, ASan+UBSan, and TSan."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tests/c23_amp_prototypes/test_amp_primitives.c"
HDR = ROOT / "tests/c23_amp_prototypes/amp_primitives.h"


def _select_clang() -> str | None:
    # On macOS, Apple Xcode /usr/bin/clang matches the native Darwin dyld ABI
    # for ASan and TSan runtimes (avoiding Nixpkgs compiler-rt dyld mismatches).
    if sys.platform == "darwin" and Path("/usr/bin/clang").is_file():
        return "/usr/bin/clang"
    return shutil.which("clang")


class C23AmpPrototypesTests(unittest.TestCase):
    def _compile_and_run(self, extra_flags: list[str], label: str):
        clang = _select_clang()
        self.assertIsNotNone(clang, "clang toolchain is required to verify C23 prototypes")
        with tempfile.TemporaryDirectory(prefix=f"amp_c23_{label}_") as tmpdir:
            out_bin = Path(tmpdir) / f"test_amp_{label}"
            cmd = [
                clang,
                "-std=c23",
                "-Wall",
                "-Wextra",
                "-Werror",
                "-pthread",
                *extra_flags,
                str(SRC),
                "-lm",
                "-o",
                str(out_bin),
            ]
            build = subprocess.run(cmd, capture_output=True, text=True, check=False, timeout=30)
            self.assertEqual(
                0,
                build.returncode,
                f"[{label}] clang build failed:\nSTDOUT:\n{build.stdout}\nSTDERR:\n{build.stderr}",
            )
            run = subprocess.run([str(out_bin)], capture_output=True, text=True, check=False, timeout=30)
            self.assertEqual(
                0,
                run.returncode,
                f"[{label}] prototype run failed:\nSTDOUT:\n{run.stdout}\nSTDERR:\n{run.stderr}",
            )
            self.assertIn("C23_AMP_PROTOTYPES_ALL_PASS", run.stdout)

    def test_c23_headers_exist(self):
        self.assertTrue(HDR.is_file())
        self.assertTrue(SRC.is_file())

    def test_c23_optimized_o3_hardware_run(self):
        self._compile_and_run(["-O3"], "o3")

    def test_c23_asan_ubsan_clean(self):
        self._compile_and_run(["-O1", "-g", "-fsanitize=address,undefined", "-fno-sanitize-recover=all"], "asan_ubsan")

    def test_c23_tsan_8thread_race_free(self):
        self._compile_and_run(["-O1", "-g", "-fsanitize=thread"], "tsan")


if __name__ == "__main__":
    unittest.main()
