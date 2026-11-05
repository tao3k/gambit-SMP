"""One real host witness flows through Scheme, Clue delta and a new owner."""
from importlib.resources import files
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

from ascent import Engine
from ascent.trajectory import ClueExchange
from gambit_smp import ascent_program
from gambit_smp.framework import ROOT
from tests import test_research_resumption


def read_fixture(request):
    source = files("ascent").joinpath("checkpoint_rules.ss").read_text()
    projection = (ROOT / "tests/fixtures/checkpoint-clue-projection.ss").read_text()
    execution = (ROOT / "evidence/dsl/checkpoint.ss").read_text()
    engine = Engine()
    attestations = {row[0]: row[0] for row in request["facts"]["receipt"]}
    attestations.update({row[3]: row[3] for row in request['facts'].get('execution_sample', [])})
    owner = ClueExchange(engine, [source, execution, projection], "project-checkpoint", request["facts"], attestations)
    try:
        if "checkpoint" in request:
            return owner.slice({"checkpoint": request["checkpoint"]})
        return owner.slice_selected([projection], "select-checkpoint",
                                    {"bindings": request.get('bindings', [["requirement", "producer"]])})
    finally:
        owner.close()


class CheckpointEvidenceExchangeTests(unittest.TestCase):
    def test_live_progress_reaches_first_clue_and_unchanged_checkpoint_reuses_it(self):
        from tests.test_stage_journal_checkpoint import StageJournalCheckpointTests
        from gambit_smp.research_kernel import inspect, process_recorder
        fixture = StageJournalCheckpointTests()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        fixture.retained_run(step_budgets={'seed': 5, 'bootstrap': 5})
        (fixture.run/'receipt.json').unlink()
        reference = json.loads((fixture.run/'run/seed.observation.json').read_text())['header']
        record = process_recorder(fixture.root, fixture.run, reference)
        emitted = {}
        original = ascent_program.query

        def observe(facts, *args, **kwargs):
            emitted.update(facts)
            return original(facts, *args, **kwargs)

        record('planned', 'native-fixture', {'cwd': str(fixture.run/'run/bootstrap'), 'argv': ['fixture']})
        record('started', 'native-fixture', {'pid': 12345})
        record('progress', 'native-fixture', {'count': 2, 'observedMonotonic': 20., 'witness': None})
        with patch('gambit_smp.ascent_program.query', side_effect=observe), \
                patch('gambit_smp.process_observation.probe_group', return_value=(False, ('present',))):
            state = inspect(fixture.run)['resumption']
        first = read_fixture(dict(facts=emitted, bindings=[['requirement', 'bootstrap']]))
        self.assertEqual(['bootstrap'], [row['claim'] for row in first['brief']['families']])
        code = ('import json,sys; from tests.test_checkpoint_evidence_exchange import read_fixture; '
                'print(json.dumps(read_fixture(json.load(sys.stdin))))')
        child = subprocess.run([sys.executable, '-c', code], input=json.dumps(
            dict(facts=emitted, checkpoint=first['checkpoint'])), text=True,
            capture_output=True, timeout=30, check=True)
        self.assertEqual([], json.loads(child.stdout)['brief']['families'])
        self.assertFalse(state['executionAuthorized'])
        self.assertFalse(state['runtimeAdmitted'])
        self.assertFalse((fixture.run/'receipt.json').exists())

    def test_real_omission_reaches_first_query_and_fresh_process_delta(self):
        fixture = test_research_resumption.ResearchResumptionTests()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        emitted = {}
        original = ascent_program.query

        def observe(facts, *args, **kwargs):
            if "support_declaration" in facts:
                emitted.clear()
                emitted.update(facts)
            return original(facts, *args, **kwargs)

        with patch("gambit_smp.ascent_program.query", side_effect=observe):
            self.assertTrue(fixture.state()["relations"]["reusable"])
        first = read_fixture({"facts": emitted})
        self.assertEqual([f["claim"] for f in first["brief"]["families"]], ["producer"])

        fixture.outer["inputs"] = {}
        fixture.child["steps"][0]["commands"] = []
        fixture.save(attest=False)
        with patch("gambit_smp.ascent_program.query", side_effect=observe):
            state = fixture.state()
        self.assertEqual(state["relations"]["reusable"], [])
        self.assertTrue(state["relations"]["enumeration_gap"])
        code = ("import json,sys; from tests.test_checkpoint_evidence_exchange import read_fixture; "
                "print(json.dumps(read_fixture(json.load(sys.stdin))))")
        request = {"facts": emitted, "checkpoint": first["checkpoint"]}
        child = subprocess.run([sys.executable, "-c", code], input=json.dumps(request),
                               text=True, capture_output=True, timeout=30, check=True)
        changed = json.loads(child.stdout)
        self.assertEqual(changed["brief"]["mode"], "refresh")
        self.assertTrue(changed["brief"]["families"])
        request["checkpoint"] = changed["checkpoint"]
        child = subprocess.run([sys.executable, "-c", code], input=json.dumps(request),
                               text=True, capture_output=True, timeout=30, check=True)
        resumed = json.loads(child.stdout)
        self.assertEqual(resumed["brief"]["families"], [])
        self.assertFalse(state["executionAuthorized"])


if __name__ == "__main__":
    unittest.main()
