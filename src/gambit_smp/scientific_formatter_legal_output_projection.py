from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'formatter_legal_output', 'namespace': 'FormatterLegalAst', 'fields': {'pc': 'int', 'writer': 'int', 'savedWriter': 'int', 'generation': 'int', 'capacity': 'int', 'produced': 'int', 'consumed': 'int', 'callbacks': 'int', 'resumes': 'int', 'epoch': 'int', 'planEpoch': 'int', 'lastWriteEpoch': 'int', 'writes': 'int', 'demand': 'int', 'certGen': 'int', 'certEpoch': 'int', 'attempts': 'int', 'validVar': 'bool', 'pipe': 'bool', 'handler': 'bool', 'captured': 'bool', 'custody': 'bool', 'newer': 'bool', 'clobbered': 'bool', 'closed': 'bool', 'fault': 'bool', 'equivalent': 'bool', 'certificate': 'bool', 'alive': 'bool', 'raw': 'bool', 'locked': 'bool'}, 'actions': ['prepare', 'enter', 'fill', 'timeout', 'captureEscape', 'publish', 'drain', 'resume', 'returnHandler', 'namedTail', 'rawTail', 'rejectDead', 'resetRegistry', 'endRegistry', 'callbackReturns', 'finish', 'closeAdmission', 'detach', 'attest', 'issue', 'attemptStale']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_formatter_legal_output_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
