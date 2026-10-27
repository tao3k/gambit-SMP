import hashlib
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

from gambit_smp.revision_submission import RevisionSubmission
from gambit_smp.task_processes import run


class RevisionSubmissionTests(unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.git("init", "-q", "-b", "modern-c")
        for name in ("a.c", "b.c"):
            (self.repo / name).write_text("base\n")
        self.git("add", ".")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "commit", "-qm", "base")
        self.head = self.git("rev-parse", "HEAD").decode().strip()
        self.workspace = self.root / "build"
        self.workspace.mkdir()
        (self.workspace / "a.c").write_text("selected\n")
        (self.workspace / "b.c").write_text("base\n")
        (self.workspace / "runtime").write_text("completed artifact\n")
        self.profile = self.root / "profile.json"
        self.profile.write_text(json.dumps({"standard": "c23"}))
        (self.repo / "b.c").write_text("unrelated staged work\n")
        self.git("add", "b.c")
        self.native = dict(complete=True, baseRevision=self.head,
                           canonicalSources={name: self.sha(self.workspace / name)
                                             for name in ("a.c", "b.c")},
                           artifacts={"runtime": self.sha(self.workspace / "runtime")})

    def git(self, *arguments):
        result = run(["git", "-C", str(self.repo), *arguments], capture_output=True,
                     timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    @staticmethod
    def sha(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def submission(self):
        return RevisionSubmission(self.root, self.repo, self.workspace,
                                  self.root / "submission", self.root / "evidence",
                                  self.native)

    def test_exact_tree_excludes_unrelated_staged_content(self):
        before = self.git("ls-files", "--stage", "-z")
        submission = self.submission()
        source = submission.prepare(["a.c"], self.profile)
        self.assertEqual(self.git("show", source["tree"] + ":a.c"), b"selected\n")
        self.assertEqual(self.git("show", source["tree"] + ":b.c"), b"base\n")
        self.assertEqual(self.git("ls-files", "--stage", "-z"), before)
        self.assertEqual((self.repo / "b.c").read_text(), "unrelated staged work\n")

    def test_an_undeclared_native_delta_cannot_enter_a_smaller_cut(self):
        (self.workspace / "b.c").write_text("another native delta\n")
        self.native["canonicalSources"]["b.c"] = self.sha(self.workspace / "b.c")
        with self.assertRaisesRegex(ValueError, "untested canonical input"):
            self.submission().prepare(["a.c"], self.profile)

    def test_incomplete_native_work_never_prepares_a_commit(self):
        self.native["complete"] = False
        with self.assertRaisesRegex(ValueError, "completed native"):
            self.submission()
        self.assertEqual(self.git("rev-parse", "HEAD").decode().strip(), self.head)

    def test_concurrent_staging_blocks_without_overwriting_it(self):
        submission = self.submission()
        submission.prepare(["a.c"], self.profile)
        submission.model_inputs = {}
        (self.repo / "b.c").write_text("concurrent work\n")
        self.git("add", "b.c")
        with self.assertRaisesRegex(ValueError, "concurrent staging"):
            submission.check_custody()
        self.assertEqual(self.git("show", ":b.c"), b"concurrent work\n")

    def test_late_native_mutation_blocks_submission(self):
        submission = self.submission()
        submission.prepare(["a.c"], self.profile)
        submission.model_inputs = {}
        (self.workspace / "runtime").write_text("different artifact\n")
        with self.assertRaisesRegex(ValueError, "native source/artifact drift"):
            submission.check_custody()

    def test_generated_product_is_exact_and_drift_blocks_submission(self):
        generated = "gsc/_sample.c"
        (self.workspace / "gsc").mkdir()
        (self.workspace / generated).write_text("generated  \n")
        self.native["generatedArtifacts"] = {
            generated: self.sha(self.workspace / generated)}
        submission = self.submission()
        source = submission.prepare(["a.c", generated], self.profile)
        self.assertEqual(self.git("show", source["tree"] + ":" + generated),
                         b"generated  \n")
        submission.model_inputs = {}
        (self.workspace / generated).write_text("manually edited\n")
        with self.assertRaisesRegex(ValueError, "native source/artifact drift"):
            submission.check_custody()

    def test_declared_generated_output_does_not_exempt_handwritten_whitespace(self):
        generated = "gsc/_sample.c"
        (self.workspace / "gsc").mkdir()
        (self.workspace / generated).write_text("generated  \n")
        (self.workspace / "a.c").write_text("handwritten  \n")
        self.native["canonicalSources"]["a.c"] = self.sha(self.workspace / "a.c")
        self.native["generatedArtifacts"] = {
            generated: self.sha(self.workspace / generated)}
        with self.assertRaises(ValueError):
            self.submission().prepare(["a.c", generated], self.profile)

    def test_caller_boolean_cannot_replace_actual_ascent_admission(self):
        submission = self.submission()
        source = submission.prepare(["a.c"], self.profile)
        with self.assertRaisesRegex(ValueError, "matching ASCENT"):
            submission.commit("not admitted\n", dict(commitAdmitted=True, tree=source["tree"]))
        self.assertEqual(self.git("rev-parse", "HEAD").decode().strip(), self.head)

    def test_admission_keeps_rules_in_source_and_audit_observations_in_data(self):
        # Transport regression only. The real source-bound ASCENT run separately
        # checks inference; this mock cannot establish an admitted native REV.
        submission = self.submission()
        submission.prepare(["a.c"], self.profile)
        submission.model_inputs = {}
        submission.need_names = ["native", "audit"]
        submission.values = {}
        for name, gate, method in (("native", "tests", "native"),
                                   ("audit", "learning", "source-analysis")):
            artifact = name + ".json"
            (self.root / artifact).write_text(json.dumps({"complete": True}))
            for key, value in {"id": name, "gate.id": gate, "method": method,
                               "artifact": artifact, "scope": 'literal "quoted" scope'}.items():
                submission.values[name + "." + key] = value
        for gate in ("tests", "learning", "process", "models", "questions"):
            submission.values["gate." + gate + ".id"] = gate
            submission.values["gate." + gate + ".purpose"] = gate
        directory = self.root / "dev/modeling/ascent"
        directory.mkdir(parents=True)
        maintained = Path(__file__).resolve().parents[1] / "dev/modeling/ascent"
        for name in ("commit-context.rules.scm", "commit-admission.rules.scm"):
            (directory / name).write_bytes((maintained / name).read_bytes())
        (submission.storage / "sysml.stdout").write_text("native model receipt")

        def observe(facts, catalog, queries, **kwargs):
            self.assertEqual(set(catalog["sourceInputs"]), {str((directory / name).resolve()) for name in
                ("commit-context.rules.scm", "commit-admission.rules.scm")})
            for name, text in zip(("commit-context.rules.scm", "commit-admission.rules.scm"),
                                  catalog["sourceTexts"]):
                self.assertEqual(text, "(ascent-fragment\n"+(directory/name).read_text()+"\n)")
            for need in ("native", "audit"):
                scenario = "missing-obligation:" + need
                self.assertIn([scenario], facts["controlExpectBlockedFact"])
                self.assertFalse(any(row[0] == scenario and row[5] == need
                                     for row in facts["commitObservationFact"]))
            self.assertTrue(any(row[9] == 'literal "quoted" scope'
                                for row in facts["commitObservationFact"]))
            answers = dict(commitReady=[["current"]], controlFailure=[],
                commitCovered=[["current", name] for name in ("native", "audit")],
                commitGateReady=[["current", gate] for gate in
                    ("tests", "learning", "process", "models", "questions")])
            return answers

        with patch("gambit_smp.ascent_program.query", side_effect=observe):
            admission = submission.admit()
        self.assertEqual(admission["negativeControls"], 7)
        self.assertFalse((submission.evidence / "query.ss").exists())
        (directory / "commit-context.rules.scm").write_text("changed policy schema")
        with self.assertRaisesRegex(ValueError, "admission artifact changed"):
            submission.commit("must not commit changed rules\n", admission)
        self.assertEqual(self.git("rev-parse", "HEAD").decode().strip(), self.head)

    def test_path_escape_is_rejected_before_reading_workspace_data(self):
        with self.assertRaisesRegex(ValueError, "repository-relative"):
            self.submission().prepare(["../outside"], self.profile)

    def test_qualified_merge_retains_both_parents_and_pending_index(self):
        tree = self.git("rev-parse", "HEAD^{tree}").decode().strip()
        other = self.git("commit-tree", tree, "-p", self.head,
                         "-m", "upstream").decode().strip()
        self.native["mergeParent"] = other
        self.native["targetTree"] = tree
        before = self.git("ls-files", "--stage", "-z")
        submission = self.submission()
        source = submission.prepare(["a.c"], self.profile)
        submission.model_inputs = {}
        # Isolate Git publication here; actual ASCENT rejection controls are
        # exercised by the source-bound native delivery, not simulated by Git.
        submission.admission = dict(commitAdmitted=True, tree=source["tree"],
                                    artifacts={})
        revision = submission.commit("qualified merge\n", submission.admission)
        parents = self.git("show", "-s", "--format=%P", revision["revision"]).decode().split()
        self.assertEqual(parents, [self.head, other])
        self.assertEqual(self.git("ls-files", "--stage", "-z"), before)
        self.assertEqual((self.repo / "b.c").read_text(), "unrelated staged work\n")

    def test_incoming_delta_preserves_pending_source_in_both_views(self):
        original = "one\ntwo\nthree\nfour\nfive\nsix\n"
        (self.repo / "a.c").write_text(original)
        self.git("add", "a.c")
        self.git("commit", "-qm", "source baseline", "--only", "a.c")
        self.native["baseRevision"] = self.git("rev-parse", "HEAD").decode().strip()
        (self.repo / "a.c").write_text(original + "pending\n")
        self.git("add", "a.c")
        incoming = original.replace("one\n", "ONE\n")
        (self.workspace / "a.c").write_text(incoming)
        self.native["canonicalSources"]["a.c"] = self.sha(self.workspace / "a.c")
        submission = self.submission()
        submission.stage_qualified_changes(["a.c"])
        self.assertEqual((self.repo / "a.c").read_text(), incoming + "pending\n")
        self.assertEqual(self.git("show", ":a.c").decode(), incoming + "pending\n")
        source = submission.prepare(["a.c"], self.profile)
        self.assertEqual(self.git("show", source["tree"] + ":a.c").decode(), incoming)
        self.assertEqual(self.git("show", ":b.c"), b"unrelated staged work\n")

    def test_incoming_conflict_never_mutates_the_real_views(self):
        (self.repo / "a.c").write_text("pending rewrite\n")
        before = self.git("ls-files", "--stage", "-z")
        with self.assertRaisesRegex(ValueError, "pending source merge conflict"):
            self.submission().stage_qualified_changes(["a.c"])
        self.assertEqual(self.git("ls-files", "--stage", "-z"), before)
        self.assertEqual((self.repo / "a.c").read_text(), "pending rewrite\n")

    def test_incoming_generated_blob_preserves_pending_raw_work(self):
        name = "gsc/_sample.c"
        (self.workspace / "gsc").mkdir()
        (self.repo / "gsc").mkdir()
        (self.workspace / name).write_text("qualified\n")
        (self.repo / name).write_text("pending feature product\n")
        self.native["generatedArtifacts"] = {name: self.sha(self.workspace / name)}
        self.submission().stage_qualified_changes([name])
        self.assertEqual(self.git("show", ":" + name), b"qualified\n")
        self.assertEqual((self.repo / name).read_text(), "pending feature product\n")

    def test_source_editor_plan_is_read_only_until_exact_edits_are_applied(self):
        before = self.git("ls-files", "--stage", "-z")
        submission = self.submission()
        plan = submission.stage_qualified_changes(["a.c"], plan_only=True)
        self.assertEqual((self.repo / "a.c").read_text(), "base\n")
        self.assertEqual(self.git("ls-files", "--stage", "-z"), before)
        with self.assertRaisesRegex(ValueError, "source editor result drift"):
            submission.apply_staging_plan(plan)
        self.assertEqual(self.git("ls-files", "--stage", "-z"), before)
        (self.repo / "a.c").write_text("selected\n")
        submission.apply_staging_plan(plan)
        self.assertEqual(self.git("show", ":a.c"), b"selected\n")
        self.assertEqual(self.git("show", ":b.c"), b"unrelated staged work\n")
