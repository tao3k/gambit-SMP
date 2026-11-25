"""Semantic producer identity is not the downstream output directory state."""
import unittest
from pathlib import Path
from gambit_smp.gerbil_build.compiler_roles import material, fingerprint, project_inputs


class CompilerArtifactRoles(unittest.TestCase):
    def test_only_exact_downstream_outputs_are_erased(self):
        root=Path('/owned');host=str(root/'build/lib/gerbil/compiler/driver.ssi')
        target=str(root/'build/lib/gerbil/polydactyl~1.o2')
        debug=target+'.dSYM/Contents/Info.plist'
        different=str(root/'build/lib/gerbil/polydactylish.o2')
        source=str(root/'src/lang/gerbil/polydactyl.ss')
        data={'inputs':{host:'host',target:'target',debug:'debug',different:'other',source:'source'}}
        projected,erased=project_inputs(data,root,{'targets':['gerbil/polydactyl']})
        self.assertEqual(set(erased),{target,debug})
        self.assertEqual(projected['inputs'],{host:'host',different:'other',source:'source'})
        self.assertEqual(len(data['inputs']),5)

    def test_consumer_change_preserves_signature_but_host_change_does_not(self):
        root=Path('/owned');host=str(root/'build/lib/gerbil/compiler.ssi')
        target=str(root/'build/lib/gerbil/polydactyl.scm')
        roles={'targets':['gerbil/polydactyl']}
        before={'inputs':{host:'same',target:'old'},'environment':{'CC':'gcc'}}
        after={'inputs':{host:'same',target:'new'},'environment':{'CC':'gcc'}}
        self.assertEqual(fingerprint(project_inputs(before,root,roles)[0]),
                         fingerprint(project_inputs(after,root,roles)[0]))
        after['inputs'][host]='different host'
        self.assertNotEqual(fingerprint(project_inputs(before,root,roles)[0]),
                            fingerprint(project_inputs(after,root,roles)[0]))

    def test_observed_bytes_and_checked_producer_projection_remain_distinct(self):
        observed=dict(inputs={'make':'observed','catalogue':'derived','host':'host'},
                      environment={},system=[],producerEntry='make stdlib',
                      unmanagedInitialization=False,providerLoaderSupported=True,reuseAllowed=True,
                      inputProjections={'make':{'producerSha256':'producer'},
                                        'catalogue':{'producerSha256':None}})
        projected=material(observed)
        self.assertEqual(projected['inputs'],{'make':'producer','host':'host'})
        self.assertEqual(observed['inputs']['make'],'observed')
