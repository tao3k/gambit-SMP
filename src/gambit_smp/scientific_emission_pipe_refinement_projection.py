from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'emission_pipe_refinement', 'namespace': 'EmissionPipeAst', 'fields': {'ep': 'int', 'profile': 'int', 'demand': 'int', 'epoch': 'int', 'planEpoch': 'int', 'certEpoch': 'int', 'outputCalls': 'int', 'pc': 'int', 'wlo': 'int', 'whi': 'int', 'rlo': 'int', 'rhi': 'int', 'emitted': 'int', 'delivered': 'int', 'index': 'int', 'savedIndex': 'int', 'wgen': 'int', 'rgen': 'int', 'resumes': 'int', 'completed': 'int', 'writer': 'int', 'savedWriter': 'int', 'unknown': 'bool', 'fault': 'bool', 'attested': 'bool', 'certificate': 'bool', 'special': 'bool', 'shared': 'bool', 'locked': 'bool', 'captured': 'bool', 'custody': 'bool', 'clobbered': 'bool'}, 'actions': ['first', 'selectDebug', 'selectCustom', 'prmRemainder', 'initText', 'gloPrefix', 'scalarDispatch', 'namedEffect', 'customRaw', 'replaceEntry', 'unknownEffect', 'ioAbort', 'attest', 'issue', 'second', 'omitSecond', 'pause', 'readChunk', 'advanceReader', 'exposeWriter', 'consumeWriter', 'resume', 'publish', 'appendTail', 'finish', 'installNew']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_emission_pipe_refinement_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
