"""Original libgerbil producer custody; no alternative compiler runner."""
import tempfile
import unittest
import json
from unittest.mock import patch
from pathlib import Path
from types import SimpleNamespace
from gambit_smp.gerbil_build.static_units import library_static_source, static_unit_products, retain_static_units, prepare_static_units


class StaticUnitContract(unittest.TestCase):
    def test_checked_inverse_preserves_official_entry(self):
        original='(def +gerbil-gsc+ #f)\n(def (invoke-gsc args)\n  (invoke-process +gerbil-gsc+ args))\n'
        new=library_static_source(original)
        self.assertEqual(library_static_source(new,inverse=True),original)
        self.assertEqual(library_static_source(new),new)
        self.assertIn('(static-unit-invoke +gerbil-gsc+ args)',new)
        self.assertIn('(invoke-process +gerbil-gsc+ args)',new)
        with self.assertRaisesRegex(ValueError,'contract differs'):
            library_static_source(new.replace('static-unit-contract "','static-unit-contract "tampered'),inverse=True)

    def test_unknown_writer_cannot_issue_completion(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);ctx=SimpleNamespace(directory=root)
            retain_static_units(ctx,root,'key',root,root,
                                {'parentReaped':True,'processGroupQuiescent':False},{},{})
            self.assertIn('"issued": 0',(root/'static-unit-custody.json').read_text())
            self.assertFalse(list(root.glob('*.scm')))

    def test_incomplete_stdlib_has_no_static_admission(self):
        with self.assertRaisesRegex(ValueError,'completed stdlib'):
            with static_unit_products(None,None,None,{'stageComplete':False}):
                self.fail('incomplete producer admitted')

class StaticUnitReadmission(unittest.TestCase):
    def test_string_identity_paths_and_changed_output(self):
        from gambit_smp.framework import digest
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory).resolve();store=root/'units';store.mkdir()
            output=root/'unit.c';output.write_text('fresh C')
            source=root/'unit.scm';source.write_text('(define value 1)')
            record=dict(data=[['context','-c','gsc',[],str(root),str(source),'oid',str(output),'contract'],'oid',[]],identities={str(output):digest(output),str(source):digest(source)})
            ref=dict(path='witness',sha256='hash',observation='id',scope='scope')
            (store/'unit.json').write_text(json.dumps(dict(record,completion=ref)))
            with patch('gambit_smp.gerbil_build.static_units._module_witnesses',
                       return_value={tuple(ref.values()):record}), patch(
                       'gambit_smp.gerbil_build.static_units._qualify_sources',
                       return_value={str(source)}):
                ctx=SimpleNamespace(root=root)
                self.assertEqual(len(prepare_static_units(ctx,store,'context',root)),1)
                self.assertTrue((store/'unit.scm').exists())
                output.write_text('unknown writer')
                self.assertEqual(prepare_static_units(ctx,store,'context',root),{})
                self.assertFalse((store/'unit.scm').exists())
