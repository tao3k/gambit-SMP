from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'native_binding_plan_retirement', 'namespace': 'NativeBindingPlanAst', 'fields': {'stage': 'int', 'epoch': 'int', 'planEpoch': 'int', 'mode': 'int', 'demand': 'int', 'headerDemand': 'int', 'prmCount': 'int', 'gloCount': 'int', 'entry': 'bool', 'layout': 'bool', 'exclusive': 'bool', 'noObservers': 'bool', 'sealed': 'bool', 'first': 'bool', 'second': 'bool', 'prm': 'bool', 'glo': 'bool', 'paused': 'bool', 'revoked': 'bool', 'custody': 'bool', 'closed': 'bool', 'receipt': 'bool'}, 'actions': ['discover', 'resolve', 'closeWriters', 'admitElision', 'requireMetadata', 'writeHeader', 'sealPlan', 'firstElide', 'firstPreserve', 'emitPrm', 'secondElide', 'secondPreserve', 'emitGlo', 'closeOutput', 'issue', 'pause', 'resumeSame', 'foreignReentry', 'lateWriter', 'escapedObserver', 'unknownExit', 'rejectResume']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_native_binding_plan_retirement_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
