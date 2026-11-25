"""Empty containers are recoverable; evidence-bearing attempts remain closed."""
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import research_kernel as kernel


class ResearchOutputAllocationTests(unittest.TestCase):
    def test_empty_container_is_adopted_without_replacing_its_inode(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / 'run'
            out.mkdir()
            identity = out.stat().st_ino
            result = kernel.allocate_run_directory(out)
            self.assertEqual(result['state'], 'adopted-empty')
            self.assertEqual(result['inode'], identity)
            self.assertFalse(result['priorBytesRemoved'])
            self.assertFalse(result['nativeResultReused'])

    def test_new_container_and_nonempty_or_alias_controls(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            out = root / 'run'
            self.assertEqual(kernel.allocate_run_directory(out)['state'], 'created')
            evidence = out / 'failed-diagnostic'
            evidence.write_bytes(b'preserve failed evidence')
            with self.assertRaisesRegex(ValueError, 'non-empty'):
                kernel.allocate_run_directory(out)
            self.assertEqual(evidence.read_bytes(), b'preserve failed evidence')
            alias = root / 'alias'
            alias.symlink_to(out, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, 'alias'):
                kernel.allocate_run_directory(alias)

    def test_read_exposes_repair_context_without_execution_authority(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            out = root / 'run'
            with patch('gambit_smp.artifact_storage.repository_root', return_value=root), \
                    patch('gambit_smp.reasoning_history.read_execution_checkpoint', return_value={'records': []}):
                for expected in ('absent', 'empty', 'unbound-content'):
                    observed = kernel.inspect(out)
                    self.assertEqual(observed['allocationState'], expected)
                    self.assertFalse(observed['executionAuthorized'])
                    self.assertFalse(observed['executionLaunched'])
                    self.assertEqual(observed['repairContext']['emptyContainerReusable'],
                                     expected in {'absent', 'empty'})
                    if expected == 'absent':
                        out.mkdir()
                    elif expected == 'empty':
                        (out / 'unknown-evidence').write_text('retain')
