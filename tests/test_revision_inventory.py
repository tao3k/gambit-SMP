"""Real Git three-version custody and exact native-model ownership controls."""
from pathlib import Path
import subprocess
import tempfile
import unittest

from gambit_smp.revision_inventory import inventory, ownership


class RevisionInventoryTests(unittest.TestCase):
    def test_ownership_rejects_gaps_stale_paths_and_ambiguous_owners(self):
        group = dict(id='owner', paths=['a'], depends=[])
        self.assertEqual(ownership(['a'], [group]), {'a': 'owner'})
        for paths, groups in [(['a', 'b'], [group]), ([], [group]),
                (['a'], [group, dict(id='other', paths=['a'], depends=[])])]:
            with self.assertRaises(ValueError):
                ownership(paths, groups)

    def test_unknown_or_cyclic_dependencies_are_rejected(self):
        for groups in [
            [dict(id='a', paths=['x'], depends=['absent'])],
            [dict(id='a', paths=['x'], depends=['b']),
             dict(id='b', paths=[], depends=['a'])]]:
            with self.assertRaises(ValueError):
                ownership(['x'], groups)

    def test_read_only_snapshot_preserves_distinct_index_and_cancelled_working(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            repo = root / 'repo'
            repo.mkdir()

            def git(*args):
                return subprocess.run(['git', '-C', str(repo), *args],
                    check=True, capture_output=True).stdout

            git('init', '-q')
            git('config', 'user.name', 'Inventory test')
            git('config', 'user.email', 'inventory@example.invalid')
            for name in ['cancelled.c', 'coordinates.c', 'three.c']:
                (repo / name).write_text('#line 10 source\nint a;\n')
            git('add', '.')
            git('commit', '-qm', 'base')
            for name in ['cancelled.c', 'three.c']:
                (repo / name).write_text('int staged;\n')
            git('add', '.')
            (repo / 'cancelled.c').write_text('#line 10 source\nint a;\n')
            (repo / 'three.c').write_text('int working;\n')
            (repo / 'coordinates.c').write_text('#line 99 source\nint a;\n')
            (repo / 'new file.c').write_text('int new_value;\n')
            files = ['cancelled.c', 'coordinates.c', 'three.c', 'new file.c']
            groups = [dict(id='one', paths=files, depends=[])]
            before = git('ls-files', '--stage', '-z')
            observed = inventory(root, repo, groups)
            rows = {row['path']: row for row in observed['rows']}
            self.assertEqual(observed['pathCount'], 4)
            self.assertTrue(rows['cancelled.c']['workingEqualsHead'])
            self.assertFalse(rows['cancelled.c']['indexEqualsHead'])
            self.assertTrue(rows['coordinates.c']['coordinateDirectivesOnly'])
            self.assertFalse(rows['three.c']['coordinateDirectivesOnly'])
            self.assertEqual(len({rows['three.c'][field] for field in
                ['headSha256', 'indexSha256', 'workingSha256']}), 3)
            self.assertIsNone(rows['new file.c']['headBlob'])
            self.assertEqual(before, git('ls-files', '--stage', '-z'))
            self.assertEqual((repo / 'three.c').read_text(), 'int working;\n')
            self.assertFalse(observed['runtimeAdmitted'])

    def test_symlink_source_is_not_admitted(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            subprocess.run(['git', '-C', str(root), 'config', 'user.name', 'Test'], check=True)
            subprocess.run(['git', '-C', str(root), 'config', 'user.email', 't@example.invalid'], check=True)
            subprocess.run(['git', '-C', str(root), 'commit', '--allow-empty', '-qm', 'base'], check=True)
            (root / 'alias').symlink_to('/etc/hosts')
            with self.assertRaisesRegex(ValueError, 'aliases'):
                inventory(root, root, [dict(id='a', paths=['alias'], depends=[])])


if __name__ == '__main__':
    unittest.main()
