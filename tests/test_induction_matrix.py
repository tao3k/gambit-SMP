import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import induction_matrix as matrix
from gambit_smp.framework import digest


def ir(actions):
    return {"stage": "parsing", "errors": [], "modules": [{"name": "protocol", "declarations": [
        {"name": "step", "qualifier": "action", "expr": {"kind": "app", "opcode": "actionAny",
            "args": [{"kind": "name", "name": name} for name in actions]}},
        *[{"name": name, "qualifier": "action"} for name in set(actions)]]}]}


class InductionMatrixTests(unittest.TestCase):
    def test_source_wait_archived_ir_keeps_all_twenty_two_branches(self):
        directory = matrix.ROOT / "evidence/model-results/gc-source-wait-new-action-induction"
        parsed = json.loads((directory / "protocol-ir.json").read_text())
        members = matrix.action_members(parsed, "gc_recursive_wait_recheck", "sourceWaitStep")
        self.assertEqual(22, len(members))
        self.assertIn("orderedRecheck", members)
        self.assertIn("unboundedWake", members)
        self.assertNotIn("probeRecheckQueue", members)
        self.assertNotIn("spuriousWake", members)
        receipt = json.loads((directory / "receipt.json").read_text())
        self.assertTrue(receipt["initialProved"])
        self.assertEqual(["orderedRecheck", "unboundedWake"], receipt["provedActions"])
        self.assertEqual(set(members) - set(receipt["provedActions"]), set(receipt["uncoveredActions"]))
        self.assertFalse(receipt["preservationComplete"])
        self.assertFalse(receipt["accepted"])

    def test_preflight_denial_is_recorded_only_in_new_owned_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for existing in (False, True):
                out = root / ("existing" if existing else "fresh")
                if existing:
                    out.mkdir()
                    (out / "keep.txt").write_text("user input")
                with patch("sys.argv", ["induction-matrix", "--out", str(out)]), \
                        patch.object(matrix, "campaign", side_effect=ValueError("invalid manifest")):
                    with self.assertRaisesRegex(SystemExit, "PREFLIGHT-DENY"):
                        matrix.main()
                if existing:
                    self.assertEqual(["keep.txt"], [path.name for path in out.iterdir()])
                    self.assertEqual("user input", (out / "keep.txt").read_text())
                else:
                    saved = json.loads((out / "receipt.json").read_text())
                    self.assertEqual("ValueError", saved["errorType"])
                    self.assertEqual([], saved["results"])
                    self.assertFalse(saved["accepted"])
                    self.assertFalse(saved["runtimeAdmitted"])

    def test_reused_safety_requires_real_logs_and_matching_source(self):
        source = matrix.ROOT / "evidence/model-results/gc-induction-cartesian-contract-ir"
        names = ["models/gambit/gc_recursive_queue_wait.qnt",
                 "models/gambit/gc_recursive_queue_induction.qnt"]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            archive = root / "evidence/checked"
            shutil.copytree(source, archive)
            for name in names:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes((archive / path.name).read_bytes())
            saved, inputs = matrix.safety_obligations(root, "evidence/checked/receipt.json", names)
            self.assertTrue(saved["preservationComplete"])
            self.assertIn("evidence/checked/proof-ir.json", inputs)
            model = root / names[0]
            original = model.read_bytes()
            model.write_bytes(original + b"// drift\n")
            with self.assertRaisesRegex(ValueError, "differs from checked"):
                matrix.safety_obligations(root, "evidence/checked/receipt.json", names)
            model.write_bytes(original)
            log = archive / saved["results"][0]["log"]
            log.write_text("fabricated success")
            with self.assertRaisesRegex(ValueError, "artifact drift"):
                matrix.safety_obligations(root, "evidence/checked/receipt.json", names)

    def test_adapters_preserve_whole_original_transition_without_guard(self):
        body = {"kind": "app", "opcode": "actionAll", "args": [
            {"kind": "name", "name": "a"},
            {"kind": "app", "opcode": "assign", "args": [
                {"kind": "name", "name": "history"}, {"kind": "int", "value": 0}]}]}
        model = {"modules": [{"name": "proof", "declarations": [
            {"kind": "var", "name": "history"},
            {"name": "ranked_a", "qualifier": "action", "expr": body}]}]}
        self.assertEqual({"a": "ranked_a"}, matrix.proof_adapters(model, "proof", "ranked_", ["a"]))
        self.assertEqual({"a": "ranked_a"}, matrix.proof_adapters(model, "proof", "ranked_", ["a"],
            updates={"history": {"kind": "int", "value": 0}}))
        with self.assertRaisesRegex(ValueError, "required update"):
            matrix.proof_adapters(model, "proof", "ranked_", ["a"],
                updates={"history": {"kind": "int", "value": 1}})
        for extra in ({"kind": "bool", "value": True},
                      {"kind": "app", "opcode": "assign", "args": [
                          {"kind": "name", "name": "s"}, {"kind": "name", "name": "s"}]}):
            body["args"].append(extra)
            with self.assertRaisesRegex(ValueError, "must not add guards"):
                matrix.proof_adapters(model, "proof", "ranked_", ["a"])
            body["args"].pop()
        body["args"][0]["name"] = "other"
        with self.assertRaises(ValueError):
            matrix.proof_adapters(model, "proof", "ranked_", ["a"])

    def test_exact_ir_membership_and_rejection(self):
        self.assertEqual(["a", "b"], matrix.action_members(ir(["a", "b"]), "protocol", "step"))
        for changed in (ir(["a", "a"]), ir([])):
            with self.assertRaises(ValueError):
                matrix.action_members(changed, "protocol", "step")

    def test_imported_actions_require_unique_explicit_origins(self):
        parsed = ir(["a", "b"])
        base = parsed["modules"][0]
        base["name"] = "base"
        local = base["declarations"].pop(0)
        imported = {"kind": "import", "defName": "*", "protoName": "base"}
        parsed["modules"].append({"name": "protocol", "declarations": [imported, local]})
        self.assertEqual(["a", "b"], matrix.action_members(parsed, "protocol", "step"))
        parsed["modules"].append({"name": "other", "declarations": [
            {"name": "a", "qualifier": "action"}]})
        parsed["modules"][-2]["declarations"].append(
            {"kind": "import", "defName": "*", "protoName": "other"})
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            matrix.action_members(parsed, "protocol", "step")
        parsed["modules"][-2]["declarations"].pop()
        imported["defName"] = "a"
        with self.assertRaisesRegex(ValueError, "wildcard"):
            matrix.action_members(parsed, "protocol", "step")
        imported["defName"] = "*"
        base["declarations"].append({"kind": "import", "defName": "*", "protoName": "protocol"})
        with self.assertRaisesRegex(ValueError, "cyclic"):
            matrix.action_members(parsed, "protocol", "step")
        changed = ir(["a"])
        changed["modules"][0]["declarations"][0]["expr"]["opcode"] = "actionAll"
        with self.assertRaisesRegex(ValueError, "explicit disjunction"):
            matrix.action_members(changed, "protocol", "step")
        changed = ir(["a"])
        changed["modules"][0]["declarations"][1]["qualifier"] = "val"
        with self.assertRaisesRegex(ValueError, "non-action"):
            matrix.action_members(changed, "protocol", "step")
        for expression in ({"kind": "name", "name": "alias"},
                           {"kind": "app", "opcode": "actionAny", "args": []}):
            changed = ir(["a"])
            changed["modules"][0]["declarations"][1]["expr"] = expression
            with self.assertRaisesRegex(ValueError, "explicit expansion"):
                matrix.action_members(changed, "protocol", "step")

    def test_symbolic_verdicts_and_unchanged_budget(self):
        for code, output, expired, proved, counterexample in (
            (0, "The outcome is: NoError\n[ok] No violation found", False, True, False),
            (0, "[ok] No violation found", False, False, False),
            (1, "[State 0]\n[violation] Found an issue", False, False, True),
            (1, "rewriter error", False, False, False),
            (0, "The outcome is: NoError\n[ok] No violation found", True, False, False)):
            with patch.object(matrix, "isolated_endpoint", return_value="127.0.0.1:1"), \
                    patch.object(matrix, "execute", return_value=(code, output, expired, 1)) as run:
                row, _ = matrix.symbolic_check(Path("model.qnt"), initializer="initI",
                    invariant="I", step="original", length=1, cwd=Path("."))
                self.assertEqual(proved, row["obligationProved"])
                self.assertEqual(counterexample, row["counterexample"])
                self.assertEqual(90, run.call_args.args[2])
                self.assertIn("original", run.call_args.args[0])
        with self.assertRaises(ValueError):
            matrix.symbolic_check(Path("x"), initializer="x", invariant="x", step="x",
                                  length=2, cwd=Path("."))

    def fixture_campaign(self, root, actions, fail=None, selected=None):
        home = root / "home"
        jar = home / ".quint/apalache-dist-0.62.1/apalache/lib/apalache.jar"
        jar.parent.mkdir(parents=True)
        jar.write_bytes(b"test checker")
        (root / "evidence").mkdir()
        (root / "evidence/context.json").write_text('{"contextInputs": {}}')
        for name in ("proof.qnt", "protocol.qnt"):
            (root / name).write_text("test model")
        for name in ("induction_matrix", "framework", "quint_backend", "model_schedule"):
            path = root / "src/gambit_smp" / (name + ".py")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("test source")
        manifest = root / "evidence/matrix.json"
        manifest.write_text(json.dumps({"schema": "gambit-induction-matrix.v1",
            "quintVersion": "0.33.0", "apalacheJarSha256": digest(jar),
            "model": "proof.qnt", "protocol": "protocol.qnt", "protocolModule": "protocol",
            "contextManifest": "evidence/context.json", "step": "step", "initializer": "init",
            "inductionInitializer": "initI", "invariant": "I", "goal": "safe"}))
        def parse(command, cwd, timeout):
            Path(command[-1]).write_text(json.dumps(ir(actions)))
            return 0, "", False, 0
        def check(snapshot, **args):
            proved = args["step"] != fail
            return {"step": args["step"], "exit": 0 if proved else 1, "timeout": False,
                    "obligationProved": proved, "seconds": 0.1}, "log"
        with patch.object(matrix, "ROOT", root), patch.object(matrix.Path, "home", return_value=home), \
                patch.object(matrix.subprocess, "check_output", return_value="0.33.0\n"), \
                patch.object(matrix, "execute", side_effect=parse), \
                patch.object(matrix, "symbolic_check", side_effect=check), \
                patch.object(matrix, "available_processors", return_value=4), \
                patch.object(matrix, "physical_memory", return_value=32 * 1024 ** 3):
            return matrix.campaign(manifest, root / "out", selected=selected)

    def test_failure_stops_next_batch_and_never_admits(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.fixture_campaign(Path(directory).resolve(), ["a", "b", "bad", "c", "never"], "bad")
            self.assertEqual(["step", "a", "b", "bad", "c"], [row["step"] for row in result["results"]])
            self.assertFalse(result["preservationComplete"])
            self.assertFalse(result["accepted"])
            self.assertTrue(result["contextStable"])
            self.assertEqual(["bad"], result["failedActions"])
            self.assertEqual(["never"], result["uncoveredActions"])

    def test_complete_atomic_matrix_is_still_not_temporal_or_generator_proof(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.fixture_campaign(Path(directory).resolve(), ["a", "b"])
            self.assertTrue(result["initialProved"])
            self.assertTrue(result["preservationComplete"])
            self.assertTrue(result["implicationProved"])
            self.assertFalse(result["generatorCoverageProved"])
            self.assertFalse(result["inductiveSafetyAdmitted"])
            self.assertFalse(result["temporalProved"])

    def test_selected_subset_cannot_be_complete(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.fixture_campaign(Path(directory).resolve(), ["a", "b"], selected=["a"])
            self.assertFalse(result["preservationComplete"])
            self.assertFalse(result["implicationProved"])


if __name__ == "__main__":
    unittest.main()
