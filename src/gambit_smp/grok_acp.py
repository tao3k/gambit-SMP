"""Concurrent ACP requests for a supervised Grok connection.

The caller owns process creation, task custody and provider permissions. An
accepted interjection is only queued by the provider, not proof of model use.
"""
import json
import threading
import uuid
from concurrent.futures import Future, TimeoutError as FutureTimeout


class AcpError(RuntimeError):
    """The provider rejected a request or its transport failed."""


class AcpOutcomeUnknown(AcpError):
    """A sent request did not receive a response; do not resend blindly."""

    def __init__(self, message, *, request_id=None, interjection_id=None):
        super().__init__(message)
        self.request_id = request_id
        self.interjection_id = interjection_id


class AcpConnection:
    """Multiplex ACP responses while a prompt request is still outstanding."""

    def __init__(self, reader, writer, *, on_notification=None, on_permission=None):
        self.reader = reader
        self.writer = writer
        self.on_notification = on_notification
        self.on_permission = on_permission
        self._lock = threading.Lock()
        self._write_lock = threading.Lock()
        self._pending = {}
        self._next_id = 0
        self._closed = None
        self._thread = threading.Thread(target=self._read, daemon=True)
        self._thread.start()

    def _send(self, message):
        raw = json.dumps(message, ensure_ascii=False, separators=(",", ":")) + "\n"
        with self._write_lock:
            self.writer.write(raw)
            self.writer.flush()

    def request(self, method, params, *, timeout):
        if not isinstance(method, str) or not method or not isinstance(params, dict):
            raise ValueError("ACP method and object parameters required")
        if timeout <= 0:
            raise ValueError("positive response timeout required")
        future = Future()
        with self._lock:
            if self._closed:
                raise AcpError("ACP connection is closed") from self._closed
            self._next_id += 1
            request_id = self._next_id
            self._pending[request_id] = future
        try:
            self._send({"jsonrpc": "2.0", "id": request_id, "method": method, "params": params})
        except (OSError, ValueError) as error:
            with self._lock:
                self._pending.pop(request_id, None)
            raise AcpOutcomeUnknown("ACP request write failed", request_id=request_id) from error
        try:
            return future.result(timeout=timeout)
        except FutureTimeout as error:
            with self._lock:
                self._pending.pop(request_id, None)
            raise AcpOutcomeUnknown("ACP response deadline elapsed", request_id=request_id) from error

    def interject(self, session_id, text, *, interjection_id=None, timeout=10):
        if not isinstance(session_id, str) or not session_id:
            raise ValueError("active provider session required")
        if not isinstance(text, str) or not text.strip():
            raise ValueError("nonempty instruction required")
        identifier = interjection_id or str(uuid.uuid4())
        if not isinstance(identifier, str) or not identifier:
            raise ValueError("interjection identity required")
        try:
            result = self.request("_x.ai/interject", {
                "sessionId": session_id, "text": text, "interjectionId": identifier,
            }, timeout=timeout)
        except AcpOutcomeUnknown as error:
            error.interjection_id = identifier
            raise
        if isinstance(result, dict) and isinstance(result.get("result"), dict):
            result = result["result"]
        if not isinstance(result, dict) or result.get("status") != "queued":
            raise AcpOutcomeUnknown("provider returned an unrecognized interjection result",
                                    interjection_id=identifier)
        return {"sessionId": session_id, "interjectionId": identifier, "status": "queued"}

    def _read(self):
        error = None
        try:
            for line in self.reader:
                message = json.loads(line)
                if not isinstance(message, dict) or message.get("jsonrpc") != "2.0":
                    raise AcpError("invalid ACP message")
                method = message.get("method")
                if method is not None:
                    if "id" in message:
                        if method == "session/request_permission":
                            response = {"outcome": {"outcome": "cancelled"}}
                            if self.on_permission:
                                option = self.on_permission(message.get("params", {}))
                                if option is not None:
                                    response = {"outcome": {"outcome": "selected", "optionId": option}}
                            self._send({"jsonrpc": "2.0", "id": message["id"], "result": response})
                        else:
                            self._send({"jsonrpc": "2.0", "id": message["id"],
                                        "error": {"code": -32601, "message": "Method not supported"}})
                    elif self.on_notification:
                        self.on_notification(message)
                    continue
                with self._lock:
                    future = self._pending.pop(message.get("id"), None)
                if future is None:
                    continue
                if "error" in message:
                    future.set_exception(AcpError(str(message["error"])))
                elif "result" in message:
                    future.set_result(message["result"])
                else:
                    future.set_exception(AcpError("ACP response has no result"))
        except (OSError, ValueError, TypeError) as exc:
            error = exc
        finally:
            error = error or AcpError("ACP connection reached EOF")
            with self._lock:
                self._closed = error
                pending, self._pending = self._pending, {}
            for request_id, future in pending.items():
                # An outstanding request may already have taken effect.
                future.set_exception(AcpOutcomeUnknown(
                    "ACP connection ended before response", request_id=request_id))
