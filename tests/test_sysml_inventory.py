"""Lexical scope is reproducible navigation, never a source-refinement verdict."""
from pathlib import Path
import unittest

from gambit_smp.sysml_adapters import adapter_bindings
from gambit_smp.sysml_inventory import inspect_inventory
from tests.test_sysml_adapters import AdapterFixture


class InventoryTests(AdapterFixture):
    def setUp(self):
        super().setUp()
        (self.root/'sources').mkdir()
        self.add('M','scope','InventoryScope',dict(id='scope',path='sources',suffixes='.c;.scm',
            exclude='_*.c',boundary='generated outputs and third-party code remain unqualified'))
        self.evaluations['M::scope.adapter.id']='adapter'
        fields=dict(id='family',pattern=r'ROOT_WRITE|SFUN_ARG',role='candidate',guard='required',
            publication='release/acquire',release='last use',knownCallers='audited callers',
            gap='not a call graph',acceptance='actual source refinement')
        self.add('M','family','AccessFamily',fields)
        self.evaluations['M::family.adapter.id']='adapter'
        self.evaluations['M::family.site.id']='source-site'
        (self.root/'sources/native.c').write_bytes(b'ROOT_WRITE(x);\n// ROOT_WRITE in comment\nSFUN_ARG(1);\n')

    def inventory(self, result=None):
        return inspect_inventory(self.root,(result or self.project())['flow'],'adapter')

    def test_all_occurrences_comments_and_emitter_strings_are_candidates(self):
        result=self.inventory()
        self.assertEqual([1,2,3],[row['line']for row in result['families'][0]['matches']])
        self.assertEqual('lexical-candidates-only',result['classification'])
        self.assertFalse(result['semanticVerified'])
        self.assertEqual([],self.policy(self.project())['shAdapterClosed'])

    def test_new_file_without_known_tokens_invalidates_subject(self):
        result=self.project();before=adapter_bindings(self.root,result)[0]['subjectSha256']
        (self.root/'sources/unknown.c').write_text('indirect_alias_store();')
        after=adapter_bindings(self.root,result)[0]['subjectSha256']
        self.assertNotEqual(before,after)

    def test_changed_zero_match_file_invalidates_subject(self):
        (self.root/'sources/unknown.c').write_text('opaque_old();')
        result=self.project();before=self.inventory(result)['subjectSha256']
        (self.root/'sources/unknown.c').write_text('opaque_new();')
        self.assertNotEqual(before,self.inventory(result)['subjectSha256'])

    def test_excluded_products_are_explicit_not_semantic_evidence(self):
        (self.root/'sources/_module.c').write_text('ROOT_WRITE(stale);')
        result=self.inventory()
        self.assertEqual(['sources/_module.c'],result['excluded'])
        self.assertEqual(3,result['families'][0]['matchCount'])
        self.assertNotIn('sources/_module.c',result['files'])

    def test_inventory_rules_follow_the_native_model(self):
        self.values['M::family']['pattern']='SFUN_ARG'
        self.assertEqual(1,self.inventory()['families'][0]['matchCount'])

    def test_overlapping_scopes_are_refused(self):
        self.add('M','overlap','InventoryScope',dict(id='overlap',path='sources/nested',suffixes='.c',exclude='',boundary='explicit'))
        self.evaluations['M::overlap.adapter.id']='adapter'
        with self.assertRaisesRegex(ValueError,'overlapping'):self.project()

    def test_scope_escape_is_refused(self):
        self.values['M::scope']['path']='../outside'
        with self.assertRaisesRegex(ValueError,'canonical'):self.project()

    def test_missing_scope_is_not_a_successful_empty_inventory(self):
        self.values['M::scope']['path']='missing'
        with self.assertRaisesRegex(ValueError,'source directory'):self.inventory()

    def test_source_symlink_is_not_silently_omitted(self):
        (self.root/'sources/link.c').symlink_to(self.root/'external.sysml')
        with self.assertRaisesRegex(ValueError,'symlinks'):self.inventory()

    def test_stale_scope_receipts_cannot_close_source_adapter(self):
        result=self.project();receipts=self.receipts(result)
        (self.root/'sources/new.c').write_text('unrecognized_writer();')
        self.assertEqual([],self.policy(result,receipts)['shAdapterClosed'])
