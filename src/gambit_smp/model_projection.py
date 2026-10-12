"""Reproducible lexical model composition using Quint's resolved IR and map."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

from gambit_smp.framework import ROOT


def bound_path(root, name, expected):
    if Path(name).is_absolute() or any(p in ("..", ".data") for p in Path(name).parts):
        raise ValueError("durable relative projection path required")
    path = (root / name).resolve()
    path.relative_to(root.resolve())
    if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise ValueError("projection input drift: " + name)
    return path


def project_body(source, source_path, module_name, prefix, parsed, positions):
    if parsed.get("errors") or not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*_", prefix):
        raise ValueError("invalid parsed projection or namespace")
    modules = [m for m in parsed["modules"] if m["name"] == module_name]
    if len(modules) != 1:
        raise ValueError("unique source module required")
    module = modules[0]
    declarations = {d["id"]: d for d in module["declarations"]
                    if d["kind"] in ("def", "var", "typedef")}
    locations = positions["map"]
    indexes = positions["sourceIndex"]
    edits = {}
    offsets, units = {0: 0}, 0
    for index, char in enumerate(source):
        units += 2 if ord(char) > 0xFFFF else 1
        offsets[units] = index + 1

    def renamed(declaration):
        namespace = prefix[0].upper() + prefix[1:] if declaration["kind"] == "typedef" else prefix
        return namespace + declaration["name"]

    def span(node):
        index, start, end = locations[str(node)]
        if Path(indexes[str(index)]).resolve() != source_path.resolve():
            raise ValueError("projection reference escaped its source")
        return offsets[start["index"]], offsets[end["index"] + 1]

    for node, binding in parsed["table"].items():
        if binding["id"] not in declarations:
            continue
        start, _ = span(node)
        name = declarations[binding["id"]]["name"]
        if source[start:start + len(name)] != name:
            raise ValueError("resolved identifier differs from source")
        edits[start, start + len(name)] = renamed(declarations[binding["id"]])
    for node, declaration in declarations.items():
        start, end = span(node)
        name = declaration["name"]
        if source[start:end] == name:
            edits[start, end] = renamed(declaration)
            continue
        pattern = r"(?:pure\s+)?(?:def|var|type|val|action|temporal)\s+(" + re.escape(name) + r")\b"
        match = re.match(pattern, source[start:end])
        if not match:
            raise ValueError("declaration header differs from parsed identity")
        edits[start + match.start(1), start + match.end(1)] = renamed(declaration)
    for declaration in module["declarations"]:
        if declaration["kind"] == "import":
            edits[span(declaration["id"])] = ""
    header = re.match(r"module\s+" + re.escape(module_name) + r"\s*\{", source)
    if not header or not source.rstrip().endswith("}"):
        raise ValueError("single whole source module required")
    edits[0, header.end()] = ""
    edits[source.rfind("}"), len(source)] = ""
    ordered = sorted(edits.items())
    if any(a[0][1] > b[0][0] for a, b in zip(ordered, ordered[1:])):
        raise ValueError("overlapping projection edits")
    for (start, end), value in reversed(ordered):
        source = source[:start] + value + source[end:]
    return source.strip("\n")


def render(root, contract, quint="quint"):
    if contract.get("schema") != "quint-model-projection.v1":
        raise ValueError("unknown model projection schema")
    version = subprocess.run([quint, "--version"], capture_output=True, text=True,
                             timeout=10, check=True).stdout.strip()
    if version != contract["quintVersion"]:
        raise ValueError("projection Quint version differs")
    source = bound_path(root, contract["source"], contract["sourceSha256"])
    template = bound_path(root, contract["template"], contract["templateSha256"])
    with tempfile.TemporaryDirectory(prefix="quint-projection-") as directory:
        ir, mapping = Path(directory) / "ir.json", Path(directory) / "map.json"
        subprocess.run([quint, "parse", str(source), "--out", str(ir),
                        "--source-map", str(mapping)], capture_output=True,
                       text=True, timeout=10, check=True)
        body = project_body(source.read_text(), source, contract["module"],
                            contract["prefix"], json.loads(ir.read_text()),
                            json.loads(mapping.read_text()))
    text = template.read_text()
    marker = contract["marker"]
    if text.count(marker) != 1:
        raise ValueError("unique projection insertion point required")
    return text.replace(marker, body)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("contract", type=Path)
    parser.add_argument("--emit-patch", action="store_true")
    args = parser.parse_args()
    contract = json.loads(args.contract.read_text())
    if Path(contract["target"]).is_absolute() or any(
            p in ("..", ".data") for p in Path(contract["target"]).parts):
        raise ValueError("durable relative projection target required")
    target = (ROOT / contract["target"]).resolve()
    target.relative_to(ROOT.resolve())
    text = render(ROOT, contract)
    if args.emit_patch:
        import difflib
        diff = list(difflib.unified_diff(target.read_text().splitlines(True),
                                        text.splitlines(True)))[2:]
        patch = "*** Begin Patch\n*** Update File: " + str(target) + "\n"
        patch += "".join("@@\n" if line.startswith("@@") else line for line in diff)
        print(json.dumps({"patch": patch + "*** End Patch"}))
    elif target.read_text() != text:
        raise ValueError("generated model differs from its bound projection")
    else:
        print("MODEL-PROJECTION-OK")


if __name__ == "__main__":
    main()
