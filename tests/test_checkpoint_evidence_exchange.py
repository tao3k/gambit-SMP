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
    engine = Engine()
    attestations = {row[0]: row[0] for row in request["facts"]["receipt"]}
    owner = ClueExchange(engine, [source, projection], "project-checkpoint", request["facts"], attestations)
    try:
        if "checkpoint" in request:
            return owner.slice({"checkpoint": request["checkpoint"]})
        return owner.slice_selected([projection], "select-checkpoint",
                                    {"bindings": [["requirement", "producer"]]})
    finally:
        owner.close()


class CheckpointEvidenceExchangeTests(unittest.TestCase):
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
