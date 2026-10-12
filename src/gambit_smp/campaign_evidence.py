"""Bind recorded native campaigns and project their observations into ASCENT.

This adapter does not authorize retries or reinterpret native outcomes. Policy
dispositions come from the native DSL; historical missing observations stay gaps.
"""
import json
from pathlib import Path

from gambit_smp.ascent_program import evaluate, load_evidence_catalog
from gambit_smp.framework import digest, relative
from gambit_smp.reasoning_history import fingerprint
from gambit_smp.recipes import inspect_run


OUTPUTS = ("CampaignKnownFailure", "CampaignOpenPremise", "CampaignActualOutcome",
           "CampaignFailure", "CampaignEligibility", "CampaignDisposition")
SOURCES = ("CampaignIdentity", "CampaignStatus", "RetryDecision", "KnownSelected",
           "RetryDenied", "RetryMissing", "RetryEligible", "NativeStepOutcome",
           "ObservedCommand", "CampaignGap")


def collect(root, paths, engine):
    root = Path(root).resolve()
    inputs, packets = {}, []
    policy = root / "evidence/campaign-rules.ss"
    catalog = load_evidence_catalog(policy, constructor="make-campaign", trusted=True)
    inputs[str(policy.relative_to(root))] = digest(policy)

    def bind(path, expected=None):
        path = path.resolve(strict=True)
        name = str(path.relative_to(root))
        actual = digest(path)
        if expected is not None and actual != expected:
            raise ValueError("campaign archive identity drift: " + name)
        if name in inputs and inputs[name] != actual:
            raise ValueError("campaign input changed during intake")
        inputs[name] = actual
        return name, actual

    for requested in paths:
        directory = Path(requested)
        directory = (root / directory if not directory.is_absolute() else directory).resolve(strict=True)
        directory.relative_to(root)
        receipt_path = directory / "receipt.json"
        receipt_name, receipt_sha = bind(receipt_path)
        receipt = json.loads(receipt_path.read_text())
        inspected = inspect_run(directory)
        if not isinstance(receipt.get("steps"), list):
            raise ValueError("campaign recipe steps required")
        ids = [step["id"] for step in receipt["steps"]]
        if len(ids) != len(set(ids)):
            raise ValueError("unique campaign step ids required")
        for step in receipt["steps"]:
            if step.get("capability") not in {"gambit.bootstrap", "gambit.suite", "native.test", "native.c-build"}:
                continue
            step_dir = relative(directory, step["id"])
            facts = {name: [] for name in SOURCES}
            cid = fingerprint([receipt_sha, step["id"]])
            gaps = []
            artifact_refs = {}
            for name, expected in step.get("artifacts", {}).items():
                archive = relative(directory, name)
                artifact_refs[name] = dict(zip(("path", "sha256"), bind(archive, expected)))
            retry_path = step_dir / "retry-preflight.json"
            retry = None
            if retry_path.is_file():
                reference = str(retry_path.relative_to(directory))
                if reference not in artifact_refs:
                    raise ValueError("campaign retry record lacks a receipt artifact binding")
                retry = json.loads(retry_path.read_text())
                if retry.get("schema") != "typed-suite-retry-review.v2":
                    gaps.append("unsupported-retry-record")
                    retry = None
            else:
                gaps.append("missing-typed-retry-record")
            campaign = retry["campaign"] if retry else {}
            if retry:
                args = step.get("arguments", {})
                if (campaign["mode"] != args.get("mode", campaign["mode"])
                        or campaign["regime"] != args.get("regime", campaign["regime"])
                        or campaign["suiteBudgetSeconds"] != step["budgetSeconds"]
                        or campaign["recipeBudgetSeconds"] != receipt["budgetSeconds"]):
                    raise ValueError("campaign retry topology or budget mismatch")
                if retry.get("executionAuthorized") is not False or retry.get("runtimeAdmitted") is not False:
                    raise ValueError("retry record cannot grant execution or runtime admission")
                facts["RetryDecision"].append([cid, retry["decision"]])
                answers = retry["answers"]
                decision = answers.get("decision", [])
                if decision != [[retry["decision"]]]:
                    raise ValueError("campaign retry disposition disagrees with native answer")
                for source, answer, arity in (("KnownSelected", "selected", 2),
                    ("RetryDenied", "denied", 2), ("RetryMissing", "missing", 2),
                    ("RetryEligible", "eligible", 2)):
                    rows = answers[answer]
                    if not isinstance(rows, list) or any(not isinstance(row, list) or len(row) != arity
                        or any(not isinstance(value, str) for value in row) for row in rows):
                        raise ValueError("typed campaign native answer shape required")
                    facts[source].extend([cid, *(row[:1] if source == "KnownSelected" else row)] for row in rows)
                for name, expected in retry["inputs"].items():
                    path = relative(root, name)
                    # Input retirement is a stale scope, not archive corruption.
                    if not path.is_file() or digest(path) != expected:
                        gaps.append("retry-input-retired:" + name)
                    elif path.is_file():
                        bind(path, expected)
            engine_id = receipt.get("engine", {}).get("engineId", "unbound-engine")
            if engine_id == "unbound-engine":
                gaps.append("missing-native-engine-identity")
            facts["CampaignIdentity"].append([cid, receipt["recipe"], engine_id, receipt_sha,
                campaign.get("candidateReceiptSha256", "unbound-candidate"),
                campaign.get("mode", "unrecorded-mode"), campaign.get("regime", "unrecorded-regime")])
            status = inspected["identityStatus"]
            if any(gap.startswith("retry-input-retired:") for gap in gaps):
                status = "STALE"
            facts["CampaignStatus"].append([cid, status])
            outcome = step.get("outcome", "BLOCKED")
            if outcome not in {"PASS", "DENY", "FAIL", "TIMEOUT", "BLOCKED", "STALE"}:
                raise ValueError("recorded native step outcome required")
            facts["NativeStepOutcome"].append([cid, outcome])
            commands = step.get("commands", [])
            if not isinstance(commands, list):
                raise ValueError("recorded native command inventory required")
            if not commands:
                gaps.append("missing-command-observation")
            for command in commands:
                if (type(command.get("exit")) is not int or type(command.get("timeout")) is not bool
                        or not isinstance(command.get("stage"), str)):
                    raise ValueError("typed native command exit and timeout required")
                facts["ObservedCommand"].append([cid, command["stage"], command["exit"], command["timeout"]])
                log = relative(step_dir, command["log"])
                if str(log.relative_to(directory)) not in artifact_refs:
                    raise ValueError("campaign command log lacks an artifact binding")
                if command.get("parentReaped") is not True:
                    gaps.append("parent-reaping-unobserved:" + command["stage"])
                if command.get("processGroupQuiescent") is not True:
                    gaps.append("process-group-quiescence-unobserved:" + command["stage"])
                for stream in ("stdout", "stderr"):
                    if stream + "Path" not in command or stream + "Sha256" not in command:
                        gaps.append("missing-" + stream + "-identity:" + command["stage"])
                    else:
                        bind(relative(step_dir, command[stream + "Path"]), command[stream + "Sha256"])
            facts["CampaignGap"] = [[cid, gap] for gap in sorted(set(gaps))]
            rows, backend = evaluate(engine, facts, catalog, {name: name for name in OUTPUTS})
            packet = {"schema": "native-campaign-observation.v1", "id": cid,
                "receipt": {"path": receipt_name, "sha256": receipt_sha}, "step": step["id"],
                "identityStatus": status, "retry": retry, "nativeOutcome": outcome,
                "commands": commands, "artifacts": artifact_refs, "facts": facts,
                "nativeAnswers": {name: [list(row) for row in values] for name, values in rows.items()},
                "backend": backend, "executionAuthorized": False, "runtimeAdmitted": False}
            packet["packetSha256"] = fingerprint(packet)
            packets.append(packet)
    if any(digest(root / name) != expected for name, expected in inputs.items()):
        raise ValueError("campaign inputs changed during native inference")
    return packets, inputs


def validate(packet):
    if (packet.get("schema") != "native-campaign-observation.v1"
            or packet.get("executionAuthorized") is not False
            or packet.get("runtimeAdmitted") is not False
            or packet.get("packetSha256") != fingerprint({key: value for key, value in packet.items()
                                                          if key != "packetSha256"})):
        raise ValueError("invalid native campaign observation boundary or fingerprint")
    if any(row[0] != packet["id"] for rows in packet["nativeAnswers"].values() for row in rows):
        raise ValueError("mixed native campaign answer scopes")
