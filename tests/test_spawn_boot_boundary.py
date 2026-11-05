"""A reboot settles process lifetime, never source/artifact or exit evidence."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from gambit_smp import spawn_protocol, task_processes


class SpawnBootBoundaryTests(unittest.TestCase):
    def test_prior_boot_needs_no_replacement_custody_file(self):
        row={'spawnProtocol':{'bootId':'previous','directory':'missing'}}
        with patch('gambit_smp.process_identity.boot_id',return_value='current'):
            result=spawn_protocol.reconcile(Path('/'),row)
        self.assertEqual('prior-boot-process-ended',result['result'])
        self.assertIsNone(result['targetExecuted'])
        self.assertFalse(result['outputsAdmitted'])
        self.assertFalse(result['replayAuthorized'])

    def test_same_boot_replacement_is_still_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);(root/'custody.lock').touch()
            row={'spawnProtocol':{'bootId':'current','directory':'.','lockIdentity':[-1,-1]}}
            with patch('gambit_smp.process_identity.boot_id',return_value='current'):
                with self.assertRaisesRegex(ValueError,'custody identity changed'):
                    spawn_protocol.reconcile(root,row)

    def test_old_numeric_group_is_not_probed_or_replayed(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);directory=root/'.state/task-processes/task/run';directory.mkdir(parents=True)
            row={'event':'finished','token':'child','pgid':123,'spawnProtocol':{'bootId':'previous','directory':'missing'}}
            (directory/'child.json').write_text(json.dumps(row))
            with patch('gambit_smp.process_identity.boot_id',return_value='current'),patch.object(task_processes,'observe_group') as group:
                self.assertEqual(['child'],task_processes.check(root,'task'))
                self.assertEqual(['child'],task_processes.check(root,'task'))
                group.assert_not_called()
            result=json.loads((directory/'child.json').read_text())
            self.assertEqual(row['spawnProtocol'],result['spawnProtocol'])
            self.assertFalse(result['spawnQuiescence']['outputsAdmitted'])

    def test_boot_closure_cannot_grant_output_admission(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);directory=root/'.state/task-processes/task/run';directory.mkdir(parents=True)
            protocol={'bootId':'previous','directory':'missing'}
            row={'event':'finished','token':'child','spawnProtocol':protocol,
                 'spawnQuiescence':{'method':'kernel-boot-boundary-no-output-admission','protocol':protocol,
                   'previousBootId':'previous','currentBootId':'current','outputsAdmitted':True,'replayAuthorized':False}}
            (directory/'child.json').write_text(json.dumps(row))
            with self.assertRaisesRegex(ValueError,'non-admitting boot closure'):
                task_processes.check(root,'task')
