"""Owner-bound delivery of instructions to one supervised ACP session."""
from contextlib import contextmanager
from hashlib import sha256
import hmac
import json
import os
from pathlib import Path
import secrets
import socket
import tempfile
import threading
import uuid

from gambit_smp.grok_acp import AcpError, AcpOutcomeUnknown


def _line(stream, limit=131072):
    data = stream.readline(limit + 1)
    if not data.endswith(b"\n") or len(data) > limit:
        raise ValueError("bounded JSON request required")
    return json.loads(data)


def _write_record(path, value):
    temporary = path.with_name(path.name + ".tmp")
    with temporary.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, indent=2)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)
    _sync_directory(path.parent)


def _sync_directory(path):
    fd = os.open(path, os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


@contextmanager
def serve(connection, *, task, owner, run, session, authorization, descriptor, attempt):
    """Publish one private endpoint while the owning session remains active."""
    descriptor = Path(descriptor)
    attempt = Path(attempt)
    directory = Path(tempfile.mkdtemp(prefix="smp-acp-"))
    endpoint = directory / "control.sock"
    listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    token = secrets.token_hex(32)
    binding = {"task": task, "owner": owner, "run": run, "sessionId": session}
    stopped = threading.Event()
    journal = attempt / "interjections"
    try:
        journal.mkdir(mode=0o700, exist_ok=True)
        descriptor.parent.mkdir(parents=True, exist_ok=True)
        listener.bind(str(endpoint))
        os.chmod(endpoint, 0o600)
        listener.listen()
        listener.settimeout(.2)
        metadata = {**binding, "endpoint": str(endpoint), "secret": token,
                    "authorizationSha256": sha256(authorization.encode()).hexdigest()}
        fd = os.open(descriptor, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(metadata, stream)
            stream.flush()
            os.fsync(stream.fileno())
        _sync_directory(descriptor.parent)

        def handle():
            while not stopped.is_set():
                try:
                    peer, _ = listener.accept()
                except socket.timeout:
                    continue
                except OSError:
                    break
                with peer:
                    peer.settimeout(25)
                    try:
                        with peer.makefile("rwb") as stream:
                            request = _line(stream)
                            if not isinstance(request, dict) or any(request.get(k) != v for k, v in binding.items()):
                                raise ValueError("active session binding mismatch")
                            if not hmac.compare_digest(str(request.get("secret", "")), token):
                                raise ValueError("invalid control capability")
                            message_id = str(uuid.UUID(request["id"]))
                            text = request["text"]
                            if not isinstance(text, str) or not text.strip():
                                raise ValueError("nonempty instruction required")
                            record = journal / (message_id + ".json")
                            initial = {**binding, "id": message_id, "textSha256": sha256(text.encode()).hexdigest(),
                                       "status": "dispatching", "nativeAdmitted": False}
                            try:
                                fd = os.open(record, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
                            except FileExistsError:
                                previous = json.loads(record.read_text())
                                if previous.get("textSha256") != initial["textSha256"]:
                                    raise ValueError("instruction identity already has different text")
                                response = ({**previous, "status": "unknown"}
                                            if previous.get("status") == "dispatching" else previous)
                            else:
                                with os.fdopen(fd, "w", encoding="utf-8") as saved:
                                    json.dump(initial, saved)
                                    saved.flush()
                                    os.fsync(saved.fileno())
                                _sync_directory(journal)
                                try:
                                    connection.interject(session, text, interjection_id=message_id, timeout=20)
                                    status = "queued"
                                except AcpOutcomeUnknown:
                                    status = "unknown"
                                except AcpError:
                                    status = "rejected"
                                response = {**initial, "status": status}
                                _write_record(record, response)
                            stream.write((json.dumps(response) + "\n").encode())
                            stream.flush()
                    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError):
                        continue

        thread = threading.Thread(target=handle, daemon=True)
        thread.start()
        yield metadata
    finally:
        stopped.set()
        listener.close()
        if "thread" in locals():
            thread.join(timeout=25)
            if thread.is_alive():
                raise RuntimeError("ACP control request remains unresolved; custody retained")
        if descriptor.exists():
            current = json.loads(descriptor.read_text())
            if current.get("secret") == token:
                descriptor.unlink()
        endpoint.unlink(missing_ok=True)
        directory.rmdir()


def send(descriptor, *, task, owner, run, session, authorization, message_id, text, timeout=25):
    """Use the published capability without acquiring or replacing its lease."""
    descriptor = Path(descriptor)
    if descriptor.is_symlink() or (descriptor.stat().st_mode & 0o077):
        raise ValueError("private control descriptor required")
    metadata = json.loads(descriptor.read_text())
    binding = {"task": task, "owner": owner, "run": run, "sessionId": session}
    if any(metadata.get(key) != value for key, value in binding.items()):
        raise ValueError("active session binding mismatch")
    expected = sha256(authorization.encode()).hexdigest()
    if not hmac.compare_digest(metadata.get("authorizationSha256", ""), expected):
        raise ValueError("authorization binding mismatch")
    request = {**binding, "secret": metadata["secret"], "id": str(uuid.UUID(message_id)), "text": text}
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as peer:
            peer.settimeout(timeout)
            peer.connect(metadata["endpoint"])
            with peer.makefile("rwb") as stream:
                stream.write((json.dumps(request) + "\n").encode())
                stream.flush()
                return _line(stream)
    except (OSError, ValueError) as error:
        raise AcpOutcomeUnknown("control delivery has no authoritative response",
                                interjection_id=request["id"]) from error
