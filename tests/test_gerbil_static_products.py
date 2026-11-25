"""Cache custody and invalidation controls; synthetic outputs grant no native admission."""
import copy
import hashlib
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp.gerbil_build.static_products import _static_plan, _static_products, _static_link_product


class StaticProductTests(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.source = self.root/'source'; self.work = self.root/'work'
        self.directory = self.root/'run'; self.directory.mkdir()
        static = self.source/'build/lib/static'; static.mkdir(parents=True)
        self.sources = [static/'a.scm',static/'b.scm']
        for p in self.sources:p.write_text('(define '+p.stem+' 1)')
        self.plan = dict(kind='StaticModuleProduct',compiler=str(self.source/'build/bin/gsc'),
            generationArgs=['-track-scheme'],sources=list(map(str,self.sources)),
            linkOutput=str(self.source/'build/lib/gerbil-link.c'),
            objectArgs=['-obj','-cc-options','-g'],nativeCompiler='/gcc',
            nativeLinkArgs=['-o',str(self.source/'build/bin/gerbil'),
                            *[str(p.with_suffix('.o')) for p in self.sources],
                            str(self.source/'build/lib/gerbil-link.o')],
            output=str(self.source/'build/bin/gerbil'))
        header = self.directory/'header.json'
        header.write_text(json.dumps(dict(runId='unit',inputs={})))
        self.witnesses = {}; self.quiescent = True; self.change_input = False
        self.ctx = SimpleNamespace(root=self.root,directory=self.directory,env={'GERBIL_BUILD_CORES':'2'},
            commands=[],remaining=lambda:10,
            receipt={'journal':dict(path=str(header),scope='synthetic-control')})
        self.omit_output = False
        def require(stage, argv, cwd, cap):
            paths = ([Path(arg) for arg in argv if str(arg).endswith('.scm')]
                     if '-c' in argv else [None])
            for path in paths:
                output = path.with_suffix('.c') if path else Path(argv[argv.index('-o')+1])
                output.parent.mkdir(parents=True,exist_ok=True)
                if not self.omit_output:
                    output.write_text('#ifdef ___LINKER_INFO\n(synthetic metadata)\n#else\n'+
                                      (path.read_text() if path else 'synthetic link'))
                if self.change_input and path:path.write_text('changed during generation')
            command=dict(stage=stage,exit=0,timeout=False,parentReaped=True,
                         processGroupQuiescent=self.quiescent)
            self.ctx.commands.append(command)
            (self.directory/(stage+'.process.json')).write_text(json.dumps(dict(state='OBSERVED',**command)))
            return ''
        self.ctx.require=require
        def retain(root,path,scope,payload,inputs):
            ref=dict(path=str(path),sha256=hashlib.sha256(str(path).encode()).hexdigest(),
                     observation='synthetic',scope=scope)
            self.witnesses[tuple(ref[k] for k in ('path','sha256','observation','scope'))]=copy.deepcopy(payload['moduleProof'])
            return ref
        self.addCleanup(patch.stopall)
        patch('gambit_smp.gerbil_build.static_products._module_witnesses',side_effect=lambda *a,**k:self.witnesses).start()
        patch('gambit_smp.research_kernel.retain_run_record',side_effect=retain).start()
        self.provider={'compiler':'synthetic-source-bound-provider'}

    def products(self):
        return _static_products(self.ctx,self.work,self.source,self.plan,self.provider,time.monotonic()+10)

    def test_cold_misses_share_one_actual_producer_and_warm_hits_run_none(self):
        first=self.products()
        self.assertEqual((2,1),(first['generated'],first['generationProcesses']))
        self.assertEqual(1,len(self.ctx.commands))
        self.assertEqual((0,0),(self.products()['generated'],self.products()['generationProcesses']))
        self.assertEqual(1,len(self.ctx.commands))

    def test_success_without_output_cannot_publish_stale_C(self):
        for path in self.sources:path.with_suffix('.c').write_text('stale C')
        self.omit_output=True
        with self.assertRaisesRegex(ValueError,'missing fresh C output'):self.products()
        self.assertFalse((self.work/'gerbil-static-products.json').exists())
        self.assertEqual(2,len(list(self.directory.glob('*-previous/*.c'))))

    def test_full_plan_rejects_duplicates_and_link_order_drift(self):
        self.assertEqual(self.plan,_static_plan(self.source,self.plan,'/gcc'))
        for field,value in [('sources',[str(self.sources[0])]*2),
                            ('nativeLinkArgs',self.plan['nativeLinkArgs'][:-1]),
                            ('compiler','/other/gsc')]:
            plan=dict(self.plan,**{field:value})
            with self.subTest(field=field),self.assertRaises(ValueError):_static_plan(self.source,plan,'/gcc')

    def test_hits_restore_outputs_without_reexecuting_a_producer(self):
        first=self.products();self.assertEqual(2,first['generated'])
        for p in self.sources:p.with_suffix('.c').unlink()
        before=len(self.ctx.commands);second=self.products()
        self.assertEqual((0,2),(second['generated'],second['reused']))
        self.assertEqual(before,len(self.ctx.commands))
        self.assertTrue(all(p.with_suffix('.c').is_file() for p in self.sources))

    def test_leaf_change_invalidates_one_product_but_macro_provider_invalidates_all(self):
        self.products();self.sources[0].write_text('(define a 2)')
        self.assertEqual(1,self.products()['generated'])
        self.provider={'compiler':'changed-macro-context'}
        self.assertEqual(2,self.products()['generated'])

    def test_reordered_link_reuses_modules_but_rebuilds_ordered_link_product(self):
        products=self.products()
        first=_static_link_product(self.ctx,self.work,self.source,self.plan,products,self.provider,time.monotonic()+10)
        self.assertFalse(first['reused'])
        second=_static_link_product(self.ctx,self.work,self.source,self.plan,products,self.provider,time.monotonic()+10)
        self.assertTrue(second['reused'])
        products['products'].reverse()
        third=_static_link_product(self.ctx,self.work,self.source,self.plan,products,self.provider,time.monotonic()+10)
        self.assertFalse(third['reused'])
        self.assertNotEqual(first['inputSha256'],third['inputSha256'])

    def test_unknown_completion_never_publishes_a_reusable_product(self):
        self.quiescent=False
        with self.assertRaisesRegex(ValueError,'unknown completion'):self.products()
        self.assertFalse((self.work/'gerbil-static-products.json').exists())

    def test_input_race_never_publishes_a_reusable_product(self):
        self.change_input=True
        with self.assertRaisesRegex(ValueError,'changed during generation'):self.products()
        self.assertFalse((self.work/'gerbil-static-products.json').exists())

    def test_corrupt_sealed_bytes_and_missing_witness_cannot_be_hits(self):
        self.products()
        cached=next((self.work/'static-products').glob('*/product.c'))
        cached.write_text('corrupt bytes')
        with self.assertRaisesRegex(ValueError,'sealed static product drift'):self.products()
        self.witnesses.clear()
        # Reacquisition is an actual producer call, never acceptance of old bytes.
        self.assertEqual(2,self.products()['generated'])


if __name__ == '__main__':unittest.main()
