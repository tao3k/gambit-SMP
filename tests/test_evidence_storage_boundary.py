"""Publication is selected evidence, not a copy of a run directory."""
import json
from pathlib import Path
import subprocess
import unittest

from gambit_smp.framework import ROOT
from gambit_smp.storage_policy import EVIDENCE_CACHE_SUFFIXES, StoragePolicyError, validate


class EvidenceStorageBoundaryTests(unittest.TestCase):
    def test_generated_suffixes_are_rejected_even_without_task_scope(self):
        for suffix in EVIDENCE_CACHE_SUFFIXES:
            for name in ('evidence/study/result', '.data/worktrees/owner/evidence/study/result'):
                with self.subTest(name=name, suffix=suffix):
                    with self.assertRaises(StoragePolicyError):
                        validate(ROOT, ROOT / (name + suffix))
                    validate(ROOT, ROOT / (name + suffix), deleting=True)
                    validate(ROOT, ROOT / ('.cache/history/result' + suffix))
        for suffix in ('.md', '.org', '.json', '.ss', '.qnt', '.lean'):
            validate(ROOT, ROOT / ('evidence/study/source' + suffix))

    def test_checkout_and_index_contain_no_mixed_run_assets(self):
        files = [str(p.relative_to(ROOT)) for p in (ROOT / 'evidence').rglob('*')
                 if p.is_file() and p.suffix.casefold() in EVIDENCE_CACHE_SUFFIXES]
        self.assertEqual([], sorted(files))
        indexed = subprocess.check_output(['git', '-C', str(ROOT), 'ls-files', '-z', 'evidence'])
        self.assertEqual([], [p for p in indexed.decode().split('\0')
                              if Path(p).suffix.casefold() in EVIDENCE_CACHE_SUFFIXES])

    def test_current_publication_inventories_do_not_bind_cache_suffixes(self):
        for path in (ROOT / 'evidence').rglob('evidence-bindings.json'):
            with self.subTest(path=str(path.relative_to(ROOT))):
                records = json.loads(path.read_text())
                self.assertEqual([], [name for name in records
                    if Path(name).suffix.casefold() in EVIDENCE_CACHE_SUFFIXES])
