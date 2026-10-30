"""Native policy controls, with synthetic gate observations, not runtime admission."""
import json
import os
from pathlib import Path
import shutil
import unittest

from gambit_smp.ascent_program import load_catalog, query
from gambit_smp.branch_evidence import content_digest
from gambit_smp.revision_submission import digest
from gambit_smp.task_processes import run


class RevisionCommentPolicyTests(unittest.TestCase):
    def test_native_sysml_fields_block_incomplete_or_stale_comments(self):
        root = Path(__file__).resolve().parents[1]
        model = root / "dev/modeling/models/sysml/commit-gates.sysml"
        policy = root / "dev/modeling/ascent/commit-admission.rules.scm"
        context = root / "dev/modeling/ascent/commit-context.rules.scm"
        tool = shutil.which(os.environ.get("SYSML", "sysml"))
        self.assertIsNotNone(tool, "native SysML is required for policy qualification")
        arguments = [tool, "-strict", "-validate", "-json"]
        for field in ("fields", "allRevisions", "rule", "matrixRequired", "matrixFields"):
            arguments += ["-e", "GambitCommitGates::revisionAudit." + field]
        result = run([*arguments, str(model)], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        values = [json.loads(line[4:]) for line in json.loads(result.stdout)["output"]
                  if line.startswith("  = ")]
        self.assertEqual(len(values), 5)
        self.assertIs(values[1], True)
        self.assertIs(values[3], True)
        matrix_fields = values[4].split(",")
        fields = values[0].split(",")
        self.assertEqual(len(fields), len(set(fields)))
        self.assertIn("validation", fields)
        self.assertIn("benefits", fields)
        catalog = load_catalog(context, policy)
        catalog["sourceTexts"] = ["(ascent-fragment\n" + source + "\n)"
                                  for source in catalog["sourceTexts"]]
        case = "REV-comment-policy-controls"
        source = ["control-head", "control-tree", "control-manifest", "control-profile"]
        gates = ["tests", "learning", "process", "models", "questions"]
        model_name = str(model.relative_to(root))
        model_hash = digest(model)
        bindings = [("target-model-bundle-sha256", model_hash),
                    ("native-output-sha256", content_digest(result.stdout)),
                    ("planner-dsl-sha256", digest(policy))]
        facts = dict(
            clue=[["audit-policy", case, case, "source", "llm", "synthetic-policy-control"]],
            factor=[["audit-policy", case, key, value] for key, value in bindings],
            binding=[list(row) for row in bindings],
            commitStudyFact=[[case]], commitPolicyFact=[[digest(policy)]],
            commitGateFact=[[gate, gate] for gate in gates],
            commitNeedFact=[[gate + "-control", gate, "policy-control", model_name, model_hash]
                            for gate in gates],
            commitArtifactFact=[[model_name, model_hash]],
            commitEvidenceFact=[["policy-control", model_hash, "synthetic-policy-control"]],
            commitSourceFact=[source], commitScenarioClassFact=[],
            commitUnitFact=[],
            commitCandidateFact=[], commitObservationFact=[],
            commitAuditRequiredFact=[[field] for field in fields],
            commitAuditPacketFact=[], commitAuditFieldFact=[],
            commitMatrixRequiredFact=[["matrix"]],
            commitMatrixFieldRequiredFact=[[x] for x in matrix_fields],
            commitMatrixPacketFact=[],commitMatrixRowFact=[],commitMatrixFieldFact=[],
            commitMatrixRefFact=[],commitMatrixValueValidFact=[],
            controlExpectReadyFact=[["complete-comment"]], controlExpectBlockedFact=[])
        scenarios = ["complete-comment", "absent-unit", "absent-comment", "stale-comment",
                     *["omit-" + field for field in fields], "absent-matrix", "stale-matrix",
                     "empty-matrix", "missing-matrix-field", "missing-matrix-evidence", "wrong-matrix-evidence", "invalid-matrix-value"]
        for scenario in scenarios:
            # This is an audit-policy control, not a runtime integration.
            if scenario != "absent-unit":
                facts["commitUnitFact"].append([scenario, "support", "", "0"])
            facts["commitCandidateFact"].append([scenario, *source])
            facts["commitScenarioClassFact"].append([scenario, "synthetic-policy-control"])
            if scenario != "complete-comment":
                facts["controlExpectBlockedFact"].append([scenario])
            for gate in gates:
                facts["commitObservationFact"].append([
                    scenario, *source, gate + "-control", "policy-control", model_name,
                    model_hash, model_hash, "pass", "policy-control", model_hash])
            if scenario == "absent-comment":
                continue
            payload = {field: "reviewed control: " + field for field in fields
                       if scenario != "omit-" + field}
            packet_hash = content_digest(payload)
            packet_source = list(source)
            if scenario == "stale-comment":
                packet_source[1] = "wrong-tree"
            facts["commitAuditPacketFact"].append([scenario, *packet_source, packet_hash])
            if scenario != "absent-matrix":
                matrix_hash = content_digest([scenario,"matrix"])
                facts["commitMatrixPacketFact"].append([scenario, "wrong" if scenario=="stale-matrix" else packet_hash, matrix_hash])
                if scenario != "empty-matrix":
                    facts["commitMatrixRowFact"].append([matrix_hash,"runtime","unmeasured","ops/s"])
                    for field in matrix_fields:
                        if scenario != "missing-matrix-field" or field != "limitation":
                            facts["commitMatrixFieldFact"].append([matrix_hash,"runtime",field,"explicit-control"])
                    if scenario != "missing-matrix-evidence":
                        facts["commitMatrixRefFact"].append([matrix_hash,"runtime",model_name,"wrong" if scenario=="wrong-matrix-evidence" else model_hash])
                    if scenario != "invalid-matrix-value":
                        facts["commitMatrixValueValidFact"].append([matrix_hash,"runtime"])
            for field, text in payload.items():
                row = [packet_hash, field, text]
                if row not in facts["commitAuditFieldFact"]:
                    facts["commitAuditFieldFact"].append(row)
        names = ("commitReady", "commitMissing", "commitAuditMissing", "commitMatrixMissing", "controlFailure",
                 "commitUnitGap", "commitProgressReady")
        answers = {name: [list(row) for row in rows] for name, rows in
                   query(facts, catalog, {name: name for name in names}).items()}
        self.assertEqual(answers["commitReady"], [["complete-comment"]])
        self.assertEqual(answers["commitMissing"], [])  # underlying gates all pass
        self.assertEqual(answers["controlFailure"], [])
        self.assertEqual(answers["commitProgressReady"], [])
        self.assertIn(["absent-unit", "missing-submission-unit"], answers["commitUnitGap"])
        self.assertTrue(answers["commitMatrixMissing"])
        for field in fields:
            self.assertIn(["omit-" + field, field], answers["commitAuditMissing"])


if __name__ == "__main__":
    unittest.main()
