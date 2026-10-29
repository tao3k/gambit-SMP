import hashlib
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

from gambit_smp.revision_submission import RevisionSubmission
from gambit_smp.task_processes import run


class RevisionSubmissionFixture(unittest.TestCase):
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

    def audit(self, submission):
        # Transport fixture only; real native SysML projection is qualified
        # separately. No fixture claim establishes a runtime admission.
        submission.values.update({"comment.allRevisions": True,
            "comment.commitUnitRequired": True,
            "comment.supportSurfaces": "tests/",
            "comment.supportFiles": "a.c;gsc/_sample.c",
            "unit.kind": "support", "unit.result": "", "unit.progressDelta": 0,
            "unit.supportPaths": "a.c;gsc/_sample.c",
            "comment.fields": "responsibility,retired,validation,benefits,costs,process,checklist,models,open",
            "comment.matrixRequired": True,
            "comment.matrixFields": "id,kind,metric,unit,direction,baseline,candidate,workload,method,evidence,limitation",
            "comment.matrixKinds": "measurement,control,accounted-cost,structural,unmeasured"})
        checklist = self.root / "dev/revision-checklist.org"
        checklist.parent.mkdir(exist_ok=True)
        checklist.write_text("#+TITLE: Transport fixture\n* Selected cut\n:PROPERTIES:\n:CUSTOM_ID: selected-cut\n:END:\n")
        matrix = {"rows": [dict(id="runtime", kind="unmeasured", metric="Runtime throughput",
            unit="ops/s", direction="none", baseline=None, candidate=None,
            workload="No runtime is launched by this transport fixture", method="not measured",
            evidence=["dev/revision-checklist.org"], limitation="No speedup claim")]}
        return dict(matrix=matrix, responsibility="Select a.c without unrelated b.c.",
                    retired="Shared-index publication for this selected cut.",
                    validation="Git fixture: selected bytes and both merge parents verified; no runtime test claimed.",
                    benefits="Measured by this fixture: unrelated staged bytes remain unchanged.",
                    costs="One bounded alternate index and reviewed comment artifact.",
                    process="Publication transport test; runtime refactoring remains outside this fixture.",
                    checklist="dev/revision-checklist.org#selected-cut",
                    models="Mock projection only; no QNT/Lean or native proof claimed.",
                    open="Whole-runtime correctness remains outside this transport fixture.")

class RevisionSubmissionTests(RevisionSubmissionFixture):

    def test_cumulative_cut_does_not_trust_last_sync_path_list(self):
        import os
        environment = dict(os.environ, GIT_INDEX_FILE=str(self.root / "producer.index"))

        def producer(*arguments):
            result = run(["git", "-C", str(self.repo), *arguments], env=environment,
                         capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout.decode().strip()

        producer("read-tree", self.head)
        blob = producer("hash-object", "-w", str(self.workspace / "a.c"))
        producer("update-index", "--cacheinfo", "100644," + blob + ",a.c")
        self.native.update(targetTree=producer("write-tree"), sourcePaths=[])
        submission = self.submission()
        self.assertEqual(submission.qualified_paths(), ["a.c"])
        submission.prepare(submission.qualified_paths(), self.profile)
        self.assertEqual(self.git("show", submission.tree + ":a.c"), b"selected\n")
        self.assertEqual(self.git("show", submission.tree + ":b.c"), b"base\n")

    def test_reviewed_manifest_keeps_full_inventory_in_execution_custody(self):
        submission = self.submission()
        submission.prepare(["a.c"], self.profile)
        full = json.loads((submission.storage / "source-manifest.json").read_text())
        reviewed = json.loads((submission.evidence / "source-manifest.json").read_text())
        self.assertEqual(set(full["files"]), {"a.c", "b.c"})
        self.assertEqual(set(reviewed["selected"]), {"a.c"})
        self.assertEqual(reviewed["fullManifestSha256"],
                         self.sha(submission.storage / "source-manifest.json"))
        self.assertEqual(reviewed["fileCount"], 2)
        self.assertEqual(reviewed["tree"], submission.tree)
        self.assertTrue(reviewed["canonicalInputEquivalence"])

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
        submission.prepare_audit(self.audit(submission))
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
                commitUnitReady=[["current"]], commitUnitGap=[], commitProgressReady=[],
                commitCovered=[["current", name] for name in ("native", "audit")],
                commitGateReady=[["current", gate] for gate in
                    ("tests", "learning", "process", "models", "questions")])
            return answers

        with patch("gambit_smp.ascent_program.query", side_effect=observe):
            admission = submission.admit()
        self.assertEqual(admission["negativeControls"], 26)
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
        submission.values = {}
        audit_digest = submission.prepare_audit(self.audit(submission))
        # Isolate Git publication here; actual ASCENT rejection controls are
        # exercised by the source-bound native delivery, not simulated by Git.
        submission.admission = dict(commitAdmitted=True, tree=source["tree"],
                                    artifacts={}, auditSha256=audit_digest)
        revision = submission.commit("qualified merge\n", submission.admission)
        parents = self.git("show", "-s", "--format=%P", revision["revision"]).decode().split()
        self.assertEqual(parents, [self.head, other])
        self.assertEqual(self.git("ls-files", "--stage", "-z"), before)
        self.assertEqual((self.repo / "b.c").read_text(), "unrelated staged work\n")
        message = self.git("show", "-s", "--format=%B", revision["revision"]).decode()
        for label in ("REV audit", "Validation:", "Benefits:", "Costs:", "Checklist:", "Open:", "REV benefit/cost matrix", "Matrix-SHA256:"):
            self.assertIn(label, message)
        self.assertIn("Tree: " + source["tree"], message)
        from gambit_smp.revision_matrix import render_matrix
        reviewed = json.loads(submission.audit_path.read_text())["matrix"]
        self.assertIn(render_matrix(reviewed), message)

    def test_actual_commit_contains_reviewed_numeric_matrix(self):
        submission = self.submission()
        source = submission.prepare(["a.c"], self.profile)
        submission.model_inputs = {}
        submission.values = {}
        report = self.audit(submission)
        quantities = dict(baseRevision=source["baseRevision"], sourceTree=source["tree"],
                          profileSha256=source["profileSha256"])
        raw = dict(quantities, before=dict(value=20, unit="s", samples=1),
                   after=dict(value=25, unit="s", samples=1))
        (self.root / "raw.json").write_text(json.dumps(raw))
        for name in ("before", "after"):
            quantities[name] = dict(raw[name], origin=dict(path="raw.json", pointer="/" + name))
        (self.root / "quantities.json").write_text(json.dumps(quantities))
        row = report["matrix"]["rows"][0]
        row.update(id="elapsed", kind="measurement", metric="Elapsed time", unit="s",
                   direction="lower", baseline=dict(path="quantities.json", pointer="/before"),
                   candidate=dict(path="quantities.json", pointer="/after"),
                   workload="Synthetic transport quantities; no runtime benchmark",
                   method="Exact commit-body transport control", evidence=["quantities.json"],
                   limitation="Not a Gambit performance observation")
        audit_digest = submission.prepare_audit(report)
        # The native policy is exercised separately; this is actual Git transport.
        submission.admission = dict(commitAdmitted=True, tree=source["tree"],
                                    artifacts={}, auditSha256=audit_digest)
        revision = submission.commit("audit matrix transport\n", submission.admission)
        message = self.git("show", "-s", "--format=%B", revision["revision"]).decode()
        from gambit_smp.revision_matrix import render_matrix
        reviewed = json.loads(submission.audit_path.read_text())["matrix"]
        self.assertIn(render_matrix(reviewed), message)
        self.assertIn("observed-regression", message)
        self.assertIn("| 20 | 25 | s | 1/1 | 25.00 |", message)
        self.assertIn("Matrix-SHA256:", message)

    def test_missing_or_empty_comment_field_blocks_every_size_of_rev(self):
        submission = self.submission()
        submission.prepare(["a.c"], self.profile)
        submission.values = {}
        report = self.audit(submission)
        for field in (x for x in report if x != "matrix"):
            with self.subTest(field=field):
                missing = dict(report)
                del missing[field]
                with self.assertRaisesRegex(ValueError, "every model-required field"):
                    submission.prepare_audit(missing)
                empty = dict(report, **{field: "  "})
                with self.assertRaisesRegex(ValueError, "explicit review text"):
                    submission.prepare_audit(empty)
        self.assertEqual(self.git("rev-parse", "HEAD").decode().strip(), self.head)

    def test_ordinary_rev_publishes_reviewed_comment_without_staging_other_work(self):
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        before = self.git("ls-files", "--stage", "-z")
        submission = self.submission()
        source = submission.prepare(["a.c"], self.profile)
        submission.model_inputs = {}
        submission.values = {}
        audit_digest = submission.prepare_audit(self.audit(submission))
        submission.admission = dict(commitAdmitted=True, tree=source["tree"],
                                    artifacts={}, auditSha256=audit_digest)
        revision = submission.commit("test: selected small REV\n", submission.admission)
        message = self.git("show", "-s", "--format=%B", revision["revision"]).decode()
        self.assertIn("Audit-SHA256: " + audit_digest, message)
        self.assertIn("Validation:\nGit fixture:", message)
        self.assertIn("Benefits:\nMeasured by this fixture:", message)
        self.assertIn("Checklist:\ndev/revision-checklist.org#selected-cut", message)
        self.assertEqual(self.git("ls-files", "--stage", "-z"), before)

    def test_cache_checklist_and_small_revision_exemption_are_rejected(self):
        submission = self.submission()
        submission.prepare(["a.c"], self.profile)
        submission.values = {}
        report = self.audit(submission)
        with self.assertRaisesRegex(ValueError, "repository Org checklist"):
            submission.prepare_audit(dict(report, checklist=".cache/checklist.org"))
        with self.assertRaisesRegex(ValueError, "real Org ID anchor"):
            submission.prepare_audit(dict(report, checklist="dev/revision-checklist.org#missing"))
        submission.values["comment.allRevisions"] = False
        with self.assertRaisesRegex(ValueError, "every REV"):
            submission.prepare_audit(report)

    def test_reviewed_comment_cannot_change_after_admission(self):
        submission = self.submission()
        source = submission.prepare(["a.c"], self.profile)
        submission.model_inputs = {}
        submission.values = {}
        audit_digest = submission.prepare_audit(self.audit(submission))
        submission.admission = dict(commitAdmitted=True, tree=source["tree"],
                                    artifacts={}, auditSha256=audit_digest)
        report = json.loads(submission.audit_path.read_text())
        report["fields"]["benefits"] = "Unreviewed claim."
        submission.audit_path.write_text(json.dumps(report))
        with self.assertRaisesRegex(ValueError, "audit changed after admission"):
            submission.commit("small correction\n", submission.admission)
        self.assertEqual(self.git("rev-parse", "HEAD").decode().strip(), self.head)

    def test_no_comment_report_cannot_enter_ascent_admission(self):
        submission = self.submission()
        submission.prepare(["a.c"], self.profile)
        with self.assertRaisesRegex(ValueError, "audit required before ASCENT"):
            submission.admit()

    def test_checklist_cannot_change_after_review(self):
        submission = self.submission()
        submission.prepare(["a.c"], self.profile)
        submission.values = {}
        report = self.audit(submission)
        audit_digest = submission.prepare_audit(report)
        (self.root / report["checklist"].split("#")[0]).write_text("changed checklist\n")
        with self.assertRaisesRegex(ValueError, "checklist changed after audit"):
            submission.audit_comment(audit_digest)

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


class CompleteDeliveryTests(RevisionSubmissionFixture):
    """Real Git/ASCENT transport controls, never native Gambit acceptance."""

    def integration(self):
        (self.workspace / 'a.c').write_text('base\n')
        self.native['canonicalSources']['a.c'] = self.sha(self.workspace / 'a.c')
        (self.workspace / 'lib').mkdir()
        (self.workspace / 'lib/gc.c').write_text('selected runtime replacement\n')
        self.native['canonicalSources']['lib/gc.c'] = self.sha(self.workspace / 'lib/gc.c')
        sub = self.submission()
        sub.prepare(['lib/gc.c'], self.profile)
        sub.values = {}
        report = self.audit(sub)
        sub.values.update({'unit.kind': 'integration', 'unit.result': 'owned-lifetime',
                           'unit.progressDelta': 1, 'unit.supportPaths': '',
                           'unit.sourceCases': 'ownership', 'unit.requiredCases': 'unknown-join'})
        obligations = {
            'frozen-roots': ['ROOT-SOURCE-UNION', 'ROOT-NATIVE-UNION', 'ROOT-CONSUMERS'],
            'independent-collector': ['COPY-PHYSICAL', 'WORKER-RESTORE', 'COLLECTOR-CONSUMERS'],
            'owned-lifetime': ['MEMBER-OWNERSHIP', 'RETIREMENT-EFFECTS', 'LIFETIME-CONSUMERS']}
        for target, names in obligations.items():
            for name in names:
                prefix = 'resultNeed.' + name
                sub.values[prefix + '.id'] = name
                sub.values[prefix + '.result.id'] = target
        for number, (before, after) in enumerate([('frozen-roots', 'independent-collector'),
                                                ('independent-collector', 'owned-lifetime')]):
            prefix = 'resultEdge.edge' + str(number)
            sub.values[prefix + '.predecessor.id'] = before
            sub.values[prefix + '.successor.id'] = after
        requirements = [x for xs in obligations.values() for x in xs] + ['source:ownership', 'native:unknown-join']
        receipt = dict(complete=True, sourceTree=sub.tree, baseRevision=sub.base,
                       profileSha256=sub.source['profileSha256'], result='owned-lifetime',
                       requirements=requirements, scope='Synthetic framework transport only')
        (self.root / 'receipt.json').write_text(json.dumps(receipt))
        packet = dict(receipt, observations=[dict(requirement=x, artifact='receipt.json',
            sha256=self.sha(self.root / 'receipt.json'), status='pass') for x in requirements])
        (self.root / 'delivery.json').write_text(json.dumps(packet))
        sub.native['deliveryEvidence'] = 'delivery.json'
        sub.model_inputs = {}
        return sub, report

    def real_policy(self, sub):
        sub.need_names = []
        for gate in ('tests', 'learning', 'process', 'models', 'questions'):
            name = 'need_' + gate
            sub.need_names.append(name)
            for key, value in {'id': name, 'gate.id': gate,
                               'method': 'native' if gate == 'tests' else 'source-analysis',
                               'artifact': 'receipt.json', 'scope': 'Transport control only'}.items():
                sub.values[name + '.' + key] = value
            sub.values['gate.' + gate + '.id'] = gate
            sub.values['gate.' + gate + '.purpose'] = 'Transport control: ' + gate
        target = self.root / 'dev/modeling/ascent'
        target.mkdir(parents=True)
        maintained = Path(__file__).resolve().parents[1] / 'dev/modeling/ascent'
        for name in ('commit-context.rules.scm', 'commit-admission.rules.scm'):
            (target / name).write_bytes((maintained / name).read_bytes())
        (sub.storage / 'sysml.stdout').write_text('explicit synthetic projection; no native claim')

    def test_whole_result_includes_all_predecessors_and_component_cases(self):
        sub, _ = self.integration()
        contract = sub.delivery_contract()
        self.assertEqual(len(contract['requirements']), 11)
        self.assertIn('ROOT-NATIVE-UNION', contract['requirements'])
        self.assertIn('WORKER-RESTORE', contract['requirements'])
        self.assertEqual(contract['runtimePaths'], ['lib/gc.c'])

    def test_missing_or_duplicate_obligation_cannot_be_a_smaller_rev(self):
        sub, report = self.integration()
        path = self.root / 'delivery.json'
        packet = json.loads(path.read_text())
        for rows in (packet['observations'][1:], packet['observations'] + [packet['observations'][0]]):
            path.write_text(json.dumps(dict(packet, observations=rows)))
            with self.assertRaisesRegex(ValueError, 'exactly once'):
                sub.prepare_audit(report)
            self.assertEqual(self.git('rev-parse', 'HEAD').decode().strip(), self.head)

    def test_stale_failed_or_wrong_result_receipt_cannot_close_delivery(self):
        sub, report = self.integration()
        path = self.root / 'delivery.json'
        packet = json.loads(path.read_text())
        for field in ('sourceTree', 'baseRevision', 'profileSha256', 'result'):
            path.write_text(json.dumps(dict(packet, **{field: 'different'})))
            with self.assertRaisesRegex(ValueError, 'another source/result/profile'):
                sub.prepare_audit(report)
        path.write_text(json.dumps(packet))
        receipt = self.root / 'receipt.json'
        receipt.write_text(json.dumps(dict(json.loads(receipt.read_text()), complete=False)))
        packet['observations'] = [dict(x, sha256=self.sha(receipt)) for x in packet['observations']]
        path.write_text(json.dumps(packet))
        with self.assertRaisesRegex(ValueError, 'complete obligation receipt'):
            sub.prepare_audit(report)

    def test_runtime_cannot_be_relabelled_support_or_hidden_in_paths(self):
        sub, report = self.integration()
        sub.values.update({'unit.kind': 'support', 'unit.result': '', 'unit.progressDelta': 0,
                           'unit.supportPaths': 'lib/gc.c'})
        with self.assertRaisesRegex(ValueError, 'non-runtime surface'):
            sub.prepare_audit(report)
        sub.values['unit.supportPaths'] = 'tests/*'
        with self.assertRaisesRegex(ValueError, 'exact non-runtime'):
            sub.prepare_audit(report)
        sub.values['unit.supportPaths'] = 'tests/allowed.scm'
        with self.assertRaisesRegex(ValueError, 'undeclared path'):
            sub.prepare_audit(report)

    def test_unclassified_and_support_progress_are_rejected_before_audit(self):
        sub = self.submission()
        sub.prepare(['a.c'], self.profile)
        sub.values = {}
        report = self.audit(sub)
        del sub.values['unit.kind']
        with self.assertRaisesRegex(ValueError, 'explicit SysML submission unit'):
            sub.prepare_audit(report)
        sub.values.update({'unit.kind': 'support', 'unit.progressDelta': 1})
        with self.assertRaisesRegex(ValueError, 'cannot claim'):
            sub.prepare_audit(report)

    def test_real_ascent_blocks_fragments_even_with_five_gates_covered(self):
        sub, report = self.integration()
        self.real_policy(sub)
        sub.prepare_audit(report)
        admitted = sub.admit()
        self.assertEqual(admitted['answers']['commitReady'], [['current']])
        self.assertEqual(admitted['answers']['commitProgressReady'], [['current', 'owned-lifetime']])
        self.assertEqual(len(admitted['gateReady']), 5)
        for requirement in sub.delivery_contract()['requirements']:
            scenario = 'missing-delivery:' + requirement
            self.assertEqual(sum(row[0] == scenario for row in admitted['answers']['commitGateReady']), 5)
            self.assertIn([scenario, requirement], admitted['answers']['commitUnitGap'])
            self.assertNotIn([scenario], admitted['answers']['commitReady'])
        self.assertEqual(admitted['negativeControls'], 41)

    def test_real_support_admission_never_advances_result(self):
        sub = self.submission()
        sub.prepare(['a.c'], self.profile)
        sub.values = {}
        report = self.audit(sub)
        (self.root / 'receipt.json').write_text(json.dumps({'complete': True}))
        sub.model_inputs = {}
        self.real_policy(sub)
        sub.prepare_audit(report)
        admitted = sub.admit()
        self.assertEqual(admitted['answers']['commitProgressReady'], [])
        self.assertEqual(admitted['progressDelta'], 0)
        self.assertEqual(admitted['negativeControls'], 29)

    def test_delivery_drift_after_admission_refuses_git_commit(self):
        sub, report = self.integration()
        self.real_policy(sub)
        sub.prepare_audit(report)
        admitted = sub.admit()
        (self.root / 'receipt.json').write_text('{}')
        with self.assertRaisesRegex(ValueError, 'delivery obligation evidence'):
            sub.commit('must reject fragment\n', admitted)
        self.assertEqual(self.git('rev-parse', 'HEAD').decode().strip(), self.head)

    def test_framework_support_scope_is_exact_and_cannot_qualify_vendor(self):
        native = dict(self.native, qualificationKind='framework-support')
        with self.assertRaisesRegex(ValueError, 'framework repository'):
            RevisionSubmission(self.root, self.repo, self.workspace, self.root / 'reject',
                               self.root / 'reject-evidence', native)
        native['canonicalSources'] = {'a.c': self.sha(self.workspace / 'a.c')}
        native['artifacts'] = {'receipt.json': self.sha(self.workspace / 'runtime')}
        (self.workspace / 'receipt.json').write_bytes((self.workspace / 'runtime').read_bytes())
        sub = RevisionSubmission(self.repo, self.repo, self.workspace, self.root / 'support',
                                 self.repo / 'evidence', native)
        with self.assertRaisesRegex(ValueError, 'exactly its tested sources'):
            sub.prepare(['a.c'], self.profile)
        # First preparation did not touch a branch or the shared index.
        sub = RevisionSubmission(self.repo, self.repo, self.workspace, self.root / 'support-complete',
                                 self.repo / 'evidence', native)
        source = sub.prepare(['a.c', 'receipt.json'], self.profile)
        self.assertFalse(source['canonicalInputEquivalence'])
        self.assertEqual(source['qualificationScope'], 'framework-support')
        sub.values = {'comment.commitUnitRequired': True, 'unit.kind': 'integration',
                      'unit.result': 'owned-lifetime', 'unit.progressDelta': 1, 'unit.supportPaths': ''}
        with self.assertRaisesRegex(ValueError, 'cannot authorize runtime integration'):
            sub.delivery_contract()

    def test_native_sysml_projects_whole_lifecycle_without_python_requirement_list(self):
        sub, _ = self.integration()
        temporary_root = sub.root
        project = Path(__file__).resolve().parents[1]
        sub.root = project
        models = ['dev/modeling/models/sysml/commit-gates.sysml'] + [
            'dev/refactoring/modern-c/models/sysml/' + name + '.sysml'
            for name in ('revision-delivery', 'delivery-plan', 'pending-cuts', 'delivery-outcomes')]
        values = sub.project('dev/refactoring/modern-c/models/sysml/owned-lifetime.sysml',
                             'GambitOwnedLifetime', models)
        sub.root = temporary_root
        self.assertEqual(values['unit.result'], 'owned-lifetime')
        self.assertEqual(values['unit.progressDelta'], 1)
        self.assertIn('MEMBER-OWNERSHIP', values.values())
        self.assertIn('WORKER-RESTORE', values.values())
        self.assertIn('ROOT-NATIVE-UNION', values.values())
        self.assertEqual(len(values['unit.sourceCases'].split(';')), 5)
        self.assertEqual(len(values['unit.requiredCases'].split(';')), 8)
        # Synthetic11-case packet cannot satisfy actual SysML's22 obligations.
        with self.assertRaisesRegex(ValueError, 'exactly once'):
            sub.delivery_contract()

    def test_framework_publication_adds_only_review_metadata_to_tested_subject(self):
        # Actual Git transport of a framework-only review envelope. Admission
        # inference is tested separately; this fixture cannot admit Gambit.
        self.root = self.repo
        (self.workspace / 'receipt.json').write_text(json.dumps(dict(complete=True,
            qualifiedTestModules=[dict(path='a.c', complete=True, skipped=0, tests=1,
                                      sha256=self.sha(self.workspace / 'a.c'))])))
        self.native = dict(self.native, qualificationKind='framework-support',
            frameworkTestReceipt='receipt.json',
            canonicalSources={'a.c': self.sha(self.workspace / 'a.c')},
            artifacts={'receipt.json': self.sha(self.workspace / 'receipt.json')})
        sub = self.submission()
        source = sub.prepare(['a.c', 'receipt.json'], self.profile)
        sub.model_inputs = {}
        sub.values = {}
        report = self.audit(sub)
        sub.values.update({'comment.supportFiles': 'a.c;receipt.json',
            'unit.supportPaths': 'a.c;receipt.json',
            'unit.testModules': 'a.c',
            'comment.derivedAuditFiles': 'source.json;source-manifest.json;model-contract.json;comment.json;admission.json',
            'comment.maxMetadataBytes': 65536})
        audit = sub.prepare_audit(report)
        sub.admission = dict(commitAdmitted=True, tree=source['tree'], artifacts={}, auditSha256=audit)
        (sub.evidence / 'model-contract.json').write_text('{"fixture":true}\n')
        (sub.evidence / 'admission.json').write_text(json.dumps(sub.admission))
        before = self.git('ls-files', '--stage', '-z')
        revision = sub.commit('framework-only transport\n', sub.admission)
        self.assertEqual(revision['testedSourceTree'], source['tree'])
        self.assertNotEqual(revision['tree'], source['tree'])
        self.assertEqual(revision['progressDelta'], 0)
        changed = self.git('diff', '--name-only', source['tree'], revision['tree']).decode().splitlines()
        self.assertEqual(set(changed), {'evidence/' + x for x in sub.values['comment.derivedAuditFiles'].split(';')})
        self.assertEqual(self.git('show', 'HEAD:a.c'), b'selected\n')
        self.assertEqual(self.git('ls-files', '--stage', '-z'), before)

    def test_framework_cannot_omit_skip_or_change_declared_test_consumer(self):
        sub, _ = self.integration()
        sub.framework_support = True  # Controlled validator fixture only.
        sub.values.update({'unit.kind': 'support', 'unit.result': '', 'unit.progressDelta': 0,
                           'unit.testModules': 'a.c;lib/gc.c'})
        first = dict(path='a.c', complete=True, skipped=0, tests=1,
                     sha256=sub.native['canonicalSources']['a.c'])
        second = dict(path='lib/gc.c', complete=True, skipped=0, tests=1,
                      sha256=sub.native['canonicalSources']['lib/gc.c'])
        receipt = self.workspace / 'test-consumers.json'
        sub.native['frameworkTestReceipt'] = receipt.name
        def publish(rows):
            receipt.write_text(json.dumps(dict(complete=True, qualifiedTestModules=rows)))
            sub.native['artifacts'][receipt.name] = self.sha(receipt)
        publish([first])
        with self.assertRaisesRegex(ValueError, 'all SysML-declared'):
            sub.delivery_contract()
        for change in ({'complete': False}, {'skipped': 1}, {'sha256': 'different'}, {'tests': 0}):
            publish([first, dict(second, **change)])
            with self.assertRaisesRegex(ValueError, 'failed, skipped, unbound or missing'):
                sub.delivery_contract()
