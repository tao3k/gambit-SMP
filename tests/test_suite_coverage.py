"""Synthetic transport controls; passing these is not native SMP evidence."""
import copy
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.ascent_program import load_catalog, query
from gambit_smp.framework import ROOT
from gambit_smp.suite_coverage import project_suite_files


_RETIRED_GSC_RECEIPT = "evidence/research/retained/modern-c/frozen-568e0276-smp/assertion-runtime-framework-gsc.json"


def _synthetic_retired_smp_receipts(root):
    """Build compact synthetic stand-ins for oversized retired SMP receipts."""
    from gambit_smp.suite_coverage import SMP_ORIGINAL_INVENTORY
    gsi = json.loads((root / "evidence/research/retained/modern-c/frozen-568e0276-smp/shared-procedure-dispatch-gsi.json").read_text())
    selected = list(gsi["selectedFiles"])
    other_files = [name for name in selected if name != "03-number/_num.scm"]
    stages = ("scheme-to-c", "c-to-dynamic-module", "compiled-execution")
    numeric_phases = [
        {"phase": name, "accepted": True, "exit": 0, "timeout": False,
         "artifactSha256": "a" * 64, **({"originalAssertionsWitness": True} if name == "compiled-execution" else {})}
        for name in stages]
    gsc_observations = [
        {"batch": 0, "shard": 0, "files": ["03-number/_num.scm"], "accepted": True, "exit": 0, "timeout": False,
         "sharedPhaseBudgetSeconds": 90, "assertionProtocol": "original-gsi-loader-and-assertion-witness",
         "compilerPhases": numeric_phases},
        {"batch": 0, "shard": 1, "files": other_files, "observedFiles": other_files,
         "accepted": True, "exit": 0, "timeout": False}]
    gsc_processes = [
        {"stage": "suite-0-0-" + name, "effectiveBudgetSeconds": cap, "seconds": secs,
         "exit": 0, "timeout": False, "parentReaped": True, "processGroupQuiescent": True}
        for name, cap, secs in zip(stages, (90, 70, 30), (20, 40, 1))]
    return {
        SMP_ORIGINAL_INVENTORY: {
            "original": {"unitInventory": ["tests/unit-tests/" + name for name in selected]}},
        _RETIRED_GSC_RECEIPT: {
            "sourceTree": gsi["sourceTree"], "profileSha256": gsi["profileSha256"],
            "producerSha256": gsi["producerSha256"], "runtimeArtifacts": gsi["runtimeArtifacts"],
            "mode": "gsc", "complete": True, "selectedFiles": selected,
            "manifestDifference": {"extra": [], "missing": []},
            "processes": gsc_processes, "observations": gsc_observations}}


def _patch_retired_original_inventory(root):
    """Supply oversized retired SMP receipts only for their exact ledger paths."""
    from unittest.mock import patch
    from gambit_smp.suite_coverage import SMP_LEDGER_FOLDER, SMP_ORIGINAL_INVENTORY, _load_smp_evidence
    ledger = json.loads((root / SMP_LEDGER_FOLDER / "accepted-smp-progress.json").read_text())
    bindings = {
        SMP_ORIGINAL_INVENTORY: ledger["originalInventory"],
        _RETIRED_GSC_RECEIPT: ledger["receipts"]["gsc"]}
    synthetic = _synthetic_retired_smp_receipts(root)
    def load(base, path, expected=None):
        key = Path(path).as_posix()
        if key in synthetic:
            binding = bindings[key]
            if expected is not None and binding["sha256"] != expected:
                raise ValueError("SMP evidence identity changed")
            return synthetic[key], dict(binding)
        return _load_smp_evidence(base, path, expected)
    return patch("gambit_smp.suite_coverage._load_smp_evidence", side_effect=load)


class AcceptedSmpProgressTests(unittest.TestCase):
    def test_smp_status_uses_accepted_history_and_rejects_drift(self):
        from gambit_smp.framework import digest
        from gambit_smp.suite_coverage import SMP_LEDGER_FOLDER, SMP_ORIGINAL_INVENTORY, accepted_smp_status

        path = SMP_LEDGER_FOLDER / "accepted-smp-progress.json"
        ledger = json.loads((ROOT / path).read_text())
        synthetic = _synthetic_retired_smp_receipts(ROOT)
        with TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            synthesized_shas = {}
            for rel, payload in synthetic.items():
                target = root / rel
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(json.dumps(payload))
                synthesized_shas[rel] = digest(target)
            recorded = copy.deepcopy(ledger)
            recorded["originalInventory"] = {"path": SMP_ORIGINAL_INVENTORY, "sha256": synthesized_shas[SMP_ORIGINAL_INVENTORY]}
            recorded["receipts"]["gsc"] = {"path": _RETIRED_GSC_RECEIPT, "sha256": synthesized_shas[_RETIRED_GSC_RECEIPT]}
            accepted_path = recorded["accepted"]["path"]
            accepted_doc = json.loads((ROOT / accepted_path).read_text())
            accepted_doc["receipts"]["gsc"]["sha256"] = synthesized_shas[_RETIRED_GSC_RECEIPT]
            accepted_target = root / accepted_path
            accepted_target.parent.mkdir(parents=True, exist_ok=True)
            accepted_target.write_text(json.dumps(accepted_doc))
            recorded["accepted"]["sha256"] = digest(accepted_target)
            refs = [recorded["origin"]["path"]]
            refs.extend(ref["path"] for family, ref in recorded["receipts"].items() if family != "gsc")
            for name in refs:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes((ROOT / name).read_bytes())
            ledger_target = root / path
            ledger_target.parent.mkdir(parents=True, exist_ok=True)
            ledger_target.write_text(json.dumps(recorded))
            loaded = accepted_smp_status(root)
            self.assertEqual(loaded, recorded)
            self.assertEqual((loaded["originPassed"], loaded["passed"], loaded["remaining"]),
                             (1, 5, 7))
            self.assertTrue(loaded["sourceTree"].startswith("65a4a2e2"))
            self.assertEqual(loaded["closed"], ["bootstrap", "gsi", "gsc", "pr-gsi", "pr-gsc"])
            ledger_target.write_text(json.dumps(dict(recorded, passed=0, closed=[], remaining=12)))
            with self.assertRaisesRegex(ValueError, "disagrees"):
                accepted_smp_status(root)
            ledger_target.write_text(json.dumps(recorded))
            (root / recorded["receipts"]["gsi"]["path"]).write_text("{}")
            with self.assertRaisesRegex(ValueError, "identity changed"):
                accepted_smp_status(root)

    def test_numeric_window_requires_three_real_phases_and_original_assertions(self):
        from gambit_smp.suite_coverage import require_numeric_smp_evidence

        names = ("scheme-to-c", "c-to-dynamic-module", "compiled-execution")
        phases = [dict(phase=name, accepted=True, exit=0, timeout=False,
                       artifactSha256="a" * 64) for name in names]
        phases[-1]["originalAssertionsWitness"] = True
        group = dict(files=["03-number/_num.scm"], batch=0, shard=1,
                     sharedPhaseBudgetSeconds=90, compilerPhases=phases,
                     assertionProtocol="original-gsi-loader-and-assertion-witness")
        processes = [dict(stage="suite-0-1-" + name, effectiveBudgetSeconds=cap, seconds=seconds)
                     for name, cap, seconds in zip(names, (90, 70, 30), (20, 40, 1))]
        require_numeric_smp_evidence([group], processes)
        with self.assertRaisesRegex(ValueError, "budget"):
            require_numeric_smp_evidence([group], [dict(row, effectiveBudgetSeconds=90) for row in processes])
        with self.assertRaisesRegex(ValueError, "budget"):
            require_numeric_smp_evidence([group], [*processes[:2], dict(processes[2], seconds=31)])
        with self.assertRaisesRegex(ValueError, "process records"):
            require_numeric_smp_evidence([group], processes[:-1])
        phases[-1]["originalAssertionsWitness"] = False
        with self.assertRaisesRegex(ValueError, "assertion witness"):
            require_numeric_smp_evidence([group], processes)

    def test_current_projection_keeps_origin_and_refuses_regression(self):
        from gambit_smp.framework import digest
        from gambit_smp.suite_coverage import accepted_smp_progress, accepted_smp_status

        origin = "evidence/research/retained/modern-c/delivery-plan/current/smp-acceptance.json"
        historical = "evidence/research/retained/modern-c/frozen-568e0276-smp/indexed-acceptance.json"
        diagnostic = "evidence/research/retained/modern-c/frozen-568e0276-smp/env-index-acceptance.json"
        with _patch_retired_original_inventory(ROOT):
            result = accepted_smp_status(ROOT)
            self.assertEqual((result["originPassed"], result["passed"], result["remaining"]), (1, 5, 7))
            self.assertEqual(result["closed"], ["bootstrap", "gsi", "gsc", "pr-gsi", "pr-gsc"])
            accepted = result["accepted"]["path"]
            self.assertFalse(result["wholeSmpAdmitted"])
            with self.assertRaisesRegex(ValueError, "cannot replace the accepted prefix"):
                accepted_smp_progress(ROOT, origin, diagnostic, result)
            with self.assertRaisesRegex(ValueError, "cannot regress"):
                accepted_smp_progress(ROOT, origin, historical, result)
            with self.assertRaisesRegex(ValueError, "cannot regress"):
                accepted_smp_progress(ROOT, origin, accepted, dict(result, passed=6))
            packet = json.loads((ROOT / accepted).read_text())
            if all(digest(ROOT / name) == expected for name, expected in packet["modelInputs"].items()):
                self.assertEqual(accepted_smp_progress(ROOT, origin, accepted, result), result)
            else:
                with self.assertRaisesRegex(ValueError, "SMP model input changed"):
                    accepted_smp_progress(ROOT, origin, accepted, result)


class StressSmpEvidenceTests(unittest.TestCase):
    """Synthetic gate controls, never original native stress admission."""

    def setUp(self):
        from gambit_smp.suite_coverage import _load_smp_evidence
        self.load = _load_smp_evidence
        self.raw = json.loads((ROOT / "evidence/research/retained/modern-c/stress-gsi/native-result.json").read_text())

    def require(self, raw):
        from unittest.mock import patch
        from gambit_smp.suite_coverage import require_stress_smp_evidence
        ref = dict(path="synthetic-stress-transport.json", sha256="0" * 64)
        receipt = dict(raw, nativeReference=ref)
        def load(root, path, expected=None):
            return (raw, ref) if str(path) == ref["path"] else self.load(root, path, expected)
        with patch("gambit_smp.suite_coverage._load_smp_evidence", side_effect=load):
            require_stress_smp_evidence(ROOT, receipt)

    def synthetic_complete_transport(self):
        # Deliberately fabricated process outcomes test the verifier's positive
        # shape only. They are neither saved as evidence nor passed to ASCENT.
        raw = copy.deepcopy(self.raw)
        raw.update(complete=True, seconds=10)
        raw["topologies"] = [copy.deepcopy(raw["topologies"][0]) for _ in range(2)]
        raw["processes"] = []
        for run, population, jobs in zip(raw["topologies"], (2, 1), (3, 4)):
            run.update(processors=population, jobs=jobs, complete=True)
            run["request"].update(processors=population, jobs=jobs)
            run["probes"][1].update(expected=population, observed=f"PROCESSORS:{population}")
            for row in run["observations"]:
                row.update(accepted=True, exit=0, timeout=False, seconds=1,
                           observedFiles=list(row["files"]))
                raw["processes"].append(dict(topology=population,
                    stage=f"suite-{row['batch']}-{row['shard']}", exit=0, timeout=False,
                    seconds=1, effectiveBudgetSeconds=200,
                    parentReaped=True, processGroupQuiescent=True,
                    argv=["/synthetic/gsi", "-:p1", "-f", "run-unit-tests.scm", "-gsi", "-stress",
                          *["unit-tests/" + name for name in row["files"]]]))
        return raw

    def test_retained_original_failure_cannot_extend_accepted_five(self):
        from gambit_smp.suite_coverage import accepted_smp_status
        with self.assertRaisesRegex(ValueError, "complete raw campaign"):
            self.require(self.raw)
        with _patch_retired_original_inventory(ROOT):
            self.assertEqual(accepted_smp_status(ROOT)["passed"], 5)

    def test_synthetic_complete_shape_is_not_published_native_credit(self):
        self.require(self.synthetic_complete_transport())

    def test_cannot_relabel_failed_or_unstarted_work_as_complete(self):
        raw = copy.deepcopy(self.raw)
        raw.update(complete=True, seconds=10)
        with self.assertRaisesRegex(ValueError, "topology is incomplete"):
            self.require(raw)

    def test_rejects_changed_budget_inputs_topology_mode_and_unsettled_child(self):
        def missing_topology(r): r["topologies"].pop()
        def missing_file(r): r["topologies"][0]["observations"][0]["observedFiles"].pop()
        def bad_input(r): r["testInputFiles"]["unit-tests/06-thread/tfib_stress.scm"] = "0" * 64
        def missing_assertion_helper(r): r["testInputFiles"].pop("unit-tests/#.scm")
        def longer_budget(r): r["wholeBudgetSeconds"] = 1800
        def spliced(r): r["observationsSpliced"] = True
        def compiled(r): r["processes"][0]["argv"][4] = "-gsc"
        def unresolved(r): r["processes"][0]["processGroupQuiescent"] = None
        def duplicate_command(r): r["processes"].append(copy.deepcopy(r["processes"][0]))
        def progress_renewal(r): r["topologies"][0]["request"]["childProgressSeconds"] = 300
        for mutate in (missing_topology, missing_file, bad_input, missing_assertion_helper, longer_budget, spliced,
                       compiled, unresolved, duplicate_command, progress_renewal):
            with self.subTest(mutation=mutate.__name__):
                raw = self.synthetic_complete_transport()
                mutate(raw)
                with self.assertRaises(ValueError):
                    self.require(raw)


class PrSmpEvidenceTests(unittest.TestCase):
    """Synthetic tampering controls; only the retained native campaign grants credit."""
    def setUp(self):
        from gambit_smp.suite_coverage import _load_smp_evidence
        self.load = _load_smp_evidence
        self.receipt = json.loads((ROOT / "evidence/research/retained/modern-c/pr-gsi/qualified-native.json").read_text())

    def test_whole_declared_pr_population_has_both_actual_topologies(self):
        from gambit_smp.suite_coverage import require_pr_smp_evidence
        require_pr_smp_evidence(ROOT, self.receipt)

    def test_tampered_complete_raw_campaign_cannot_hide_missing_obligations(self):
        from unittest.mock import patch
        from gambit_smp.suite_coverage import require_pr_smp_evidence
        def missing_population(v):
            v["topologies"].pop()
        def missing_case(v):
            v["topologies"][0]["observations"].pop()
        def longer_guard(v):
            v["topologies"][0]["request"]["fileBudgetSeconds"]["06-thread/thread_interrupt_ended.scm"] = 21
        def false_topology(v):
            v["topologies"][1]["probes"][1]["observed"] = "PROCESSORS:1"
        def wrong_constructor(v):
            v["testInputFiles"]["unit-tests/06-thread/thread_interrupt_ended.scm"] = "0" * 64
        def wrong_producer(v):
            v["producerSha256"] = "0" * 64
        def incomplete(v):
            v["complete"] = False
        for mutate in [missing_population, missing_case, longer_guard, false_topology,
                       wrong_constructor, wrong_producer, incomplete]:
            receipt = copy.deepcopy(self.receipt)
            mutate(receipt)
            raw = {k: v for k, v in receipt.items()
                   if k not in {"nativeReference", "modelBindingSha256"}}
            def load(root, path, expected=None):
                if str(path) == receipt["nativeReference"]["path"]:
                    return raw, receipt["nativeReference"]
                return self.load(root, path, expected)
            with self.subTest(mutation=mutate.__name__), \
                 patch("gambit_smp.suite_coverage._load_smp_evidence", side_effect=load):
                with self.assertRaises(ValueError):
                    require_pr_smp_evidence(ROOT, receipt)

    def test_relabeling_the_failed_legacy_campaign_cannot_grant_credit(self):
        from gambit_smp.framework import digest
        from gambit_smp.suite_coverage import require_pr_smp_evidence
        receipt = copy.deepcopy(self.receipt)
        path = "evidence/research/retained/modern-c/pr-gsi/legacy-request-failure.json"
        receipt["nativeReference"] = dict(path=path, sha256=digest(ROOT / path))
        with self.assertRaises(ValueError):
            require_pr_smp_evidence(ROOT, receipt)

    def test_remainder_correction_preserves_every_native_and_model_fact(self):
        from gambit_smp.suite_coverage import accepted_smp_progress, accepted_smp_status
        current = json.loads((ROOT / "evidence/research/retained/modern-c/pr-gsc/previous-accepted-smp-progress.json").read_text())
        packet = json.loads((ROOT / current["accepted"]["path"]).read_text())
        previous = dict(current, accepted=packet["metadataCorrectionOf"])
        # The historical correction preserves facts; admission under a later
        # model epoch must still fail instead of rewriting old credentials.
        before = json.loads((ROOT / packet["metadataCorrectionOf"]["path"]).read_text())
        self.assertEqual({k:v for k,v in before.items() if k != "currentRemaining"},
                         {k:v for k,v in packet.items() if k not in {"currentRemaining", "metadataCorrectionOf"}})
        from gambit_smp.framework import digest
        if any(digest(ROOT / name) != expected for name,expected in packet["modelInputs"].items()):
            with self.assertRaisesRegex(ValueError, "SMP model input changed"):
                accepted_smp_progress(ROOT, "evidence/research/retained/modern-c/delivery-plan/current/smp-acceptance.json",
                                     current["accepted"]["path"], previous)
        else:
            self.assertEqual(accepted_smp_progress(ROOT,
                "evidence/research/retained/modern-c/delivery-plan/current/smp-acceptance.json",
                current["accepted"]["path"], previous), current)

    def test_metadata_correction_cannot_replace_native_facts(self):
        from unittest.mock import patch
        from gambit_smp.suite_coverage import accepted_smp_progress, accepted_smp_status
        current = json.loads((ROOT / "evidence/research/retained/modern-c/pr-gsc/previous-accepted-smp-progress.json").read_text())
        packet = json.loads((ROOT / current["accepted"]["path"]).read_text())
        previous = dict(current, accepted=packet["metadataCorrectionOf"])
        packet["receipts"]["pr-gsi"]["sha256"] = "0" * 64
        def load(root, path, expected=None):
            if str(path) == "synthetic-correction.json":
                return packet, dict(path=str(path), sha256="1" * 64)
            return self.load(root, path, expected)
        with patch("gambit_smp.suite_coverage._load_smp_evidence", side_effect=load):
            with self.assertRaisesRegex(ValueError, "cannot regress or replace"):
                accepted_smp_progress(
                    ROOT, "evidence/research/retained/modern-c/delivery-plan/current/smp-acceptance.json",
                    "synthetic-correction.json", previous)


class CompiledPrSmpEvidenceTests(unittest.TestCase):
    """The same PR invariants, with independent compiled-command controls."""
    def setUp(self):
        from gambit_smp.suite_coverage import _load_smp_evidence
        self.load = _load_smp_evidence
        self.receipt = json.loads((ROOT / "evidence/research/retained/modern-c/pr-gsc/qualified-published-native.json").read_text())

    test_whole_declared_pr_population_has_both_actual_topologies = PrSmpEvidenceTests.test_whole_declared_pr_population_has_both_actual_topologies
    test_tampered_complete_raw_campaign_cannot_hide_missing_obligations = PrSmpEvidenceTests.test_tampered_complete_raw_campaign_cannot_hide_missing_obligations
    test_relabeling_the_failed_legacy_campaign_cannot_grant_credit = PrSmpEvidenceTests.test_relabeling_the_failed_legacy_campaign_cannot_grant_credit

    def test_historical_source_uses_published_commit_and_rejects_record_drift(self):
        from unittest.mock import patch
        from gambit_smp.suite_coverage import _published_pr_source
        import hashlib
        path = "evidence/research/retained/modern-c/pr-gsi/submission/source.json"
        proof = json.loads((ROOT / "evidence/research/retained/modern-c/pr-gsi/request-constructor-refinement.json").read_text())
        original = _published_pr_source(ROOT, path, proof["projectionSource"], proof["projectionSha256"])
        self.assertEqual(hashlib.sha256(original).hexdigest(), proof["projectionSha256"])
        def stale_record(root, name, expected=None):
            value, identity = self.load(root, name, expected)
            return (value, dict(identity, sha256="0" * 64)) if str(name) == path else (value, identity)
        with patch("gambit_smp.suite_coverage._load_smp_evidence", side_effect=stale_record):
            with self.assertRaisesRegex(ValueError, "published epoch"):
                _published_pr_source(ROOT, path, proof["projectionSource"], proof["projectionSha256"])

    def test_compilation_commands_group_guard_and_lifetime_proof_are_mandatory(self):
        from unittest.mock import patch
        from gambit_smp.suite_coverage import require_pr_smp_evidence
        def interpreted_command(value):
            next(p for p in value["processes"] if p["stage"].startswith("suite-"))["argv"][4] = "-gsi"
        def missing_command(value):
            value["processes"].remove(next(p for p in value["processes"] if p["stage"].startswith("suite-")))
        def duplicate_command(value):
            value["processes"].append(copy.deepcopy(next(p for p in value["processes"] if p["stage"].startswith("suite-"))))
        def missing_group(value):
            value["topologies"][0]["request"].pop("groupBudgetSeconds")
        def longer_group(value):
            value["topologies"][0]["request"]["groupBudgetSeconds"]["thread-completion"]["budgetSeconds"] = 121
        def lost_lifetime_proof(value):
            value.pop("controlRefinement")
        def wrong_mode(value):
            value["mode"] = "gsi"
        def wrong_publication(value):
            value["publicationSource"] = dict(repository="vendor/gambit",
                revision=value["baselineRevision"], path="tests/unit-tests/06-thread/thread_interrupt.scm")
        def longer_command(value):
            next(p for p in value["processes"] if p["stage"].startswith("suite-"))["effectiveBudgetSeconds"] = 301
        for mutate in [interpreted_command, missing_command, duplicate_command,
                       missing_group, longer_group, lost_lifetime_proof, wrong_mode, wrong_publication,
                       longer_command]:
            receipt = copy.deepcopy(self.receipt)
            mutate(receipt)
            raw = {k:v for k,v in receipt.items() if k != "nativeReference"}
            def load(root, path, expected=None):
                if str(path) == receipt["nativeReference"]["path"]:
                    return raw, receipt["nativeReference"]
                return self.load(root, path, expected)
            with self.subTest(mutation=mutate.__name__), \
                    patch("gambit_smp.suite_coverage._load_smp_evidence", side_effect=load):
                with self.assertRaises(ValueError):
                    require_pr_smp_evidence(ROOT, receipt)

    def test_lifetime_projection_retains_the_source_and_refuses_reapplication(self):
        from gambit_smp.suite_primitives import thread_interrupt_lifetime_fixture
        from gambit_smp.task_processes import check_output
        proof = self.receipt["controlRefinement"]
        original = check_output(["git", "-C", ROOT / "vendor/gambit", "show",
                                 proof["originalRevision"] + ":tests/unit-tests/" + proof["target"]], timeout=10)
        projected = thread_interrupt_lifetime_fixture(original)
        publication = self.receipt.get("publicationSource")
        delivered = (check_output(["git", "-C", ROOT / "vendor/gambit", "show",
                                  publication["revision"] + ":" + publication["path"]], timeout=10)
                     if publication else (ROOT / proof["source"]).read_bytes())
        self.assertEqual(projected, delivered)
        for invalid in [projected, original + original,
                        original.replace(b"(test-equal 11 var)", b"(test-equal 12 var)")]:
            with self.subTest(invalid=hash(invalid)), self.assertRaises(ValueError):
                thread_interrupt_lifetime_fixture(invalid)


class SuiteCoverageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        recipe = json.loads((ROOT/"evidence/research/retained/modern-c/pr-gsc/framework-fixtures/dynamic-modulo-interpreted.recipe.json").read_text())
        cls.fixtures = next(row for row in recipe["steps"] if row["capability"]=="gambit.suite")["arguments"]["additionalFixtures"]
        cls.catalog = load_catalog(
            ROOT/"evidence/research/retained/modern-c/pr-gsc/framework-fixtures/compiled-coverage-rules.ss",
            ROOT/"evidence/research/retained/modern-c/pr-gsc/framework-fixtures/pr-regression-requirements.ss")

    def receipt(self):
        files = sorted(self.fixtures)
        step = {"id":"native-gsc","capability":"gambit.suite","outcome":"PASS","mode":"gsc",
                "arguments":{"mode":"gsc","inventory":"unit","selection":["."],
                             "regime":"whole-parallel","expectedFiles":files,
                             "additionalFixtures":self.fixtures},
                "passedFiles":files,"suiteGroups":[{"files":files,"accepted":True,"exit":0,"timeout":False}],
                "artifacts":{"native-gsc/runtime/tests/unit-tests/"+file:row["sha256"]
                             for file,row in self.fixtures.items()}}
        return {"steps":[step]}

    def evaluate(self, receipt):
        return query(project_suite_files(receipt),self.catalog,
                     {"qualified":"qualified_suite_gate","missing":"pr_missing_file"})

    def test_checked_files_derive_scope_without_fabricating_observed_steps(self):
        facts = project_suite_files(self.receipt())
        self.assertNotIn("observed_step",facts)
        self.assertEqual(len(self.fixtures),len(facts["observed_suite_file"]))
        answer = self.evaluate(self.receipt())
        self.assertEqual([],answer["missing"])
        self.assertEqual({("complete-gsc","native-gsc"),("pr-regressions-gsc","native-gsc")},
                         set(answer["qualified"]))

    def test_pass_name_model_pass_and_denied_execution_do_not_qualify(self):
        for change in ({"passedFiles":None},{"capability":"quint.verify"},{"outcome":"DENY"}):
            receipt = self.receipt()
            if change=={"passedFiles":None}:
                del receipt["steps"][0]["passedFiles"]
            else:
                receipt["steps"][0].update(change)
            self.assertEqual([],self.evaluate(receipt)["qualified"])

    def test_suite_identifier_is_opaque_not_a_qualification_selector(self):
        for name in ("source-032", "source-999", "semantic-candidate"):
            receipt = self.receipt()
            step = receipt["steps"][0]
            step["id"] = name
            step["artifacts"] = {key.replace("native-gsc/", name+"/", 1): value
                                 for key, value in step["artifacts"].items()}
            self.assertEqual({("complete-gsc",name),("pr-regressions-gsc",name)},
                             set(self.evaluate(receipt)["qualified"]))

    def test_missing_pr_fixture_leaves_pr_gate_open(self):
        receipt = self.receipt()
        step = receipt["steps"][0]
        removed = step["passedFiles"][0]
        remaining = [file for file in step["passedFiles"] if file!=removed]
        step["passedFiles"] = step["arguments"]["expectedFiles"] = remaining
        step["suiteGroups"][0]["files"] = remaining
        answer = self.evaluate(receipt)
        self.assertEqual([("native-gsc",removed)],answer["missing"])
        self.assertEqual([("complete-gsc","native-gsc")],answer["qualified"])

    def test_changed_fixture_or_failed_group_rejects_projection(self):
        for fault in ("fixture","group","inventory"):
            receipt = self.receipt()
            step = receipt["steps"][0]
            if fault=="fixture":
                step["artifacts"][next(iter(step["artifacts"]))]="0"*64
            elif fault=="group":
                step["suiteGroups"][0]["timeout"]=True
            else:
                step["suiteGroups"][0]["files"] = step["passedFiles"][:-1]
            with self.subTest(fault=fault),self.assertRaises(ValueError):
                project_suite_files(receipt)

    def test_phased_case_requires_all_artifacts_original_loader_and_window(self):
        receipt = self.receipt()
        step = receipt["steps"][0]
        files = step["passedFiles"]
        step["arguments"].update(compilerPhaseFiles=[files[0]],fileBudgetSeconds={files[0]:90})
        phase_group = {"files":[files[0]],"accepted":True,"exit":0,"timeout":False,
                       "phaseInactivitySeconds":90,"assertionProtocol":"original-gsi-loader-and-unit-test-exit",
                       "compilerPhases":[{"phase":name,"accepted":True,"exit":0,"timeout":False,
                                          "artifactSha256":"a"*64 if index<2 else None}
                                         for index,name in enumerate(("scheme-to-c","c-to-dynamic-module","compiled-execution"))]}
        step["suiteGroups"] = [phase_group,{"files":files[1:],"accepted":True,"exit":0,"timeout":False}]
        self.assertTrue(project_suite_files(receipt)["observed_suite_file"])
        for fault in ("window","loader","missing","assertions"):
            mutated = copy.deepcopy(receipt)
            group = mutated["steps"][0]["suiteGroups"][0]
            if fault=="window": group["phaseInactivitySeconds"]=180
            elif fault=="loader": group["assertionProtocol"]="diagnostic-entry"
            elif fault=="missing": group["compilerPhases"][0]["artifactSha256"]=None
            else: group["compilerPhases"][2]["exit"]=1
            with self.subTest(fault=fault),self.assertRaises(ValueError):
                project_suite_files(mutated)
