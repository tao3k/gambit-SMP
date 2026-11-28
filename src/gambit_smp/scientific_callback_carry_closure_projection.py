from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'callback_carry_closure', 'namespace': 'CallbackCarryAst', 'fields': {'pc': 'int', 'wlo': 'int', 'whi': 'int', 'rlo': 'int', 'rhi': 'int', 'carry': 'int', 'physical': 'int', 'bias': 'int', 'roots': 'int', 'active': 'int', 'epoch': 'int', 'sealedEpoch': 'int', 'closed': 'bool', 'mapped': 'bool', 'released': 'bool', 'permit': 'bool', 'unknown': 'bool'}, 'actions': ['beginLegal', 'beginInternalCarry', 'advanceFifo', 'allocateCandidate', 'installShared', 'expose', 'allocationFailure', 'capture', 'resume', 'returnActivation', 'attestRootRetirement', 'release', 'changeRegistration', 'unknownCallback', 'attestEffects']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_callback_carry_closure_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
