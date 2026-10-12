from pathlib import Path
from io import StringIO
from contextlib import nullcontext
import json
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.bootstrap_runtime import generated_c, compiler_binding, build_errors, generated_stamp, main, apply_source_patch, repair_artifacts_rebuilt, archive_members, seed_source_binding
from gambit_smp.source_binding import gc_table_snapshot, ended_interrupt_source_hash, shared_pipe_source_hash, serialization_snapshot_source_hash, vector_increment_source_hash
from gambit_smp.framework import apply_untracked_patch, digest


SNAPSHOT_SOURCE = '''(define-prim (##gc-hash-table-snapshot gcht)
(let ((snapshot (##make-vector (##gc-hash-table-length gcht))))
memmove(___BODY_AS(___ARG2, ___tVECTOR), ___BODY_AS(___ARG1, ___tSUBTYPED),
___HD_WORDS(___HEADER(___ARG1)) * ___WS);
___RESULT = ___ARG2;
gcht snapshot)))
'''
for name in ("##gc-hash-table-for-each", "##gc-hash-table-search", "##gc-hash-table-foldl"):
    SNAPSHOT_SOURCE += f'''(define-prim ({name} proc gcht)
(let ((snapshot (##gc-hash-table-snapshot gcht)))
(##vector-ref snapshot i) (##vector-ref snapshot (##fx+ i 1))))
'''
SNAPSHOT_SOURCE += "(define-prim (next-procedure x) x)\n"


class BootstrapRuntimeTests(unittest.TestCase):
    def test_missing_seed_revision_requires_explicit_source_authority(self):
        with self.assertRaisesRegex(ValueError, "explicit versioned source lock"):
            seed_source_binding(Path("unused"), {"sourceFiles": {}})
        self.assertEqual(seed_source_binding(Path("unused"), {"sourceRevision": "old-bound-revision"}),
                         ("old-bound-revision", {}))

    def test_explicit_source_lock_rejects_candidate_and_revision_drift(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            runtime, source = root / "runtime", root / "source"
            for base in (runtime, source):
                (base / "lib").mkdir(parents=True)
                (base / "lib/mem.c").write_text("locked source\n")
            lock = root / "lock.json"
            revision = "f" * 40
            lock.write_text(json.dumps({"revision": revision,
                "files": {"lib/mem.c": {"candidateSha256": digest(source / "lib/mem.c")}}}))
            inputs = {"lock.json": digest(lock)}
            with patch("gambit_smp.bootstrap_runtime.ROOT", root), patch(
                    "gambit_smp.source_materialize.locked_source",
                    side_effect=lambda *args: nullcontext((source, inputs))):
                self.assertEqual(seed_source_binding(runtime, {}, lock), (revision, inputs))
                with self.assertRaisesRegex(ValueError, "revision conflicts"):
                    seed_source_binding(runtime, {"sourceRevision": "e" * 40}, lock)
                (runtime / "lib/mem.c").write_text("different candidate\n")
                with self.assertRaisesRegex(ValueError, "differs from locked candidate"):
                    seed_source_binding(runtime, {}, lock)

    def test_vector_delta_guard_patch_is_exact_and_rejects_source_drift(self):
        candidate = Path(__file__).resolve().parents[1] / "patches/candidates/vector-increment-type-guard.patch"
        lines = candidate.read_text().splitlines()[3:]
        body = "\n".join(line[1:] for line in lines if line.startswith((" ", "-"))) + "\n"
        original = ("      (define (make-ref-set!-cas!-inc!-expander type-check? kind)\n" + body
                    + "      ;; inline make-vect and ##make-vect\n").encode()
        expected = vector_increment_source_hash(original)
        with tempfile.TemporaryDirectory() as temporary:
            runtime = Path(temporary)
            (runtime / "gsc").mkdir()
            target = runtime / "gsc/_prims.scm"
            target.write_bytes(original)
            hashes, binding = apply_source_patch(runtime, {"sourceFiles": {"gsc/_prims.scm": digest(target)}},
                                                 candidate, "vector_increment_guard")
            self.assertEqual({"gsc/_prims.scm": expected}, hashes)
            self.assertTrue(binding["publicIncrementFixnumGuard"])
        for changed in (original + original, original.replace(b"(caddr vars)", b"(cadr vars)")):
            with self.assertRaises(ValueError):
                vector_increment_source_hash(changed)

    def test_compiler_only_repair_requires_new_compiler_not_changed_runtime(self):
        identity = {"gscSha256": "old", "binarySha256": "gsi", "librarySha256": "lib"}
        artifacts = {**identity, "gscSha256": "new"}
        self.assertTrue(repair_artifacts_rebuilt("vector_increment_guard", artifacts, identity, True, True))
        self.assertFalse(repair_artifacts_rebuilt("vector_increment_guard", artifacts, identity, False, True))
        self.assertFalse(repair_artifacts_rebuilt("vector_increment_guard", identity, identity, True, True))
        self.assertFalse(repair_artifacts_rebuilt("vector_increment_guard", artifacts, identity, True, False))
        self.assertFalse(repair_artifacts_rebuilt("vector_increment_guard", {**artifacts, "binarySha256": "changed"}, identity, True, True))
        self.assertTrue(repair_artifacts_rebuilt("vector_increment_guard", {**artifacts, "librarySha256": "new-container"}, identity, True, True))

    def test_archive_member_binding_rejects_duplicate_or_option_names(self):
        from types import SimpleNamespace
        for names in (b"a.o\na.o\n", b"-option\n", b"dir/a.o\n", b""):
            with patch("gambit_smp.bootstrap_runtime.subprocess.run", return_value=SimpleNamespace(stdout=names)):
                with self.assertRaises(ValueError):
                    archive_members(Path("archive.a"))
        with patch("gambit_smp.bootstrap_runtime.subprocess.run", side_effect=[SimpleNamespace(stdout=b"__.SYMDEF SORTED\na.o\nb.o\n"),
                       SimpleNamespace(stdout=b"first"), SimpleNamespace(stdout=b"second")]):
            members = archive_members(Path("archive.a"))
            self.assertEqual(["a.o", "b.o"], list(members))
            self.assertNotEqual(members["a.o"], members["b.o"])

    def test_serializer_delta_is_exact_and_rejects_live_cursor_or_helper_drift(self):
        patch = Path(__file__).resolve().parents[1] / "patches/candidates/gc-table-serialization-snapshot.patch"
        lines = patch.read_text().splitlines()[4:]
        old = "\n".join(line[1:] for line in lines if line.startswith((" ", "-"))) + "\n"
        original = (old + "\n(define-prim (##implode-gc-hash-table re fields) fields)\n" + SNAPSHOT_SOURCE).encode()
        expected = serialization_snapshot_source_hash(original)
        with tempfile.TemporaryDirectory() as temporary:
            runtime = Path(temporary)
            (runtime / "lib").mkdir()
            target = runtime / "lib/_system.scm"
            target.write_bytes(original)
            self.assertEqual({"lib/_system.scm": expected},
                apply_untracked_patch(runtime, patch.read_bytes(), {"lib/_system.scm"}))
            self.assertEqual(expected, digest(target))
        for changed in (original.replace(b"(##gc-hash-table-field-ref gcht i)", b"(other gcht i)"),
                        original.replace(b"___tSUBTYPED", b"___tVECTOR"), original + original):
            with self.assertRaises(ValueError):
                serialization_snapshot_source_hash(changed)

    def test_serializer_repair_requires_snapshot_proof_before_reading_runtime(self):
        argv = ["gambit_smp.bootstrap_runtime.py", "--runtime", "missing", "--toolchain-receipt", "missing",
                "--gcc", "missing", "--out", "unused", "--timeout", "1", "--target", "core",
                "--patch", "missing", "--model-receipt", "missing", "--patch-model", "gc_table_serialization"]
        with patch("sys.argv", argv), patch("sys.stderr", new_callable=StringIO) as stderr:
            with self.assertRaises(SystemExit) as result:
                main()
            self.assertEqual(2, result.exception.code)
            self.assertIn("companion proofs", stderr.getvalue())

    def test_pipe_repair_requires_companion_proof_before_reading_runtime(self):
        argv = ["gambit_smp.bootstrap_runtime.py", "--runtime", "missing", "--toolchain-receipt", "missing",
                "--gcc", "missing", "--out", "unused", "--timeout", "1", "--target", "core",
                "--patch", "missing", "--model-receipt", "missing", "--patch-model", "pipe_wait"]
        with patch("sys.argv", argv), patch("sys.stderr", new_callable=StringIO) as stderr:
            with self.assertRaises(SystemExit) as result:
                main()
            self.assertEqual(2, result.exception.code)
            self.assertIn("companion proofs", stderr.getvalue())
    def test_unknown_source_repair_does_not_fall_through_to_snapshot(self):
        with self.assertRaisesRegex(ValueError, "no audited binding"):
            apply_source_patch(Path("missing"), {}, Path("missing"), "unknown")
    def test_pipe_binding_requires_the_original_unique_constructor(self):
        original = (b"                 (whi2 (,macro-vect-port-whi port2)))\n"
                    b"             (,macro-vect-port-wbuf-set! port1 wbuf2)")
        self.assertEqual(64, len(shared_pipe_source_hash(original)))
        for changed in (original + original, original.replace(b"whi2", b"other", 1)):
            with self.assertRaises(ValueError):
                shared_pipe_source_hash(changed)
    def test_ended_target_binding_rejects_definition_or_branch_drift(self):
        source = (b"(define-prim (##thread-intr-propagate! interrupt)\n"
                  b"       (if (##not (macro-terminated-thread-given-initialized? thread))\n"
                  b"(body))\n(define-prim (next x) x)\n")
        self.assertEqual(64, len(ended_interrupt_source_hash(source)))
        for changed in (source.replace(b"(##not (macro-terminated", b"(other (macro-terminated"),
                        source.replace(b"\n(define-prim ", b"\n(unknown "), source + source):
            with self.assertRaises(ValueError):
                ended_interrupt_source_hash(changed)
    def test_lexical_snapshot_binding_rejects_wrong_tag_and_raw_cursor(self):
        self.assertEqual(gc_table_snapshot(SNAPSHOT_SOURCE)["bindingKind"], "lexical-not-semantic")
        with self.assertRaisesRegex(ValueError, "typed body copy"):
            gc_table_snapshot(SNAPSHOT_SOURCE.replace("___BODY_AS(___ARG1, ___tSUBTYPED)",
                                                     "___BODY_AS(___ARG1, ___tVECTOR)"))
        with self.assertRaisesRegex(ValueError, "rooted stable snapshot"):
            gc_table_snapshot(SNAPSHOT_SOURCE.replace("(##vector-ref snapshot i)",
                                                     "(##gc-hash-table-field-ref gcht i)", 1))

    def test_only_observed_non_git_empty_stamp_is_metadata(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "include").mkdir()
            path = root / "include/stamp.h"
            path.write_bytes(b"\n")
            message = "Gambit is not being built from a Git clone. Creating empty stamp.h."
            self.assertTrue(generated_stamp("include/stamp.h", root, message))
            self.assertFalse(generated_stamp("include/stamp.h", root, ""))
            self.assertFalse(generated_stamp("include/config.h", root, message))
            (root / ".git").mkdir()
            self.assertFalse(generated_stamp("include/stamp.h", root, message))
            (root / ".git").rmdir()
            path.write_bytes(b"#define UNRELATED 1\n")
            self.assertFalse(generated_stamp("include/stamp.h", root, message))

    def test_masked_recursive_error_is_rejected(self):
        for failure in ("make[3]: *** [_system.o] Error 1", "make: *** No rule to make target 'core'. Stop.",
                        "gcc: fatal error: input missing", "Segmentation fault: 11", "Bus error"):
            self.assertEqual(len(build_errors("compile\n" + failure + "\nmake finished\n")), 1)
        self.assertEqual(build_errors("warning: unused variable\n*** making phase1\n"), [])

    def test_generated_exception_is_narrow(self):
        for name in ("lib/_system.c", "gsi/_gsi.c", "gsc/_host.c"):
            self.assertTrue(generated_c(name))
        for name in ("lib/mem.c", "lib/_system.scm", "include/gambit.h", "lib/sub/_x.c", "../lib/_x.c"):
            self.assertFalse(generated_c(name))

    def test_compiler_binding_rejects_configuration_drift(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            compiler = root / "gcc"
            compiler.touch()
            for folder in ("lib", "gsi", "gsc"):
                (root / folder).mkdir()
                (root / folder / "Makefile").write_text(f"C_COMPILER = {compiler}\n")
            compiler_binding(root, compiler)
            (root / "gsc/Makefile").write_text("C_COMPILER = clang\n")
            with self.assertRaises(ValueError):
                compiler_binding(root, compiler)
