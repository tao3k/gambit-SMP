"""Assert that durable protocol registration and current checking stay distinct."""

from gambit_smp.framework import digest
from gambit_smp.protocol_evidence import BUNDLES, checked_rows
from gambit_smp.verify_protocols import load_manifest


def assert_current_status(test, root, manifest_name, facts):
    manifest = load_manifest(root / manifest_name)
    receipt_name = dict(BUNDLES)[manifest_name]
    receipt = root / receipt_name
    missing = [name for name in manifest["contextInputs"] if not (root / name).is_file()]
    registered = dict(facts["protocol_model"])
    checked = dict(facts["protocol_checked"])
    for case in manifest["cases"]:
        model = case["id"]
        test.assertEqual(digest(root / "models/gambit" / (model + ".qnt")), registered[model])
        if missing:
            test.assertNotIn(model, checked)
        else:
            test.assertEqual(model, checked_rows(root, manifest, receipt)[0][0])
            test.assertEqual(digest(receipt), checked[model])
    return missing
