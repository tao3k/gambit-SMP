"""Publication is selected evidence, not a copy of a run directory."""
import json
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
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

    def test_compressed_inputs_and_aliases_cannot_be_evidence(self):
        from gambit_smp.framework import relative
        from gambit_smp.research_audit import local
        from gambit_smp.reflection import validate as reflection
        with TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            archive = root / 'raw.GZ'
            archive.write_bytes(b'compressed raw output')
            (root / 'report.json').symlink_to(archive)
            for name in ('raw.GZ', 'report.json'):
                for reader in (relative, local):
                    with self.subTest(reader=reader.__name__, name=name):
                        with self.assertRaisesRegex(ValueError, 'not evidence'):
                            reader(root, name)
                record = {'schema': 'gambit-evidence-reflection.v1',
                          'references': [{'id': 'raw', 'kind': 'observation',
                                          'path': name, 'locator': 'raw', 'scope': 'local'}],
                          'requirements': [{'id': 'gap', 'status': 'open', 'gap': 'unproved',
                                            'conditions': ['structured observation'],
                                            'references': ['raw']}]}
                with self.assertRaisesRegex(ValueError, 'not evidence'):
                    reflection(root, record)
                validate(root, root / ('evidence/' + name), deleting=True)
            with self.assertRaises(StoragePolicyError):
                validate(root, root / 'evidence/raw.GZ')
            validate(root, root / '.cache/raw.GZ')

    def test_compressed_archives_are_absent_from_evidence_and_git_index(self):
        files = [str(p.relative_to(ROOT)) for p in (ROOT / 'evidence').rglob('*')
                 if p.is_file() and p.suffix.casefold() == '.gz']
        self.assertEqual([], files)
        indexed = subprocess.check_output(['git', '-C', str(ROOT), 'ls-files', '-z'])
        self.assertEqual([], [p for p in indexed.decode().split('\0')
                              if Path(p).suffix.casefold() == '.gz'])
        ignored = subprocess.check_output(
            ['git', '-C', str(ROOT), 'check-ignore', 'evidence/study/raw.gz', 'raw.gz'])
        self.assertEqual(['evidence/study/raw.gz', 'raw.gz'], ignored.decode().splitlines())

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
