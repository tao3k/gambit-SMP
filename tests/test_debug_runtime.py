from pathlib import Path
import ast
import unittest

from gambit_smp.debug_runtime import admitted_capture, capture_command


class DebugRuntimeTests(unittest.TestCase):
    def test_hidden_debugger_failure_is_denied(self):
        for output in ("", "Traceback (most recent call last):\nAssertionError: launch failed",
                       "DIAGNOSTIC-STATE 5 STOP-ID 2 INITIAL 1\nAssertionError: bad"):
            with self.assertRaises(ValueError):
                admitted_capture(output)
        self.assertTrue(admitted_capture("DIAGNOSTIC-STATE 5 STOP-ID 2 INITIAL 1")["diagnosticOnly"])

    def test_compiler_capture_uses_real_executable_compile_path(self):
        args = (Path("gsc"), Path("runtime"), Path("fixture.scm"), Path("out"), 8, 10)
        compiler = " ".join(capture_command(*args, compile_fixture=True))
        interpreter = " ".join(capture_command(*args))
        self.assertIn("-exe", compiler)
        self.assertIn("native-regression", compiler)
        self.assertNotIn("-exe", interpreter)

    def test_gc_state_capture_can_recover_vm_from_processor(self):
        command = " ".join(capture_command(Path("gsc"), Path("runtime"),
                          Path("fixture.scm"), Path("out"), 8, 10, True))
        for token in ("GetChildMemberWithName('vmstate')", "scan_workers_count_",
                      "nb_gcs_", "SCAN-WORKERS", "heap_chunks_to_scan_head_"):
            self.assertIn(token, command)

    def test_repeated_capture_is_same_process_and_valid_python(self):
        argv = capture_command(Path("gsc"), Path("runtime"), Path("fixture.scm"),
                               Path("out"), 8, 5, True, 2)
        script = next(arg for arg in argv if arg.startswith("script exec("))
        call = ast.parse(script[len("script "):]).body[0].value
        body = ast.literal_eval(call.args[0])
        ast.parse(body)
        self.assertEqual(1, body.count(".Launch(info,error)"))
        self.assertIn("for sample in range(2):", body)
        rows = "DIAGNOSTIC-STATE 5 STOP-ID 2 INITIAL 1\nDIAGNOSTIC-STATE 5 STOP-ID 4 INITIAL 2"
        self.assertEqual(2, len(admitted_capture(rows, 2)["observations"]))
        with self.assertRaises(ValueError):
            admitted_capture(rows.splitlines()[0], 2)
        with self.assertRaises(ValueError):
            admitted_capture(rows)
