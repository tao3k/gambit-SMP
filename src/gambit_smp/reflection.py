"""Unclosed requirements and contextual references, never proof admission."""
from pathlib import Path

from gambit_smp.framework import digest


def validate(root, reflection):
    if reflection.get("schema") != "gambit-evidence-reflection.v1":
        raise ValueError("unknown reflection schema")
    references = reflection.get("references", [])
    requirements = reflection.get("requirements", [])
    if not references or not requirements:
        raise ValueError("reflection needs references and requirements")
    ids, inputs = set(), {}
    def bind(name, expected=None):
        path = Path(name)
        if path.is_absolute() or ".." in path.parts or ".data" in path.parts:
            raise ValueError("durable repository-relative reflection path required")
        resolved = (root / path).resolve()
        local = resolved.relative_to(root.resolve())
        if any(part.casefold() in {".data", ".cache", ".git", ".venv", "__pycache__"}
               for part in (*path.parts, *local.parts)) or not resolved.is_file():
            raise ValueError("durable repository file required, not a cache alias")
        actual = digest(resolved)
        if expected is not None and actual != expected:
            raise ValueError("stale reflection artifact: " + name)
        inputs[name] = actual
    for reference in references:
        name = reference["id"]
        if not isinstance(name, str) or not name or name in ids:
            raise ValueError("duplicate or invalid reflection reference")
        ids.add(name)
        if reference["kind"] not in {"paper", "source-lock", "model", "observation", "report", "limitation"}:
            raise ValueError("unknown reflection reference kind")
        if not reference.get("scope", "").strip() or not reference.get("locator", "").strip():
            raise ValueError("reflection reference needs locator and scope")
        bind(reference["path"])
        for artifact in reference.get("artifacts", []):
            if not isinstance(artifact, dict) or not isinstance(artifact.get("sha256"), str):
                raise ValueError("reflection artifact needs an expected digest")
            bind(artifact["path"], artifact["sha256"])
        if "history" in reference:
            from gambit_smp.registry_history import validate as validate_history
            history = reference["history"]
            if (not isinstance(history, dict) or history.get("path") != reference["path"]
                    or not isinstance(history.get("sha256"), str)):
                raise ValueError("reflection history must bind its declared reference")
            bind(history["path"], history["sha256"])
            inputs.update(validate_history(root, history["path"]))
    seen = set()
    for requirement in requirements:
        name = requirement["id"]
        if not isinstance(name, str) or not name or name in seen:
            raise ValueError("duplicate or invalid reflection requirement")
        seen.add(name)
        if requirement["status"] not in {"open", "partial"}:
            raise ValueError("reflection cannot admit a closed requirement")
        if not requirement.get("gap", "").strip() or not requirement.get("conditions"):
            raise ValueError("requirement needs a gap and acceptance conditions")
        for condition in requirement["conditions"]:
            if not isinstance(condition, str) or not condition.strip():
                raise ValueError("empty acceptance condition")
        refs = requirement.get("references", [])
        if not refs or len(set(refs)) != len(refs) or not set(refs).issubset(ids):
            raise ValueError("unknown or duplicate requirement reference")
    return inputs
