"""Enforce reusable capability boundaries, not a second build execution path."""
import ast
import inspect
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from gambit_smp import gerbil_build
from gambit_smp.gerbil_build import sources


class GerbilBuildArchitectureTests(unittest.TestCase):
    def setUp(self):
        self.directory = Path(gerbil_build.__file__).parent
        self.files = sorted(self.directory.glob('*.py'))

    def test_public_capabilities_are_direct_owner_exports(self):
        self.assertFalse(self.directory.with_suffix('.py').exists())
        self.assertFalse(hasattr(gerbil_build, '__getattr__'))
        for name in gerbil_build.__all__:
            value = getattr(gerbil_build, name)
            if inspect.isfunction(value):
                self.assertNotEqual(value.__module__, gerbil_build.__name__)
                self.assertEqual(value.__name__, name)
        self.assertFalse(any(name.startswith('_') for name in gerbil_build.__all__))
        self.assertFalse(hasattr(gerbil_build, '_current'))

    def test_stdlib_withdrawal_callers_bind_the_real_owner_signature(self):
        from gambit_smp.gerbil_build.batches import _withdraw_stdlib_batch
        signature=inspect.signature(_withdraw_stdlib_batch)
        with self.assertRaises(TypeError):signature.bind(object(),object())
        found=0
        for file in self.files:
            for node in ast.walk(ast.parse(file.read_text())):
                if (isinstance(node,ast.Call) and isinstance(node.func,ast.Name)
                        and node.func.id=='_withdraw_stdlib_batch'):
                    with self.subTest(file=file.name,line=node.lineno):
                        signature.bind(*[object() for _ in node.args],**{k.arg:object() for k in node.keywords})
                    found+=1
        self.assertGreater(found,0)

    def test_module_dependencies_have_no_cycles(self):
        prefix = gerbil_build.__name__ + '.'
        graph = {path.stem: set() for path in self.files}
        for path in self.files:
            for node in ast.walk(ast.parse(path.read_text())):
                if isinstance(node, ast.ImportFrom) and node.module and node.module.startswith(prefix):
                    graph[path.stem].add(node.module[len(prefix):].split('.')[0])
        visited = set()

        def visit(name, ancestors):
            self.assertNotIn(name, ancestors, 'Cyclic build responsibilities')
            if name in visited:
                return
            for child in graph[name]:
                visit(child, ancestors | {name})
            visited.add(name)

        for name in graph:
            visit(name, set())

    def test_modules_do_not_become_standalone_task_scripts(self):
        for path in self.files:
            source = path.read_text()
            with self.subTest(module=path.name):
                definitions=[n.name for n in ast.parse(source).body
                             if isinstance(n,(ast.FunctionDef,ast.ClassDef))]
                self.assertEqual(len(definitions),len(set(definitions)),
                                 'Duplicate owner definitions silently replace implementations')
                # A reviewability budget, not a runtime resource limit.
                self.assertLessEqual(len(source.splitlines()), 600)
                self.assertNotIn('.cache/tasks/', source)
                self.assertNotIn("__main__", source)
                self.assertNotIn('sys.modules', source)
                for node in ast.parse(source).body:
                    self.assertIsInstance(node, (ast.Expr, ast.Import, ast.ImportFrom,
                        ast.FunctionDef, ast.ClassDef, ast.Assign, ast.AnnAssign))
                    if isinstance(node, ast.Expr):
                        self.assertIsInstance(node.value, ast.Constant,
                            'No import-time execution pipeline')

    def test_provenance_covers_every_module_and_the_scheme_helper(self):
        expected = set(self.files) | {self.directory.parent / name for name in
            ('gerbil_compile_products.ss', 'gerbil_library_order.ss', 'gerbil_semantic_graph.ss', 'gerbil_initialization_view.ss', 'gerbil_static_products.ss')}
        self.assertEqual(set(sources.source_files()), expected)
        self.assertTrue(all(path.is_file() for path in expected))

    def test_provenance_changes_for_each_owned_input_but_not_relocation(self):
        with tempfile.TemporaryDirectory() as temp:
            left = Path(temp) / 'left'
            right = Path(temp) / 'right'
            for folder in (left, right):
                folder.mkdir()
                (folder / 'owner.py').write_text('source')
                (folder / 'helper.ss').write_text('scheme')
            paths = tuple(sorted(left.iterdir()))
            with patch.object(sources, 'source_files', return_value=paths):
                original = sources.source_identity()
                for path in paths:
                    before = path.read_bytes()
                    path.write_bytes(before + b'changed')
                    self.assertNotEqual(original, sources.source_identity())
                    path.write_bytes(before)
            with patch.object(sources, 'source_files', return_value=tuple(sorted(right.iterdir()))):
                self.assertEqual(original, sources.source_identity())
