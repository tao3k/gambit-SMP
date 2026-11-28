"""Binary publication must preserve old readers and refuse changed identities."""
import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp.product_materialization import materialize_product


class ProductMaterializationTests(unittest.TestCase):
    def setUp(self):
        self.storage = tempfile.TemporaryDirectory()
        self.addCleanup(self.storage.cleanup)
        self.root = Path(self.storage.name).resolve()
        self.source = self.root / 'source'
        self.target = self.root / 'target'
        self.source.write_bytes(b'new product')
        self.target.write_bytes(b'old product')
        self.sha = hashlib.sha256(self.source.read_bytes()).hexdigest()
        self.route = patch('gambit_smp.product_materialization.runtime_output',
                           side_effect=lambda root, path: path)
        self.route.start()
        self.addCleanup(self.route.stop)

    def publish(self):
        return materialize_product(self.root, self.source, self.target, self.sha)

    def test_old_reader_survives_fresh_inode_publication_even_for_equal_bytes(self):
        with self.target.open('rb') as reader:
            before = self.target.stat().st_ino
            self.publish()
            self.assertNotEqual(before, self.target.stat().st_ino)
            self.assertEqual(reader.read(), b'old product')
            self.assertEqual(self.target.read_bytes(), b'new product')
            before = self.target.stat().st_ino
            self.publish()
            self.assertNotEqual(before, self.target.stat().st_ino)

    def test_wrong_digest_preserves_destination(self):
        self.source.write_bytes(b'changed')
        with self.assertRaisesRegex(ValueError, 'digest mismatch'):
            self.publish()
        self.assertEqual(self.target.read_bytes(), b'old product')

    def test_alias_and_self_publication_are_refused(self):
        self.target.unlink()
        self.target.symlink_to(self.source)
        with self.assertRaisesRegex(ValueError, 'aliases'):
            self.publish()
        self.target.unlink()
        with self.assertRaisesRegex(ValueError, 'distinct'):
            materialize_product(self.root, self.source, self.source, self.sha)

    def test_transfer_failure_preserves_destination(self):
        with patch('gambit_smp.product_materialization.clone_file', side_effect=OSError('failure')):
            with self.assertRaises(OSError):
                self.publish()
        self.assertEqual(self.target.read_bytes(), b'old product')
        self.assertEqual(sorted(p.name for p in self.root.iterdir()), ['source', 'target'])

    def test_source_change_during_transfer_cannot_publish(self):
        def mutate(source, staged):
            staged.write_bytes(source.read_bytes())
            source.write_bytes(b'late write')
            return 'test-transfer'

        with patch('gambit_smp.product_materialization.clone_file', side_effect=mutate):
            with self.assertRaisesRegex(ValueError, 'changed during'):
                self.publish()
        self.assertEqual(self.target.read_bytes(), b'old product')
