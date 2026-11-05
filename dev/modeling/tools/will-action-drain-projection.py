from pathlib import Path
import importlib.util
SPEC={'module': 'will_action_drain', 'namespace': 'WillDrainAst', 'fields': {'weak': 'int', 'ready': 'int', 'claimed': 'int', 'loaded': 'int', 'runnable': 'int', 'active': 'int', 'unknown': 'int', 'pins': 'int', 'captures': 'int', 'created': 'int', 'retired': 'int', 'epoch': 'int', 'sealedEpoch': 'int', 'uses': 'int', 'closed': 'bool', 'mapped': 'bool', 'aliases': 'bool', 'issued': 'bool'}, 'actions': ['reserveExternal', 'reserveChild', 'commitWill', 'abortReservation', 'unknownCommit', 'closeExternal', 'makeExecutable', 'dequeue', 'loadOperands', 'zapWillFields', 'enterAction', 'capture', 'returnAction', 'escapeAction', 'resumeCapture', 'retireOneCapture', 'resolveUnknownDone', 'resolveUnknownReady', 'attestRootMaps', 'attestAliasClosure', 'issue', 'reuse', 'unmanagedInterference']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py');s=importlib.util.spec_from_file_location('interval_scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
