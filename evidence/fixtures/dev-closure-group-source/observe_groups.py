"""Bound contiguous literal closure runs in the retained generated cohort.

This is a text census, not a control-flow or complete allocation-batch bound.
"""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
CENSUS = ROOT / "evidence/research/retained/modern-c/stress-gsi/dev-generated-closure-census.json"
PHASE = ROOT / (".cache/tasks/modern-c-frame-contract/runs/"
                "dev-selected-source-core-v3/run/source-core.observation.json")
RAW_PHASE = PHASE.parent / "source-core/observation.json"

def sha(data):
    return hashlib.sha256(data).hexdigest()

base = json.loads(CENSUS.read_text())
phase = json.loads(PHASE.read_text())
tree = ROOT / phase["step"]["outputs"]["runtime"]["workspace"]
if (sha(RAW_PHASE.read_bytes()) != base["sourceCoreObservationSha256"] or
        phase["step"]["artifacts"]["source-core/observation.json"] != sha(RAW_PHASE.read_bytes())):
    raise ValueError("source-core observation identity changed")
if base["generatedFiles"] != 51 or base["nonLiteralSites"]:
    raise ValueError("unexpected generated cohort inventory")
abi = base["selectedAbi"]
overhead = abi["subtypedBodyWords"] + abi["closureExtraWords"]
if abi["trampolineWords"] != 0 or overhead != 2:
    raise ValueError("selected closure ABI differs from the census")
pattern = re.compile(r"___ALLOC_CLO\((\d+)UL\)")
groups = []
count = 0
for name, expected in sorted(base["generatedSourceHashes"].items()):
    raw = (tree / name).read_bytes()
    if sha(raw) != expected:
        raise ValueError(f"generated file identity changed: {name}")
    current = []
    for line_no, line in enumerate(raw.decode().splitlines(), 1):
        occurrences = line.count("___ALLOC_CLO(")
        matches = pattern.findall(line)
        if occurrences != len(matches) or len(matches) > 1:
            raise ValueError(f"nonliteral or multiple closure calls: {name}:{line_no}")
        if matches:
            current.append((line_no, int(matches[0])))
            count += 1
        elif current:
            groups.append((sum(x[1] + overhead for x in current), len(current), name, current[0][0]))
            current = []
    if current:
        groups.append((sum(x[1] + overhead for x in current), len(current), name, current[0][0]))
if count != base["literalSites"] or len(base["generatedSourceHashes"]) != 51:
    raise ValueError("site or file count changed")
maximum = max(row[0] for row in groups)
locations = [dict(words=w, closures=n, path=p, line=line)
             for w, n, p, line in groups if w == maximum]
result = dict(schema="gambit-dev-contiguous-closure-census.v1",
    scope="Consecutive literal ALLOC_CLO lines only in 51 retained generated C files; excludes other allocations, control flow, dynamic code and runtime behavior",
    priorCensus=dict(path=str(CENSUS.relative_to(ROOT)), sha256=sha(CENSUS.read_bytes())),
    sourceCoreObservation=dict(path=str(PHASE.relative_to(ROOT)), sha256=sha(PHASE.read_bytes())),
    sourceCoreRawObservation=dict(path=str(RAW_PHASE.relative_to(ROOT)), sha256=sha(RAW_PHASE.read_bytes())),
    observerSha256=sha(Path(__file__).read_bytes()), generatedFiles=51,
    literalSites=count, contiguousRuns=len(groups), selectedAbi=abi,
    maximumWords=maximum, maximumLocations=locations,
    runtimeAdmitted=False, sourceRefinementAdmitted=False, releaseAdmitted=False, acceptedSmp=5)
if len(sys.argv) != 2:
    raise ValueError("one task-cache output path required")
target = Path(sys.argv[1]).resolve()
if not target.is_relative_to(ROOT / ".cache/tasks/modern-c-frame-contract"):
    raise ValueError("output must belong to the task cache")
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.dumps(result, indent=2) + "\n")
print(target)
