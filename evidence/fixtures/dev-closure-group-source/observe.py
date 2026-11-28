"""Read-only source correspondence for one materialized DEV producer.

This checks selected text and source identities, not Scheme reachability,
generated control flow, memory safety, or a native execution result.
"""
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
OBSERVATION = ROOT / (".cache/tasks/modern-c-frame-contract/runs/"
                      "dev-resume-limit-object-v1/run/materialize.observation.json")
SOURCE_LOCK = ROOT / "evidence/fixtures/dev-resume-limit-568e/source.lock.json"
FILES = {
    "gsc/_front.scm": ["(make-close", "clo-vars-list"],
    "gsc/_t-c-1.scm": ["(define targ-msection-fudge   4096)"],
    "gsc/_t-c-2.scm": ["(define (targ-gen-close parms sn)",
                        "(map (lambda (parm)", "(targ-closure-space",
                        '(list "ALLOC_CLO"', "(+ targ-msection-fudge heap)"],
    "include/_gambit/module_generation.h.in": ["#define ___CHECK_HEAP(n,m)",
                         "___hp>___ps->heap_limit", "#define ___ALLOC_CLO(n)"],
    "lib/mem.h": ["#define ___MAX_NB_FRAME_SLOTS   8192",
                   "#define ___MSECTION_FUDGE       (___MAX_NB_FRAME_SLOTS+1+___SUBTYPED_BODY)"],
}

def sha(data):
    return hashlib.sha256(data).hexdigest()

observation = json.loads(OBSERVATION.read_text())
source = observation["step"]["outputs"]["source"]
tree = ROOT / source["workspace"]
lock = json.loads(SOURCE_LOCK.read_text())
rows = []
for name, anchors in FILES.items():
    data = (tree / name).read_bytes()
    digest = sha(data)
    recorded = source["identity"][name]["sha256"]
    if digest != recorded:
        raise ValueError(f"materialized source drift: {name}")
    candidate = lock["files"].get(name)
    if candidate and digest != candidate["candidateSha256"]:
        raise ValueError(f"locked source mismatch: {name}")
    lines = data.decode().splitlines()
    locations = {}
    for anchor in anchors:
        found = [i for i, line in enumerate(lines, 1) if anchor in line]
        if not found:
            raise ValueError(f"missing anchor: {name}: {anchor}")
        locations[anchor] = found
    rows.append(dict(path=name, sha256=digest, anchors=locations,
                     explicitlyLocked=bool(candidate)))

result = dict(schema="gambit-dev-closure-group-source-observation.v1",
              scope="Selected materialized source text only; conditional grouped-allocation risk, no reachability or runtime proof",
              observerSha256=sha(Path(__file__).read_bytes()),
              materializeObservation=dict(path=str(OBSERVATION.relative_to(ROOT)),
                                           sha256=sha(OBSERVATION.read_bytes())),
              sourceLock=dict(path=str(SOURCE_LOCK.relative_to(ROOT)), sha256=sha(SOURCE_LOCK.read_bytes())),
              sourceWorkspace=source["workspace"], files=rows,
              runtimeAdmitted=False, sourceRefinementAdmitted=False,
              releaseAdmitted=False, acceptedSmp=5)
output = json.dumps(result, indent=2) + "\n"
if len(sys.argv) != 2:
    raise ValueError("one task-cache output path required")
target = Path(sys.argv[1]).resolve()
if not target.is_relative_to(ROOT / ".cache/tasks/modern-c-frame-contract"):
    raise ValueError("output must belong to the task cache")
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(output)
print(target)
