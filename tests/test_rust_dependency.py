"""The installed fixed wheel and its published source/artifact lock."""
import importlib.metadata
import json
from pathlib import Path
import tomllib
import unittest
import copy

import ascent
from ascent.build import runtime_identity
from gambit_smp.ascent_program import artifact_paths, engine_api
from gambit_smp.ascent_runtime import require_packaged_runtime, validate_publication, publication_artifact, LIBRARY_LOCK
from gambit_smp.framework import ROOT, digest


class RustDependencyTests(unittest.TestCase):
    def test_deployed_package_does_not_depend_on_a_build_machine_runtime(self):
        require_packaged_runtime(runtime_identity(), Path(ascent.__file__).parent)

    def test_installed_revision_matches_the_declared_github_dependency(self):
        declared = tomllib.loads((ROOT / "pyproject.toml").read_text())
        source = declared["tool"]["uv"]["sources"]["gerbil-ascent"]
        distribution = importlib.metadata.distribution("gerbil-ascent")
        installed = json.loads(distribution.read_text("direct_url.json"))
        self.assertIn("archive_info", installed)
        self.assertNotIn("vcs_info", installed)
        self.assertTrue(installed["url"].endswith(".whl"))
        publication = json.loads((ROOT / LIBRARY_LOCK).read_text())
        extension = artifact_paths()["ascent._core"]
        validate_publication(publication, source, runtime_identity(), digest(extension))
        for key in ("revision", "extensionSha256", "sourceInputsSha256", "sourceInputCount"):
            with self.subTest(drift=key), self.assertRaisesRegex(ValueError, "published source/artifact lock"):
                altered = copy.deepcopy(publication)
                altered[key] = 'changed'
                if key == 'extensionSha256':
                    for artifact in altered.get('artifacts', {}).values():
                        artifact[key] = 'changed'
                validate_publication(altered, source,
                                     runtime_identity(), digest(extension))
        self.assertNotIn("ascent-test-support", declared["tool"]["uv"]["sources"])

    def test_platform_publication_is_explicit_and_ci_install_hash_matches(self):
        publication = json.loads((ROOT / LIBRARY_LOCK).read_text())
        linux = publication_artifact(publication, 'linux-x86_64')
        self.assertNotEqual(linux['extensionSha256'], publication['extensionSha256'])
        requirement = (ROOT / 'integrations/ascent/ci-linux.requirements.txt').read_text().strip()
        self.assertEqual(requirement, '.cache/ci/library/' + linux['wheel'] +
                         ' --hash=sha256:' + linux['wheelSha256'])
        action = (ROOT / '.github/actions/framework/action.yml').read_text()
        self.assertIn('artifact-ids: ' + str(linux['artifactId']), action)
        self.assertIn('run-id: ' + linux['ci'].rsplit('/', 1)[1], action)
        self.assertIn('--no-install-package gerbil-ascent', action)
        self.assertIn('--no-build --require-hashes', action)
        with self.assertRaisesRegex(ValueError, 'no locked artifact'):
            publication_artifact(publication, 'unsupported-platform')

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
