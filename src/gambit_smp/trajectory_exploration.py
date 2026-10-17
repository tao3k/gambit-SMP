"""SMP projection into the upstream, non-authorizing Trajectory exploration API."""
import argparse
import json
from pathlib import Path

from gambit_smp.framework import digest
from gambit_smp.reasoning_history import (append_trajectory_attempt,
                                          fingerprint, read_trajectory_attempts)


def _current(snapshot):
    if snapshot.get("executionAuthorized") is not False:
        raise ValueError("recorded-only action snapshot required")
    for path, sha in snapshot["inputs"].items():
        if digest(Path(path)) != sha:
            raise ValueError("trajectory action source changed: " + path)


def candidate(snapshot, action_id, *, check_current=True):
    """Map a discovered SMP action to opaque, source-bound upstream identities."""
    if check_current:
        _current(snapshot)
    actions = [action for action in snapshot["actions"] if action["id"] == action_id]
    if len(actions) != 1:
        raise ValueError("unique discovered action required")
    action = actions[0]
    result = dict(questionIdentity=action["id"], scopeIdentity=action["study"],
                  operationIdentity=action["operation"],
                  inputIdentity=snapshot["sourceIdentity"],
                  toolIdentity=fingerprint(snapshot["backend"]))
    if snapshot.get("engine") is not None:
        result["modelIdentity"] = fingerprint(snapshot["engine"])
    if action["hypothesis"] != "none":
        result["proposalIdentity"] = action["hypothesis"]
    return result


def record(root, scope, snapshot, action_id, handle, *, purpose=None):
    """Retain an existing action request and outcome; never launch an action."""
    from gambit_smp.research_actions import observe

    observed = observe(root, handle)
    request = observed["request"]
    if (request["action"] != action_id or request["sourceIdentity"] != snapshot["sourceIdentity"]
            or request["revision"] != snapshot["revision"] or request["authorization"] is not True):
        raise ValueError("observed action differs from selected source and request")
    proposed = candidate(snapshot, action_id, check_current=False)
    result = observed["result"]
    retained_result = {key: value for key, value in result.items() if key != "inspection"}
    proof = dict(handle=handle, status=result["status"],
                 outcome=result.get("outcome", result["status"]),
                 resultIdentity=fingerprint(retained_result))
    return append_trajectory_attempt(root, scope, snapshot["sourceIdentity"],
                                     proposed, observation=proof,
                                     snapshot_identity=fingerprint(snapshot), purpose=purpose)


def _replay(root, scope, snapshot, engine, *, through=None, proposed=None):
    """Read one retained prefix into a short-lived upstream ledger."""
    from ascent.trajectory import Trajectory

    retained = read_trajectory_attempts(root, scope)
    if through is not None:
        matches = [index for index, event in enumerate(retained) if event["id"] == through]
        if len(matches) != 1:
            raise ValueError("trajectory prefix endpoint must name one retained attempt")
        retained = retained[:matches[0] + 1]
        if retained[-1].get("snapshotIdentity") != fingerprint(snapshot):
            raise ValueError("trajectory prefix snapshot identity mismatch")
    source = retained[0]["sourceIdentity"] if retained else snapshot["sourceIdentity"]
    with Trajectory(engine, scope, source) as trajectory:
        for event in retained:
            if event["sourceIdentity"] != trajectory.source_identity:
                trajectory.invalidate(event["sourceIdentity"])
            fields = dict(event["candidate"])
            if event["purpose"] is not None:
                fields["purpose"] = event["purpose"]
            trajectory.append("attempt", event_id=event["id"], **fields)
        if snapshot["sourceIdentity"] != trajectory.source_identity:
            trajectory.invalidate(snapshot["sourceIdentity"])
        packet = trajectory.context() if proposed is None else trajectory.explore(proposed)
    return packet, retained


def context(root, scope, snapshot, engine, *, through=None):
    """Expose retained observations before selecting any action or hypothesis."""
    _current(snapshot)
    packet, retained = _replay(root, scope, snapshot, engine, through=through)
    _current(snapshot)
    return dict(packet, historyThrough=through, replayedAttempts=len(retained),
                openPredictions=snapshot["research"]["openPredictions"],
                discriminators=snapshot["research"]["discriminators"],
                executionAuthorized=False, runtimeAdmitted=False)


def inspect(root, scope, snapshot, action_id, engine, *, through=None):
    """Compare a chosen candidate with durable attempts; never choose it."""
    from gambit_smp.ascent_program import load_component_catalog, query

    proposed = candidate(snapshot, action_id)
    packet, retained = _replay(root, scope, snapshot, engine,
                               through=through, proposed=proposed)
    catalog = load_component_catalog(
        Path(__file__).resolve().parents[2] / "evidence/dsl/trajectory-review.components.json",
        entry="trajectory-review", constructor="make-trajectory-review", trusted=True)
    facts = {
        "comparison": [(row["earlierEvent"], row["relation"])
                       for row in packet["comparisons"]],
        "attempt": [(event["id"], ordinal, event["observation"]["status"],
                     event["observation"]["outcome"], event["purpose"] or "")
                    for ordinal, event in enumerate(retained)],
    }
    review = query(facts, catalog, {
        "repeatedObservation": "repeated_observation",
        "repeatCandidates": "repeat_candidate",
        "intentionalReplication": "intentional_replication",
        "comparisonUnknown": "comparison_unknown",
        "changedPremise": "changed_premise",
        "historical": "historical",
    }, engine=engine)
    _current(snapshot)
    action = next(action for action in snapshot["actions"] if action["id"] == action_id)
    return dict(packet, action=action_id, historyThrough=through,
                replayedAttempts=len(retained),
                openPredictions=snapshot["research"]["openPredictions"],
                discriminators=snapshot["research"]["discriminators"],
                sameInputFailures=action["explanation"]["sameInputFailures"],
                review=review,
                executionAuthorized=False, runtimeAdmitted=False)


def main():
    from gambit_smp.framework import ROOT

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=("record", "inspect", "context"))
    parser.add_argument("--request", type=Path, required=True)
    args = parser.parse_args()
    request = json.loads(args.request.read_text())
    common = {"scope", "snapshot", "action"}
    if args.operation == "record":
        if set(request) not in (common | {"handle"}, common | {"handle", "purpose"}):
            raise ValueError("record requires scope, snapshot, action and observed handle")
        result = record(ROOT, request["scope"], request["snapshot"], request["action"],
                        request["handle"], purpose=request.get("purpose"))
    else:
        required = common if args.operation == "inspect" else {"scope", "snapshot"}
        if set(request) not in (required, required | {"through"}):
            raise ValueError(args.operation + " requires " + ", ".join(sorted(required))
                             + " and optional through")
        from gambit_smp.ascent_program import engine_api

        with engine_api() as (engine, _):
            if args.operation == "context":
                result = context(ROOT, request["scope"], request["snapshot"], engine,
                                 through=request.get("through"))
            else:
                result = inspect(ROOT, request["scope"], request["snapshot"],
                                 request["action"], engine, through=request.get("through"))
    print(json.dumps(result, sort_keys=True, allow_nan=False))


if __name__ == "__main__":
    main()
