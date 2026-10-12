"""Explicit real-checker induction audit, never runtime or temporal admission."""
import json
import os
from pathlib import Path
import subprocess
import unittest

from gambit_smp.framework import ROOT, digest, execute
from gambit_smp.quint_backend import isolated_endpoint
from gambit_smp.induction_matrix import symbolic_check


class QuintInductionIntegration(unittest.TestCase):
    def test_definedness_original_evaluation(self):
        out = Path(os.environ["GAMBIT_SMP_INDUCTION_OUT"]).resolve()
        out.mkdir(parents=True, exist_ok=False)
        source = ROOT / "tests/fixtures/guard_definedness_controls.qnt"
        snapshot = out / source.name
        snapshot.write_bytes(source.read_bytes())
        receipt = {"schema": "gc-original-evaluation-controls.v1", "accepted": False,
            "native": {"status": "not-run"}, "runtimeAdmitted": False, "releaseAdmitted": False,
            "temporalProved": False, "enablednessProved": False, "auditPassed": False,
            "modelInputs": {snapshot.name: digest(snapshot)}, "results": [],
            "frameworkInputs": {name: digest(ROOT / name) for name in (
                "tests/integration_quint_induction.py", "src/gambit_smp/framework.py")}}
        try:
            for step, expected_error in (("mapGood", None), ("mapBad", "QNT507"),
                                          ("setBad", "QNT507"), ("listBad", "QNT510")):
                code, output, expired, seconds = execute(["quint", "run", str(snapshot),
                    "--backend", "typescript", "--seed", "1", "--max-steps", "1",
                    "--max-samples", "1", "--step", step, "--verbosity", "3"], out, 10)
                log = out / (step + ".log")
                log.write_text(output)
                receipt["results"].append({"case": snapshot.stem, "variant": "diagnostic",
                    "modelSha256": digest(snapshot), "stage": "original-action-simulation", "step": step,
                    "exit": code, "timeout": expired, "seconds": round(seconds, 3),
                    "expectedError": expected_error, "log": log.name, "logSha256": digest(log)})
                self.assertFalse(expired)
                if expected_error:
                    self.assertNotEqual(0, code)
                    self.assertIn(expected_error, output)
                else:
                    self.assertEqual(0, code, output)
                    self.assertIn("[State 1]", output)
            receipt["contextStable"] = (digest(source) == digest(snapshot) and
                all(digest(ROOT / name) == sha for name, sha in receipt["frameworkInputs"].items()))
            self.assertTrue(receipt["contextStable"])
            receipt["auditPassed"] = True
        finally:
            (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")

    def test_definedness_semantic_controls(self):
        from gambit_smp.guard_projection import format_ir, normalized, projections, project
        from gambit_smp.expression_definedness import sufficient_projections
        out = Path(os.environ["GAMBIT_SMP_INDUCTION_OUT"]).resolve()
        out.mkdir(parents=True, exist_ok=False)
        source = ROOT / "tests/fixtures/guard_definedness_controls.qnt"
        snapshot = out / source.name
        snapshot.write_bytes(source.read_bytes())
        receipt = {"schema": "gc-definedness-controls-audit.v1", "accepted": False,
            "native": {"status": "not-run"}, "runtimeAdmitted": False, "releaseAdmitted": False,
            "temporalProved": False, "enablednessProved": False, "auditPassed": False,
            "modelInputs": {snapshot.name: digest(snapshot)}, "results": [],
            "frameworkInputs": {name: digest(ROOT / name) for name in (
                "tests/integration_quint_induction.py", "src/gambit_smp/guard_projection.py",
                "src/gambit_smp/expression_definedness.py", "src/gambit_smp/induction_matrix.py",
                "src/gambit_smp/framework.py", "src/gambit_smp/quint_backend.py")}}
        try:
            ir_path = out / "protocol-ir.json"
            code, output, expired, _ = execute(["quint", "parse", str(snapshot), "--out", str(ir_path)], out, 10)
            self.assertEqual(0, code, output)
            self.assertFalse(expired)
            ir = json.loads(ir_path.read_text())
            necessary = projections(ir, "guard_definedness_controls")
            sufficient, partial = sufficient_projections(ir, necessary, "guard_definedness_controls")
            receipt["partialOperationsCovered"] = partial
            conflict_source = ROOT / "tests/fixtures/guard_conflicting_assignment.qnt"
            conflict_snapshot = out / conflict_source.name
            conflict_snapshot.write_bytes(conflict_source.read_bytes())
            receipt["modelInputs"][conflict_snapshot.name] = digest(conflict_snapshot)
            conflict_ir = out / "conflict-ir.json"
            code, output, expired, _ = execute(["quint", "parse", str(conflict_snapshot),
                "--out", str(conflict_ir)], out, 10)
            self.assertEqual(0, code, output)
            self.assertFalse(expired)
            declarations = json.loads(conflict_ir.read_text())["modules"][0]["declarations"]
            conflict = next(item for item in declarations if item.get("name") == "conflictingAssignments")
            with self.assertRaisesRegex(ValueError, "exactly one"):
                project(conflict["expr"])
            receipt["conflictingAssignmentRejected"] = True
            code, output, expired, seconds = execute(["quint", "typecheck", str(conflict_snapshot)], out, 10)
            log = out / "conflictingAssignments.log"
            log.write_text(output)
            receipt["results"].append({"case": conflict_snapshot.stem, "variant": "diagnostic",
                "modelSha256": digest(conflict_snapshot), "stage": "typecheck", "exit": code,
                "timeout": expired, "seconds": round(seconds, 3), "expectedRejection": "QNT202",
                "log": log.name, "logSha256": digest(log)})
            self.assertFalse(expired)
            self.assertNotEqual(0, code)
            self.assertIn("QNT202", output)
            expressions = {**{"necessary_" + key: expr for key, expr in necessary.items()},
                           **{"defined_" + key: expr for key, expr in sufficient.items()}}
            payload = {"name": "definedness_checks", "declarations": [
                {"kind": "import", "protoName": "guard_definedness_controls", "defName": "*",
                 "fromSource": "./guard_definedness_controls"}] + [
                {"kind": "def", "qualifier": "val", "name": key, "expr": expr}
                for key, expr in expressions.items()]}
            generated = out / "definedness_checks.qnt"
            generated.write_text(format_ir(payload, out))
            proof_ir = out / "proof-ir.json"
            code, output, expired, _ = execute(["quint", "parse", str(generated), "--out", str(proof_ir)], out, 10)
            self.assertEqual(0, code, output)
            self.assertFalse(expired)
            actual = next(item for item in json.loads(proof_ir.read_text())["modules"]
                          if item["name"] == "definedness_checks")["declarations"]
            actual = {item["name"]: item for item in actual if "name" in item}
            self.assertEqual(set(expressions), set(actual))
            for key, expr in expressions.items():
                self.assertEqual(expr, normalized(actual[key]["expr"]))
            receipt.update(protocolIrSha256=digest(ir_path), proofIrSha256=digest(proof_ir), projectionVerified=True)
            receipt["modelInputs"][generated.name] = digest(generated)
            for invariant, positive in (("defined_mapGood", True), ("necessary_mapBad", True),
                    ("defined_mapBad", False), ("defined_setBad", False), ("defined_listBad", False),
                    ("defined_emptyChoice", False), ("necessary_emptyChoice", False)):
                directory = out / invariant
                directory.mkdir()
                result, output = symbolic_check(generated, initializer="init", invariant=invariant,
                    step="step", length=0, cwd=directory, timeout=30)
                log = out / (invariant + ".log")
                log.write_text(output)
                result.update(case=generated.stem, variant="diagnostic", modelSha256=digest(generated),
                              log=log.name, logSha256=digest(log))
                receipt["results"].append(result)
                self.assertTrue(result["obligationProved"] if positive else result["counterexample"], output[-2000:])
            receipt["contextStable"] = (digest(source) == digest(snapshot) and
                digest(conflict_source) == digest(conflict_snapshot) and
                all(digest(out / name) == sha for name, sha in receipt["modelInputs"].items()) and
                all(digest(ROOT / name) == sha for name, sha in receipt["frameworkInputs"].items()))
            self.assertTrue(receipt["contextStable"])
            receipt["auditPassed"] = True
        finally:
            (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")

    def test_compositional_rank_rule(self):
        out = Path(os.environ["GAMBIT_SMP_INDUCTION_OUT"]).resolve()
        out.mkdir(parents=True, exist_ok=False)
        source = ROOT / "tests/fixtures/rank_composition.qnt"
        snapshot = out / source.name
        snapshot.write_bytes(source.read_bytes())
        receipt = {"schema": "quint-rank-composition-audit.v1", "accepted": False,
            "native": {"status": "not-run"}, "runtimeAdmitted": False,
            "releaseAdmitted": False, "temporalProved": False,
            "auditPassed": False, "results": []}
        try:
            for invariant, positive in (("boundedAndStrict", True), ("rejectsInsufficientWeight", False)):
                directory = out / invariant
                directory.mkdir()
                result, output = symbolic_check(snapshot, initializer="init", invariant=invariant,
                    step="step", length=0, cwd=directory, timeout=30)
                log = out / (invariant + ".log")
                log.write_text(output)
                result.update(case=snapshot.stem, variant="diagnostic",
                    modelSha256=digest(snapshot), log=log.name, logSha256=digest(log))
                receipt["results"].append(result)
                self.assertFalse(result["timeout"], output[-1500:])
                self.assertTrue(result["obligationProved"] if positive else result["counterexample"], output[-1500:])
            receipt["contextStable"] = digest(source) == digest(snapshot)
            self.assertTrue(receipt["contextStable"])
            receipt["auditPassed"] = True
        finally:
            (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")

    def test_zero_step_native_enabledness(self):
        out = Path(os.environ["GAMBIT_SMP_INDUCTION_OUT"]).resolve()
        out.mkdir(parents=True, exist_ok=False)
        source = ROOT / "tests/fixtures/induction_enabledness.qnt"
        snapshot = out / source.name
        snapshot.write_bytes(source.read_bytes())
        receipt = {"schema": "quint-enabledness-audit.v1", "accepted": False,
            "native": {"status": "not-run"}, "runtimeAdmitted": False,
            "releaseAdmitted": False, "temporalProved": False,
            "auditPassed": False, "results": []}
        try:
            for invariant, positive in (("enabledCandidate", True), ("rejectsBlocked", False)):
                directory = out / invariant
                directory.mkdir()
                result, output = symbolic_check(snapshot, initializer="initCandidate",
                    invariant=invariant, step="step", length=0, cwd=directory, timeout=30)
                log = out / (invariant + ".log")
                log.write_text(output)
                result.update(case=snapshot.stem, variant="diagnostic",
                    modelSha256=digest(snapshot), log=log.name, logSha256=digest(log))
                receipt["results"].append(result)
                self.assertFalse(result["timeout"], output[-2000:])
                self.assertTrue(result["obligationProved"] if positive else result["counterexample"],
                                output[-2000:])
            receipt["contextStable"] = digest(source) == digest(snapshot)
            self.assertTrue(receipt["contextStable"])
            receipt["auditPassed"] = True
        finally:
            (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")

    def test_function_domain_direct_induction(self):
        out = Path(os.environ["GAMBIT_SMP_INDUCTION_OUT"]).resolve()
        out.mkdir(parents=True, exist_ok=False)
        source = ROOT / "tests/fixtures/induction_function_domain.qnt"
        snapshot = out / source.name
        snapshot.write_bytes(source.read_bytes())
        receipt = {"schema": "quint-function-domain-audit.v1", "accepted": False,
            "runtimeAdmitted": False, "releaseAdmitted": False, "temporalProved": False,
            "native": {"status": "not-run"}, "auditPassed": False, "results": []}
        try:
            for step, positive in (("step", True), ("escape", False), ("omitKey", False)):
                directory = out / step
                directory.mkdir()
                command = ["quint", "verify", str(snapshot), "--backend", "apalache",
                    "--apalache-version", "0.62.1", "--inductive-invariant", "inductive",
                    "--invariant", "safe", "--step", step,
                    "--server-endpoint", isolated_endpoint(), "--verbosity", "2"]
                code, output, expired, seconds = execute(command, directory, 30)
                log = out / (step + ".log")
                log.write_text(output)
                receipt["results"].append({"case": snapshot.stem, "variant": "diagnostic",
                    "modelSha256": digest(snapshot), "step": step, "exit": code,
                    "timeout": expired, "seconds": round(seconds, 3),
                    "log": log.name, "logSha256": digest(log)})
                self.assertFalse(expired, output[-1500:])
                self.assertIn("[1/3] Checking whether", output)
                self.assertIn("[2/3] Checking whether", output)
                if positive:
                    self.assertEqual(0, code, output[-1500:])
                    self.assertIn("[3/3] Checking whether", output)
                    self.assertIn("[ok] No violation found", output)
                else:
                    self.assertNotEqual(0, code, output[-1500:])
                    self.assertIn("[violation] Found an issue", output)
                    self.assertNotIn("[3/3] Checking whether", output)
            receipt["contextStable"] = digest(source) == digest(snapshot)
            self.assertTrue(receipt["contextStable"])
            receipt["auditPassed"] = True
        finally:
            (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")

    def test_gc_candidate_obligation(self):
        out = Path(os.environ["GAMBIT_SMP_INDUCTION_OUT"]).resolve()
        out.mkdir(parents=True, exist_ok=False)
        names = ("gc_recursive_queue_induction.qnt", "gc_recursive_queue_wait.qnt")
        inputs = {}
        for name in names:
            source = ROOT / "models/gambit" / name
            (out / name).write_bytes(source.read_bytes())
            inputs[name] = digest(source)
        obligation = os.environ.get("GAMBIT_SMP_GC_OBLIGATION", "closure")
        self.assertIn(obligation, ("initial", "closure", "termination-step"))
        step = "countOrRetry" if obligation == "termination-step" else "step"
        result, output = symbolic_check(out / names[0],
            initializer="init" if obligation == "initial" else "initSafetyCandidate",
            step=step, invariant="candidateInvariant", length=0 if obligation == "initial" else 1,
            cwd=out)
        code, timed_out, seconds = result["exit"], result["timeout"], result["seconds"]
        log = out / "closure.log"
        log.write_text(output)
        stable = all(digest(ROOT / "models/gambit" / name) == sha == digest(out / name)
                     for name, sha in inputs.items())
        receipt = {"schema": "gc-induction-obligation.v1", "accepted": False,
            "scope": "safety-candidate-one-step-closure-only-not-complete-proof",
            "obligation": "domain-and-safe-and-step-implies-domain-prime-and-safe-prime",
            "obligationKind": obligation, "targetStep": step,
            "exit": code, "timeout": timed_out, "seconds": round(seconds, 3),
            "contextStable": stable, "modelInputs": inputs,
            "native": {"status": "not-run"},
            "results": [{"case": "gc_recursive_queue_induction", "variant": "diagnostic",
                "modelSha256": inputs[names[0]], "log": log.name}],
            "log": log.name, "logSha256": digest(log),
            "closureCounterexample": not timed_out and code != 0 and
                "[violation] Found an issue" in output,
            "obligationProved": not timed_out and code == 0 and "[ok] No violation found" in output,
            "runtimeAdmitted": False, "releaseAdmitted": False, "temporalProved": False}
        (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        self.assertTrue(stable)
        self.assertFalse(timed_out)
        self.assertTrue(receipt["closureCounterexample"] if obligation == "closure"
                        else receipt["obligationProved"], output[-2500:])

    def test_initial_preservation_and_implication_are_distinct(self):
        out = Path(os.environ["GAMBIT_SMP_INDUCTION_OUT"]).resolve()
        out.mkdir(parents=True, exist_ok=False)
        fixture = ROOT / "tests/fixtures/induction_gate.qnt"
        snapshot = out / fixture.name
        snapshot.write_bytes(fixture.read_bytes())
        receipt = {"schema": "quint-induction-audit.v1", "accepted": False,
            "auditPassed": False, "runtimeAdmitted": False, "releaseAdmitted": False,
            "native": {"status": "not-run"},
            "temporalProved": False, "scope": "checker-only-induction-phase-controls",
            "modelSha256": digest(snapshot), "results": [],
            "quintVersion": subprocess.check_output(["quint", "--version"],
                                                      text=True, timeout=10).strip(),
            "frameworkInputs": {name: digest(ROOT / name) for name in (
                "tests/integration_quint_induction.py", "src/gambit_smp/framework.py",
                "src/gambit_smp/quint_backend.py")}}
        try:
            for name, invariant, step, last_phase, positive in (
                ("inductive", "inductive", "step", 3, True),
                ("failsInitial", "failsInitial", "step", 1, False),
                ("failsPreservation", "failsPreservation", "step", 2, False),
                ("failsImplication", "failsImplication", "step", 3, False),
                ("domainEscape", "inductive", "stepEscapesDomain", 2, False)):
                directory = out / name
                directory.mkdir()
                command = ["quint", "verify", str(snapshot), "--backend", "apalache",
                    "--inductive-invariant", invariant, "--invariant", "safe",
                    "--step", step,
                    "--server-endpoint", isolated_endpoint(), "--verbosity", "2"]
                code, output, timed_out, seconds = execute(command, directory, 30)
                log = out / (name + ".log")
                log.write_text(output)
                receipt["results"].append({"name": name, "invariant": invariant, "step": step, "exit": code,
                    "case": "induction_gate", "variant": "diagnostic",
                    "modelSha256": receipt["modelSha256"],
                    "timeout": timed_out, "seconds": round(seconds, 3),
                    "expectedLastPhase": last_phase, "log": log.name,
                    "logSha256": digest(log)})
                self.assertFalse(timed_out, invariant)
                for phase in range(1, last_phase + 1):
                    self.assertIn(f"[{phase}/3] Checking whether", output, invariant)
                if last_phase < 3:
                    self.assertNotIn(f"[{last_phase + 1}/3] Checking whether", output, invariant)
                if positive:
                    self.assertEqual(0, code, output)
                    self.assertIn("[ok] No violation found", output)
                else:
                    self.assertNotEqual(0, code, output)
                    self.assertIn("[violation] Found an issue", output)
            stable = digest(fixture) == receipt["modelSha256"] == digest(snapshot) and all(
                digest(ROOT / name) == sha for name, sha in receipt["frameworkInputs"].items())
            receipt["contextStable"] = stable
            self.assertTrue(stable)
            receipt["auditPassed"] = True
        finally:
            (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")


if __name__ == "__main__":
    unittest.main()
