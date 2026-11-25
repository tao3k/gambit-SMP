"""Typed finite-state verification using the shared checker and process recorder."""
import json
import re
from pathlib import Path

from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import isolated_endpoint, interpret, summarize


def checked_observed_tests(output, expected):
    """Require the exact nonempty set of passed Quint CLI test names.

    This checks the emitted test report, not the parsed module's complete test
    inventory; use quint.test for a separately parsed exact inventory.
    """
    rows = re.findall(r'^\s*ok\s+(\S+)\s+passed\s+([0-9]+)\s+test\(s\)\s*$',
                      output, re.MULTILINE)
    names = [name for name, count in rows if int(count) > 0]
    summaries = re.findall(r'^\s*([0-9]+)\s+passing\b', output, re.MULTILINE)
    if (not expected or len(names) != len(rows) or len(names) != len(set(names))
            or sorted(names) != sorted(expected) or len(summaries) != 1
            or int(summaries[0]) != len(names)):
        raise ValueError('Quint observed test report differs from exact nonempty inventory')
    return names


def observation_command(arguments, context):
    """Bind a finite scientific request without changing flags or defaults."""
    from gambit_smp.research_flow import EvidenceUnavailable
    if (not isinstance(arguments,list) or len(arguments)<2
            or arguments[0] not in {'parse','typecheck','test','run'}
            or not all(isinstance(arg,str) for arg in arguments)):
        raise ValueError('explicit Quint operation and source required')
    source=Path(arguments[1]);source=source if source.is_absolute() else context.root/source
    if source.suffix!='.qnt' or source.is_symlink() or not source.is_file():
        raise EvidenceUnavailable('Quint source is unavailable')
    resolved=source.resolve()
    if not resolved.is_relative_to(context.root) or (resolved.is_relative_to(context.root/'.cache') and not resolved.is_relative_to(context.directory)):
        raise ValueError('Quint source must be maintained or owned generated input')
    allowed={'--out','--main','--backend','--seed','--max-samples','--max-steps',
             '--match','--init','--step','--invariant','--verbosity'}
    options=arguments[2:];seen=set();index=0
    while index<len(options):
        flag=options[index]
        if flag not in allowed or flag in seen or index+1>=len(options):
            raise ValueError('unsupported or duplicated Quint request option: '+flag)
        seen.add(flag);index+=2
    if not context.tools.get('node') or not context.tools.get('quint'):
        raise EvidenceUnavailable('sealed Quint/Node provider unavailable')
    context.bind([resolved])
    return [context.tools['node'],context.tools['quint'],*arguments]


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
    def validate_observation(args,inputs):
        from gambit_smp.recipes import fields
        fields(args,('argv',),('typed','expectedTests'))
        if (not isinstance(args['argv'],list) or len(args['argv'])<2
                or not all(isinstance(value,str) for value in args['argv'])
                or args['argv'][0] not in {'parse','typecheck','test','run'} or args['argv'][1] not in inputs):
            raise ValueError('explicit finite Quint operation required')
        if 'typed' in args and (args['typed'] is not True or args['argv'][0]!='typecheck' or '--out' in args['argv']):
            raise ValueError('typed artifact requires typecheck and an owner-generated output')
        if 'expectedTests' in args:
            tests = args['expectedTests']
            if (args['argv'][0] != 'test' or not isinstance(tests, list) or not tests
                    or any(not isinstance(name, str)
                    or not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_:]*Test', name) for name in tests)
                    or len(tests) != len(set(tests))):
                raise ValueError('exact nonempty Quint test inventory required')
    def observe(args,context):
        # Preserve samples/seeds exactly. This observation cannot claim TLC's
        # exhaustive result or discharge Lean's induction obligations.
        arguments=list(args['argv'])
        typed=context.directory/'typed-ir.json'
        if args.get('typed'):arguments+=['--out',str(typed)]
        observation_command(arguments,context)
        text=context.command('quint',['quint',*arguments],policy=dict(
            cap=60,stream='stdout',failure='runtime',failParameter=False,expectedParameter=False))
        tests = checked_observed_tests(text, args['expectedTests']) if 'expectedTests' in args else None
        path=context.directory/'observation.json'
        from gambit_smp.framework import digest
        result=dict(operation=args['argv'][0],stdout=text,source=args['argv'][1],
                    sourceSha256=digest(context.root/args['argv'][1]),exhaustive=False,runtimeAdmitted=False)
        if tests is not None:
            result['observedPassingTests'] = tests
        path.write_text(json.dumps(result,indent=2)+'\n')
        outputs=context.publish('observation','quint-observation',path)
        if args.get('typed'):
            data=json.loads(typed.read_text())
            if data.get('stage')!='typechecking' or data.get('errors'):
                raise ValueError('complete successful typed IR required')
            from gambit_smp.framework import digest
            result.update(typedSource=args['argv'][1],typedSourceSha256=digest(context.root/args['argv'][1]))
            outputs.update(context.publish('typed','quint-typed-ir',typed))
        return dict(result,outputs=outputs)
    return {"quint.observe": Capability(validate_observation,executor=observe,
                                       outputs=(("observation","quint-observation"),("typed","quint-typed-ir"))),
            "quint.verify": Capability(validate, executor=verify, graph=graph,
                                       outputs=(("verification", "quint-verification"),))}
