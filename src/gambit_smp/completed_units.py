"""Strict ordered, result-bearing completion records for native workloads."""
import re

from gambit_smp.recipes import fields


def validate(contract):
    fields(contract, ("marker", "count", "result"))
    if (not isinstance(contract["marker"], str)
            or not re.fullmatch(r"[A-Z][A-Z0-9-]{0,63}", contract["marker"])
            or type(contract["count"]) is not int or not 0 < contract["count"] <= 1000000
            or not isinstance(contract["result"], str)
            or not re.fullmatch(r"[A-Za-z0-9_.+-]{1,64}", contract["result"])):
        raise ValueError("bounded result-bearing completed-unit contract required")


class CompletedUnits:
    def __init__(self, contract):
        validate(contract)
        self.contract = contract

    def project(self, output, *, final=False):
        completed, remainder = 0, []
        for line in output.splitlines(keepends=True):
            if not line.endswith("\n") and not final:
                continue
            if line.startswith(self.contract["marker"]):
                expected = (f"{self.contract['marker']} {completed + 1}/"
                            f"{self.contract['count']} {self.contract['result']}\n")
                if completed >= self.contract["count"] or line != expected:
                    raise ValueError("native completion record is duplicated, unordered or incorrect")
                completed += 1
            else:
                remainder.append(line)
        if final and completed != self.contract["count"]:
            raise ValueError("native completed-unit inventory is incomplete")
        return completed, "".join(remainder)

    def __call__(self, stdout, stderr):
        return self.project(stdout)[0]
