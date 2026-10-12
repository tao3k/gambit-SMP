from types import SimpleNamespace
import unittest
from unittest.mock import patch
from pathlib import Path
import json

from gambit_smp.provider_contract import REQUIRED_OPERATIONS, inspect_provider, validate_description


class ProviderContractTests(unittest.TestCase):
    def test_old_api_cannot_qualify_native_dsl(self):
        with self.assertRaisesRegex(ValueError, "open-sources"):
            validate_description({"abi": 1, "operations": ["open", "replace", "run", "close", "read-rules"]})

    def test_matched_description_is_canonical_and_path_free(self):
        result = validate_description({"abi": 1, "operations": sorted(REQUIRED_OPERATIONS)})
        self.assertEqual("matched", result["status"])
        self.assertEqual(sorted(REQUIRED_OPERATIONS), result["requiredOperations"])

    def test_text_only_provider_cannot_qualify_modules(self):
        with self.assertRaisesRegex(ValueError, "native-result, open-module"):
            validate_description({'abi': 1, 'operations': ['open-sources', 'source-replace',
                                                         'source-run', 'close']})

    def test_malformed_descriptions_fail_closed(self):
        for value in (None, [], {}, {"abi": True, "operations": sorted(REQUIRED_OPERATIONS)},
                      {"abi": 2, "operations": sorted(REQUIRED_OPERATIONS)},
                      {"abi": 1, "operations": "open-sources"},
                      {"abi": 1, "operations": [1]}, {"abi": 1, "operations": ["close", "close"]}):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validate_description(value)

    def test_probe_binds_selected_provider_and_budget(self):
        observation = SimpleNamespace(exit=0, timeout=False, group_quiescent=True,
                                      stdout=json.dumps({"abi": 1, "operations": sorted(REQUIRED_OPERATIONS)}))
        with patch("gambit_smp.provider_contract.capture", return_value=observation) as capture:
            result = inspect_provider(Path("/tmp/api"), Path("/tmp/python/ascent_engine"))
        argv, cwd, budget, environment = capture.call_args.args
        self.assertEqual(["-I", "-B", "-c"], argv[1:4])
        self.assertEqual([str(Path("/tmp/api").resolve()), str(Path("/tmp/python").resolve())], argv[-2:])
        self.assertEqual(10, budget)
        self.assertEqual("api", environment["ASCENT_ENGINE_BACKEND"])
        self.assertEqual("matched", result["status"])

    def test_timeout_exit_and_nonquiescent_probe_are_denied(self):
        for exit, timeout, quiescent in ((1, False, True), (0, True, True),
                                        (0, False, False), (0, False, None)):
            observation = SimpleNamespace(exit=exit, timeout=timeout, group_quiescent=quiescent)
            with patch("gambit_smp.provider_contract.capture", return_value=observation), \
                    self.assertRaisesRegex(ValueError, "probe failed"):
                inspect_provider(Path("/tmp/api"), Path("/tmp/python/ascent_engine"))
