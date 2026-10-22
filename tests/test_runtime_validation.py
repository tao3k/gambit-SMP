"""Real held-tree validation: reuse byte proofs, never stale pathname guesses."""
import os,shutil,time,unittest
from unittest.mock import patch
from pathlib import Path
from gambit_smp import workspace as w
from gambit_smp.framework import digest
from gambit_smp.recipes import ExecutionContext,tree_identity
from gambit_smp.suite_primitives import check_runtime
from tests import test_workspace as fixtures

class RuntimeValidationTests(unittest.TestCase):
    setUp=fixtures.WorkspaceTests.setUp
    def test_regular_entries_avoid_repeated_resolution_but_source_writes_are_detected(self):
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            build=w.build_output(self.root,'native',compiler=shutil.which('cc'))
            source=build/'source';source.mkdir();(source/'lib').mkdir();(source/'gsi').mkdir();(source/'gsc').mkdir()
            for name in ('lib/unit.scm','gsi/gsi','gsc/gsc','lib/libgambit.a'):(source/name).write_bytes(name.encode())
            expected=dict(sourceFiles={'lib/unit.scm':digest(source/'lib/unit.scm')},
                binarySha256=digest(source/'gsi/gsi'),gscSha256=digest(source/'gsc/gsc'),librarySha256=digest(source/'lib/libgambit.a'))
            out=w.task_output(self.root,self.root/'.cache/checks');out.mkdir(parents=True)
            ctx=ExecutionContext(self.root,out,out,{},time.monotonic()+20,{}, {},{})
            try:
                ctx.lease_workspace(source,tree_identity(source))
                with patch('gambit_smp.suite_primitives.relative',side_effect=AssertionError('redundant deep path resolution')):
                    check_runtime(source,expected)
                (source/'lib/unit.scm').write_bytes(b'changed real source bytes')
                with self.assertRaisesRegex(ValueError,'candidate input inventory changed'):
                    check_runtime(source,expected)
                (source/'lib/unit.scm').write_bytes(b'lib/unit.scm')
                (source/'lib/alias.scm').symlink_to('unit.scm')
                expected['sourceFiles']['lib/alias.scm']=digest(source/'lib/unit.scm')
                check_runtime(source,expected)
                (source/'lib/alias.scm').unlink();(source/'lib/alias.scm').symlink_to(self.root/'outside')
                (self.root/'outside').write_bytes(b'lib/unit.scm')
                with self.assertRaisesRegex(ValueError,'external symlink'):
                    check_runtime(source,expected)
            finally:ctx.workspace_leases.close()
