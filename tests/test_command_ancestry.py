"""Reused stage history is authenticated ancestry, never a fresh launch."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import step_checkpoint as checkpoint
from gambit_smp.framework import digest
from gambit_smp.research_kernel import content_id


class CommandAncestryTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name); self.run = self.root/'origin'; (self.run/'run').mkdir(parents=True)
        self.original = dict(id='configure', capability='gambit.configure', arguments={'source': 'bound'},
                             dependsOn=['candidate'], commands=[{'stage':'configure','argv':['gcc-bound']}],
                             outcome='PASS', journal={'path':'authenticated-observation'})
        self.row = {k: copy.deepcopy(self.original[k]) for k in ('id','capability','arguments','dependsOn')}
        self.row.update(executionLaunched=False, originCommands=self.original['commands'],
                        reused={'run':'bound-run','step':'configure','receipt':content_id(
                            {k:v for k,v in self.original.items() if k!='journal'})})
        self.path = self.run/'run/receipt.json'
        self.path.write_text(json.dumps({'steps':[self.original]}))
        self.outer = {'childReceiptSha256':digest(self.path)}
        self.closure = [{k:v for k,v in self.original.items() if k!='journal'}]

    def read(self):
        with patch.object(checkpoint,'fixture_path',return_value=self.run), \
             patch.object(checkpoint,'observe_journal',return_value=({},self.outer,self.closure,{})):
            return checkpoint.stage_commands(self.root,self.row)

    def test_authentic_origin_is_read_without_changing_execution_marker(self):
        self.assertEqual(self.original['commands'],self.read())
        self.assertFalse(self.row['executionLaunched'])
        self.assertNotIn('commands',self.row)

    def test_substituted_origin_or_command_inventory_is_rejected(self):
        for change in ('receipt','commands','journal','child'):
            with self.subTest(change=change):
                row=copy.deepcopy(self.row); closure=copy.deepcopy(self.closure); outer=dict(self.outer)
                if change=='receipt': self.row['reused']['receipt']='0'*64
                if change=='commands': self.row['originCommands']=[{'stage':'invented'}]
                if change=='journal': self.closure[0]['arguments']={'source':'different'}
                if change=='child': self.outer['childReceiptSha256']='0'*64
                with self.assertRaises(ValueError): self.read()
                self.row=row; self.closure=closure; self.outer=outer

    def test_reuse_cannot_claim_it_launched_or_supply_new_commands(self):
        for changes in ({'executionLaunched':True},{'commands':[{'stage':'invented'}]}):
            row={**self.row,**changes}
            with self.assertRaisesRegex(ValueError,'not a new native launch'):
                checkpoint.stage_commands(self.root,row)
