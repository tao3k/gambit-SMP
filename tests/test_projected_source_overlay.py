"""A byte-checked partial source overlay never admits an existing runtime."""
from pathlib import Path
from types import SimpleNamespace
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import source_capabilities as source
from gambit_smp.framework import digest


class Context:
    def __init__(self, root, step, artifacts):
        self.root = root
        self.step = step
        self.directory = root / step
        self.directory.mkdir()
        self.artifacts = artifacts
        self.tools = {"git": "/usr/bin/git"}

    def artifact(self, ref, kinds):
        kind, path = self.artifacts[ref["step"], ref["output"]]
        if kind not in ({kinds} if isinstance(kinds, str) else kinds):
            raise ValueError("artifact type mismatch")
        return path

    def publish(self, name, kind, path):
        self.artifacts[self.step, name] = kind, path
        return {name: {"type": kind, "path": str(path)}}

    def require(self, label, argv, cwd, cap):
        return subprocess.check_output(argv, cwd=cwd, text=True, stderr=subprocess.STDOUT)

    def remaining(self):
        return 10


class ProjectedSourceOverlayTests(unittest.TestCase):
    def test_runtime_header_projection_binds_and_rejects_drift_without_mutating_runtime(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);runtime=root/'runtime';runtime.mkdir()
            header=runtime/'native.h';header.write_text('typedef unsigned long native_word;\n')
            artifacts={('runtime','runtime'):('source-runtime',runtime)}
            ref={'step':'runtime','output':'runtime'}
            row={'target':'native.h','origin':{'kind':'source-artifact','path':'native.h'},'sha256':digest(header)}
            source.project({'source':ref,'files':[row]},Context(root,'project',artifacts))
            bound=source.bind({'workspace':{'step':'project','output':'workspace'}},Context(root,'bind',artifacts))
            self.assertEqual(bound['claim'],'byte-origin-only')
            self.assertEqual(header.read_text(),'typedef unsigned long native_word;\n')
            header.write_text('typedef unsigned int native_word;\n')
            with self.assertRaisesRegex(ValueError,'correspondence drift'):
                source.bind({'workspace':{'step':'project','output':'workspace'}},Context(root,'drift',artifacts))

    def test_native_workspace_accepts_structured_c23_not_arbitrary_flags(self):
        from gambit_smp.native_capabilities import validate_c
        args = {"sources":["a.c"],"headers":[],"standard":"gnu23",
                "optimization":3,"pthread":True,"target":"object"}
        validate_c(args,{"a.c"})
        for value in ("c23", "c11", "gnu11"):
            validate_c(dict(args,standard=value),{"a.c"})
        for value in ("gnu23 -include other.h", "c17", "gnu23; echo ignored"):
            with self.assertRaisesRegex(ValueError,"C standard"):
                validate_c(dict(args,standard=value),{"a.c"})

    def test_graph_accepts_projection_but_not_runtime_as_overlay_input(self):
        step = {"capability":"source.overlay", "dependsOn":["project"],
                "arguments":{"source":{"step":"project","output":"workspace"}}}
        registry = {"source.project":SimpleNamespace(outputs=(("workspace","compilation-workspace"),)),
                    "runtime":SimpleNamespace(outputs=(("workspace","source-runtime"),))}
        source.graph(step, {"project":{"capability":"source.project"}}, registry)
        with self.assertRaisesRegex(ValueError, "type mismatch"):
            source.graph(step, {"project":{"capability":"runtime"}}, registry)

    def test_project_overlay_reproject_rebind_preserves_original_and_exact_derivation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tree = root / "original"
            tree.mkdir()
            original = tree / "a.c"
            original.write_text("int value = 1;\n")
            artifacts = {("source","source"):("source-tree",tree)}
            source_ref = {"step":"source","output":"source"}
            row = {"target":"a.c","origin":{"kind":"source-artifact","path":"a.c"},
                   "sha256":digest(original)}
            source.project({"source":source_ref,"files":[row]}, Context(root,"project",artifacts))
            patch = root / "change.patch"
            patch.write_text("--- a/a.c\n+++ b/a.c\n@@ -1 +1 @@\n-int value = 1;\n+int value = 2;\n")
            revised = root / "expected.c"
            revised.write_text("int value = 2;\n")
            args = {"source":{"step":"project","output":"workspace"},"patch":"change.patch",
                    "files":{"a.c":{"before":digest(original),"after":digest(revised)}},"role":"candidate"}
            overlaid = source.overlay(args, Context(root,"overlay",artifacts))
            self.assertEqual("source-tree",overlaid["outputs"]["source"]["type"])
            self.assertEqual("int value = 1;\n",original.read_text())
            self.assertEqual("int value = 1;\n",(root/"project/workspace/a.c").read_text())
            self.assertEqual("int value = 2;\n",(root/"overlay/source/a.c").read_text())
            self.assertEqual(digest(patch),overlaid["outputs"]["source"]["derivation"]["patchSha256"])
            with self.assertRaisesRegex(ValueError,"type mismatch"):
                source.bind({"workspace":{"step":"overlay","output":"source"}},Context(root,"bad-bind",artifacts))
            source.project({"source":{"step":"overlay","output":"source"},
                            "files":[dict(row,sha256=digest(revised))]},Context(root,"reproject",artifacts))
            bound = source.bind({"workspace":{"step":"reproject","output":"workspace"}},
                                Context(root,"bind",artifacts))
            self.assertEqual("byte-origin-only",bound["claim"])

    def test_projected_overlay_rejects_wrong_baseline_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            tree = root/"workspace"
            tree.mkdir()
            (tree/"a.c").write_text("changed\n")
            artifacts = {("project","workspace"):("compilation-workspace",tree)}
            args = {"source":{"step":"project","output":"workspace"},"patch":"never-read.patch",
                    "files":{"a.c":{"before":"0"*64,"after":"1"*64}},"role":"candidate"}
            with self.assertRaisesRegex(ValueError,"baseline differs"):
                source.overlay(args,Context(root,"overlay",artifacts))

    def test_bound_c_projection_is_not_misclassified_as_a_complete_task_runtime_copy(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            original = root/'original'; original.mkdir()
            (original/'a.c').write_text('int value = 1;\n')
            artifacts = {('source','source'):('source-tree',original)}
            source.project({'source':{'step':'source','output':'source'},'files':[
                {'target':'a.c','origin':{'kind':'source-artifact','path':'a.c'},'sha256':digest(original/'a.c')}]},
                Context(root,'project',artifacts))
            source.bind({'workspace':{'step':'project','output':'workspace'}}, Context(root,'bind',artifacts))
            step = '.cache/tasks/repair/runs/one/compile'
            (root/step).parent.mkdir(parents=True)
            ctx = Context(root, step, artifacts)
            args = {'workspace':{'step':'project','output':'workspace'},
                    'binding':{'step':'bind','output':'binding'},'translationUnit':'a.c'}
            with patch('gambit_smp.fixture_storage.source_capacity', side_effect=AssertionError('runtime-only guard')), \
                 patch('gambit_smp.native_capabilities.compile_workspace', return_value={'compiled': True}):
                self.assertEqual({'compiled': True}, source.workspace_build(args,ctx))
            self.assertEqual((original/'a.c').read_bytes(), (ctx.directory/'inputs/a.c').read_bytes())
            (root/'project/workspace/unbound.c').write_text('unexpected source')
            denied = Context(root, step+'-unbound', artifacts)
            with self.assertRaisesRegex(ValueError, 'inventory differs from binding'):
                source.workspace_build(args, denied)
            self.assertFalse((denied.directory/'inputs').exists())


if __name__ == "__main__":
    unittest.main()
