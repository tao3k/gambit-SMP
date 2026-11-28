from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'will_action_drain', 'namespace': 'WillDrainAst', 'fields': {'weak': 'int', 'ready': 'int', 'claimed': 'int', 'loaded': 'int', 'runnable': 'int', 'active': 'int', 'unknown': 'int', 'pins': 'int', 'captures': 'int', 'created': 'int', 'retired': 'int', 'epoch': 'int', 'sealedEpoch': 'int', 'uses': 'int', 'closed': 'bool', 'mapped': 'bool', 'aliases': 'bool', 'issued': 'bool'}, 'actions': ['reserveExternal', 'reserveChild', 'commitWill', 'abortReservation', 'unknownCommit', 'closeExternal', 'makeExecutable', 'dequeue', 'loadOperands', 'zapWillFields', 'enterAction', 'capture', 'returnAction', 'escapeAction', 'resumeCapture', 'retireOneCapture', 'resolveUnknownDone', 'resolveUnknownReady', 'attestRootMaps', 'attestAliasClosure', 'issue', 'reuse', 'unmanagedInterference']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_will_action_drain_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
