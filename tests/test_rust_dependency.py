"""The installed ASCENT package's runtime and compiled-input contract."""
from collections import Counter
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import ascent
from ascent.build import runtime_identity
from gambit_smp.ascent_program import artifact_paths, engine_api
from gambit_smp.ascent_runtime import inventory, require_packaged_runtime
from gambit_smp.framework import digest


class RustDependencyTests(unittest.TestCase):
    def test_packaged_resource_resolution_is_once_and_same_length_change_is_denied(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve(strict=True)
            resource = root / "source"
            resource.write_bytes(b"before")
            sha = digest(resource)
            build = {"runtimeInputs": {str(resource): sha},
                     "packageInputs": {"source": sha},
                     "runtimePackagePaths": {str(resource): "source"}}
            original = Path.resolve
            calls = Counter()

            def observed(path, *args, **kwargs):
                calls[str(path)] += 1
                return original(path, *args, **kwargs)

            with patch.object(Path, "resolve", observed):
                require_packaged_runtime(build, root)
            self.assertEqual(calls[str(resource)], 1)
            resource.write_bytes(b"after!")
            with self.assertRaisesRegex(ValueError, "runtime resource mismatch"):
                require_packaged_runtime(build, root)
            resource.unlink()
            resource.symlink_to(root / "missing")
            with self.assertRaisesRegex(ValueError, "external runtime resource"):
                require_packaged_runtime(build, root)

    def test_inventory_resolves_each_package_entry_once_before_source_binding(self):
        original = Path.resolve
        calls = Counter()

        def observed(path, *args, **kwargs):
            calls[str(path)] += 1
            return original(path, *args, **kwargs)

        with patch.object(Path, "resolve", observed):
            files, build = inventory(verify=False)
        self.assertTrue(build["sourceInputs"])
        for name, sha in build["sourceInputs"].items():
            path = files["source:" + name]
            self.assertLessEqual(calls[str(path)], 2, name)
            self.assertGreater(calls[str(path)], 0, name)
            self.assertEqual(digest(path), sha, name)

    def test_deployed_package_does_not_depend_on_a_build_machine_runtime(self):
        require_packaged_runtime(runtime_identity(), Path(ascent.__file__).parent)

    def test_complete_compiled_sources_and_resources_are_hashed(self):
        build = runtime_identity()
        self.assertEqual(build["schema"], "ascent.rust-build.v1")
        self.assertTrue(build["rayon"])
        files = artifact_paths()
        self.assertTrue(files["ascent._core"].name.endswith(".so"))
        self.assertNotIn("library", files)
        for prefix, inputs in (("source:", build["sourceInputs"]),
                               ("runtime:", build["runtimeInputs"])):
            self.assertEqual({name.removeprefix(prefix) for name in files if name.startswith(prefix)},
                             set(inputs))
            for name, sha in inputs.items():
                self.assertEqual(digest(files[prefix + name]), sha, name)

    def test_rust_engine_has_no_legacy_library_or_dispatcher_entry(self):
        with self.assertRaises(TypeError):
            ascent.Engine(library="unavailable")
        with engine_api() as (engine, bindings):
            self.assertIsInstance(engine, ascent.Engine)
            self.assertFalse(hasattr(engine, "request"))
            self.assertIn("ascent._core", bindings)
            self.assertIsInstance(engine.describe(), dict)


if __name__ == "__main__":
    unittest.main()
