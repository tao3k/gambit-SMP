"""Shared Quint/TLC backend; no case names, native admission or CLI."""
import re
import socket
import json

from gambit_smp.framework import execute
from gambit_smp.tlc_values import merge_shapes, shape, value


def interpret_simulation(code, output, timed_out, *, negative):
    """Accept a completed bounded run, not a TLC proof or a native witness.

    Counterexample transport supports scalar Boolean/string record states.
    Unknown Quint value shapes fail closed instead of executing trace text.
    """
    if type(code) is not int or type(timed_out) is not bool or type(negative) is not bool:
        return False, None

    def decode(term):
        kind = term.get('kind')
        if kind in ('bool', 'str'):
            if type(term.get('value')) is not (bool if kind == 'bool' else str):
                raise ValueError('typed simulation scalar required')
            return term['value']
        if kind != 'app' or term.get('opcode') != 'Rec':
            raise ValueError('unsupported simulation value')
        args = term['args']
        if len(args) % 2:
            raise ValueError('record key/value pairs required')
        result = {}
        for key, item in zip(args[::2], args[1::2]):
            if key.get('kind') != 'str' or key.get('value') in result:
                raise ValueError('unique record names required')
            result[key['value']] = decode(item)
        return result

    try:
        data = json.loads(output)
        expected = 'violation' if negative else 'ok'
        if (timed_out or code != (1 if negative else 0) or data.get('stage') != 'running'
                or data.get('status') != expected or data.get('errors') != []
                or not isinstance(data.get('trace'), list) or not data['trace']):
            return False, None
        if not negative:
            return True, None
        states = [decode(term) for term in data['trace']]
        if len(states) < 2:
            return False, None
        return True, {'schema': 'gambit-smp-counterexample.v1', 'states': states}
    except (ValueError, KeyError, TypeError, AttributeError):
        return False, None


def admitted_model(code, output, timed_out, old):
    if timed_out:
        return False
    if old:
        return code != 0 and "Error: Invariant q_inv is violated." in output
    return (code == 0 and "Model checking completed. No error has been found." in output
            and re.search(r"\b0 states left on queue\.", output) is not None)


def counterexample(output):
    """Decode the supported TLC value subset; never evaluate trace text."""
    states = []
    for block in re.findall(r"^State \d+:[^\n]*\n((?:[^\n]+\n)+)", output, re.MULTILINE):
        state = {}
        assignments = list(re.finditer(r"^(?:/\\ )?(\w+) = ", block, re.MULTILINE))
        if not assignments or assignments[0].start() != 0:
            raise ValueError("unsupported TLC state assignment")
        for i, match in enumerate(assignments):
            name = match.group(1)
            if name in state:
                raise ValueError("duplicate TLC state variable")
            end = assignments[i + 1].start() if i + 1 < len(assignments) else len(block)
            state[name] = value(block[match.end():end])
        states.append(state)
    if len(states) < 2:
        raise ValueError("missing or inconsistent TLC states")
    inferred = shape(states[0])
    for state in states[1:]:
        inferred = merge_shapes(inferred, shape(state))
    return {"schema": "gambit-smp-counterexample.v1", "states": states}


def summarize(output):
    matches = list(re.finditer(r"([\d,]+) states generated(?: \([^)]*\))?, "
        r"([\d,]+) distinct states found(?: \([^)]*\))?, ([\d,]+) states left on queue", output))
    return ({key: int(number.replace(",", "")) for key, number in
             zip(("generated", "distinct", "queued"), matches[-1].groups())} if matches else {})


def isolated_endpoint():
    # Competing binds fail closed; this is not a persistent port lease.
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return "127.0.0.1:" + str(listener.getsockname()[1])


def interpret(code, output, timed_out, *, negative, temporal=None):
    accepted = admitted_model(code, output, timed_out, negative)
    trace = None
    if accepted and negative:
        try:
            trace = counterexample(output)
        except ValueError:
            accepted = False
    if temporal:
        accepted = accepted and not(negative) and "Finished checking temporal properties" in output
    return accepted, trace


def check(snapshot, *, initializer, invariant, negative, timeout, cwd,
          temporal=None, step=None, config=None, executable="quint",
          liveness_schedule="default", tlc_jar=None):
    if liveness_schedule not in ("default", "final"):
        raise ValueError("unsupported liveness schedule")
    if liveness_schedule == "final" and tlc_jar is None:
        raise ValueError("explicit TLC jar required for final schedule")
    if liveness_schedule != "final" and tlc_jar is not None:
        raise ValueError("explicit jar requires final liveness schedule")
    endpoint = isolated_endpoint()
    if liveness_schedule == "final":
        from gambit_smp.tlc_execution import compiled_check
        code, output, timed_out, seconds, identity = compiled_check(snapshot,
            initializer=initializer, invariant=invariant, timeout=timeout, cwd=cwd,
            endpoint=endpoint, jar=tlc_jar, temporal=temporal, step=step,
            config=config, executable=executable)
        accepted, trace = interpret(code, output, timed_out, negative=negative, temporal=temporal)
        accepted = accepted and identity["inputsStable"] and identity["phase"] == "tlc"
        row = dict(accepted=accepted, exit=code, timeout=timed_out,
                   seconds=round(seconds, 3), temporal=temporal, serverEndpoint=endpoint,
                   states=summarize(output), checker=identity)
        return row, output, trace
    command = [executable, "verify", str(snapshot), "--init", initializer,
               "--invariant", invariant, "--backend", "tlc", "--server-endpoint", endpoint]
    for option, setting in (("--step", step), ("--tlc-config", config), ("--temporal", temporal)):
        if setting is not None:
            command.extend([option, str(setting)])
    code, output, timed_out, seconds = execute(command, cwd, timeout)
    accepted, trace = interpret(code, output, timed_out, negative=negative, temporal=temporal)
    row = dict(accepted=accepted, exit=code, timeout=timed_out,
               seconds=round(seconds, 3), temporal=temporal, serverEndpoint=endpoint,
               states=summarize(output))
    return row, output, trace
