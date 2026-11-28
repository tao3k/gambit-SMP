"""Check source-role custody; graph semantics run through native Scheme tests."""

import unittest
from pathlib import Path

from gambit_smp.gerbil_build.library_source import library_order_source, original_order, library_initialization_source


class LibraryOrderSourceTests(unittest.TestCase):
    def setUp(self):
        p = Path(__file__).resolve().parents[1]/'src/gambit_smp/gerbil_library_order.ss'
        text = p.read_text()
        self.new = text[text.index('(def (order-modules '):].strip()
        self.old = original_order(self.new)
        self.source = ';;; Original builder preamble\n'+self.old+'\n;;; Native compilation follows\n'

    def test_exact_inverse_and_idempotent_install(self):
        new = library_order_source(self.source)
        self.assertIn(self.new, new)
        self.assertEqual(library_order_source(new), new)
        self.assertEqual(library_order_source(new, inverse=True), self.source)

    def test_unreviewed_edge_semantics_cannot_acquire_projection(self):
        changed = self.source.replace('(fxzero? (module-import-phi hd))', '#t')
        with self.assertRaises(ValueError):
            library_order_source(changed)

    def test_unrelated_edits_are_not_erased_from_producer_identity(self):
        new = library_order_source(self.source)+'(displayln "changed builder")\n'
        self.assertEqual(library_order_source(new, inverse=True),
                         self.source+'(displayln "changed builder")\n')

    def test_missing_or_duplicate_owner_is_rejected(self):
        for text in ('', self.source+self.source):
            with self.subTest(text=text[:20]), self.assertRaises(ValueError):
                library_order_source(text)

    def test_initialization_consumer_preserves_official_fallback_and_inverse(self):
        body='(def (build-libgerbil)\n  (let* ((ordered-modules (order-modules stdlib-modules))) ordered-modules))'
        new=library_initialization_source(body)
        self.assertIn('initialization-graph-resolve initialization-graph-operations',new)
        self.assertIn('(order-modules stdlib-modules)',new)
        self.assertEqual(library_initialization_source(new),new)
        self.assertEqual(library_initialization_source(new,inverse=True),body)
        with self.assertRaises(ValueError):
            library_initialization_source(new.replace('initialization-graph-resolve initialization-graph-operations','unqualified'),inverse=True)
