"""Bound continuation accounting; no execution, producer export or admission."""
import hashlib
from contextlib import contextmanager
from decimal import Decimal
import fcntl
import json
import math
import os
from pathlib import Path
import re
import uuid


def remaining_budget(limit, receipts):
    """Retain every immutable attempt, including failures and outer teardown."""
    if type(limit) not in (int, float) or not math.isfinite(limit) or limit <= 0:
        raise ValueError("finite positive original budget required")
    seen, observations, expenditure = set(), [], 0.0
    for path, expected_sha in receipts:
        raw = path.read_bytes()
        actual = hashlib.sha256(raw).hexdigest()
        if actual != expected_sha:
            raise ValueError("continuation receipt identity changed")
        identity = str(path.resolve(strict=True))
        if identity in seen or actual in seen:
            raise ValueError("duplicate continuation expenditure")
        seen.update((identity, actual))
        receipt = json.loads(raw)
        if (receipt.get("schema") != "sealed-research-run.v1"
                or receipt.get("parentReaped") is not True
                or receipt.get("processGroupQuiescent") is not True
                or receipt.get("outcome") not in {"PASS", "DENY"}):
            raise ValueError("terminal quiescent sealed observation required")
        spent = receipt.get("wholeSeconds")
        cap = receipt.get("budgetSeconds")
        if (type(spent) not in (int, float) or not math.isfinite(spent) or spent <= 0
                or type(cap) not in (int, float) or not math.isfinite(cap)
                or not 0 < cap <= limit):
            raise ValueError("valid original expenditure and non-expanded cap required")
        if cap > limit - expenditure:
            raise ValueError("attempt cap exceeds remaining original budget")
        expenditure += spent
        observations.append({"sha256": actual, "outcome": receipt["outcome"],
                             "budgetSeconds": cap, "wholeSeconds": spent})
        if path.read_bytes() != raw:
            raise ValueError("continuation receipt changed during observation")
    remaining = limit - expenditure
    if remaining <= 0:
        raise TimeoutError("original cumulative budget exhausted")
    return {"originalBudgetSeconds": limit, "spentSeconds": expenditure,
            "remainingSeconds": remaining, "observations": observations,
            "prefixReusable": False, "producerAdmitted": False}


def continuation_request(root, limit, receipts, source_lock, recipe):
    """Project bound accounting into a request; Scheme DSL owns eligibility."""
    from gambit_smp.framework import digest
    from gambit_smp.recipes import read_json, source_path
    root = root.resolve(strict=True)
    receipts = tuple(receipts)
    if not receipts:
        raise ValueError("continuation requires original expenditure receipts")
    source = source_path(root, source_lock)
    plan = source_path(root, recipe)
    declared = read_json(plan).get("budgetSeconds")
    observed = remaining_budget(limit, receipts)
    if (type(declared) not in (int, float) or not math.isfinite(declared)
            or not 0 < declared <= observed["remainingSeconds"]):
        raise ValueError("recipe cap exceeds remaining original budget")
    return {"schema": "budget-bound-continuation-request.v1",
            **observed, "sourceLock": source_lock, "sourceLockSha256": digest(source),
            "recipe": recipe, "recipeSha256": digest(plan), "requestedSeconds": declared,
            "receiptBindings": [{"path": path.resolve().relative_to(root).as_posix(),
                                 "sha256": sha} for path, sha in receipts],
            "executionAuthorized": False,
            "claim": "accounting-transport-pending-native-ascent-review"}


def revalidate_continuation_request(root, request):
    from gambit_smp.framework import relative
    if request.get("schema") != "budget-bound-continuation-request.v1":
        raise ValueError("typed continuation request required")
    actual = continuation_request(root, request["originalBudgetSeconds"],
        [(relative(root, row["path"]), row["sha256"]) for row in request["receiptBindings"]],
        request["sourceLock"], request["recipe"])
    if actual != request:
        raise ValueError("continuation request changed after review")
    return actual


def _bytes(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False).encode()


def _identifier(value):
    return hashlib.sha256(_bytes(value)).hexdigest()


def _write_once(path, value):
    data = _bytes(value)
    with path.open("xb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())


def initialize_budget_ledger(root, limit, receipts):
    """Create one canonical ledger for the original expenditure root."""
    from gambit_smp.framework import digest
    observations = remaining_budget(limit, tuple(receipts))
    if not observations["observations"] or observations["observations"][0]["budgetSeconds"] != limit:
        raise ValueError("ledger must start with the original full-budget observation")
    record = {"schema": "continuation-budget-genesis.v1", **observations}
    from gambit_smp.artifact_storage import cache_path
    first = observations["observations"][0]["sha256"]
    if (root.resolve() / "evidence/research/budget-ledgers" / first).exists():
        raise ValueError("existing historical ledger cannot be reset in a new cache directory")
    directory = cache_path(root, "research/budget-ledgers/" + first)
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / "genesis.json"
    _write_once(target, record)
    _write_once(directory / "head.json", {"event": None})
    fd = os.open(directory, os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)
    return {"path": target.relative_to(root.resolve()).as_posix(), "sha256": digest(target)}


@contextmanager
def _ledger_lock(root, reference):
    from gambit_smp.framework import digest, relative
    from gambit_smp.recipes import read_json
    root = root.resolve(strict=True)
    path = relative(root, reference["path"])
    if digest(path) != reference["sha256"]:
        raise ValueError("budget ledger genesis changed")
    genesis = read_json(path)
    first = genesis["observations"][0]["sha256"]
    from gambit_smp.artifact_storage import cache_path
    expected = (cache_path(root, "research/budget-ledgers/" + first) / "genesis.json",
                root / "evidence/research/budget-ledgers" / first / "genesis.json")
    if path not in expected or genesis.get("schema") != "continuation-budget-genesis.v1":
        raise ValueError("canonical original-budget ledger required")
    fd = os.open(path.parent / ".ledger.lock", os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o600)
    try:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise ValueError("budget ledger already locked") from error
        yield path.parent, genesis
    finally:
        os.close(fd)


def _state(directory, genesis):
    from gambit_smp.recipes import read_json
    head = read_json(directory / "head.json")["event"]
    events, seen, current = [], set(), head
    while current is not None:
        if not isinstance(current, str) or not re.fullmatch(r"[0-9a-f]{64}", current) or current in seen:
            raise ValueError("invalid budget event chain")
        seen.add(current)
        event = read_json(directory / (current + ".json"))
        if _identifier(event) != current:
            raise ValueError("budget event bytes changed")
        events.append((current, event))
        current = event["parent"]
    spent = sum((Decimal(str(row["wholeSeconds"])) for row in genesis["observations"]), Decimal(0))
    pending, settled, settlements, attempts, breached = {}, {}, {}, set(), False
    for identity, event in reversed(events):
        if event["kind"] == "reserve":
            if event["attempt"] in attempts:
                raise ValueError("duplicate budget attempt")
            attempts.add(event["attempt"])
            cap = Decimal(str(event["cap"]))
            held = sum((Decimal(str(row["cap"])) for row in pending.values()), Decimal(0))
            if not cap.is_finite() or cap <= 0 or spent + held + cap > Decimal(str(genesis["originalBudgetSeconds"])):
                raise ValueError("invalid historical budget reservation")
            pending[identity] = event
        elif event["kind"] == "settle":
            token = event["reservation"]
            if token not in pending or token in settled:
                raise ValueError("duplicate or unbound budget settlement")
            cost = Decimal(str(event["wholeSeconds"]))
            if not cost.is_finite() or cost <= 0 or event["outcome"] not in {"PASS", "DENY", "STALE", "TIMEOUT"}:
                raise ValueError("invalid budget settlement cost")
            breached = breached or cost > Decimal(str(pending[token]["cap"]))
            spent += cost
            settled[token] = pending.pop(token)
            settlements[token] = event
        else:
            raise ValueError("unknown budget event")
    held = sum((Decimal(str(row["cap"])) for row in pending.values()), Decimal(0))
    breached = breached or spent + held > Decimal(str(genesis["originalBudgetSeconds"]))
    return {"head": head, "spent": spent, "held": held, "pending": pending, "breached": breached,
            "settled": settled, "settlements": settlements, "attempts": attempts,
            "available": Decimal(str(genesis["originalBudgetSeconds"])) - spent - held}


def _append(directory, event):
    identity = _identifier(event)
    _write_once(directory / (identity + ".json"), event)
    temporary = directory / ("head-" + uuid.uuid4().hex + ".pending")
    _write_once(temporary, {"event": identity})
    temporary.replace(directory / "head.json")
    fd = os.open(directory, os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)
    return identity


def reserve_budget(root, ledger, request, attempt):
    revalidate_continuation_request(root, request)
    if not isinstance(attempt, str) or not re.fullmatch(r"[a-z][a-z0-9-]{0,95}", attempt):
        raise ValueError("typed budget attempt identity required")
    with _ledger_lock(root, ledger) as (directory, genesis):
        if request["observations"] != genesis["observations"] or request["originalBudgetSeconds"] != genesis["originalBudgetSeconds"]:
            raise ValueError("continuation omits or changes original expenditures")
        state = _state(directory, genesis)
        cap = Decimal(str(request["requestedSeconds"]))
        if state["breached"]:
            raise ValueError("observed budget overrun requires review; no further reservation")
        if attempt in state["attempts"] or cap > state["available"]:
            raise ValueError("attempt already reserved or remaining shared budget insufficient")
        event = {"kind": "reserve", "parent": state["head"], "attempt": attempt,
                 "cap": request["requestedSeconds"], "requestSha256": _identifier(request)}
        token = _append(directory, event)
    return {"ledger": ledger, "token": token, "attempt": attempt}


def check_reservation(root, reservation, request):
    revalidate_continuation_request(root, request)
    with _ledger_lock(root, reservation["ledger"]) as (directory, genesis):
        state = _state(directory, genesis)
        if state["breached"]:
            raise ValueError("budget overrun denies continuation execution")
        row = state["pending"].get(reservation["token"])
        if row is None or row["attempt"] != reservation["attempt"] or row["requestSha256"] != _identifier(request):
            raise ValueError("continuation reservation missing, settled or changed")
    return row


def checkpoint_allowance(root, ledger, producer_reservation, producer_sha, consumer_reservation, request):
    """Consume a charged producer only within this already reserved allowance."""
    if (producer_reservation.get("ledger") != ledger or consumer_reservation.get("ledger") != ledger):
        raise ValueError("checkpoint and consumer must share the original budget ledger")
    check_reservation(root, consumer_reservation, request)
    with _ledger_lock(root, ledger) as (directory, genesis):
        state = _state(directory, genesis)
        producer = state["settled"].get(producer_reservation["token"])
        settled = state["settlements"].get(producer_reservation["token"])
        consumer = state["pending"].get(consumer_reservation["token"])
        if (state["breached"] or producer is None or settled is None or consumer is None
                or producer["attempt"] != producer_reservation["attempt"]
                or settled["receiptSha256"] != producer_sha
                or consumer["attempt"] != consumer_reservation["attempt"]
                or consumer["requestSha256"] != _identifier(request)):
            raise ValueError("checkpoint expenditure or live consumer reservation is unbound")
        return {"originalBudgetSeconds": genesis["originalBudgetSeconds"],
                "remainingSeconds": consumer["cap"], "producerChargedSeconds": settled["wholeSeconds"],
                "ledger": ledger, "reservation": consumer_reservation["token"],
                "scope": "existing-consumer-reservation-not-new-budget",
                "prefixReusable": False, "producerAdmitted": False}


def settle_budget(root, reservation, receipt_path, receipt_sha):
    """Charge a terminal outer observation atomically before releasing its hold."""
    raw = receipt_path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != receipt_sha:
        raise ValueError("settlement receipt changed")
    receipt = json.loads(raw)
    if (receipt.get("schema") != "sealed-research-run.v1" or receipt.get("parentReaped") is not True
            or receipt.get("processGroupQuiescent") is not True or receipt.get("outcome") not in {"PASS", "DENY", "STALE", "TIMEOUT"}
            or receipt.get("budgetReservation") != reservation):
        raise ValueError("exact quiescent reservation-bound outer receipt required")
    cost = receipt.get("wholeSeconds")
    if type(cost) not in (int, float) or not math.isfinite(cost) or cost <= 0:
        raise ValueError("finite settlement expenditure required")
    with _ledger_lock(root, reservation["ledger"]) as (directory, genesis):
        state = _state(directory, genesis)
        row = state["pending"].get(reservation["token"])
        if row is None or row["attempt"] != reservation["attempt"] or receipt.get("budgetSeconds") != row["cap"]:
            raise ValueError("settlement reservation missing or cap changed")
        if receipt_path.read_bytes() != raw:
            raise ValueError("settlement receipt changed during observation")
        return _append(directory, {"kind": "settle", "parent": state["head"],
            "reservation": reservation["token"], "receiptSha256": receipt_sha,
            "wholeSeconds": cost, "outcome": receipt["outcome"]})


def inspect_budget_ledger(root, ledger):
    with _ledger_lock(root, ledger) as (directory, genesis):
        state = _state(directory, genesis)
        return {"originalBudgetSeconds": genesis["originalBudgetSeconds"],
                "spentSeconds": float(state["spent"]), "heldSeconds": float(state["held"]),
                "remainingSeconds": float(state["available"]), "pending": len(state["pending"]),
                "settled": len(state["settled"]), "budgetBreached": state["breached"], "runtimeAdmitted": False}
