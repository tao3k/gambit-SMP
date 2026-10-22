"""Cache paginated public GitHub SMP evidence; never apply patches or run tests."""
from gambit_smp.task_processes import check_output as _task_check_output
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess

REPO = "gambit/gambit"
BOUNTY_START = "2022-08-04T11:56:37Z"
SIGNALS = re.compile(r"smp|parallel.{0,20}(gc|collect)|multiple.{0,12}vm|"
                     r"thread.{0,30}(race|hang|crash|terminat|priority|mailbox)|"
                     r"continuation.{0,40}(ownership|overflow|stack)", re.I)
CRITICAL_SOURCE = {"lib/mem.c", "lib/setup.c", "lib/os_thread.c", "lib/os_io.c",
                   "lib/_thread.scm", "lib/_kernel.scm", "lib/_system.scm",
                   "lib/c_intf.c", "include/gambit.h.in", "include/gambit.h"}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def api(endpoint, cache, name):
    target = cache / (name + ".json")
    if target.exists():
        return json.loads(target.read_text())
    output = _task_check_output(["gh", "api", endpoint], timeout=45)
    result = json.loads(output)
    temporary = target.with_suffix(".partial")
    temporary.write_bytes(output)
    temporary.replace(target)
    return result


def pages(endpoint, cache, name, max_pages=20):
    result = []
    for page in range(1, max_pages + 1):
        items = api(endpoint + f"?per_page=100&page={page}", cache, f"{name}-{page}")
        if not isinstance(items, list):
            raise ValueError("expected paginated GitHub array")
        result.extend(items)
        if len(items) < 100:
            return result
    raise ValueError("pagination bound reached; incomplete snapshot rejected")


def discovery(cache):
    rows = []
    for page in range(1, 21):
        items = api(f"repos/{REPO}/pulls?state=all&sort=created&direction=desc&per_page=100&page={page}",
                    cache, f"pull-index-{page}")
        for item in items:
            if item["created_at"] >= BOUNTY_START:
                body = item.get("body") or ""
                hits = sorted({m.group(0).lower() for m in SIGNALS.finditer(item["title"] + "\n" + body)})
                rows.append({"number": item["number"], "title": item["title"],
                             "head": item["head"]["sha"], "base": item["base"]["sha"],
                             "url": item["html_url"], "state": item["state"],
                             "createdAt": item["created_at"], "updatedAt": item["updated_at"],
                             "bodySha256": sha(body.encode()), "signals": hits,
                             "disposition": "requires-human-triage" if hits else "no-discovery-signal"})
        if len(items) < 100 or any(item["created_at"] < BOUNTY_START for item in items):
            break
    else:
        raise ValueError("discovery pagination bound reached")
    if len({row["number"] for row in rows}) != len(rows):
        raise ValueError("duplicate discovery PR")
    bounty = api(f"repos/{REPO}/issues/760", cache, "bounty")
    comments = pages(f"repos/{REPO}/issues/760/comments", cache, "bounty-comments")
    linked = sorted({int(number) for item in [bounty, *comments]
                     for number in re.findall(r"(?:github\.com/gambit/gambit/pull/|(?<!\w)#)(\d+)", item.get("body") or "")})
    result = {"schema": "gambit-smp-discovery.v1", "repository": REPO,
              "capturedAt": datetime.now(timezone.utc).isoformat(),
              "windowStart": BOUNTY_START, "windowKind": "created-since-bounty",
              "completeCreatedWindow": True, "bountyLinkedNumbers": linked,
              "selectionBoundary": "heuristic signals require human review; no completeness claim for implicit issues",
              "pulls": sorted(rows, key=lambda row: row["number"])}
    (cache / "discovery.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def snapshot(number, cache):
    metadata = api(f"repos/{REPO}/pulls/{number}", cache, f"pr-{number}")
    files = pages(f"repos/{REPO}/pulls/{number}/files", cache, f"pr-{number}-files")
    comments = pages(f"repos/{REPO}/issues/{number}/comments", cache, f"pr-{number}-comments")
    reviews = pages(f"repos/{REPO}/pulls/{number}/reviews", cache, f"pr-{number}-reviews")
    inline = pages(f"repos/{REPO}/pulls/{number}/comments", cache, f"pr-{number}-inline")
    final = _task_check_output(["gh", "api", f"repos/{REPO}/pulls/{number}"], timeout=45)
    current = json.loads(final)
    if (metadata["head"]["sha"], metadata["base"]["sha"], metadata["updated_at"]) != (
            current["head"]["sha"], current["base"]["sha"], current["updated_at"]):
        raise ValueError("PR changed during snapshot; use a fresh cache directory")
    if metadata["changed_files"] != len(files) or len({f["filename"] for f in files}) != len(files):
        raise ValueError("incomplete or duplicate PR file inventory")
    row = {"number": number, "url": metadata["html_url"], "title": metadata["title"],
           "head": metadata["head"]["sha"], "base": metadata["base"]["sha"],
           "state": metadata["state"], "merged": metadata["merged"],
           "updatedAt": metadata["updated_at"], "bodySha256": sha((metadata.get("body") or "").encode()),
           "reportEvidence": "public-author-or-review-reports-not-native-acceptance",
           "comments": [{"id": c["id"], "url": c["html_url"],
                         "bodySha256": sha((c.get("body") or "").encode())}
                        for c in [*comments, *reviews, *inline]],
           "reviewStates": [r["state"] for r in reviews],
           "files": [{"file": f["filename"], "blobSha": f["sha"], "status": f["status"],
                      "additions": f["additions"], "deletions": f["deletions"],
                      "apiPatchPresent": "patch" in f,
                      "apiPatchSha256": sha(f["patch"].encode()) if "patch" in f else None}
                     for f in files]}
    (cache / f"pr-{number}-snapshot.json").write_text(json.dumps(row, indent=2) + "\n")
    return row


def issue_snapshot(number, cache):
    metadata = api(f"repos/{REPO}/issues/{number}", cache, f"issue-{number}")
    if "pull_request" in metadata:
        raise ValueError("issue snapshot requires an issue, not a PR")
    comments = pages(f"repos/{REPO}/issues/{number}/comments", cache, f"issue-{number}-comments")
    current = json.loads(_task_check_output(["gh", "api", f"repos/{REPO}/issues/{number}"], timeout=45))
    if metadata["updated_at"] != current["updated_at"]:
        raise ValueError("issue changed during snapshot; use a fresh cache")
    row = {"number": number, "url": metadata["html_url"], "title": metadata["title"],
           "state": metadata["state"], "updatedAt": metadata["updated_at"],
           "bodySha256": sha((metadata.get("body") or "").encode()),
           "reportEvidence": "public-report-not-local-reproduction",
           "comments": [{"id": c["id"], "url": c["html_url"],
                         "bodySha256": sha((c.get("body") or "").encode())} for c in comments]}
    (cache / f"issue-{number}-snapshot.json").write_text(json.dumps(row, indent=2) + "\n")
    return row


def footprint_bound(row, files, snapshot):
    return (snapshot is not None and row["head"] == snapshot["head"]
            and row["base"] == snapshot["base"]
            and {(f["file"], f["blobSha"]) for f in files}
            == {(f["file"], f["blobSha"]) for f in snapshot["files"]})


def export_triage(cache, target):
    """Offline inventory classification, not a semantic exclusion proof."""
    discovery_path = target / "discovery.json"
    discovered = json.loads(discovery_path.read_text())
    catalog_path = target.parents[2] / "models/gambit/report_catalog.json"
    catalog = json.loads(catalog_path.read_text())
    included = {r["number"] for r in catalog["reports"]}
    window = json.loads((cache / "window-files.json").read_text())
    if window["discoverySha256"] != sha(discovery_path.read_bytes()):
        raise ValueError("window discovery digest mismatch")
    rows = {r["number"]: r for r in discovered["pulls"]}
    if set(rows) != {r["number"] for r in window["pulls"]}:
        raise ValueError("incomplete window inventory")
    triage = []
    for footprint in window["pulls"]:
        number = footprint["number"]
        row = rows[number]
        snapshot_path = target / f"pr-{number}-snapshot.json"
        saved = json.loads(snapshot_path.read_text()) if snapshot_path.exists() else None
        footprint["headBound"] = footprint_bound(row, footprint["files"], saved)
        overlap = sorted({f["file"] for f in footprint["files"]} & CRITICAL_SOURCE)
        if number in included:
            disposition = "catalog-included"
            reason = "exact-head snapshot; model and native acceptance tracked separately"
        elif overlap or row["signals"] or number in discovered["bountyLinkedNumbers"]:
            disposition = "adjacent-source-overlap-review-open"
            reason = "source overlap or discovery signal requires semantic review"
        else:
            disposition = "no-signal-or-critical-source-overlap"
            reason = "outside current protocol triage scope; not proof of absence of SMP bugs"
        triage.append({"number": number, "url": row["url"], "title": row["title"],
                       "disposition": disposition, "reason": reason, "criticalFiles": overlap})
    output = target / "window-files.json"
    output.write_text(json.dumps(window, indent=2) + "\n")
    root = target.parents[2]
    inputs = {str(p.relative_to(root)): sha(p.read_bytes()) for p in
              (discovery_path, output, target / "classification.json")}
    result = {"schema": "gambit-smp-window-triage.v1", "inputs": inputs,
              "boundary": "complete creation-window inventory, not complete semantic audit or native acceptance",
              "pulls": triage}
    (target / "triage.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--cache", type=runtime_argument, required=True)
    parser.add_argument("--discover", action="store_true")
    parser.add_argument("--window-files", action="store_true",
                        help="inventory changed files for every PR in the cached creation window")
    parser.add_argument("--prs", type=int, nargs="+")
    parser.add_argument("--issues", type=int, nargs="+")
    parser.add_argument("--export-triage", type=Path, help="offline export to existing tracked evidence directory")
    args = parser.parse_args()
    if not args.discover and not args.prs and not args.issues and not args.window_files and not args.export_triage:
        parser.error("select discovery or explicit PR snapshots")
    args.cache.mkdir(parents=True, exist_ok=True)
    if args.discover:
        result = discovery(args.cache)
        print(f"DISCOVERY-OK: {len(result['pulls'])} PRs in created window", flush=True)
        print(json.dumps([{k: row[k] for k in ("number", "title", "signals")}
                          for row in result["pulls"] if row["signals"]]), flush=True)
    if args.window_files:
        result = json.loads((args.cache / "discovery.json").read_text())
        footprints = []
        for row in result["pulls"]:
            number = row["number"]
            files = pages(f"repos/{REPO}/pulls/{number}/files", args.cache, f"pr-{number}-files")
            if len({f["filename"] for f in files}) != len(files):
                raise ValueError("duplicate window file inventory")
            portable = [{"file": f["filename"], "blobSha": f["sha"]} for f in files]
            snapshot_path = args.cache / f"pr-{number}-snapshot.json"
            saved = json.loads(snapshot_path.read_text()) if snapshot_path.exists() else None
            footprints.append({"number": number, "indexHead": row["head"],
                               "headBound": footprint_bound(row, portable, saved), "files": portable})
            print(f"WINDOW-FILES-OK: {number}, {len(files)} files", flush=True)
        (args.cache / "window-files.json").write_text(json.dumps({
            "schema": "gambit-smp-window-files.v1", "discoverySha256": sha((args.cache / "discovery.json").read_bytes()),
            "scope": "source-footprint triage; unbound heads require full snapshot before admission",
            "pulls": footprints}, indent=2) + "\n")
    for number in sorted(set(args.prs or [])):
        if number <= 0:
            parser.error("invalid PR number")
        row = snapshot(number, args.cache)
        print(f"PR-SNAPSHOT-OK: {number}, {row['head']}, {len(row['files'])} files, "
              f"{len(row['comments'])} comments/reviews", flush=True)
    if args.export_triage:
        result = export_triage(args.cache, args.export_triage)
        counts = {kind: sum(r["disposition"] == kind for r in result["pulls"])
                  for kind in sorted({r["disposition"] for r in result["pulls"]})}
        print(json.dumps(counts, sort_keys=True))
    for number in sorted(set(args.issues or [])):
        if number <= 0:
            parser.error("invalid issue number")
        row = issue_snapshot(number, args.cache)
        print(f"ISSUE-SNAPSHOT-OK: {number}, {len(row['comments'])} comments")


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('upstream-snapshot')(main)

if __name__ == "__main__":
    main()
