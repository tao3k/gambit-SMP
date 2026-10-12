"""Synthetic tamper controls for historical fixture identity, not evidence."""
import json
from pathlib import Path
import tempfile
import unittest

from gambit_smp.framework import digest
from tests.fixture_history import historical_observation


class FixtureHistoryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.original = "models/original.qnt"
        self.archive = "evidence/frozen.qnt"
        self.live = "models/live.qnt"
        self.observation = "evidence/source-results/fixtures/example/observation.json"
        self.index = "evidence/source-results/fixture-history/inputs.json"
        self.write(self.original, "new source")
        self.write(self.archive, "old source")
        self.write(self.live, "unchanged source")
        self.summary = {"runtimeAdmitted": False, "inputs": {
            self.original: digest(self.root / self.archive),
            self.live: digest(self.root / self.live)}}
        self.write(self.observation, json.dumps(self.summary))
        self.record = {"schema": "gambit-historical-fixture-inputs.v1",
            "runtimeAdmitted": False, "fixtures": {"example": {
                "observationSha256": digest(self.root / self.observation),
                "archives": {self.original: self.archive}}}}
        self.save_index()

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def save_index(self):
        self.write(self.index, json.dumps(self.record))

    def test_exact_archive_does_not_assert_current_source_admission(self):
        self.assertEqual(self.summary, historical_observation(self, "example", self.root))
        self.assertNotEqual(digest(self.root / self.original), digest(self.root / self.archive))

    def test_original_observation_tamper_rejected(self):
        self.write(self.observation, json.dumps(self.summary) + " ")
        with self.assertRaisesRegex(AssertionError, "original observation changed"):
            historical_observation(self, "example", self.root)

    def test_archived_input_tamper_rejected(self):
        self.write(self.archive, "not the old source")
        with self.assertRaises(AssertionError):
            historical_observation(self, "example", self.root)

    def test_unlisted_current_input_drift_rejected(self):
        self.write(self.live, "unapproved source change")
        with self.assertRaises(AssertionError):
            historical_observation(self, "example", self.root)

    def test_archive_escape_rejected(self):
        self.record["fixtures"]["example"]["archives"][self.original] = "../outside.qnt"
        self.save_index()
        with self.assertRaises(AssertionError):
            historical_observation(self, "example", self.root)

    def test_historical_runtime_admission_rejected(self):
        self.summary["runtimeAdmitted"] = True
        self.write(self.observation, json.dumps(self.summary))
        self.record["fixtures"]["example"]["observationSha256"] = digest(self.root / self.observation)
        self.save_index()
        with self.assertRaises(AssertionError):
            historical_observation(self, "example", self.root)
