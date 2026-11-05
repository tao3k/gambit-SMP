"""Only explicitly selected, byte-bound replay evidence is durable."""
import json
from pathlib import Path
import re
import subprocess
import unittest

from gambit_smp.framework import ROOT, digest


class PublishedEvidenceTests(unittest.TestCase):
    def test_registered_observations_are_typed_data_not_log_file_dependencies(self):
        from gambit_smp.output_observations import validate, TRANSCRIPT_SUFFIXES
        manifest = json.loads((ROOT/'evidence/published-inputs.json').read_text())
        self.assertTrue(manifest['observations'])
        for identity, observation in manifest['observations'].items():
            self.assertEqual(identity, observation['sha256'])
            for name in observation['origins']:
                self.assertIn(Path(name).suffix.casefold(), TRANSCRIPT_SUFFIXES)
                self.assertFalse((ROOT/name).exists(), name)
            validate(observation)
            self.assertFalse({'text', 'stdout', 'stderr', 'rawText', 'lines'} & observation.keys())

    def test_selected_replay_material_is_tracked_exact_and_nonadmitting(self):
        manifest = json.loads((ROOT / 'evidence/published-inputs.json').read_text())
        self.assertEqual(manifest['schema'], 'published-evidence-inputs.v1')
        self.assertIs(manifest['runtimeAdmitted'], False)
        self.assertIs(manifest['sourceRefinementAdmitted'], False)
        tracked = set(subprocess.check_output(
            ['git', '-C', str(ROOT), 'ls-files', '-z']).decode().split('\0'))
        self.assertTrue(manifest['records'])
        for name, record in manifest['records'].items():
            with self.subTest(path=name):
                self.assertIn(name, tracked)
                self.assertTrue(name.startswith(('evidence/model-results/', 'evidence/source-results/')))
                self.assertFalse(set(Path(name).parts) & {'.data', '.cache', '..'})
                path = ROOT / name
                self.assertEqual(path.resolve(strict=True), path)
                self.assertEqual(digest(path), record['sha256'])
                self.assertTrue(record['purpose'])
                raw = path.read_bytes()
                self.assertNotIn(b'/Users/', raw)
                self.assertIsNone(re.search(
                    rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|AKIA[A-Z0-9]{16}|-----BEGIN (?:RSA |OPENSSH )?PRIVATE KEY-----)',
                    raw))
