"""Fail-closed ACP permissions from the registered Grok task profile."""
import re
import shlex
from pathlib import Path

from gambit_smp.workspace import bounded


def _contained(root, raw):
    if not isinstance(raw, str) or not raw or "\x00" in raw:
        raise ValueError("path required")
    path = Path(raw)
    if not path.is_absolute():
        path = root / path
    relative = path.relative_to(root)
    return bounded(root, relative)


def _matches(path, patterns):
    # Support the profile's exact paths and recursive directory grants only.
    # fnmatch treats '*' as matching '/', which can silently widen a grant.
    value = str(path)
    for pattern in patterns:
        base = pattern[:-3] if pattern.endswith('/**') else pattern
        if any(char in base for char in '*?['):
            continue
        if value == base or (pattern.endswith('/**') and value.startswith(base + '/')):
            return True
    return False


def permission_decision(params, *, root, session, profile, evidence_read, script_grants):
    """Return an ACP option ID; unknown and ambiguous operations are refused."""
    root = Path(root).resolve(strict=True)
    if not isinstance(params, dict) or params.get("sessionId") != session:
        return None
    options = params.get("options")
    if not isinstance(options, list):
        return None
    def option(kind):
        matches = [entry.get("optionId") for entry in options
                   if isinstance(entry, dict) and entry.get("kind") == kind
                   and isinstance(entry.get("optionId"), str)]
        return matches[0] if len(matches) == 1 else None

    reject = option("reject_once")
    call = params.get("toolCall")
    if not isinstance(call, dict):
        return reject
    meta = call.get("_meta")
    if not isinstance(meta, dict):
        return reject
    tool = meta.get("x.ai/tool")
    if not isinstance(tool, dict) or meta.get("x.ai/requestingSessionId") != session:
        return reject
    name = tool.get("name")
    raw = call.get("rawInput") or {}
    if not isinstance(raw, dict):
        return reject
    approved = False
    try:
        if name in {"write", "search_replace", "read_file", "list_dir", "grep", "grep_search"}:
            is_edit = name in {"write", "search_replace"}
            file_path = (raw.get("file_path") or raw.get("target_file") or raw.get("path") or
                         raw.get("directory_path") or raw.get("target_directory") or raw.get("search_path"))
            declared = (tool.get("input") or {}).get("path")
            if declared is not None and declared != file_path:
                return reject
            path = _contained(root, file_path)
            relative = path.relative_to(root)
            forbidden = {".git", ".grok", ".codex", ".claude", ".cursor", ".ssh", ".aws", ".state"}
            if any(part in forbidden for part in relative.parts) or "grok-runs" in relative.parts:
                return reject
            if is_edit and relative.parts[:1] == ("evidence",):
                from gambit_smp.storage_policy import EVIDENCE_CACHE_SUFFIXES
                if any(path.name.endswith(suffix) for suffix in EVIDENCE_CACHE_SUFFIXES):
                    return reject
            approved = _matches(path, profile["edit" if is_edit else "read"])
        elif name in {"run_terminal_cmd", "run_terminal_command"}:
            command = raw.get("command")
            if not isinstance(command, str) or not command.strip() or re.search(r"[\n\r`$]", command):
                return reject
            declared_command = (tool.get("input") or {}).get("command")
            if declared_command is not None and declared_command != command:
                return reject
            # The one documented Evidence read uses its fixed input redirect.
            if evidence_read and command == evidence_read["command"]:
                approved = True
            else:
                lexer = shlex.shlex(command, posix=True, punctuation_chars="|&;<>")
                lexer.whitespace_split = True
                tokens = list(lexer)
                if not tokens or any(re.fullmatch(r"[|&;<>]+", token) for token in tokens):
                    return reject
                dispatcher = {str(root / ".venv/bin/gambit-smp"), ".venv/bin/gambit-smp"}
                if (len(tokens) >= 4 and tokens[0] in dispatcher and tokens[1:3] == ["--task", profile["task"]]
                        and tokens[3] in profile["commands"]):
                    approved = True
                elif shlex.join(tokens) in script_grants:
                    approved = True
    except (OSError, ValueError, TypeError, AttributeError):
        return reject
    desired = "allow_once" if approved else "reject_once"
    return option(desired)
