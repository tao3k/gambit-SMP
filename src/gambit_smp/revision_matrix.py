"""Evidence-bound quantitative rows for REV comments; no benchmark executor."""
from decimal import Decimal, localcontext
import hashlib
import json
from pathlib import Path


def _digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalize_matrix(root, matrix, source, fields, kinds, *, efficiency_policy=None):
    """Read typed values from durable evidence; never accept literal report numbers.

    A directionally favorable observation is not a causal/statistical performance
    theorem. Control, accounting and structural rows cannot claim runtime speedup.
    """
    root = Path(root).resolve()
    if (not isinstance(matrix, dict) or "rows" not in matrix
            or set(matrix) - {"rows", "claim", "benchmark"}):
        raise ValueError("REV matrix requires rows")
    rows = matrix["rows"]
    if not isinstance(rows, list) or not rows:
        raise ValueError("REV matrix requires at least one row")
    evidence, result, seen = {}, [], set()
    row_evidence = {}

    def file(name):
        if not isinstance(name, str):
            raise ValueError("matrix evidence path must be text")
        p = Path(name)
        if (p.is_absolute() or ".." in p.parts or ".cache" in p.parts
                or not (root / p).is_file()
                or not (root / p).resolve().is_relative_to(root)):
            raise ValueError("matrix requires durable repository evidence")
        evidence[str(p)] = _digest(root / p)
        row_evidence[str(p)] = evidence[str(p)]
        return root / p

    def value(ref, unit, kind):
        if ref is None:
            return None, 0
        if not isinstance(ref, dict) or set(ref) != {"path", "pointer"}:
            raise ValueError("matrix numbers require evidence references")
        record = json.loads(file(ref["path"]).read_text())
        for key, expected in (("sourceTree", source["tree"]),
                              ("profileSha256", source["profileSha256"]),
                              ("baseRevision", source["baseRevision"])):
            if record.get(key) != expected:
                raise ValueError("matrix evidence source/profile mismatch")
        pointer = ref["pointer"]
        if not isinstance(pointer, str) or not pointer.startswith("/"):
            raise ValueError("matrix evidence requires a JSON pointer")
        try:
            for token in pointer[1:].split("/"):
                token = token.replace("~1", "/").replace("~0", "~")
                if isinstance(record, list):
                    if not token.isdecimal() or str(int(token)) != token:
                        raise ValueError("invalid array index")
                    record = record[int(token)]
                else:
                    record = record[token]
        except (KeyError, IndexError, TypeError, ValueError) as exc:
            raise ValueError("matrix evidence pointer is missing") from exc
        if (not isinstance(record, dict) or set(record) != {"value", "unit", "samples", "origin"}
                or record["unit"] != unit):
            raise ValueError("matrix evidence unit/schema mismatch")
        raw, n = record["value"], record["samples"]
        if isinstance(raw, bool) or not isinstance(raw, (int, float, str)):
            raise ValueError("matrix value must be a finite nonnegative number")
        try:
            number = Decimal(str(raw))
        except Exception as exc:
            raise ValueError("invalid matrix number") from exc
        if not number.is_finite() or number < 0:
            raise ValueError("matrix value must be a finite nonnegative number")
        if (type(n) is not int or n < 0 or
                (kind in {"measurement", "control"} and n < 1) or
                (kind in {"accounted-cost", "structural"} and n != 0)):
            raise ValueError("matrix sample count disagrees with observation kind")
        origin = record["origin"]
        if not isinstance(origin, dict) or set(origin) != {"path", "pointer"}:
            raise ValueError("matrix quantity requires raw provenance")
        raw_document = json.loads(file(origin["path"]).read_text())
        for names, expected in [(("sourceTree", "tree", "targetTree", "candidateTree"), source["tree"]),
                                (("profileSha256",), source["profileSha256"]),
                                (("baseRevision", "base"), source["baseRevision"])]:
            observed = [raw_document[key] for key in names if key in raw_document]
            if not observed or any(item != expected for item in observed):
                raise ValueError("raw matrix provenance source/profile mismatch")
        pointer = origin["pointer"]
        if not isinstance(pointer, str) or not pointer.startswith("/"):
            raise ValueError("raw matrix provenance needs a JSON pointer")
        try:
            for token in pointer[1:].split("/"):
                token = token.replace("~1", "/").replace("~0", "~")
                if isinstance(raw_document, list):
                    if not token.isdecimal() or str(int(token)) != token:
                        raise ValueError("invalid array index")
                    raw_document = raw_document[int(token)]
                else:
                    raw_document = raw_document[token]
        except (KeyError, IndexError, TypeError, ValueError) as exc:
            raise ValueError("raw matrix provenance pointer is missing") from exc
        if isinstance(raw_document, dict):
            if (isinstance(raw_document.get("value"), bool)
                    or type(raw_document.get("samples")) is not int
                    or any(raw_document.get(key) != record[key] for key in ("value", "unit", "samples"))):
                raise ValueError("quantity disagrees with raw evidence")
        else:
            expected_samples = 1 if kind in {"measurement", "control"} else 0
            if (isinstance(raw_document, bool) or
                    not isinstance(raw_document, (str, int, float)) or
                    Decimal(str(raw_document)) != number or n != expected_samples):
                raise ValueError("quantity or sample count disagrees with raw evidence")
        return number, n

    for row in rows:
        row_evidence = {}
        if (not isinstance(row, dict) or not set(fields) <= set(row)
                or set(row) - set(fields) - {"dimension"}):
            raise ValueError("matrix row must supply every SysML field")
        if "dimension" in row and (not isinstance(row["dimension"], str) or not row["dimension"]):
            raise ValueError("matrix dimension must be explicit")
        for key in set(fields) - {"baseline", "candidate", "evidence"}:
            if not isinstance(row[key], str) or not row[key].strip():
                raise ValueError("matrix row text must be explicit")
        if row["id"] in seen:
            raise ValueError("duplicate matrix row identity")
        seen.add(row["id"])
        kind, direction = row["kind"], row["direction"]
        if kind not in kinds or direction not in {"lower", "higher", "none"}:
            raise ValueError("unknown matrix kind/direction")
        if kind in {"measurement", "control"} and direction == "none":
            raise ValueError("measured comparison requires a direction")
        if not isinstance(row["evidence"], list) or not row["evidence"]:
            raise ValueError("matrix row needs evidence")
        for name in row["evidence"]:
            file(name)
        before, bn = value(row["baseline"], row["unit"], kind)
        after, cn = value(row["candidate"], row["unit"], kind)
        if kind == "unmeasured":
            if before is not None or after is not None:
                raise ValueError("unmeasured row cannot contain invented numbers")
        elif after is None:
            raise ValueError("matrix candidate value required")
        if kind == "control" and before is None:
            raise ValueError("control requires both observations")
        delta = percent = ratio = None
        if before is not None and after is not None:
            with localcontext() as context:
                context.prec = 28
                delta = after - before
                if before != 0:
                    percent, ratio = delta / before * 100, after / before
        outcome = {"control": "control-only", "accounted-cost": "accounted-cost",
                   "structural": "structural-only", "unmeasured": "not-measured"}.get(kind)
        if kind == "measurement":
            outcome = "candidate-only-observation"
            if delta is not None:
                favorable = delta < 0 if direction == "lower" else delta > 0
                outcome = ("no-observed-change" if delta == 0 else
                           "observed-improvement" if favorable else "observed-regression")
        if outcome is None:
            raise ValueError("matrix kind has no defined semantics")
        string = lambda number: None if number is None else format(number, "f")
        result.append(dict(row, baseline_value=string(before), candidate_value=string(after),
                           baseline_samples=bn, candidate_samples=cn,
                           delta=string(delta), delta_percent=string(percent),
                           candidate_over_baseline=string(ratio), outcome=outcome,
                           generalized_performance_claim=False, evidenceSha256=dict(row_evidence)))
    normalized = dict(source={k: source[k] for k in ("baseRevision", "tree", "profileSha256")},
                      input=matrix, rows=result, evidence=evidence)
    normalized["efficiency"] = efficiency_evidence(
        root, normalized, source, efficiency_policy, file)
    return normalized



def benefit_admission(matrix, *, integration=False):
    """A favorable row never offsets a measured regression in another row.

    Input is the source-verified normalized matrix, not a caller's narrative.
    This conservative publication gate establishes neither causality nor a
    statistically stable speedup. Unmeasured/control/structural rows cannot
    supply positive measured benefit for a runtime integration.
    """
    positive = [row['id'] for row in matrix['rows']
                if row['outcome'] == 'observed-improvement']
    regressions = [row['id'] for row in matrix['rows']
                   if row['outcome'] == 'observed-regression']
    reasons = (['measured-regression'] if regressions else [])
    if integration and not positive:
        reasons.append('positive-benefit-unproven')
    efficiency = matrix.get("efficiency", {"claim": "foundation"})
    if efficiency["claim"] == "efficiency-upgrade":
        reasons.extend(efficiency.get("reasons", []))
        if not efficiency.get("benchmarkQualified"):
            reasons.append("efficiency-upgrade-unproven")
        if not positive:
            reasons.append("positive-efficiency-benefit-unproven")
    return dict(admitted=not reasons, positiveRows=positive,
                regressionRows=regressions, reasons=reasons)



def render_matrix(matrix):
    def cell(value):
        if value is None:
            return "unmeasured"
        return str(value).replace("|", "\\|").replace("\n", "<br>")
    lines = ["", "REV benefit/cost matrix", "",
             "| Metric / kind | Baseline | Candidate | Unit | N base/candidate | Delta % | Interpretation | Workload / method / limit | Evidence |",
             "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
    for row in matrix["rows"]:
        values = [row["metric"]+" / "+row["kind"], row["baseline_value"],
                  row["candidate_value"], row["unit"],
                  str(row["baseline_samples"])+"/"+str(row["candidate_samples"]),
                  row["delta_percent"], row["outcome"], row["workload"]+"; "+row["method"]+"; "+row["limitation"], ", ".join(sorted(row["evidenceSha256"]))]
        lines.append("| "+" | ".join(map(cell, values))+" |")
    lines += ["", "Numbers are scoped observations or source accounting; sample counts, workloads,",
              "methods, limits and evidence digests are retained in the bound audit JSON.",
              "Control timings and structural benefits do not establish a runtime speedup."]
    return "\n".join(lines)

def efficiency_evidence(root, matrix, source, policy, file):
    """Qualify a declared benchmark population, not an attractive metric label."""
    request = matrix["input"]
    claim = request.get("claim", "foundation")
    if claim not in {"foundation", "efficiency-upgrade"}:
        raise ValueError("explicit foundation or efficiency-upgrade claim required")
    required = policy["requiredMetrics"].split(";") if policy else []
    result = dict(claim=claim, required=required, covered=[], benchmarkQualified=False,
                  fixedOverheadAccounted=False, reasons=[])
    if claim == "foundation":
        return result
    if not policy:
        result["reasons"].append("efficiency-policy-unbound")
        return result
    reference = request.get("benchmark")
    if not isinstance(reference, dict) or set(reference) != {"path", "sha256"}:
        result["reasons"].append("matched-benchmark-missing")
        return result
    path = file(reference["path"])
    if _digest(path) != reference["sha256"]:
        raise ValueError("matched benchmark evidence changed")
    packet = json.loads(path.read_text())
    if any(packet.get(k) != v for k, v in (
            ("sourceTree", source["tree"]), ("baseRevision", source["baseRevision"]),
            ("profileSha256", source["profileSha256"]))):
        raise ValueError("matched benchmark source/profile mismatch")
    native_ref = packet.get("nativeReceipt")
    if not isinstance(native_ref, dict) or set(native_ref) != {"path", "sha256"}:
        result["reasons"].append("native-benchmark-receipt-missing")
        return result
    native_path = file(native_ref["path"])
    if _digest(native_path) != native_ref["sha256"]:
        raise ValueError("native benchmark receipt changed")
    native = json.loads(native_path.read_text())
    if (native.get("complete") is not True
            or any(native.get(k) != packet.get(k) for k in
                   ("sourceTree", "baseRevision", "profileSha256"))
            or not native.get("processes")
            or any(p.get("exit") != 0 or p.get("timeout") is not False
                   or p.get("parentReaped") is not True or p.get("processGroupQuiescent") is not True
                   for p in native["processes"])
            or any(native_ref["path"] not in row["evidenceSha256"]
                   for row in matrix["rows"] if row.get("dimension") in required)):
        result["reasons"].append("native-benchmark-unsettled-or-unbound")
        return result
    plan_ref = packet.get("samplePlan")
    if not isinstance(plan_ref, dict) or set(plan_ref) != {"path", "sha256"}:
        result["reasons"].append("predeclared-sample-plan-missing")
        return result
    plan_path = file(plan_ref["path"])
    if _digest(plan_path) != plan_ref["sha256"] or plan_ref["sha256"] != packet.get("samplePlanSha256"):
        raise ValueError("matched benchmark sample plan changed")
    plan = json.loads(plan_path.read_text())
    if any(plan.get(k) != packet.get(k) for k in
           ("plannedSamples", "workloadSha256", "limitsSha256", "rssScope", "costsIncluded")):
        raise ValueError("benchmark population differs from its predeclared plan")
    identity = lambda x: isinstance(x, str) and len(x) == 64 and all(c in "0123456789abcdef" for c in x)
    matched = all(identity(packet.get(k)) and packet.get(k) == packet.get("baseline" + k[0].upper() + k[1:])
                  for k in ("workloadSha256", "limitsSha256"))
    if (packet.get("complete") is not True or packet.get("selection") != "all-planned"
            or packet.get("excludedSamples") != [] or not matched
            or packet.get("controlsComplete") is not True
            or not set(policy["includedCosts"].split(";")) <= set(packet.get("costsIncluded", []))
            or not isinstance(packet.get("rssScope"), str) or not packet["rssScope"].strip()
            or packet.get("baselineRssScope") != packet["rssScope"]
            or not isinstance(packet.get("samplePlanSha256"), str)
            or not identity(packet["samplePlanSha256"])):
        result["reasons"].append("benchmark-population-or-accounting-incomplete")
        return result
    planned = packet.get("plannedSamples", {})
    for dimension in required:
        rows = [row for row in matrix["rows"] if row.get("dimension") == dimension]
        count = planned.get(dimension)
        if (type(count) is int and count > 1 and rows and all(
                row["kind"] == "measurement" and row["baseline_value"] is not None
                and row["candidate_value"] is not None
                and row["baseline_samples"] == count == row["candidate_samples"]
                for row in rows)):
            result["covered"].append(dimension)
        else:
            result["reasons"].append("systematic-" + dimension + "-missing")
    result["fixedOverheadAccounted"] = any(
        row.get("dimension") == policy["fixedOverhead"]
        and row["kind"] in {"measurement", "accounted-cost"}
        and row["baseline_value"] is not None and row["candidate_value"] is not None
        for row in matrix["rows"])
    if not result["fixedOverheadAccounted"]:
        result["reasons"].append("fixed-overhead-unaccounted")
    if not all(isinstance(packet.get(k), str) and packet[k].strip()
               for k in ("avoidedFixedWork", "residualFixedWork")):
        result["reasons"].append("fixed-work-ledger-missing")
    result["benchmarkQualified"] = not result["reasons"]
    return result
