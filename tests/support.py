"""Isolated validator fixtures, never published as research evidence."""
from contextlib import contextmanager
import json
from pathlib import Path
import shutil
import tempfile

from gambit_smp.framework import digest


@contextmanager
def protocol_fixture(repository, manifest_name, receipt_name):
    """Retain checker logs/models but substitute explicitly synthetic context."""
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary).resolve()
        manifest = json.loads((repository / manifest_name).read_text())
        receipt = json.loads((repository / receipt_name).read_text())
        shutil.copytree((repository / receipt_name).parent, (root / receipt_name).parent)
        for case in manifest["cases"]:
            name = "models/gambit/" + case["id"] + ".qnt"
            (root / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(repository / name, root / name)
        for name in manifest["contextInputs"]:
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("Synthetic context for validator unit tests; not native source.\n")
            manifest["contextInputs"][name] = digest(target)
            receipt["inputs"][name] = digest(target)
        (root / manifest_name).parent.mkdir(parents=True, exist_ok=True)
        (root / manifest_name).write_text(json.dumps(manifest))
        (root / receipt_name).write_text(json.dumps(receipt))
        yield root, manifest, root / receipt_name
