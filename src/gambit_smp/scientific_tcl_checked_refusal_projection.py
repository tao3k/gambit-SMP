"""Restricted typed AST projection; no native C23 or slot-value proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'tcl_checked_refusal', 'namespace': 'TclRefusalAst', 'fields': {'scope': 'int', 'vmOpen': 'int', 'outerSticky': 'int', 'childSticky': 'int', 'childMerged': 'int', 'eventSeen': 'int', 'tclCode': 'int', 'diagnostic': 'int', 'done': 'int', 'delivered': 'int', 'origin': 'int', 'translated': 'int'}, 'actions': ['beginEval', 'beginNested', 'recordOuterRefusal', 'recordChildRefusal', 'publishOuterDiagnostic', 'publishChildDiagnostic', 'catchOrResetResult', 'ordinaryTclError', 'mergeChildRefusal', 'popNested', 'finishEval', 'deliverRefusal', 'deliverOrdinaryNativeError', 'translateOrdinaryError', 'deliverSuccess', 'closeVm', 'resumeVm']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_tcl_checked_refusal_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
