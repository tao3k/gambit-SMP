"""Source inventory and clean-checkout checks for research artifact contracts.

AST enumeration is not a complete Python/native effect proof. Dynamic accesses
stay visible with their runtime boundary; unknown native effects stay unresolved.
"""
import json
from pathlib import Path
import sys

from gambit_smp.task_entry import managed_tool
from gambit_smp.task_processes import run as run_process
from gambit_smp.research_flow import inventory, clean_smoke
from gambit_smp.framework import digest as sha


@managed_tool('research-flow-audit')
def main():
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--clean-checkout', action='store_true')
    parser.add_argument('--source', type=Path, help='source checkout bound to the model sourcePrefix; never re-sign identities')
    parser.add_argument('--model', type=Path, help='maintained SysML contract loaded through the official Python API')
    parser.add_argument('--part', help='qualified contract part; no version-specific Python selector')
    parser.add_argument('--engine', type=Path, help='existing immutable seal containing the managed SDK/service provider')
    parser.add_argument('--baseline', type=Path, help='reviewed frontend equivalence oracle; never regenerated automatically')
    args = parser.parse_args()
    flags = [args.source, args.model, args.part, args.engine]
    if any(value is not None for value in flags) and (not all(value is not None for value in flags) or args.clean_checkout):
        parser.error('--source, --model, --part and --engine form one inspection; separate --clean-checkout')
    if args.baseline is not None and args.source is None:
        parser.error('--baseline requires the parameterized source inspection')
    root = Path(__file__).resolve().parents[2]
    from gambit_smp.research_publication import _rules
    if sha(root/'dev/modeling/models/sysml/research-storage.sysml') != _rules.POLICY_SHA256:
        raise SystemExit('stale SysML-derived policy')
    from gambit_smp.workspace import task_output
    out = task_output(root, root/'.cache/research-flow-audit')
    out.mkdir(parents=True, exist_ok=False)
    if args.source is not None:
        return inspect_source(root, out, args)
    report = inventory(root)
    (out/'inventory.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['violations']:
        print(json.dumps(report['violations'][:20], indent=2))
        raise SystemExit(1)
    cold = clean_smoke(root, out/'clean-checkout') if args.clean_checkout else None
    if cold:
        (out/'clean-checkout.json').write_text(json.dumps(cold, indent=2)+'\n')
    print(json.dumps(dict(pythonFiles=len(report['files']), accesses=len(report['accesses']),
                         requiredInputsAvailable=report['requiredInputsAvailable'],
                         unavailableRecipes=report['unavailableRecipes'], runtimeAdmitted=False,
                         violations=0, cleanCheckoutChecked=cold is not None, nativeWriterClosure='unresolved',
                         output=str(out.relative_to(root))), indent=2))
    return 0 if report['requiredInputsAvailable'] else 2


def inspect_source(root, out, args):
    """Operator adapter; the existing capabilities still own the actual checks."""
    import time
    from gambit_smp import contract_capabilities as capabilities
    from gambit_smp.recipes import read_json
    from gambit_smp.research_kernel import manifest_paths
    model = args.model.resolve(strict=True).relative_to(root).as_posix()
    source = args.source.resolve(strict=True)
    if not source.is_dir():
        raise ValueError('existing source checkout required')
    arguments = dict(models=[model], part=args.part)
    declared = [model, capabilities.SERVICE_ENTRY, capabilities.SERVICE_RULES]
    if args.baseline is not None:
        baseline = args.baseline.resolve(strict=True).relative_to(root).as_posix()
        arguments['baseline'] = baseline
        declared.append(baseline)
    capabilities.validate_project(arguments, declared)
    engine = args.engine.resolve(strict=True)
    manifest = manifest_paths(engine)
    if not manifest.get("sysmlProvider"):
        raise FileNotFoundError("sealed OpenSysML provider unavailable")
    receipt = dict(declaredInputs=declared, steps=[], runtimeAdmitted=False, evidenceAccepted=False,
                   engine=dict(path=str(engine), engineId=manifest['engineId']),
                   sourceRoot=str(source), model=model, part=args.part, budgetSeconds=50)
    request = out/'inspection-request.json'
    request.write_text(json.dumps(dict(engine=str(engine), engineId=manifest['engineId'],
        root=str(root), arguments=arguments, receipt=receipt, deadline=time.monotonic()+50))+'\n')
    completed = run_process([sys.executable, '-I', '-S', '-B',
        str(engine/'python/gambit_smp/contract_capabilities.py'), '--source-inspect', str(request)],
        cwd=root, timeout=50, capture_output=True)
    (out/'inspection.stdout').write_bytes(completed.stdout)
    (out/'inspection.stderr').write_bytes(completed.stderr)
    if not (out/'inspection.json').is_file():
        raise ValueError('sealed inspection did not deliver a receipt; see inspection.stderr')
    receipt = read_json(out/'inspection.json')
    if completed.returncode and receipt.get('outcome') == 'MATCHED':
        raise ValueError('failed inspection cannot deliver a matched result')
    print(json.dumps({key: receipt.get(key) for key in ['outcome', 'sourceRoot', 'model', 'part', 'reason',
                                                      'runtimeAdmitted', 'evidenceAccepted']}, indent=2))
    return 0 if receipt['outcome'] == 'MATCHED' else 2


if __name__ == '__main__':
    raise SystemExit(main())
