"""Typed finite-state verification using the shared checker and process recorder."""
import json

from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import isolated_endpoint, interpret, summarize


def validate(args, inputs):
    from gambit_smp.recipes import fields, source_operand, SYMBOL
    fields(args, ("source", "parsed", "initializer", "step", "invariant", "negative"), ("temporal",))
    source_operand(args, inputs)
    for key in ("initializer", "step", "invariant", "temporal"):
        if key in args and (not isinstance(args[key], str) or not SYMBOL.fullmatch(args[key])):
            raise ValueError("explicit Quint operator name required")
    if type(args["negative"]) is not bool or args["negative"] and "temporal" in args:
        raise ValueError("negative verification cannot claim temporal completion")


def graph(step, by_id, capabilities):
    args = step["arguments"]
    parent = by_id.get(args["parsed"])
    if (args["parsed"] not in step["dependsOn"] or parent is None
            or parent["capability"] != "quint.parse"
            or parent["arguments"]["source"] != args["source"]):
        raise ValueError("verification requires the matching declared parsed source")


def verify(args, context):
    from gambit_smp.recipes import source_path
    source = source_path(context.root, args["source"])
    context.bind([source])
    config = context.directory / "tlc-config.json"
    cpus = available_processors()
    config.write_text(json.dumps({"workers": cpus, "maxHeap": "-Xmx8G"}) + "\n")
    argv = [context.tools["node"], context.tools["quint"], "verify", str(source),
            "--backend", "tlc", "--server-endpoint", isolated_endpoint(),
            "--init", args["initializer"], "--step", args["step"],
            "--invariant", args["invariant"], "--tlc-config", str(config)]
    if "temporal" in args:
        argv.extend(["--temporal", args["temporal"]])
    code, output, timeout, seconds = context.run("verify", argv, context.root, context.remaining())
    accepted, trace = interpret(code, output, timeout, negative=args["negative"], temporal=args.get("temporal"))
    process = context.commands[-1]
    if (not accepted or process.get("parentReaped") is not True
            or process.get("processGroupQuiescent") is not True):
        raise ValueError("checker verdict, exhaustive completion or process teardown not established")
    if args["negative"]:
        process["expectedExit"] = code
        (context.directory / "counterexample.json").write_text(json.dumps(trace, indent=2) + "\n")
    verdict = {"accepted": accepted, "negative": args["negative"], "states": summarize(output),
               "temporal": args.get("temporal"), "availableProcessors": cpus,
               "seconds": seconds, "runtimeAdmitted": False, "sourceRefinementAdmitted": False}
    (context.directory / "verdict.json").write_text(json.dumps(verdict, indent=2) + "\n")
    return {"verification": verdict,
            "outputs": context.publish("verification", "quint-verification", context.directory / "verdict.json")}


def capabilities(Capability):
    return {"quint.verify": Capability(validate, executor=verify, graph=graph,
                                       outputs=(("verification", "quint-verification"),))}
