"""Transport explicit host-reviewed correspondences; Scheme decides usability."""
import json

from gambit_smp.framework import digest, relative
from gambit_smp.native_review import pointer

SCHEMA = "failure-claim-receipt-links.v1"
ROOT_CLAIMS = ("failure-scope-review", "change-relevance-review", "assumptions-review")


def load(root, path, candidates, failures, inventory_sha):
    document = relative(root, path)
    data = json.loads(document.read_text())
    if (set(data) != {"schema", "failureInventorySha256", "links"}
            or data["schema"] != SCHEMA or data["failureInventorySha256"] != inventory_sha
            or not isinstance(data["links"], list)):
        raise ValueError("exact failure inventory and typed review links required")
    inputs = {path: digest(document)}
    specs, rows, claims, seen = {}, [], [], set()
    current = {row[0]: row[2] for row in candidates}
    failures = {row["id"]: row for row in failures}

    def reference(ref):
        if (not isinstance(ref, dict) or set(ref) != {"path", "sha256", "pointer"}
                or not isinstance(ref["pointer"], str)):
            raise ValueError("exact receipt SHA and JSON pointer required")
        source = relative(root, ref["path"])
        if digest(source) != ref["sha256"]:
            raise ValueError("review reference changed: " + ref["path"])
        inputs[ref["path"]] = ref["sha256"]
        value = json.loads(source.read_text())
        # RFC6901's empty pointer names the entire document. The suite gate's
        # event-only pointer helper intentionally accepts nonempty pointers.
        return value if ref["pointer"] == "" else pointer(value, ref["pointer"])

    for link in data["links"]:
        if not isinstance(link, dict) or set(link) != {
                "candidate", "candidateIdentity", "failure", "failureReceipt", "evidence"}:
            raise ValueError("typed failure-claim-receipt link required")
        candidate, failure = link["candidate"], link["failure"]
        if (candidate not in current or current[candidate] != link["candidateIdentity"]
                or failure not in failures or (candidate, failure) in seen):
            raise ValueError("unknown, duplicate or stale review link")
        seen.add((candidate, failure))
        original = link["failureReceipt"]
        reference(original)
        if original["path"] != failures[failure]["receipt"]:
            raise ValueError("review link does not name the original failure receipt")
        evidence = link["evidence"]
        record = reference(evidence)
        claim = "reviewed-causal-link:" + failure
        if (not isinstance(record, dict) or record.get("schema") != "failure-causal-review.v1"
                or record.get("domain") != "causal-review" or record.get("status") != "reviewed"
                or record.get("claim") != claim or record.get("failure") != failure
                or record.get("candidateIdentity") != current[candidate]
                or record.get("failureReceipt") != original
                or not isinstance(record.get("reviews"), dict)
                or set(record["reviews"]) != set(ROOT_CLAIMS)):
            raise ValueError("claim must bind this failure and current candidate")
        receipt = "causal-review:" + evidence["sha256"] + ":" + evidence["pointer"]
        dependencies = []
        for name, ref in record["reviews"].items():
            review = reference(ref)
            if (not isinstance(review, dict) or review.get("domain") != "causal-review"
                    or review.get("status") != "reviewed" or review.get("claim") != name
                    or review.get("candidateIdentity") != current[candidate]
                    or review.get("failureReceipt") != original
                    or not isinstance(review.get("premises"), list)
                    or any(not isinstance(item, str) or not item for item in review["premises"])
                    or len(set(review["premises"])) != len(review["premises"])):
                raise ValueError("typed transitive review premises required")
            qualified = receipt + ":" + name
            dependencies.append(qualified)
            # All referenced bytes remain inputs of each review; no text is
            # interpreted as a proof or as an execution authorization.
            specs[qualified] = {"claim": name + ":" + failure,
                                "depends": list(review["premises"])}
            claims.append([claim, name + ":" + failure])
        specs[receipt] = {"claim": claim, "depends": dependencies}
        rows.append([candidate, failure, current[candidate], original["path"],
                     original["sha256"], claim, receipt])
    for spec in specs.values():
        spec.update(inputs=dict(inputs), binding="recorded")
    return rows, claims, specs, inputs
