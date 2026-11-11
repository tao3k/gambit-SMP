"""Wait for a Grok supervision event without polling its terminal UI."""

import argparse
import json
import os
import select
import sys
import time
import uuid
from contextlib import contextmanager
from pathlib import Path
from urllib.parse import quote


def event_path(session: str, workspace: Path, grok_home: Path) -> Path:
    session = str(uuid.UUID(session))
    return grok_home / "sessions" / quote(str(workspace.resolve()), safe="") / session / "events.jsonl"


def classify(events: list[dict], pending: list[dict]) -> dict | None:
    notable = None
    for event in events:
        kind = event.get("type")
        if kind == "permission_requested":
            pending.append(event)
        elif kind == "permission_resolved":
            for index in range(len(pending) - 1, -1, -1):
                if pending[index].get("tool_name") == event.get("tool_name"):
                    del pending[index]
                    break
        elif kind == "tool_completed" and (
            event.get("outcome") != "success"
            or event.get("tool_name") == "run_terminal_command"
        ):
            notable = event
        elif kind in {"turn_ended", "tool_failed"}:
            notable = event
    return pending[-1] if pending else notable


@contextmanager
def _file_notifications(path, fd):
    if sys.platform.startswith("linux"):
        import ctypes
        libc = ctypes.CDLL(None, use_errno=True)
        libc.inotify_init1.argtypes = [ctypes.c_int]
        libc.inotify_init1.restype = ctypes.c_int
        libc.inotify_add_watch.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_uint32]
        libc.inotify_add_watch.restype = ctypes.c_int
        notify = libc.inotify_init1(os.O_NONBLOCK | os.O_CLOEXEC)
        if notify < 0:
            raise OSError(ctypes.get_errno(), "inotify_init1")
        try:
            # Linux UAPI: MODIFY, CLOSE_WRITE, DELETE_SELF, MOVE_SELF.
            mask = 0x00000002 | 0x00000008 | 0x00000400 | 0x00000800
            if libc.inotify_add_watch(notify, os.fsencode(path), mask) < 0:
                raise OSError(ctypes.get_errno(), "inotify_add_watch", str(path))

            def wait(timeout):
                if not select.select([notify], [], [], timeout)[0]:
                    return False
                os.read(notify, 65536)
                return True

            yield wait
        finally:
            os.close(notify)
    elif hasattr(select, "kqueue"):
        watcher = select.kqueue()
        try:
            watcher.control([select.kevent(
                fd, filter=select.KQ_FILTER_VNODE,
                flags=select.KQ_EV_ADD | select.KQ_EV_CLEAR,
                fflags=select.KQ_NOTE_WRITE | select.KQ_NOTE_EXTEND,
            )], 0, 0)
            yield lambda timeout: bool(watcher.control(None, 1, timeout))
        finally:
            watcher.close()
    else:
        raise RuntimeError("grok-wait requires kernel file notifications")


def wait_for_event(path: Path, quiet_seconds: float) -> dict:
    fd = os.open(path, os.O_RDONLY)
    pending: list[dict] = []
    remainder = b""

    def drain() -> list[dict]:
        nonlocal remainder
        chunks = []
        while chunk := os.read(fd, 65536):
            chunks.append(chunk)
        if not chunks:
            return []
        lines = (remainder + b"".join(chunks)).split(b"\n")
        remainder = lines.pop()
        return [json.loads(line) for line in lines if line]

    def unresolved_permission() -> dict | None:
        if not pending:
            return None
        # Grok also emits requested/resolved for immediately allowed reads.
        time.sleep(0.05)
        classify(drain(), pending)
        return pending[-1] if pending else None

    try:
        with _file_notifications(path, fd) as wait:
            classify(drain(), pending)
            if event := unresolved_permission():
                return event
            deadline = time.monotonic() + quiet_seconds if quiet_seconds > 0 else None
            while True:
                timeout = max(0, deadline - time.monotonic()) if deadline else None
                if not wait(timeout):
                    return {"type": "supervision_quiet", "quiet_seconds": quiet_seconds}
                event = classify(drain(), pending)
                if pending:
                    event = unresolved_permission()
                if event is not None:
                    return event
    finally:
        os.close(fd)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("session", help="Exact Grok session UUID")
    parser.add_argument("--quiet-seconds", type=float, default=90)
    parser.add_argument("--workspace", type=Path, default=Path.cwd())
    parser.add_argument("--grok-home", type=Path, default=Path.home() / ".grok")
    args = parser.parse_args()
    if args.quiet_seconds < 0:
        parser.error("--quiet-seconds must be nonnegative")
    try:
        path = event_path(args.session, args.workspace, args.grok_home)
        event = wait_for_event(path, args.quiet_seconds)
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"grok event wait: {exc}", file=sys.stderr)
        return 1
    result = {key: event[key] for key in (
        "ts", "type", "tool_name", "duration_ms", "outcome", "quiet_seconds"
    ) if key in event}
    result["may_prompt"] = event.get("type") == "turn_ended"
    print(json.dumps(result, separators=(",", ":")))
    return 0


from gambit_smp.task_entry import managed_tool as _managed_tool
main = _managed_tool('grok-event-wait')(main)

if __name__ == '__main__':
    from gambit_smp.task_entry import tool_main
    raise SystemExit(tool_main('grok-event-wait',main))
