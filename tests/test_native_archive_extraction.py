"""Real native archive transport and bounded path controls, not Scheme admission."""
import io,json,os,shutil,tarfile,time,unittest
from pathlib import Path
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import extract_archive,workspace_lease
from gambit_smp.recipes import ExecutionContext,tree_identity
from tests import test_workspace as fixtures

class NativeArchiveExtractionTests(unittest.TestCase):
    setUp=fixtures.WorkspaceTests.setUp
    def context(self):
        out=w.task_output(self.root,self.root/'.cache/extraction');out.mkdir(parents=True)
        return ExecutionContext(self.root,out,out,dict(os.environ),time.monotonic()+15,{}, {},
                                {'tar':Path(shutil.which('tar')).resolve(),'sh':Path('/bin/sh')})
    def test_git_source_modes_match_data_filter_without_changing_parent_umask(self):
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            ctx=self.context();archive=ctx.out/'source.tar'
            with tarfile.open(archive,'w') as tree:
                for name,mode in [('source.c',0o664),('configure',0o775)]:
                    item=tarfile.TarInfo(name);item.mode=mode;item.size=1;tree.addfile(item,io.BytesIO(b'x'))
            destination=ctx.out/'source'
            extract_archive(archive,destination,ctx,stage='source',preserve_modes=False)
            self.assertEqual(0o644,(destination/'source.c').stat().st_mode & 0o777)
            self.assertEqual(0o755,(destination/'configure').stat().st_mode & 0o777)
    def test_native_transfer_preserves_real_cache_timestamps_modes_and_internal_alias(self):
        source=self.root/'input';source.mkdir();(source/'program').write_bytes(b'compiled payload fixture')
        (source/'program').chmod(0o755);os.utime(source/'program',(1234567890,1234567890))
        (source/'alias').symlink_to('program')
        archive=self.root/'input.tar'
        with tarfile.open(archive,'w') as tree:tree.add(source,arcname='runtime')
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            ctx=self.context();build=w.build_output(self.root,'native',compiler=shutil.which('cc'))
            target=build/'source';target.mkdir();empty=ctx.out/'empty';empty.mkdir()
            try:
                with workspace_lease(self.root,target,tree_identity(target)):
                    w.sync_build_source(self.root,build,empty,inventory=tree_identity(source),
                        initial_transfer=lambda:extract_archive(archive,target,ctx,stage='install',runtime_only=True,
                                                               existing_inputs=tree_identity(source)))
                self.assertEqual(tree_identity(source),tree_identity(target))
                self.assertEqual(1234567890,(target/'program').stat().st_mtime)
                self.assertEqual(0,ctx.commands[-1]['exit']);self.assertTrue(ctx.commands[-1]['parentReaped'])
            finally:ctx.workspace_leases.close()
    def test_symlink_ancestor_and_traversal_are_refused_before_a_native_child(self):
        w.start(self.root,'repair',adopt=True)
        with w.execution_scope(self.root,'repair'):
            ctx=self.context()
            for index,entries in enumerate((['../escape'],['alias','alias/child'])):
                archive=ctx.out/('bad'+str(index)+'.tar')
                with tarfile.open(archive,'w') as tree:
                    for name in entries:
                        item=tarfile.TarInfo(name)
                        if name=='alias':item.type=tarfile.SYMTYPE;item.linkname='internal'
                        tree.addfile(item,io.BytesIO())
                with self.assertRaisesRegex(ValueError,'unsafe archive|symlink ancestor'):
                    extract_archive(archive,ctx.out/('target'+str(index)),ctx,stage='bad'+str(index))
            self.assertEqual([],ctx.commands)
